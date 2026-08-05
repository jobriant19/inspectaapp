import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'dart:async';
import '../../core/utils/app_branding_cache.dart';
import '../admin/admin_shell_screen.dart';
import '../user/home/popup/home_point_popup.dart';
import 'auth_service.dart';
import '../user/home/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/font_warmup.dart';

class LoginScreen extends StatefulWidget {
  final String? initialLang;
  final String? initialAppName;
  final String? initialAppLogoUrl;
  final String? initialTaglineId;
  final String? initialTaglineEn;
  final String? initialTaglineZh;

  const LoginScreen({
    super.key,
    this.initialLang,
    this.initialAppName,
    this.initialAppLogoUrl,
    this.initialTaglineId,
    this.initialTaglineEn,
    this.initialTaglineZh,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();

  StreamSubscription? _authStateSubscription;

  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isRememberMe       = false;
  bool isLoading          = false;
  bool isPasswordVisible  = false;

  String selectedLanguage = 'EN';

  String? _dbAppName;
  String? _dbTaglineId;
  String? _dbTaglineEn;
  String? _dbTaglineZh;
  String? _dbLogoUrl;

  static const Map<String, String> _defaultTaglineOnly = {
    'EN': 'Make Your Discipline day!',
    'ID': 'Jadikan Harimu Disiplin!',
    'ZH': '让您的纪律日!',
  };

  String get _brandAppName =>
      (_dbAppName != null && _dbAppName!.trim().isNotEmpty) ? _dbAppName!.trim() : 'Inspecta';

  String get _brandTagline {
    String? dbVal;
    switch (selectedLanguage) {
      case 'EN':
        dbVal = _dbTaglineEn;
        break;
      case 'ZH':
        dbVal = _dbTaglineZh;
        break;
      default:
        dbVal = _dbTaglineId;
    }
    if (dbVal != null && dbVal.trim().isNotEmpty) return dbVal.trim();
    return _defaultTaglineOnly[selectedLanguage] ?? _defaultTaglineOnly['EN']!;
  }

  String get _brandTaglineFull => '$_brandAppName: $_brandTagline';

  static const Map<String, Map<String, String>> _translations = {
    'EN': {
      'login': 'Login',
      'welcome': 'Welcome Back!',
      'tagline_login': 'Inspecta: Make Your Discipline day!',
      'email_label': 'Email Address',
      'email_hint': 'Email',
      'pass_label': 'Password',
      'remember_me': 'Remember Me',
      'forgot_pass': 'Forgot Password?',
      'or_login': 'Or continue with',
      'google': 'Login with Google',
      'err_email': 'Fill E-mail First',
      'err_pass': 'Fill Password First',
      'err_email_pass': 'Fill E-mail & Password First',
      'err_wrong': 'Wrong Email or Password!',
      'try_again': 'Try Again',
      'reset_sent': 'Reset link sent to your email',
      'fill_email_reset': 'Fill your email to reset password!',
      'err_unknown': 'Unknown Email! Not registered.',
      'sign_in': 'Sign In',
      'select_language': 'Select Language',
      'select_language_desc': 'Choose your preferred display language',
      'pass_hint': 'Password',
    },
    'ID': {
      'login': 'Masuk',
      'welcome': 'Selamat Datang!',
      'tagline_login': 'Inspecta: Jadikan Harimu Disiplin!',
      'email_label': 'Alamat Email',
      'email_hint': 'Email',
      'pass_label': 'Kata Sandi',
      'remember_me': 'Ingat Saya',
      'forgot_pass': 'Lupa Sandi?',
      'or_login': 'Atau masuk dengan',
      'google': 'Masuk dengan Google',
      'err_email': 'Isi E-mail Terlebih Dahulu',
      'err_pass': 'Isi Password Terlebih Dahulu',
      'err_email_pass': 'Isi E-mail & Password Terlebih Dahulu',
      'err_wrong': 'Email atau Password Salah!',
      'try_again': 'Coba Lagi',
      'reset_sent': 'Link reset dikirim ke email Anda',
      'fill_email_reset': 'Isi email dulu untuk mereset password!',
      'err_unknown': 'Email Tidak Terdaftar!',
      'sign_in': 'Masuk',
      'select_language': 'Pilih Bahasa',
      'select_language_desc': 'Pilih bahasa tampilan yang Anda inginkan',
      'pass_hint': 'Kata Sandi',
    },
    'ZH': {
      'login': '登录',
      'welcome': '欢迎回来！',
      'tagline_login': 'Inspecta: 让您的纪律日!',
      'email_label': '电子邮件地址',
      'email_hint': '电子邮件',
      'pass_label': '密码',
      'remember_me': '记住我',
      'forgot_pass': '忘记密码？',
      'or_login': '或继续使用',
      'google': '使用Google登录',
      'err_email': '请先填写电子邮件',
      'err_pass': '请先填写密码',
      'err_email_pass': '请先填写电子邮件和密码',
      'err_wrong': '邮箱或密码错误！',
      'try_again': '重试',
      'reset_sent': '重置链接已发送到您的邮箱',
      'fill_email_reset': '请先填写您的邮箱以重置密码！',
      'err_unknown': '未知的电子邮件！',
      'sign_in': '登录',
      'select_language': '选择语言',
      'select_language_desc': '选择您偏好的显示语言',
      'pass_hint': '密码',
    },
  };

  String getTxt(String key) => _translations[selectedLanguage]![key] ?? key;

  @override
  void initState() {
    super.initState();
    if (widget.initialLang != null && _translations.containsKey(widget.initialLang)) {
      selectedLanguage = widget.initialLang!;
    }
    _dbAppName   = widget.initialAppName;
    _dbLogoUrl   = widget.initialAppLogoUrl;
    _dbTaglineId = widget.initialTaglineId;
    _dbTaglineEn = widget.initialTaglineEn;
    _dbTaglineZh = widget.initialTaglineZh;

    _loadSavedCredentials();
    _loadBrandingInstantly();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _setupAuthListener();
  }

  Future<void> _loadBrandingInstantly() async {
    if (_dbAppName == null && _dbLogoUrl == null && _dbTaglineId == null) {
      final cached = await AppBrandingCache.load();
      final hasCache = (cached['app_name']?.isNotEmpty ?? false) ||
          (cached['logo_url']?.isNotEmpty ?? false);
      if (mounted && hasCache) {
        setState(() {
          _dbAppName   = (cached['app_name']?.isNotEmpty ?? false) ? cached['app_name'] : _dbAppName;
          _dbLogoUrl   = (cached['logo_url']?.isNotEmpty ?? false) ? cached['logo_url'] : _dbLogoUrl;
          _dbTaglineId = (cached['tagline']?.isNotEmpty ?? false) ? cached['tagline'] : _dbTaglineId;
          _dbTaglineEn = (cached['tagline_en']?.isNotEmpty ?? false) ? cached['tagline_en'] : _dbTaglineEn;
          _dbTaglineZh = (cached['tagline_zh']?.isNotEmpty ?? false) ? cached['tagline_zh'] : _dbTaglineZh;
        });
        if (_dbLogoUrl != null && _dbLogoUrl!.isNotEmpty && mounted) {
          precacheImage(CachedNetworkImageProvider(_dbLogoUrl!), context)
              .catchError((_) {});
        }
      }
    }
    _fetchAppBranding();
  }

  Future<void> _fetchAppBranding() async {
    try {
      final res = await Supabase.instance.client
          .from('app_info')
          .select('app_name, tagline, tagline_en, tagline_zh, logo_url')
          .order('id')
          .limit(1)
          .maybeSingle();
      if (res != null) await AppBrandingCache.save(res);
      if (mounted && res != null) {
        setState(() {
          _dbAppName   = res['app_name'] as String?;
          _dbTaglineId = res['tagline'] as String?;
          _dbTaglineEn = res['tagline_en'] as String?;
          _dbTaglineZh = res['tagline_zh'] as String?;
          _dbLogoUrl   = res['logo_url'] as String?;
        });
        if (_dbLogoUrl != null && _dbLogoUrl!.isNotEmpty && mounted) {
          precacheImage(CachedNetworkImageProvider(_dbLogoUrl!), context)
              .catchError((_) {});
        }
      }
    } catch (e) {
      debugPrint('Error fetching app branding for login: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event != AuthChangeEvent.signedIn) return;
      final session = data.session;
      if (session == null) return;

      final String provider = session.user.appMetadata['provider'] ?? 'email';
      if (provider != 'google') return;

      if (!mounted) return;
      setState(() => isLoading = true);

      try {
        final userData = await Supabase.instance.client
            .from('User')
            .select('id_user, email, gambar_user, is_verificator, id_jabatan')
            .eq('email', session.user.email!)
            .maybeSingle();

        if (userData == null) {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            setState(() => isLoading = false);
            _showCustomDialog(getTxt('err_unknown'));
          }
          return;
        }

        final String? googleImage = session.user.userMetadata?['avatar_url']
                                 ?? session.user.userMetadata?['picture'];
        if ((userData['gambar_user'] == null || userData['gambar_user'] == '') &&
            googleImage != null) {
          await Supabase.instance.client
              .from('User')
              .update({'gambar_user': googleImage})
              .eq('id_user', userData['id_user']);
        }

        if (!mounted) return;

        final String? googleImg = userData['gambar_user'];
        if (googleImg != null && googleImg.isNotEmpty) {
          await precacheImage(CachedNetworkImageProvider(googleImg), context);
        }

        final int? jabatanGoogle = userData['id_jabatan'] as int?;

        if (jabatanGoogle == 6) {
          // ADMIN VIA GOOGLE
          int sTotalUsers = 0, sTotalLokasi = 0, sTotalKategori = 0;
          int sTotalTemuan = 0;
          try {
            final stats = await Future.wait([
              Supabase.instance.client.from('User').count(),
              Supabase.instance.client.from('lokasi').count(),
              Supabase.instance.client.from('kategoritemuan').count(),
              Supabase.instance.client.from('temuan').count(),
              Supabase.instance.client.from('temuan').count().eq('status_temuan', 'Belum'),
              Supabase.instance.client.from('temuan').count().eq('status_temuan', 'Selesai'),
              if (mounted)
              precacheImage(const AssetImage('assets/images/bgadmin.png'), context)
                  .catchError((_) async {}),
            ]);
            sTotalUsers    = stats[0] as int;
            sTotalLokasi   = stats[1] as int;
            sTotalKategori = stats[2] as int;
            sTotalTemuan   = stats[3] as int;
          } catch (_) {
            if (!mounted) return;
            await precacheImage(const AssetImage('assets/images/bgadmin.png'), context)
                .catchError((_) async {});
          }

          if (mounted) await warmupAdminFonts(context);
          if (!mounted) return;

          Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AdminShellScreen(
              initialUserName:      userData['nama'],
              initialUserImage:     userData['gambar_user'],
              initialTotalUsers:    sTotalUsers,
              initialTotalLokasi:   sTotalLokasi,
              initialTotalKategori: sTotalKategori,
              initialTotalTemuan:   sTotalTemuan,
              initialLang:          selectedLanguage,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        } else {
          // USER VIA GOOGLE
          if (!mounted) return;
          await warmupPointPopupFonts();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    });
  }

  // REMEMBER ME
  void _onRememberMeChanged(bool? value) async {
    final newVal = value ?? false;
    setState(() => isRememberMe = newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', newVal);
    if (!newVal) {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (widget.initialLang == null) {
        final savedLang = prefs.getString('lang');
        if (savedLang != null && _translations.containsKey(savedLang)) {
          selectedLanguage = savedLang;
        }
      }
      isRememberMe = prefs.getBool('remember_me') ?? false;
      if (isRememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  void _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', selectedLanguage);
    if (isRememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  void _showCustomDialog(String message) {
    const Color primaryColor = Color(0xFFEF4444);
    const Color iconBackground = Color(0xFFFFEBEB);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: primaryColor, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    getTxt('try_again'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                          width: 2),
                    ),
                    child: const Icon(Icons.mark_email_read_rounded,
                        color: Color(0xFF16A34A), size: 42),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2200),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  Future<List<Map<String, dynamic>>> _fetchPendingAuditsForLogin(
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
      debugPrint('Login pending audits error: $e');
      return [];
    }
  }

  void _submitForm() async {
    final email = _emailController.text.trim();
    final pass  = _passwordController.text.trim();

    if (email.isEmpty && pass.isEmpty) {
      _showCustomDialog(getTxt('err_email_pass')); return;
    } else if (email.isEmpty) {
      _showCustomDialog(getTxt('err_email')); return;
    } else if (pass.isEmpty) {
      _showCustomDialog(getTxt('err_pass')); return;
    }

    setState(() => isLoading = true);
    _saveCredentials();

    try {
      final AuthResponse? res = await _auth.signInWithEmail(email, pass);

      if (res == null || res.user == null) {
        _showCustomDialog(getTxt('err_wrong'));
        return;
      }

      final userId = res.user!.id;

      final results = await Future.wait([
        Supabase.instance.client
            .from('User')
            .select(
                'nama, poin, gambar_user, id_jabatan, id_unit, id_lokasi, '
                'id_subunit, id_area, is_verificator, is_visitor, is_pro_mode, '
                'is_blocked, unblock_requested, '
                'jabatan(nama_jabatan)')
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

      final bool isVerificator = userData['is_verificator'] as bool? ?? false;
      final int? idJabatan     = userData['id_jabatan'] as int?;
      final bool canShowVerifButton = isVerificator || idJabatan == 1 || idJabatan == 2 || idJabatan == 5;
      final bool isAdmin            = idJabatan == 6;

      final locationData = await _resolveLocationName(userData);

      if (!mounted) return;

      final String? imageToPreload = userData['gambar_user'];
      await Future.wait([
        precacheImage(const AssetImage('assets/images/logo1.png'), context)
            .catchError((_) {}),
        if (imageToPreload != null && imageToPreload.isNotEmpty)
          precacheImage(CachedNetworkImageProvider(imageToPreload), context)
              .catchError((_) {}),
      ]);

      int initialNotifCount  = 0;
      int initialMonthlyPoin = 0;
      bool initialIsPmVisible = true;
      List<Map<String, dynamic>> initialPendingAudits = [];
      try {
        final now          = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
        final startOfNext  = DateTime(now.year, now.month + 1, 1).toIso8601String();

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
          _fetchPendingAuditsForLogin(userId, selectedLanguage),
        ]);
        initialNotifCount  = preload[0] as int;
        final logList      = preload[1] as List<dynamic>;
        initialMonthlyPoin = logList.fold<int>(
          0, (sum, l) => sum + ((l['poin'] as num?)?.toInt() ?? 0),
        );
        final pmRow = preload[2] as Map<String, dynamic>?;
        initialIsPmVisible = pmRow?['setting_value'] as bool? ?? true;
        initialPendingAudits = preload[3] as List<Map<String, dynamic>>;
      } catch (_) {}

      if (!mounted) return;

      if (isAdmin) {
        int sTotalUsers = 0, sTotalLokasi = 0, sTotalKategori = 0;
        int sTotalTemuan = 0;
        try {
          final stats = await Future.wait([
            Supabase.instance.client.from('User').count(),
            Supabase.instance.client.from('lokasi').count(),
            Supabase.instance.client.from('kategoritemuan').count(),
            Supabase.instance.client.from('temuan').count(),
            Supabase.instance.client.from('temuan').count().eq('status_temuan', 'Belum'),
            Supabase.instance.client.from('temuan').count().eq('status_temuan', 'Selesai'),
            precacheImage(const AssetImage('assets/images/bgadmin.png'), context)
                .catchError((_) {}),
            GoogleFonts.pendingFonts([
              GoogleFonts.sourceCodePro(),
              GoogleFonts.poppins(),
              GoogleFonts.inter()
            ]).catchError((_) => <void>[]),
          ]);
          sTotalUsers    = stats[0] as int;
          sTotalLokasi   = stats[1] as int;
          sTotalKategori = stats[2] as int;
          sTotalTemuan   = stats[3] as int;
        } catch (_) {
          if (!mounted) return;
          await precacheImage(const AssetImage('assets/images/bgadmin.png'), context)
              .catchError((_) async {});
        }

        if (mounted) await warmupAdminFonts(context);
        if (!mounted) return;

        Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => AdminShellScreen(
                initialUserName:      userData['nama'],
                initialUserImage:     userData['gambar_user'],
                initialTotalUsers:    sTotalUsers,
                initialTotalLokasi:   sTotalLokasi,
                initialTotalKategori: sTotalKategori,
                initialTotalTemuan:   sTotalTemuan,
                initialLang:          selectedLanguage,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
      } else {
        if (!mounted) return;
        await warmupPointPopupFonts();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              initialUserName:      userData['nama'],
              initialUserPoin:      userData['poin'],
              initialUserImage:     userData['gambar_user'],
              initialUserRole:      userData['jabatan']?['nama_jabatan'],
              initialUserLocation:  locationData['name'],
              initialUserLocationLevel: locationData['level'],
              initialLatestLog:     latestLog,
              initialUserJabatanId: idJabatan,
              initialIsVerificator: canShowVerifButton,
              initialNotifCount:    initialNotifCount,
              initialMonthlyPoin:   initialMonthlyPoin,
              initialIsProMode:     userData['is_pro_mode'] as bool? ?? false,
              initialIsVisitorMode: userData['is_visitor'] as bool? ?? false,
              initialIsPreventiveMaintenanceVisible: initialIsPmVisible,
              initialPendingAudits: initialPendingAudits,
              initialIsBlocked: userData['is_blocked'] as bool? ?? false,
              initialUnblockRequested: userData['unblock_requested'] as bool? ?? false,
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        _showCustomDialog(getTxt('err_wrong'));
      } else if (msg.contains('email not confirmed')) {
        _showCustomDialog('Email belum dikonfirmasi!');
      } else {
        _showCustomDialog('Gagal Login: ${e.message}');
      }
    } catch (_) {
      _showCustomDialog('Terjadi kesalahan sistem saat login.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Stack(
        children: [
          Positioned(
            top: -80, left: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1976D2).withValues(alpha:0.12),
              ),
            ),
          ),
          Positioned(
            top: -30, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF42A5F5).withValues(alpha:0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 120, right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withValues(alpha:0.08),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      // LANG PICKER
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => _showLanguagePicker(),
                            child: _buildLangButton(),
                          ),
                        ),
                      ),

                      // LOGO
                      SizedBox(
                        height: size.height * 0.22,
                        width: double.infinity,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.elasticOut,
                            builder: (_, v, child) => Transform.scale(
                              scale: v.clamp(0.0, 1.0),
                              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                            ),
                            child: (_dbLogoUrl != null && _dbLogoUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: _dbLogoUrl!,
                                    height: size.height * 0.13,
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) => Image.asset(
                                      'assets/images/logo1.png',
                                      height: size.height * 0.13,
                                      fit: BoxFit.contain,
                                    ),
                                    errorWidget: (_, __, ___) => Image.asset(
                                      'assets/images/logo1.png',
                                      height: size.height * 0.13,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/logo1.png',
                                    height: size.height * 0.13,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1976D2).withValues(alpha:0.3),
                                            blurRadius: 16,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.shield, color: Colors.white, size: 42),
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.92),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                                border: Border.all(
                                  color: const Color(0xFF90CAF9).withValues(alpha:0.6),
                                  width: 1.2,
                                ),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                24, 24, 24,
                                MediaQuery.of(context).viewInsets.bottom + 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      getTxt('welcome'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 26, fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1D72F3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      _brandTaglineFull,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12, fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1565C0).withValues(alpha:0.75),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  _buildLabel(getTxt('email_label'), icon: Icons.email_outlined),
                                  _buildTextField(
                                    hint: getTxt('email_hint'),
                                    controller: _emailController,
                                    isPassword: false,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildLabel(getTxt('pass_label'), icon: Icons.lock_outline),
                                  _buildTextField(
                                    hint: '••••••••',
                                    controller: _passwordController,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 10),

                                  // REMEMBER ME + FORGOT PASSWORD
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 22, height: 22,
                                              child: Checkbox(
                                                value: isRememberMe,
                                                activeColor: const Color(0xFF1976D2),
                                                side: const BorderSide(color: Color(0xFF90CAF9), width: 1.5),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(4)),
                                                onChanged: _onRememberMeChanged,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                getTxt('remember_me'),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12, fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF1D72F3),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          if (_emailController.text.isNotEmpty) {
                                            _auth.resetPassword(_emailController.text);
                                            _showSuccessDialog(getTxt('reset_sent'));
                                          } else {
                                            _showCustomDialog(getTxt('fill_email_reset'));
                                          }
                                        },
                                        child: Text(
                                          getTxt('forgot_pass'),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12, fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1D72F3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // SIGN IN BUTTON
                                  SizedBox(
                                    width: double.infinity, height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1D72F3),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14)),
                                        shadowColor: const Color(0xFF1D72F3).withValues(alpha:0.4),
                                      ),
                                      onPressed: isLoading ? null : _submitForm,
                                      child: Text(
                                        getTxt('sign_in'),
                                        style: GoogleFonts.poppins(
                                            fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),

                                  // const SizedBox(height: 20),

                                  // // Divider
                                  // Row(children: [
                                  //   Expanded(
                                  //     child: Divider(
                                  //         color: const Color(0xFF90CAF9).withValues(alpha:0.5))),
                                  //   Padding(
                                  //     padding: const EdgeInsets.symmetric(horizontal: 12),
                                  //     child: Text(
                                  //       getTxt('or_login'),
                                  //       style: const TextStyle(
                                  //           fontSize: 11, color: Color(0xFF1565C0),
                                  //           fontWeight: FontWeight.w600),
                                  //     ),
                                  //   ),
                                  //   Expanded(
                                  //     child: Divider(
                                  //         color: const Color(0xFF90CAF9).withValues(alpha:0.5))),
                                  // ]),

                                  // const SizedBox(height: 14),

                                  // // Tombol Google
                                  // SizedBox(
                                  //   width: double.infinity, height: 50,
                                  //   child: OutlinedButton.icon(
                                  //     style: OutlinedButton.styleFrom(
                                  //       foregroundColor: const Color(0xFF1565C0),
                                  //       side: const BorderSide(
                                  //           color: Color(0xFF90CAF9), width: 1.2),
                                  //       backgroundColor: Colors.white,
                                  //       shape: RoundedRectangleBorder(
                                  //           borderRadius: BorderRadius.circular(14)),
                                  //     ),
                                  //     onPressed: isLoading ? null : () => _auth.signInWithGoogle(),
                                  //     icon: Image.asset(
                                  //       'assets/images/Google.svg',
                                  //       height: 22,
                                  //       errorBuilder: (_, __, ___) => const Icon(
                                  //           Icons.g_mobiledata,
                                  //           size: 28,
                                  //           color: Color(0xFF1976D2)),
                                  //     ),
                                  //     label: Text(
                                  //       getTxt('google'),
                                  //       style: const TextStyle(
                                  //           fontWeight: FontWeight.w700, fontSize: 14),
                                  //     ),
                                  //   ),
                                  // ),

                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    const langs = [
      {'code': 'EN', 'flag': '🇺🇸', 'label': 'English'},
      {'code': 'ID', 'flag': '🇮🇩', 'label': 'Indonesia'},
      {'code': 'ZH', 'flag': '🇨🇳', 'label': '中文'},
    ];
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D72F3).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        getTxt('select_language'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: const Color(0xFF1D72F3),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF1D72F3)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  children: langs.map((l) {
                    final isSelected = selectedLanguage == l['code'];
                    return GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('lang', l['code']!);
                        if (mounted) setState(() => selectedLanguage = l['code']!);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1D72F3).withValues(alpha: 0.08)
                              : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1D72F3)
                                : const Color(0xFFE0E7FF),
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE0E7FF)),
                              ),
                              child: Text(l['flag']!, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                l['label']!,
                                style: GoogleFonts.poppins(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 15,
                                  color: isSelected
                                      ? const Color(0xFF1D72F3)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF1D72F3), size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton() {
    const flagMap = {'EN': '🇺🇸', 'ID': '🇮🇩', 'ZH': '🇨🇳'};
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D72F3).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flagMap[selectedLanguage] ?? '🇺🇸', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            selectedLanguage,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D72F3),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF1D72F3)),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1D72F3)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1D72F3),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required bool isPassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isFilled = controller.text.isNotEmpty;

    final String displayHint = isPassword
        ? (isPasswordVisible ? getTxt('pass_hint') : hint)
        : hint;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withValues(alpha:0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFilled ? const Color(0xFF1D72F3) : const Color(0xFF90CAF9).withValues(alpha:0.8),
          width: 1.2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
        obscureText: isPassword && !isPasswordVisible,
        onFieldSubmitted: isPassword ? (_) => _submitForm() : null,
        style: GoogleFonts.poppins( color: Color(0xFF1D72F3), fontWeight: FontWeight.w700, fontSize: 14),
        decoration: InputDecoration(
          hintText: displayHint,
          hintStyle: GoogleFonts.poppins(
              color: Color(0xFF64748B),
              fontSize: 14, fontWeight: FontWeight.w700),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: isFilled ? const Color(0xFF1D72F3) : const Color(0xFF5B7A9D),
                    size: 23,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}