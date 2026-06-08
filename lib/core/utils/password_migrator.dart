import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';

/// Utility untuk admin: reset password semua user lama ke format BCrypt baru.
/// Panggil sekali dari admin screen setelah deploy.
class PasswordMigrator {
  static final _supabase = Supabase.instance.client;

  /// Reset password satu user ke password baru dengan BCrypt hash.
  /// [newPlainPassword] adalah password baru yang akan diset untuk user tersebut.
  static Future<bool> resetUserPassword({
    required String userId,
    required String email,
    required String newPlainPassword,
  }) async {
    try {
      // 1. Hash password baru dengan BCrypt
      final newHash = BCrypt.hashpw(
        newPlainPassword,
        BCrypt.gensalt(logRounds: 10),
      );

      // 2. Update kolom pass di tabel User
      await _supabase
          .from('User')
          .update({'pass': newHash})
          .eq('id_user', userId);

      // 3. Update password di Supabase Auth (via admin API jika tersedia)
      // Note: ini memerlukan service_role key, tidak bisa dari client biasa
      // Lakukan via Supabase Dashboard atau Edge Function jika diperlukan

      debugPrint('✅ Password reset berhasil untuk: $email');
      return true;
    } catch (e) {
      debugPrint('❌ Password reset gagal untuk $email: $e');
      return false;
    }
  }
}