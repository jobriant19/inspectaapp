import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Hash untuk disimpan di kolom pass — pure Dart, identik semua platform
  String hashPassword(String email, String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 10));
  }

  // Login: langsung ke Supabase Auth dengan password asli
  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      debugPrint('Error Login: $e');
      return null;
    }
  }

  // Register: daftar ke Supabase Auth dengan password asli
  Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      debugPrint('Error Sign Up: $e');
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error Reset Password: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final String redirectUrl = kIsWeb
          ? 'http://localhost:3000'
          : 'io.supabase.inspecta://login-callback/';
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        queryParams: {'prompt': 'select_account'},
      );
      return true;
    } catch (e) {
      debugPrint('Error Google Sign-In: $e');
      return false;
    }
  }
}