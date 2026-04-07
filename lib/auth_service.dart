import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'dart:convert';

class AuthService {
  final supabase = Supabase.instance.client;

  // Fungsi Hashing Password Argon2id
  Future<String> hashPassword(String email, String password) async {
    try {
      String saltText = email.padRight(16, 'x'); 
      final salt = Salt(utf8.encode(saltText));

      final result = await argon2.hashPasswordString(
        password,
        salt: salt,
        type: Argon2Type.id,
      );
      return result.encodedString;
    } catch (e) {
      print("Argon2 Error: $e");
      throw Exception("Gagal mengenkripsi password");
    }
  }

  // Login Email & Password
  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      String authPassword = password.split('\$').last;
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: authPassword,
      );
      return response;
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      print("Error Login: $e");
      return null;
    }
  }

  // Register Email & Password
  Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    try {
      String authPassword = password.split('\$').last;
      final response = await supabase.auth.signUp(
        email: email,
        password: authPassword,
      );
      return response;
    } on AuthException catch (_) {
      rethrow;
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
        // URL redirect untuk web testing
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
