import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/home/admin_home_screen.dart';
import '../user/home/home_screen.dart';
import '../auth/login_screen.dart';
import '../user/home/popup/home_point_popup.dart';
import 'onboarding_screen.dart';
import '../../core/utils/font_warmup.dart';

const _kMinSplashMs = 2200;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _navigateWhenReady();
  }

  // ── Navigasi: jalankan resolusi + splash timer secara paralel ────────────────
  Future<void> _navigateWhenReady() async {
    final stopwatch = Stopwatch()..start();
    final destination = await _resolveDestination();

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < _kMinSplashMs) {
      await Future.delayed(Duration(milliseconds: _kMinSplashMs - elapsed));
    }

    if (!mounted || _navigating) return;
    _navigating = true;

    // Tunggu 2 frame agar Flutter engine flush semua resource
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;
    destination();
  }

  /// Mengembalikan closure navigasi tanpa langsung mengeksekusinya.
  Future<VoidCallback> _resolveDestination() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        return await _resolveLoggedIn(session);
      }

      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

      return onboardingDone
          ? () => Navigator.pushReplacement(context, _slideRoute(const LoginScreen()))
          : () => Navigator.pushReplacement(context, _slideRoute(const OnboardingScreen()));
    } catch (e) {
      debugPrint('SplashScreen resolve error: $e');
      await Supabase.instance.client.auth.signOut().catchError((_) {});
      return () => Navigator.pushReplacement(context, _slideRoute(const LoginScreen()));
    }
  }

  Future<VoidCallback> _resolveLoggedIn(Session session) async {
    try {
      final userId = session.user.id;
      final prefs = await SharedPreferences.getInstance();
      final String lang = prefs.getString('lang') ?? 'EN';

      // Ambil data user + log poin secara paralel
      final results = await Future.wait([
        Supabase.instance.client
            .from('User')
            .select(
                'is_verificator, nama, poin, gambar_user, id_jabatan, id_unit, '
                'id_lokasi, id_subunit, id_area, is_visitor, is_pro_mode, jabatan(nama_jabatan)')
            .eq('id_user', userId)
            .single(),
        Supabase.instance.client
            .from('log_poin')
            .select('poin, deskripsi, tipe_aktivitas, created_at')
            .eq('id_user', userId)
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(1),
      ]);

      final userData  = results[0] as Map<String, dynamic>;
      final logs      = results[1] as List<dynamic>;
      final latestLog = logs.isNotEmpty ? logs.first as Map<String, dynamic> : null;

      final bool isVerifFlag = userData['is_verificator'] as bool? ?? false;
      final int? idJabatan   = userData['id_jabatan'] as int?;
      final bool isVerificator = isVerifFlag || idJabatan == 1 || idJabatan == 2 || idJabatan == 5;
      final bool isAdmin       = idJabatan == 6;

      // Resolusi nama lokasi (level paling spesifik)
      final locationData = await _resolveLocationName(userData);

      // Gambar: DB lebih prioritas, fallback ke OAuth meta
      final metaName  = session.user.userMetadata?['full_name']
                     ?? session.user.userMetadata?['name'];
      final metaImage = session.user.userMetadata?['avatar_url']
                     ?? session.user.userMetadata?['picture'];
      final String? dbImage =
          (userData['gambar_user'] as String?)?.isNotEmpty == true
              ? userData['gambar_user']
              : null;
      final String? imageToUse = dbImage ?? metaImage;

      // Precache aset + gambar user secara paralel
      if (mounted) {
        await Future.wait([
          precacheImage(const AssetImage('assets/images/logo1.png'), context)
              .catchError((_) {}),
          precacheImage(const AssetImage('assets/images/bgadmin.png'), context)
              .catchError((_) {}),
          if (imageToUse != null)
            precacheImage(CachedNetworkImageProvider(imageToUse), context)
                .catchError((_) {}),
        ]);
      }

      int initialNotifCount  = 0;
      int initialMonthlyPoin = 0;
      bool initialIsPmVisible = true;
      List<Map<String, dynamic>> initialPendingAudits = [];
      try {
        final now           = DateTime.now();
        final startOfMonth  = DateTime(now.year, now.month, 1).toIso8601String();
        final startOfNext   = DateTime(now.year, now.month + 1, 1).toIso8601String();

        final preload = await Future.wait<dynamic>([
          Supabase.instance.client
              .from('temuan')
              .count(CountOption.exact)
              .eq('id_penanggung_jawab', userId)
              .neq('status_temuan', 'Selesai'),
          Supabase.instance.client
              .from('log_poin')
              .select('poin')
              .eq('id_user', userId)
              .gte('created_at', startOfMonth)
              .lt('created_at', startOfNext),
          Supabase.instance.client
              .from('app_settings')
              .select('setting_value')
              .eq('setting_key', 'preventive_maintenance_visible')
              .maybeSingle(),
          _fetchPendingAuditsForSplash(userId, lang),
        ]);
        initialNotifCount = preload[0] as int;
        final logList     = preload[1] as List<dynamic>;
        initialMonthlyPoin = logList.fold<int>(
          0, (sum, l) => sum + ((l['poin'] as num?)?.toInt() ?? 0),
        );
        final pmRow = preload[2] as Map<String, dynamic>?;
        initialIsPmVisible = pmRow?['setting_value'] as bool? ?? true;
        initialPendingAudits = preload[3] as List<Map<String, dynamic>>;
      } catch (_) {}

      if (!mounted) return () {};

      // ── Alur Admin ────────────────────────────────────────────────────────
      if (isAdmin) {
        int sTotalUsers = 0, sTotalLokasi = 0, sTotalKategori = 0;
        int sTotalTemuan = 0, sTemuanBelum = 0, sTemuanSelesai = 0;
        try {
          final stats = await Future.wait([
            Supabase.instance.client.from('User').count(),
            Supabase.instance.client.from('lokasi').count(),
            Supabase.instance.client.from('kategoritemuan').count(),
            Supabase.instance.client.from('temuan').count(),
            Supabase.instance.client.from('temuan').count().eq('status_temuan', 'Belum'),
            Supabase.instance.client.from('temuan').count().eq('status_temuan', 'Selesai'),
          ]);
          sTotalUsers    = stats[0];
          sTotalLokasi   = stats[1];
          sTotalKategori = stats[2];
          sTotalTemuan   = stats[3];
          sTemuanBelum   = stats[4];
          sTemuanSelesai = stats[5];
        } catch (_) {}

        if (mounted) await warmupAdminFonts(context);

        return () => Navigator.pushReplacement(
          context,
          _instantRoute(AdminHomeScreen(
            initialUserName:    (userData['nama'] as String?) ?? metaName?.toString(),
            initialUserImage:   imageToUse,
            initialTotalUsers:  sTotalUsers,
            initialTotalLokasi: sTotalLokasi,
            initialTotalKategori: sTotalKategori,
            initialTotalTemuan: sTotalTemuan,
            initialTemuanBelum: sTemuanBelum,
            initialTemuanSelesai: sTemuanSelesai,
          )),
        );
      }

      // ── Alur User biasa ───────────────────────────────────────────────────
      await warmupPointPopupFonts();

      return () => Navigator.pushReplacement(
        context,
        _slideRoute(HomeScreen(
          initialUserName:      (userData['nama'] as String?) ?? metaName,
          initialUserPoin:      userData['poin'] as int?,
          initialUserImage:     imageToUse,
          initialUserRole:      userData['jabatan']?['nama_jabatan'] as String?,
          initialUserLocation:  locationData['name'],
          initialUserLocationLevel: locationData['level'],
          initialLatestLog:     latestLog,
          initialUserJabatanId: idJabatan,
          initialIsVerificator: isVerificator,
          initialNotifCount:    initialNotifCount,
          initialMonthlyPoin:   initialMonthlyPoin,
          initialIsProMode:     userData['is_pro_mode'] as bool? ?? false,
          initialIsVisitorMode: userData['is_visitor'] as bool? ?? false,
          initialIsPreventiveMaintenanceVisible: initialIsPmVisible,
          initialPendingAudits: initialPendingAudits,
        )),
      );
    } catch (e) {
      debugPrint('SplashScreen resolveLoggedIn error: $e');
      await Supabase.instance.client.auth.signOut().catchError((_) {});
      return () => Navigator.pushReplacement(context, _slideRoute(const LoginScreen()));
    }
  }

  Future<Map<String, String>> _resolveLocationName(Map<String, dynamic> userData) async {
    final idArea    = userData['id_area'];
    final idSubunit = userData['id_subunit'];
    final idUnit    = userData['id_unit'];
    final idLokasi  = userData['id_lokasi'];

    try {
      if (idArea != null) {
        final d = await Supabase.instance.client
            .from('area').select('nama_area').eq('id_area', idArea).maybeSingle();
        return {'name': d?['nama_area'] ?? '...', 'level': 'area'};
      } else if (idSubunit != null) {
        final d = await Supabase.instance.client
            .from('subunit').select('nama_subunit').eq('id_subunit', idSubunit).maybeSingle();
        return {'name': d?['nama_subunit'] ?? '...', 'level': 'subunit'};
      } else if (idUnit != null) {
        final d = await Supabase.instance.client
            .from('unit').select('nama_unit').eq('id_unit', idUnit).maybeSingle();
        return {'name': d?['nama_unit'] ?? '...', 'level': 'unit'};
      } else if (idLokasi != null) {
        final d = await Supabase.instance.client
            .from('lokasi').select('nama_lokasi').eq('id_lokasi', idLokasi).maybeSingle();
        return {'name': d?['nama_lokasi'] ?? '...', 'level': 'lokasi'};
      }
    } catch (_) {}
    return {'name': '...', 'level': 'lokasi'};
  }

  Future<List<Map<String, dynamic>>> _fetchPendingAuditsForSplash(
      String userId, String lang) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final rows = await Supabase.instance.client
          .from('audit_schedule')
          .select(
              'id_schedule, level_type, id_ref, periode_mulai, periode_selesai, status, '
              'id_jenis_audit, JenisAudit:jenis_audit(nama_id, nama_en, nama_zh)')
          .eq('id_auditor', userId)
          .inFilter('status', ['pending', 'in_progress'])
          .lte('periode_mulai', today)
          .gte('periode_selesai', today);

      if (rows.isEmpty) return [];

      final byLevel = <String, List<String>>{};
      for (final r in rows) {
        final level = r['level_type'] as String;
        byLevel.putIfAbsent(level, () => []).add(r['id_ref'].toString());
      }

      final nameMap = <String, String>{};
      await Future.wait(byLevel.entries.map((e) async {
        final level = e.key;
        final ids = e.value;
        try {
          final res = await Supabase.instance.client
              .from(level)
              .select('id_$level, nama_$level')
              .inFilter('id_$level', ids);
          for (final r in res) {
            nameMap[r['id_$level'].toString()] =
                r['nama_$level']?.toString() ?? r['id_$level'].toString();
          }
        } catch (_) {}
      }));

      return List<Map<String, dynamic>>.from(rows).map((row) {
        String? jenisLabel;
        final jenisData = row['JenisAudit'] as Map<String, dynamic>?;
        if (jenisData != null) {
          jenisLabel = lang == 'EN'
              ? jenisData['nama_en']?.toString()
              : lang == 'ZH'
                  ? jenisData['nama_zh']?.toString()
                  : jenisData['nama_id']?.toString();
        }
        return {
          ...row,
          'location_name': nameMap[row['id_ref'].toString()] ?? row['id_ref'].toString(),
          'jenis_audit_label': jenisLabel,
        };
      }).toList();
    } catch (e) {
      debugPrint('Splash pending audits error: $e');
      return [];
    }
  }

  // ── Route helpers ────────────────────────────────────────────────────────────
  PageRouteBuilder<T> _slideRoute<T>(Widget screen) => PageRouteBuilder<T>(
        pageBuilder: (_, animation, __) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      );

  PageRouteBuilder<T> _instantRoute<T>(Widget screen) => PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, __, ___, child) => child,
        transitionDuration: const Duration(milliseconds: 1),
        reverseTransitionDuration: Duration.zero,
      );

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFF92B5F6)],
            stops: [0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Efek lingkaran pudar
            Center(
              child: Container(
                width: 500, height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.15),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.2),
                ),
              ),
            ),

            // Item kiri atas: Clean
            _buildAnimatedItem(
              imagePath: 'assets/images/clean.png',
              width: 120,
              targetOffset: Offset(-size.width * 0.35, -size.height * 0.18),
            ),
            // Item tengah atas: Winner
            _buildAnimatedItem(
              imagePath: 'assets/images/winner.png',
              width: 130,
              targetOffset: Offset(0, -size.height * 0.22),
            ),
            // Item kanan atas: Regular
            _buildAnimatedItem(
              imagePath: 'assets/images/regular.png',
              width: 120,
              targetOffset: Offset(size.width * 0.35, -size.height * 0.18),
            ),

            // Karakter 3D meluncur dari bawah
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (_, value, child) => Transform.translate(
                  offset: Offset(0, size.height * 0.25 * (1 - value)),
                  child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                ),
                child: Image.asset(
                  'assets/images/character.png',
                  fit: BoxFit.fitWidth,
                  width: size.width * 0.78,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),

            // Logo
            Align(
              alignment: Alignment.center,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, scale, child) => Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: scale.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: Image(
                  image: const AssetImage('assets/images/logo1.png'),
                  width: size.width * 0.52,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.shield, color: Color(0xFF1976D2), size: 80),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedItem({
    required String imagePath,
    required double width,
    required Offset targetOffset,
  }) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => Transform.translate(
          offset: Offset(targetOffset.dx * value, targetOffset.dy * value),
          child: Transform.scale(
            scale: value.clamp(0.0, 1.0),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
        ),
        child: Image.asset(
          imagePath,
          width: width,
          errorBuilder: (_, __, ___) => const SizedBox(),
        ),
      ),
    );
  }
}