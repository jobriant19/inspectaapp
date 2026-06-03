import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // ── Hash SHA-256 untuk user BARU (registrasi via admin, emulator-safe) ──
  Future<String> hashPasswordSha256(String email, String password) async {
    try {
      final saltText = email.padRight(16, 'x').substring(0, 16);
      final combined = '$saltText:$password';
      final bytes = utf8.encode(combined);
      final digest = sha256.convert(bytes);
      return '\$sha256\$$saltText\$${digest.toString()}';
    } catch (e) {
      debugPrint('Hash Error: $e');
      throw Exception('Gagal mengenkripsi password');
    }
  }

  // ── hashPassword: dipanggil dari login_screen & admin ──
  // Untuk user lama: ambil hash dari DB, ekstrak bagian terakhir
  // Untuk user baru (SHA-256): sama, ekstrak bagian terakhir
  Future<String> hashPassword(String email, String password) async {
    // Untuk login, kita tidak hash di sini
    // hashPassword hanya dipakai untuk registrasi user baru via admin
    return hashPasswordSha256(email, password);
  }

  // ── Login dengan multi-strategy ──
  // Strategy 1: Ambil hash dari DB, ekstrak bagian terakhir → kirim ke Supabase Auth
  // Strategy 2: Kirim plain password langsung (fallback)
  Future<AuthResponse?> signInWithEmail(
      String email, String password) async {

    // Cek apakah input sudah berupa hash (dari login_screen lama yang hash dulu)
    // atau plain password
    if (password.contains('\$')) {
      // Sudah di-hash, ekstrak bagian terakhir langsung
      final authPassword = password.split('\$').last;
      try {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: authPassword,
        );
        return response;
      } on AuthException {
        rethrow;
      } catch (e) {
        debugPrint('Error Login (hashed): $e');
        return null;
      }
    }

    // Plain password — coba Strategy 1: ambil hash dari DB dulu
    try {
      final userData = await supabase
          .from('User')
          .select('pass')
          .eq('email', email)
          .maybeSingle();

      if (userData != null && userData['pass'] != null) {
        final storedHash = userData['pass'] as String;
        // Ekstrak bagian terakhir dari hash (Argon2 atau SHA-256)
        final authPassword = storedHash.split('\$').last;

        try {
          final response = await supabase.auth.signInWithPassword(
            email: email,
            password: authPassword,
          );
          return response;
        } on AuthException catch (e) {
          // Jika gagal dengan hash dari DB, coba plain password
          debugPrint(
              'Strategy 1 failed: ${e.message}, trying plain password...');
        }
      }
    } catch (e) {
      debugPrint('Error fetching user hash: $e');
    }

    // Strategy 2: Coba plain password langsung
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Error Login (plain): $e');
      return null;
    }
  }

  // ── Register untuk user baru via admin ──
  Future<AuthResponse?> signUpWithEmail(
      String email, String password) async {
    try {
      final authPassword = password.contains('\$')
          ? password.split('\$').last
          : password;

      final response = await supabase.auth.signUp(
        email: email,
        password: authPassword,
      );
      return response;
    } on AuthException catch (_) {
      rethrow;
    } catch (e) {
      debugPrint('Error Sign Up: $e');
      return null;
    }
  }

  // ── Reset Password ──
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error Reset Password: $e');
    }
  }

  // ── Login dengan Google ──
  Future<bool> signInWithGoogle() async {
    try {
      final String redirectUrl;
      if (kIsWeb) {
        redirectUrl = 'http://localhost:3000';
      } else {
        redirectUrl = 'io.supabase.inspecta://login-callback/';
      }

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