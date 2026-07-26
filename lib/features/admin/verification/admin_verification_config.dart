import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminVerificationConfigTab extends StatefulWidget {
  final String lang;
  const AdminVerificationConfigTab({super.key, required this.lang});

  @override
  State<AdminVerificationConfigTab> createState() =>
      _AdminVerificationConfigTabState();
}

class _AdminVerificationConfigTabState
    extends State<AdminVerificationConfigTab> {
  final _client = Supabase.instance.client;

  bool _configLoading = true;
  bool _configSaving = false;
  int _durasiHari = 7;
  int _minSuara = 3;
  bool _autoValid = true;

  static const Color _primaryColor = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  String t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  Future<void> _loadConfig() async {
    setState(() => _configLoading = true);
    try {
      final rows = await _client
          .from('verifikasi_config')
          .select('kode, nilai_int');
      for (final row in rows) {
        switch (row['kode']) {
          case 'durasi_verifikasi_hari':
            _durasiHari = row['nilai_int'] ?? 7;
            break;
          case 'min_suara_finalisasi':
            _minSuara = row['nilai_int'] ?? 3;
            break;
          case 'auto_valid_jika_timeout':
            _autoValid = (row['nilai_int'] ?? 1) == 1;
            break;
        }
      }
    } catch (e) {
      debugPrint('loadConfig error: $e');
    }
    if (mounted) setState(() => _configLoading = false);
  }

  void _showSuccessPopup({
    required bool isSuccess,
    required String titleId,
    required String titleEn,
    required String titleZh,
    required String msgId,
    required String msgEn,
    required String msgZh,
  }) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        final color =
            isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final bgLight =
            isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
        final icon =
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: bgLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withValues(alpha: 0.25), width: 2),
                    ),
                    child: Icon(icon, color: color, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    t(titleId, titleEn, titleZh),
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t(msgId, msgEn, msgZh),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        t('Tutup', 'Close', '关闭'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveConfig() async {
    setState(() => _configSaving = true);
    try {
      final updates = [
        {'kode': 'durasi_verifikasi_hari', 'nilai_int': _durasiHari},
        {'kode': 'min_suara_finalisasi', 'nilai_int': _minSuara},
        {'kode': 'auto_valid_jika_timeout', 'nilai_int': _autoValid ? 1 : 0},
      ];
      for (final u in updates) {
        await _client
            .from('verifikasi_config')
            .update({
              'nilai_int': u['nilai_int'] as int,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('kode', u['kode'] as String);
      }
      if (mounted) {
        _showSuccessPopup(
          isSuccess: true,
          titleId: 'Tersimpan!',
          titleEn: 'Saved!',
          titleZh: '已保存！',
          msgId: 'Konfigurasi berhasil disimpan.',
          msgEn: 'Configuration saved successfully.',
          msgZh: '配置保存成功。',
        );
      }
    } catch (e) {
      debugPrint('saveConfig error: $e');
    }
    if (mounted) setState(() => _configSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _buildConfigTab();
  }

  Widget _buildConfigTab() {
    if (_configLoading) {
      return _buildShimmer();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INFO CARD
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('Konfigurasi Sistem Verifikasi',
                            'Verification System Config', '验证系统配置'),
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      Text(
                        t('Ubah parameter verifikasi temuan di sini.',
                            'Edit finding verification parameters here.',
                            '在此编辑参数。'),
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // VERIFICATION DURATION
          _buildConfigSection(
            icon: Icons.timer_rounded,
            title: t('Durasi Verifikasi (Hari)',
                'Verification Duration (Days)', '验证时长（天）'),
            subtitle: t(
              'Temuan yang melebihi durasi ini akan difinalisasi otomatis.',
              'Findings exceeding this duration will be auto-finalized.',
              '超过此时限的发现将自动完成。',
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _durasiHari.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: _primaryColor,
                        inactiveColor: _primaryColor.withValues(alpha:0.2),
                        onChanged: (v) =>
                            setState(() => _durasiHari = v.toInt()),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _primaryColor.withValues(alpha:0.3)),
                      ),
                      child: Text(
                        '$_durasiHari',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 hari',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey.shade500)),
                    Text('30 hari',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // MINIMUM MAJORITY VOTES
          _buildConfigSection(
            icon: Icons.how_to_vote_rounded,
            title: t('Minimum Suara Mayoritas',
                'Minimum Majority Votes', '最少多数票'),
            subtitle: t(
              'Jika suara mayoritas mencapai angka ini, verifikasi langsung difinalisasi.',
              'When majority votes reach this number, verification is immediately finalized.',
              '当多数票达到此数字时，验证立即完成。',
            ),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _minSuara.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _primaryColor,
                    inactiveColor: _primaryColor.withValues(alpha:0.2),
                    onChanged: (v) => setState(() => _minSuara = v.toInt()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _primaryColor.withValues(alpha:0.3)),
                  ),
                  child: Text(
                    '$_minSuara',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // AUTO RESULT ON TIMEOUT
          _buildConfigSection(
            icon: Icons.auto_mode_rounded,
            title: t('Hasil Otomatis jika Timeout',
                'Auto Result on Timeout', '超时自动结果'),
            subtitle: t(
              'Jika tidak ada suara hingga batas waktu, hasil ditetapkan sebagai:',
              'If no votes until timeout, result is set as:',
              '如果超时无投票，结果设置为：',
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withValues(alpha:0.2)),
              ),
              child: Row(
                children: [
                  _buildToggleOption(
                    label: t('Valid', 'Valid', '有效'),
                    icon: Icons.thumb_up_rounded,
                    isSelected: _autoValid,
                    color: const Color(0xFF16A34A),
                    onTap: () => setState(() => _autoValid = true),
                  ),
                  _buildToggleOption(
                    label: t('Tidak Valid', 'Invalid', '无效'),
                    icon: Icons.thumb_down_rounded,
                    isSelected: !_autoValid,
                    color: const Color(0xFFDC2626),
                    onTap: () => setState(() => _autoValid = false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _configSaving ? null : _saveConfig,
              icon: _configSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                t('Simpan Konfigurasi', 'Save Configuration', '保存配置'),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // MANUAL AUTO FINALIZED BUTTON
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await _client.rpc('auto_finalize_timeout_temuan');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(t(
                        'Auto-finalisasi berhasil dijalankan.',
                        'Auto-finalization ran successfully.',
                        '自动完成运行成功。',
                      )),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                } catch (e) {
                  debugPrint('manual finalize error: $e');
                }
              },
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: Text(
                t('Jalankan Auto-Finalisasi Sekarang',
                    'Run Auto-Finalization Now', '立即运行自动完成'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConfigSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withValues(alpha:0.15)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha:0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: _primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: color.withValues(alpha:0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : color, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
              4,
              (_) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    height: 100,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                  )),
        ),
      ),
    );
  }
}