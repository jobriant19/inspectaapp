import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/utils/jabatan_helper.dart';
import '../../../accident/picker/accident_pick_cause.dart';
import '../../../accident/picker/accident_pick_severity.dart';
import '../accident_verification_history.dart';
import 'accident_verification_edit.dart';

class AccidentVerificationScreen extends StatefulWidget {
  final String lang;
  final int? userJabatanId;

  const AccidentVerificationScreen({
    super.key,
    required this.lang,
    this.userJabatanId,
  });

  @override
  State<AccidentVerificationScreen> createState() =>
      _AccidentVerificationScreenState();
}

class _AccidentVerificationScreenState
    extends State<AccidentVerificationScreen> {
  final _client = Supabase.instance.client;
  late String _lang;

  int _tabIndex = 0;

  bool _isAccidentLoading = true;
  bool _noAccidentData = false;
  bool _showAccidentSuccess = false;
   Map<String, dynamic>? _accidentData;
  int _accidentCountdown = 5;
  Timer? _accidentCountdownTimer;
  bool _showAccidentVerifPopup = false;
  bool _isAccidentVoteValid = false;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'tab_verify': 'Verify',
      'tab_history': 'History',
      'finding': 'Finding',
      'completion': 'Completion',
      'swipe_correct': 'VALID',
      'swipe_incorrect': 'SWIPE — INVALID',
      'wait_prefix': 'Please read carefully —',
      'wait_suffix': 's remaining',
      'swipe_now': 'Swipe right for Valid',
      'back': 'Back',
      'success_title': 'Verification Submitted',
      'success_body': 'Thank you! Continue to the next?',
      'continue_btn': 'Next Report',
      'auto_next': 'Auto-next in',
      'auto_suf': 's',
      'no_data_title': 'All Caught Up!',
      'no_data_body': 'No pending accident reports at the moment.',
      'verif_popup_valid': 'You voted VALID',
      'verif_popup_invalid': 'You voted INVALID',
      'verif_popup_sub': 'Your verification has been recorded.',
      'verif_popup_processing': 'Processing...',
    },
    'ID': {
      'tab_verify': 'Verifikasi',
      'tab_history': 'Riwayat',
      'finding': 'Temuan',
      'completion': 'Penyelesaian',
      'swipe_correct': 'VALID',
      'swipe_incorrect': 'GESER — TIDAK VALID',
      'wait_prefix': 'Baca dulu —',
      'wait_suffix': 'd tersisa',
      'swipe_now': 'Geser ke kanan untuk Valid',
      'back': 'Kembali',
      'success_title': 'Verifikasi Terkirim',
      'success_body': 'Terima kasih! Lanjut ke berikutnya?',
      'continue_btn': 'Laporan Berikutnya',
      'auto_next': 'Lanjut otomatis dalam',
      'auto_suf': 'd',
      'no_data_title': 'Semua Beres!',
      'no_data_body': 'Tidak ada laporan kecelakaan yang perlu diverifikasi saat ini.',
      'verif_popup_valid': 'Anda memilih VALID',
      'verif_popup_invalid': 'Anda memilih TIDAK VALID',
      'verif_popup_sub': 'Verifikasi Anda telah dicatat.',
      'verif_popup_processing': 'Memproses...',
    },
    'ZH': {
      'tab_verify': '验证',
      'tab_history': '历史',
      'finding': '发现',
      'completion': '完成',
      'swipe_correct': '有效',
      'swipe_incorrect': '滑动 — 无效',
      'wait_prefix': '请仔细阅读 —',
      'wait_suffix': '秒剩余',
      'swipe_now': '向右滑动以确认有效',
      'back': '返回',
      'success_title': '验证已提交',
      'success_body': '谢谢！继续下一个？',
      'continue_btn': '下一份报告',
      'auto_next': '自动继续于',
      'auto_suf': '秒',
      'no_data_title': '全部完成！',
      'no_data_body': '目前没有待处理的事故报告。',
      'verif_popup_valid': '您投票：有效',
      'verif_popup_invalid': '您投票：无效',
      'verif_popup_sub': '您的验证已记录。',
      'verif_popup_processing': '处理中...',
    },
  };

  String t(String key) => _txt[_lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _lang = widget.lang;
    _loadNextAccidentReport();
  }

  @override
  void dispose() {
    _accidentCountdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: _tabIndex == 0
                      ? _buildVerifyTab()
                      : AccidentVerificationHistoryScreen(
                          lang: _lang,
                          userJabatanId: widget.userJabatanId,
                        ),
                ),
              ],
            ),
            if (_showAccidentVerifPopup) _buildAccidentVerifPopupOverlay(),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HEADER & TAB BAR
  // ================================================================
  Widget _buildHeader() {
    String roleLabel;
    if (widget.userJabatanId == 2) {
      roleLabel = _lang == 'EN' ? 'Manager' : _lang == 'ZH' ? '经理' : 'Manager';
    } else {
      roleLabel = 'HRD';
    }

    final String screenTitle = _lang == 'EN'
        ? 'Accident Verification'
        : _lang == 'ZH'
            ? '事故验证'
            : 'Verifikasi Kecelakaan';

    List<Color> badgeColors;
    IconData badgeIcon;
    if (widget.userJabatanId == 2) {
      badgeColors = [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
      badgeIcon = Icons.workspace_premium_rounded;
    } else {
      badgeColors = [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      badgeIcon = Icons.people_rounded;
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
                  size: 18, color: Color(0xFF1E3A8A)),
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
                        ? const Color(0xFF1D72F3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _tabIndex == 1
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
                      Icon(Icons.history_rounded,
                          size: 15,
                          color: _tabIndex == 1
                              ? Colors.white
                              : const Color(0xFF1D72F3)),
                      const SizedBox(width: 5),
                      Text(
                        t('tab_history'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _tabIndex == 1
                              ? Colors.white
                              : const Color(0xFF1D72F3),
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

  Widget _buildVerifyTab() {
    if (_isAccidentLoading) return _buildVerifyShimmer();
    if (_showAccidentSuccess) return _buildAccidentSuccessView();
    if (_noAccidentData) return _buildNoDataView();
    if (_accidentData != null) return _buildAccidentVerificationCard();
    return const SizedBox();
  }

  Widget _buildVerifyShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14)))),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14)))),
            ]),
            const SizedBox(height: 14),
            Container(
                height: 72,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 8),
            Container(
                height: 72,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.task_alt_rounded,
                  size: 54, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 24),
            Text(t('no_data_title'),
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D72F3))),
            const SizedBox(height: 8),
            Text(t('no_data_body'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    height: 1.5)),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(t('back'),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1D72F3),
                side: const BorderSide(color: Color(0xFF1D72F3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ACCIDENT REPORT VERIFICATION — LOAD DATA
  // ================================================================
  Future<void> _loadNextAccidentReport() async {
    setState(() {
      _isAccidentLoading = true;
      _noAccidentData = false;
      _showAccidentSuccess = false;
      _accidentData = null;
      _showAccidentVerifPopup = false;
    });

    try {
      final userId = _client.auth.currentUser!.id;

      final votedLogs = await _client
          .from('accident_verifikasi_log')
          .select('id_laporan')
          .eq('id_verificator', userId);
      final List votedIds = votedLogs.map((l) => l['id_laporan']).toList();

      var query = _client.from('accident_report').select('''
        id_laporan, judul, deskripsi, foto_bukti,
        tanggal_kejadian, waktu_kejadian, penyebab,
        tingkat_keparahan, departemen_terdampak, tindakan_diambil,
        status, created_at, is_verif,
        nama_pihak_terdampak, nama_saksi,
        lokasi:id_lokasi(nama_lokasi),
        pelapor:accident_report_id_pelapor_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
        pihak_terdampak:accident_report_id_pihak_terdampak_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
        supervisor_user:accident_report_id_supervisor_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
        saksi_user:accident_report_id_saksi_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan))
      ''').eq('is_verif', false);

      if (votedIds.isNotEmpty) {
        query = query.not('id_laporan', 'in', votedIds);
      }

      final result = await query
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (result == null) {
        setState(() { _noAccidentData = true; _isAccidentLoading = false; });
        return;
      }

      setState(() {
        _accidentData = result;
        _isAccidentLoading = false;
      });
      _startAccidentCountdown();
    } catch (e) {
      debugPrint('loadNextAccidentReport error: $e');
      if (mounted) setState(() => _isAccidentLoading = false);
    }
  }

  void _startAccidentCountdown() {
    _accidentCountdownTimer?.cancel();
    setState(() => _accidentCountdown = 5);
    _accidentCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_accidentCountdown > 0) {
        setState(() => _accidentCountdown--);
      } else {
        timer.cancel();
        setState(() {});
      }
    });
  }

  Future<void> _submitAccidentVerification(bool isValid) async {
    if (_accidentData == null) return;
    _accidentCountdownTimer?.cancel();

    setState(() {
      _showAccidentVerifPopup = true;
      _isAccidentVoteValid = isValid;
    });

    final String lapdoranId = _accidentData!['id_laporan'].toString();
    final userId = _client.auth.currentUser!.id;

    try {
      await _client.from('accident_verifikasi_log').upsert({
        'id_laporan': lapdoranId,
        'id_verificator': userId,
        'jawaban_benar': isValid,
        'waktu_verifikasi': DateTime.now().toIso8601String(),
      }, onConflict: 'id_laporan,id_verificator');

      await _client.from('accident_report').update({
        'is_verif': true,
        'hasil_verifikasi_mayoritas': isValid,
        'status': isValid ? 'Ditinjau' : 'Selesai',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_laporan', lapdoranId);

    } catch (e) {
      debugPrint('submitAccidentVerification error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showAccidentVerifPopup = false;
        _showAccidentSuccess = true;
      });
    }
  }

  // ================================================================
  // ACCIDENT REPORT — UI WIDGETS (mengikuti gaya accident_detail_screen)
  // ================================================================

  Color _accidentStatusColor(String status) {
    switch (status) {
      case 'Ditinjau':
        return const Color(0xFF2563EB);
      case 'Selesai':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFDC2626);
    }
  }

  Color _accidentStatusBg(String status) {
    switch (status) {
      case 'Ditinjau':
        return const Color(0xFFEFF6FF);
      case 'Selesai':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFFFF1F2);
    }
  }

  String _accidentStatusLabel(String status) {
    switch (status) {
      case 'Ditinjau':
        return _lang == 'ID' ? 'Ditinjau' : _lang == 'ZH' ? '审核中' : 'Under Review';
      case 'Selesai':
        return _lang == 'ID' ? 'Selesai' : _lang == 'ZH' ? '已完成' : 'Finished';
      default:
        return _lang == 'ID' ? 'Belum Selesai' : _lang == 'ZH' ? '未完成' : 'Unfinished';
    }
  }

  IconData _accidentStatusIcon(String status) {
    switch (status) {
      case 'Ditinjau':
        return Icons.search_rounded;
      case 'Selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _formatAccidentDate(String? d) {
    if (d == null) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d).toLocal());
    } catch (_) {
      return d;
    }
  }

  Widget _buildAccidentVerificationCard() {
    final laporan = _accidentData!;
    final bool canSwipe = _accidentCountdown == 0;
    final String status = laporan['status'] ?? 'Menunggu';
    final String? rawSeverity = laporan['tingkat_keparahan'] as String?;
    final String severity = AccidentSeverityData.labelOf(rawSeverity, _lang);
    final Color sevColor = AccidentSeverityData.colorOf(rawSeverity);

    Map<String, dynamic>? getUserMap(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    }

    final pelapor = getUserMap(laporan['pelapor']);
    final victim = getUserMap(laporan['pihak_terdampak']);
    final supervisor = getUserMap(laporan['supervisor_user']);
    final witness = getUserMap(laporan['saksi_user']);

    final List<Color> headerColors = widget.userJabatanId == 2
        ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
        : [const Color(0xFFDC2626), const Color(0xFFB91C1C)];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FOTO
          if (laporan['foto_bukti'] != null) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black.withValues(alpha: 0.95),
                  transitionDuration: const Duration(milliseconds: 200),
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder: (_, __, ___) => AccidentFullscreenImageViewer(
                    imageUrl: laporan['foto_bukti'],
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.network(
                        laporan['foto_bukti'],
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 240,
                          color: Colors.grey.shade100,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: Colors.grey.shade400, size: 48),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fullscreen_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // TITLE CARD — sama seperti accident detail
          _buildDetailStyleTitleCard(laporan, status, severity, rawSeverity, sevColor),
          const SizedBox(height: 20),

          // DESKRIPSI
          if (laporan['deskripsi'] != null &&
              laporan['deskripsi'].toString().isNotEmpty) ...[
            _buildDetailStyleSectionTitle(
                Icons.description_outlined,
                _lang == 'ID'
                    ? 'Deskripsi Detail'
                    : _lang == 'ZH'
                        ? '详细描述'
                        : 'Detailed Description'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
              ),
              child: Text(laporan['deskripsi'],
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // TINDAKAN DIAMBIL
          if (laporan['tindakan_diambil'] != null &&
              laporan['tindakan_diambil'].toString().isNotEmpty) ...[
            _buildDetailStyleSectionTitle(
                Icons.medical_services_outlined,
                _lang == 'ID'
                    ? 'Tindakan Diambil'
                    : _lang == 'ZH'
                        ? '采取的措施'
                        : 'Action Taken',
                color: const Color(0xFF1D72F3)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
              ),
              child: Text(laporan['tindakan_diambil'],
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // PIHAK TERLIBAT
          _buildDetailStyleSectionTitle(
              Icons.people_alt_rounded,
              _lang == 'ID'
                  ? 'Pihak Terlibat'
                  : _lang == 'ZH'
                      ? '涉及人员'
                      : 'Involved Parties'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
            ),
            child: Column(
              children: [
                if (pelapor != null)
                  _buildDetailStylePersonRow(
                      _lang == 'ID'
                          ? 'Dilaporkan oleh'
                          : _lang == 'ZH'
                              ? '报告人'
                              : 'Reported by',
                      pelapor,
                      Icons.person_rounded),

                if (victim != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildDetailStylePersonRow(
                      _lang == 'ID'
                          ? 'Pihak Terdampak'
                          : _lang == 'ZH'
                              ? '受影响方'
                              : 'Affected Party',
                      victim,
                      Icons.person_outline),
                ] else if (laporan['nama_pihak_terdampak'] != null &&
                    laporan['nama_pihak_terdampak'].toString().isNotEmpty) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildDetailStyleManualPersonRow(
                      _lang == 'ID'
                          ? 'Pihak Terdampak'
                          : _lang == 'ZH'
                              ? '受影响方'
                              : 'Affected Party',
                      laporan['nama_pihak_terdampak'].toString(),
                      Icons.person_outline),
                ],

                if (supervisor != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildDetailStylePersonRow(
                      'Supervisor', supervisor, Icons.supervisor_account_outlined),
                ],

                if (witness != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildDetailStylePersonRow(
                      _lang == 'ID'
                          ? 'Saksi'
                          : _lang == 'ZH'
                              ? '目击者'
                              : 'Witness',
                      witness,
                      Icons.visibility_outlined),
                ] else if (laporan['nama_saksi'] != null &&
                    laporan['nama_saksi'].toString().isNotEmpty) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildDetailStyleManualPersonRow(
                      _lang == 'ID'
                          ? 'Saksi'
                          : _lang == 'ZH'
                              ? '目击者'
                              : 'Witness',
                      laporan['nama_saksi'].toString(),
                      Icons.visibility_outlined),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // INFO CARD — lokasi, tanggal, waktu, penyebab, departemen
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailStyleInfoRowBadge(
                    Icons.map,
                    _lang == 'ID' ? 'Lokasi Kejadian' : _lang == 'ZH' ? '事故地点' : 'Incident Location',
                    _buildDetailStyleValueBadge(Icons.location_city_rounded,
                        laporan['lokasi']?['nama_lokasi'] ?? '-',
                        const Color(0xFF10B981))),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                _buildDetailStyleInfoRow(
                    Icons.calendar_today_outlined,
                    _lang == 'ID' ? 'Tanggal' : _lang == 'ZH' ? '日期' : 'Date',
                    _formatAccidentDate(laporan['tanggal_kejadian']?.toString())),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                _buildDetailStyleInfoRow(
                    Icons.access_time_rounded,
                    _lang == 'ID' ? 'Waktu' : _lang == 'ZH' ? '时间' : 'Time',
                    laporan['waktu_kejadian']?.toString().substring(0, 5) ?? '-'),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                _buildDetailStyleInfoRowBadge(
                    Icons.warning_amber_rounded,
                    _lang == 'ID' ? 'Penyebab' : _lang == 'ZH' ? '原因' : 'Cause',
                    _buildDetailStyleValueBadge(
                        AccidentCauseData.iconOf(laporan['penyebab'] as String?),
                        AccidentCauseData.labelOf(laporan['penyebab'] as String?, _lang),
                        AccidentCauseData.colorOf(laporan['penyebab'] as String?))),
                if (laporan['departemen_terdampak'] != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildDetailStyleInfoRowBadge(
                      Icons.business_outlined,
                      _lang == 'ID' ? 'Departemen' : _lang == 'ZH' ? '部门' : 'Department',
                      _buildDetailStyleValueBadge(Icons.business_rounded,
                          laporan['departemen_terdampak'], const Color(0xFF6366F1))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AREA VERIFIKASI — hanya swipe VALID + info edit untuk kasus invalid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: canSwipe
                        ? headerColors.first.withValues(alpha: 0.08)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canSwipe
                          ? headerColors.first.withValues(alpha: 0.3)
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canSwipe ? Icons.swipe_rounded : Icons.timer_outlined,
                        size: 18,
                        color: canSwipe ? headerColors.first : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canSwipe
                            ? t('swipe_now')
                            : '${t("wait_prefix")} $_accidentCountdown ${t("wait_suffix")}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: canSwipe ? headerColors.first : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: _SwipeButton(
                    label: t('swipe_correct'),
                    color: const Color(0xFF16A34A),
                    icon: Icons.arrow_forward_rounded,
                    direction: _SwipeDirection.leftToRight,
                    enabled: canSwipe,
                    onSwiped: () => _submitAccidentVerification(true),
                  ),
                ),
                const SizedBox(height: 14),

                // Info pengganti swipe invalid
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _lang == 'ID'
                              ? 'Laporan tidak valid? Edit datanya di bawah.'
                              : _lang == 'ZH'
                                  ? '报告无效？请在下方编辑数据。'
                                  : 'Report invalid? Edit the data below.',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF991B1B),
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ACCIDENT REPORT EDIT — dipindah ke paling bawah
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => AccidentVerificationEditScreen(
                    lang: _lang,
                    laporan: laporan,
                  ),
                ),
              );
              if (updated != null && mounted) {
                setState(() => _accidentData = updated);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: headerColors.last.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lang == 'ID'
                              ? 'Edit Laporan Kecelakaan'
                              : _lang == 'ZH'
                                  ? '编辑事故报告'
                                  : 'Accident Report Edit',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _lang == 'ID'
                              ? 'Ketuk untuk meninjau dan mengedit laporan'
                              : _lang == 'ZH'
                                  ? '点击以审查并编辑报告'
                                  : 'Tap to review and edit the report',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Widget-widget bergaya accident_detail_screen ─────────────
  Widget _buildDetailStyleTitleCard(Map<String, dynamic> d, String status,
      String severity, String? rawSeverity, Color sevColor) {
    final statusColor = _accidentStatusColor(status);
    final statusBg = _accidentStatusBg(status);
    final statusIcon = _accidentStatusIcon(status);
    final statusText = _accidentStatusLabel(status);
    const badgeColor = Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d['judul'] ?? '-',
                  style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.3),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: badgeColor, width: 1.2),
                ),
                child: Text(
                  _lang == 'ID'
                      ? 'LAPORAN KECELAKAAN'
                      : _lang == 'ZH'
                          ? '事故报告'
                          : 'ACCIDENT REPORT',
                  style: GoogleFonts.inter(
                      color: badgeColor, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sevColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(AccidentSeverityData.iconOf(rawSeverity), size: 13, color: sevColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        severity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: sevColor),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 5),
                  Text(statusText,
                      style: GoogleFonts.inter(
                          fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStyleSectionTitle(IconData icon, String title,
      {Color color = const Color(0xFF1D72F3)}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
      ],
    );
  }

  Widget _buildDetailStyleInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1D72F3), size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
          const Spacer(),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStyleInfoRowBadge(IconData icon, String label, Widget valueBadge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1D72F3), size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
          const Spacer(),
          valueBadge,
        ],
      ),
    );
  }

  Widget _buildDetailStyleValueBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _accidentJabatanLabel(Map<String, dynamic> user) {
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final jabatanNama =
        (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
    return JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: _lang,
    );
  }

  Widget _buildDetailStyleJabatanBadge(Map<String, dynamic> user) {
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final label = _accidentJabatanLabel(user);
    if (label.isEmpty) return const SizedBox.shrink();
    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildDetailStylePersonRow(String label, Map<String, dynamic> user, IconData icon) {
    final jabatanText = _accidentJabatanLabel(user);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1D72F3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
          ),
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                user['gambar_user'] != null
                    ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(user['gambar_user']))
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 20, color: Color(0xFF1D72F3)),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nama'] ?? '-',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
                      ),
                      if (jabatanText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildDetailStyleJabatanBadge(user),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStyleManualPersonRow(String label, String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1D72F3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
          ),
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 20, color: Color(0xFF1D72F3)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccidentSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha:0.4),
                    blurRadius: 20, spreadRadius: 4)],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
            ),
            const SizedBox(height: 24),
            Text(t('success_title'),
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D72F3))),
            const SizedBox(height: 8),
            Text(t('success_body'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _loadNextAccidentReport,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(t('continue_btn'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CountdownAutoNext(
              textPrefix: t('auto_next'),
              textSuffix: t('auto_suf'),
              onFinished: _loadNextAccidentReport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccidentVerifPopupOverlay() {
    final Color primary =
        _isAccidentVoteValid ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData icon =
        _isAccidentVoteValid ? Icons.thumb_up_rounded : Icons.thumb_down_rounded;
    final String title =
        _isAccidentVoteValid ? t('verif_popup_valid') : t('verif_popup_invalid');

    return Container(
      color: Colors.black.withValues(alpha:0.65),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: primary.withValues(alpha:0.3), width: 2),
              boxShadow: [
                BoxShadow(color: primary.withValues(alpha:0.25),
                    blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha:0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withValues(alpha:0.4), width: 2.5),
                  ),
                  child: Icon(icon, color: primary, size: 38),
                ),
                const SizedBox(height: 16),
                Text(title, style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w800, color: primary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(t('verif_popup_sub'),
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
                  const SizedBox(width: 8),
                  Text(t('verif_popup_processing'),
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// SUB-WIDGETS khusus accident (duplikat dari executive_verification_screen.dart
// karena class privat Dart tidak bisa diimpor lintas file)
// ──────────────────────────────────────────────────────────────

enum _SwipeDirection { leftToRight, rightToLeft }

class _SwipeButton extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final _SwipeDirection direction;
  final bool enabled;
  final VoidCallback onSwiped;

  const _SwipeButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.direction,
    required this.enabled,
    required this.onSwiped,
  });

  @override
  State<_SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<_SwipeButton>
    with SingleTickerProviderStateMixin {
  double _drag = 0;
  late AnimationController _snapCtrl;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d, double maxW) {
    if (!widget.enabled) return;
    final isLTR = widget.direction == _SwipeDirection.leftToRight;
    final newDrag = _drag + (isLTR ? d.delta.dx : -d.delta.dx);
    setState(() => _drag = newDrag.clamp(0.0, maxW - 56));
  }

  void _onDragEnd(DragEndDetails d, double maxW) {
    if (!widget.enabled) return;
    final threshold = (maxW - 56) * 0.75;
    if (_drag >= threshold) {
      widget.onSwiped();
      setState(() => _drag = 0);
    } else {
      final anim = Tween<double>(begin: _drag, end: 0).animate(
          CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut));
      anim.addListener(() {
        if (mounted) setState(() => _drag = anim.value);
      });
      _snapCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final maxW = constraints.maxWidth;
      final trackW = maxW - 56;
      final opacity = ((trackW - _drag) / trackW).clamp(0.0, 1.0);
      final isRTL = widget.direction == _SwipeDirection.rightToLeft;

      return GestureDetector(
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxW),
        onHorizontalDragEnd: (d) => _onDragEnd(d, maxW),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: widget.enabled
                ? widget.color.withValues(alpha:0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.enabled
                  ? widget.color.withValues(alpha:0.4)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: isRTL ? 0 : 50, right: isRTL ? 50 : 0),
                child: Opacity(
                  opacity: widget.enabled ? opacity : 1.0,
                  child: Text(widget.label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: widget.enabled
                              ? widget.color
                              : Colors.grey.shade400,
                          letterSpacing: 0.5),
                      overflow: TextOverflow.fade,
                      softWrap: false),
                ),
              ),
              Positioned(
                left: isRTL ? null : 6 + _drag,
                right: isRTL ? 6 + _drag : null,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? widget.color
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: widget.enabled
                        ? [
                            BoxShadow(
                                color: widget.color.withValues(alpha:0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _CountdownAutoNext extends StatefulWidget {
  final String textPrefix;
  final String textSuffix;
  final VoidCallback onFinished;

  const _CountdownAutoNext({
    required this.textPrefix,
    required this.textSuffix,
    required this.onFinished,
  });

  @override
  State<_CountdownAutoNext> createState() => _CountdownAutoNextState();
}

class _CountdownAutoNextState extends State<_CountdownAutoNext> {
  int _count = 8;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_count > 1) {
        setState(() => _count--);
      } else {
        t.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('${widget.textPrefix} $_count ${widget.textSuffix}',
        style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87));
  }
}