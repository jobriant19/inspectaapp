import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspectaapp/features/verificator/home/verificator_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user/home/home_screen.dart';
import '../auth/login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Delay untuk splash screen
    await Future.delayed(const Duration(milliseconds: 3500));

    // Cek apakah user sudah pernah lihat onboarding
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    // Cek apakah user sudah login
    final session = Supabase.instance.client.auth.currentSession;
    
    if (!mounted) return;

    if (session != null) {
      try {
        final userData = await Supabase.instance.client
            .from('User')
            .select('is_verificator, nama, poin, gambar_user, jabatan(nama_jabatan)')
            .eq('id_user', session.user.id)
            .single();

        final isVerificator = userData['is_verificator'] as bool? ?? false;

        final userName = userData['nama'] as String?;
        final userPoin = userData['poin'] as int?;
        final userImage = userData['gambar_user'] as String?;
        final userRole = userData['jabatan']?['nama_jabatan'] as String?;
        final metaName = session.user.userMetadata?['full_name'] ?? session.user.userMetadata?['name'];
        final metaImage = session.user.userMetadata?['avatar_url'] ?? session.user.userMetadata?['picture'];

        if (!mounted) return;

        if (isVerificator) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerificatorHomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(
              initialUserName: userName ?? metaName,
              initialUserPoin: userPoin,
              initialUserImage: userImage ?? metaImage,
              initialUserRole: userRole,
            )),
          );
        }
      } catch (e) {
        debugPrint("Error cek verifikator di splash: $e");
        // Jika gagal ambil data, arahkan ke login untuk keamanan
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else if (onboardingComplete) {
      // Jika sudah lihat onboarding tapi belum login, ke LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // Jika belum pernah lihat onboarding, ke OnboardingScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        // --- 1. BACKGROUND GRADIENT Putih ke Biru Muda ---
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
            // --- 2. EFEK LINGKARAN PUDAR DI BELAKANG ---
            Center(
              child: Container(
                width: 500, height: 500,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
              ),
            ),
            Center(
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
              ),
            ),

            // --- 3. ITEM TERBANG DARI TENGAH KE ATAS ---
            // Item 1: Clean (Kiri Atas)
            _buildAnimatedItem(
              imagePath: 'assets/images/clean.png', 
              width: 90,
              targetOffset: const Offset(-120, -140), 
            ),
            // Item 2: Winner (Tengah Atas)
            _buildAnimatedItem(
              imagePath: 'assets/images/winner.png', 
              width: 80,
              targetOffset: const Offset(0, -200), 
            ),
            // Item 3: Regular (Kanan Atas)
            _buildAnimatedItem(
              imagePath: 'assets/images/regular.png', 
              width: 100,
              targetOffset: const Offset(130, -140),
            ),

            // --- 4. KARAKTER 3D (Animasi Meluncur dari Bawah) ---
            Positioned( 
              bottom: -25, 
              left: 0,
              right: 0,
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1800),
                curve: Curves.easeOutCubic, 
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 300 * (1 - value)), 
                    child: Opacity(
                      opacity: value, 
                      child: child,
                    ),
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

            // --- 5. LOGO DI TENGAH ---
            Align(
              alignment: const Alignment(0.0, -0.15),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 2500),
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
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 40, spreadRadius: 10)
                    ]
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 180, 
                    errorBuilder: (c, e, s) => const Icon(Icons.shield, size: 100, color: Color(0xFF00C9E4)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI BANTUAN: Untuk Mengatur Animasi 3 Item Terbang ---
  Widget _buildAnimatedItem({required String imagePath, required double width, required Offset targetOffset}) {
    return Center( 
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 2200),
        curve: Curves.elasticOut,
        builder: (context, double value, child) {
          return Transform.translate(
            // Mendorong elemen dari Offset(0,0) ke titik target offset
            offset: Offset(targetOffset.dx * value, targetOffset.dy * value),
            child: Transform.scale(
              scale: value.clamp(0.0, 1.0), // Muncul dari sangat kecil membesar
              child: Opacity(
                opacity: value.clamp(0.0, 1.0), // Dari transparan memudar jadi nyata
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