import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../shared/code/qr_scanner_screen.dart';
import '../../finding/camera/camera_finding_screen.dart';

final _sb = Supabase.instance.client;

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
  int _activeTabLevel = 0;
  bool _isBrowseLoading = true;

  List<_SearchResult> _allLokasi = [];
  List<_SearchResult> _allUnit = [];
  List<_SearchResult> _allSubunit = [];
  List<_SearchResult> _allArea = [];

  // SEARCH
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;
  String _searchQuery = '';
  int _preSearchTabLevel = 0;

  // USER SPECIFIC DATA
  String? _userSpecificId;
  Set<String> _userPicIds = {};

  String? _userLokasiId;
  String? _userUnitId;
  String? _userSubunitId;
  String? _userAreaId;

  bool get _hasFullAccess => widget.isProMode || widget.userRole == 'Eksekutif';

  static const List<Color> _levelColors = [
    Color(0xFF10B981), Color(0xFF6366F1), Color(0xFFFBBF24), Color(0xFFF472B6),
  ];
  static const List<IconData> _levelIcons = [
    Icons.location_city_rounded, Icons.business_rounded, Icons.layers_rounded, Icons.place_rounded,
  ];
  static const List<String> _tabLabelKeys = ['tab_lokasi', 'tab_unit', 'tab_subunit', 'tab_area'];
  static const List<String> _myLabelKeys = ['my_lokasi', 'my_unit', 'my_subunit', 'my_area'];
  static const Map<String, int> _typeIndex = {'lokasi': 0, 'unit': 1, 'subunit': 2, 'area': 3};

  @override
  void initState() {
    super.initState();
    _loadUserSpecificData();
    CameraWarmupService.instance.warmUp();
  }

  @override
  void dispose() {
    _searchController.dispose();
    CameraWarmupService.instance.release();
    super.dispose();
  }

  Future<void> _loadUserSpecificData() async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) { _fetchAllFlatData(); return; }

      final userData = await _sb
          .from('User')
          .select('id_area, id_subunit, id_unit, id_lokasi')
          .eq('id_user', userId)
          .maybeSingle();

      if (userData != null) {
        _userLokasiId  = userData['id_lokasi']?.toString();
        _userUnitId    = userData['id_unit']?.toString();
        _userSubunitId = userData['id_subunit']?.toString();
        _userAreaId    = userData['id_area']?.toString();

        if (userData['id_area'] != null) {
          _userSpecificId   = userData['id_area'].toString();
        } else if (userData['id_subunit'] != null) {
          _userSpecificId   = userData['id_subunit'].toString();
        } else if (userData['id_unit'] != null) {
          _userSpecificId   = userData['id_unit'].toString();
        } else if (userData['id_lokasi'] != null) {
          _userSpecificId   = userData['id_lokasi'].toString();
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

    } catch (e) {
      debugPrint('Error loading user specific data: $e');
    }
    _fetchAllFlatData();
  }

  Future<void> _fetchAllFlatData() async {
    if (mounted) setState(() => _isBrowseLoading = true);
    try {
      final futures = await Future.wait([
        _sb.from('lokasi')
            .select('id_lokasi, nama_lokasi, gambar_lokasi, is_star, id_pic, unit(id_unit)'),
        _sb.from('unit')
            .select('id_unit, nama_unit, gambar_unit, is_star, id_pic, id_lokasi, lokasi(nama_lokasi), subunit(id_subunit)'),
        _sb.from('subunit')
            .select('id_subunit, nama_subunit, gambar_subunit, is_star, id_pic, id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi), area(id_area)'),
        _sb.from('area')
            .select('id_area, nama_area, gambar_area, is_star, id_pic, id_subunit, id_unit, id_lokasi, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi)'),
      ]);

      List<_SearchResult> lokasi  = (futures[0] as List).map((r) => _makeResult(r, 'lokasi', 0)).toList();
      List<_SearchResult> unit    = (futures[1] as List).map((r) => _makeResult(r, 'unit', 1)).toList();
      List<_SearchResult> subunit = (futures[2] as List).map((r) => _makeResult(r, 'subunit', 2)).toList();
      List<_SearchResult> area    = (futures[3] as List).map((r) => _makeResult(r, 'area', 3)).toList();

      if (!_hasFullAccess) {
        lokasi  = lokasi.where((r) => r.isPic || _isInUserScope(r)).toList();
        unit    = unit.where((r) => r.isPic || _isInUserScope(r)).toList();
        subunit = subunit.where((r) => r.isPic || _isInUserScope(r)).toList();
        area    = area.where((r) => r.isPic || _isInUserScope(r)).toList();
      }

      _sortResults(lokasi);
      _sortResults(unit);
      _sortResults(subunit);
      _sortResults(area);

      if (mounted) {
        setState(() {
          _allLokasi  = lokasi;
          _allUnit    = unit;
          _allSubunit = subunit;
          _allArea    = area;
          _isBrowseLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching flat location data: $e');
      if (mounted) setState(() => _isBrowseLoading = false);
    }
  }

  void _sortResults(List<_SearchResult> list) {
    list.sort((a, b) {
      if (a.isUserSpecific != b.isUserSpecific) return a.isUserSpecific ? -1 : 1;
      if (a.isPic != b.isPic) return a.isPic ? -1 : 1;
      if (a.isStar != b.isStar) return a.isStar ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  bool _isInUserScope(_SearchResult r) {
    switch (r.type) {
      case 'lokasi':
        if (_userLokasiId == null) return false;
        return r.id == _userLokasiId;
      case 'unit':
        if (_userUnitId == null) return false;
        return r.id == _userUnitId;
      case 'subunit':
        if (_userSubunitId == null) return false;
        return r.id == _userSubunitId;
      case 'area':
        if (_userAreaId == null) return false;
        return r.id == _userAreaId;
      default:
        return false;
    }
  }

  _SearchResult _makeResult(Map<String, dynamic> r, String type, int level) {
    final idKey   = 'id_$type';
    final nameKey = 'nama_$type';
    final id      = r[idKey]?.toString() ?? '';

    String? breadcrumb;
    if (type == 'unit')    breadcrumb = r['lokasi']?['nama_lokasi']?.toString();
    if (type == 'subunit') breadcrumb = r['unit']?['nama_unit']?.toString();
    if (type == 'area')    breadcrumb = r['subunit']?['nama_subunit']?.toString();

    return _SearchResult(
      id: id, name: r[nameKey]?.toString() ?? '', type: type, level: level,
      imgUrl: r['gambar_$type'] as String?,
      isStar: (r['is_star'] ?? 0) == 1,
      isPic: _userPicIds.contains(id),
      isUserSpecific: _userSpecificId == id,
      breadcrumb: breadcrumb, raw: r,
    );
  }

  List<_SearchResult> _listForLevel(int level) {
    switch (level) {
      case 0: return _allLokasi;
      case 1: return _allUnit;
      case 2: return _allSubunit;
      case 3: return _allArea;
      default: return const [];
    }
  }

  List<_SearchResult> _filteredForLevel(int level) {
    final list = _listForLevel(level);
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  void _onSearchChanged(String value) {
    final bool willBeSearchMode = value.trim().isNotEmpty;

    setState(() {
      if (willBeSearchMode && !_isSearchMode) {
        _preSearchTabLevel = _activeTabLevel;
      }

      _searchQuery = value;
      _isSearchMode = willBeSearchMode;

      if (_isSearchMode) {
        final hasMatchOnCurrentTab = _filteredForLevel(_activeTabLevel).isNotEmpty;
        if (!hasMatchOnCurrentTab) {
          for (int lvl = 0; lvl < 4; lvl++) {
            if (_filteredForLevel(lvl).isNotEmpty) {
              _activeTabLevel = lvl;
              break;
            }
          }
        }
      } else {
        _activeTabLevel = _preSearchTabLevel;
      }
    });
  }

  void _onTabTap(int level) {
    setState(() => _activeTabLevel = level);
  }

  String _getEmptyMessage() {
    const levelKeys = ['lokasi_empty', 'unit_empty', 'subunit_empty', 'area_empty'];
    return _bs(levelKeys[_activeTabLevel]);
  }

  static const Map<String, Map<String, String>> _bsTxt = {
    'EN': {
      'pilih_lokasi': 'Choose 5R Finding Location',
      'cari': 'Search specific location',
      'semua': 'All Locations',
      'kosong': 'Location not found',
      'sub': 'Sub-locations',
      'my_location': 'My Location',
      'pic': 'My Responsibility',
      'search_result': 'Search Results',
      'lokasi_empty': 'Location not found',
      'unit_empty': 'Unit not found',
      'subunit_empty': 'Subunit not found',
      'area_empty': 'Area not found',
      'highlight_title': 'Your Locations',
      'pro_mode_label': 'Professional Mode',
      'exec_mode_label': 'Executive Access',
      'tab_lokasi': 'Location',
      'tab_unit': 'Unit',
      'tab_subunit': 'Subunit',
      'tab_area': 'Area',
      'my_lokasi': 'My Location',
      'my_unit': 'My Unit',
      'my_subunit': 'My Subunit',
      'my_area': 'My Area',
    },
    'ID': {
      'pilih_lokasi': 'Pilih Lokasi Temuan 5R',
      'cari': 'Cari lokasi spesifik',
      'semua': 'Semua Lokasi',
      'kosong': 'Lokasi tidak ditemukan',
      'sub': 'Sub-lokasi',
      'my_location': 'Lokasi Saya',
      'pic': 'Tanggung Jawab Saya',
      'search_result': 'Hasil Pencarian',
      'lokasi_empty': 'Lokasi tidak ditemukan',
      'unit_empty': 'Unit tidak ditemukan',
      'subunit_empty': 'Subunit tidak ditemukan',
      'area_empty': 'Area tidak ditemukan',
      'highlight_title': 'Lokasi Anda',
      'pro_mode_label': 'Mode Profesional',
      'exec_mode_label': 'Akses Eksekutif',
      'tab_lokasi': 'Lokasi',
      'tab_unit': 'Unit',
      'tab_subunit': 'Subunit',
      'tab_area': 'Area',
      'my_lokasi': 'Lokasi Saya',
      'my_unit': 'Unit Saya',
      'my_subunit': 'Subunit Saya',
      'my_area': 'Area Saya',
    },
    'ZH': {
      'pilih_lokasi': '选择5R发现位置',
      'cari': '搜索特定位置',
      'semua': '所有位置',
      'kosong': '未找到位置',
      'sub': '子位置',
      'my_location': '我的位置',
      'pic': '我的责任',
      'search_result': '搜索结果',
      'lokasi_empty': '未找到位置',
      'unit_empty': '未找到单位',
      'subunit_empty': '未找到子单位',
      'area_empty': '未找到区域',
      'highlight_title': '您的位置',
      'pro_mode_label': '专业模式',
      'exec_mode_label': '高管权限',
      'tab_lokasi': '位置',
      'tab_unit': '单位',
      'tab_subunit': '子单位',
      'tab_area': '区域',
      'my_lokasi': '我的位置',
      'my_unit': '我的单位',
      'my_subunit': '我的子单位',
      'my_area': '我的区域',
    },
  };

  String _bs(String key) => _bsTxt[widget.lang]?[key] ?? _bsTxt['ID']![key]!;

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _bs('pilih_lokasi'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D72F3),
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // SEARCH BAR + QRCODE BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 12),
                _buildQrButton(context),
              ],
            ),
          ),

          _buildTabBar(),

          Expanded(child: _buildResultsArea()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isSearchMode ? const Color(0xFF1D72F3) : Colors.grey.shade300,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF1D72F3), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: _bs('cari'),
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_isSearchMode)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D72F3).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF1D72F3)),
              ),
            ),
        ],
      ),
    );
  }

  bool _isOpeningQr = false;

  Future<void> _openQrScanner(BuildContext context) async {
    if (_isOpeningQr) return;
    _isOpeningQr = true;
    await CameraWarmupService.instance.release();
    unawaited(QrWarmupService.instance.warmUp());

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          lang: widget.lang,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
        ),
      ),
    );

    if (mounted) {
      unawaited(QrWarmupService.instance.release());
      unawaited(CameraWarmupService.instance.warmUp());
    }
    _isOpeningQr = false;
  }

  Widget _buildQrButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _openQrScanner(context),
      child: Container(
        height: 54,
        width: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.qr_code_scanner, color: Color(0xFF1D72F3), size: 24),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessBanner() {
    if (widget.isProMode) {
      return _buildSectionHeader(
        icon: Icons.workspace_premium_rounded,
        label: _bs('pro_mode_label'),
        gradientColors: const [Color(0xFF4ADE80), Color(0xFF16A34A)],
        textColor: const Color(0xFF16A34A),
      );
    }
    return _buildSectionHeader(
      icon: Icons.workspace_premium_rounded,
      label: _bs('exec_mode_label'),
      gradientColors: const [Color(0xFFF87171), Color(0xFFDC2626)],
      textColor: const Color(0xFFDC2626),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 4, 15, 10),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = _activeTabLevel == i;
          final color = _levelColors[i];
          final icon = _levelIcons[i];
          final label = _bs(_tabLabelKeys[i]);
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabTap(i),
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? color : Colors.grey.shade300),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: isActive ? Colors.white : color),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isBrowseLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: 5,
        itemBuilder: (_, __) => _buildShimmerCard(),
      );
    }

    final results = _filteredForLevel(_activeTabLevel);
    final showBanner = _hasFullAccess && !_isSearchMode;

    if (results.isEmpty) {
      return Column(
        children: [
          if (showBanner) _buildAccessBanner(),
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      physics: const BouncingScrollPhysics(),
      children: [
        if (showBanner) _buildAccessBanner(),
        ...results.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _buildSearchResultItem(r),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(_SearchResult result) {
    final bool showMyBadge = result.isUserSpecific;
    final bool showPicBadge = result.isPic;
    final bool hasBadge = showMyBadge || showPicBadge;

    final IconData levelIcon = _levelIcons[result.level];
    final Color levelColor = _levelColors[result.level];

    Widget pill({required IconData icon, required String label, required Color color}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      );
    }

    Widget? breadcrumbPill;
    if (result.breadcrumb != null && result.level > 0) {
      final parentLevel = result.level - 1;
      breadcrumbPill = pill(
        icon: _levelIcons[parentLevel],
        label: result.breadcrumb!,
        color: _levelColors[parentLevel],
      );
    }

    Widget? subCountPill;
    switch (result.level) {
      case 0:
        final units = result.raw['unit'] as List?;
        subCountPill = pill(icon: _levelIcons[1], label: '${units?.length ?? 0} Unit', color: _levelColors[1]);
        break;
      case 1:
        final subunits = result.raw['subunit'] as List?;
        subCountPill = pill(icon: _levelIcons[2], label: '${subunits?.length ?? 0} Subunit', color: _levelColors[2]);
        break;
      case 2:
        final areas = result.raw['area'] as List?;
        subCountPill = pill(icon: _levelIcons[3], label: '${areas?.length ?? 0} Area', color: _levelColors[3]);
        break;
      default:
        subCountPill = null;
    }

    Widget actionButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              final idCol = 'id_${result.type}';
              final curStar = (result.raw['is_star'] ?? 0) == 1;
              final newStar = curStar ? 0 : 1;
              result.raw['is_star'] = newStar;
              setState(() {});
              await _sb.from(result.type).update({'is_star': newStar}).eq(idCol, result.id);
            },
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                (result.raw['is_star'] ?? 0) == 1 ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openCameraFromSearch(result),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9E4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt, color: Color(0xFF00C9E4), size: 24),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _openCameraFromSearch(result),
        child: Stack(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 68),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAFE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.15), width: 1),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: SizedBox(
                        width: 80,
                        child: result.imgUrl != null
                            ? Image.network(
                                result.imgUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: levelColor.withValues(alpha: 0.1),
                                  child: Center(child: Icon(levelIcon, color: levelColor, size: 28)),
                                ),
                              )
                            : Container(
                                color: levelColor.withValues(alpha: 0.1),
                                child: Center(child: Icon(levelIcon, color: levelColor, size: 28)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 90, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              result.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: levelColor,
                                height: 1.25,
                              ),
                            ),
                            if (breadcrumbPill != null) ...[
                              const SizedBox(height: 6),
                              breadcrumbPill,
                            ],
                            const SizedBox(height: 6),
                            if (breadcrumbPill == null) ...[
                              pill(icon: levelIcon, label: _bs(_tabLabelKeys[result.level]), color: levelColor),
                              if (subCountPill != null) ...[
                                const SizedBox(height: 6),
                                subCountPill,
                              ],
                            ] else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  pill(icon: levelIcon, label: _bs(_tabLabelKeys[result.level]), color: levelColor),
                                  if (subCountPill != null) subCountPill,
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasBadge)
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showPicBadge) _buildBadgeChip(_ItemBadge.pic, result.type),
                    if (showPicBadge && showMyBadge) const SizedBox(height: 6),
                    if (showMyBadge) _buildBadgeChip(_ItemBadge.myLocation, result.type),
                  ],
                ),
              ),
            // STAR & CAMERA BUTTON
            if (hasBadge)
              Positioned(
                bottom: 10,
                right: 8,
                child: actionButtons(),
              )
            else
              Positioned(
                top: 0,
                bottom: 0,
                right: 8,
                child: Center(child: actionButtons()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(_ItemBadge badge, String type) {
    final idx   = _typeIndex[type] ?? 0;
    final color = badge == _ItemBadge.myLocation ? _levelColors[idx] : const Color(0xFF16A34A);
    final icon  = badge == _ItemBadge.myLocation ? Icons.person_pin_circle_rounded : Icons.verified_rounded;
    final label = badge == _ItemBadge.myLocation ? _bs(_myLabelKeys[idx]) : _bs('pic');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 8.5, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final color = _levelColors[_activeTabLevel];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 140,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.location_off_rounded, size: 80, color: color.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCameraFromSearch(_SearchResult result) async {
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
    final savedResult = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => CameraFindingScreen(
        lang: widget.lang, isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        selectedLocationName: result.name,
        selectedLocationId: idL, selectedUnitId: idU,
        selectedSubunitId: idS, selectedAreaId: idA,
        onFindingSaved: onSaved,
      ),
    ));

    if (!mounted) return;

    if (savedResult == true) {
      Navigator.pop(context, true);
    } else {
      CameraWarmupService.instance.warmUp();
    }
  }
}

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

// ignore: unused_field
enum _ItemBadge { none, myLocation, pic }