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

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  
  // Controller Form
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();
  
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
      'google': 'Continue with Google',
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
      'google': 'Lanjutkan dengan Google',
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
      'google': '使用Google继续',
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
    }
  };

  String getTxt(String key) => translations[selectedLanguage]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _passwordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    if (isLogin) return;
    String pass = _passwordController.text;
    setState(() {
      if (pass.isEmpty) {
        _passStrengthText = "";
      } else if (pass.length < 6) {
        _passStrengthText = getTxt('weak');
        _passStrengthColor = Colors.redAccent;
      } else if (pass.length < 9) {
        _passStrengthText = getTxt('medium');
        _passStrengthColor = Colors.orangeAccent;
      } else {
        _passStrengthText = getTxt('strong');
        _passStrengthColor = const Color(0xFF42E27A);
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
                // Ikon X
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4B4B), // Merah terang seperti digambar
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                // Teks Pesan
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 25),
                // Tombol Try Again
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9E4), // Biru terang seperti digambar
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      getTxt('try_again'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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

    // 1. VALIDASI DENGAN POP-UP KUSTOM
    if (email.isEmpty && pass.isEmpty) {
      _showCustomDialog(getTxt('err_email_pass'));
      return;
    } else if (email.isEmpty) {
      _showCustomDialog(getTxt('err_email'));
      return;
    } else if (pass.isEmpty) {
      _showCustomDialog(getTxt('err_pass'));
      return;
    } else if (!isLogin && name.isEmpty) {
      _showCustomDialog(getTxt('err_name'));
      return;
    } else if (!isLogin && pass.length < 6) {
      _showCustomDialog(getTxt('err_len'));
      return;
    }

    setState(() => isLoading = true);
    
    try {
      if (isLogin) {
        // PROSES LOGIN
        await _auth.signInWithEmail(email, pass);
        
        // Simpan Remember me jika berhasil login
        _saveCredentials(); 
        
        // Pindah ke Home Screen
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        // PROSES SIGN UP
        await _auth.signUpWithEmail(email, pass);

        // --- INTEGRASI ERD SUPABASE (TABEL USER) ---
        // Insert data username, email, dan pass ke tabel 'User' sesuai gambar ERD Crowfoot.
        // Catatan: Secara praktik terbaik keamanan, "pass" tidak boleh disimpan dalam plain text, 
        // namun instruksi ini mengikuti ERD yang Anda berikan.
        try {
          await Supabase.instance.client.from('User').insert({
            'nama': name,
            'email': email,
            'pass': pass, // Sesuai ERD Anda
            'poin': 0,    // Default value sesuai struktur umum database Anda
            'is_visitor': false,
            // 'id_jabatan' dan 'id_unit' bisa ditambahkan jika ada default value
          });
        } catch (e) {
          debugPrint("Gagal insert tabel User: $e");
          // Anda dapat menangani error insert database di sini
        }

        _saveCredentials(); 
        
        // Pindah ke Home Screen
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      }
    } catch (e) {
      // Jika terjadi kesalahan dari AuthService (Salah email/password)
      _showCustomDialog(getTxt('err_wrong'));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFCBE5F6), Color(0xFFE2DDF3), Color(0xFF90B1C6)],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 2. KONTEN
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false, 
                  child: Column(
                    children: [
                      // --- HEADER & LOKALISASI TRANSLATE ---
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0, top: 10.0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
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
                                  _checkPasswordStrength(); // Refresh strength text language
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      // --- ILUSTRASI ATAS ---
                      Container(
                        height: 200,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Image.asset(
                            isLogin 
                                ? 'assets/images/login_illustration.png'  
                                : 'assets/images/signup_illustration.png', 
                            key: ValueKey<bool>(isLogin), 
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // --- FORM Glassmorph ---
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
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
                                  const SizedBox(height: 25),

                                  // Tagline
                                  Center(
                                    child: Text(
                                      isLogin ? getTxt('welcome') : getTxt('get_started'),
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      isLogin 
                                        ? getTxt('tagline_login') 
                                        : getTxt('tagline_signup'),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 35),

                                  // 1. FORM: EMAIL
                                  _buildInputLabel(getTxt('email_label')),
                                  _buildGlassTextField(
                                    hint: getTxt('email_hint'),
                                    controller: _emailController,
                                    icon: Icons.email_outlined,
                                    isPassword: false,
                                  ),
                                  
                                  // 2. FORM: YOUR NAME (HANYA MUNCUL KETIKA SIGN UP)
                                  if (!isLogin) ...[
                                    const SizedBox(height: 20),
                                    _buildInputLabel(getTxt('name_label')),
                                    _buildGlassTextField(
                                      hint: getTxt('name_hint'),
                                      controller: _nameController,
                                      icon: Icons.person_outline,
                                      isPassword: false,
                                    ),
                                  ],

                                  const SizedBox(height: 20),
                                  
                                  // 3. FORM: PASSWORD
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
                                            width: 20, height: 20,
                                            child: Checkbox(
                                              value: isRememberMe,
                                              activeColor: const Color(0xFF00C9E4),
                                              side: BorderSide(color: Colors.black.withOpacity(0.5)),
                                              onChanged: (value) => setState(() => isRememberMe = value!),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(getTxt('remember_me'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        ],
                                      ),
                                      if (isLogin)
                                        GestureDetector(
                                          onTap: () {
                                            if(_emailController.text.isNotEmpty){
                                              _auth.resetPassword(_emailController.text);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(getTxt('reset_sent')),
                                                  backgroundColor: Colors.green,
                                                )
                                              );
                                            } else {
                                              _showCustomDialog(getTxt('fill_email_reset'));
                                            }
                                          },
                                          child: Text(
                                            getTxt('forgot_pass'),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

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
                                            isLogin ? getTxt('login') : getTxt('signup'),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // BUTTON CONTINUE WITH GOOGLE
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.black.withOpacity(0.15), thickness: 1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          isLogin ? getTxt('or_login') : getTxt('or_signup'),
                                          style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: Colors.black.withOpacity(0.15), thickness: 1)),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

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
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(color: Colors.black.withOpacity(0.8), width: 1.2)
                                        ),
                                      ),
                                      onPressed: () async {
                                        bool success = await _auth.signInWithGoogle();
                                        if (success) {
                                          if (mounted) {
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                                          }
                                        }
                                      },
                                      icon: Image.network(
                                        'assets/images/Google.svg', // Pastikan asset google ada, jika tidak ganti dengan Icon() bawaan
                                        height: 20,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 30),
                                      ), 
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
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildGlassTextField({
    required String hint, 
    required TextEditingController controller, 
    required IconData icon, 
    required bool isPassword
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !isPasswordVisible : false,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          
          suffixIcon: isPassword 
              ? Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    if (!isLogin && _passStrengthText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          "--- $_passStrengthText",
                          style: TextStyle(color: _passStrengthColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.7), size: 18),
                      onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                    ),
                  ],
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
            width: isActive ? 30 : 0,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
          )
        ],
      ),
    );
  }
}