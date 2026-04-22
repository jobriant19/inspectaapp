import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/notification_service.dart';

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

class _ExecVerificationScreenState extends State<ExecVerificationScreen>
    with TickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late String _lang;

  bool _isLoading = true;
  bool _noData = false;
  bool _showSuccess = false;
  Map<String, dynamic>? _temuanData;

  bool _showHistory = false;
  bool _historyLoading = false;
  List<Map<String, dynamic>> _historyList = [];
  Map<int, Map<String, dynamic>> _voteStats = {};
  Map<int, int> _historyPointMap = {};

  int _countdown = 5;
  Timer? _countdownTimer;
  int _verificationSecondsLeft = 300;
  Timer? _verificationTimer;
  bool _verificationExpired = false;
  bool _allVotedByUser = false;

  int _tabIndex = 0;

  // ── Popup state untuk notif verifikasi ──
  bool _showVerifPopup = false;
  bool _isVoteValid = false;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'screen_title': 'Executive Verification',
      'tab_verify': 'Verify',
      'tab_history': 'History',
      'card_title': 'Verification Review',
      'card_subtitle': 'Examine the finding & completion carefully. Is this report valid?',
      'finding': 'Finding',
      'completion': 'Completion',
      'finding_notes': 'Finding Notes',
      'completion_notes': 'Completion Notes',
      'category': 'Category',
      'location': 'Location',
      'swipe_correct': 'SWIPE — VALID',
      'swipe_incorrect': 'SWIPE — INVALID',
      'wait_prefix': 'Please read carefully —',
      'wait_suffix': 's remaining',
      'swipe_now': 'Swipe left or right to respond',
      'no_data_title': 'All Caught Up!',
      'no_data_body': 'No pending reports at the moment. Great work, Executive!',
      'back': 'Back',
      'success_title': 'Verification Submitted',
      'success_body': 'Thank you! Continue to the next?',
      'continue_btn': 'Next Report',
      'auto_next': 'Auto-next in',
      'auto_suf': 's',
      'hist_title': 'Verification History',
      'hist_empty': 'No history yet.',
      'your_vote': 'Your Vote',
      'majority': 'Majority',
      'minority': 'Minority',
      'pending': 'Pending',
      'valid': 'Valid',
      'invalid': 'Invalid',
      'accident_restricted': 'Accident reports can only be verified by HRD.',
      'vote_breakdown': 'Vote Breakdown',
      'total_votes': 'Total Votes',
      'majority_result': 'Majority Result',
      'your_points': 'Your Points',
      'votes_valid': 'Valid',
      'votes_invalid': 'Invalid',
      'finalized': 'Finalized',
      'not_finalized': 'In Progress',
      'point_earned': 'Points Earned',
      'point_deducted': 'Points Deducted',
      'participation': 'Participation',
      'verif_popup_valid': 'You voted VALID',
      'verif_popup_invalid': 'You voted INVALID',
      'verif_popup_sub': 'Your verification has been recorded.',
      'verif_popup_point': 'Participation Points',
      'verif_popup_processing': 'Processing...',
    },
    'ID': {
      'screen_title': 'Verifikasi Eksekutif',
      'tab_verify': 'Verifikasi',
      'tab_history': 'Riwayat',
      'card_title': 'Tinjauan Verifikasi',
      'card_subtitle': 'Periksa temuan & penyelesaian dengan teliti. Apakah laporan ini valid?',
      'finding': 'Temuan',
      'completion': 'Penyelesaian',
      'finding_notes': 'Catatan Temuan',
      'completion_notes': 'Catatan Penyelesaian',
      'category': 'Kategori',
      'location': 'Lokasi',
      'swipe_correct': 'GESER — VALID',
      'swipe_incorrect': 'GESER — TIDAK VALID',
      'wait_prefix': 'Baca dulu —',
      'wait_suffix': 'd tersisa',
      'swipe_now': 'Geser kiri atau kanan untuk menjawab',
      'no_data_title': 'Semua Beres!',
      'no_data_body': 'Tidak ada laporan yang perlu diverifikasi saat ini.',
      'back': 'Kembali',
      'success_title': 'Verifikasi Terkirim',
      'success_body': 'Terima kasih! Lanjut ke berikutnya?',
      'continue_btn': 'Laporan Berikutnya',
      'auto_next': 'Lanjut otomatis dalam',
      'auto_suf': 'd',
      'hist_title': 'Riwayat Verifikasi',
      'hist_empty': 'Belum ada riwayat.',
      'your_vote': 'Pilihan Anda',
      'majority': 'Mayoritas',
      'minority': 'Minoritas',
      'pending': 'Menunggu',
      'valid': 'Valid',
      'invalid': 'Tidak Valid',
      'accident_restricted': 'Laporan kecelakaan hanya dapat diverifikasi oleh HRD.',
      'vote_breakdown': 'Rincian Suara',
      'total_votes': 'Total Suara',
      'majority_result': 'Hasil Mayoritas',
      'your_points': 'Poin Anda',
      'votes_valid': 'Valid',
      'votes_invalid': 'Tidak Valid',
      'finalized': 'Final',
      'not_finalized': 'Berlangsung',
      'point_earned': 'Poin Diperoleh',
      'point_deducted': 'Poin Dikurangi',
      'participation': 'Partisipasi',
      'verif_popup_valid': 'Anda memilih VALID',
      'verif_popup_invalid': 'Anda memilih TIDAK VALID',
      'verif_popup_sub': 'Verifikasi Anda telah dicatat.',
      'verif_popup_point': 'Poin Partisipasi',
      'verif_popup_processing': 'Memproses...',
    },
    'ZH': {
      'screen_title': '高管验证',
      'tab_verify': '验证',
      'tab_history': '历史',
      'card_title': '验证审查',
      'card_subtitle': '仔细检查发现和完成情况。此报告是否有效？',
      'finding': '发现',
      'completion': '完成',
      'finding_notes': '发现说明',
      'completion_notes': '完成说明',
      'category': '类别',
      'location': '地点',
      'swipe_correct': '滑动 — 有效',
      'swipe_incorrect': '滑动 — 无效',
      'wait_prefix': '请仔细阅读 —',
      'wait_suffix': '秒剩余',
      'swipe_now': '向左或向右滑动作答',
      'no_data_title': '全部完成！',
      'no_data_body': '目前没有待处理的报告。',
      'back': '返回',
      'success_title': '验证已提交',
      'success_body': '谢谢！继续下一个？',
      'continue_btn': '下一份报告',
      'auto_next': '自动继续于',
      'auto_suf': '秒',
      'hist_title': '验证历史',
      'hist_empty': '暂无历史记录。',
      'your_vote': '您的投票',
      'majority': '多数',
      'minority': '少数',
      'pending': '待定',
      'valid': '有效',
      'invalid': '无效',
      'accident_restricted': '事故报告只能由HRD验证。',
      'vote_breakdown': '投票详情',
      'total_votes': '总票数',
      'majority_result': '多数结果',
      'your_points': '您的积分',
      'votes_valid': '有效',
      'votes_invalid': '无效',
      'finalized': '已终结',
      'not_finalized': '进行中',
      'point_earned': '获得积分',
      'point_deducted': '扣除积分',
      'participation': '参与',
      'verif_popup_valid': '您投票：有效',
      'verif_popup_invalid': '您投票：无效',
      'verif_popup_sub': '您的验证已记录。',
      'verif_popup_point': '参与积分',
      'verif_popup_processing': '处理中...',
    },
  };

  String t(String key) => _txt[_lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _lang = widget.lang;
    _loadNextTemuan();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNextTemuan() async {
    setState(() {
      _isLoading = true;
      _noData = false;
      _showSuccess = false;
      _temuanData = null;
      _showVerifPopup = false;
    });

    try {
      final userId = _client.auth.currentUser!.id;

      final verifiedLogs = await _client
          .from('verifikasi_log')
          .select('id_temuan')
          .eq('id_verificator', userId);

      final List<dynamic> verifiedIds =
          verifiedLogs.map<dynamic>((l) => l['id_temuan']).toList();

      var query = _client.from('temuan').select('''
        id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, status_temuan,
        id_kategoritemuan,
        penyelesaian:id_penyelesaian (gambar_penyelesaian, catatan_penyelesaian),
        kategoritemuan:id_kategoritemuan (nama_kategoritemuan),
        lokasi:id_lokasi(nama_lokasi),
        area:id_area(nama_area),
        unit:id_unit(nama_unit)
      ''')
          .eq('status_temuan', 'Selesai')
          .eq('is_verif', false);

      if (verifiedIds.isNotEmpty) {
        query = query.not('id_temuan', 'in', verifiedIds);
      }

      final result = await query
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (result == null) {
        final totalEligible = await _client
            .from('temuan')
            .select('id_temuan')
            .eq('status_temuan', 'Selesai')
            .eq('is_verif', false);

        setState(() {
          _noData = true;
          _isLoading = false;
          _allVotedByUser = verifiedIds.isNotEmpty &&
              totalEligible
                  .every((t) => verifiedIds.contains(t['id_temuan']));
        });
        return;
      }

      final String katName =
          (result['kategoritemuan']?['nama_kategoritemuan']?.toString() ?? '')
              .toLowerCase();
      final bool isAccident =
          katName.contains('kecelakaan') || katName.contains('accident');
      const int hrdJabatanId = 5;
      final bool isHrd = widget.userJabatanId == hrdJabatanId;

      if (isAccident && !isHrd) {
        final verifiedIdsUpdated = List<dynamic>.from(verifiedIds)
          ..add(result['id_temuan']);

        var queryNext = _client.from('temuan').select('''
          id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, status_temuan,
          id_kategoritemuan,
          penyelesaian:id_penyelesaian (gambar_penyelesaian, catatan_penyelesaian),
          kategoritemuan:id_kategoritemuan (nama_kategoritemuan),
          lokasi:id_lokasi(nama_lokasi),
          area:id_area(nama_area),
          unit:id_unit(nama_unit)
        ''')
            .eq('status_temuan', 'Selesai')
            .eq('is_verif', false)
            .not('id_temuan', 'in', verifiedIdsUpdated);

        final nextResult = await queryNext
            .order('created_at', ascending: true)
            .limit(1)
            .maybeSingle();

        if (!mounted) return;

        if (nextResult == null) {
          setState(() {
            _noData = true;
            _isLoading = false;
            _allVotedByUser = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('accident_restricted'),
                    style: GoogleFonts.poppins(color: Colors.white)),
                backgroundColor: Colors.orange.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          return;
        }

        setState(() {
          _temuanData = nextResult;
          _isLoading = false;
          _allVotedByUser = false;
        });
        _startCountdown();
        return;
      }

      setState(() {
        _temuanData = result;
        _isLoading = false;
        _allVotedByUser = false;
      });
      _startCountdown();
    } catch (e) {
      debugPrint('ExecVerif loadNextTemuan error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 5);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() {});
      }
    });
    _startVerificationTimer();
  }

  void _startVerificationTimer() {
    _verificationTimer?.cancel();
    setState(() {
      _verificationSecondsLeft = 300;
      _verificationExpired = false;
    });
    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_verificationSecondsLeft > 0) {
        setState(() => _verificationSecondsLeft--);
      } else {
        timer.cancel();
        setState(() => _verificationExpired = true);
        _loadNextTemuan();
      }
    });
  }

  // ══════════════════════════════════════════════════════
  // SUBMIT VERIFIKASI — Tampilkan popup DULU, proses background
  // ══════════════════════════════════════════════════════
  Future<void> _submitVerification(bool isValid) async {
    if (_temuanData == null) return;
    _verificationTimer?.cancel();

    // 1. Tampilkan popup langsung (sebelum proses berat)
    setState(() {
      _showVerifPopup = true;
      _isVoteValid = isValid;
    });

    final temuanId = _temuanData!['id_temuan'] as int;
    final temuanTitle = _temuanData!['judul_temuan']?.toString() ?? '-';
    final temuanImg = _temuanData!['gambar_temuan']?.toString();
    final completionImg =
        _temuanData!['penyelesaian']?['gambar_penyelesaian']?.toString();
    final findingNotes = _temuanData!['deskripsi_temuan']?.toString() ?? '-';
    final completionNotes =
        _temuanData!['penyelesaian']?['catatan_penyelesaian']?.toString() ??
            '-';

    // 2. Proses berat di background
    try {
      final userId = _client.auth.currentUser!.id;

      // Catat vote
      await _client.rpc('handle_verification_vote', params: {
        'p_temuan_id': temuanId,
        'p_verificator_id': userId,
        'p_vote_is_correct': isValid,
        'p_point_change': 0,
      });

      // Ambil konfigurasi poin partisipasi
      int pointParticipation = 10;
      String descParticipation = '';

      try {
        final configs = await _client
            .from('konfigurasi_poin')
            .select('kode, poin, deskripsi_template')
            .eq('kode', 'verifikasi_partisipasi')
            .eq('is_aktif', true)
            .limit(1);

        if (configs.isNotEmpty) {
          pointParticipation =
              (configs.first['poin'] as num).toInt().abs();
          descParticipation =
              configs.first['deskripsi_template']?.toString() ?? '';
        }
      } catch (e) {
        debugPrint('Gagal ambil konfigurasi_poin: $e');
      }

      if (descParticipation.isEmpty) {
        descParticipation = _lang == 'EN'
            ? 'Thank you for participating in verification. +$pointParticipation points!'
            : _lang == 'ZH'
                ? '感谢您参与验证。+$pointParticipation积分！'
                : 'Terima kasih telah berpartisipasi dalam verifikasi. +$pointParticipation poin!';
      }

      // Beri poin partisipasi
      await _addPointsToUser(
        userId: userId,
        points: pointParticipation,
        desc: descParticipation,
        tipe: 'verifikasi_partisipasi',
      );

      // Trigger animasi poin di HomeScreen
      if (mounted) {
        widget.onPointEarned?.call(pointParticipation);
      }

      // Notifikasi partisipasi
      NotificationService.instance.showNotification(
        title: _lang == 'EN'
            ? '✅ Verification Recorded'
            : _lang == 'ZH'
                ? '✅ 验证已记录'
                : '✅ Verifikasi Dicatat',
        body: descParticipation,
      );

      // Tampilkan popup poin partisipasi setelah 1.5 detik (saat popup verif masih di layar)
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        _showVerifPointDialog(
          pointParticipation,
          descParticipation,
          'verifikasi_partisipasi',
        );
      }

      // Set success state
      if (mounted) {
        setState(() {
          _showVerifPopup = false;
          _showSuccess = true;
        });
      }
    } catch (e) {
      debugPrint('Submit verif error: $e');
      if (mounted) {
        setState(() {
          _showVerifPopup = false;
          _showSuccess = true;
        });
      }
    }
  }

  Future<void> _addPointsToUser({
    required String userId,
    required int points,
    required String desc,
    required String tipe,
  }) async {
    try {
      await _client.from('log_poin').insert({
        'id_user': userId,
        'poin': points,
        'deskripsi': desc,
        'tipe_aktivitas': tipe,
      });

      final row = await _client
          .from('User')
          .select('poin')
          .eq('id_user', userId)
          .single();

      final int currentPoin = (row['poin'] as num?)?.toInt() ?? 0;

      await _client
          .from('User')
          .update({'poin': currentPoin + points}).eq('id_user', userId);
    } catch (e) {
      debugPrint(
          '_addPointsToUser error (userId=$userId, points=$points): $e');
    }
  }

  void _showVerifPointDialog(int points, String description, String tipe) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 4500), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        final bool isPositive = points > 0;
        final Color primary =
            isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final String pointLabel =
            isPositive ? '+$points' : '$points';
        final IconData icon = isPositive
            ? Icons.verified_rounded
            : Icons.warning_amber_rounded;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: primary.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: primary.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 4,
                        offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32)),
                      ),
                      child: Column(children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: primary.withOpacity(0.3), width: 2),
                          ),
                          child: Icon(icon, color: primary, size: 36),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '$pointLabel ${_lang == 'ZH' ? '积分' : 'Poin'}',
                            style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                      child: Column(children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: primary.withOpacity(0.12), width: 1),
                          ),
                          child: Text(
                            description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E3A8A),
                                height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: const Duration(milliseconds: 4500),
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 3,
                              backgroundColor: primary.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  primary.withOpacity(0.45)),
                            ),
                            child: null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lang == 'EN'
                              ? 'Tap anywhere to close'
                              : _lang == 'ZH'
                                  ? '点击任意处关闭'
                                  : 'Ketuk di mana saja untuk menutup',
                          style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: Colors.grey.shade400),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final userId = _client.auth.currentUser!.id;

      final response = await _client
          .from('verifikasi_log')
          .select('''
            id_log,
            jawaban_benar,
            waktu_verifikasi,
            temuan:id_temuan (
              id_temuan,
              judul_temuan,
              deskripsi_temuan,
              gambar_temuan,
              status_temuan,
              is_verif,
              hasil_verifikasi_mayoritas,
              created_at,
              lokasi:id_lokasi (nama_lokasi),
              area:id_area (nama_area),
              unit:id_unit (nama_unit),
              kategoritemuan:id_kategoritemuan (nama_kategoritemuan),
              penyelesaian:id_penyelesaian (
                gambar_penyelesaian,
                catatan_penyelesaian,
                tanggal_selesai
              )
            )
          ''')
          .eq('id_verificator', userId)
          .order('waktu_verifikasi', ascending: false);

      final List<Map<String, dynamic>> processed = [];
      final List<int> temuanIds = [];

      for (final item in response) {
        final rawTemuan = item['temuan'];
        if (rawTemuan == null) continue;
        final data = Map<String, dynamic>.from(rawTemuan as Map);
        data['user_vote'] = item['jawaban_benar'] as bool? ?? false;
        data['waktu_verifikasi'] = item['waktu_verifikasi'];
        data['id_log'] = item['id_log'];
        processed.add(data);
        final tid = data['id_temuan'] as int?;
        if (tid != null) temuanIds.add(tid);
      }

      final Map<int, Map<String, dynamic>> voteStats = {};
      if (temuanIds.isNotEmpty) {
        final allVotes = await _client
            .from('verifikasi_log')
            .select('id_temuan, jawaban_benar')
            .inFilter('id_temuan', temuanIds);

        // Hitung total verificator gabungan: id_jabatan=1 AND is_verificator=true
        // PLUS semua is_verificator=true (union, deduplicated)
        int totalVerificators = 0;
        try {
          // Ambil semua user dengan id_jabatan=1 ATAU is_verificator=true
          // sesuai query: WHERE id_jabatan = 1 OR is_verificator = true
          final jabatanUsers = await _client
              .from('User')
              .select('id_user')
              .eq('id_jabatan', 1);
          
          final verifUsers = await _client
              .from('User')
              .select('id_user')
              .eq('is_verificator', true);

          // Gabungkan dengan deduplikasi (union)
          final Set<String> allIds = {};
          for (final v in jabatanUsers) {
            allIds.add(v['id_user'].toString());
          }
          for (final v in verifUsers) {
            allIds.add(v['id_user'].toString());
          }
          totalVerificators = allIds.length;

          // Fallback minimal
          if (totalVerificators == 0) totalVerificators = 1;
        } catch (e) {
          debugPrint('Load verificators error: $e');
          totalVerificators = 1;
        }

        for (final tid in temuanIds) {
          final votesForTemuan =
              allVotes.where((v) => v['id_temuan'] == tid).toList();
          final int validCount =
              votesForTemuan.where((v) => v['jawaban_benar'] == true).length;
          final int invalidCount =
              votesForTemuan.where((v) => v['jawaban_benar'] == false).length;
          voteStats[tid] = {
            'valid_count': validCount,
            'invalid_count': invalidCount,
            'total': validCount + invalidCount,
            'total_verificators': totalVerificators,
          };
        }
      }

      // Poin map
      final Map<int, int> pointMap = {};
      try {
        final pointLogs = await _client
            .from('log_poin')
            .select('poin, tipe_aktivitas, created_at, deskripsi')
            .eq('id_user', userId)
            .inFilter('tipe_aktivitas', [
              'verifikasi_partisipasi',
              'verifikasi_benar',
              'verifikasi_salah',
            ])
            .order('created_at', ascending: false);

        for (int i = 0; i < processed.length; i++) {
          final tid = processed[i]['id_temuan'] as int?;
          if (tid == null) continue;

          // Cek log yang punya marker #T{id}
          int net = 0;
          for (final log in pointLogs) {
            final desc = log['deskripsi']?.toString() ?? '';
            final tipe = log['tipe_aktivitas']?.toString() ?? '';

            // Partisipasi: cari berdasarkan waktu ±30 detik
            if (tipe == 'verifikasi_partisipasi') {
              final rawWaktu = processed[i]['waktu_verifikasi'];
              if (rawWaktu != null) {
                final verifyTime =
                    DateTime.parse(rawWaktu.toString()).toUtc();
                final rawCt = log['created_at'];
                if (rawCt != null) {
                  final logTime = DateTime.parse(rawCt.toString()).toUtc();
                  if (logTime.difference(verifyTime).inSeconds.abs() <= 30) {
                    net += (log['poin'] as num).toInt();
                  }
                }
              }
            }
            // Bonus/penalti: cari berdasarkan marker #T{id}
            else if (desc.contains('#T$tid')) {
              net += (log['poin'] as num).toInt();
            }
          }
          pointMap[tid] = net;
        }
      } catch (e) {
        debugPrint('Load point map error: $e');
      }

      if (mounted) {
        setState(() {
          _historyList = processed;
          _voteStats = voteStats;
          _historyPointMap = pointMap;
          _historyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load history error: $e');
      if (mounted) setState(() => _historyLoading = false);
    }
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
                  child:
                      _tabIndex == 0 ? _buildVerifyTab() : _buildHistoryTab(),
                ),
              ],
            ),
            // ── Popup overlay verifikasi ──
            if (_showVerifPopup) _buildVerifPopupOverlay(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // POPUP OVERLAY: Muncul langsung saat swipe sebelum loading selesai
  // ══════════════════════════════════════════════════════
  Widget _buildVerifPopupOverlay() {
    final Color primary =
        _isVoteValid ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData icon =
        _isVoteValid ? Icons.thumb_up_rounded : Icons.thumb_down_rounded;
    final String title =
        _isVoteValid ? t('verif_popup_valid') : t('verif_popup_invalid');
    final String sub = t('verif_popup_sub');
    final String findingImg = _temuanData?['gambar_temuan']?.toString() ?? '';
    final String completionImg =
        _temuanData?['penyelesaian']?['gambar_penyelesaian']?.toString() ?? '';

    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: primary.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header berwarna
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(26)),
                  ),
                  child: Column(children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: primary.withOpacity(0.4), width: 2.5),
                      ),
                      child: Icon(icon, color: primary, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),

                // Thumbnail temuan & penyelesaian
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPopupThumb(
                            findingImg, t('finding'), const Color(0xFFFF6B6B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPopupThumb(completionImg, t('completion'),
                            const Color(0xFF4ADE80)),
                      ),
                    ],
                  ),
                ),

                // Catatan
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPopupNote(
                          _temuanData?['deskripsi_temuan']?.toString() ?? '-',
                          t('finding_notes'),
                          const Color(0xFFFF6B6B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPopupNote(
                          _temuanData?['penyelesaian']
                                  ?['catatan_penyelesaian']
                                  ?.toString() ??
                              '-',
                          t('completion_notes'),
                          const Color(0xFF4ADE80),
                        ),
                      ),
                    ],
                  ),
                ),

                // Processing indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t('verif_popup_processing'),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupThumb(String? url, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A8A))),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 100,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: (url != null && url.isNotEmpty)
                ? Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade400))
                : Icon(Icons.image_not_supported_outlined,
                    color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupNote(String text, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color.withOpacity(0.8))),
          const SizedBox(height: 3),
          Text(
            text.isEmpty ? '-' : text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF1E3A8A),
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C9E4).withOpacity(0.1),
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
              t('screen_title'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Executive',
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
                        ? const Color(0xFF0EA5E9)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _tabIndex == 0
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9).withOpacity(0.3),
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
                              : const Color(0xFF0EA5E9)),
                      const SizedBox(width: 5),
                      Text(
                        t('tab_verify'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _tabIndex == 0
                              ? Colors.white
                              : const Color(0xFF0EA5E9),
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
                    _loadHistory();
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
                              color: const Color(0xFF0EA5E9).withOpacity(0.3),
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

  Widget _buildVerifyTab() {
    if (_isLoading) return _buildVerifyShimmer();
    if (_showSuccess) return _buildSuccessView();
    if (_noData) return _buildNoDataView();
    if (_temuanData != null) return _buildVerificationCard();
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

  Widget _buildVerificationCard() {
    final temuan = _temuanData!;
    final bool canSwipe = _countdown == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_rounded,
                    color: Colors.white70, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('card_title'),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text(t('card_subtitle'),
                          style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ImageBox(
                  label: t('finding'),
                  url: temuan['gambar_temuan'],
                  color: const Color(0xFFFF6B6B)),
              const SizedBox(width: 12),
              _ImageBox(
                  label: t('completion'),
                  url: temuan['penyelesaian']?['gambar_penyelesaian'],
                  color: const Color(0xFF4ADE80)),
            ],
          ),
          const SizedBox(height: 14),
          _NoteCard(
              label: t('finding_notes'),
              text: temuan['deskripsi_temuan'],
              color: const Color(0xFFFF6B6B)),
          const SizedBox(height: 8),
          _NoteCard(
              label: t('completion_notes'),
              text: temuan['penyelesaian']?['catatan_penyelesaian'],
              color: const Color(0xFF4ADE80)),
          const SizedBox(height: 8),
          _InfoRow(
              icon: Icons.category_outlined,
              text:
                  '${t("category")}: ${temuan['kategoritemuan']?['nama_kategoritemuan'] ?? '-'}'),
          _InfoRow(
              icon: Icons.location_on_outlined,
              text:
                  '${t("location")}: ${temuan['lokasi']?['nama_lokasi'] ?? '-'} ${temuan['area']?['nama_area'] != null ? '— ${temuan['area']['nama_area']}' : ''}'),
          const SizedBox(height: 20),
          _buildVerificationTimerBar(),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: canSwipe
                  ? const Color(0xFF00C9E4).withOpacity(0.1)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: canSwipe
                    ? const Color(0xFF00C9E4).withOpacity(0.3)
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canSwipe ? Icons.swipe_rounded : Icons.timer_outlined,
                  size: 16,
                  color: canSwipe
                      ? const Color(0xFF00C9E4)
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  canSwipe
                      ? t('swipe_now')
                      : '${t("wait_prefix")} $_countdown ${t("wait_suffix")}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: canSwipe
                        ? const Color(0xFF00C9E4)
                        : Colors.orange.shade700,
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
              onSwiped: () => _submitVerification(true),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _SwipeButton(
              label: t('swipe_incorrect'),
              color: const Color(0xFFDC2626),
              icon: Icons.arrow_back_rounded,
              direction: _SwipeDirection.rightToLeft,
              enabled: canSwipe,
              onSwiped: () => _submitVerification(false),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVerificationTimerBar() {
    final int minutes = _verificationSecondsLeft ~/ 60;
    final int seconds = _verificationSecondsLeft % 60;
    final double progress = _verificationSecondsLeft / 300.0;
    final bool isUrgent = _verificationSecondsLeft <= 60;
    final Color timerColor =
        isUrgent ? const Color(0xFFDC2626) : const Color(0xFF00C9E4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: timerColor.withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.timer_rounded, size: 16, color: timerColor),
              const SizedBox(width: 6),
              Text(
                _lang == 'ID'
                    ? 'Batas waktu verifikasi'
                    : _lang == 'ZH'
                        ? '验证截止时间'
                        : 'Verification time limit',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: timerColor,
                    fontWeight: FontWeight.w600),
              ),
            ]),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: timerColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: timerColor.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(timerColor),
          ),
        ),
      ]),
    );
  }

  Widget _buildNoDataView() {
    return FutureBuilder<bool>(
      future: _checkAllVerificatorsDone(),
      builder: (context, snapshot) {
        final bool allDone = snapshot.data ?? false;

        if (allDone) {
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
                      color: const Color(0xFF4ADE80).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.task_alt_rounded,
                        size: 54, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 24),
                  Text(t('no_data_title'),
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E3A8A))),
                  const SizedBox(height: 8),
                  Text(t('no_data_body'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          height: 1.5)),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(t('back')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
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
                    color: const Color(0xFF00C9E4).withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF00C9E4).withOpacity(0.3),
                        width: 2),
                  ),
                  child: const Icon(Icons.how_to_vote_rounded,
                      size: 50, color: Color(0xFF00C9E4)),
                ),
                const SizedBox(height: 24),
                Text(
                  _lang == 'EN'
                      ? "You're All Voted!"
                      : _lang == 'ZH'
                          ? '您已投票完毕！'
                          : 'Semua Sudah Kamu Verifikasi!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 8),
                Text(
                  _lang == 'EN'
                      ? 'You have verified all available reports.\nWaiting for other verificators to complete.'
                      : _lang == 'ZH'
                          ? '您已验证所有报告。\n等待其他验证者完成。'
                          : 'Kamu sudah memverifikasi semua laporan.\nMenunggu verificator lain menyelesaikan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.6),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _loadNextTemuan,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(_lang == 'EN'
                      ? 'Refresh'
                      : _lang == 'ZH'
                          ? '刷新'
                          : 'Perbarui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9E4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(t('back')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
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
      },
    );
  }

  Future<bool> _checkAllVerificatorsDone() async {
    try {
      final remaining = await _client
          .from('temuan')
          .select('id_temuan')
          .eq('status_temuan', 'Selesai')
          .eq('is_verif', false)
          .limit(1);
      return remaining.isEmpty;
    } catch (e) {
      return false;
    }
  }

  Widget _buildSuccessView() {
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
                gradient: const LinearGradient(
                    colors: [Color(0xFF00C9E4), Color(0xFF0891B2)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00C9E4).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 4)
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 54),
            ),
            const SizedBox(height: 24),
            Text(t('success_title'),
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 8),
            Text(t('success_body'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loadNextTemuan,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(t('continue_btn')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9E4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CountdownAutoNext(
              textPrefix: t('auto_next'),
              textSuffix: t('auto_suf'),
              onFinished: _loadNextTemuan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyLoading) return _buildHistoryShimmer();
    if (_historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(t('hist_empty'),
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyList.length,
      itemBuilder: (_, i) => _buildHistoryCard(_historyList[i]),
    );
  }

  Widget _buildHistoryShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 90,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final int? tid = data['id_temuan'] as int?;
    final String title = data['judul_temuan']?.toString() ?? '-';
    final String? imageUrl = data['gambar_temuan']?.toString();
    final String? completionImageUrl =
        data['penyelesaian']?['gambar_penyelesaian']?.toString();
    final bool userVote = data['user_vote'] as bool? ?? false;
    final bool? finalOutcome = data['hasil_verifikasi_mayoritas'] as bool?;
    final bool isFinalized = data['is_verif'] as bool? ?? false;

    final stats =
        tid != null ? (_voteStats[tid] ?? {}) : <String, dynamic>{};
    final int validCount = (stats['valid_count'] as int?) ?? 0;
    final int invalidCount = (stats['invalid_count'] as int?) ?? 0;
    final int totalVotes = (stats['total'] as int?) ?? 0;
    final int totalVerificators =
        (stats['total_verificators'] as int?) ?? 0;

    final int netPoint =
        tid != null ? (_historyPointMap[tid] ?? 0) : 0;

    // ── STATUS: Mayoritas / Minoritas / Menunggu ──
    Color accent;
    String statusLabel;
    IconData statusIcon;

    if (!isFinalized || finalOutcome == null) {
      // Belum semua voter vote → pending
      accent = Colors.orange.shade400;
      statusLabel = t('pending');
      statusIcon = Icons.hourglass_empty_rounded;
    } else {
      // Sudah finalized (is_verif=true) → tampil mayoritas/minoritas
      final bool inMajority = userVote == finalOutcome;
      accent = inMajority
          ? const Color(0xFF16A34A)
          : const Color(0xFFDC2626);
      statusLabel = inMajority ? t('majority') : t('minority');
      statusIcon = inMajority
          ? Icons.emoji_events_rounded
          : Icons.highlight_off_rounded;
    }

    final String voteLabel = userVote ? t('valid') : t('invalid');
    final Color voteColor =
        userVote ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    String loc = '-';
    if (data['area']?['nama_area'] != null) {
      loc = data['area']['nama_area'].toString();
    } else if (data['unit']?['nama_unit'] != null) {
      loc = data['unit']['nama_unit'].toString();
    } else if (data['lokasi']?['nama_lokasi'] != null) {
      loc = data['lokasi']['nama_lokasi'].toString();
    }

    String date = '-';
    try {
      final rawDate = data['waktu_verifikasi'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        date = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final double validRatio =
        totalVotes > 0 ? validCount / totalVotes : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 88,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      bottomLeft: Radius.circular(4)),
                ),
              ),
              const SizedBox(width: 10),
              _HistoryThumb(url: imageUrl, label: t('finding')),
              const SizedBox(width: 6),
              _HistoryThumb(url: completionImageUrl, label: t('completion')),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                              height: 1.25)),
                      const SizedBox(height: 5),
                      Row(children: [
                        _VotePill(
                            label: voteLabel,
                            color: voteColor,
                            icon: userVote
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_down_rounded),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Row(children: [
                            Icon(Icons.place_outlined,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(loc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade500)),
                            ),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(date,
                            style: GoogleFonts.poppins(
                                fontSize: 9.5, color: Colors.grey.shade400)),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: accent.withOpacity(0.3), width: 1.5),
                      ),
                      child: Icon(statusIcon, color: accent, size: 22),
                    ),
                    const SizedBox(height: 3),
                    Text(statusLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: accent)),
                  ],
                ),
              ),
            ],
          ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 1,
              color: accent.withOpacity(0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.how_to_vote_rounded,
                          size: 13,
                          color: const Color(0xFF1E3A8A).withOpacity(0.7)),
                      const SizedBox(width: 5),
                      Text(t('vote_breakdown'),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A))),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFinalized
                            ? const Color(0xFF16A34A).withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFinalized
                              ? const Color(0xFF16A34A).withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                            isFinalized
                                ? Icons.verified_rounded
                                : Icons.pending_rounded,
                            size: 10,
                            color: isFinalized
                                ? const Color(0xFF16A34A)
                                : Colors.orange),
                        const SizedBox(width: 3),
                        Text(
                            isFinalized
                                ? t('finalized')
                                : t('not_finalized'),
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isFinalized
                                    ? const Color(0xFF16A34A)
                                    : Colors.orange)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _VoteCountChip(
                          icon: Icons.thumb_up_rounded,
                          label: t('votes_valid'),
                          count: validCount,
                          color: const Color(0xFF16A34A)),
                      Text(
                          '$totalVotes / $totalVerificators ${_lang == 'EN' ? 'voters' : _lang == 'ZH' ? '投票者' : 'pemilih'}',
                          style: GoogleFonts.poppins(
                              fontSize: 9.5, color: Colors.grey.shade500)),
                      _VoteCountChip(
                          icon: Icons.thumb_down_rounded,
                          label: t('votes_invalid'),
                          count: invalidCount,
                          color: const Color(0xFFDC2626),
                          iconOnRight: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(children: [
                      Container(
                          height: 8,
                          width: double.infinity,
                          color: const Color(0xFFDC2626).withOpacity(0.18)),
                      FractionallySizedBox(
                        widthFactor: validRatio.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF16A34A), Color(0xFF4ADE80)]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: finalOutcome == null
                            ? Colors.orange.withOpacity(0.07)
                            : finalOutcome
                                ? const Color(0xFF16A34A).withOpacity(0.07)
                                : const Color(0xFFDC2626).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: finalOutcome == null
                              ? Colors.orange.withOpacity(0.2)
                              : finalOutcome
                                  ? const Color(0xFF16A34A).withOpacity(0.2)
                                  : const Color(0xFFDC2626).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('majority_result'),
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(
                                finalOutcome == null
                                    ? Icons.hourglass_empty_rounded
                                    : finalOutcome
                                        ? Icons.thumb_up_rounded
                                        : Icons.thumb_down_rounded,
                                size: 13,
                                color: finalOutcome == null
                                    ? Colors.orange
                                    : finalOutcome
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text(
                                finalOutcome == null
                                    ? t('pending')
                                    : finalOutcome
                                        ? t('valid')
                                        : t('invalid'),
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: finalOutcome == null
                                        ? Colors.orange
                                        : finalOutcome
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFDC2626))),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final int displayPoint = isFinalized ? netPoint : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: displayPoint >= 0
                                ? const Color(0xFF1E3A8A).withOpacity(0.05)
                                : const Color(0xFFDC2626).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: displayPoint >= 0
                                  ? const Color(0xFF1E3A8A).withOpacity(0.15)
                                  : const Color(0xFFDC2626).withOpacity(0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t('your_points'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(
                                    displayPoint >= 0
                                        ? Icons.star_rounded
                                        : Icons.star_half_rounded,
                                    size: 13,
                                    color: displayPoint >= 0
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFDC2626)),
                                const SizedBox(width: 4),
                                Text(
                                    !isFinalized
                                        ? '-'
                                        : displayPoint > 0
                                            ? '+$displayPoint'
                                            : '$displayPoint',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: displayPoint >= 0
                                            ? const Color(0xFF1E3A8A)
                                            : const Color(0xFFDC2626))),
                                const SizedBox(width: 3),
                                Text(_lang == 'ZH' ? '积分' : 'Poin',
                                    style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        color: Colors.grey.shade500)),
                              ]),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// SUB-WIDGETS (tidak berubah dari asli, disertakan ulang)
// ──────────────────────────────────────────────────────────────

class _ImageBox extends StatelessWidget {
  final String label;
  final String? url;
  final Color color;
  const _ImageBox({required this.label, required this.url, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 6,
                height: 14,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A))),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: color.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(14)),
              child: (url != null && url!.isNotEmpty)
                  ? Image.network(url!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00C9E4)));
                      },
                      errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.grey.shade400, size: 36)))
                  : Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400, size: 36)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String label;
  final String? text;
  final Color color;
  const _NoteCard({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.8))),
        const SizedBox(height: 4),
        Text((text != null && text!.isNotEmpty) ? text! : '-',
            style: GoogleFonts.poppins(
                fontSize: 13, color: const Color(0xFF1E3A8A), height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

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
                ? widget.color.withOpacity(0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.enabled
                  ? widget.color.withOpacity(0.4)
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
                                color: widget.color.withOpacity(0.4),
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
            fontSize: 12, color: Colors.grey.shade400));
  }
}

class _HistoryThumb extends StatelessWidget {
  final String? url;
  final String label;
  const _HistoryThumb({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500)),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 52,
            height: 52,
            color: Colors.grey.shade100,
            child: (url != null && url!.isNotEmpty)
                ? Image.network(url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        size: 20,
                        color: Colors.grey.shade400))
                : Icon(Icons.image_not_supported_outlined,
                    size: 20, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }
}

class _VotePill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _VotePill({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _VoteCountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool iconOnRight;

  const _VoteCountChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.iconOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 11, color: color);
    final textWidget = Text('$count $label',
        style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700, color: color));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconOnRight
          ? [textWidget, const SizedBox(width: 3), iconWidget]
          : [iconWidget, const SizedBox(width: 3), textWidget],
    );
  }
}