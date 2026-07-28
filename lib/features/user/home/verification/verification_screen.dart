import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accident/accident_verification.dart';
import 'finding/finding_verification_history.dart';
import 'finding/finding_verification.dart';

class ExecVerificationScreen extends StatefulWidget {
  final String lang;
  final int? userJabatanId;
  final Function(int)? onPointEarned;

  const ExecVerificationScreen({
    super.key,
    required this.lang,
    this.userJabatanId,
    this.onPointEarned,
  });

  @override
  State<ExecVerificationScreen> createState() => _ExecVerificationScreenState();
}

class _ExecVerificationScreenState extends State<ExecVerificationScreen> {
  late String _lang;
  bool _isHrdMode = false; // true jika user adalah HRD (id_jabatan=5) atau Manager (2)
  int _tabIndex = 0;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'screen_title': 'Executive Verification',
      'tab_verify': 'Verify',
      'tab_history': 'History',
    },
    'ID': {
      'screen_title': 'Verifikasi Eksekutif',
      'tab_verify': 'Verifikasi',
      'tab_history': 'Riwayat',
    },
    'ZH': {
      'screen_title': '高管验证',
      'tab_verify': '验证',
      'tab_history': '历史',
    },
  };

  String t(String key) => _txt[_lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _lang = widget.lang;
    _isHrdMode = widget.userJabatanId == 5 || widget.userJabatanId == 2;
  }

  @override
  Widget build(BuildContext context) {
    if (_isHrdMode) {
      return AccidentVerificationScreen(
        lang: widget.lang,
        userJabatanId: widget.userJabatanId,
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _tabIndex == 0
                  ? FindingVerification(
                      lang: _lang,
                      isHrdMode: _isHrdMode,
                      onPointEarned: widget.onPointEarned,
                    )
                  : FindingVerificationHistory(lang: _lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String roleLabel;
    if (widget.userJabatanId == 5) {
      roleLabel = 'HRD';
    } else if (widget.userJabatanId == 2) {
      roleLabel = _lang == 'EN' ? 'Manager' : _lang == 'ZH' ? '经理' : 'Manager';
    } else if (widget.userJabatanId == 1) {
      roleLabel = _lang == 'EN' ? 'Executive' : _lang == 'ZH' ? '高管' : 'Eksekutif';
    } else if (widget.userJabatanId == 3) {
      roleLabel = _lang == 'EN' ? 'Supervisor' : _lang == 'ZH' ? '主管' : 'Supervisor';
    } else if (widget.userJabatanId == 4) {
      roleLabel = 'Staff';
    } else {
      roleLabel = 'Executive';
    }

    String screenTitle;
    if (_isHrdMode) {
      screenTitle = _lang == 'EN'
          ? 'Accident Verification'
          : _lang == 'ZH'
              ? '事故验证'
              : 'Verifikasi Kecelakaan';
    } else {
      screenTitle = t('screen_title');
    }

    List<Color> badgeColors;
    IconData badgeIcon;

    switch (widget.userJabatanId) {
      case 1: // Eksekutif: Pink-Rose
        badgeColors = [const Color(0xFFFB7185), const Color(0xFFFDA4AF)];
        badgeIcon = Icons.workspace_premium_rounded;
        break;
      case 2: // Manager: Biru
        badgeColors = [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
        badgeIcon = Icons.workspace_premium_rounded;
        break;
      case 3: // Supervisor: Teal/Cyan
        badgeColors = [const Color(0xFF06B6D4), const Color(0xFF22D3EE)];
        badgeIcon = Icons.manage_accounts_rounded;
        break;
      case 4: // Staff: Ungu
        badgeColors = [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
        badgeIcon = Icons.badge_rounded;
        break;
      case 5: // HRD: Pink
        badgeColors = [const Color(0xFFEC4899), const Color(0xFFF472B6)];
        badgeIcon = Icons.people_rounded;
        break;
      default:
        badgeColors = [const Color(0xFF00C9E4), const Color(0xFF0891B2)];
        badgeIcon = Icons.verified_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: badgeColors.first.withValues(alpha:0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Color(0xFF1D72F3)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              screenTitle,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D72F3),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: badgeColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: badgeColors.first.withValues(alpha:0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, color: Colors.white, size: 14),
                const SizedBox(width: 5),
                Text(
                  roleLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_tabIndex != 0) setState(() => _tabIndex = 0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _tabIndex == 0
                        ? const Color(0xFF1D72F3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _tabIndex == 0
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1D72F3).withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 15,
                          color: _tabIndex == 0
                              ? Colors.white
                              : const Color(0xFF1D72F3)),
                      const SizedBox(width: 5),
                      Text(
                        t('tab_verify'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _tabIndex == 0
                              ? Colors.white
                              : const Color(0xFF1D72F3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_tabIndex != 1) {
                    setState(() => _tabIndex = 1);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _tabIndex == 1
                        ? const Color(0xFF0EA5E9)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _tabIndex == 1
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9).withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 15,
                          color: _tabIndex == 1
                              ? Colors.white
                              : const Color(0xFF0EA5E9)),
                      const SizedBox(width: 5),
                      Text(
                        t('tab_history'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _tabIndex == 1
                              ? Colors.white
                              : const Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}