import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_home_screen.dart';
import '../user/home/home_screen.dart';
import '../auth/login_screen.dart';
import 'onboarding_screen.dart';

// ─── Durasi konstan ──────────────────────────────────────────────────────────
const _kMinSplashMs = 2200; // tampil minimum sebelum navigasi

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers animasi ──────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _itemsCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _textCtrl;

  // Animasi logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Animasi item terbang
  late final Animation<double> _itemsScale;
  late final Animation<Offset> _itemLeftOffset;
  late final Animation<Offset> _itemCenterOffset;
  late final Animation<Offset> _itemRightOffset;

  // Animasi teks
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  // Animasi pulsa latar
  late final Animation<double> _pulse;

  // Navigasi
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    // ── Setup controllers ─────────────────────────────────────────────────────
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _itemsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    // Logo scale + fade
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)));

    // Item terbang
    _itemsScale = CurvedAnimation(parent: _itemsCtrl, curve: Curves.easeOutBack);
    _itemLeftOffset = Tween<Offset>(
            begin: Offset.zero, end: const Offset(-1.4, -1.6))
        .animate(CurvedAnimation(
            parent: _itemsCtrl, curve: Curves.easeOutCubic));
    _itemCenterOffset = Tween<Offset>(
            begin: Offset.zero, end: const Offset(0.0, -2.0))
        .animate(CurvedAnimation(
            parent: _itemsCtrl, curve: Curves.easeOutCubic));
    _itemRightOffset = Tween<Offset>(
            begin: Offset.zero, end: const Offset(1.4, -1.6))
        .animate(CurvedAnimation(
            parent: _itemsCtrl, curve: Curves.easeOutCubic));

    // Teks bawah
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // Pulsa latar
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Jalankan urutan animasi
    _runAnimationSequence();

    // Navigasi: paralel dengan animasi agar tidak buang waktu
    _navigateWhenReady();
  }

  Future<void> _runAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _logoCtrl.forward();
    if (!mounted) return;
    _itemsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textCtrl.forward();
  }

  Future<void> _navigateWhenReady() async {
    // Jalankan fetch session & navigasi secara paralel agar hemat waktu
    final stopwatch = Stopwatch()..start();

    final destination = await _resolveDestination();

    // Pastikan splash tampil minimal _kMinSplashMs ms
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < _kMinSplashMs) {
      await Future.delayed(
          Duration(milliseconds: _kMinSplashMs - elapsed));
    }

    if (!mounted || _navigating) return;
    _navigating = true;
    destination();
  }

  /// Mengembalikan closure navigasi tanpa langsung mengeksekutinya,
  /// sehingga dapat ditunda hingga splash selesai.
  Future<VoidCallback> _resolveDestination() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        return await _resolveLoggedIn(session);
      }

      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

      if (onboardingDone) {
        return () => Navigator.pushReplacement(
            context,
            _slideRoute(const LoginScreen()));
      }
      return () => Navigator.pushReplacement(
          context,
          _slideRoute(const OnboardingScreen()));
    } catch (e) {
      debugPrint('SplashScreen resolve error: $e');
      await Supabase.instance.client.auth.signOut().catchError((_) {});
      return () => Navigator.pushReplacement(
          context,
          _slideRoute(const LoginScreen()));
    }
  }

  Future<VoidCallback> _resolveLoggedIn(Session session) async {
    try {
      final userId = session.user.id;

      // Ambil data user + meta login paralel
      final results = await Future.wait([
        Supabase.instance.client
            .from('User')
            .select(
                'is_verificator, nama, poin, gambar_user, id_jabatan, id_unit, id_lokasi, id_subunit, id_area, jabatan(nama_jabatan)')
            .eq('id_user', userId)
            .single(),
        Supabase.instance.client
            .from('log_poin')
            .select('poin, deskripsi, tipe_aktivitas, created_at')
            .eq('id_user', userId)
            .order('created_at', ascending: false)
            .limit(1),
      ]);

      final userData = results[0] as Map<String, dynamic>;
      final logs = results[1] as List<dynamic>;
      Map<String, dynamic>? latestLog =
          logs.isNotEmpty ? logs.first : null;

      final bool isVerificatorFlag =
          userData['is_verificator'] as bool? ?? false;
      final int? idJabatan = userData['id_jabatan'] as int?;
      final bool isVerificator =
          isVerificatorFlag || idJabatan == 1 || idJabatan == 5;

      // Resolusi lokasi
      String locationName = '...';
      final idArea = userData['id_area'];
      final idSubunit = userData['id_subunit'];
      final idUnit = userData['id_unit'];
      final idLokasi = userData['id_lokasi'];

      if (idArea != null) {
        final d = await Supabase.instance.client
            .from('area')
            .select('nama_area')
            .eq('id_area', idArea)
            .maybeSingle();
        locationName = d?['nama_area'] ?? locationName;
      } else if (idSubunit != null) {
        final d = await Supabase.instance.client
            .from('subunit')
            .select('nama_subunit')
            .eq('id_subunit', idSubunit)
            .maybeSingle();
        locationName = d?['nama_subunit'] ?? locationName;
      } else if (idUnit != null) {
        final d = await Supabase.instance.client
            .from('unit')
            .select('nama_unit')
            .eq('id_unit', idUnit)
            .maybeSingle();
        locationName = d?['nama_unit'] ?? locationName;
      } else if (idLokasi != null) {
        final d = await Supabase.instance.client
            .from('lokasi')
            .select('nama_lokasi')
            .eq('id_lokasi', idLokasi)
            .maybeSingle();
        locationName = d?['nama_lokasi'] ?? locationName;
      }

      final metaName =
          session.user.userMetadata?['full_name'] ??
          session.user.userMetadata?['name'];
      final metaImage =
          session.user.userMetadata?['avatar_url'] ??
          session.user.userMetadata?['picture'];
      final String? dbImage =
          (userData['gambar_user'] as String?)?.isNotEmpty == true
              ? userData['gambar_user']
              : null;
      final String? imageToUse = dbImage ?? metaImage;

      // Precache paralel
      if (mounted) {
        final tasks = <Future>[
          precacheImage(
                  const AssetImage('assets/images/logo1.png'), context)
              .catchError((_) {}),
          precacheImage(
                  const AssetImage('assets/images/bgadmin.png'), context)
              .catchError((_) {}),
        ];
        if (imageToUse != null) {
          tasks.add(
            precacheImage(CachedNetworkImageProvider(imageToUse), context)
                .catchError((_) {}),
          );
        }
        await Future.wait(tasks);
      }

      // Notif + monthly poin paralel
      int initialNotifCount = 0;
      int initialMonthlyPoin = 0;
      try {
        final now = DateTime.now();
        final startOfMonth =
            DateTime(now.year, now.month, 1).toIso8601String();
        final startOfNextMonth =
            DateTime(now.year, now.month + 1, 1).toIso8601String();

        final preload = await Future.wait([
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
              .lt('created_at', startOfNextMonth),
        ]);
        initialNotifCount = preload[0] as int;
        final logList = preload[1] as List<dynamic>;
        int total = 0;
        for (final log in logList) {
          total += ((log['poin'] as num?)?.toInt() ?? 0);
        }
        initialMonthlyPoin = total;
      } catch (_) {}

      if (!mounted) return () {};

      final bool isAdmin = idJabatan == 6;

      if (isAdmin) {
        int sTotalUsers = 0,
            sTotalLokasi = 0,
            sTotalKategori = 0;
        int sTotalTemuan = 0, sTemuanBelum = 0, sTemuanSelesai = 0;
        try {
          final statsResults = await Future.wait([
            Supabase.instance.client.from('User').count(),
            Supabase.instance.client.from('lokasi').count(),
            Supabase.instance.client.from('kategoritemuan').count(),
            Supabase.instance.client.from('temuan').count(),
            Supabase.instance.client
                .from('temuan')
                .count()
                .eq('status_temuan', 'Belum'),
            Supabase.instance.client
                .from('temuan')
                .count()
                .eq('status_temuan', 'Selesai'),
          ]);
          sTotalUsers = statsResults[0] as int;
          sTotalLokasi = statsResults[1] as int;
          sTotalKategori = statsResults[2] as int;
          sTotalTemuan = statsResults[3] as int;
          sTemuanBelum = statsResults[4] as int;
          sTemuanSelesai = statsResults[5] as int;
        } catch (_) {}
        return () => Navigator.pushReplacement(
            context,
            _slideRoute(AdminHomeScreen(
              initialUserName:
                  (userData['nama'] as String?) ?? metaName?.toString(),
              initialUserImage: imageToUse,
              initialTotalUsers: sTotalUsers,
              initialTotalLokasi: sTotalLokasi,
              initialTotalKategori: sTotalKategori,
              initialTotalTemuan: sTotalTemuan,
              initialTemuanBelum: sTemuanBelum,
              initialTemuanSelesai: sTemuanSelesai,
            )));
      }

      return () => Navigator.pushReplacement(
          context,
          _slideRoute(HomeScreen(
            initialUserName: (userData['nama'] as String?) ?? metaName,
            initialUserPoin: userData['poin'] as int?,
            initialUserImage: imageToUse,
            initialUserRole:
                userData['jabatan']?['nama_jabatan'] as String?,
            initialUserLocation: locationName,
            initialLatestLog: latestLog,
            initialUserJabatanId: idJabatan,
            initialIsVerificator: isVerificator,
            initialNotifCount: initialNotifCount,
            initialMonthlyPoin: initialMonthlyPoin,
          )));
    } catch (e) {
      debugPrint('SplashScreen resolveLoggedIn error: $e');
      await Supabase.instance.client.auth.signOut().catchError((_) {});
      return () => Navigator.pushReplacement(
          context,
          _slideRoute(const LoginScreen()));
    }
  }

  PageRouteBuilder<T> _slideRoute<T>(Widget screen) => PageRouteBuilder<T>(
        pageBuilder: (_, animation, __) => screen,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity:
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child),
        transitionDuration: const Duration(milliseconds: 350),
      );

  @override
  void dispose() {
    _logoCtrl.dispose();
    _itemsCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

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
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),

            // Item 1: Clean (Kiri Atas) — jarak diperkecil seperti semula
            _buildAnimatedItem(
              imagePath: 'assets/images/clean.png',
              width: 120,
              targetOffset: Offset(-size.width * 0.35, -size.height * 0.18),
            ),
            // Item 2: Winner (Tengah Atas)
            _buildAnimatedItem(
              imagePath: 'assets/images/winner.png',
              width: 130,
              targetOffset: Offset(0, -size.height * 0.22),
            ),
            // Item 3: Regular (Kanan Atas)
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
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, size.height * 0.25 * (1 - value)),
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Image.asset(
                  'assets/images/character.png',
                  fit: BoxFit.fitWidth,
                  width: size.width * 0.78,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),

            // Logo 
            Align(
              alignment: Alignment.center,
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: scale.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/logo1.png',
                  width: size.width * 0.52,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.shield,
                    color: Color(0xFF1976D2),
                    size: 80,
                  ),
                ),
              ),
            ),
            // TIDAK ada Text 'Inspecta' di sini
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
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(
              targetOffset.dx * value,
              targetOffset.dy * value,
            ),
            child: Transform.scale(
              scale: value.clamp(0.0, 1.0),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          );
        },
        child: Image.asset(
          imagePath,
          width: width,
          errorBuilder: (c, e, s) => const SizedBox(),
        ),
      ),
    );
  }
}

// ─── Loading dots animasi ─────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = ((_ctrl.value - delay + 1) % 1);
            final scale = 0.6 + 0.8 * math.sin(t * math.pi).clamp(0.0, 1.0);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.4 + 0.6 * scale - 0.6),
              ),
              transform: Matrix4.diagonal3Values(scale, scale, 1),
              transformAlignment: Alignment.center,
            );
          }),
        );
      },
    );
  }
}