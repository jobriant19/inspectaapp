import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_branding_cache.dart';
import '../admin/admin_shell_screen.dart';
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

  Future<void> _navigateWhenReady() async {
    final stopwatch = Stopwatch()..start();
    final destination = await _resolveDestination();

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < _kMinSplashMs) {
      await Future.delayed(Duration(milliseconds: _kMinSplashMs - elapsed));
    }

    if (!mounted || _navigating) return;
    _navigating = true;

    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;
    destination();
  }

  Future<Map<String, dynamic>?> _fetchAppBranding() async {
    try {
      final res = await Supabase.instance.client
          .from('app_info')
          .select('app_name, tagline, tagline_en, tagline_zh, logo_url')
          .order('id')
          .limit(1)
          .maybeSingle();
      if (res != null) await AppBrandingCache.save(res);
      return res;
    } catch (e) {
      debugPrint('Splash fetch app branding error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOnboardingSlides() async {
    try {
      final res = await Supabase.instance.client
          .from('onboarding_slides')
          .select()
          .order('sort_order');
      final slides = List<Map<String, dynamic>>.from(res);
      if (mounted) {
        await Future.wait(slides.map((s) {
          final url = s['image_url'] as String?;
          if (url == null || url.isEmpty) return Future.value();
          return precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
        }));
      }
      return slides;
    } catch (e) {
      debugPrint('Splash fetch onboarding slides error: $e');
      return [];
    }
  }

  Future<VoidCallback> _resolveDestination() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        return await _resolveLoggedIn(session);
      }

      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
      final savedLang = prefs.getString('lang') ?? 'EN';

      final branding = await _fetchAppBranding();
      final String? brandLogoUrl = branding?['logo_url'] as String?;
      if (brandLogoUrl != null && brandLogoUrl.isNotEmpty && mounted) {
        await precacheImage(CachedNetworkImageProvider(brandLogoUrl), context)
            .catchError((_) {});
      }

      final List<Map<String, dynamic>> onboardingSlides =
          onboardingDone ? [] : await _fetchOnboardingSlides();

      return onboardingDone
          ? () => Navigator.pushReplacement(
              context,
              _slideRoute(LoginScreen(
                initialLang: savedLang,
                initialAppName: branding?['app_name'] as String?,
                initialAppLogoUrl: brandLogoUrl,
                initialTaglineId: branding?['tagline'] as String?,
                initialTaglineEn: branding?['tagline_en'] as String?,
                initialTaglineZh: branding?['tagline_zh'] as String?,
              )))
          : () => Navigator.pushReplacement(
              context,
              _slideRoute(OnboardingScreen(
                initialAppName: branding?['app_name'] as String?,
                initialAppLogoUrl: brandLogoUrl,
                initialTaglineId: branding?['tagline'] as String?,
                initialTaglineEn: branding?['tagline_en'] as String?,
                initialTaglineZh: branding?['tagline_zh'] as String?,
                initialSlides: onboardingSlides.isEmpty ? null : onboardingSlides,
              )));
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

      final results = await Future.wait([
        Supabase.instance.client
            .from('User')
            .select(
                'is_verificator, nama, poin, gambar_user, id_jabatan, id_unit, '
                'id_lokasi, id_subunit, id_area, is_visitor, is_pro_mode, '
                'is_blocked, unblock_requested, jabatan(nama_jabatan)')
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

      final locationData = await _resolveLocationName(userData);

      final metaName  = session.user.userMetadata?['full_name']
                     ?? session.user.userMetadata?['name'];
      final metaImage = session.user.userMetadata?['avatar_url']
                     ?? session.user.userMetadata?['picture'];
      final String? dbImage =
          (userData['gambar_user'] as String?)?.isNotEmpty == true
              ? userData['gambar_user']
              : null;
      final String? imageToUse = dbImage ?? metaImage;

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

      if (isAdmin) {
        int sTotalUsers = 0, sTotalLokasi = 0, sTotalKategori = 0;
        int sTotalTemuan = 0;
        int sTotalUnit = 0, sTotalSubunit = 0, sTotalArea = 0;
        try {
          final stats = await Future.wait([
            Supabase.instance.client.from('User').count(),
            Supabase.instance.client.from('lokasi').count(),
            Supabase.instance.client.from('kategoritemuan').count(),
            Supabase.instance.client.from('temuan').count(),
            Supabase.instance.client.from('temuan').count().eq('status_temuan', 'Belum'),
            Supabase.instance.client.from('temuan').count().eq('status_temuan', 'Selesai'),
            Supabase.instance.client.from('unit').count(),
            Supabase.instance.client.from('subunit').count(),
            Supabase.instance.client.from('area').count(),
          ]);
          sTotalUsers    = stats[0];
          sTotalLokasi   = stats[1];
          sTotalKategori = stats[2];
          sTotalTemuan   = stats[3];
          sTotalUnit     = stats[6];
          sTotalSubunit  = stats[7];
          sTotalArea     = stats[8];
        } catch (_) {}

        if (mounted) await warmupAdminFonts(context);

        return () => Navigator.pushReplacement(
          context,
          _instantRoute(AdminShellScreen(
            initialUserName:    (userData['nama'] as String?) ?? metaName?.toString(),
            initialUserImage:   imageToUse,
            initialTotalUsers:  sTotalUsers,
            initialTotalLokasi: sTotalLokasi,
            initialTotalKategori: sTotalKategori,
            initialTotalTemuan: sTotalTemuan,
            initialTotalUnit: sTotalUnit,
            initialTotalSubunit: sTotalSubunit,
            initialTotalArea: sTotalArea,
            initialLang: lang,
          )),
        );
      }

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
          initialIsBlocked: userData['is_blocked'] as bool? ?? false,
          initialUnblockRequested: userData['unblock_requested'] as bool? ?? false,
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
            Positioned(
              top: 0,
              left: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.0,
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: OverflowBox(
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: 500,
                      maxHeight: 500,
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        children: [
                          const Text('🇺🇸🇮🇩🇨🇳', style: TextStyle(fontSize: 22)),
                          const Text('🇺🇸🇮🇩🇨🇳', style: TextStyle(fontSize: 18)),
                          Text(
                            '欢迎来到Inspecta实时分析攀登排行榜庆祝成就',
                            style: GoogleFonts.notoSansSc(fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '有纪律高效率地监控报告解决问题通过我们先进的分析仪表板即时获取洞察'
                            '每项任务都能获得积分并在排行榜上看到您的名字解锁奖励与团队一起庆祝里程碑跳过',
                            style: GoogleFonts.notoSansSc(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '开始使用下一步',
                            style: GoogleFonts.notoSansSc(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '选择语言',
                            style: GoogleFonts.notoSansSc(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          Text('中文', style: GoogleFonts.notoSansSc(fontSize: 15, fontWeight: FontWeight.w700)),
                          Text('中文', style: GoogleFonts.notoSansSc(fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

            _buildAnimatedItem(
              imagePath: 'assets/images/clean.png',
              width: 120,
              targetOffset: Offset(-size.width * 0.35, -size.height * 0.18),
            ),
            _buildAnimatedItem(
              imagePath: 'assets/images/winner.png',
              width: 130,
              targetOffset: Offset(0, -size.height * 0.22),
            ),
            _buildAnimatedItem(
              imagePath: 'assets/images/regular.png',
              width: 120,
              targetOffset: Offset(size.width * 0.35, -size.height * 0.18),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
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
                    fit: BoxFit.contain,
                    height: size.height * 0.42,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),

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
                  width: size.width * 0.68,
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