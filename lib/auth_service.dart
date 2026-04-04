import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Login Email & Password
  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print("Error Login: $e");
      return null;
    }
  }

  // Register Email & Password
  Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print("Error Sign Up: $e");
      return null;
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      print("Error Reset Password: $e");
    }
  }

  // Login dengan Google (Supabase)
  Future<bool> signInWithGoogle() async {
    try {
      final String redirectUrl;
      if (kIsWeb) {
        // URL redirect untuk web testing (sesuai port tetap)
        redirectUrl = 'http://localhost:3000';
      } else {
        // URL redirect untuk mobile
        redirectUrl = 'io.supabase.inspecta://login-callback/';
      }

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        queryParams: {
          'prompt': 'select_account', 
        },
      );
      return true;
    } catch (e) {
      print("Error Google Sign-In: $e");
      return false;
    }
  }
}
