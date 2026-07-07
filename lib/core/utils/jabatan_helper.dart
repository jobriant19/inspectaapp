import 'package:flutter/material.dart';

class JabatanHelper {
  static bool isVerificator({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    return isVerificatorFlag == true;
  }

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

  static List<Color> getGradientColors({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    if (isVerificatorFlag == true) {
      return [const Color(0xFF059669), const Color(0xFF065F46)];
    }
    switch (idJabatan) {
      case 1:  return [const Color(0xFFFA527B), const Color(0xFF6A041D)];
      case 2:  return [const Color(0xFF1D72F3), const Color(0xFF00C9E4)];
      case 3:  return [const Color(0xFF26D0CE), const Color(0xFF1A2980)];
      case 4:  return [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)];
      case 5:  return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      default: return [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)]; 
    }
  }

  static Color getPrimaryColor({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    return getGradientColors(
      isVerificatorFlag: isVerificatorFlag,
      idJabatan: idJabatan,
    ).first;
  }

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

  static List<Color> getCardGradient({
    required bool? isVerificatorFlag,
    required int? idJabatan,
  }) {
    if (isVerificatorFlag == true) {
      return [
        const Color(0xFF6EE7B7),
        const Color(0xFFD1FAE5),
        const Color(0xFFECFDF5),
        const Color(0xFF34D399),
      ];
    }
    switch (idJabatan) {
      case 1: // EKSEKUTIF
        return [
          const Color(0xFFFDA4AF),
          const Color(0xFFFFE4E6),
          const Color(0xFFFFF1F2),
          const Color(0xFFFB7185),
        ];
      case 2: // MANAGER
        return [
          const Color(0xFF93C5FD),
          const Color(0xFFDBEAFE),
          const Color(0xFFEFF6FF),
          const Color(0xFF60A5FA),
        ];
      case 3: // KASIE
        return [
          const Color(0xFF67E8F9),
          const Color(0xFFCFFAFE),
          const Color(0xFFECFEFF),
          const Color(0xFF22D3EE),
        ];
      case 4: // STAFF
        return [
          const Color(0xFFC4B5FD),
          const Color(0xFFEDE9FE),
          const Color(0xFFF5F3FF),
          const Color(0xFFA78BFA),
        ];
      case 5: // HRD
        return [
          const Color(0xFFF9A8D4),
          const Color(0xFFFCE7F3),
          const Color(0xFFFDF2F8),
          const Color(0xFFF472B6),
        ];
      default:
        return [
          const Color(0xFFC4B5FD), 
          const Color(0xFFEDE9FE),
          const Color(0xFFF5F3FF),
          const Color(0xFFA78BFA),
        ];
    }
  }
}