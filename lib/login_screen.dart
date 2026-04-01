import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool isLogin = true; // Toggle antara Login dan Sign Up
  bool isRememberMe = false; // Fitur Ingatkan Saya
  bool isLoading = false;

  final Color primaryBlue = const Color(0xFF00B5E4);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // FITUR: Remember Email & Password
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

  void _submitForm() async {
    setState(() => isLoading = true);
    _saveCredentials(); 
    
    // Logika Supabase
    if (isLogin) {
      await _auth.signInWithEmail(_emailController.text, _passwordController.text);
      // Tambahkan navigasi ke Home setelah sukses
    } else {
      await _auth.signUpWithEmail(_emailController.text, _passwordController.text);
      // Tambahkan navigasi ke Home setelah sukses
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // BAGIAN ATAS (Header & Tab)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      "Welcome to Inspecta\nMake your discipline day!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ILUSTRASI ATAS
                    SizedBox(
                      height: 120,
                      child: Image.asset('assets/images/top_illustration.png'), 
                    ),
                    const SizedBox(height: 20),
                    
                    // CUSTOM TAB BAR (Login | Sign Up)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTabButton("Login", true),
                        _buildTabButton("Sign Up", false),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // BAGIAN BAWAH (Form Area)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    // ILUSTRASI TENGAH (Background form)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/images/center_illustration.png', height: 200, width: 250),
                        
                        Column(
                          children: [
                            _buildTextField("E-mail", _emailController, false),
                            const SizedBox(height: 15),
                            _buildTextField("Password", _passwordController, true),
                          ],
                        ),
                      ],
                    ),
                    
                    // CHECKBOX INGATKAN SAYA
                    Row(
                      children: [
                        Checkbox(
                          value: isRememberMe,
                          activeColor: primaryBlue,
                          onChanged: (value) {
                            setState(() {
                              isRememberMe = value!;
                            });
                          },
                        ),
                        const Text("Remember Me / Ingatkan Saya", style: TextStyle(fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // TOMBOL LOGIN / SIGN UP
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryBlue, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: isLoading ? null : _submitForm,
                        child: isLoading 
                          ? CircularProgressIndicator(color: primaryBlue)
                          : Text(
                              isLogin ? "Login" : "Sign Up",
                              style: TextStyle(color: primaryBlue, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),

                    // LUPA PASSWORD
                    if (isLogin)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            // Panggil modal/dialog untuk input email reset password
                            if(_emailController.text.isNotEmpty){
                              _auth.resetPassword(_emailController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link reset password dikirim ke email'))
                              );
                            }
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.black87, fontSize: 12),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // TOMBOL GOOGLE
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300)
                          ),
                        ),
                        onPressed: () async {
                          bool success = await _auth.signInWithGoogle();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google Login berhasil!')),
                            );
                            // Navigasi ke Home screen di sini nanti setelah bikin Home
                          }
                        },
                        icon: Image.network(
                          'assets/images/Google.svg',
                          height: 24,
                        ),
                        label: const Text(
                          "Continue with Google",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER: Tab Button (Login / Sign Up)
  Widget _buildTabButton(String title, bool isLoginTab) {
    bool isActive = isLogin == isLoginTab;
    return GestureDetector(
      onTap: () {
        setState(() {
          isLogin = isLoginTab;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            width: isActive ? 60 : 0,
            color: primaryBlue,
          )
        ],
      ),
    );
  }

  // WIDGET HELPER: Text Field Putih
  Widget _buildTextField(String hint, TextEditingController controller, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}