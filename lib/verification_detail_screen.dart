import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inspectaapp/verificator_home_screen.dart';

// =======================================================
// KELAS UTAMA
// =======================================================

class VerificationDetailScreen extends StatefulWidget {
  final String lang;
  const VerificationDetailScreen({super.key, required this.lang});

  @override
  State<VerificationDetailScreen> createState() =>
      _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen>
    with TickerProviderStateMixin { // Tambahkan TickerProviderStateMixin di sini
  final SupabaseClient _client = Supabase.instance.client;

  String _lang = 'EN';

  final Map<String, Map<String, String>> _text = {
    'EN': {
      'title': 'Verify Report',
      'subtitle': 'Check the following finding and completion data. Is this report valid and appropriate?',
      'finding_image': 'Finding',
      'completion_image': 'Completion',
      'finding_notes': 'Finding Notes',
      'completion_notes': 'Completion Notes',
      'category_prefix': 'Category',
      'location_prefix': 'Location',
      'swipe_if_correct': 'SWIPE IF CORRECT',
      'swipe_if_incorrect': 'SWIPE IF INCORRECT',
      'can_answer_prefix': 'You can answer in',
      'can_answer_suffix': 'seconds',
      'please_swipe': 'PLEASE SWIPE TO ANSWER',
      'no_report_title': 'Excellent!',
      'no_report_body': 'There are currently no new reports to verify. Thank you for your hard work!',
      'back_to_home': 'Back to Home',
      'success_title': 'Verification Sent',
      'success_body': 'Thank you! Continue to the next verification?',
      'continue_verification': 'Continue Verification Now',
      'auto_continue_prefix': 'Auto-continue in',
      'auto_continue_suffix': 'seconds (or exit)',
      'error_loading': 'Error loading data:',
      'already_verified': 'You have already verified this finding.',
      'error_submitting': 'Error during submission:',
    },
    'ID': {
      'title': 'Verifikasi Laporan',
      'subtitle': 'Periksa data temuan dan penyelesaian berikut. Apakah laporan ini valid dan sesuai?',
      'finding_image': 'Temuan',
      'completion_image': 'Penyelesaian',
      'finding_notes': 'Catatan Temuan',
      'completion_notes': 'Catatan Penyelesaian',
      'category_prefix': 'Kategori',
      'location_prefix': 'Lokasi',
      'swipe_if_correct': 'GESER JIKA SESUAI',
      'swipe_if_incorrect': 'GESER JIKA TIDAK',
      'can_answer_prefix': 'Anda dapat menjawab dalam',
      'can_answer_suffix': 'detik',
      'please_swipe': 'SILAKAN GESER UNTUK MENJAWAB',
      'no_report_title': 'Luar Biasa!',
      'no_report_body': 'Saat ini tidak ada laporan baru yang perlu diverifikasi. Terima kasih atas kerja keras Anda!',
      'back_to_home': 'Kembali ke Beranda',
      'success_title': 'Verifikasi Terkirim',
      'success_body': 'Terima kasih! Lanjut verifikasi laporan berikutnya?',
      'continue_verification': 'Lanjut Verifikasi Sekarang',
      'auto_continue_prefix': 'Otomatis lanjut dalam',
      'auto_continue_suffix': 'detik (atau keluar)',
      'error_loading': 'Error memuat data:',
      'already_verified': 'Anda sudah pernah memverifikasi temuan ini.',
      'error_submitting': 'Error saat submit:',
    },
    'ZH': {
      'title': '验证报告',
      'subtitle': '请检查以下发现和完成数据。此报告是否有效且适当？',
      'finding_image': '发现',
      'completion_image': '完成',
      'finding_notes': '发现说明',
      'completion_notes': '完成说明',
      'category_prefix': '类别',
      'location_prefix': '地点',
      'swipe_if_correct': '如果正确请滑动',
      'swipe_if_incorrect': '如果不符请滑动',
      'can_answer_prefix': '您可以在',
      'can_answer_suffix': '秒后回答',
      'please_swipe': '请滑动以回答',
      'no_report_title': '太棒了!',
      'no_report_body': '目前没有新的报告需要验证。感谢您的辛勤工作！',
      'back_to_home': '返回首页',
      'success_title': '验证已发送',
      'success_body': '谢谢！要继续下一个验证吗？',
      'continue_verification': '立即继续验证',
      'auto_continue_prefix': '将在',
      'auto_continue_suffix': '秒后自动继续 (或退出)',
      'error_loading': '加载数据时出错：',
      'already_verified': '您已经验证过此发现。',
      'error_submitting': '提交时出错：',
    },
  };

  String getTxt(String key) => _text[_lang]?[key] ?? key;

  // State untuk mengelola UI
  bool _isLoading = true;
  bool _noTemuanAvailable = false;
  bool _showSuccessDialog = false;

  Map<String, dynamic>? _temuanData;
  Timer? _accessTimer;
  int _secondsToAccess = 5; // Countdown untuk bisa menjawab

  @override
  void initState() {
    super.initState();
    _lang = widget.lang;
    _findAndLoadTemuan();
  }

  @override
  void dispose() {
    _accessTimer?.cancel();
    super.dispose();
  }

  void _startAccessTimer() {
    setState(() {
      _secondsToAccess = 5;
    });
    _accessTimer?.cancel(); // Batalkan timer sebelumnya jika ada
    _accessTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsToAccess > 0) {
        setState(() {
          _secondsToAccess--;
        });
      } else {
        timer.cancel();
        setState(() {}); // Update UI untuk menunjukkan tombol aktif
      }
    });
  }

  // FUNGSI KUNCI: Mencari 1 temuan yang valid untuk diverifikasi
  Future<void> _findAndLoadTemuan() async {
    setState(() {
      _isLoading = true;
      _noTemuanAvailable = false;
      _showSuccessDialog = false;
    });

    try {
      final userId = _client.auth.currentUser!.id;

      // 1. Ambil daftar ID temuan yang SUDAH diverifikasi oleh user ini
      final verifiedLogs = await _client
          .from('verifikasi_log')
          .select('id_temuan')
          .eq('id_verificator', userId);
      final verifiedTemuanIds =
          verifiedLogs.map<dynamic>((log) => log['id_temuan']).toList();

      // 2. Cari satu temuan yang memenuhi SEMUA kriteria:
      final response = await _client
          .from('temuan')
          .select(
            '''
              id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, status_temuan,
              penyelesaian:id_penyelesaian (gambar_penyelesaian, catatan_penyelesaian),
              kategoritemuan:id_kategoritemuan (nama_kategoritemuan),
              lokasi:id_lokasi(nama_lokasi),
              area:id_area(nama_area),
              unit:id_unit(nama_unit)
            ''')
          .eq('status_temuan', 'Selesai') // Kriteria 1: Status harus 'Selesai'
          .eq('is_verif', false) // Kriteria 2: Belum terverifikasi final
          .not('id_temuan', 'in',
              verifiedTemuanIds.isNotEmpty ? verifiedTemuanIds : [0]) // Kriteria 3: Belum pernah diverifikasi user ini
          .order('created_at', ascending: true) // Ambil yang paling lama dulu
          .limit(1)
          .maybeSingle(); // Ambil satu atau null jika tidak ada

      if (!mounted) return;

      if (response == null) {
        // Tidak ada temuan yang bisa diverifikasi saat ini
        setState(() {
          _noTemuanAvailable = true;
          _isLoading = false;
        });
      } else {
        // Temuan ditemukan, siapkan UI verifikasi
        setState(() {
          _temuanData = response;
          _isLoading = false;
        });
        _startAccessTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${getTxt("error_loading")} ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _submitVerification(bool isDataSesuai) async {
    if (_temuanData == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _client.auth.currentUser!.id;
      final temuanId = _temuanData!['id_temuan'];

      await _client.rpc('handle_verification_vote', params: {
        'p_temuan_id': temuanId,
        'p_verificator_id': userId,
        'p_vote_is_correct': isDataSesuai, // Jawaban dari verifikator
        'p_point_change': 5, // Jumlah poin yang didapat
      });

      setState(() {
        _isLoading = false;
        _showSuccessDialog = true;
      });
    } catch (e) {
      if (mounted) {
        if (e is PostgrestException && e.code == '23505') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(getTxt('already_verified')),
              backgroundColor: Colors.orange));
          _findAndLoadTemuan();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${getTxt("error_submitting")} ${e.toString()}'),
              backgroundColor: Colors.red));
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // --- WIDGET BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_showSuccessDialog) {
      return _buildSuccessDialog(context);
    }
    if (_noTemuanAvailable) {
      return _buildNoTemuanAvailable();
    }
    if (_temuanData != null) {
      return _buildVerificationCard();
    }
    return const Text('Terjadi kesalahan tidak terduga.',
        style: TextStyle(color: Colors.white));
  }

  Widget _buildVerificationCard() {
    final temuan = _temuanData!;
    return Container(
      key: const ValueKey('verificationCard'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5)
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(getTxt('title'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(
              getTxt('subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageContainer(getTxt('finding_image'), temuan['gambar_temuan']),
                const SizedBox(width: 10),
                _buildImageContainer(getTxt('completion_image'),
                    temuan['penyelesaian']?['gambar_penyelesaian']),
              ],
            ),
            const SizedBox(height: 15),
            _buildNoteCard(getTxt('finding_notes'), temuan['deskripsi_temuan']),
            const SizedBox(height: 8),
            _buildNoteCard(getTxt('completion_notes'),
                temuan['penyelesaian']?['catatan_penyelesaian']),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.category_outlined,
                "${getTxt('category_prefix')}: ${temuan['kategoritemuan']?['nama_kategoritemuan'] ?? 'N/A'}"),
            _buildInfoRow(Icons.location_on_outlined,
                "${getTxt('location_prefix')}: ${temuan['lokasi']?['nama_lokasi'] ?? 'N/A'} - ${temuan['area']?['nama_area'] ?? 'N/A'}"),
            const SizedBox(height: 20),

            _buildSwipeActionButton(getTxt('swipe_if_correct'), Colors.green,
                Icons.arrow_forward, () => _submitVerification(true)),
            const SizedBox(height: 10),
            _buildSwipeActionButton(getTxt('swipe_if_incorrect'), Colors.red,
                Icons.arrow_back, () => _submitVerification(false)),

            const SizedBox(height: 15),
            Text(
              _secondsToAccess > 0
                  ? "${getTxt('can_answer_prefix')} $_secondsToAccess ${getTxt('can_answer_suffix')}"
                  : getTxt('please_swipe'),
              style: TextStyle(
                color: _secondsToAccess > 0
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeActionButton(
      String text, Color color, IconData icon, VoidCallback onSwiped) {
    bool canPress = _secondsToAccess == 0;

    final direction = (icon == Icons.arrow_forward)
        ? SwipeDirection.leftToRight
        : SwipeDirection.rightToLeft;

    return SizedBox(
      width: double.infinity, // Ini akan membuat lebarnya sama seperti kartu catatan
      child: _InteractiveSwipeButton(
        key: ValueKey(text),
        text: text,
        color: color,
        icon: icon,
        onSwiped: onSwiped,
        enabled: canPress,
        direction: direction,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style:
                      TextStyle(color: Colors.grey.shade700, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildImageContainer(String title, String? imageUrl) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Image Load Error: $error');
                        return const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.grey, size: 40));
                      },
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.grey, size: 40)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String title, String? note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(
            note != null && note.isNotEmpty ? note : '-',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNoTemuanAvailable() {
    return Container(
      key: const ValueKey('noTemuan'),
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt_rounded, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          Text(getTxt('no_report_title'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
              getTxt('no_report_body'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(getTxt('back_to_home')),
          )
        ],
      ),
    );
  }

  Widget _buildSuccessDialog(BuildContext context) {
    return PopScope(
      canPop: false,
      key: const ValueKey('successDialog'),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.blue, size: 60),
              const SizedBox(height: 20),
              Text(getTxt('success_title'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                  getTxt('success_body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () {
                    _findAndLoadTemuan();
                  },
                  child: Text(getTxt('continue_verification')),
                ),
              ),
              const SizedBox(height: 10),
              CountdownButton(
                onFinished: () {
                  if (mounted && _showSuccessDialog) {
                    _findAndLoadTemuan();
                  }
                },
                textPrefix: getTxt('auto_continue_prefix'),
                textSuffix: getTxt('auto_continue_suffix'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SwipeDirection { leftToRight, rightToLeft }

class _InteractiveSwipeButton extends StatefulWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onSwiped;
  final bool enabled;
  final SwipeDirection direction;

  const _InteractiveSwipeButton({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
    required this.onSwiped,
    required this.enabled,
    this.direction = SwipeDirection.leftToRight,
  });

  @override
  _InteractiveSwipeButtonState createState() => _InteractiveSwipeButtonState();
}

class _InteractiveSwipeButtonState extends State<_InteractiveSwipeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (!widget.enabled) return;

    final dragWidth = maxWidth - 60; // 60 is approx width of thumb
    final newPosition = _dragPosition +
        (widget.direction == SwipeDirection.leftToRight
            ? details.delta.dx
            : -details.delta.dx);

    setState(() {
      _dragPosition = newPosition.clamp(0.0, dragWidth);
    });
  }

  void _handleDragEnd(DragEndDetails details, double maxWidth) {
    if (!widget.enabled) return;

    final dragWidth = maxWidth - 60;
    final successThreshold = dragWidth * 0.8; // User must drag 80% of the way

    if (_dragPosition >= successThreshold) {
      widget.onSwiped();
      // Reset position for next time
      if (mounted) {
        setState(() {
          _dragPosition = 0.0;
        });
      }
    } else {
      // Animate back to start
      final snapAnimation =
          Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      );
      snapAnimation.addListener(() {
        if (mounted) {
          setState(() {
            _dragPosition = snapAnimation.value;
          });
        }
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final dragWidth = maxWidth - 60;
      final opacity = ((dragWidth - _dragPosition) / dragWidth).clamp(0.0, 1.0);

      final isRightToLeft = widget.direction == SwipeDirection.rightToLeft;

      return GestureDetector(
        onHorizontalDragUpdate: (details) =>
            _handleDragUpdate(details, maxWidth),
        onHorizontalDragEnd: (details) => _handleDragEnd(details, maxWidth),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: widget.enabled
                ? widget.color.withOpacity(0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: widget.enabled ? widget.color : Colors.grey.shade400),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --- PERUBAHAN DI SINI ---
              // Menambahkan Padding agar teks tidak tertimpa lingkaran
              Padding(
                padding: EdgeInsets.only(
                  left: isRightToLeft ? 0 : 45.0,  // Beri ruang di kiri untuk tombol "Geser Kanan"
                  right: isRightToLeft ? 45.0 : 0, // Beri ruang di kanan untuk tombol "Geser Kiri"
                ),
                child: Opacity(
                  opacity: widget.enabled ? opacity : 1.0,
                  child: Text(
                    widget.text,
                    style: TextStyle(
                        color: widget.enabled ? widget.color : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    overflow: TextOverflow.fade, // Mencegah teks terpotong kasar
                    softWrap: false,             // Mencegah teks turun baris
                  ),
                ),
              ),
              // --------------------------

              // Draggable Thumb
              Positioned(
                left: isRightToLeft ? null : 5 + _dragPosition,
                right: isRightToLeft ? 5 + _dragPosition : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.enabled ? widget.color : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class CountdownButton extends StatefulWidget {
  final VoidCallback onFinished;
  final String textPrefix;
  final String textSuffix;

  const CountdownButton({
    super.key,
    required this.onFinished,
    required this.textPrefix,
    required this.textSuffix,
  });

  @override
  _CountdownButtonState createState() => _CountdownButtonState();
}

class _CountdownButtonState extends State<CountdownButton> {
  int _countdown = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
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
    return TextButton(
      onPressed: () {
        _timer?.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => VerificatorHomeScreen()),
          (Route<dynamic> route) => false,
        );
      },
      child: Text('${widget.textPrefix} $_countdown ${widget.textSuffix}'),
    );
  }
}