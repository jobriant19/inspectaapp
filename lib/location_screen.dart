import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final String userRole;
  final int? userUnitId;
  final int? userLokasiId;

  const LocationScreen({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.userRole,
    this.userUnitId,
    this.userLokasiId,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  int _currentLevel = 0;
  bool _isLoading = true;
  List<dynamic> _currentData = [];
  List<dynamic> _filteredData = [];
  String _searchQuery = "";
  bool _isLokasiSaya = false;

  List<Map<String, dynamic>> _navHistory = [];
  Map<String, dynamic>? _currentParentData;

  bool get _hasFullAccess => widget.isProMode || widget.userRole == 'Eksekutif';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({int? parentId, Map<String, dynamic>? parentData}) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];

      if (_currentLevel == 0) {
        var query = supabase.from('lokasi').select('id_lokasi, nama_lokasi, gambar_lokasi, deskripsi_lokasi, kategori, is_star, id_pic, User!id_pic(nama), unit(id_unit)');
        
        if (_isLokasiSaya && widget.userLokasiId != null) {
          query = query.eq('id_lokasi', widget.userLokasiId!);
        }
        data = await query;
      } 
      else if (_currentLevel == 1) {
        if (_isLokasiSaya || !_hasFullAccess) {
          if (widget.userUnitId != null) {
            data = await supabase.from('unit').select('id_unit, nama_unit, gambar_unit, deskripsi_unit, kategori, is_star, id_pic, User!id_pic(nama), subunit(id_subunit)').eq('id_lokasi', parentId!).eq('id_unit', widget.userUnitId!);
          } else {
            data = [];
          }
        } else {
          data = await supabase.from('unit').select('id_unit, nama_unit, gambar_unit, deskripsi_unit, kategori, is_star, id_pic, User!id_pic(nama), subunit(id_subunit)').eq('id_lokasi', parentId!);
        }
      } 
      else if (_currentLevel == 2) {
        data = await supabase.from('subunit').select('id_subunit, nama_subunit, gambar_subunit, deskripsi_subunit, kategori, is_star, id_pic, User!id_pic(nama), area(id_area)').eq('id_unit', parentId!);
      } 
      else if (_currentLevel == 3) {
        data = await supabase.from('area').select('id_area, nama_area, gambar_area, deskripsi_area, kategori, is_star, id_pic, User!id_pic(nama)').eq('id_subunit', parentId!);
      }

      if (mounted) {
        setState(() {
          _currentData = data;
          _currentParentData = parentData;
          _onSearch(_searchQuery);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Load Location: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    _searchQuery = query.toLowerCase();
    setState(() {
      _filteredData = _currentData.where((item) {
        String name = item['nama_${_getLevelName()}'].toString().toLowerCase();
        return name.contains(_searchQuery);
      }).toList();

      _filteredData.sort((a, b) {
        int starA = a['is_star'] ?? 0;
        int starB = b['is_star'] ?? 0;
        if (starA == 1 && starB == 0) return -1;
        if (starA == 0 && starB == 1) return 1;
        String nameA = a['nama_${_getLevelName()}'].toString().toLowerCase();
        String nameB = b['nama_${_getLevelName()}'].toString().toLowerCase();
        return nameA.compareTo(nameB);
      });
    });
  }

  String _getLevelName([int? level]) {
    int lvl = level ?? _currentLevel;
    return ['lokasi', 'unit', 'subunit', 'area'][lvl];
  }

  void _goBack() {
    if (_navHistory.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _navHistory.removeLast();
      _currentLevel--;
      _searchQuery = "";
    });
    if (_navHistory.isEmpty) {
      _fetchData();
    } else {
      final prev = _navHistory.last;
      _fetchData(parentId: prev['id'], parentData: prev['data']);
    }
  }

  Future<void> _toggleStar(Map<String, dynamic> item) async {
    final String tName = _getLevelName();
    final String idCol = 'id_$tName';
    final int id = item[idCol];
    final int newStar = (item['is_star'] ?? 0) == 1 ? 0 : 1;

    setState(() {
      item['is_star'] = newStar;
      _onSearch(_searchQuery);
    });
    await Supabase.instance.client.from(tName).update({'is_star': newStar}).eq(idCol, id);
  }

  void _showDetailModal() {
    if (_currentParentData == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (ctx) => _DetailBottomSheet(
        level: _currentLevel - 1,
        data: _currentParentData!,
        lang: widget.lang,
      ),
    );
  }

  void _showDetailModalForItem(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (ctx) => _DetailBottomSheet(
        level: _currentLevel,
        data: item,
        lang: widget.lang,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- KAMUS BAHASA ---
    final Map<String, Map<String, String>> texts = {
      'EN': {
        'cari': 'Search',
        'lokasi_saya': 'My Location',
        'sublokasi': 'Sub-locations',
        'detail': 'View Detail',
        'kategori': 'Category',
        'tanpa_kategori': 'No Category',
        'pic_kosong': 'No PIC',
      },
      'ID': {
        'cari': 'Cari',
        'lokasi_saya': 'Lokasi saya',
        'sublokasi': 'Sublokasi',
        'detail': 'Lihat Detail',
        'kategori': 'Kategori',
        'tanpa_kategori': 'Tanpa Kategori',
        'pic_kosong': 'Belum ada PIC',
      },
      'ZH': {
        'cari': '搜索',
        'lokasi_saya': '我的位置',
        'sublokasi': '子位置',
        'detail': '查看详情',
        'kategori': '类别',
        'tanpa_kategori': '无类别',
        'pic_kosong': '没有负责人',
      }
    };
    String getTxt(String key) => texts[widget.lang]?[key] ?? key;

    String title = _navHistory.isEmpty ? (_getLevelName().toUpperCase()) : _navHistory.last['name'];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E3A8A), size: 20),
          onPressed: _goBack,
        ),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Bagian Search & Lokasi Saya
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6F8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: _onSearch,
                              decoration: InputDecoration(
                                hintText: "${getTxt('cari')} ${_getLevelName()}",
                                border: InputBorder.none,
                                isDense: true,
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() => _isLokasiSaya = !_isLokasiSaya);
                    _fetchData(
                      parentId: _navHistory.isNotEmpty ? _navHistory.last['id'] : null,
                      parentData: _currentParentData,
                    );
                  },
                  child: SizedBox(
                    height: 42,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: _isLokasiSaya ? const Color(0xFF1E3A8A) : Colors.white,
                        border: Border.all(color: const Color(0xFF1E3A8A)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        getTxt('lokasi_saya'),
                        style: TextStyle(
                          color: _isLokasiSaya ? Colors.white : const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          // Header Card 
          if (_currentLevel > 0 && _currentParentData != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF8FA2AD), 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // KIRI: Gambar Persegi
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                        image: _currentParentData!['gambar_${_getLevelName(_currentLevel - 1)}'] != null
                            ? DecorationImage(
                                image: NetworkImage(_currentParentData!['gambar_${_getLevelName(_currentLevel - 1)}']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _currentParentData!['gambar_${_getLevelName(_currentLevel - 1)}'] == null
                          ? const Center(child: Icon(Icons.domain, color: Colors.white, size: 35))
                          : null,
                    ),
                    const SizedBox(width: 15),

                    // KANAN: PIC, Kategori, Button Detail
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PIC (Atas)
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFF00C9E4),
                                child: Text(
                                  (_currentParentData!['User'] != null && _currentParentData!['User']['nama'] != null)
                                      ? _currentParentData!['User']['nama'].substring(0, 1).toUpperCase()
                                      : "U",
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (_currentParentData!['User'] != null) ? _currentParentData!['User']['nama'] : getTxt('pic_kosong'),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Kategori (Bawah PIC)
                          Text(
                            _currentParentData!['kategori'] ?? getTxt('tanpa_kategori'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 10),

                          // Button Detail (Bawah Kanan)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: GestureDetector(
                              onTap: _showDetailModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(getTxt('detail'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

          if (_currentLevel > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sublokasi (${_filteredData.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
            ),

          // List Data
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final item = _filteredData[index];
                      final tName = _getLevelName();
                      final childName = _currentLevel < 3 ? ['unit', 'subunit', 'area'][_currentLevel] : '';
                      final childCount = _currentLevel < 3 ? (item[childName] as List?)?.length ?? 0 : 0;

                      return GestureDetector(
                        // Tap pada KARTU akan membawa user masuk ke Sub-level
                        onTap: () {
                          if (_currentLevel == 3) return;
                          setState(() {
                            _navHistory.add({'level': _currentLevel, 'id': item['id_$tName'], 'name': item['nama_$tName'], 'data': item});
                            _currentLevel++;
                            _searchQuery = "";
                          });
                          _fetchData(parentId: item['id_$tName'], parentData: item);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              // Area Gambar Kiri
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                  image: item['gambar_$tName'] != null
                                      ? DecorationImage(image: NetworkImage(item['gambar_$tName']), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: item['gambar_$tName'] == null
                                    ? const Center(child: Icon(Icons.domain, color: Colors.blueGrey, size: 30))
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              
                              // Info Kanan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showDetailModalForItem(item),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              item['nama_$tName'],
                                              style: const TextStyle(
                                                fontSize: 15, 
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.3,
                                                color: Color(0xFF1E3A8A)
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF00C9E4)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (_currentLevel < 3)
                                      Row(
                                        children: [
                                          const Icon(Icons.account_tree_outlined, size: 14, color: Colors.blueGrey),
                                          const SizedBox(width: 5),
                                          Text(
                                            "$childCount ${getTxt('sublokasi')}", 
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueGrey)
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Bintang
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: IconButton(
                                  icon: Icon(
                                    (item['is_star'] ?? 0) == 1 ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: const Color(0xFFFFC107),
                                    size: 28,
                                  ),
                                  onPressed: () => _toggleStar(item),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// WIDGET BOTTOM SHEET DETAIL (INFO & ANGGOTA)
// ==========================================================
class _DetailBottomSheet extends StatefulWidget {
  final int level; 
  final Map<String, dynamic> data;
  final String lang; 

  const _DetailBottomSheet({required this.level, required this.data, this.lang = 'ID'});

  @override
  State<_DetailBottomSheet> createState() => _DetailBottomSheetState();
}

class _DetailBottomSheetState extends State<_DetailBottomSheet> {
  int _tabIndex = 0; 
  String _searchMember = "";
  final TextEditingController _searchMemberController = TextEditingController();
  late Future<List<dynamic>> _membersFuture;

  

  // Kamus Bahasa Lokal
  final Map<String, Map<String, String>> bsTxt = {
    'EN': {'info': 'Info', 'anggota': 'Members', 'cari_anggota': 'Search member...', 'kategori': 'Category', 'pic': 'Person in Charge', 'deskripsi': 'Description', 'tdk_ada': 'No description available', 'kosong': 'No members found'},
    'ID': {'info': 'Info', 'anggota': 'Anggota', 'cari_anggota': 'Cari anggota...', 'kategori': 'Kategori', 'pic': 'Penanggung Jawab', 'deskripsi': 'Deskripsi', 'tdk_ada': 'Tidak ada deskripsi tersedia', 'kosong': 'Belum ada anggota'},
    'ZH': {'info': '信息', 'anggota': '成员', 'cari_anggota': '搜索成员...', 'kategori': '类别', 'pic': '负责人', 'deskripsi': '描述', 'tdk_ada': '没有可用描述', 'kosong': '未找到成员'},
  };
  String getTxt(String key) => bsTxt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    String tName = ['lokasi', 'unit', 'subunit', 'area'][widget.level];
    _membersFuture = _fetchMembersData(widget.data['id_$tName']);
  }

  Future<List<dynamic>> _fetchMembersData(int idValue) async {
    final supabase = Supabase.instance.client;
    const selectQuery = 'nama, gambar_user, jabatan(nama_jabatan)';

    if (widget.level == 0) {
      return await supabase.from('User').select(selectQuery).eq('id_lokasi', idValue);
    } 
    else if (widget.level == 1) {
      return await supabase.from('User').select(selectQuery).eq('id_unit', idValue);
    } 
    else if (widget.level == 2) {
      final subunitData = await supabase.from('subunit').select('id_unit').eq('id_subunit', idValue).maybeSingle();
      if (subunitData == null || subunitData['id_unit'] == null) return [];
      return await supabase.from('User').select(selectQuery).eq('id_unit', subunitData['id_unit']);
    } 
    else {
      final areaData = await supabase.from('area').select('id_unit').eq('id_area', idValue).maybeSingle();
      if (areaData == null || areaData['id_unit'] == null) return [];
      return await supabase.from('User').select(selectQuery).eq('id_unit', areaData['id_unit']);
    }
  }

  @override
  void dispose() {
    _searchMemberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String tName = ['lokasi', 'unit', 'subunit', 'area'][widget.level];
    String idCol = 'id_$tName';
    String itemName = widget.data['nama_$tName'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFC), // Warna background soft
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Garis Handle Atas
          const SizedBox(height: 12),
          Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 15),
          
          // Judul
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              itemName.toUpperCase(), 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Color(0xFF1E3A8A))
            ),
          ),
          const SizedBox(height: 15),
          
          // Tab Menu
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tabIndex == 0 ? const Color(0xFF00C9E4) : Colors.transparent, width: 3))),
                      child: Center(
                        child: Text(
                          getTxt('info'), 
                          style: TextStyle(fontSize: 15, fontWeight: _tabIndex == 0 ? FontWeight.w800 : FontWeight.w600, color: _tabIndex == 0 ? const Color(0xFF1E3A8A) : Colors.grey.shade500)
                        )
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tabIndex == 1 ? const Color(0xFF00C9E4) : Colors.transparent, width: 3))),
                      child: Center(
                        child: Text(
                          getTxt('anggota'), 
                          style: TextStyle(fontSize: 15, fontWeight: _tabIndex == 1 ? FontWeight.w800 : FontWeight.w600, color: _tabIndex == 1 ? const Color(0xFF1E3A8A) : Colors.grey.shade500)
                        )
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten Tab
          Expanded(
            child: _tabIndex == 0 
              ? _buildInfoTab(tName) 
              : _buildAnggotaTab(idCol, widget.data[idCol]),
          )
        ],
      ),
    );
  }

  Widget _buildInfoTab(String tName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar di ATAS
          Container(
            height: 200, width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              image: widget.data['gambar_$tName'] != null 
                  ? DecorationImage(image: NetworkImage(widget.data['gambar_$tName']), fit: BoxFit.cover) 
                  : null,
            ),
            child: widget.data['gambar_$tName'] == null 
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.black12),
                      SizedBox(height: 8),
                      Text("Tidak ada gambar", style: TextStyle(color: Colors.black26, fontWeight: FontWeight.w600))
                    ],
                  ) 
                : null,
          ),
          const SizedBox(height: 25),

          // Card Informasi (Kategori & PIC)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.category_rounded, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(getTxt('kategori'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(widget.data['kategori'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E3A8A))),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                
                // PIC (Penanggung Jawab) - Cukup satu saja untuk semua level
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.person_pin_rounded, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(getTxt('pic'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text((widget.data['User'] != null) ? widget.data['User']['nama'] : '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E3A8A))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card Deskripsi
          Text(getTxt('deskripsi'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Text(
              widget.data['deskripsi_$tName'] ?? getTxt('tdk_ada'), 
              style: const TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w500, color: Colors.blueGrey),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAnggotaTab(String idColumn, int idValue) {
    Color getRoleColor(String role) {
      switch (role.toLowerCase()) {
        case 'eksekutif': return const Color(0xFF6B21A8); 
        case 'manager': return const Color(0xFF1E3A8A); 
        case 'kasie': return const Color(0xFF047857); 
        case 'staff': default: return const Color(0xFF00C9E4); 
      }
    }

    Color getRoleBgColor(String role) {
      switch (role.toLowerCase()) {
        case 'eksekutif': return const Color(0xFFF3E8FF); 
        case 'manager': return const Color(0xFFDBEAFE); 
        case 'kasie': return const Color(0xFFD1FAE5); 
        case 'staff': default: return const Color(0xFFE0F7FA); 
      }
    }

    // PERBAIKAN: Kolom utama (Search di luar FutureBuilder)
    return Column(
      children: [
        // 1. Search Bar Anggota (Tidak akan ter-reset saat loading)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchMemberController, // Panggil controller
                    onChanged: (val) => setState(() => _searchMember = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: getTxt('cari_anggota'),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 2. FutureBuilder HANYA untuk List Data
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _membersFuture, // Menggunakan future yang sudah disave di initState
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)));
              }
              
              List<dynamic> allMembers = snapshot.data ?? [];
              List<dynamic> filteredMembers = allMembers.where((user) {
                return user['nama'].toString().toLowerCase().contains(_searchMember);
              }).toList();

              final rolePriority = {'eksekutif': 1, 'manager': 2, 'kasie': 3, 'staff': 4};
              filteredMembers.sort((a, b) {
                String roleA = a['jabatan']?['nama_jabatan']?.toString().toLowerCase() ?? 'staff';
                String roleB = b['jabatan']?['nama_jabatan']?.toString().toLowerCase() ?? 'staff';
                return (rolePriority[roleA] ?? 5).compareTo(rolePriority[roleB] ?? 5);
              });

              if (filteredMembers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_off_rounded, size: 60, color: Colors.black12),
                      const SizedBox(height: 10),
                      Text(getTxt('kosong'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  )
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final user = filteredMembers[index];
                  final String roleName = user['jabatan']?['nama_jabatan'] ?? 'Staff';
                  final String? imageUrl = user['gambar_user'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: getRoleColor(roleName), width: 1.5),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFEFF6FF),
                          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                          child: (imageUrl == null || imageUrl.isEmpty) 
                              ? Text(user['nama'][0].toUpperCase(), style: TextStyle(color: getRoleColor(roleName), fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                      title: Text(
                        user['nama'], 
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E3A8A)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: getRoleBgColor(roleName),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: getRoleColor(roleName).withOpacity(0.3)),
                              ),
                              child: Text(
                                roleName,
                                style: TextStyle(color: getRoleColor(roleName), fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}