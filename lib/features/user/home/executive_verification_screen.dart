import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/notification_service.dart';

// Tambahkan di luar class, di bawah semua import
void unawaited(Future<void> future) {
  future.catchError((e) => debugPrint('Unawaited error: $e'));
}

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
  Map<String, Map<String, dynamic>> _voteStats = {};
  Map<String, int> _historyPointMap = {};

  int _countdown = 5;
  Timer? _countdownTimer;
  int _verificationSecondsLeft = 300;
  Timer? _verificationTimer;
  bool _verificationExpired = false;
  bool _allVotedByUser = false;

  int _tabIndex = 0;

  // ── Mode HRD untuk accident report ──
  bool _isHrdMode = false; // true jika user adalah HRD (id_jabatan=5)

  // ── State untuk accident report verification ──
  bool _isAccidentLoading = true;
  bool _noAccidentData = false;
  bool _showAccidentSuccess = false;
  Map<String, dynamic>? _accidentData;
  List<Map<String, dynamic>> _accidentHistoryList = [];
  bool _accidentHistoryLoading = false;
  Map<String, Map<String, dynamic>> _accidentVoteStats = {};
  int _accidentCountdown = 5;
  Timer? _accidentCountdownTimer;
  bool _showAccidentVerifPopup = false;
  bool _isAccidentVoteValid = false;
  bool _showResolutionForm = false; // form penyelesaian setelah vote

  // ── Konfigurasi verifikasi dari DB ──
  int _verifikasiDurasiHari = 7;
  int _minSuaraFinalisasi = 3;
  bool _autoValidJikaTimeout = true;
  
  bool _isDecoyMode = false;
  Map<String, dynamic>? _decoyData;

  // Internal: set berisi index sesi verifikasi mana yang akan jadi decoy
  // dalam batch 10 verifikasi berikutnya. Diisi ulang setiap batch habis.
  final Set<int> _decoyPositions = {};
  int _sessionVerifCount = 0; // counter total verifikasi sejak layar dibuka
  int _currentBatchStart = 0; // awal batch saat ini (kelipatan 10)

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
    _isHrdMode = widget.userJabatanId == 5 || widget.userJabatanId == 2;
    _loadVerifikasiConfig().then((_) {
      if (_isHrdMode) {
        _loadNextAccidentReport();
      } else {
        _loadNextTemuan();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVerifikasiConfig() async {
    try {
      final rows = await _client
          .from('verifikasi_config')
          .select('kode, nilai_int');
      for (final row in rows) {
        switch (row['kode']) {
          case 'durasi_verifikasi_hari':
            _verifikasiDurasiHari = row['nilai_int'] ?? 7;
            break;
          case 'min_suara_finalisasi':
            _minSuaraFinalisasi = row['nilai_int'] ?? 3;
            break;
          case 'auto_valid_jika_timeout':
            _autoValidJikaTimeout = (row['nilai_int'] ?? 1) == 1;
            break;
          // Hapus case 'jeda_decoy_min' dan 'jeda_decoy_max'
          // Admin tidak lagi mengatur posisi decoy
        }
      }
    } catch (e) {
      debugPrint('loadVerifikasiConfig error: $e');
    }
    // Generate posisi decoy batch pertama setelah config selesai dimuat
    _generateDecoyBatch(batchStart: 0);
  }

  /// Generate posisi decoy untuk batch 10 verifikasi berikutnya.
  ///
  /// Aturan:
  /// - Per 5 verifikasi dalam batch → tepat 1 posisi decoy acak
  /// - Batch 10 → 2 decoy (posisi 0-4 dapat 1, posisi 5-9 dapat 1)
  /// - Posisi dipilih murni random, tidak ada pola
  /// - Admin tidak bisa mengatur, user tidak bisa menebak
  void _generateDecoyBatch({required int batchStart}) {
    _decoyPositions.clear();
    _currentBatchStart = batchStart;

    final rng = DateTime.now().microsecondsSinceEpoch;

    // Batch dibagi 2 slot: slot A = indeks 0-4, slot B = indeks 5-9
    // Masing-masing slot mendapat tepat 1 posisi decoy acak
    // Sehingga: 5 verif → 1 decoy, 10 verif → 2 decoy

    // Slot A: pilih 1 posisi acak dari 0,1,2,3,4
    final int posA = batchStart + (rng % 5);

    // Slot B: pilih 1 posisi acak dari 5,6,7,8,9
    // Gunakan seed berbeda agar posA dan posB tidak berkorelasi
    final int seedB = rng ^ (rng >> 17) ^ (rng * 0x45d9f3b);
    final int posB = batchStart + 5 + (seedB.abs() % 5);

    _decoyPositions.add(posA);
    _decoyPositions.add(posB);

    debugPrint('[Decoy] Batch $batchStart–${batchStart + 9}: posisi decoy = $_decoyPositions');
  }

  Future<void> _loadNextTemuan() async {
    setState(() {
      _isLoading = true;
      _noData = false;
      _showSuccess = false;
      _temuanData = null;
      _showVerifPopup = false;
      _isDecoyMode = false;
      _decoyData = null;
    });

    try {
      final userId = _client.auth.currentUser!.id;

      final verifiedLogs = await _client
          .from('verifikasi_log')
          .select('id_temuan')
          .eq('id_verificator', userId);
      final List<dynamic> verifiedIds =
          verifiedLogs.map<dynamic>((l) => l['id_temuan']).toList();

      final cutoffDate = DateTime.now()
          .subtract(Duration(days: _verifikasiDurasiHari))
          .toIso8601String();

      // Cek apakah batch saat ini sudah habis (setiap 10 verifikasi)
      // Jika iya, generate batch baru sebelum menentukan apakah ini decoy
      if (_sessionVerifCount > 0 &&
          _sessionVerifCount % 10 == 0 &&
          _sessionVerifCount != _currentBatchStart) {
        _generateDecoyBatch(batchStart: _sessionVerifCount);
      }

      // Cek apakah posisi sesi ini adalah decoy
      final bool shouldShowDecoy =
          _decoyPositions.contains(_sessionVerifCount);

      // Naikkan counter SETELAH pengecekan
      _sessionVerifCount++;

      if (shouldShowDecoy) {
        await _loadDecoyTemuan(userId, verifiedIds, cutoffDate);
        return;
      }

      // ── Verifikasi Normal (tidak ada perubahan dari kode asli) ──
      var query = _client.from('temuan').select('''
        id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, status_temuan,
        id_kategoritemuan_uuid,
        penyelesaian:id_penyelesaian (gambar_penyelesaian, catatan_penyelesaian),
        kategoritemuan:id_kategoritemuan_uuid (nama_kategoritemuan),
        lokasi:id_lokasi(nama_lokasi),
        area:id_area(nama_area),
        unit:id_unit(nama_unit)
      ''')
          .eq('status_temuan', 'Selesai')
          .eq('is_verif', false)
          .gte('created_at', cutoffDate);

      if (verifiedIds.isNotEmpty) {
        query = query.not('id_temuan', 'in', verifiedIds);
      }

      final result = await query
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (result == null) {
        await _checkAndAutoFinalizeTimeout();
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

      // Skip accident jika bukan HRD
      final String katName =
          (result['kategoritemuan']?['nama_kategoritemuan']?.toString() ?? '')
              .toLowerCase();
      final bool isAccident =
          katName.contains('kecelakaan') || katName.contains('accident');

      if (isAccident && !_isHrdMode) {
        final verifiedIdsUpdated = List<dynamic>.from(verifiedIds)
          ..add(result['id_temuan']);
        var queryNext = _client.from('temuan').select('''
          id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, status_temuan,
          id_kategoritemuan_uuid,
          penyelesaian:id_penyelesaian (gambar_penyelesaian, catatan_penyelesaian),
          kategoritemuan:id_kategoritemuan_uuid (nama_kategoritemuan),
          lokasi:id_lokasi(nama_lokasi),
          area:id_area(nama_area),
          unit:id_unit(nama_unit)
        ''')
            .eq('status_temuan', 'Selesai')
            .eq('is_verif', false)
            .gte('created_at', cutoffDate)
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

  /// Load decoy: ambil 2 temuan berbeda, swap gambar finding/completion secara acak
  Future<void> _loadDecoyTemuan(
    String userId,
    List<dynamic> verifiedIds,
    String cutoffDate,
  ) async {
    try {
      // Query temuan yang belum diverifikasi user ini
      // (sama dengan query normal, tapi ambil 2 untuk di-swap)
      var query = _client.from('temuan').select('''
        id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, status_temuan,
        id_kategoritemuan_uuid,
        penyelesaian:id_penyelesaian (gambar_penyelesaian, catatan_penyelesaian),
        kategoritemuan:id_kategoritemuan_uuid (nama_kategoritemuan),
        lokasi:id_lokasi(nama_lokasi),
        area:id_area(nama_area),
        unit:id_unit(nama_unit)
      ''')
          .eq('status_temuan', 'Selesai')
          .eq('is_verif', false)
          .gte('created_at', cutoffDate);

      // Exclude yang sudah diverifikasi oleh user ini
      if (verifiedIds.isNotEmpty) {
        query = query.not('id_temuan', 'in', verifiedIds);
      }

      // Ambil 2 temuan berbeda untuk bahan swap
      final results = await query
          .order('created_at', ascending: true)
          .limit(2);

      if (!mounted) return;

      // Jika data kurang dari 2, tidak bisa buat decoy → tampilkan normal
      if (results.length < 2) {
        debugPrint('[Decoy] Data tidak cukup untuk decoy, tampilkan normal.');
        setState(() => _isDecoyMode = false);
        final result = results.isNotEmpty ? results.first : null;
        if (result == null) {
          setState(() { _noData = true; _isLoading = false; });
          return;
        }
        setState(() {
          _temuanData = result;
          _isLoading = false;
        });
        _startCountdown();
        return;
      }

      // Pilih jenis swap secara acak:
      // 0 = swap gambar finding saja (swap_finding)
      // 1 = swap gambar completion saja (swap_completion)
      // 2 = swap keduanya (both) — paling sulit
      final int swapType =
          DateTime.now().microsecondsSinceEpoch % 3;

      final Map<String, dynamic> primary = Map.from(results[0]);
      final Map<String, dynamic> secondary = Map.from(results[1]);
      Map<String, dynamic> decoyTemuan = Map.from(primary);

      switch (swapType) {
        case 0: // swap_finding: gambar temuan diambil dari secondary
          decoyTemuan['gambar_temuan'] = secondary['gambar_temuan'];
          break;
        case 1: // swap_completion: gambar penyelesaian diambil dari secondary
          final completionCopy = Map<String, dynamic>.from(
              primary['penyelesaian'] as Map? ?? {});
          completionCopy['gambar_penyelesaian'] =
              (secondary['penyelesaian'] as Map?)?['gambar_penyelesaian'];
          decoyTemuan['penyelesaian'] = completionCopy;
          break;
        case 2: // both: swap gambar finding DAN completion
        default:
          decoyTemuan['gambar_temuan'] = secondary['gambar_temuan'];
          final completionCopyBoth = Map<String, dynamic>.from(
              primary['penyelesaian'] as Map? ?? {});
          completionCopyBoth['gambar_penyelesaian'] =
              (secondary['penyelesaian'] as Map?)?['gambar_penyelesaian'];
          decoyTemuan['penyelesaian'] = completionCopyBoth;
          break;
      }

      debugPrint('[Decoy] Jenis swap: $swapType (0=finding, 1=completion, 2=both)');

      // Jawaban BENAR untuk soal decoy adalah TIDAK VALID
      // karena gambar temuan dan penyelesaian sengaja tidak cocok
      setState(() {
        _isDecoyMode = true;
        _decoyData = Map.from(primary); // simpan data asli untuk referensi
        _temuanData = decoyTemuan;       // tampilkan yang sudah di-swap
        _isLoading = false;
        _allVotedByUser = false;
      });
      _startCountdown();
    } catch (e) {
      debugPrint('loadDecoyTemuan error: $e');
      // Jika gagal, kembali ke mode normal
      if (mounted) setState(() { _isDecoyMode = false; _isLoading = false; });
    }
  }

  /// Auto-finalisasi temuan yang sudah melewati batas waktu
  Future<void> _checkAndAutoFinalizeTimeout() async {
    try {
      await _client.rpc('auto_finalize_timeout_temuan');
    } catch (e) {
      debugPrint('autoFinalizeTimeout error: $e');
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
    // Durasi dari config (dalam hari), untuk UI tampilkan 5 menit sebagai batas baca
    setState(() {
      _verificationSecondsLeft = 120;
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

    if (_isDecoyMode) {
      // Decoy: jawaban BENAR adalah TIDAK VALID (karena gambar sengaja tidak match)
      // Tidak ada perubahan data DB, hanya feedback ke user
      final bool answeredCorrectly = !isValid;
      _handleDecoyResult(answeredCorrectly, isValid);
      return;
    }

    // ── Verifikasi normal: sama persis dengan kode asli ──
    setState(() {
      _showVerifPopup = true;
      _isVoteValid = isValid;
    });

    final String temuanId = _temuanData!['id_temuan'].toString();
    unawaited(_processVerificationBackground(temuanId, isValid));

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showVerifPopup = false;
        _showSuccess = true;
      });
    }
  }

  void _handleDecoyResult(bool answeredCorrectly, bool userVote) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 4), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: answeredCorrectly
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (answeredCorrectly
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B))
                        .withValues(alpha:0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: (answeredCorrectly
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFF59E0B))
                            .withValues(alpha:0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        answeredCorrectly
                            ? Icons.military_tech_rounded
                            : Icons.psychology_alt_rounded,
                        size: 38,
                        color: answeredCorrectly
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      answeredCorrectly
                          ? (_lang == 'ID'
                              ? '🎯 Ketelitian Terbukti!'
                              : '🎯 Sharp Eye!')
                          : (_lang == 'ID'
                              ? '🔍 Periksa Lebih Teliti'
                              : '🔍 Look More Carefully'),
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: answeredCorrectly
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      answeredCorrectly
                          ? (_lang == 'ID'
                              ? 'Anda berhasil mendeteksi ketidaksesuaian gambar temuan dan penyelesaian. Bagus!'
                              : 'You detected the mismatch between finding and completion images. Well done!')
                          : (_lang == 'ID'
                              ? 'Gambar temuan dan penyelesaian tidak sesuai satu sama lain. Periksa lebih seksama.'
                              : 'The finding and completion images did not match. Examine more carefully.'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _lang == 'ID'
                            ? 'Ini adalah uji ketelitian otomatis — tidak mempengaruhi data verifikasi.'
                            : 'This was an automatic focus test — it does not affect verification data.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Lanjut ke temuan berikutnya setelah dialog ditutup
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isDecoyMode = false;
          _decoyData = null;
          _showSuccess = false;
        });
        _loadNextTemuan();
      }
    });
  }

  Future<void> _processVerificationBackground(String temuanId, bool isValid) async {
    try {
      final userId = _client.auth.currentUser!.id;

      // Jalankan RPC vote dan ambil config poin SECARA PARALLEL
      // Pisahkan tipe agar Future.wait tidak konflik
      final rpcFuture = _client.rpc('handle_verification_vote', params: {
        'p_temuan_id': temuanId,
        'p_verificator_id': userId,
        'p_vote_is_correct': isValid,
        'p_point_change': 0,
      });

      final configFuture = _client
          .from('konfigurasi_poin')
          .select('kode, poin, deskripsi_template')
          .eq('kode', 'verifikasi_partisipasi')
          .eq('is_aktif', true)
          .limit(1);

      // Tunggu keduanya selesai secara parallel
      final results = await Future.wait<dynamic>([rpcFuture, configFuture]);

      // Parse hasil config poin
      int pointParticipation = 10;
      String descParticipation = '';

      final configs = (results[1] as List<dynamic>);
      if (configs.isNotEmpty) {
        pointParticipation = (configs.first['poin'] as num).toInt().abs();
        descParticipation = configs.first['deskripsi_template']?.toString() ?? '';
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

      if (!mounted) return;

      // Trigger animasi poin
      widget.onPointEarned?.call(pointParticipation);

      // Notifikasi
      NotificationService.instance.showNotification(
        title: _lang == 'EN'
            ? '✅ Verification Recorded'
            : _lang == 'ZH'
                ? '✅ 验证已记录'
                : '✅ Verifikasi Dicatat',
        body: descParticipation,
      );

      // Tampilkan dialog poin (muncul setelah success view sudah tampil)
      if (mounted) {
        _showVerifPointDialog(
          pointParticipation,
          descParticipation,
          'verifikasi_partisipasi',
        );
      }
    } catch (e) {
      debugPrint('Background verif process error: $e');
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
      barrierColor: Colors.black.withValues(alpha:0.55),
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
                      color: primary.withValues(alpha:0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: primary.withValues(alpha:0.2),
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
                        color: primary.withValues(alpha:0.06),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32)),
                      ),
                      child: Column(children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha:0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: primary.withValues(alpha:0.3), width: 2),
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
                            color: primary.withValues(alpha:0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: primary.withValues(alpha:0.12), width: 1),
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
                              backgroundColor: primary.withValues(alpha:0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  primary.withValues(alpha:0.45)),
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
              kategoritemuan:id_kategoritemuan_uuid (nama_kategoritemuan),
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
      final List<String> temuanIds = [];

      for (final item in response) {
        final rawTemuan = item['temuan'];
        if (rawTemuan == null) continue;
        final data = Map<String, dynamic>.from(rawTemuan as Map);
        data['user_vote'] = item['jawaban_benar'] as bool? ?? false;
        data['waktu_verifikasi'] = item['waktu_verifikasi'];
        data['id_log'] = item['id_log'];
        processed.add(data);
        final tid = data['id_temuan']?.toString();
        if (tid != null && tid.isNotEmpty) temuanIds.add(tid);
      }

      final Map<String, Map<String, dynamic>> voteStats = {};
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
              allVotes.where((v) => v['id_temuan']?.toString() == tid).toList();
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
      final Map<String, int> pointMap = {};
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
          final tid = processed[i]['id_temuan']?.toString();
          if (tid == null || tid.isEmpty) continue;

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
                  child: _tabIndex == 0 ? _buildVerifyTab() : _buildHistoryTab(),
                ),
              ],
            ),
            // Popup overlay — sesuaikan dengan mode
            if (_isHrdMode && _showAccidentVerifPopup) _buildAccidentVerifPopupOverlay(),
            if (!_isHrdMode && _showVerifPopup) _buildVerifPopupOverlay(),
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
      color: Colors.black.withValues(alpha:0.65),
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
              border: Border.all(color: primary.withValues(alpha:0.3), width: 2),
              boxShadow: [
                BoxShadow(
                    color: primary.withValues(alpha:0.25),
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
                    color: primary.withValues(alpha:0.08),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(26)),
                  ),
                  child: Column(children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha:0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: primary.withValues(alpha:0.4), width: 2.5),
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
        color: color.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha:0.8))),
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

  // ================================================================
  // ACCIDENT REPORT VERIFICATION — LOAD DATA
  // ================================================================
  Future<void> _loadNextAccidentReport() async {
    setState(() {
      _isAccidentLoading = true;
      _noAccidentData = false;
      _showAccidentSuccess = false;
      _showResolutionForm = false;
      _accidentData = null;
      _showAccidentVerifPopup = false;
    });

    try {
      final userId = _client.auth.currentUser!.id;

      // Ambil laporan yang sudah divote oleh user ini
      final votedLogs = await _client
          .from('accident_verifikasi_log')
          .select('id_laporan')
          .eq('id_verificator', userId);
      final List votedIds = votedLogs.map((l) => l['id_laporan']).toList();

      // Query laporan yang:
      // 1. Belum difinalisasi (is_verif = false) — sudah difinalisasi tidak perlu verifikasi lagi
      // 2. Belum divote oleh user ini
      var query = _client.from('accident_report').select('''
        id_laporan, judul, deskripsi, foto_bukti,
        tanggal_kejadian, waktu_kejadian, penyebab,
        tingkat_keparahan, departemen_terdampak, tindakan_diambil,
        status, created_at, is_verif,
        lokasi:id_lokasi(nama_lokasi),
        pelapor:id_pelapor(nama),
        pihak_terdampak:id_pihak_terdampak(nama),
        supervisor_user:id_supervisor(nama),
        saksi_user:id_saksi(nama)
      ''').eq('is_verif', false); // hanya yang BELUM difinalisasi

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
      // Insert/update vote log
      await _client.from('accident_verifikasi_log').upsert({
        'id_laporan': lapdoranId,
        'id_verificator': userId,
        'jawaban_benar': isValid,
        'waktu_verifikasi': DateTime.now().toIso8601String(),
      }, onConflict: 'id_laporan,id_verificator');

      // Langsung finalisasi — vote pertama yang masuk menentukan hasil
      // isValid sesuai pilihan HRD/Manager yang bersangkutan
      await _client.from('accident_report').update({
        'is_verif': true,
        'hasil_verifikasi_mayoritas': isValid,
        'status': 'Selesai',
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
  
  Future<void> _loadAccidentHistory() async {
    setState(() => _accidentHistoryLoading = true);
    try {
      // Ambil SEMUA accident report — baik yang sudah maupun belum difinalisasi
      // Tampilkan semua agar history lengkap; filter is_verif tidak dibatasi
      final allReports = await _client
          .from('accident_report')
          .select('''
            id_laporan, judul, deskripsi, foto_bukti,
            tanggal_kejadian, waktu_kejadian, penyebab,
            tingkat_keparahan, departemen_terdampak, tindakan_diambil,
            status, created_at, updated_at, is_verif,
            hasil_verifikasi_mayoritas,
            lokasi:id_lokasi(nama_lokasi),
            pelapor:id_pelapor(nama),
            pihak_terdampak:id_pihak_terdampak(nama)
          ''')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> processed = [];
      final List<String> lapdoranIds = [];

      for (final item in allReports) {
        final data = Map<String, dynamic>.from(item as Map);
        processed.add(data);
        final lid = data['id_laporan']?.toString();
        if (lid != null) lapdoranIds.add(lid);
      }

      final Map<String, Map<String, dynamic>> voteStats = {};

      if (lapdoranIds.isNotEmpty) {
        // Ambil semua log verifikasi beserta data verificator
        final allVoteLogs = await _client
            .from('accident_verifikasi_log')
            .select('''
              id_laporan,
              jawaban_benar,
              id_verificator,
              waktu_verifikasi,
              verificator:id_verificator (
                nama,
                id_jabatan,
                gambar_user,
                jabatan:id_jabatan (nama_jabatan)
              )
            ''')
            .inFilter('id_laporan', lapdoranIds);

        for (final lid in lapdoranIds) {
          final votesForLaporan = allVoteLogs
              .where((v) => v['id_laporan']?.toString() == lid)
              .toList();

          final int validCount =
              votesForLaporan.where((v) => v['jawaban_benar'] == true).length;
          final int invalidCount =
              votesForLaporan.where((v) => v['jawaban_benar'] == false).length;

          // Detail verificator yang sudah vote
          final Map<String, Map<String, String>> verifDetailMap = {};
          for (final v in votesForLaporan) {
            final vid = v['id_verificator']?.toString();
            if (vid == null) continue;
            final rawVerif = v['verificator'];
            if (rawVerif == null) continue;
            final nama = rawVerif['nama']?.toString() ?? vid;
            final jabatanId = rawVerif['id_jabatan'];
            final jabatanName =
                rawVerif['jabatan']?['nama_jabatan']?.toString() ?? '';
            final fotoUrl = rawVerif['gambar_user']?.toString() ?? '';
            verifDetailMap[vid] = {
              'nama': nama,
              'jabatan': jabatanName,
              'jabatan_id': jabatanId?.toString() ?? '',
              'foto_url': fotoUrl,
            };
          }

          voteStats[lid] = {
            'valid_count': validCount,
            'invalid_count': invalidCount,
            'total': validCount + invalidCount,
            'total_hrd': validCount + invalidCount,
            'verif_detail_map': verifDetailMap,
          };
        }
      }

      if (mounted) {
        setState(() {
          _accidentHistoryList = processed;
          _accidentVoteStats = voteStats;
          _accidentHistoryLoading = false;
        });
      }
    } catch (e) {
      debugPrint('loadAccidentHistory error: $e');
      if (mounted) setState(() => _accidentHistoryLoading = false);
    }
  }

  // ================================================================
  // ACCIDENT REPORT — UI WIDGETS
  // ================================================================
  Widget _buildAccidentVerificationCard() {
    final laporan = _accidentData!;
    final bool canSwipe = _accidentCountdown == 0;
    final String severity = laporan['tingkat_keparahan'] ?? '';
    final Color sevColor = severity == 'Berat'
        ? const Color(0xFFDC2626)
        : severity == 'Menengah'
            ? const Color(0xFFF97316)
            : const Color(0xFF16A34A);

    // Warna tema header berdasarkan jabatan
    final List<Color> headerColors = widget.userJabatanId == 2
        ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
        : [const Color(0xFFDC2626), const Color(0xFFB91C1C)];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Card ──
          Container(
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
                  color: headerColors.last.withValues(alpha:0.3),
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
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.health_and_safety_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lang == 'ID'
                            ? 'Tinjauan Laporan Kecelakaan'
                            : _lang == 'ZH'
                                ? '事故报告审查'
                                : 'Accident Report Review',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lang == 'ID'
                            ? 'Periksa dan edit laporan jika diperlukan'
                            : _lang == 'ZH'
                                ? '检查并编辑报告（如需要）'
                                : 'Review and edit the report if needed',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Edit
                GestureDetector(
                  onTap: () => _showEditAccidentDialog(laporan),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Foto Bukti ──
          if (laporan['foto_bukti'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    laporan['foto_bukti'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400, size: 48),
                    ),
                  ),
                  // Badge severity di atas foto
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sevColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: sevColor.withValues(alpha:0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(severity,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Info Utama ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul laporan
                Text(
                  laporan['judul'] ?? '-',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A)),
                ),
                if (laporan['foto_bukti'] == null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sevColor.withValues(alpha:0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 12, color: sevColor),
                        const SizedBox(width: 4),
                        Text(severity,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sevColor)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                // Grid 2 kolom untuk info
                _buildInfoGrid([
                  {
                    'icon': Icons.person_outline,
                    'label': _lang == 'ID' ? 'Pelapor' : 'Reporter',
                    'value': laporan['pelapor']?['nama'] ?? '-',
                  },
                  {
                    'icon': Icons.personal_injury_outlined,
                    'label': _lang == 'ID' ? 'Pihak Terdampak' : 'Affected',
                    'value': laporan['pihak_terdampak']?['nama'] ?? '-',
                  },
                  {
                    'icon': Icons.location_on_outlined,
                    'label': _lang == 'ID' ? 'Lokasi' : 'Location',
                    'value': laporan['lokasi']?['nama_lokasi'] ?? '-',
                  },
                  {
                    'icon': Icons.calendar_today,
                    'label': _lang == 'ID' ? 'Tanggal' : 'Date',
                    'value': laporan['tanggal_kejadian']?.toString() ?? '-',
                  },
                  {
                    'icon': Icons.access_time,
                    'label': _lang == 'ID' ? 'Waktu' : 'Time',
                    'value': laporan['waktu_kejadian']
                            ?.toString()
                            .substring(0, 5) ??
                        '-',
                  },
                  {
                    'icon': Icons.build_circle_outlined,
                    'label': _lang == 'ID' ? 'Penyebab' : 'Cause',
                    'value': laporan['penyebab'] ?? '-',
                  },
                  if (laporan['supervisor_user']?['nama'] != null)
                    {
                      'icon': Icons.supervisor_account_outlined,
                      'label': 'Supervisor',
                      'value': laporan['supervisor_user']['nama'],
                    },
                  if (laporan['saksi_user']?['nama'] != null)
                    {
                      'icon': Icons.visibility_outlined,
                      'label': _lang == 'ID' ? 'Saksi' : 'Witness',
                      'value': laporan['saksi_user']['nama'],
                    },
                  if (laporan['departemen_terdampak'] != null)
                    {
                      'icon': Icons.business_outlined,
                      'label': _lang == 'ID' ? 'Departemen' : 'Department',
                      'value': laporan['departemen_terdampak'],
                    },
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Deskripsi Kejadian ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.description_outlined,
                      size: 14, color: Colors.orange.shade800),
                  const SizedBox(width: 6),
                  Text(
                    _lang == 'ID'
                        ? 'Deskripsi Kejadian'
                        : _lang == 'ZH'
                            ? '事故描述'
                            : 'Incident Description',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade800),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                  laporan['deskripsi'] ?? '-',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF1E3A8A),
                      height: 1.5),
                ),
              ],
            ),
          ),

          if (laporan['tindakan_diambil'] != null &&
              laporan['tindakan_diambil'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.medical_services_outlined,
                        size: 14, color: Colors.green.shade800),
                    const SizedBox(width: 6),
                    Text(
                      _lang == 'ID'
                          ? 'Tindakan yang Diambil'
                          : _lang == 'ZH'
                              ? '已采取的措施'
                              : 'Action Taken',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade800),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    laporan['tindakan_diambil'],
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF1E3A8A),
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Countdown & Swipe Area ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Status countdown
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: canSwipe
                        ? headerColors.first.withValues(alpha:0.08)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canSwipe
                          ? headerColors.first.withValues(alpha:0.3)
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canSwipe
                            ? Icons.swipe_rounded
                            : Icons.timer_outlined,
                        size: 18,
                        color: canSwipe
                            ? headerColors.first
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canSwipe
                            ? t('swipe_now')
                            : '${t("wait_prefix")} $_accidentCountdown ${t("wait_suffix")}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: canSwipe
                              ? headerColors.first
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Swipe Valid
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
                const SizedBox(height: 10),

                // Swipe Invalid
                SizedBox(
                  width: double.infinity,
                  child: _SwipeButton(
                    label: t('swipe_incorrect'),
                    color: const Color(0xFFDC2626),
                    icon: Icons.arrow_back_rounded,
                    direction: _SwipeDirection.rightToLeft,
                    enabled: canSwipe,
                    onSwiped: () => _submitAccidentVerification(false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helper: Grid 2 kolom untuk info laporan ──
  Widget _buildInfoGrid(List<Map<String, dynamic>> items) {
    final List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildInfoGridItem(left)),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? _buildInfoGridItem(right)
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildInfoGridItem(Map<String, dynamic> item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item['icon'] as IconData,
            size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['label'] as String,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey.shade500),
              ),
              Text(
                item['value'] as String,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditAccidentDialog(Map<String, dynamic> laporan) {
    final judulCtrl = TextEditingController(text: laporan['judul'] ?? '');
    final descCtrl = TextEditingController(text: laporan['deskripsi'] ?? '');
    final tindakanCtrl =
        TextEditingController(text: laporan['tindakan_diambil'] ?? '');
    final deptCtrl =
        TextEditingController(text: laporan['departemen_terdampak'] ?? '');
    String selectedSeverity = laporan['tingkat_keparahan'] ?? 'Ringan';
    String selectedCause = laporan['penyebab'] ?? 'Lainnya';
    bool isSaving = false;

    final List<String> severities = ['Ringan', 'Menengah', 'Berat'];
    final List<String> causes = [
      'Mesin', 'Benda Berat', 'Kendaraan / Alat Angkut',
      'Jatuh', 'Listrik', 'Panas / Api', 'Perkakas',
      'Benda Tajam', 'Bahan Kimia', 'Lainnya',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Color(0xFFDC2626), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lang == 'ID'
                            ? 'Edit Laporan Kecelakaan'
                            : _lang == 'ZH'
                                ? '编辑事故报告'
                                : 'Edit Accident Report',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Judul
                _buildEditField(
                    ctrl: judulCtrl,
                    label: _lang == 'ID' ? 'Judul *' : 'Title *',
                    hint: _lang == 'ID'
                        ? 'Contoh: Tergelincir di gudang'
                        : 'Example: Slipped in warehouse'),
                const SizedBox(height: 14),

                // Deskripsi
                _buildEditField(
                    ctrl: descCtrl,
                    label: _lang == 'ID'
                        ? 'Deskripsi Kejadian *'
                        : 'Incident Description *',
                    hint: _lang == 'ID'
                        ? 'Ceritakan kejadian secara rinci...'
                        : 'Describe the incident...',
                    maxLines: 4),
                const SizedBox(height: 14),

                // Severity dropdown
                Text(
                    _lang == 'ID' ? 'Tingkat Keparahan *' : 'Severity Level *',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSeverity,
                      isExpanded: true,
                      items: severities
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  style: GoogleFonts.poppins(fontSize: 14))))
                          .toList(),
                      onChanged: (v) =>
                          setDlg(() => selectedSeverity = v ?? selectedSeverity),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Cause dropdown
                Text(
                    _lang == 'ID' ? 'Penyebab *' : 'Cause *',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCause,
                      isExpanded: true,
                      items: causes
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) =>
                          setDlg(() => selectedCause = v ?? selectedCause),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Departemen
                _buildEditField(
                    ctrl: deptCtrl,
                    label: _lang == 'ID'
                        ? 'Departemen Terdampak'
                        : 'Affected Department',
                    hint: _lang == 'ID' ? 'Contoh: Marketing' : 'e.g. Marketing'),
                const SizedBox(height: 14),

                // Tindakan
                _buildEditField(
                    ctrl: tindakanCtrl,
                    label: _lang == 'ID' ? 'Tindakan yang Diambil' : 'Action Taken',
                    hint: _lang == 'ID'
                        ? 'Contoh: Dibawa ke rumah sakit'
                        : 'e.g. Taken to hospital',
                    maxLines: 3),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                            _lang == 'ID' ? 'Batal' : 'Cancel',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (judulCtrl.text.trim().isEmpty ||
                                    descCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(_lang == 'ID'
                                        ? 'Judul dan deskripsi wajib diisi!'
                                        : 'Title and description required!'),
                                    backgroundColor: Colors.red,
                                  ));
                                  return;
                                }
                                setDlg(() => isSaving = true);
                                try {
                                  await _client
                                      .from('accident_report')
                                      .update({
                                    'judul': judulCtrl.text.trim(),
                                    'deskripsi': descCtrl.text.trim(),
                                    'tingkat_keparahan': selectedSeverity,
                                    'penyebab': selectedCause,
                                    'departemen_terdampak':
                                        deptCtrl.text.trim().isEmpty
                                            ? null
                                            : deptCtrl.text.trim(),
                                    'tindakan_diambil':
                                        tindakanCtrl.text.trim().isEmpty
                                            ? null
                                            : tindakanCtrl.text.trim(),
                                    'updated_at':
                                        DateTime.now().toIso8601String(),
                                  }).eq('id_laporan',
                                          laporan['id_laporan'].toString());

                                  // Update local state
                                  if (mounted) {
                                    setState(() {
                                      _accidentData!['judul'] =
                                          judulCtrl.text.trim();
                                      _accidentData!['deskripsi'] =
                                          descCtrl.text.trim();
                                      _accidentData!['tingkat_keparahan'] =
                                          selectedSeverity;
                                      _accidentData!['penyebab'] = selectedCause;
                                      _accidentData!['departemen_terdampak'] =
                                          deptCtrl.text.trim().isEmpty
                                              ? null
                                              : deptCtrl.text.trim();
                                      _accidentData!['tindakan_diambil'] =
                                          tindakanCtrl.text.trim().isEmpty
                                              ? null
                                              : tindakanCtrl.text.trim();
                                    });
                                  }
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(_lang == 'ID'
                                        ? 'Laporan berhasil diperbarui!'
                                        : 'Report updated successfully!'),
                                    backgroundColor: Colors.green,
                                  ));
                                } catch (e) {
                                  debugPrint('Update error: $e');
                                  setDlg(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                _lang == 'ID' ? 'Simpan' : 'Save',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper field untuk dialog edit
  Widget _buildEditField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFDC2626), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAccidentInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label: ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
                    color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 8),
            Text(t('success_body'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _loadNextAccidentReport,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(t('continue_btn')),
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

  // Form penyelesaian accident report (setelah HRD vote)
  Widget _buildResolutionForm() {
    final judulCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final korektifCtrl = TextEditingController();
    final preventifCtrl = TextEditingController();
    bool isSavingResolution = false;

    return StatefulBuilder(
      builder: (context, setInner) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded,
                        color: Colors.white70, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lang == 'ID' ? 'Isi Penyelesaian Laporan'
                                : _lang == 'ZH' ? '填写解决方案'
                                : 'Fill Report Resolution',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            _lang == 'ID' ? 'Berikan tindakan korektif dan preventif'
                                : _lang == 'ZH' ? '提供纠正和预防措施'
                                : 'Provide corrective and preventive actions',
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildResFormField(
                ctrl: judulCtrl,
                label: _lang == 'ID' ? 'Judul Penyelesaian *'
                    : _lang == 'ZH' ? '解决方案标题 *' : 'Resolution Title *',
                hint: _lang == 'ID' ? 'Contoh: Penanganan Insiden Gudang'
                    : 'Example: Warehouse Incident Handling',
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 14),
              _buildResFormField(
                ctrl: descCtrl,
                label: _lang == 'ID' ? 'Deskripsi Penyelesaian *'
                    : _lang == 'ZH' ? '解决方案描述 *' : 'Resolution Description *',
                hint: _lang == 'ID' ? 'Jelaskan penyelesaian secara rinci...'
                    : 'Explain the resolution in detail...',
                icon: Icons.description_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              _buildResFormField(
                ctrl: korektifCtrl,
                label: _lang == 'ID' ? 'Tindakan Korektif'
                    : _lang == 'ZH' ? '纠正措施' : 'Corrective Action',
                hint: _lang == 'ID' ? 'Tindakan untuk mengatasi masalah...'
                    : 'Actions to address the issue...',
                icon: Icons.build_rounded,
                maxLines: 3,
                color: const Color(0xFFF97316),
              ),
              const SizedBox(height: 14),
              _buildResFormField(
                ctrl: preventifCtrl,
                label: _lang == 'ID' ? 'Tindakan Preventif'
                    : _lang == 'ZH' ? '预防措施' : 'Preventive Action',
                hint: _lang == 'ID' ? 'Tindakan untuk mencegah terulang...'
                    : 'Actions to prevent recurrence...',
                icon: Icons.shield_rounded,
                maxLines: 3,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showResolutionForm = false;
                          _showAccidentSuccess = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_lang == 'ID' ? 'Lewati'
                          : _lang == 'ZH' ? '跳过' : 'Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isSavingResolution ? null : () async {
                        if (judulCtrl.text.trim().isEmpty ||
                            descCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(_lang == 'ID'
                                ? 'Judul dan deskripsi wajib diisi!'
                                : 'Title and description are required!'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        setInner(() => isSavingResolution = true);
                        try {
                          final userId = _client.auth.currentUser!.id;
                          await _client.from('resolution_accident').insert({
                            'id_laporan': _accidentData!['id_laporan'],
                            'id_hrd': userId,
                            'judul_resolusi': judulCtrl.text.trim(),
                            'deskripsi_resolusi': descCtrl.text.trim(),
                            'tindakan_korektif': korektifCtrl.text.trim().isEmpty
                                ? null : korektifCtrl.text.trim(),
                            'tindakan_preventif': preventifCtrl.text.trim().isEmpty
                                ? null : preventifCtrl.text.trim(),
                            'tanggal_resolusi': DateTime.now()
                                .toIso8601String().substring(0, 10),
                          });
                          // Update status accident_report menjadi Selesai
                          await _client.from('accident_report')
                              .update({'status': 'Selesai'})
                              .eq('id_laporan', _accidentData!['id_laporan']);

                          if (mounted) {
                            setState(() {
                              _showResolutionForm = false;
                              _showAccidentSuccess = true;
                            });
                          }
                        } catch (e) {
                          debugPrint('Save resolution error: $e');
                          setInner(() => isSavingResolution = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isSavingResolution
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(_lang == 'ID' ? 'Simpan Penyelesaian'
                              : _lang == 'ZH' ? '保存解决方案'
                              : 'Save Resolution',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResFormField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    Color color = const Color(0xFF00C9E4),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: const Color(0xFF1E3A8A))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: color, size: 20) : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withValues(alpha:0.3), width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildAccidentHistoryCard(Map<String, dynamic> data) {
    final String? lid = data['id_laporan']?.toString();
    final String title = data['judul']?.toString() ?? '-';
    final String? imageUrl = data['foto_bukti']?.toString();
    final bool? finalOutcome = data['hasil_verifikasi_mayoritas'] as bool?;
    final bool isFinalized = data['is_verif'] as bool? ?? false;
    final String severity = data['tingkat_keparahan'] ?? '';
    final String lokasiName = data['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String pelaporName = data['pelapor']?['nama']?.toString() ?? '-';
    final String pihakName =
        data['pihak_terdampak']?['nama']?.toString() ?? '-';
    final String tanggalKejadian = data['tanggal_kejadian']?.toString() ?? '-';
    final String penyebab = data['penyebab']?.toString() ?? '-';

    // Waktu finalisasi — gunakan updated_at jika ada, fallback ke created_at
    String finalisasiDateStr = '-';
    try {
      final rawDate = data['updated_at'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        finalisasiDateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final stats =
        lid != null ? (_accidentVoteStats[lid] ?? {}) : <String, dynamic>{};
    final int validCount = (stats['valid_count'] as int?) ?? 0;
    final int invalidCount = (stats['invalid_count'] as int?) ?? 0;
    final int totalVotes = (stats['total'] as int?) ?? 0;

    final Map<String, Map<String, String>> verifDetailMap =
        (stats['verif_detail_map'] as Map?)?.map(
              (k, v) => MapEntry(
                k.toString(),
                (v as Map).map((dk, dv) =>
                    MapEntry(dk.toString(), dv?.toString() ?? '')),
              ),
            ) ??
            {};

    // Status berdasarkan hasil_verifikasi_mayoritas
    final Color accent =
        finalOutcome == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final String statusLabel =
        finalOutcome == true ? t('valid') : t('invalid');
    final IconData statusIcon =
        finalOutcome == true ? Icons.verified_rounded : Icons.cancel_rounded;

    final Color sevColor = severity == 'Berat'
        ? const Color(0xFFDC2626)
        : severity == 'Menengah'
            ? const Color(0xFFF97316)
            : const Color(0xFF16A34A);

    final double validRatio = totalVotes > 0 ? validCount / totalVotes : 0.0;

    return GestureDetector(
      onTap: () => _showAccidentHistoryDetail(
          data, stats, accent, statusLabel, statusIcon,
          statusLabel, accent, validRatio),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha:0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha:0.08),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            // ── Header: foto + info utama ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto bukti
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade100,
                      child: imageUrl != null
                          ? Image.network(imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  Icons.warning_amber_rounded,
                                  color: sevColor, size: 28))
                          : Icon(Icons.warning_amber_rounded,
                              color: sevColor, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info tengah
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge ACCIDENT + Severity
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _lang == 'ID' ? 'KECELAKAAN'
                                  : _lang == 'ZH' ? '事故' : 'ACCIDENT',
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sevColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: sevColor.withValues(alpha:0.4), width: 1),
                            ),
                            child: Text(severity,
                                style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: sevColor)),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        // Judul
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E3A8A),
                                height: 1.25)),
                        const SizedBox(height: 5),
                        // Lokasi
                        Row(children: [
                          const Icon(Icons.place_rounded,
                              size: 12, color: Color(0xFF0891B2)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(lokasiName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0891B2))),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        // Pelapor
                        Row(children: [
                          Icon(Icons.person_outline,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(pelaporName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade600)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        // Waktu finalisasi
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1E3A8A).withValues(alpha:0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF1E3A8A)
                                    .withValues(alpha:0.12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 11, color: Color(0xFF1E3A8A)),
                              const SizedBox(width: 4),
                              Text(
                                '${_lang == 'ID' ? 'Final' : 'Finalized'}: $finalisasiDateStr',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge kanan
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha:0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: Colors.white, size: 18),
                            const SizedBox(height: 3),
                            Text(
                              statusLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Divider ──
            Container(height: 1, color: Colors.grey.shade100),

            // ── Verificator badges ──
            if (verifDetailMap.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 13, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 5),
                      Text(
                        _lang == 'ID' ? 'Diverifikasi Oleh'
                            : _lang == 'ZH' ? '由...验证' : 'Verified By',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: verifDetailMap.entries.map((entry) {
                        final nama = entry.value['nama'] ?? '-';
                        final jabatan = entry.value['jabatan'] ?? '';
                        final jabatanId = entry.value['jabatan_id'] ?? '';
                        final fotoUrl = entry.value['foto_url'] ?? '';

                        Color badgeColor;
                        IconData badgeIcon;
                        if (jabatanId == '5') {
                          badgeColor = const Color(0xFFEC4899);
                          badgeIcon = Icons.people_rounded;
                        } else if (jabatanId == '2') {
                          badgeColor = const Color(0xFF3B82F6);
                          badgeIcon = Icons.workspace_premium_rounded;
                        } else if (jabatanId == '1') {
                          badgeColor = const Color(0xFFFB7185);
                          badgeIcon = Icons.workspace_premium_rounded;
                        } else {
                          badgeColor = const Color(0xFF8B5CF6);
                          badgeIcon = Icons.badge_rounded;
                        }

                        return Container(
                          padding:
                              const EdgeInsets.fromLTRB(6, 5, 10, 5),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha:0.07),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: badgeColor.withValues(alpha:0.25),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: badgeColor.withValues(alpha:0.15),
                                  border: Border.all(
                                      color: badgeColor.withValues(alpha:0.4),
                                      width: 1.5),
                                ),
                                child: ClipOval(
                                  child: fotoUrl.isNotEmpty
                                      ? Image.network(fotoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Icon(badgeIcon,
                                                  size: 14,
                                                  color: badgeColor))
                                      : Icon(badgeIcon,
                                          size: 14, color: badgeColor),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(nama,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: badgeColor)),
                                  if (jabatan.isNotEmpty)
                                    Text(jabatan,
                                        style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color:
                                                badgeColor.withValues(alpha:0.7),
                                            fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    _lang == 'ID'
                        ? 'Belum ada yang memverifikasi'
                        : 'No verifier yet',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // ── Detail popup saat history card diklik ──
  void _showAccidentHistoryDetail(
    Map<String, dynamic> data,
    Map<String, dynamic> stats,
    Color accent,
    String statusLabel,
    IconData statusIcon,
    String voteLabel,
    Color voteColor,
    double validRatio,
  ) {
    final String title = data['judul']?.toString() ?? '-';
    final String? imageUrl = data['foto_bukti']?.toString();
    final String severity = data['tingkat_keparahan'] ?? '';
    final String deskripsi = data['deskripsi']?.toString() ?? '-';
    final String lokasiName = data['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String pelaporName = data['pelapor']?['nama']?.toString() ?? '-';
    final String pihakName =
        data['pihak_terdampak']?['nama']?.toString() ?? '-';
    final String tanggal =
        data['tanggal_kejadian']?.toString() ?? '-';
    final String waktu =
        data['waktu_kejadian']?.toString().substring(0, 5) ?? '-';
    final String penyebab = data['penyebab']?.toString() ?? '-';
    final bool? finalOutcome = data['hasil_verifikasi_mayoritas'] as bool?;
    final bool isFinalized = data['is_verif'] as bool? ?? false;
    final int validCount = (stats['valid_count'] as int?) ?? 0;
    final int invalidCount = (stats['invalid_count'] as int?) ?? 0;
    final int totalVotes = (stats['total'] as int?) ?? 0;
    final int totalHrd = (stats['total_hrd'] as int?) ?? 1;

    String dateStr = '-';
    try {
      final rawDate = data['waktu_verifikasi'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final Color sevColor = severity == 'Berat'
        ? const Color(0xFFDC2626)
        : severity == 'Menengah'
            ? const Color(0xFFF97316)
            : const Color(0xFF16A34A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F7FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.userJabatanId == 2
                        ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
                        : [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.health_and_safety_outlined,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lang == 'ID'
                                ? 'Detail Laporan Kecelakaan'
                                : _lang == 'ZH'
                                    ? '事故报告详情'
                                    : 'Accident Report Detail',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                          Text(dateStr,
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    // Badge Valid/Invalid berwarna solid
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha:0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Foto bukti
                    if (imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(children: [
                          Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                height: 200,
                                color: Colors.grey.shade100,
                                child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 48)),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: sevColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(severity,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Judul & Identitas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E3A8A))),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildDetailInfoRow(Icons.person_outline,
                              _lang == 'ID' ? 'Pelapor' : 'Reporter',
                              pelaporName),
                          _buildDetailInfoRow(Icons.personal_injury_outlined,
                              _lang == 'ID' ? 'Pihak Terdampak' : 'Affected',
                              pihakName),
                          _buildDetailInfoRow(Icons.location_on_outlined,
                              _lang == 'ID' ? 'Lokasi' : 'Location', lokasiName),
                          _buildDetailInfoRow(Icons.calendar_today,
                              _lang == 'ID' ? 'Tanggal' : 'Date', tanggal),
                          _buildDetailInfoRow(Icons.access_time,
                              _lang == 'ID' ? 'Waktu' : 'Time', waktu),
                          _buildDetailInfoRow(Icons.build_circle_outlined,
                              _lang == 'ID' ? 'Penyebab' : 'Cause', penyebab),
                          if (data['supervisor_user']?['nama'] != null)
                            _buildDetailInfoRow(
                                Icons.supervisor_account_outlined,
                                'Supervisor',
                                data['supervisor_user']['nama'].toString()),
                          if (data['saksi_user']?['nama'] != null)
                            _buildDetailInfoRow(
                                Icons.visibility_outlined,
                                _lang == 'ID' ? 'Saksi' : 'Witness',
                                data['saksi_user']['nama'].toString()),
                          if (data['departemen_terdampak'] != null)
                            _buildDetailInfoRow(
                                Icons.business_outlined,
                                _lang == 'ID' ? 'Departemen' : 'Department',
                                data['departemen_terdampak'].toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Deskripsi
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.description_outlined,
                                size: 14, color: Colors.orange.shade800),
                            const SizedBox(width: 6),
                            Text(
                              _lang == 'ID'
                                  ? 'Deskripsi Kejadian'
                                  : _lang == 'ZH'
                                      ? '事故描述'
                                      : 'Incident Description',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade800),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(deskripsi,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF1E3A8A),
                                  height: 1.5)),
                        ],
                      ),
                    ),

                    if (data['tindakan_diambil'] != null &&
                        data['tindakan_diambil'].toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.medical_services_outlined,
                                  size: 14, color: Colors.green.shade800),
                              const SizedBox(width: 6),
                              Text(
                                _lang == 'ID'
                                    ? 'Tindakan yang Diambil'
                                    : 'Action Taken',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade800),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text(data['tindakan_diambil'].toString(),
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF1E3A8A),
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper row untuk detail di bottom sheet
  Widget _buildDetailInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha:0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade500)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Popup overlay untuk accident verification
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

    // Warna badge sesuai getCardGradient dari jabatan_helper.dart
    // Ambil warna pertama (paling cerah) dan terakhir (medium) sebagai gradient badge
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
                color: const Color(0xFF1E3A8A),
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
                        ? const Color(0xFF0EA5E9)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _tabIndex == 0
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
                    if (_isHrdMode) {
                      _loadAccidentHistory();
                    } else {
                      _loadHistory();
                    }
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

  Widget _buildVerifyTab() {
    // HRD: tampilkan verifikasi accident report
    if (_isHrdMode) {
      if (_isAccidentLoading) return _buildVerifyShimmer();
      if (_showAccidentSuccess) return _buildAccidentSuccessView();
      if (_showResolutionForm && _accidentData != null) {
        return _buildResolutionForm();
      }
      if (_noAccidentData) return _buildNoDataView();
      if (_accidentData != null) return _buildAccidentVerificationCard();
      return const SizedBox();
    }
    // Non-HRD: verifikasi temuan biasa
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
                  ? const Color(0xFF00C9E4).withValues(alpha:0.1)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: canSwipe
                    ? const Color(0xFF00C9E4).withValues(alpha:0.3)
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

    // Label decoy
    final bool showDecoyBadge = _isDecoyMode;

    return Column(
      children: [
        if (showDecoyBadge)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha:0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology_alt_rounded,
                    size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _lang == 'ID'
                        ? '🔍 Uji Ketelitian — Perhatikan gambar dengan seksama!'
                        : '🔍 Focus Test — Examine the images carefully!',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: timerColor.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: timerColor.withValues(alpha:0.3)),
          ),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.timer_rounded, size: 16, color: timerColor),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        _lang == 'ID'
                            ? 'Auto-valid setelah $_verifikasiDurasiHari hari'
                            : 'Auto-valid after $_verifikasiDurasiHari days',
                        style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: timerColor.withValues(alpha:0.7)),
                      ),
                    ],
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
                backgroundColor: timerColor.withValues(alpha:0.12),
                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              ),
            ),
          ]),
        ),
      ],
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
                      color: const Color(0xFF4ADE80).withValues(alpha:0.1),
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
                    color: const Color(0xFF00C9E4).withValues(alpha:0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF00C9E4).withValues(alpha:0.3),
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
                      color: const Color(0xFF00C9E4).withValues(alpha:0.4),
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
    if (_isHrdMode) {
      if (_accidentHistoryLoading) return _buildHistoryShimmer();
      if (_accidentHistoryList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 70, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(t('hist_empty'),
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade400)),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _accidentHistoryList.length,
        itemBuilder: (_, i) => _buildAccidentHistoryCard(_accidentHistoryList[i]),
      );
    }
    // Non-HRD: history temuan biasa
    if (_historyLoading) return _buildHistoryShimmer();
    if (_historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(t('hist_empty'),
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade400)),
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
    final String? tid = data['id_temuan']?.toString();
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
        border: Border.all(color: accent.withValues(alpha:0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha:0.08),
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
                        color: accent.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: accent.withValues(alpha:0.3), width: 1.5),
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
              color: accent.withValues(alpha:0.12)),
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
                          color: const Color(0xFF1E3A8A).withValues(alpha:0.7)),
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
                            ? const Color(0xFF16A34A).withValues(alpha:0.1)
                            : Colors.orange.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFinalized
                              ? const Color(0xFF16A34A).withValues(alpha:0.3)
                              : Colors.orange.withValues(alpha:0.3),
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
                          color: const Color(0xFFDC2626).withValues(alpha:0.18)),
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
                            ? Colors.orange.withValues(alpha:0.07)
                            : finalOutcome
                                ? const Color(0xFF16A34A).withValues(alpha:0.07)
                                : const Color(0xFFDC2626).withValues(alpha:0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: finalOutcome == null
                              ? Colors.orange.withValues(alpha:0.2)
                              : finalOutcome
                                  ? const Color(0xFF16A34A).withValues(alpha:0.2)
                                  : const Color(0xFFDC2626).withValues(alpha:0.2),
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
                                ? const Color(0xFF1E3A8A).withValues(alpha:0.05)
                                : const Color(0xFFDC2626).withValues(alpha:0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: displayPoint >= 0
                                  ? const Color(0xFF1E3A8A).withValues(alpha:0.15)
                                  : const Color(0xFFDC2626).withValues(alpha:0.15),
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
                  border: Border.all(color: color.withValues(alpha:0.3)),
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
          color: color.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha:0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha:0.8))),
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
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha:0.3), width: 1)),
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