import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../shared/code/qr_scanner_screen.dart';
import '../../finding/camera_finding_screen.dart';

// Supabase shorthand khusus file ini
final _sb = Supabase.instance.client;

// ============================================================
// LOCATION BOTTOM SHEET
// ============================================================
class LocationBottomSheet extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;
  final String? userUnitId;
  final String? userLokasiId;
  final String userRole;
  final VoidCallback? onFindingSaved;

  const LocationBottomSheet({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.isVisitorMode,
    required this.userRole,
    this.userUnitId,
    this.userLokasiId,
    this.onFindingSaved,
  });

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  int _currentLevel = 0;
  bool _isLoading = true;
  List<dynamic> _currentData = [];
  List<dynamic> _filteredData = [];
  final List<Map<String, dynamic>> _navHistory = [];

  // ── Global search state ──
  bool _isSearchMode = false;
  bool _isSearchLoading = false;
  List<_SearchResult> _searchResults = [];

  // ── Highlight: lokasi spesifik user & PIC ──
  List<_HighlightItem> _highlightItems = [];
  bool _isHighlightLoading = true;

  // ── User specific data ──
  String? _userSpecificId;
  String? _userSpecificType;
  Set<String> _userPicIds = {};

  bool get _hasFullAccess => widget.isProMode || widget.userRole == 'Eksekutif';

  static const List<String> _tables = ['lokasi', 'unit', 'subunit', 'area'];
  String _getIdCol(int l) => 'id_${_tables[l]}';
  String _getNameCol(int l) => 'nama_${_tables[l]}';
  String _getChildKey(int l) => l < 3 ? _tables[l + 1] : '';

  @override
  void initState() {
    super.initState();
    _loadUserSpecificData();
  }

  Future<void> _loadUserSpecificData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) { _fetchData(); return; }

      final userData = await _sb
          .from('User')
          .select('id_area, id_subunit, id_unit, id_lokasi')
          .eq('id_user', userId)
          .maybeSingle();

      if (userData != null) {
        if (userData['id_area'] != null) {
          _userSpecificId   = userData['id_area'].toString();
          _userSpecificType = 'area';
        } else if (userData['id_subunit'] != null) {
          _userSpecificId   = userData['id_subunit'].toString();
          _userSpecificType = 'subunit';
        } else if (userData['id_unit'] != null) {
          _userSpecificId   = userData['id_unit'].toString();
          _userSpecificType = 'unit';
        } else if (userData['id_lokasi'] != null) {
          _userSpecificId   = userData['id_lokasi'].toString();
          _userSpecificType = 'lokasi';
        }
      }

      final picResults = await Future.wait([
        _sb.from('lokasi').select('id_lokasi').eq('id_pic', userId),
        _sb.from('unit').select('id_unit').eq('id_pic', userId),
        _sb.from('subunit').select('id_subunit').eq('id_pic', userId),
        _sb.from('area').select('id_area').eq('id_pic', userId),
      ]);

      final Set<String> picIds = {};
      for (final r in picResults[0] as List) { picIds.add(r['id_lokasi'].toString()); }
      for (final r in picResults[1] as List) { picIds.add(r['id_unit'].toString()); }
      for (final r in picResults[2] as List) { picIds.add(r['id_subunit'].toString()); }
      for (final r in picResults[3] as List) { picIds.add(r['id_area'].toString()); }

      if (mounted) setState(() => _userPicIds = picIds);

      await _fetchUserHighlightData(userId);
    } catch (e) {
      debugPrint('Error loading user specific data: $e');
    }
    _fetchData();
  }

  Future<void> _fetchUserHighlightData(String userId) async {
    try {
      final items = <_HighlightItem>[];

      if (_userSpecificType != null && _userSpecificId != null) {
        final type = _userSpecificType!;
        final id   = _userSpecificId!;
        final row  = await _sb.from(type)
            .select('id_$type, nama_$type, gambar_$type, is_star')
            .eq('id_$type', id)
            .maybeSingle();
        if (row != null) {
          items.add(_HighlightItem(
            id: id, name: row['nama_$type']?.toString() ?? '',
            type: type, badge: _ItemBadge.myLocation,
            imgUrl: row['gambar_$type'] as String?, raw: row,
          ));
        }
      }

      if (_userPicIds.isNotEmpty) {
        final futures = await Future.wait([
          _sb.from('lokasi').select('id_lokasi, nama_lokasi, gambar_lokasi, is_star')
              .inFilter('id_lokasi', _userPicIds.toList()).limit(5),
          _sb.from('unit').select('id_unit, nama_unit, gambar_unit, is_star')
              .inFilter('id_unit', _userPicIds.toList()).limit(5),
          _sb.from('subunit').select('id_subunit, nama_subunit, gambar_subunit, is_star')
              .inFilter('id_subunit', _userPicIds.toList()).limit(5),
          _sb.from('area').select('id_area, nama_area, gambar_area, is_star')
              .inFilter('id_area', _userPicIds.toList()).limit(5),
        ]);

        final types = ['lokasi', 'unit', 'subunit', 'area'];
        for (int i = 0; i < futures.length; i++) {
          for (final r in futures[i] as List) {
            final id = r['id_${types[i]}']?.toString() ?? '';
            if (id == _userSpecificId) continue;
            items.add(_HighlightItem(
              id: id, name: r['nama_${types[i]}']?.toString() ?? '',
              type: types[i], badge: _ItemBadge.pic,
              imgUrl: r['gambar_${types[i]}'] as String?, raw: r,
            ));
          }
        }
      }

      if (mounted) setState(() { _highlightItems = items; _isHighlightLoading = false; });
    } catch (e) {
      debugPrint('Error fetch highlight: $e');
      if (mounted) setState(() => _isHighlightLoading = false);
    }
  }

  String _getEmptyMessage() {
    if (_isSearchMode) return _bs('kosong');
    const levelKeys = ['lokasi_empty', 'unit_empty', 'subunit_empty', 'area_empty'];
    return _bs(levelKeys[_currentLevel]);
  }

  Future<void> _fetchData({String? parentId}) async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> data = [];
      final level = _currentLevel;

      if (level == 0) {
        if (_hasFullAccess) {
          data = await _sb.from('lokasi').select('id_lokasi, nama_lokasi, gambar_lokasi, unit(id_unit), is_star, id_pic');
        } else if (_userSpecificId != null && _userSpecificType == 'lokasi') {
          data = await _sb.from('lokasi').select('id_lokasi, nama_lokasi, gambar_lokasi, unit(id_unit), is_star, id_pic')
              .eq('id_lokasi', _userSpecificId!);
        } else if (_userSpecificId != null) {
          // Untuk user dengan unit/subunit/area, ambil lokasi induknya
          data = await _sb.from('lokasi').select('id_lokasi, nama_lokasi, gambar_lokasi, unit(id_unit), is_star, id_pic');
        } else {
          data = await _sb.from('lokasi').select('id_lokasi, nama_lokasi, gambar_lokasi, unit(id_unit), is_star, id_pic');
        }
      } else if (level == 1) {
        if (_hasFullAccess) {
          data = await _sb.from('unit').select('id_unit, nama_unit, gambar_unit, subunit(id_subunit), is_star, id_pic').eq('id_lokasi', parentId!);
        } else if (widget.userUnitId != null) {
          data = await _sb.from('unit').select('id_unit, nama_unit, gambar_unit, subunit(id_subunit), is_star, id_pic')
              .eq('id_lokasi', parentId!).eq('id_unit', widget.userUnitId!);
        } else {
          data = await _sb.from('unit').select('id_unit, nama_unit, gambar_unit, subunit(id_subunit), is_star, id_pic').eq('id_lokasi', parentId!);
        }
      } else if (level == 2) {
        data = await _sb.from('subunit').select('id_subunit, nama_subunit, gambar_subunit, area(id_area), is_star, id_pic').eq('id_unit', parentId!);
      } else if (level == 3) {
        data = await _sb.from('area').select('id_area, nama_area, gambar_area, is_star, id_pic').eq('id_subunit', parentId!);
      }

      if (mounted) {
        setState(() {
          _currentData = data;
          _filteredData = List.from(data);
          _sortData();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performGlobalSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _isSearchMode = false; _searchResults = []; });
      return;
    }
    setState(() {
      _isSearchMode = true;
      _isSearchLoading = true;
      _searchResults = [];
    });

    try {
      final List<_SearchResult> results = [];

      // Selalu cari semua tabel dengan sub-count untuk label
      final futures = await Future.wait([
        _sb.from('lokasi')
            .select('id_lokasi, nama_lokasi, gambar_lokasi, is_star, id_pic, unit(id_unit)')
            .ilike('nama_lokasi', '%$query%').limit(10),
        _sb.from('unit')
            .select('id_unit, nama_unit, gambar_unit, is_star, id_pic, id_lokasi, lokasi(nama_lokasi), subunit(id_subunit)')
            .ilike('nama_unit', '%$query%').limit(10),
        _sb.from('subunit')
            .select('id_subunit, nama_subunit, gambar_subunit, is_star, id_pic, id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi), area(id_area)')
            .ilike('nama_subunit', '%$query%').limit(10),
        _sb.from('area')
            .select('id_area, nama_area, gambar_area, is_star, id_pic, id_subunit, id_unit, id_lokasi, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi)')
            .ilike('nama_area', '%$query%').limit(10),
      ]);
      _mapSearchFutures(futures, results);

      // Filter scope jika mode non-pro
      final filtered = _hasFullAccess
          ? results
          : results.where((r) => _isInUserScope(r)).toList();

      filtered.sort((a, b) {
        if (a.isUserSpecific != b.isUserSpecific) return a.isUserSpecific ? -1 : 1;
        if (a.isPic != b.isPic) return a.isPic ? -1 : 1;
        if (a.isStar != b.isStar) return a.isStar ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error global search: $e');
      if (mounted) setState(() => _isSearchLoading = false);
    }
  }

  /// Cek apakah result masuk dalam scope lokasi user (mode non-professional)
  bool _isInUserScope(_SearchResult r) {
    // Jika user tidak punya data lokasi sama sekali, tampilkan semua
    if (_userSpecificId == null) return true;

    switch (_userSpecificType) {
      case 'lokasi':
        // Lokasi: tampilkan jika id cocok ATAU item merupakan turunan lokasi user
        if (r.type == 'lokasi') return r.id == _userSpecificId;
        return r.raw['id_lokasi']?.toString() == _userSpecificId;
      case 'unit':
        if (r.type == 'lokasi') {
          // Tampilkan lokasi induk dari unit user
          return r.raw['unit'] != null
              ? (r.raw['unit'] as List).any(
                  (u) => u['id_unit']?.toString() == _userSpecificId)
              : false;
        }
        if (r.type == 'unit') return r.id == _userSpecificId;
        return r.raw['id_unit']?.toString() == _userSpecificId;
      case 'subunit':
        if (r.type == 'lokasi' || r.type == 'unit') return false;
        if (r.type == 'subunit') return r.id == _userSpecificId;
        return r.raw['id_subunit']?.toString() == _userSpecificId;
      case 'area':
        return r.type == 'area' && r.id == _userSpecificId;
      default:
        return true;
    }
  }

  _SearchResult _makeResult(Map<String, dynamic> r, String type, int level) {
    final idKey   = 'id_$type';
    final nameKey = 'nama_$type';
    final id      = r[idKey]?.toString() ?? '';

    String? breadcrumb;
    if (type == 'unit')    breadcrumb = r['lokasi']?['nama_lokasi']?.toString();
    if (type == 'subunit') {
      final parts = [r['lokasi']?['nama_lokasi'], r['unit']?['nama_unit']].whereType<String>().join(' › ');
      breadcrumb = parts.isNotEmpty ? parts : null;
    }
    if (type == 'area') {
      final parts = [r['lokasi']?['nama_lokasi'], r['unit']?['nama_unit'], r['subunit']?['nama_subunit']].whereType<String>().join(' › ');
      breadcrumb = parts.isNotEmpty ? parts : null;
    }

    return _SearchResult(
      id: id, name: r[nameKey]?.toString() ?? '', type: type, level: level,
      imgUrl: r['gambar_$type'] as String?,
      isStar: (r['is_star'] ?? 0) == 1,
      isPic: _userPicIds.contains(id),
      isUserSpecific: _userSpecificId == id,
      breadcrumb: breadcrumb, raw: r,
    );
  }

  void _mapSearchFutures(List<dynamic> futures, List<_SearchResult> results) {
    for (final r in futures[0] as List) { results.add(_makeResult(r, 'lokasi', 0)); }
    for (final r in futures[1] as List) { results.add(_makeResult(r, 'unit', 1)); }
    for (final r in futures[2] as List) { results.add(_makeResult(r, 'subunit', 2)); }
    for (final r in futures[3] as List) { results.add(_makeResult(r, 'area', 3)); }
  }

  void _onItemTapped(Map<String, dynamic> item) {
    if (_currentLevel == 3) { Navigator.pop(context, item); return; }
    _navHistory.add({
      'level': _currentLevel,
      'id': item[_getIdCol(_currentLevel)]?.toString(),
      'name': item[_getNameCol(_currentLevel)],
    });
    setState(() { _currentLevel++; });
    _fetchData(parentId: _navHistory.last['id']);
  }

  void _goBack() {
    if (_navHistory.isEmpty) return;
    _navHistory.removeLast();
    setState(() { _currentLevel--; });
    _fetchData(parentId: _navHistory.isEmpty ? null : _navHistory.last['id']);
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() { _isSearchMode = false; _searchResults = []; _filteredData = List.from(_currentData); _sortData(); });
      return;
    }
    _performGlobalSearch(query);
  }

  void _sortData() {
    final nameCol = _getNameCol(_currentLevel);
    _filteredData.sort((a, b) {
      final idA = a[_getIdCol(_currentLevel)]?.toString() ?? '';
      final idB = b[_getIdCol(_currentLevel)]?.toString() ?? '';
      final isSpecA = _userSpecificId == idA ? 1 : 0;
      final isSpecB = _userSpecificId == idB ? 1 : 0;
      if (isSpecA != isSpecB) return isSpecB - isSpecA;
      final isPicA = _userPicIds.contains(idA) ? 1 : 0;
      final isPicB = _userPicIds.contains(idB) ? 1 : 0;
      if (isPicA != isPicB) return isPicB - isPicA;
      final starA = a['is_star'] ?? 0;
      final starB = b['is_star'] ?? 0;
      if (starA != starB) return starB - starA;
      return a[nameCol].toString().toLowerCase().compareTo(b[nameCol].toString().toLowerCase());
    });
  }

  _ItemBadge _getItemBadge(String itemId) {
    if (_userSpecificId == itemId) return _ItemBadge.myLocation;
    if (_userPicIds.contains(itemId)) return _ItemBadge.pic;
    return _ItemBadge.none;
  }

  static const Map<String, Map<String, String>> _bsTxt = {
    'EN': {
      'pilih_lokasi': 'Choose Finding Location',
      'cari': 'Search location, unit, subunit, area...',
      'semua': 'All Locations',
      'unit_saya': 'My Unit',
      'kosong': 'Location not found',
      'sub': 'Sub-locations',
      'my_location': 'My Location',
      'pic': 'My Responsibility',
      'search_result': 'Search Results',
      'lokasi_empty': 'Location not found',
      'unit_empty': 'Unit not found',
      'subunit_empty': 'Subunit not found',
      'area_empty': 'Area not found',
      'my_location_label': 'My Location',
      'pic_label': 'My Responsibility',
      'highlight_title': 'Your Locations',
      'pro_mode_label': 'Professional Mode — All Locations',
    },
    'ID': {
      'pilih_lokasi': 'Pilih Lokasi Temuan',
      'cari': 'Cari lokasi, unit, subunit, area...',
      'semua': 'Semua Lokasi',
      'unit_saya': 'Unit Saya',
      'kosong': 'Lokasi tidak ditemukan',
      'sub': 'Sub-lokasi',
      'my_location': 'Lokasi Saya',
      'pic': 'Tanggung Jawab Saya',
      'search_result': 'Hasil Pencarian',
      'lokasi_empty': 'Lokasi tidak ditemukan',
      'unit_empty': 'Unit tidak ditemukan',
      'subunit_empty': 'Subunit tidak ditemukan',
      'area_empty': 'Area tidak ditemukan',
      'my_location_label': 'Lokasi Saya',
      'pic_label': 'Tanggung Jawab Saya',
      'highlight_title': 'Lokasi Anda',
      'pro_mode_label': 'Mode Profesional — Semua Lokasi Tampil',
    },
    'ZH': {
      'pilih_lokasi': '选择发现位置',
      'cari': '搜索位置、单位、子单位、区域...',
      'semua': '所有位置',
      'unit_saya': '我的单位',
      'kosong': '未找到位置',
      'sub': '子位置',
      'my_location': '我的位置',
      'pic': '我的责任',
      'search_result': '搜索结果',
      'lokasi_empty': '未找到位置',
      'unit_empty': '未找到单位',
      'subunit_empty': '未找到子单位',
      'area_empty': '未找到区域',
      'my_location_label': '我的位置',
      'pic_label': '我的责任',
      'highlight_title': '您的位置',
      'pro_mode_label': '专业模式 — 显示所有位置',
    },
  };

  String _bs(String key) => _bsTxt[widget.lang]?[key] ?? _bsTxt['ID']![key]!;

  // ── Shimmer card untuk loading ──
  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8F4FD),
      highlightColor: const Color(0xFFF5FBFF),
      period: const Duration(milliseconds: 1200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 8),
                    Container(height: 11, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String parentName = _navHistory.isEmpty
        ? _bs('semua')
        : _navHistory.last['name'];

    // Label section bawah saat pro aktif
    final String sectionLabel = _hasFullAccess
        ? (_bsTxt[widget.lang]?['pro_mode_label'] ?? 'Mode Profesional — Semua Lokasi')
        : _bs('semua');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(
              _bs('pilih_lokasi'),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8)),
            ),
          ),
          const Divider(height: 1, color: Colors.black12),

          // ── Search bar — selalu tampil ──
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: _onSearch,
                            decoration: InputDecoration(
                              hintText: _bs('cari'),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_isSearchMode)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSearchMode  = false;
                                _searchResults = [];
                              });
                            },
                            child: const Icon(Icons.close,
                                color: Colors.grey, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QRScannerScreen(
                        lang: widget.lang,
                        isProMode: widget.isProMode,
                        isVisitorMode: widget.isVisitorMode,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF1D4ED8).withValues(alpha:0.2)),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),

          // ── MODE NON-PRO: hanya Your Locations + hasil search terbatas ──
          if (!_hasFullAccess) ...[
            if (_isSearchMode)
              Expanded(child: _buildSearchResults())
            else ...[
              _buildHighlightSection(),
              // Tidak ada section list bawah
            ],
          ]

          // ── MODE PRO: Your Locations + section semua lokasi + search bebas ──
          else ...[
            if (_isSearchMode)
              Expanded(child: _buildSearchResults())
            else ...[
              _buildHighlightSection(),
              // Label "Mode Profesional Aktif — Semua Lokasi Tampil"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Row(
                  children: [
                    if (_navHistory.isNotEmpty)
                      GestureDetector(
                        onTap: _goBack,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.arrow_back_ios,
                              size: 18, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    const Icon(Icons.workspace_premium_rounded,
                        size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _navHistory.isEmpty ? sectionLabel : parentName.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: _isLoading
                    ? _buildShimmerList()
                    : _buildLocationList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      itemCount: 5,
      itemBuilder: (_, __) => _buildShimmerCard(),
    );
  }

  Widget _buildHighlightSection() {
    if (_isSearchMode || (_highlightItems.isEmpty && !_isHighlightLoading)) {
      return const SizedBox.shrink();
    }

    const levelColors = [Color(0xFF0891B2), Color(0xFF7C3AED), Color(0xFF059669), Color(0xFFD97706)];
    const levelIcons  = [Icons.location_city_rounded, Icons.domain_rounded, Icons.grid_view_rounded, Icons.place_rounded];
    const typeIndex   = {'lokasi': 0, 'unit': 1, 'subunit': 2, 'area': 3};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
          child: Row(children: [
            const Icon(Icons.person_pin_circle_rounded, size: 14, color: Color(0xFF1D4ED8)),
            const SizedBox(width: 6),
            Text(_bs('highlight_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), fontSize: 13)),
          ]),
        ),
        if (_isHighlightLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: List.generate(1, (_) => _buildShimmerCard()),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: _highlightItems.map((item) {
                final idx      = typeIndex[item.type] ?? 0;
                final clr      = levelColors[idx];
                final ico      = levelIcons[idx];
                final isMyLoc  = item.badge == _ItemBadge.myLocation;
                final badge    = item.badge;

                return GestureDetector(
                  onTap: () => _openCameraFromHighlight(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAFE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isMyLoc
                            ? const Color(0xFF00C9E4).withValues(alpha:0.5)
                            : const Color(0xFF16A34A).withValues(alpha:0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Gambar — sama persis dengan card bawah
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(0),
                          ),
                          child: SizedBox(
                            width: 80,
                            height: 90,
                            child: item.imgUrl != null
                                ? Image.network(
                                    item.imgUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: clr.withValues(alpha:0.1),
                                      child: Center(child: Icon(ico, color: clr, size: 28)),
                                    ),
                                  )
                                : Container(
                                    color: clr.withValues(alpha:0.1),
                                    child: Center(child: Icon(ico, color: clr, size: 28)),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nama + badge
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E3A8A)),
                                      ),
                                    ),
                                    if (badge != _ItemBadge.none) ...[
                                      const SizedBox(width: 6),
                                      _buildBadgeChip(badge),
                                    ],
                                  ],
                                ),
                                // Sub-locations count (selalu 0 untuk highlight, tapi konsisten)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(children: [
                                    const Icon(Icons.account_tree_outlined,
                                        size: 14, color: Colors.black54),
                                    const SizedBox(width: 5),
                                    Text(_bs('sub'),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.black54)),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Star + Camera — sama persis dengan card bawah
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final idCol  = 'id_${item.type}';
                                final curStar = (item.raw['is_star'] ?? 0) == 1;
                                final newStar = curStar ? 0 : 1;
                                // Update raw agar UI ikut berubah
                                item.raw['is_star'] = newStar;
                                setState(() {});
                                await _sb
                                    .from(item.type)
                                    .update({'is_star': newStar})
                                    .eq(idCol, item.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha:0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  (item.raw['is_star'] ?? 0) == 1
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _openCameraFromHighlight(item),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C9E4).withValues(alpha:0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Color(0xFF00C9E4), size: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const Divider(height: 16, color: Colors.black12, indent: 15, endIndent: 15),
      ],
    );
  }

  void _openCameraFromHighlight(_HighlightItem item) {
    String? idL, idU, idS, idA;
    final raw = item.raw;
    switch (item.type) {
      case 'lokasi':  idL = item.id; break;
      case 'unit':    idL = raw['id_lokasi']?.toString(); idU = item.id; break;
      case 'subunit': idL = raw['id_lokasi']?.toString(); idU = raw['id_unit']?.toString(); idS = item.id; break;
      case 'area':    idL = raw['id_lokasi']?.toString(); idU = raw['id_unit']?.toString();
                      idS = raw['id_subunit']?.toString(); idA = item.id; break;
    }
    final onSaved = widget.onFindingSaved;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CameraFindingScreen(
        lang: widget.lang, isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        selectedLocationName: item.name,
        selectedLocationId: idL, selectedUnitId: idU,
        selectedSubunitId: idS, selectedAreaId: idA,
        onFindingSaved: onSaved,
      ),
    ));
  }

  Widget _buildLocationList() {
    if (_filteredData.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final item = _filteredData[index];
        final idCol = _getIdCol(_currentLevel);
        final nameCol = _getNameCol(_currentLevel);
        final childKey = _getChildKey(_currentLevel);
        final String itemId = item[idCol]?.toString() ?? '';
        final String itemName = item[nameCol].toString();
        final int subCount = _currentLevel < 3
            ? ((item[childKey] as List<dynamic>?)?.length ?? 0)
            : 0;
        final badge = _getItemBadge(itemId);
        final String? imgUrl = item['gambar_${_tables[_currentLevel]}'] as String?;

        return _buildLocationItem(
          item: item, itemId: itemId, itemName: itemName,
          subCount: subCount, badge: badge, imgUrl: imgUrl,
          onTap: () => _onItemTapped(item),
          onCamera: () => _openCamera(item, itemId, itemName),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: 5,
        itemBuilder: (_, __) => _buildShimmerCard(),
      );
    }
    if (_searchResults.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Text(
            '${_bs('search_result')} (${_searchResults.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            physics: const BouncingScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildSearchResultItem(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(_SearchResult result) {
    final badge = result.isUserSpecific
        ? _ItemBadge.myLocation
        : result.isPic
            ? _ItemBadge.pic
            : _ItemBadge.none;

    final IconData levelIcon = [
      Icons.location_city_rounded, Icons.domain_rounded,
      Icons.grid_view_rounded, Icons.place_rounded,
    ][result.level];

    final Color levelColor = [
      const Color(0xFF0891B2), const Color(0xFF7C3AED),
      const Color(0xFF059669), const Color(0xFFD97706),
    ][result.level];

    // Label sub dinamis per level
    String subLabel() {
      switch (result.level) {
        case 0:
          final units = result.raw['unit'] as List?;
          return '${units?.length ?? 0} Unit';
        case 1:
          final subunits = result.raw['subunit'] as List?;
          return '${subunits?.length ?? 0} Subunit';
        case 2:
          final areas = result.raw['area'] as List?;
          return '${areas?.length ?? 0} Area';
        default:
          return '';
      }
    }

    return GestureDetector(
      onTap: () => _openCameraFromSearch(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha:0.15), width: 1),
        ),
        child: Column(
          children: [
            // ── IntrinsicHeight agar gambar memenuhi tinggi konten ──
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gambar memenuhi penuh tinggi konten, radius pojok kiri atas saja
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: 80,
                      child: result.imgUrl != null
                          ? Image.network(
                              result.imgUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: levelColor.withValues(alpha:0.1),
                                child: Center(
                                    child: Icon(levelIcon,
                                        color: levelColor, size: 28)),
                              ),
                            )
                          : Container(
                              color: levelColor.withValues(alpha:0.1),
                              child: Center(
                                  child: Icon(levelIcon,
                                      color: levelColor, size: 28)),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info teks
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(result.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E3A8A))),
                              ),
                              if (badge != _ItemBadge.none) ...[
                                const SizedBox(width: 6),
                                _buildBadgeChip(badge),
                              ],
                            ],
                          ),
                          if (result.breadcrumb != null) ...[
                            const SizedBox(height: 3),
                            Text(result.breadcrumb!,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 5),
                          // Type chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha:0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(result.type.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    color: levelColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                          // Sub count
                          if (result.level < 3 && subLabel().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(children: [
                              Icon(Icons.account_tree_outlined,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(subLabel(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // ── Star + Camera sejajar horizontal, center vertikal ──
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final idCol = 'id_${result.type}';
                              final curStar = (result.raw['is_star'] ?? 0) == 1;
                              final newStar = curStar ? 0 : 1;
                              result.raw['is_star'] = newStar;
                              setState(() {});
                              await _sb
                                  .from(result.type)
                                  .update({'is_star': newStar})
                                  .eq(idCol, result.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                (result.raw['is_star'] ?? 0) == 1
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _openCameraFromSearch(result),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C9E4).withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Color(0xFF00C9E4), size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required Map<String, dynamic> item,
    required String itemId,
    required String itemName,
    required int subCount,
    required _ItemBadge badge,
    required String? imgUrl,
    required VoidCallback onTap,
    required VoidCallback onCamera,
  }) {
    final IconData levelIcon = [
      Icons.location_city_rounded, Icons.domain_rounded,
      Icons.grid_view_rounded, Icons.place_rounded,
    ][_currentLevel];

    final Color levelColor = [
      const Color(0xFF0891B2), const Color(0xFF7C3AED),
      const Color(0xFF059669), const Color(0xFFD97706),
    ][_currentLevel];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge == _ItemBadge.myLocation
                ? const Color(0xFF00C9E4).withValues(alpha:0.5)
                : badge == _ItemBadge.pic
                    ? const Color(0xFF16A34A).withValues(alpha:0.4)
                    : Colors.blue.withValues(alpha:0.15),
            width: badge != _ItemBadge.none ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Gambar memenuhi, radius hanya pojok kiri atas
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(0),
              ),
              child: SizedBox(
                width: 80, height: 90,
                child: imgUrl != null
                    ? Image.network(imgUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: levelColor.withValues(alpha:0.1),
                          child: Center(child: Icon(levelIcon, color: levelColor, size: 28)),
                        ))
                    : Container(
                        color: levelColor.withValues(alpha:0.1),
                        child: Center(child: Icon(levelIcon, color: levelColor, size: 28)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(itemName,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A))),
                        ),
                        if (badge != _ItemBadge.none) ...[
                          const SizedBox(width: 6),
                          _buildBadgeChip(badge),
                        ],
                      ],
                    ),
                    if (_currentLevel < 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          const Icon(Icons.account_tree_outlined,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 5),
                          Text('$subCount ${_bs('sub')}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ]),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final idCol = _getIdCol(_currentLevel);
                    final int newStar = (item['is_star'] ?? 0) == 1 ? 0 : 1;
                    setState(() { item['is_star'] = newStar; _sortData(); });
                    await _sb.from(_tables[_currentLevel])
                        .update({'is_star': newStar}).eq(idCol, itemId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      (item['is_star'] ?? 0) == 1
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber, size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCamera,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9E4).withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Color(0xFF00C9E4), size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(_ItemBadge badge) {
    if (badge == _ItemBadge.myLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF00C9E4).withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00C9E4).withValues(alpha:0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_pin_circle_rounded, size: 10, color: Color(0xFF0891B2)),
            const SizedBox(width: 3),
            Text(_bs('my_location'),
                style: const TextStyle(fontSize: 9, color: Color(0xFF0891B2), fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha:0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 10, color: Color(0xFF16A34A)),
            const SizedBox(width: 3),
            Text(_bs('pic'),
                style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/team_illustration.png', height: 140,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.location_off_rounded, size: 80, color: Colors.grey)),
            const SizedBox(height: 16),
            Text(_getEmptyMessage(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _openCameraFromSearch(_SearchResult result) {
    String? idL, idU, idS, idA;
    final raw = result.raw;
    switch (result.type) {
      case 'lokasi': idL = result.id; break;
      case 'unit': idL = raw['id_lokasi']?.toString(); idU = result.id; break;
      case 'subunit': idL = raw['id_lokasi']?.toString(); idU = raw['id_unit']?.toString(); idS = result.id; break;
      case 'area': idL = raw['id_lokasi']?.toString(); idU = raw['id_unit']?.toString();
                   idS = raw['id_subunit']?.toString(); idA = result.id; break;
    }
    final onSaved = widget.onFindingSaved;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CameraFindingScreen(
        lang: widget.lang, isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        selectedLocationName: result.name,
        selectedLocationId: idL, selectedUnitId: idU,
        selectedSubunitId: idS, selectedAreaId: idA,
        onFindingSaved: onSaved,
      ),
    ));
  }

  void _openCamera(Map<String, dynamic> item, String itemId, String itemName) {
    String? idL, idU, idS, idA;
    final level = _currentLevel;
    if (level == 0) { idL = itemId; }
    else if (level == 1) { idL = _navHistory[0]['id']; idU = itemId; }
    else if (level == 2) { idL = _navHistory[0]['id']; idU = _navHistory[1]['id']; idS = itemId; }
    else if (level == 3) { idL = _navHistory[0]['id']; idU = _navHistory[1]['id']; idS = _navHistory[2]['id']; idA = itemId; }

    final onSaved = widget.onFindingSaved;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CameraFindingScreen(
        lang: widget.lang, isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        selectedLocationName: itemName,
        selectedLocationId: idL, selectedUnitId: idU,
        selectedSubunitId: idS, selectedAreaId: idA,
        onFindingSaved: onSaved,
      ),
    ));
  }
}

class _HighlightItem {
  final String id;
  final String name;
  final String type;
  final _ItemBadge badge;
  final String? imgUrl;
  final Map<String, dynamic> raw;
  const _HighlightItem({
    required this.id, required this.name,
    required this.type, required this.badge,
    this.imgUrl,
    required this.raw,
  });
}

// ── Helper: search result model ──
class _SearchResult {
  final String id;
  final String name;
  final String type;
  final int level;
  final bool isStar;
  final bool isPic;
  final bool isUserSpecific;
  final String? imgUrl;
  final String? breadcrumb;
  final Map<String, dynamic> raw;

  const _SearchResult({
    required this.id, required this.name, required this.type,
    required this.level, required this.isStar, required this.isPic,
    required this.isUserSpecific, this.imgUrl, required this.breadcrumb,
    required this.raw,
  });
}

// ── Helper: badge type ──
enum _ItemBadge { none, myLocation, pic }