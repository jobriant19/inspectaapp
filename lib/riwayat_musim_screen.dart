import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './leaderboard_detail_screen.dart';

// Model Data dinamis
class SeasonHistory {
  final int year;
  final int month;
  final int participants;

  SeasonHistory({
    required this.year,
    required this.month,
    required this.participants,
  });

  // Helper untuk mendapatkan nama bulan
  String get monthName {
    // Buat objek DateTime untuk bulan tersebut
    final date = DateTime(year, month);
    // Format menggunakan intl
    return DateFormat.MMMM('id_ID').format(date);
  }

  // Helper untuk rentang tanggal
  String get dateRange {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return '${formatter.format(firstDay)} - ${formatter.format(lastDay)}';
  }
}

class RiwayatMusimScreen extends StatefulWidget {
  final String lang;
  const RiwayatMusimScreen({super.key, required this.lang});

  @override
  State<RiwayatMusimScreen> createState() => _RiwayatMusimScreenState();
}

class _RiwayatMusimScreenState extends State<RiwayatMusimScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<List<SeasonHistory>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<SeasonHistory>> _fetchHistory() async {
    try {
      final response = await _supabase.rpc('get_season_history');
      final List<dynamic> data = response;
      return data.map((item) => SeasonHistory(
        year: item['season_year'] as int,
        month: item['season_month'] as int,
        participants: (item['participant_count'] as int?) ?? 0,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching season history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat riwayat: $e'), backgroundColor: Colors.red),
      );
      return [];
    }
  }

  String get _title {
    if (widget.lang == 'ZH') return '赛季历史';
    if (widget.lang == 'ID') return 'Riwayat Musim';
    return 'Season History';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Color(0xFF0C4A6E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: const IconThemeData(color: Color(0xFF0C4A6E)),
      ),
      body: FutureBuilder<List<SeasonHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada riwayat musim ditemukan.'));
          }

          final historyList = snapshot.data!;
          return ListView.separated(
            itemCount: historyList.length,
            padding: const EdgeInsets.symmetric(vertical: 16),
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final item = historyList[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  '${item.monthName} ${item.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0C4A6E),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      item.dateRange,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          '${item.participants} Peserta',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaderboardDetailScreen(
                        // Kirim data bulan dan tahun ke halaman detail
                        seasonTitle: '${item.monthName} ${item.year}',
                        year: item.year,
                        month: item.month,
                        lang: widget.lang,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}