import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ─── Warna & Tema ──────────────────────────────────────────────────────────
class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight = Color(0xFFE0F2FE);
  static const accent = Color(0xFF38BDF8);
  static const surface = Color(0xFFF0F9FF);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
  static const selfHighlight = Color(0xFFFFF7ED);
  static const selfHighlightBorder = Color(0xFFFED7AA);
  static const chipSelected = Color(0xFF0369A1);
  static const chipUnselected = Colors.white;
  static const targetBlue = Color(0xFF0EA5E9);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

// ─── Model Data ──────────────────────────────────────────────────────────────
class MemberData {
  final String name;
  final String? unitName; // BARU: Tambahkan ini
  final int findings;
  final int completed;
  final bool isSelf;
  final String? avatarUrl;
  final Color? avatarColor;

  const MemberData({
    required this.name,
    this.unitName, // BARU: Tambahkan di constructor
    required this.findings,
    required this.completed,
    this.isSelf = false,
    this.avatarUrl,
    this.avatarColor,
  });
}

class InspectionData {
  final String name;
  final int findings;
  final bool isSelf;

  const InspectionData({
    required this.name,
    required this.findings,
    this.isSelf = false,
  });
}

class LocationData {
  final String name;
  final String pic;
  final String? value;

  const LocationData({
    required this.name,
    required this.pic,
    this.value,
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  final String lang;
  const AnalyticsScreen({super.key, required this.lang});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'anggota': 'Anggota',
      'inspeksi': 'Inspeksi',
      'lokasi': 'Lokasi',
      'temuan_berulang': 'Temuan Berulang',
      'memuat_data': 'Memuat data...',
      'diperbarui_pada': 'Terakhir diperbarui pada',
      'semua_grup': 'Semua Grup',
      'gagal_muat_anggota': 'Gagal memuat data Anggota',
      'gagal_muat_inspeksi': 'Gagal memuat data Inspeksi',
      'gagal_muat_lokasi': 'Gagal memuat data Lokasi',
      'tidak_ada_data_anggota': 'Tidak ada data anggota.',
      'tidak_ada_temuan_role': 'Tidak ada temuan untuk role',
      'tidak_ada_data_level': 'Tidak ada data untuk level',
      'nama': 'Nama',
      'temuan': 'Temuan',
      'selesai': 'Selesai',
      'target_bulanan': 'Target Bulanan',
      'saya': 'Saya',
      'rank': 'Rank',
      'periode_audit': 'Periode audit: ',
      'topik': 'Topik',
      'belum_memiliki_temuan': 'belum\nmemiliki temuan berulang',
      'eksekutif': 'Eksekutif',
      'profesional': 'Profesional',
      'visitor': 'Visitor',
      'level_lokasi': 'Lokasi',
      'level_unit': 'Unit',
      'level_subunit': 'Subunit',
      'level_area': 'Area',
    },
    'EN': {
      'anggota': 'Members',
      'inspeksi': 'Inspection',
      'lokasi': 'Location',
      'temuan_berulang': 'Recurring Findings',
      'memuat_data': 'Loading data...',
      'diperbarui_pada': 'Last updated at',
      'semua_grup': 'All Groups',
      'gagal_muat_anggota': 'Failed to load Member data',
      'gagal_muat_inspeksi': 'Failed to load Inspection data',
      'gagal_muat_lokasi': 'Failed to load Location data',
      'tidak_ada_data_anggota': 'No member data available.',
      'tidak_ada_temuan_role': 'No findings for role',
      'tidak_ada_data_level': 'No data for level',
      'nama': 'Name',
      'temuan': 'Findings',
      'selesai': 'Completed',
      'target_bulanan': 'Monthly Target',
      'saya': 'Me',
      'rank': 'Rank',
      'periode_audit': 'Audit period: ',
      'topik': 'Topic',
      'belum_memiliki_temuan': 'does not have\nrecurring findings yet',
      'eksekutif': 'Executive',
      'profesional': 'Professional',
      'visitor': 'Visitor',
      'level_lokasi': 'Location',
      'level_unit': 'Unit',
      'level_subunit': 'Sub-unit',
      'level_area': 'Area',
    },
    'ZH': {
      'anggota': '成员',
      'inspeksi': '检查',
      'lokasi': '位置',
      'temuan_berulang': '重复发现',
      'memuat_data': '加载数据...',
      'diperbarui_pada': '最后更新于',
      'semua_grup': '所有组',
      'gagal_muat_anggota': '加载成员数据失败',
      'gagal_muat_inspeksi': '加载检查数据失败',
      'gagal_muat_lokasi': '加载位置数据失败',
      'tidak_ada_data_anggota': '没有成员数据。',
      'tidak_ada_temuan_role': '没有角色的发现',
      'tidak_ada_data_level': '没有级别的数据',
      'nama': '名称',
      'temuan': '发现',
      'selesai': '已完成',
      'target_bulanan': '每月目标',
      'saya': '我',
      'rank': '排名',
      'periode_audit': '审计期间: ',
      'topik': '话题',
      'belum_memiliki_temuan': '还没有\n重复的发现',
      'eksekutif': '行政',
      'profesional': '专业',
      'visitor': '访客',
      'level_lokasi': '位置',
      'level_unit': '单元',
      'level_subunit': '子单元',
      'level_area': '区域',
    },
  };

  // BARU: Tambahkan fungsi helper getTxt
  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // ─── State untuk Filter ──────────────────────────────────────────────────
  String _selectedMonth = 'Apr';
  int _selectedUnitId = 0;
  String _selectedInspectionRole = 'Eksekutif';
  String _selectedLocationLevel = 'Lokasi';
  DateTime? _lastUpdated;

  // ─── State untuk Data ────────────────────────────────────────────────────
  Future<List<MemberData>>? _anggotaFuture;
  Future<List<InspectionData>>? _inspeksiFuture;
  Future<List<LocationData>>? _lokasiFuture;
  List<Map<String, dynamic>> _unitList = [];

  late List<String> _translatedMonths;
  late List<String> _translatedRoles;
  late List<String> _translatedLocationLevels;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchUnits().then((_) {
      // Setelah daftar unit didapat, baru ambil data lainnya
      _fetchAllData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initLocaleDependentLists();
  }

  void _initLocaleDependentLists() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');

    // Inisialisasi daftar bulan
    _translatedMonths = List.generate(12, (i) {
      return DateFormat.MMM(locale).format(DateTime(2000, i + 1));
    });
    // Set bulan terpilih ke bulan saat ini jika belum di-set
    if (!_translatedMonths.contains(_selectedMonth)) {
      _selectedMonth = DateFormat.MMM(locale).format(DateTime.now());
    }

    // Inisialisasi daftar role
    final rolesBackend = ['Eksekutif', 'Profesional', 'Visitor'];
    _translatedRoles = [
      getTxt('eksekutif'),
      getTxt('profesional'),
      getTxt('visitor'),
    ];
    // Cocokkan _selectedInspectionRole dengan versi terjemahan
    final selectedRoleIndex = rolesBackend.indexOf(_selectedInspectionRole);
    if(selectedRoleIndex != -1) {
      _selectedInspectionRole = _translatedRoles[selectedRoleIndex];
    }

    // Inisialisasi daftar level lokasi
    final locationLevelsBackend = ['Lokasi', 'Unit', 'Subunit', 'Area'];
    _translatedLocationLevels = [
      getTxt('level_lokasi'),
      getTxt('level_unit'),
      getTxt('level_subunit'),
      getTxt('level_area'),
    ];
    // Cocokkan _selectedLocationLevel dengan versi terjemahan
    final selectedLevelIndex = locationLevelsBackend.indexOf(_selectedLocationLevel);
    if(selectedLevelIndex != -1) {
      _selectedLocationLevel = _translatedLocationLevels[selectedLevelIndex];
    }
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await _supabase.from('unit').select('id_unit, nama_unit');
      if (mounted) {
        setState(() {
          _unitList = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching units: $e');
      // Handle error
    }
  }

  // Helper untuk mengubah nama bulan menjadi angka
  int _monthNameToNumber(String monthName) {
    return _translatedMonths.indexOf(monthName) + 1;
  }

  void _fetchAllData() {
    final roleBackendValue = ['Eksekutif', 'Profesional', 'Visitor'][_translatedRoles.indexOf(_selectedInspectionRole)];
    final levelBackendValue = ['Lokasi', 'Unit', 'Subunit', 'Area'][_translatedLocationLevels.indexOf(_selectedLocationLevel)];

    setState(() {
      _lastUpdated = DateTime.now();
      final month = _monthNameToNumber(_selectedMonth);
      final year = DateTime.now().year;

      _anggotaFuture = _fetchAnggotaData(month, year, _selectedUnitId);
      _inspeksiFuture = _fetchInspeksiData(month, year, roleBackendValue);
      _lokasiFuture = _fetchLokasiData(month, year, levelBackendValue);
    });
  }

  // ─── Fungsi Pengambilan Data dari Supabase (RPC) ─────────────────────────
  Future<List<MemberData>> _fetchAnggotaData(int month, int year, int unitId) async { // Tambahkan 'year'
    try {
      final List<dynamic> response = await _supabase.rpc('get_anggota_stats',
          params: {
            'selected_month': month,
            'selected_year': year, // BARU: Kirim parameter tahun
            'selected_unit_id': unitId
          });

      return response.map((item) => MemberData(
        name: item['nama'] as String,
        unitName: item['unit_nama'] as String?,
        findings: item['temuan'] as int,
        completed: item['selesai'] as int,
        isSelf: item['user_id'] == _supabase.auth.currentUser?.id,
        avatarUrl: item['avatar_url'] as String?,
        avatarColor: const Color(0xFF0EA5E9),
      )).toList();

    } catch (e) {
      debugPrint('Error fetching Anggota: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${getTxt('gagal_muat_anggota')}: $e'), backgroundColor: Colors.red));
      return [];
    }
  }

  Future<List<InspectionData>> _fetchInspeksiData(int month, int year, String role) async { // Tambahkan 'year'
     try {
       final List<dynamic> response = await _supabase.rpc('get_inspeksi_stats',
          params: {
            'selected_month': month,
            'selected_year': year, // Kirim 'year'
            'role_type': role.toLowerCase(),
          });

      return response.map((item) => InspectionData(
        name: item['nama'] as String,
        findings: item['temuan'] as int,
      )).toList();

    } catch (e) {
      debugPrint('Error fetching Inspeksi: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${getTxt('gagal_muat_inspeksi')}: $e'), backgroundColor: Colors.red));
      return [];
    }
  }

  Future<List<LocationData>> _fetchLokasiData(int month, int year, String level) async { 
      try {
        final List<dynamic> response = await _supabase.rpc('get_lokasi_stats',
          params: {
            'selected_month': month,
            'selected_year': year, // Kirim 'year'
            'level_name': level.toLowerCase(),
          });

      return response.map((item) => LocationData(
        name: item['nama_item'] as String,
        pic: item['nama_pic'] as String,
        value: (item['nilai_temuan'] as int).toString(),
      )).toList();

    } catch (e) {
      debugPrint('Error fetching Lokasi: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${getTxt('gagal_muat_lokasi')}: $e'), backgroundColor: Colors.red));
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _lastUpdatedText {
    if (_lastUpdated == null) {
      return getTxt('memuat_data'); 
    }
    final formattedDate = DateFormat('d MMM yyyy HH:mm', widget.lang == 'ID' ? 'id_ID' : 'en_US').format(_lastUpdated!);
    return '${getTxt('diperbarui_pada')} $formattedDate (GMT+7)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.surface,
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnggotaTab(),
                _buildInspeksiTab(),
                _buildLokasiTab(),
                _buildTemuanBerulangTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = [
      getTxt('anggota'), 
      getTxt('inspeksi'), 
      getTxt('lokasi'), 
      getTxt('temuan_berulang')
    ];
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        indicator: BoxDecoration(
          color: _AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: _AppColors.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13.5),
        dividerColor: Colors.transparent,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ── Filter Row ─────────────────────────────────────────────────────────────
  Widget _buildMonthDropdown() {
    return _StyledDropdown(
      value: _selectedMonth,
      items: _translatedMonths,
      onChanged: (v) {
        if (v != null) {
          setState(() => _selectedMonth = v);
          _fetchAllData();
        }
      },
      isDark: false,
      width: 100,
    );
  }

  Widget _buildGroupDropdown() {
    // Buat item dropdown secara dinamis dari _unitList
    List<DropdownMenuItem<int>> dropdownItems = [
      DropdownMenuItem(value: 0, child: Text(getTxt('semua_grup'))),
    ];

    dropdownItems.addAll(_unitList.map((unit) {
      return DropdownMenuItem(
        value: unit['id_unit'] as int,
        child: Text(unit['nama_unit'] as String),
      );
    }));

    return DropdownButtonHideUnderline(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _AppColors.divider, width: 1.0),
        ),
        child: DropdownButton<int>(
          value: _selectedUnitId,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _AppColors.textSecondary, size: 20),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: dropdownItems,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedUnitId = value);
              _fetchAllData(); // Ambil data baru saat grup berubah
            }
          },
        ),
      ),
    );
  }

  Widget _buildLastUpdatedTextWidget() { // Renamed to avoid conflict
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        _lastUpdatedText,
        style: const TextStyle(
          fontSize: 11,
          color: _AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  // ── Anggota Tab ────────────────────────────────────────────────────────────
  Widget _buildAnggotaTab() {
    return Column(
      children: [
        _buildFilterRow(
          left: _buildMonthDropdown(),
          right: _buildGroupDropdown(),
        ),
        _buildLastUpdatedTextWidget(),
        Expanded(
          child: FutureBuilder<List<MemberData>>(
            future: _anggotaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(getTxt('tidak_ada_data_anggota')));
              }

              final memberList = snapshot.data!;
              final self = memberList.firstWhere(
                (m) => m.isSelf,
                orElse: () => MemberData(name: getTxt('saya'), findings: 0, completed: 0, isSelf: true),
              );

              return Column(
                children: [
                  _buildTableHeader([getTxt('nama'), getTxt('temuan'), getTxt('selesai')], flex: [3, 1, 1]),
                  _buildTargetRow([getTxt('target_bulanan'), '30', '30']),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: memberList.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1, color: _AppColors.divider, indent: 16,
                      ),
                      itemBuilder: (_, i) => _buildMemberRow(memberList[i]),
                    ),
                  ),
                  _buildSelfPinnedRow(self),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterRow({required Widget left, required Widget? right}) {
     return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          left,
          if (right != null) ...[
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberTable(List<MemberData> memberList) {
    // ...
    // Logika ini dipindahkan ke dalam FutureBuilder
    // ...
    return Container(); // Placeholder
  }

  Widget _buildTableHeader(List<String> cols, {required List<int> flex}) {
    return Container(
      color: const Color(0xFFF8FAFF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(cols.length, (i) {
          return Expanded(
            flex: flex[i],
            child: Text(
              cols[i],
              textAlign: i == 0 ? TextAlign.left : TextAlign.center,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _AppColors.textSecondary, letterSpacing: 0.2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTargetRow(List<String> vals) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        border: Border(bottom: BorderSide(color: _AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(vals[0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primary)),
          ),
          ...vals.sublist(1).map((v) => Expanded(
            flex: 1,
            child: Text(v, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primary)),
          )),
        ],
      ),
    );
  }

  Widget _buildMemberRow(MemberData m) {
    return Container(
      color: m.isSelf ? _AppColors.selfHighlight : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _Avatar(name: m.name, avatarUrl: m.avatarUrl, color: m.avatarColor, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  // BARU: Gunakan Column untuk Nama dan Unit
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (m.unitName != null && m.unitName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          m.unitName!,
                          style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${m.findings}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: m.findings > 0 ? _AppColors.primaryDark : _AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${m.completed}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: m.completed > 0 ? _AppColors.success : _AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfPinnedRow(MemberData self) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.selfHighlight,
        border: Border(top: BorderSide(color: _AppColors.selfHighlightBorder, width: 1.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // BARU: Kirim avatarUrl ke widget _Avatar
          _Avatar(name: self.name, avatarUrl: self.avatarUrl, color: self.avatarColor, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Text(self.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary)),
          ),
          SizedBox(width: 60, child: Text('${self.findings}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _AppColors.textSecondary))),
          SizedBox(width: 60, child: Text('${self.completed}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _AppColors.textSecondary))),
        ],
      ),
    );
  }

  // ── Inspeksi Tab ───────────────────────────────────────────────────────────
  Widget _buildInspeksiTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _buildMonthDropdown(),
              const SizedBox(width: 10),
              ..._translatedRoles.map((r) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _RoleChip(
                  label: r,
                  selected: _selectedInspectionRole == r,
                  onTap: () {
                    setState(() => _selectedInspectionRole = r);
                    _fetchAllData(); // Ambil data baru
                  },
                ),
              )),
            ],
          ),
        ),
        _buildLastUpdatedTextWidget(),
        _buildTableHeader([getTxt('nama'), getTxt('temuan')], flex: [3, 1]),
        _buildTargetRow([getTxt('target_bulanan'), '2']),
        Expanded(
          child: FutureBuilder<List<InspectionData>>(
            future: _inspeksiFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('${getTxt('tidak_ada_temuan_role')} "$_selectedInspectionRole".'));
              }
              final inspectionList = snapshot.data!;
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: inspectionList.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
                itemBuilder: (_, i) => _buildInspectionRow(inspectionList[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInspectionRow(InspectionData item) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _Avatar(name: item.name, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _AppColors.textPrimary)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${item.findings}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: item.findings > 0 ? _AppColors.primaryDark : _AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }


  // ── Lokasi Tab ─────────────────────────────────────────────────────────────
  Widget _buildLokasiTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _buildMonthDropdown(),
              const SizedBox(width: 10),
              Expanded(
                // PERUBAHAN DI SINI: Dropdown untuk level lokasi
                child: _StyledDropdown(
                  value: _selectedLocationLevel,
                  items: _translatedLocationLevels,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedLocationLevel = v);
                      _fetchAllData(); // Ambil data baru
                    }
                  },
                  isDark: false,
                ),
              ),
            ],
          ),
        ),
        _buildAuditPeriodBanner(),
        _buildLastUpdatedTextWidget(),
        _buildTableHeader([getTxt('rank'), getTxt('lokasi'), getTxt('temuan')], flex: [1, 3, 1]),
        Expanded(
          child: FutureBuilder<List<LocationData>>(
            future: _lokasiFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('${getTxt('tidak_ada_data_level')} "$_selectedLocationLevel".'));
              }
              final locationList = snapshot.data!;
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: locationList.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: _AppColors.divider, indent: 16),
                itemBuilder: (_, i) => _buildLocationRow(i + 1, locationList[i]), // Kirim rank
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAuditPeriodBanner() {
     // ... (tidak ada perubahan, salin dari kode asli)
     return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 15, color: _AppColors.primary),
          const SizedBox(width: 8),
          Text(getTxt('periode_audit'), style: TextStyle(fontSize: 13, color: _AppColors.textSecondary)),
          const Text('13 Apr - 19 Apr 2026', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.primaryDark)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(int rank, LocationData loc) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('$rank', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: _AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.location_city_rounded, color: _AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // BARU: Tampilkan nama PIC
                      Text(
                        loc.pic,
                        style: const TextStyle(fontSize: 11.5, color: _AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              loc.value ?? '0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: (int.tryParse(loc.value ?? '0') ?? 0) > 0 ? _AppColors.primaryDark : _AppColors.textMuted
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Temuan Berulang Tab ────────────────────────────────────────────────────
  Widget _buildTemuanBerulangTab() {
    // ... (tidak ada perubahan, salin dari kode asli)
     return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(child: _OutlinedBox(child: Text('Okt 2025 - Mar 2026', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _AppColors.textPrimary)))),
              const SizedBox(width: 10),
              Expanded(child: _StyledDropdown(value: 'Adi Widya Wasana', items: const ['Adi Widya Wasana', 'Anggota Lain'], onChanged: (_) {}, isDark: false)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(alignment: Alignment.centerLeft, child: Text(getTxt('topik'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.textPrimary))),
        ),
        const Divider(height: 1, color: _AppColors.divider),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: _AppColors.primaryLight, shape: BoxShape.circle),
                  child: Icon(Icons.search_off_rounded, size: 36, color: _AppColors.primary.withOpacity(0.5)),
                ),
                const SizedBox(height: 16),
                Text('Adi Widya Wasana ${getTxt('belum_memiliki_temuan')}', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatarUrl; // BARU: Tambahkan properti untuk URL gambar

  const _Avatar({
    required this.name,
    this.color,
    this.size = 36,
    this.avatarUrl, // BARU: Tambahkan ke constructor
  });

  @override
  Widget build(BuildContext context) {
    // BARU: Logika untuk menampilkan gambar jika URL ada
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        // Tambahkan error builder untuk fallback jika gambar gagal dimuat
        onBackgroundImageError: (_, __) {},
        // Tampilkan inisial di dalam jika gambar gagal
        child: (avatarUrl == null || avatarUrl!.isEmpty) ? _buildInitials() : null,
      );
    }

    // Fallback: Tampilkan inisial jika tidak ada URL gambar
    return _buildInitialsContainer();
  }

  // Helper untuk membuat widget inisial
  Widget _buildInitials() {
    final initials = name.trim().split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final bg = color ?? _AppColors.primary;

     return Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: bg,
        ),
      );
  }

  // Helper untuk membuat container inisial (logika lama Anda)
  Widget _buildInitialsContainer() {
    final bg = color ?? _AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: _buildInitials(),
      ),
    );
  }
}

// ── PERUBAHAN UTAMA: _StyledDropdown ─────────────────────────────────────────
// isDark tidak lagi mengubah background menjadi gelap.
// Semua mode kini menggunakan background putih.
// Perbedaan isDark hanya pada warna teks & ikon:
//   isDark=true  → teks & ikon biru cerah (primary) + border biru cerah
//   isDark=false → teks & ikon textPrimary + border divider (perilaku lama)
class _StyledDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isDark;
  final double? width;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.isDark = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Background selalu putih
    const bg = Colors.white;
    // Warna teks: biru cerah jika isDark, hitam primer jika tidak
    final textColor = isDark ? _AppColors.primary : _AppColors.textPrimary;
    // Warna ikon: biru cerah jika isDark, abu jika tidak
    final iconColor = isDark ? _AppColors.primary : _AppColors.textSecondary;
    // Border: biru cerah jika isDark, divider abu jika tidak
    final borderColor = isDark ? _AppColors.primary : _AppColors.divider;

    Widget dropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isDark ? 1.5 : 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: iconColor, size: 20),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: TextStyle(color: _AppColors.textPrimary, fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: dropdown);
    }
    return dropdown;
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _AppColors.primary : _AppColors.divider,
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _AppColors.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OutlinedBox extends StatelessWidget {
  final Widget child;

  const _OutlinedBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _AppColors.divider),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}