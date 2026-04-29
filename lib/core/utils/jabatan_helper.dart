import 'package:flutter/material.dart';

class JabatanHelper {
  // Tentukan apakah user adalah verificator (is_verificator SELALU prioritas utama)
  static bool isVerificator({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    return isVerificatorFlag == true;
  }

  // Ambil nama jabatan — is_verificator TRUE selalu menang, abaikan id_jabatan
  static String getDisplayRole({
    required bool? isVerificatorFlag,
    required int? idJabatan,
    required String? jabatanFromDb,
    required String lang,
  }) {
    if (isVerificatorFlag == true) {
      return _getVerificatorLabel(lang);
    }
    return jabatanFromDb ?? 'Staff';
  }

  static String _getVerificatorLabel(String lang) {
    switch (lang) {
      case 'ID': return 'Verificator';
      case 'ZH': return '验证者';
      case 'EN':   return 'Verifier';
      default: return '';
    }
  }

  // Gradient colors — is_verificator TRUE selalu menang, abaikan id_jabatan
  static List<Color> getGradientColors({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    if (isVerificatorFlag == true) {
      // Verificator: Hijau Emerald
      return [const Color(0xFF059669), const Color(0xFF065F46)];
    }
    switch (idJabatan) {
      case 1:  return [const Color(0xFFFA527B), const Color(0xFF6A041D)];
      case 2:  return [const Color(0xFF1D72F3), const Color(0xFF00C9E4)];
      case 3:  return [const Color(0xFF26D0CE), const Color(0xFF1A2980)];
      case 4:  return [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)];
      case 5:  return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      default: return [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)]; // Staff
    }
  }

  // Warna utama (stop pertama dari gradient)
  static Color getPrimaryColor({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    return getGradientColors(
      isVerificatorFlag: isVerificatorFlag,
      idJabatan: idJabatan,
    ).first;
  }

  // Icon badge role
  static IconData getRoleIcon({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    if (isVerificatorFlag == true) return Icons.verified_rounded;
    switch (idJabatan) {
      case 1:  return Icons.workspace_premium_rounded;
      case 2:  return Icons.workspace_premium_rounded;
      case 3:  return Icons.manage_accounts_rounded;
      case 4:  return Icons.badge_rounded;
      case 5:  return Icons.people_rounded;
      default: return Icons.badge_rounded;
    }
  }

  // Warna api progress bar (berbasis poin)
  static Color getFireColor({
    required bool? isVerificatorFlag,
    required int? idJabatan,
    required int points,
  }) {
    if (points >= 1000) return const Color(0xFFEF4444);
    if (points >= 500)  return const Color(0xFFF97316);
    if (points >= 100)  return const Color(0xFF22C55E);
    if (points > 0)     return const Color(0xFF3B82F6);
    return Colors.grey.shade400;
  }

  // ── Background gradient UserInfoCard — lebih kontras dan jelas ──
  static List<Color> getCardGradient({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    if (isVerificatorFlag == true) {
      // Verificator: Hijau mint solid-ish
      return [
        const Color(0xFF6EE7B7), // hijau mint terang
        const Color(0xFFD1FAE5), // hijau sangat muda
        const Color(0xFFECFDF5), // hampir putih hijau
        const Color(0xFF34D399), // hijau medium
      ];
    }
    switch (idJabatan) {
      case 1: // Eksekutif: Pink-Rose tegas
        return [
          const Color(0xFFFDA4AF), // rose terang
          const Color(0xFFFFE4E6), // rose muda
          const Color(0xFFFFF1F2), // hampir putih rose
          const Color(0xFFFB7185), // rose medium
        ];
      case 2: // Manager: Biru tegas
        return [
          const Color(0xFF93C5FD), // biru terang
          const Color(0xFFDBEAFE), // biru muda
          const Color(0xFFEFF6FF), // hampir putih biru
          const Color(0xFF60A5FA), // biru medium
        ];
      case 3: // Kasie: Teal/Cyan tegas
        return [
          const Color(0xFF67E8F9), // cyan terang
          const Color(0xFFCFFAFE), // cyan muda
          const Color(0xFFECFEFF), // hampir putih cyan
          const Color(0xFF22D3EE), // cyan medium
        ];
      case 4: 
        return [
          const Color(0xFFC4B5FD), // ungu terang
          const Color(0xFFEDE9FE), // ungu muda
          const Color(0xFFF5F3FF), // hampir putih ungu
          const Color(0xFFA78BFA), // ungu medium
        ];
      case 5: // HRD: Pink tegas
        return [
          const Color(0xFFF9A8D4),
          const Color(0xFFFCE7F3),
          const Color(0xFFFDF2F8),
          const Color(0xFFF472B6),
        ];
      default: // Staff: Ungu tegas
        return [
          const Color(0xFFC4B5FD), // ungu terang
          const Color(0xFFEDE9FE), // ungu muda
          const Color(0xFFF5F3FF), // hampir putih ungu
          const Color(0xFFA78BFA), // ungu medium
        ];
    }
  }
}