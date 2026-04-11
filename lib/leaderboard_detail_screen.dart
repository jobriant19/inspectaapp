import 'package:flutter/material.dart';

// --- Warna yang Digunakan di Halaman Ini ---
const _primaryColor = Color(0xFF0EA5E9);
const _primaryDarkColor = Color(0xFF0369A1);
const _textPrimaryColor = Color(0xFF0C4A6E);
const _textSecondaryColor = Color(0xFF64748B);

class LeaderboardDetailScreen extends StatefulWidget {
  final String seasonTitle;
  final String lang;

  const LeaderboardDetailScreen({
    super.key,
    required this.seasonTitle,
    required this.lang,
  });

  @override
  State<LeaderboardDetailScreen> createState() => _LeaderboardDetailScreenState();
}

class _LeaderboardDetailScreenState extends State<LeaderboardDetailScreen> {
  String _selectedTab = 'Harian'; // Harian atau Bulanan
  String _selectedGroup = 'Semua Grup';
  DateTime _selectedDate = DateTime(2026, 3, 1);

  final List<String> _groupOptions = ['FIN', 'MA', 'MDC', 'Support', 'WF'];

  // --- Fungsi untuk menampilkan Group Picker ---
  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Grup Performa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ..._groupOptions.map((group) => ListTile(
                      title: Text(group, style: const TextStyle(color: _textPrimaryColor)),
                      onTap: () {
                        setState(() {
                          _selectedGroup = group;
                        });
                        Navigator.pop(context);
                      },
                    )),
                const Divider(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedGroup = 'Semua Grup';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Reset', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Fungsi untuk menampilkan Date Picker ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
      // Styling agar mirip dengan gambar
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textPrimaryColor,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Leaderboard The Mountain',
          style: const TextStyle(color: _textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: const IconThemeData(color: _textPrimaryColor),
      ),
      body: ListView(
        children: [
          _buildHeader(),
          _buildFilters(),
          _buildTabs(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Season',
                style: TextStyle(fontSize: 14, color: _textSecondaryColor),
              ),
              const SizedBox(height: 4),
              Text(
                widget.seasonTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimaryColor,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Selesai'),
            style: TextButton.styleFrom(
              foregroundColor: _textSecondaryColor,
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        children: [
          // Filter Grup
          GestureDetector(
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
                  Text(
                    _selectedGroup,
                    style: const TextStyle(fontSize: 14, color: _textPrimaryColor),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildTabItem('Harian', 'Peringkat #?'),
            _buildTabItem('Bulanan', 'Peringkat #?'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, String subtitle) {
    bool isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _primaryDarkColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : _textSecondaryColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Tampilkan konten berbeda berdasarkan tab yang dipilih
    if (_selectedTab == 'Harian') {
      return _buildDailyContent();
    } else {
      return _buildMonthlyContent();
    }
  }

  Widget _buildDailyContent() {
    return Column(
      children: [
        // Date Picker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimaryColor),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _textSecondaryColor),
                ],
              ),
            ),
          ),
        ),
        // Tabel Harian (Data Dummy)
        _buildDummyTable(isDaily: true),
      ],
    );
  }

  Widget _buildMonthlyContent() {
    return Column(
      children: [
         Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Anggota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textPrimaryColor)),
              Text('Pencapai The Cloud (?)', style: TextStyle(color: _textSecondaryColor, fontSize: 13)),
            ],
          ),
        ),
        // Tabel Bulanan (Data Dummy)
        _buildDummyTable(isDaily: false),
      ],
    );
  }
  
  // Helper untuk mendapatkan nama bulan
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
  
  // Tabel dummy untuk menampilkan data
  Widget _buildDummyTable({required bool isDaily}) {
    // Data ini hanya contoh, bisa diganti dengan data asli
    final data = isDaily 
      ? [
          {'rank': '🥇', 'name': 'Lusia Ika Hattary Kira...', 'val1': '≈ 200', 'val2': '22'},
          {'rank': '2', 'name': 'Yohanes Oscar Andri...', 'val1': '≈ 74', 'val2': '5'},
          {'rank': '3', 'name': 'Bintoro Setyo Harwi...', 'val1': '≈ 27', 'val2': '5'},
          {'rank': '4', 'name': 'Wisnu Wijayanto', 'val1': '≈ 20', 'val2': '5'},
        ]
      : [
          {'rank': '🥇', 'name': 'Angga Prasetyo Nugroho', 'val1': '2436'},
          {'rank': '2', 'name': 'Bintoro Setyo Hutomo', 'val1': '2147'},
          {'rank': '3', 'name': 'Agung Setyo Harwijayanto', 'val1': '2140'},
          {'rank': '4', 'name': 'Jakub Ari Darmawan', 'val1': '2049'},
          {'rank': '5', 'name': 'Lusia Ika Hattary Kirana', 'val1': '1724'},
        ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header Tabel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 40, child: Text('Rank', style: TextStyle(color: _textSecondaryColor, fontWeight: FontWeight.w600))),
                const Expanded(child: Text('Nama', style: TextStyle(color: _textSecondaryColor, fontWeight: FontWeight.w600))),
                SizedBox(width: 80, child: Icon(isDaily ? Icons.sync_alt : Icons.cloud_outlined, color: _textSecondaryColor, size: 20)),
                if (isDaily)
                  const SizedBox(width: 40, child: Icon(Icons.trending_up, color: _textSecondaryColor, size: 20)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Isi Tabel
          ...data.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
            child: Row(
              children: [
                // PERBAIKAN DI SINI
                SizedBox(width: 40, child: Text(item['rank']!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                // Avatar + Nama
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(child: Text(item['name']![0]), radius: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item['name']!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
                // PERBAIKAN DI SINI
                SizedBox(width: 80, child: Text(item['val1']!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                if (isDaily)
                  // PERBAIKAN DI SINI
                  SizedBox(width: 40, child: Text(item['val2']!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}