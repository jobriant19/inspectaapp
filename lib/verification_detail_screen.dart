import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:inspectaapp/verificator_home_screen.dart';

// =======================================================
// KELAS UTAMA
// =======================================================

class VerificationDetailScreen extends StatefulWidget {
  // Tidak perlu temuanId lagi, screen ini akan mencari sendiri
  const VerificationDetailScreen({super.key});

  @override
  State<VerificationDetailScreen> createState() =>
      _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends State<VerificationDetailScreen>
    with TickerProviderStateMixin { // Tambahkan TickerProviderStateMixin di sini
  final SupabaseClient _client = Supabase.instance.client;

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
    // Memulai proses pencarian dan pemuatan temuan
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
            content: Text('Error memuat data: ${e.toString()}'),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Anda sudah pernah memverifikasi temuan ini.'),
              backgroundColor: Colors.orange));
          _findAndLoadTemuan();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error saat submit: ${e.toString()}'),
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
            const Text("Verifikasi Laporan",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text(
              'Periksa data temuan dan penyelesaian berikut. Apakah laporan ini valid dan sesuai?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageContainer("Temuan", temuan['gambar_temuan']),
                const SizedBox(width: 10),
                _buildImageContainer("Penyelesaian",
                    temuan['penyelesaian']?['gambar_penyelesaian']),
              ],
            ),
            const SizedBox(height: 15),
            _buildNoteCard("Catatan Temuan", temuan['deskripsi_temuan']),
            const SizedBox(height: 8),
            _buildNoteCard("Catatan Penyelesaian",
                temuan['penyelesaian']?['catatan_penyelesaian']),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.category_outlined,
                "Kategori: ${temuan['kategoritemuan']?['nama_kategoritemuan'] ?? 'N/A'}"),
            _buildInfoRow(Icons.location_on_outlined,
                "Lokasi: ${temuan['lokasi']?['nama_lokasi'] ?? 'N/A'} - ${temuan['area']?['nama_area'] ?? 'N/A'}"),
            const SizedBox(height: 20),

            // --- PERUBAHAN UTAMA DI SINI ---
            // Mengubah teks menjadi lebih pendek agar pas.
            _buildSwipeActionButton("GESER JIKA SESUAI", Colors.green,
                Icons.arrow_forward, () => _submitVerification(true)),
            const SizedBox(height: 10),
            _buildSwipeActionButton("GESER JIKA TIDAK", Colors.red, // Teks diperpendek
                Icons.arrow_back, () => _submitVerification(false)),
            // ------------------------------------

            const SizedBox(height: 15),
            Text(
              _secondsToAccess > 0
                  ? "Anda dapat menjawab dalam $_secondsToAccess detik"
                  : "SILAKAN GESER UNTUK MENJAWAB",
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
          const Text('Luar Biasa!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
              'Saat ini tidak ada laporan baru yang perlu diverifikasi. Terima kasih atas kerja keras Anda!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali ke Beranda'),
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
              const Text('Verifikasi Terkirim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                  'Terima kasih! Lanjut verifikasi laporan berikutnya?',
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
                  child: const Text('Lanjut Verifikasi Sekarang'),
                ),
              ),
              const SizedBox(height: 10),
              CountdownButton(
                onFinished: () {
                  if (mounted && _showSuccessDialog) {
                    _findAndLoadTemuan();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================
// SEMUA KELAS HELPER DI BAWAH SINI (DI LUAR KELAS STATE)
// =======================================================

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
  const CountdownButton({super.key, required this.onFinished});

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
              builder: (context) => const VerificatorHomeScreen()),
          (Route<dynamic> route) => false,
        );
      },
      child: Text('Otomatis lanjut dalam $_countdown detik (atau keluar)'),
    );
  }
}