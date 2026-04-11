import 'package:flutter/material.dart';
import './leaderboard_detail_screen.dart'; // Kita akan buat file ini selanjutnya

// --- Model Data Sederhana untuk Riwayat ---
class SeasonHistory {
  final String month;
  final String dateRange;
  final int participants;

  SeasonHistory({
    required this.month,
    required this.dateRange,
    required this.participants,
  });
}

// --- Dummy Data ---
final List<SeasonHistory> _historyData = [
  SeasonHistory(month: 'Maret', dateRange: '01 Mar 2026 - 31 Mar 2026', participants: 14),
  SeasonHistory(month: 'Februari', dateRange: '01 Feb 2026 - 28 Feb 2026', participants: 15),
  SeasonHistory(month: 'Januari', dateRange: '01 Jan 2026 - 31 Jan 2026', participants: 14),
  SeasonHistory(month: 'Desember', dateRange: '01 Des 2025 - 31 Des 2025', participants: 14),
  SeasonHistory(month: 'November', dateRange: '01 Nov 2025 - 30 Nov 2025', participants: 13),
  SeasonHistory(month: 'Oktober', dateRange: '01 Okt 2025 - 31 Okt 2025', participants: 15),
  // Tambahkan data lain jika perlu
];

class RiwayatMusimScreen extends StatelessWidget {
  final String lang;
  const RiwayatMusimScreen({super.key, required this.lang});

  String get _title {
    if (lang == 'ZH') return '赛季历史';
    if (lang == 'ID') return 'Riwayat Musim';
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
      body: ListView.separated(
        itemCount: _historyData.length,
        padding: const EdgeInsets.symmetric(vertical: 16),
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: Color(0xFFF1F5F9),
        ),
        itemBuilder: (context, index) {
          final item = _historyData[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              item.month,
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '${item.participants} Peserta', // Anda bisa menambahkan lokalisasi di sini
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
              // Navigasi ke detail leaderboard dengan membawa data musim
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaderboardDetailScreen(
                    seasonTitle: '${item.month} 2026', // Contoh
                    lang: lang,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}