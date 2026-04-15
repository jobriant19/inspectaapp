import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const primaryColor = Color(0xFF0EA5E9);
}
class LeaderboardMember {
  final int rank;
  final String name;
  final String? avatarUrl;
  final int score;

  LeaderboardMember({
    required this.rank,
    required this.name,
    this.avatarUrl,
    required this.score,
  });

  String get altitudeLabel => '${score * 10} ft';
}

class LeaderboardDetailScreen extends StatefulWidget {
  final String seasonTitle;
  final int year;
  final int month;
  final String lang;

  const LeaderboardDetailScreen({
    super.key,
    required this.seasonTitle,
    required this.year,
    required this.month,
    required this.lang,
  });

  @override
  State<LeaderboardDetailScreen> createState() => _LeaderboardDetailScreenState();
}

enum FilterType { monthly, daily }

class _LeaderboardDetailScreenState extends State<LeaderboardDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<List<LeaderboardMember>>? _leaderboardFuture;

  // State untuk filter
  int _selectedUnitId = 0;
  String _selectedUnitName = 'Semua Grup';
  List<Map<String, dynamic>> _unitList = [];
  FilterType _filterType = FilterType.monthly;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.year, widget.month, 1);
    _fetchUnits().then((_) {
      _fetchData();
    });
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) {
        setState(() {
          _unitList = List<Map<String, dynamic>>.from(response);
          // Tambahkan opsi "Semua Grup" di awal
          _unitList.insert(0, {'id_unit': 0, 'nama_unit': 'Semua Grup'});
        });
      }
    } catch (e) {
      debugPrint('Error fetching units: $e');
    }
  }

  void _fetchData() {
    setState(() {
      if (_filterType == FilterType.monthly) {
        _leaderboardFuture = _supabase.rpc('get_monthly_leaderboard', params: {
          'selected_month': _selectedDate.month,
          'selected_year': _selectedDate.year,
          'selected_unit_id': _selectedUnitId,
        }).then((response) {
          final List<dynamic> data = response;
          return data.map((item) => LeaderboardMember(
            rank: item['rank_num'] as int,
            name: item['nama'] as String,
            avatarUrl: item['gambar_user'] as String?,
            score: item['monthly_score'] as int,
          )).toList();
        });
      } else { // FilterType.daily
        _leaderboardFuture = _supabase.rpc('get_daily_leaderboard', params: {
          'selected_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'selected_unit_id': _selectedUnitId,
        }).then((response) {
            final List<dynamic> data = response;
            return data.map((item) => LeaderboardMember(
              rank: item['rank_num'] as int,
              name: item['nama'] as String,
              avatarUrl: item['gambar_user'] as String?,
              score: item['daily_score'] as int,
            )).toList();
        });
      }
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _fetchData();
      });
    }
  }

  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Pilih Grup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _unitList.length,
                  itemBuilder: (context, index) {
                    final unit = _unitList[index];
                    return ListTile(
                      title: Text(unit['nama_unit']),
                      onTap: () {
                        setState(() {
                          _selectedUnitId = unit['id_unit'];
                          _selectedUnitName = unit['nama_unit'];
                          _fetchData(); // Muat ulang data dengan filter baru
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Papan Peringkat Detail',
          style: const TextStyle(color: Color(0xFF0C4A6E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0C4A6E)),
      ),
      body: ListView(
        children: [
          _buildHeader(),
          _buildFilterTypeSelector(),
          _buildFilters(),
          _buildLeaderboardTable(),
        ],
      ),
    );
  }

  Widget _buildFilterTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: SegmentedButton<FilterType>(
        segments: const [
          ButtonSegment(value: FilterType.monthly, label: Text('Bulanan'), icon: Icon(Icons.calendar_month)),
          ButtonSegment(value: FilterType.daily, label: Text('Harian'), icon: Icon(Icons.calendar_today)),
        ],
        selected: {_filterType},
        onSelectionChanged: (newSelection) {
          setState(() {
            _filterType = newSelection.first;
            // Saat beralih, muat ulang data
            _fetchData();
          });
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.primaryColor.withOpacity(0.2),
          selectedForegroundColor: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Widget ini sama seperti sebelumnya, tidak perlu diubah.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Musim', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(
                widget.seasonTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0C4A6E)),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Selesai'),
          )
        ],
      ),
    );
  }

  Widget _buildFilters() {
    // Definisikan warna di sini agar mudah diakses jika belum ada di scope class
    const Color textPrimaryColor = Color(0xFF0C4A6E);
    const Color textSecondaryColor = Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          // Filter Grup (Selalu tampil)
          Expanded(
            // Mengatur proporsi lebar antara filter grup dan tanggal
            flex: _filterType == FilterType.daily ? 2 : 1,
            child: GestureDetector(
              onTap: _showGroupPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Expanded untuk memastikan teks tidak overflow jika terlalu panjang
                    Expanded(
                      child: Text(
                        _selectedUnitName,
                        style: const TextStyle(fontSize: 14, color: textPrimaryColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: textSecondaryColor),
                  ],
                ),
              ),
            ),
          ),
          
          // Bagian ini hanya akan dibangun dan tampil jika filter Harian dipilih
          if (_filterType == FilterType.daily) ...[
            const SizedBox(width: 8), // Spasi antar filter
            Expanded(
              flex: 3, // Beri lebih banyak ruang untuk filter tanggal
              child: GestureDetector(
                onTap: _pickDate, // Panggil fungsi untuk menampilkan date picker
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tampilkan tanggal yang dipilih dengan format yang mudah dibaca
                      Text(
                        DateFormat('d MMM yyyy', 'id_ID').format(_selectedDate),
                        style: const TextStyle(fontSize: 14, color: textPrimaryColor, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.calendar_today, color: textSecondaryColor, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboardTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header Tabel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: const [
                SizedBox(width: 40, child: Text('Rank', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
                Expanded(child: Text('Nama', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
                SizedBox(width: 80, child: Text('Ketinggian', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
                SizedBox(width: 60, child: Text('Poin', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const Divider(height: 1),
          // Isi Tabel dari Future
          FutureBuilder<List<LeaderboardMember>>(
            future: _leaderboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(32.0), child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(padding: EdgeInsets.all(32.0), child: Center(child: Text('Tidak ada data untuk filter ini.')));
              }

              final data = snapshot.data!;
              return Column(
                children: data.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text('${item.rank}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(
                        child: Row(
                          children: [
                            // Gunakan widget Avatar dari ranking_screen jika Anda mengekstraknya
                            CircleAvatar(
                                backgroundImage: (item.avatarUrl != null && item.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(item.avatarUrl!)
                                    : null,
                                child: (item.avatarUrl == null || item.avatarUrl!.isEmpty)
                                    ? Text(item.name[0])
                                    : null,
                                radius: 18),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                      SizedBox(width: 80, child: Text(item.altitudeLabel, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(width: 60, child: Text('${item.score}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}