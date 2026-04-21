import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';

// ============================================================
// LAYAR VERIFIKASI EKSEKUTIF
// Panggil dengan Navigator.push ke ExecVerificationScreen
// Persyaratan: id_jabatan == 1 (Eksekutif) && is_verificator == true
// ============================================================

class ExecVerificationScreen extends StatefulWidget {
  final String lang;
  final int? userJabatanId; // untuk cek HRD di accident

  const ExecVerificationScreen({
    super.key,
    required this.lang,
    this.userJabatanId,
  });

  @override
  State<ExecVerificationScreen> createState() => _ExecVerificationScreenState();
}

class _ExecVerificationScreenState extends State<ExecVerificationScreen>
    with TickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late String _lang;

  // ── State ──
  bool _isLoading = true;
  bool _noData = false;
  bool _showSuccess = false;
  Map<String, dynamic>? _temuanData;

  // History
  bool _showHistory = false;
  bool _historyLoading = false;
  List<Map<String, dynamic>> _historyList = [];

  // Countdown untuk enable swipe
  int _countdown = 5;
  Timer? _countdownTimer;
  // Timer batas waktu verifikasi (5 menit)
  int _verificationSecondsLeft = 300; // 5 menit
  Timer? _verificationTimer;
  bool _verificationExpired = false;

  // Tab index (0 = verifikasi aktif, 1 = riwayat)
  int _tabIndex = 0;

  // ── Terjemahan ──
  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'screen_title': 'Executive Verification',
      'tab_verify': 'Verify',
      'tab_history': 'History',
      'card_title': 'Verification Review',
      'card_subtitle':
          'Examine the finding & completion carefully. Is this report valid?',
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
      'no_data_body':
          'No pending reports at the moment. Great work, Executive!',
      'back': 'Back',
      'success_title': 'Verification Submitted',
      'success_body': 'Thank you! Continue to the next?',
      'continue_btn': 'Next Report',
      'auto_next': 'Auto-next in',
      'auto_suf': 's',
      'hist_title': 'Verification History',
      'hist_empty': 'No history yet.',
      'your_vote': 'Your Vote',
      'match': 'Match',
      'mismatch': 'Mismatch',
      'pending': 'Pending',
      'valid': 'Valid',
      'invalid': 'Invalid',
      'accident_restricted':
          'Accident reports can only be verified by HRD.',
    },
    'ID': {
      'screen_title': 'Verifikasi Eksekutif',
      'tab_verify': 'Verifikasi',
      'tab_history': 'Riwayat',
      'card_title': 'Tinjauan Verifikasi',
      'card_subtitle':
          'Periksa temuan & penyelesaian dengan teliti. Apakah laporan ini valid?',
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
      'no_data_body':
          'Tidak ada laporan yang perlu diverifikasi saat ini. Kerja bagus!',
      'back': 'Kembali',
      'success_title': 'Verifikasi Terkirim',
      'success_body': 'Terima kasih! Lanjut ke berikutnya?',
      'continue_btn': 'Laporan Berikutnya',
      'auto_next': 'Lanjut otomatis dalam',
      'auto_suf': 'd',
      'hist_title': 'Riwayat Verifikasi',
      'hist_empty': 'Belum ada riwayat.',
      'your_vote': 'Pilihan Anda',
      'match': 'Sesuai',
      'mismatch': 'Tidak Sesuai',
      'pending': 'Menunggu',
      'valid': 'Valid',
      'invalid': 'Tidak Valid',
      'accident_restricted':
          'Laporan kecelakaan hanya dapat diverifikasi oleh HRD.',
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
      'no_data_body': '目前没有待处理的报告。做得好！',
      'back': '返回',
      'success_title': '验证已提交',
      'success_body': '谢谢！继续下一个？',
      'continue_btn': '下一份报告',
      'auto_next': '自动继续于',
      'auto_suf': '秒',
      'hist_title': '验证历史',
      'hist_empty': '暂无历史记录。',
      'your_vote': '您的投票',
      'match': '匹配',
      'mismatch': '不匹配',
      'pending': '待定',
      'valid': '有效',
      'invalid': '无效',
      'accident_restricted': '事故报告只能由HRD验证。',
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

  // ── Load temuan berikutnya ──
  Future<void> _loadNextTemuan() async {
    setState(() {
      _isLoading = true;
      _noData = false;
      _showSuccess = false;
      _temuanData = null;
    });

    try {
      final userId = _client.auth.currentUser!.id;

      // Sudah diverifikasi oleh user ini
      final verifiedLogs = await _client
          .from('verifikasi_log')
          .select('id_temuan')
          .eq('id_verificator', userId);
      final verifiedIds =
          verifiedLogs.map<dynamic>((l) => l['id_temuan']).toList();

      // Bangun query
      var query = _client.from('temuan').select('''
        id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, status_temuan,
        id_kategoritemuan,
        penyelesaian:id_penyelesaian (gambar_penyelesaian, catatan_penyelesaian),
        kategoritemuan:id_kategoritemuan (nama_kategoritemuan),
        lokasi:id_lokasi(nama_lokasi),
        area:id_area(nama_area),
        unit:id_unit(nama_unit)
      ''').eq('status_temuan', 'Selesai').eq('is_verif', false);

      if (verifiedIds.isNotEmpty) {
        query = query.not(
            'id_temuan', 'in', verifiedIds);
      }

      final result = await query
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _noData = true;
          _isLoading = false;
        });
        return;
      }

      // Cek apakah kategori kecelakaan & user bukan HRD
      // Asumsikan id_kategoritemuan untuk kecelakaan/accident tertentu
      // dan HRD memiliki id_jabatan tertentu (sesuaikan dengan data Anda)
      // Di sini kita cek dari nama kategori mengandung 'kecelakaan' atau 'accident'
      final String katName = (result['kategoritemuan']?['nama_kategoritemuan']
                  ?.toString() ??
              '')
          .toLowerCase();
      final bool isAccident =
          katName.contains('kecelakaan') || katName.contains('accident');

      // HRD: id_jabatan tertentu — sesuaikan dengan data Anda
      // Anggap HRD = id_jabatan 5 (sesuaikan)
      const int hrdJabatanId = 5;
      final bool isHrd = widget.userJabatanId == hrdJabatanId;

      if (isAccident && !isHrd) {
        // Skip & load next
        // Tandai agar tidak terus loop — tambahkan id ke exclude manual
        // Untuk sekarang: tampilkan pesan
        setState(() {
          _isLoading = false;
          _noData = true;
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
        _temuanData = result;
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      debugPrint('ExecVerif error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 5);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() {});
      }
    });
    _startVerificationTimer(); // ← TAMBAHKAN BARIS INI
  }

  void _startVerificationTimer() {
    _verificationTimer?.cancel();
    setState(() {
      _verificationSecondsLeft = 300;
      _verificationExpired = false;
    });
    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_verificationSecondsLeft > 0) {
        setState(() => _verificationSecondsLeft--);
      } else {
        timer.cancel();
        setState(() => _verificationExpired = true);
        // Otomatis lanjut ke temuan berikutnya saat waktu habis
        _loadNextTemuan();
      }
    });
  }

  Future<void> _submitVerification(bool isValid) async {
    if (_temuanData == null) return;
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser!.id;
      final temuanId = _temuanData!['id_temuan'];

      await _client.rpc('handle_verification_vote', params: {
        'p_temuan_id': temuanId,
        'p_verificator_id': userId,
        'p_vote_is_correct': isValid,
        'p_point_change': 5,
      });

      // ── Ambil konfigurasi poin verifikasi dari DB ──
      int pointReward = 10;
      int pointPenalty = 5;
      String descReward = '';
      String descPenalty = '';

      try {
        final configs = await _client
            .from('konfigurasi_poin')
            .select('kode, poin, deskripsi_template')
            .inFilter('kode', ['verifikasi_benar', 'verifikasi_salah'])
            .eq('is_aktif', true);

        for (final cfg in configs) {
          if (cfg['kode'] == 'verifikasi_benar') {
            pointReward = (cfg['poin'] as num).toInt().abs();
            descReward = cfg['deskripsi_template']?.toString() ?? '';
          } else if (cfg['kode'] == 'verifikasi_salah') {
            pointPenalty = (cfg['poin'] as num).toInt().abs();
            descPenalty = cfg['deskripsi_template']?.toString() ?? '';
          }
        }
      } catch (_) {}

      // Fallback deskripsi jika konfigurasi kosong
      if (descReward.isEmpty) {
        descReward = widget.lang == 'EN'
            ? 'Your verification vote matched the majority. +$pointReward points!'
            : widget.lang == 'ZH'
                ? '您的验证投票与多数一致。+$pointReward积分！'
                : 'Suara verifikasi Anda sesuai mayoritas. +$pointReward poin!';
      }
      if (descPenalty.isEmpty) {
        descPenalty = widget.lang == 'EN'
            ? 'Your verification vote was in the minority. -$pointPenalty points.'
            : widget.lang == 'ZH'
                ? '您的验证投票属于少数。-$pointPenalty积分。'
                : 'Suara verifikasi Anda masuk minoritas. -$pointPenalty poin.';
      }

      // ── Cek hasil verifikasi: apakah user ada di mayoritas? ──
      // Ambil log verifikasi untuk temuan ini
      final logs = await _client
          .from('verifikasi_log')
          .select('jawaban_benar')
          .eq('id_temuan', temuanId);

      final int totalVotes = logs.length;
      final int validVotes =
          logs.where((l) => l['jawaban_benar'] == true).length;
      final int invalidVotes = totalVotes - validVotes;

      // Tentukan mayoritas
      final bool majorityIsValid = validVotes >= invalidVotes;
      final bool userInMajority = isValid == majorityIsValid;

      // Jika voting sudah cukup (minimal 2 suara) untuk menentukan posisi
      if (totalVotes >= 2) {
        final int pointChange = userInMajority ? pointReward : -pointPenalty;
        final String desc =
            userInMajority ? descReward : descPenalty;
        final String tipe = userInMajority
            ? 'verifikasi_benar'
            : 'verifikasi_salah';

        // ── Simpan ke log_poin ──
        await _client.from('log_poin').insert({
          'id_user': userId,
          'poin': pointChange,
          'deskripsi': desc,
          'tipe_aktivitas': tipe,
        });

        // ── Update poin user ──
        await _client.rpc('increment_user_poin', params: {
          'p_user_id': userId,
          'p_delta': pointChange,
        });

        // ── Tampilkan notifikasi lokal ──
        NotificationService.instance.showNotification(
          title: userInMajority
              ? (widget.lang == 'EN'
                  ? '🎉 Verification Points!'
                  : widget.lang == 'ZH'
                      ? '🎉 验证积分！'
                      : '🎉 Poin Verifikasi!')
              : (widget.lang == 'EN'
                  ? '⚠️ Points Deducted'
                  : widget.lang == 'ZH'
                      ? '⚠️ 积分已扣除'
                      : '⚠️ Poin Dikurangi'),
          body: desc,
        );

        // ── Tampilkan dialog notifikasi poin (seperti di home) ──
        if (mounted) {
          _showVerifPointDialog(pointChange, desc, tipe);
        }
      }

      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });
    } catch (e) {
      debugPrint('Submit verif error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerifPointDialog(int points, String description, String tipe) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) {
        // Auto dismiss setelah 4.5 detik
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
                    // Header
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
                    // Body
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

  // ── Load history ──
  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('verifikasi_log')
          .select('''
            jawaban_benar,
            temuan:id_temuan (
              *, hasil_verifikasi_mayoritas,
              lokasi(nama_lokasi), unit(nama_unit),
              subunit(nama_subunit), area(nama_area)
            )
          ''')
          .eq('id_verificator', userId)
          .order('waktu_verifikasi', ascending: false);

      final List<Map<String, dynamic>> processed = [];
      for (var item in response) {
        if (item['temuan'] != null) {
          final data = Map<String, dynamic>.from(item['temuan']);
          data['user_vote'] = item['jawaban_benar'];
          processed.add(data);
        }
      }
      if (mounted) {
        setState(() {
          _historyList = processed;
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _tabIndex == 0 ? _buildVerifyTab() : _buildHistoryTab(),
            ),
          ],
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('screen_title'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          // Badge eksekutif
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
      child: Row(
        children: [
          _TabChip(
            label: t('tab_verify'),
            icon: Icons.verified_outlined,
            isActive: _tabIndex == 0,
            activeColor: const Color(0xFF00C9E4),
            onTap: () => setState(() => _tabIndex = 0),
          ),
          const SizedBox(width: 10),
          _TabChip(
            label: t('tab_history'),
            icon: Icons.history_rounded,
            isActive: _tabIndex == 1,
            activeColor: const Color(0xFF1E3A8A),
            onTap: () {
              setState(() => _tabIndex = 1);
              _loadHistory();
            },
          ),
        ],
      ),
    );
  }

  // ── Tab Verifikasi ──
  Widget _buildVerifyTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C9E4)),
      );
    }
    if (_showSuccess) return _buildSuccessView();
    if (_noData) return _buildNoDataView();
    if (_temuanData != null) return _buildVerificationCard();
    return const SizedBox();
  }

  Widget _buildVerificationCard() {
    final temuan = _temuanData!;
    final bool canSwipe = _countdown == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card
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
                      Text(
                        t('card_title'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        t('card_subtitle'),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Images row
          Row(
            children: [
              _ImageBox(
                label: t('finding'),
                url: temuan['gambar_temuan'],
                color: const Color(0xFFFF6B6B),
              ),
              const SizedBox(width: 12),
              _ImageBox(
                label: t('completion'),
                url: temuan['penyelesaian']?['gambar_penyelesaian'],
                color: const Color(0xFF4ADE80),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Notes
          _NoteCard(
            label: t('finding_notes'),
            text: temuan['deskripsi_temuan'],
            color: const Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 8),
          _NoteCard(
            label: t('completion_notes'),
            text: temuan['penyelesaian']?['catatan_penyelesaian'],
            color: const Color(0xFF4ADE80),
          ),
          const SizedBox(height: 8),

          // Info row
          _InfoRow(
            icon: Icons.category_outlined,
            text:
                '${t("category")}: ${temuan['kategoritemuan']?['nama_kategoritemuan'] ?? '-'}',
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            text:
                '${t("location")}: ${temuan['lokasi']?['nama_lokasi'] ?? '-'} ${temuan['area']?['nama_area'] != null ? '— ${temuan['area']['nama_area']}' : ''}',
          ),

          const SizedBox(height: 20),

          // Timer batas waktu
          _buildVerificationTimerBar(),
          const SizedBox(height: 12),

          // Countdown / swipe hint
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Swipe buttons
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
    final Color timerColor = isUrgent
        ? const Color(0xFFDC2626)
        : const Color(0xFF00C9E4);

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
                widget.lang == 'ID'
                    ? 'Batas waktu verifikasi'
                    : widget.lang == 'ZH'
                        ? '验证截止时间'
                        : 'Verification time limit',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: timerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: timerColor,
              ),
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
            Text(
              t('no_data_title'),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('no_data_body'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
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
                  colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C9E4).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 54),
            ),
            const SizedBox(height: 24),
            Text(
              t('success_title'),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('success_body'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey.shade500),
            ),
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

  // ── Tab History ──
  Widget _buildHistoryTab() {
    if (_historyLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C9E4)));
    }
    if (_historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              t('hist_empty'),
              style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.grey.shade400),
            ),
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

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final String title = data['judul_temuan'] ?? '-';
    final String? imageUrl = data['gambar_temuan'];
    final bool userVote = data['user_vote'] ?? false;
    final bool? finalOutcome = data['hasil_verifikasi_mayoritas'];

    Color accent;
    String statusLabel;
    IconData statusIcon;

    if (finalOutcome == null) {
      accent = Colors.grey.shade400;
      statusLabel = t('pending');
      statusIcon = Icons.hourglass_empty_rounded;
    } else {
      final bool match = userVote == finalOutcome;
      accent = match ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
      statusLabel = match ? t('match') : t('mismatch');
      statusIcon =
          match ? Icons.check_circle_outline : Icons.highlight_off_rounded;
    }

    // Location
    String loc = '-';
    if (data['area']?['nama_area'] != null) loc = data['area']['nama_area'];
    else if (data['unit']?['nama_unit'] != null) loc = data['unit']['nama_unit'];
    else if (data['lokasi']?['nama_lokasi'] != null) loc = data['lokasi']['nama_lokasi'];

    // Date
    String date = '-';
    try {
      final dt = DateTime.parse(data['created_at'].toString());
      date = DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 8,
            height: 80,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                bottomLeft: Radius.circular(17),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 62,
              height: 62,
              color: Colors.grey.shade100,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.grey))
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.place_outlined,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        loc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  ]),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // Status
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: accent, size: 26),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUB-WIDGETS
// ============================================================

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isActive ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  final String label;
  final String? url;
  final Color color;

  const _ImageBox(
      {required this.label, required this.url, required this.color});

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
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E3A8A),
              ),
            ),
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
                borderRadius: BorderRadius.circular(14),
              ),
              child: (url != null && url!.isNotEmpty)
                  ? Image.network(
                      url!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00C9E4)));
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.grey.shade400, size: 36),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400, size: 36),
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
  final String? text;
  final Color color;

  const _NoteCard(
      {required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (text != null && text!.isNotEmpty) ? text! : '-',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF1E3A8A),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Swipe button ──
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
    final newDrag =
        _drag + (isLTR ? d.delta.dx : -d.delta.dx);
    setState(() => _drag = newDrag.clamp(0.0, maxW - 56));
  }

  void _onDragEnd(DragEndDetails d, double maxW) {
    if (!widget.enabled) return;
    final threshold = (maxW - 56) * 0.75;
    if (_drag >= threshold) {
      widget.onSwiped();
      setState(() => _drag = 0);
    } else {
      final anim =
          Tween<double>(begin: _drag, end: 0).animate(
        CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
      );
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
      final opacity =
          ((trackW - _drag) / trackW).clamp(0.0, 1.0);
      final isRTL =
          widget.direction == _SwipeDirection.rightToLeft;

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
              // Label
              Padding(
                padding: EdgeInsets.only(
                  left: isRTL ? 0 : 50,
                  right: isRTL ? 50 : 0,
                ),
                child: Opacity(
                  opacity: widget.enabled ? opacity : 1.0,
                  child: Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: widget.enabled
                          ? widget.color
                          : Colors.grey.shade400,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ),
              // Thumb
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
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Icon(widget.icon,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Countdown auto next ──
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
      if (!mounted) { t.cancel(); return; }
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
    return Text(
      '${widget.textPrefix} $_count ${widget.textSuffix}',
      style: GoogleFonts.poppins(
          fontSize: 12, color: Colors.grey.shade400),
    );
  }
}