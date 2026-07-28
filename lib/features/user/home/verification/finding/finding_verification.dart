import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/services/notification_service.dart';

void unawaited(Future<void> future) {
  future.catchError((e) => debugPrint('Unawaited error: $e'));
}

class FindingVerification extends StatefulWidget {
  final String lang;
  final bool isHrdMode;
  final Function(int)? onPointEarned;

  const FindingVerification({
    super.key,
    required this.lang,
    required this.isHrdMode,
    this.onPointEarned,
  });

  @override
  State<FindingVerification> createState() => _FindingVerificationState();
}

class _FindingVerificationState extends State<FindingVerification> {
  final _client = Supabase.instance.client;
  late String _lang;
  late bool _isHrdMode;

  bool _isLoading = true;
  bool _noData = false;
  bool _showSuccess = false;
  Map<String, dynamic>? _temuanData;

  int _countdown = 5;
  Timer? _countdownTimer;
  int _verificationSecondsLeft = 300;
  Timer? _verificationTimer;

  // ── Konfigurasi verifikasi dari DB ──
  int _verifikasiDurasiHari = 7;

  bool _isDecoyMode = false;

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
      'card_title': 'Verification Review',
      'card_subtitle': 'Examine the finding & completion carefully. Is this report valid?',
      'finding': 'Finding',
      'completion': 'Solution',
      'finding_notes': 'Finding Notes',
      'completion_notes': 'Solution Notes',
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
      'verif_popup_valid': 'You voted VALID',
      'verif_popup_invalid': 'You voted INVALID',
      'verif_popup_sub': 'Your verification has been recorded.',
      'verif_popup_point': 'Participation Points',
      'verif_popup_processing': 'Processing...',
    },
    'ID': {
      'card_title': 'Tinjauan Verifikasi',
      'card_subtitle': 'Periksa temuan & penyelesaian dengan teliti. Apakah laporan ini valid?',
      'finding': 'Temuan',
      'completion': 'Solusi',
      'finding_notes': 'Catatan Temuan',
      'completion_notes': 'Catatan Solusi',
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
      'verif_popup_valid': 'Anda memilih VALID',
      'verif_popup_invalid': 'Anda memilih TIDAK VALID',
      'verif_popup_sub': 'Verifikasi Anda telah dicatat.',
      'verif_popup_point': 'Poin Partisipasi',
      'verif_popup_processing': 'Memproses...',
    },
    'ZH': {
      'card_title': '验证审查',
      'card_subtitle': '仔细检查发现和完成情况。此报告是否有效？',
      'finding': '发现',
      'completion': '解决方案',
      'finding_notes': '发现说明',
      'completion_notes': '解决方案说明',
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
    _isHrdMode = widget.isHrdMode;
    if (!_isHrdMode) {
      _loadVerifikasiConfig().then((_) {
        _loadNextTemuan();
      });
    }
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
            break;
          case 'auto_valid_jika_timeout':
            break;
        }
      }
    } catch (e) {
      debugPrint('loadVerifikasiConfig error: $e');
    }
    _generateDecoyBatch(batchStart: 0);
  }

  void _generateDecoyBatch({required int batchStart}) {
    _decoyPositions.clear();
    _currentBatchStart = batchStart;

    final rng = DateTime.now().microsecondsSinceEpoch;

    final int posA = batchStart + (rng % 5);

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

      if (_sessionVerifCount > 0 &&
          _sessionVerifCount % 10 == 0 &&
          _sessionVerifCount != _currentBatchStart) {
        _generateDecoyBatch(batchStart: _sessionVerifCount);
      }

      final bool shouldShowDecoy =
          _decoyPositions.contains(_sessionVerifCount);

      _sessionVerifCount++;

      if (shouldShowDecoy) {
        await _loadDecoyTemuan(userId, verifiedIds, cutoffDate);
        return;
      }

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
        setState(() {
          _noData = true;
          _isLoading = false;
        });
        return;
      }

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
          });
          return;
        }
        setState(() {
          _temuanData = nextResult;
          _isLoading = false;
        });
        _startCountdown();
        return;
      }

      setState(() {
        _temuanData = result;
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      debugPrint('ExecVerif loadNextTemuan error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDecoyTemuan(
    String userId,
    List<dynamic> verifiedIds,
    String cutoffDate,
  ) async {
    try {
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

      final results = await query
          .order('created_at', ascending: true)
          .limit(2);

      if (!mounted) return;

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

      final int swapType =
          DateTime.now().microsecondsSinceEpoch % 3;

      final Map<String, dynamic> primary = Map.from(results[0]);
      final Map<String, dynamic> secondary = Map.from(results[1]);
      Map<String, dynamic> decoyTemuan = Map.from(primary);

      switch (swapType) {
        case 0:
          decoyTemuan['gambar_temuan'] = secondary['gambar_temuan'];
          break;
        case 1:
          final completionCopy = Map<String, dynamic>.from(
              primary['penyelesaian'] as Map? ?? {});
          completionCopy['gambar_penyelesaian'] =
              (secondary['penyelesaian'] as Map?)?['gambar_penyelesaian'];
          decoyTemuan['penyelesaian'] = completionCopy;
          break;
        case 2:
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

      setState(() {
        _isDecoyMode = true;
        _temuanData = decoyTemuan;
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      debugPrint('loadDecoyTemuan error: $e');
      if (mounted) setState(() { _isDecoyMode = false; _isLoading = false; });
    }
  }

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
    setState(() {
      _verificationSecondsLeft = 120;
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
        _loadNextTemuan();
      }
    });
  }

  Future<void> _submitVerification(bool isValid) async {
    if (_temuanData == null) return;
    _verificationTimer?.cancel();

    if (_isDecoyMode) {
      final bool answeredCorrectly = !isValid;
      _handleDecoyResult(answeredCorrectly, isValid);
      return;
    }

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

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isDecoyMode = false;
          _showSuccess = false;
        });
        _loadNextTemuan();
      }
    });
  }

  Future<void> _processVerificationBackground(String temuanId, bool isValid) async {
    try {
      final userId = _client.auth.currentUser!.id;

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

      final results = await Future.wait<dynamic>([rpcFuture, configFuture]);

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

      await _addPointsToUser(
        userId: userId,
        points: pointParticipation,
        desc: descParticipation,
        tipe: 'verifikasi_partisipasi',
      );

      if (!mounted) return;

      widget.onPointEarned?.call(pointParticipation);

      NotificationService.instance.showNotification(
        title: _lang == 'EN'
            ? '✅ Verification Recorded'
            : _lang == 'ZH'
                ? '✅ 验证已记录'
                : '✅ Verifikasi Dicatat',
        body: descParticipation,
      );

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
                                color: const Color(0xFF1D72F3),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildVerifyTab(),
        if (_showVerifPopup) _buildVerifPopupOverlay(),
      ],
    );
  }

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
                  color: const Color(0xFF1D72F3))),
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
                color: const Color(0xFF1D72F3),
                height: 1.4),
          ),
        ],
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
                colors: [Color(0xFF1D72F3), Color(0xFF0891B2)],
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
                  labelIcon: Icons.report_problem_outlined,
                  url: temuan['gambar_temuan'],
                  color: const Color(0xFFFF6B6B)),
              const SizedBox(width: 12),
              _ImageBox(
                  label: t('completion'),
                  labelIcon: Icons.task_alt_rounded,
                  url: temuan['penyelesaian']?['gambar_penyelesaian'],
                  color: const Color(0xFF4ADE80)),
            ],
          ),
          const SizedBox(height: 14),
          _NoteCard(
              label: t('finding_notes'),
              labelIcon: Icons.sticky_note_2_outlined,
              text: temuan['deskripsi_temuan'],
              color: const Color(0xFFFF6B6B)),
          const SizedBox(height: 8),
          _NoteCard(
              label: t('completion_notes'),
              labelIcon: Icons.sticky_note_2_outlined,
              text: temuan['penyelesaian']?['catatan_penyelesaian'],
              color: const Color(0xFF4ADE80)),
          const SizedBox(height: 8),
          _buildIconSectionTitle(Icons.category_outlined, t('category')),
          _buildInfoValueCard(
            icon: Icons.category_outlined,
            text:
                temuan['kategoritemuan']?['nama_kategoritemuan']?.toString() ?? '-',
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 14),
          _buildIconSectionTitle(Icons.location_on_outlined, t('location')),
          _buildInfoValueCard(
            icon: Icons.location_on_outlined,
            text:
                '${temuan['lokasi']?['nama_lokasi'] ?? '-'}${temuan['area']?['nama_area'] != null ? ' — ${temuan['area']['nama_area']}' : ''}',
            color: const Color(0xFF10B981),
          ),
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

  Widget _buildIconSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1D72F3)),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFF1D72F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoValueCard({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTimerBar() {
    final int minutes = _verificationSecondsLeft ~/ 60;
    final int seconds = _verificationSecondsLeft % 60;
    final double progress = _verificationSecondsLeft / 120.0;
    final bool isUrgent = _verificationSecondsLeft <= 60;
    final Color timerColor =
        isUrgent ? const Color(0xFFDC2626) : const Color(0xFF00C9E4);

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
                          color: const Color(0xFF1D72F3))),
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
                      color: const Color(0xFF1D72F3)),
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
                    color: const Color(0xFF1D72F3))),
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
}

// ──────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ──────────────────────────────────────────────────────────────

class _ImageBox extends StatelessWidget {
  final String label;
  final IconData labelIcon;
  final String? url;
  final Color color;
  const _ImageBox({
    required this.label,
    required this.labelIcon,
    required this.url,
    required this.color,
  });

  void _openFullImage(BuildContext context) {
    if (url == null || url!.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.network(
                        url!,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00C9E4)));
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 44,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(labelIcon, size: 15, color: const Color(0xFF1D72F3)),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D72F3))),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _openFullImage(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: color.withValues(alpha:0.3)),
                    borderRadius: BorderRadius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (url != null && url!.isNotEmpty)
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
                    if (url != null && url!.isNotEmpty)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String label;
  final IconData labelIcon;
  final String? text;
  final Color color;
  const _NoteCard({
    required this.label,
    required this.labelIcon,
    required this.text,
    required this.color,
  });

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
        Row(children: [
          Icon(labelIcon, size: 13, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha:0.8))),
        ]),
        const SizedBox(height: 4),
        Text((text != null && text!.isNotEmpty) ? text! : '-',
            style: GoogleFonts.poppins(
                fontSize: 13, color: const Color(0xFF1D72F3), height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
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