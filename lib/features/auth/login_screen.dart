import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'dart:async';
import '../../core/services/auth_service.dart';
import '../admin/admin_home_screen.dart';
import '../user/home/home_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();

  StreamSubscription? _authStateSubscription;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isRememberMe = false;
  bool isLoading = false;
  bool isPasswordVisible = false;

  // ─── Localisation ───────────────────────────────────────────────────────────
  String selectedLanguage = 'EN';

  final Map<String, Map<String, String>> translations = {
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
    },
  };

  String getTxt(String key) => translations[selectedLanguage]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final String provider =
            session.user.appMetadata['provider'] ?? 'email';

        if (provider == 'google') {
          if (!mounted) return;
          setState(() => isLoading = true);

          try {
            final userData = await Supabase.instance.client
                .from('User')
                .select(
                    'id_user, email, gambar_user, is_verificator, id_jabatan')
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

            final String? googleImage =
                session.user.userMetadata?['avatar_url'] ??
                    session.user.userMetadata?['picture'];

            if ((userData['gambar_user'] == null ||
                    userData['gambar_user'] == '') &&
                googleImage != null) {
              await Supabase.instance.client.from('User').update(
                  {'gambar_user': googleImage}).eq('id_user', userData['id_user']);
            }

            if (mounted) {
              final String? googleImg = userData['gambar_user'];
              if (googleImg != null && googleImg.isNotEmpty) {
                await precacheImage(
                    CachedNetworkImageProvider(googleImg), context);
              }
              final int? jabatanGoogle = userData['id_jabatan'] as int?;
              if (jabatanGoogle == 6) {
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
                    precacheImage(
                            const AssetImage('assets/images/bgadmin.png'),
                            context)
                        .catchError((_) {}),
                  ]);
                  sTotalUsers = statsResults[0] as int;
                  sTotalLokasi = statsResults[1] as int;
                  sTotalKategori = statsResults[2] as int;
                  sTotalTemuan = statsResults[3] as int;
                  sTemuanBelum = statsResults[4] as int;
                  sTemuanSelesai = statsResults[5] as int;
                } catch (_) {
                  await precacheImage(
                          const AssetImage('assets/images/bgadmin.png'),
                          context)
                      .catchError((_) {});
                }
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminHomeScreen(
                      initialUserName: userData['nama'],
                      initialUserImage: userData['gambar_user'],
                      initialTotalUsers: sTotalUsers,
                      initialTotalLokasi: sTotalLokasi,
                      initialTotalKategori: sTotalKategori,
                      initialTotalTemuan: sTotalTemuan,
                      initialTemuanBelum: sTemuanBelum,
                      initialTemuanSelesai: sTemuanSelesai,
                    ),
                  ),
                );
              } else {
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HomeScreen()),
                );
              }
            }
          } catch (e) {
            if (mounted) setState(() => isLoading = false);
          }
        }
      }
    });
  }

  // ─── Remember Me – diperbaiki ────────────────────────────────────────────────
  // Simpan langsung saat user toggle, bukan hanya saat submit
  void _onRememberMeChanged(bool? value) async {
    final newVal = value ?? false;
    setState(() => isRememberMe = newVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', newVal);
    if (!newVal) {
      // Hapus kredensial tersimpan langsung ketika dinonaktifkan
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final savedLang = prefs.getString('lang');
      if (savedLang != null && translations.containsKey(savedLang)) {
        selectedLanguage = savedLang;
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 255, 25, 25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      getTxt('try_again'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitForm() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty && pass.isEmpty) {
      _showCustomDialog(getTxt('err_email_pass'));
      return;
    } else if (email.isEmpty) {
      _showCustomDialog(getTxt('err_email'));
      return;
    } else if (pass.isEmpty) {
      _showCustomDialog(getTxt('err_pass'));
      return;
    }

    setState(() => isLoading = true);
    _saveCredentials();

    String hashedPass = pass;
    try {
      hashedPass = await _auth.hashPassword(email, pass);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showCustomDialog('Terjadi kesalahan enkripsi keamanan password.');
      return;
    }

    try {
      final AuthResponse? res = await _auth.signInWithEmail(email, hashedPass);

      if (res != null && res.user != null) {
        final userId = res.user!.id;

        final results = await Future.wait([
          Supabase.instance.client
              .from('User')
              .select(
                  'nama, poin, gambar_user, id_jabatan, id_unit, id_lokasi, id_subunit, id_area, is_verificator, jabatan(nama_jabatan)')
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

        final bool isVerificator =
            userData['is_verificator'] as bool? ?? false;
        final int? idJabatan = userData['id_jabatan'] as int?;
        final bool canShowVerifButton =
            isVerificator || idJabatan == 1 || idJabatan == 5;

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

        if (mounted) {
          final List<Future> precacheTasks = [
            precacheImage(
                    const AssetImage('assets/images/logo1.png'), context)
                .catchError((_) {}),
          ];
          final String? imageToPreload = userData['gambar_user'];
          if (imageToPreload != null && imageToPreload.isNotEmpty) {
            precacheTasks.add(
              precacheImage(
                      CachedNetworkImageProvider(imageToPreload), context)
                  .catchError((_) {}),
            );
          }
          await Future.wait(precacheTasks);

          int initialNotifCount = 0;
          int initialMonthlyPoin = 0;
          try {
            final now = DateTime.now();
            final startOfMonth =
                DateTime(now.year, now.month, 1).toIso8601String();
            final startOfNextMonth =
                DateTime(now.year, now.month + 1, 1).toIso8601String();

            final preloadResults = await Future.wait([
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

            initialNotifCount = preloadResults[0] as int;
            final logList = preloadResults[1] as List<dynamic>;
            int total = 0;
            for (final log in logList) {
              total += ((log['poin'] as num?)?.toInt() ?? 0);
            }
            initialMonthlyPoin = total;
          } catch (_) {}

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
                precacheImage(
                        const AssetImage('assets/images/bgadmin.png'),
                        context)
                    .catchError((_) {}),
              ]);
              sTotalUsers = statsResults[0] as int;
              sTotalLokasi = statsResults[1] as int;
              sTotalKategori = statsResults[2] as int;
              sTotalTemuan = statsResults[3] as int;
              sTemuanBelum = statsResults[4] as int;
              sTemuanSelesai = statsResults[5] as int;
            } catch (_) {
              await precacheImage(
                      const AssetImage('assets/images/bgadmin.png'),
                      context)
                  .catchError((_) {});
            }
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminHomeScreen(
                  initialUserName: userData['nama'],
                  initialUserImage: userData['gambar_user'],
                  initialTotalUsers: sTotalUsers,
                  initialTotalLokasi: sTotalLokasi,
                  initialTotalKategori: sTotalKategori,
                  initialTotalTemuan: sTotalTemuan,
                  initialTemuanBelum: sTemuanBelum,
                  initialTemuanSelesai: sTemuanSelesai,
                ),
              ),
            );
          } else {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  initialUserName: userData['nama'],
                  initialUserPoin: userData['poin'],
                  initialUserImage: userData['gambar_user'],
                  initialUserRole: userData['jabatan']?['nama_jabatan'],
                  initialUserLocation: locationName,
                  initialLatestLog: latestLog,
                  initialUserJabatanId: idJabatan,
                  initialIsVerificator: canShowVerifButton,
                  initialNotifCount: initialNotifCount,
                  initialMonthlyPoin: initialMonthlyPoin,
                ),
              ),
            );
          }
        }
      } else {
        _showCustomDialog(getTxt('err_wrong'));
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        _showCustomDialog(getTxt('err_wrong'));
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
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

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  DropdownMenuItem<String> _buildDropdownItem(
      String value, String flag, String label) {
    return DropdownMenuItem(
      value: value,
      child: Row(children: [
        Text(flag, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ]),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Stack(
        children: [
          // ── Blob biru latar ──────────────────────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1976D2).withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF42A5F5).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withOpacity(0.08),
              ),
            ),
          ),

          // ── Konten utama ─────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      // Language picker
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              final langs = [
                                {'code': 'EN', 'flag': '🇬🇧', 'label': 'English'},
                                {'code': 'ID', 'flag': '🇮🇩', 'label': 'Indonesia'},
                                {'code': 'ZH', 'flag': '🇨🇳', 'label': '中文'},
                              ];
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => Container(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40, height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Select Language',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ...langs.map((l) {
                                        final isSelected = selectedLanguage == l['code'];
                                        return GestureDetector(
                                          onTap: () async {
                                            final prefs = await SharedPreferences.getInstance();
                                            await prefs.setString('lang', l['code']!);
                                            if (mounted) {
                                              setState(() => selectedLanguage = l['code']!);
                                            }
                                            if (ctx.mounted) Navigator.pop(ctx);
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 18, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF1976D2).withOpacity(0.08)
                                                  : Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF1976D2)
                                                    : Colors.grey.shade200,
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(l['flag']!,
                                                    style: const TextStyle(fontSize: 24)),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Text(
                                                    l['label']!,
                                                    style: TextStyle(
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      fontSize: 15,
                                                      color: isSelected
                                                          ? const Color(0xFF1976D2)
                                                          : const Color(0xFF1565C0),
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(Icons.check_circle_rounded,
                                                      color: Color(0xFF1976D2), size: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF90CAF9), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedLanguage == 'EN'
                                        ? '🇬🇧'
                                        : selectedLanguage == 'ID'
                                            ? '🇮🇩'
                                            : '🇨🇳',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    selectedLanguage,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 18, color: Color(0xFF1565C0)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Ilustrasi & Logo ─────────────────────────────────────
                      SizedBox(
                        height: size.height * 0.22,
                        width: double.infinity,
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.elasticOut,
                            builder: (context, v, child) => Transform.scale(
                              scale: v.clamp(0.0, 1.0),
                              child: Opacity(
                                opacity: v.clamp(0.0, 1.0),
                                child: child,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/logo1.png',
                              height: size.height * 0.13,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Container(
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
                                      color: const Color(0xFF1976D2).withOpacity(0.3),
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

                      // ── Glass card Form ──────────────────────────────────────
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(36)),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(36)),
                                border: Border.all(
                                    color: const Color(0xFF90CAF9)
                                        .withOpacity(0.6),
                                    width: 1.2),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                  24,
                                  24,
                                  24,
                                  MediaQuery.of(context).viewInsets.bottom +
                                      24),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Center(
                                    child: Text(
                                      getTxt('welcome'),
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      getTxt('tagline_login'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1565C0)
                                            .withOpacity(0.75),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Email
                                  _buildLabel(getTxt('email_label')),
                                  _buildTextField(
                                    hint: getTxt('email_hint'),
                                    controller: _emailController,
                                    icon: Icons.email_outlined,
                                    isPassword: false,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password
                                  _buildLabel(getTxt('pass_label')),
                                  _buildTextField(
                                    hint: '••••••••',
                                    controller: _passwordController,
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                  ),
                                  const SizedBox(height: 10),

                                  // Remember Me + Forgot Password
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: Checkbox(
                                              value: isRememberMe,
                                              activeColor: const Color(
                                                  0xFF1976D2),
                                              side: const BorderSide(
                                                  color: Color(0xFF90CAF9),
                                                  width: 1.5),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4)),
                                              onChanged:
                                                  _onRememberMeChanged,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            getTxt('remember_me'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1565C0),
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (_emailController
                                              .text.isNotEmpty) {
                                            _auth.resetPassword(
                                                _emailController.text);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  getTxt('reset_sent')),
                                              backgroundColor:
                                                  const Color(0xFF1976D2),
                                            ));
                                          } else {
                                            _showCustomDialog(getTxt(
                                                'fill_email_reset'));
                                          }
                                        },
                                        child: Text(
                                          getTxt('forgot_pass'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Tombol Sign In
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1976D2),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14)),
                                        shadowColor:
                                            const Color(0xFF1976D2).withOpacity(0.4),
                                      ),
                                      onPressed: isLoading ? null : _submitForm,
                                      child: Text(
                                        getTxt('sign_in'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Divider
                                  Row(children: [
                                    Expanded(
                                        child: Divider(
                                            color: const Color(0xFF90CAF9)
                                                .withOpacity(0.5))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        getTxt('or_login'),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF1565C0),
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: const Color(0xFF90CAF9)
                                                .withOpacity(0.5))),
                                  ]),

                                  const SizedBox(height: 14),

                                  // Google Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF1565C0),
                                        side: const BorderSide(
                                            color: Color(0xFF90CAF9),
                                            width: 1.2),
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              await _auth.signInWithGoogle();
                                            },
                                      icon: Image.asset(
                                        'assets/images/Google.svg',
                                        height: 22,
                                        errorBuilder: (c, e, s) => const Icon(
                                            Icons.g_mobiledata,
                                            size: 28,
                                            color: Color(0xFF1976D2)),
                                      ),
                                      label: Text(
                                        getTxt('google'),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ),

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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0D47A1),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isPassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isFilled = controller.text.isNotEmpty;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFilled
              ? const Color(0xFF1976D2)
              : const Color(0xFF90CAF9).withOpacity(0.8),
          width: 1.2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction:
            isPassword ? TextInputAction.done : TextInputAction.next,
        obscureText: isPassword ? !isPasswordVisible : false,
        onFieldSubmitted: isPassword ? (_) => _submitForm() : null,
        style: const TextStyle(
          color: Color(0xFF0D47A1),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF90CAF9).withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon,
              color: isFilled
                  ? const Color(0xFF1976D2)
                  : const Color(0xFF90CAF9),
              size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: isFilled
                        ? const Color(0xFF1976D2)
                        : const Color(0xFF90CAF9),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}