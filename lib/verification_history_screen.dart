import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'finding_detail_screen.dart';

class VerificationHistoryScreen extends StatefulWidget {
  final String lang;
  const VerificationHistoryScreen({super.key, required this.lang});

  @override
  State<VerificationHistoryScreen> createState() =>
      _VerificationHistoryScreenState();
}

class _VerificationHistoryScreenState extends State<VerificationHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  // Kamus Terjemahan
  final Map<String, Map<String, String>> _text = {
    'EN': {
      'title': 'Verification History',
      'loading': 'Loading history...',
      'empty_title': 'No History Yet',
      'empty_subtitle': 'Your verification activities will appear here.',
      'your_vote': 'Your Vote',
      'final_result': 'Final Result',
      'match': 'Match',
      'mismatch': 'Mismatch',
      'verified': 'Verified',
      'not_verified': 'Not Verified',
      'pending': 'Pending', // Tambahkan terjemahan untuk Pending
    },
    'ID': {
      'title': 'Riwayat Verifikasi',
      'loading': 'Memuat riwayat...',
      'empty_title': 'Belum Ada Riwayat',
      'empty_subtitle': 'Aktivitas verifikasi Anda akan muncul di sini.',
      'your_vote': 'Pilihan Anda',
      'final_result': 'Hasil Akhir',
      'match': 'Sesuai',
      'mismatch': 'Tidak Sesuai',
      'verified': 'Terverifikasi',
      'not_verified': 'Tidak Terverifikasi',
      'pending': 'Menunggu', // Tambahkan terjemahan untuk Pending
    },
    'ZH': {
      'title': '验证历史',
      'loading': '加载历史记录...',
      'empty_title': '暂无历史记录',
      'empty_subtitle': '您的验证活动将显示在此处。',
      'your_vote': '您的投票',
      'final_result': '最终结果',
      'match': '匹配',
      'mismatch': '不匹配',
      'verified': '已验证',
      'not_verified': '未验证',
      'pending': '待定', // Tambahkan terjemahan untuk Pending
    },
  };

  String getTxt(String key) => _text[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // PERUBAHAN: Pastikan kolom 'hasil_verifikasi_mayoritas' diambil.
      // Dengan menyebutkannya secara eksplisit, kita menjamin kolom ini ada dalam response.
      final response = await Supabase.instance.client
          .from('verifikasi_log')
          .select('''
            jawaban_benar, 
            temuan:id_temuan (
              *,
              hasil_verifikasi_mayoritas, 
              lokasi(nama_lokasi), 
              unit(nama_unit), 
              subunit(nama_subunit), 
              area(nama_area)
            ) 
          ''')
          .eq('id_verificator', userId)
          .order('waktu_verifikasi', ascending: false);

      final List<Map<String, dynamic>> processedData = [];
      for (var item in response) {
        if (item['temuan'] != null) {
          Map<String, dynamic> temuanData =
              Map<String, dynamic>.from(item['temuan']);
          // Tambahkan vote user ('jawaban_benar' dari log) ke dalam data temuan
          temuanData['user_vote'] = item['jawaban_benar'];
          processedData.add(temuanData);
        }
      }
      return processedData;
    } catch (e) {
      debugPrint('Error fetching verification history: $e');
      throw Exception('Failed to load history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(getTxt('title'),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00C9E4)),
                const SizedBox(height: 16),
                Text(getTxt('loading')),
              ],
            ));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(getTxt('empty_title'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(getTxt('empty_subtitle'),
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final findings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: findings.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(findings[index]);
            },
          );
        },
      ),
    );
  }

  // --- KODE LOGIKA UTAMA ADA DI SINI ---
  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final String title = data['judul_temuan'] ?? 'Tanpa Judul';
    final String? imageUrl = data['gambar_temuan'];
    final String location = _formatLocation(data);
    final String date = _formatDate(data['created_at']);

    // 1. Ambil vote individu user (dari 'verifikasi_log')
    // Ini adalah jawaban Anda saat verifikasi (true atau false)
    final bool userVote = data['user_vote'];

    // 2. Ambil hasil akhir dari mayoritas (dari kolom 'temuan')
    // Ini bisa bernilai true, false, atau null jika voting belum selesai.
    final bool? finalOutcome = data['hasil_verifikasi_mayoritas'];

    // 3. Logika Penentuan Warna dan Teks Status
    Color borderColor;
    String statusText;
    IconData statusIcon;

    if (finalOutcome == null) {
      // KASUS 1: Voting belum selesai, hasil akhir belum ada.
      borderColor = Colors.grey.shade400;
      statusText = getTxt('pending'); // 'Menunggu' atau 'Pending'
      statusIcon = Icons.hourglass_empty;
    } else {
      // KASUS 2: Voting sudah punya hasil akhir.
      // Bandingkan jawaban Anda (userVote) dengan hasil akhir (finalOutcome).
      bool isVoteMatch = (userVote == finalOutcome);

      if (isVoteMatch) {
        // Jawaban Anda SAMA dengan hasil akhir.
        borderColor = Colors.green.shade600;
        statusText = getTxt('match'); // 'Sesuai'
        statusIcon = Icons.check_circle_outline;
      } else {
        // Jawaban Anda BERBEDA dengan hasil akhir.
        borderColor = Colors.red.shade600;
        statusText = getTxt('mismatch'); // 'Tidak Sesuai'
        statusIcon = Icons.highlight_off;
      }
    }

    final Color cardShadowColor = borderColor.withOpacity(0.3);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FindingDetailScreen(initialData: data, lang: widget.lang),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 10,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey),
                                )
                              : const Icon(Icons.image_not_supported,
                                  color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    height: 1.2)),
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(Icons.place_outlined,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700)),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 13, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(date,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 80,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: borderColor, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: borderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLocation(Map<String, dynamic> item) {
    if (item['area'] != null && item['area']['nama_area'] != null) {
      return item['area']['nama_area'].toString();
    }
    if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) {
      return item['subunit']['nama_subunit'].toString();
    }
    if (item['unit'] != null && item['unit']['nama_unit'] != null) {
      return item['unit']['nama_unit'].toString();
    }
    if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) {
      return item['lokasi']['nama_lokasi'].toString();
    }
    return '-';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final dt = DateTime.parse(value.toString());
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return '-';
    }
  }
}