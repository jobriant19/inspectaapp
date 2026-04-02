import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'dart:ui';
import 'auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  
  // Controller Form
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedJabatan; 
  
  bool isLogin = true; 
  bool isRememberMe = false; 
  bool isLoading = false;
  bool isPasswordVisible = false;

  // Variabel untuk kekuatan password
  String _passStrengthText = "";
  Color _passStrengthColor = Colors.transparent;

  // --- FITUR LOKALISASI (TRANSLATE) ---
  String selectedLanguage = 'EN';
  
  final Map<String, Map<String, String>> translations = {
    'EN': {
      'login': 'Login',
      'signup': 'Sign Up',
      'welcome': 'Welcome Back!',
      'tagline_login': 'Inspecta: Make Your Discipline day!',
      'get_started': 'Get Started Free',
      'tagline_signup': 'Free Forever. No Credit Card Needed',
      'email_label': 'Email Address',
      'email_hint': 'Email',
      'name_label': 'Your Name',
      'name_hint': '@yourname',
      'pass_label': 'Password',
      'remember_me': 'Remember Me',
      'forgot_pass': 'Forgot Password?',
      'or_login': 'Or continue with',
      'or_signup': 'Or sign up with',
      'google': 'Login with Google',
      'weak': 'Weak',
      'medium': 'Medium',
      'strong': 'Strong',
      'err_email': 'Fill E-mail First',
      'err_pass': 'Fill Password First',
      'err_email_pass': 'Fill E-mail & Password First',
      'err_name': 'Fill Name First',
      'err_wrong': 'Wrong Email or Password!',
      'err_len': 'Password must be at least 6 characters',
      'try_again': 'Try Again',
      'reset_sent': 'Reset link sent to your email',
      'fill_email_reset': 'Fill your email to reset password!',
      'role_label': 'Job Title',
      'role_hint': 'Select Job Title',
      'err_role': 'Select Job Title First',
    },
    'ID': {
      'login': 'Masuk',
      'signup': 'Daftar',
      'welcome': 'Selamat Datang!',
      'tagline_login': 'Inspecta: Jadikan Harimu Disiplin!',
      'get_started': 'Mulai Gratis',
      'tagline_signup': 'Gratis Selamanya. Tanpa Kartu Kredit',
      'email_label': 'Alamat Email',
      'email_hint': 'Email',
      'name_label': 'Nama Anda',
      'name_hint': '@namaanda',
      'pass_label': 'Kata Sandi',
      'remember_me': 'Ingat Saya',
      'forgot_pass': 'Lupa Sandi?',
      'or_login': 'Atau masuk dengan',
      'or_signup': 'Atau daftar dengan',
      'google': 'Masuk dengan Google',
      'weak': 'Lemah',
      'medium': 'Sedang',
      'strong': 'Kuat',
      'err_email': 'Isi E-mail Terlebih Dahulu',
      'err_pass': 'Isi Password Terlebih Dahulu',
      'err_email_pass': 'Isi E-mail & Password Terlebih Dahulu',
      'err_name': 'Isi Nama Terlebih Dahulu',
      'err_wrong': 'Email atau Password Salah!',
      'err_len': 'Password minimal 6 karakter',
      'try_again': 'Coba Lagi',
      'reset_sent': 'Link reset dikirim ke email Anda',
      'fill_email_reset': 'Isi email dulu untuk mereset password!',
      'role_label': 'Jabatan',
      'role_hint': 'Pilih Jabatan',
      'err_role': 'Pilih Jabatan Terlebih Dahulu',
    },
    'ZH': {
      'login': '登录',
      'signup': '注册',
      'welcome': '欢迎回来！',
      'tagline_login': 'Inspecta: 让您的纪律日!',
      'get_started': '免费开始',
      'tagline_signup': '永久免费。无需信用卡',
      'email_label': '电子邮件地址',
      'email_hint': '电子邮件',
      'name_label': '您的名字',
      'name_hint': '@您的名字',
      'pass_label': '密码',
      'remember_me': '记住我',
      'forgot_pass': '忘记密码？',
      'or_login': '或继续使用',
      'or_signup': '或注册使用',
      'google': '使用Google登录',
      'weak': '弱',
      'medium': '中',
      'strong': '强',
      'err_email': '请先填写电子邮件',
      'err_pass': '请先填写密码',
      'err_email_pass': '请先填写电子邮件和密码',
      'err_name': '请先填写姓名',
      'err_wrong': '邮箱或密码错误！',
      'err_len': '密码至少需要6个字符',
      'try_again': '重试',
      'reset_sent': '重置链接已发送到您的邮箱',
      'fill_email_reset': '请先填写您的邮箱以重置密码！',
      'role_label': '职位',
      'role_hint': '选择职位',
      'err_role': '请先选择职位',
    }
  };

  String getTxt(String key) => translations[selectedLanguage]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _passwordController.addListener(_checkPasswordStrength);
  }

  // FITUR: Pengecekan Password cerdas (Keragaman Karakter)
  void _checkPasswordStrength() {
    if (isLogin) return;
    String pass = _passwordController.text;
    setState(() {
      if (pass.isEmpty) {
        _passStrengthText = "";
        _passStrengthColor = Colors.transparent;
      } else {
        bool hasLower = RegExp(r'[a-z]').hasMatch(pass);
        bool hasUpper = RegExp(r'[A-Z]').hasMatch(pass);
        bool hasDigit = RegExp(r'\d').hasMatch(pass);
        bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass);

        int strengthScore = 0;
        if (pass.length >= 6) strengthScore++;
        if (pass.length >= 8) strengthScore++;
        if (hasLower && hasUpper) strengthScore++;
        if (hasDigit) strengthScore++;
        if (hasSpecial) strengthScore++;

        if (strengthScore <= 2) {
          _passStrengthText = getTxt('weak');
          _passStrengthColor = const Color(0xFFFF4B4B); 
        } else if (strengthScore <= 4) {
          _passStrengthText = getTxt('medium');
          _passStrengthColor = Colors.orangeAccent; 
        } else {
          _passStrengthText = getTxt('strong');
          _passStrengthColor = const Color(0xFF4CD978); 
        }
      }
    });
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isRememberMe = prefs.getBool('remember_me') ?? false;
      if (isRememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  void _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', selectedLanguage); 
    if (isRememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  // FITUR: Pop-Up Kustom
  void _showCustomDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFFFF4B4B), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity, height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9E4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(getTxt('try_again'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitForm() async {
    String email = _emailController.text.trim();
    String pass = _passwordController.text.trim();
    String name = _nameController.text.trim();

    if (email.isEmpty && pass.isEmpty) {
      _showCustomDialog(getTxt('err_email_pass')); return;
    } else if (email.isEmpty) {
      _showCustomDialog(getTxt('err_email')); return;
    } else if (pass.isEmpty) {
      _showCustomDialog(getTxt('err_pass')); return;
    } else if (!isLogin) {
      if (name.isEmpty) {
        _showCustomDialog(getTxt('err_name')); return;
      } else if (_selectedJabatan == null) {
        _showCustomDialog(getTxt('err_role')); return;
      } else if (pass.length < 6) {
        _showCustomDialog(getTxt('err_len')); return;
      }
    }

    setState(() => isLoading = true);
    try {
      _saveCredentials(); // Simpan bahasa dan remember me

      if (isLogin) {
        await _auth.signInWithEmail(email, pass);
        // Log log_login (opsional)
        try {
          final user = Supabase.instance.client.auth.currentUser;
          if(user != null) {
            await Supabase.instance.client.from('User').update({'log_login': DateTime.now().toIso8601String()}).eq('id_user', user.id);
          }
        } catch(e){}
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        // Proses Sign Up
        final AuthResponse res = await Supabase.instance.client.auth.signUp(email: email, password: pass);
        
        if (res.user != null) {
          // Mapping jabatan string ke ID sesuai script SQL
          int idJabatan = 4; // Default Staff
          if(_selectedJabatan == 'Eksekutif') idJabatan = 1;
          if(_selectedJabatan == 'Manager') idJabatan = 2;
          if(_selectedJabatan == 'Kasie') idJabatan = 3;

          // INSERT KE TABEL User
          await Supabase.instance.client.from('User').insert({
            'id_user': res.user!.id, // Menggunakan ID yang sama dari Auth
            'nama': name,
            'email': email,
            'pass': pass,
            'id_jabatan': idJabatan,
            'poin': 0,
            'is_visitor': false,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      _showCustomDialog(getTxt('err_wrong'));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // KOMPONEN: Radial Glow Background
  Widget _buildRadialGlow(double? top, double? left, double? right, double? bottom, Color centerColor, Color edgeColor, double size) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [centerColor.withOpacity(0.6), edgeColor.withOpacity(0.0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCBE5F6), 
      body: Stack(
        children: [
          // --- 1. RADIAL EFEK BACKGROUND ---
          _buildRadialGlow(null, -50, null, 100, const Color(0xFF4CD978), const Color(0xFFD25A63), 300),
          _buildRadialGlow(null, null, -50, -50, const Color(0xFF00B5E4), const Color(0xFF360060), 350),
          _buildRadialGlow(-50, null, -50, null, const Color(0xFFB379DF), const Color(0xFF360060), 250),

          // --- 2. KONTEN UTAMA ---
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false, 
                  child: Column(
                    children: [
                      // Dropdown Bahasa
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0, top: 10.0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            height: 35,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButton<String>(
                              value: selectedLanguage,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                              items: [
                                _buildDropdownItem('EN', '🇬🇧', 'English'),
                                _buildDropdownItem('ID', '🇮🇩', 'Indonesia'),
                                _buildDropdownItem('ZH', '🇨🇳', '中文'),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedLanguage = value!;
                                  _checkPasswordStrength(); 
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      // --- AREA ILUSTRASI & ANIMASI CUBE ---
                      SizedBox(
                        height: 210,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Cube Kiri Atas (Tarik dari assets)
                            Positioned(
                              top: 20, left: 40,
                              child: _buildEntranceAnim(
                                child: Image.asset(
                                  'assets/images/topcube.png', 
                                  width: 55, 
                                  errorBuilder: (c,e,s) => const Icon(Icons.view_in_ar, color: Colors.amber, size: 30) // Fallback jika gambar belum ada
                                ),
                                delay: 200,
                              ),
                            ),
                            // Cube Kanan Bawah (Tarik dari assets)
                            Positioned(
                              bottom: 30, right: 1,
                              child: _buildEntranceAnim(
                                child: Image.asset(
                                  'assets/images/bottomcube.png', 
                                  width: 45, 
                                  errorBuilder: (c,e,s) => const Icon(Icons.view_in_ar, color: Colors.pinkAccent, size: 25)
                                ),
                                delay: 400,
                              ),
                            ),

                            // Ilustrasi Utama (Animasi Toggle)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
                                  child: FadeTransition(opacity: animation, child: child),
                                );
                              },
                              child: isLogin 
                                  ? Image.asset(
                                      'assets/images/login_illustration.png', 
                                      key: const ValueKey<bool>(true), 
                                      height: 190, fit: BoxFit.contain,
                                    )
                                  : Row(
                                      key: const ValueKey<bool>(false),
                                      children: [
                                        // Area Kiri: Logo Aplikasi
                                        Expanded(
                                          flex: 4, 
                                          child: Container(
                                            alignment: Alignment.centerRight, // Mendorong logo mentok ke kanan
                                            padding: const EdgeInsets.only(right: 5), // Mendekatkan jarak dengan ilustrasi
                                            child: Image.asset(
                                              'assets/images/logo.png',
                                              width: 180, // Logo diperbesar secara signifikan
                                              errorBuilder: (c,e,s) => Icon(Icons.shield_outlined, size: 70, color: Colors.blue.shade800), // Fallback
                                            ),
                                          )
                                        ),
                                        // Area Kanan: Ilustrasi Sign Up
                                        Expanded(
                                          flex: 5,
                                          child: Image.asset(
                                            'assets/images/signup_illustration.png', 
                                            height: 190, 
                                            fit: BoxFit.contain, 
                                            alignment: Alignment.centerLeft, // Mendekatkan ilustrasi mentok ke kiri (bertemu dengan logo)
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // --- FORM Glassmorph ---
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25), 
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TAB LOGIN / SIGN UP
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildTabButton(getTxt('login'), true),
                                      const SizedBox(width: 40),
                                      _buildTabButton(getTxt('signup'), false),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Tagline
                                  Center(
                                    child: Text(
                                      isLogin ? getTxt('welcome') : getTxt('get_started'),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        shadows: [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))]
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      isLogin ? getTxt('tagline_login') : getTxt('tagline_signup'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // 1. FORM EMAIL
                                  _buildInputLabel(getTxt('email_label')),
                                  _buildGlassTextField(
                                    hint: getTxt('email_hint'),
                                    controller: _emailController,
                                    icon: Icons.email_outlined,
                                    isPassword: false,
                                  ),
                                  
                                  // 2. FORM NAME 
                                  if (!isLogin) ...[
                                    const SizedBox(height: 15),
                                    _buildInputLabel(getTxt('name_label')),
                                    _buildGlassTextField(
                                      hint: getTxt('name_hint'),
                                      controller: _nameController,
                                      icon: Icons.person_outline,
                                      isPassword: false,
                                    ),

                                    const SizedBox(height: 15),
                                    // 3. FORM ROLE
                                    _buildInputLabel(getTxt('role_label')),
                                    Container(
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB6E3EF).withOpacity(0.55), 
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.0), 
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          dropdownColor: const Color(0xFFB6E3EF),
                                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                          value: _selectedJabatan,
                                          hint: Text(getTxt('role_hint'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                          items: ['Eksekutif', 'Manager', 'Kasie', 'Staff'].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                            );
                                          }).toList(),
                                          onChanged: (newValue) {
                                            setState(() { _selectedJabatan = newValue; });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 15),
                
                                  // 4. FORM PASSWORD
                                  _buildInputLabel(getTxt('pass_label')),
                                  _buildGlassTextField(
                                    hint: "••••••••",
                                    controller: _passwordController,
                                    icon: Icons.key_outlined,
                                    isPassword: true,
                                  ),

                                  const SizedBox(height: 8),

                                  // LUPA PASSWORD & REMEMBER ME
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24, height: 24,
                                            child: Checkbox(
                                              value: isRememberMe,
                                              activeColor: const Color(0xFF00C9E4),
                                              side: const BorderSide(color: Colors.black54),
                                              onChanged: (value) => setState(() => isRememberMe = value!),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(getTxt('remember_me'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        ],
                                      ),
                                      if (isLogin)
                                        GestureDetector(
                                          onTap: () {
                                            if(_emailController.text.isNotEmpty){
                                              _auth.resetPassword(_emailController.text);
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getTxt('reset_sent')), backgroundColor: Colors.green));
                                            } else {
                                              _showCustomDialog(getTxt('fill_email_reset'));
                                            }
                                          },
                                          child: Text(
                                            getTxt('forgot_pass'),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black87),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 25),

                                  // TOMBOL LOGIN / SIGN UP 
                                  Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF00C9E4), Color(0xFF42E27A)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF42E27A).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                                      ]
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: isLoading ? null : _submitForm,
                                      child: isLoading 
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Text(
                                            isLogin ? 'Sign in' : 'Sign up', 
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // BUTTON CONTINUE WITH GOOGLE
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.black.withOpacity(0.1), thickness: 1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          isLogin ? getTxt('or_login') : getTxt('or_signup'),
                                          style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: Colors.black.withOpacity(0.1), thickness: 1)),
                                    ],
                                  ),

                                  const SizedBox(height: 15),

                                  // TOMBOL GOOGLE
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Colors.black.withOpacity(0.8), width: 1.2)
                                        ),
                                      ),
                                      onPressed: () async {
                                        setState(() => isLoading = true); // Tampilkan loading
                                        try {
                                          // Panggil fungsi login Google
                                          bool success = await _auth.signInWithGoogle();
                                          
                                          // Cek apakah user sudah login (session ada)
                                          final session = Supabase.instance.client.auth.currentSession;
                                          
                                          if (success && session != null && mounted) {
                                            // Jika Sign Up via Google, cek apakah data user sudah ada di tabel 'User'
                                            // Jika belum, insert data default
                                            final user = session.user;
                                            final existingData = await Supabase.instance.client
                                                .from('User')
                                                .select('id_user')
                                                .eq('id_user', user.id)
                                                .maybeSingle();
                                            
                                            if (existingData == null) {
                                              await Supabase.instance.client.from('User').insert({
                                                'id_user': user.id,
                                                'nama': user.userMetadata?['full_name'] ?? 'User Google',
                                                'email': user.email,
                                                'pass': 'google_auth', // Dummy password
                                                'id_jabatan': 4, // Default Staff
                                                'poin': 0,
                                                'is_visitor': false,
                                                'timestamp': DateTime.now().toIso8601String(),
                                              });
                                            }
                                            
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                                          } else {
                                            // Jika gagal atau session null
                                            _showCustomDialog("Google Sign-In Gagal atau Dibatalkan");
                                          }
                                        } catch (e) {
                                          _showCustomDialog("Terjadi kesalahan: $e");
                                        } finally {
                                          if(mounted) setState(() => isLoading = false);
                                        }
                                      },
                                      icon: Image.network('assets/images/Google.svg', height: 22, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata, size: 30)), 
                                      label: Text(
                                        getTxt('google'),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
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

  DropdownMenuItem<String> _buildDropdownItem(String value, String flag, String label) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }

  // Text Field B6E3EF
  Widget _buildGlassTextField({
    required String hint, 
    required TextEditingController controller, 
    required IconData icon, 
    required bool isPassword
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFB6E3EF).withOpacity(0.55), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.0), 
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !isPasswordVisible : false,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: Colors.white, size: 20),
          
          suffixIcon: isPassword 
              ? Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    if (!isLogin && _passStrengthText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          children: [
                            Text(
                              "―――  ",
                              style: TextStyle(color: _passStrengthColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _passStrengthText,
                              style: TextStyle(color: _passStrengthColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white, size: 20),
                      onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                  ],
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isLoginTab) {
    bool isActive = isLogin == isLoginTab;
    return GestureDetector(
      onTap: () {
        setState(() {
          isLogin = isLoginTab;
          _checkPasswordStrength(); 
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              color: isActive ? Colors.white : Colors.black54,
              shadows: isActive ? [const Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))] : [],
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isActive ? 35 : 0,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
          )
        ],
      ),
    );
  }

  // Animasi Cube
  Widget _buildEntranceAnim({required Widget child, required int delay}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, double value, childWidget) {
        return Transform.scale(
          scale: value,
          child: childWidget,
        );
      },
      child: child,
    );
  }
}