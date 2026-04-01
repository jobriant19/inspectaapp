import 'package:supabase_flutter/supabase_flutter.dart';

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
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.inspecta://login-callback/',
        scopes: 'email profile', // Tambahan scopes
      );
      return true;
    } catch (e) {
      print("Error Google Sign-In: $e");
      return false;
    }
  }
}