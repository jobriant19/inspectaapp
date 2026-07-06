import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FindingLocationFilterScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final String userRole;
  final String? userLokasiId;
  final String? userUnitId;
  final String? userSubunitId;
  final String? userAreaId;

  final String? preSelectedLokasiId;
  final String? preSelectedUnitId;
  final String? preSelectedSubunitId;
  final String? preSelectedAreaId;

  const FindingLocationFilterScreen({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.userRole,
    this.userLokasiId,
    this.userUnitId,
    this.userSubunitId,
    this.userAreaId,
    this.preSelectedLokasiId,
    this.preSelectedUnitId,
    this.preSelectedSubunitId,
    this.preSelectedAreaId,
  });

  @override
  State<FindingLocationFilterScreen> createState() =>
      _FindingLocationFilterScreenState();
}

class _FindingLocationFilterScreenState
    extends State<FindingLocationFilterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>>? _lokasiData;
  List<Map<String, dynamic>>? _unitData;
  List<Map<String, dynamic>>? _subunitData;
  List<Map<String, dynamic>>? _areaData;

  List<_LocationSearchResult>? _searchResults;
  bool _isSearching = false;

  final _loading = {0: false, 1: false, 2: false, 3: false};

  bool get _isProAccess => widget.isProMode || widget.userRole == 'Eksekutif';

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  static const _tabIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_outlined,
    Icons.place_rounded,
  ];

  static const List<Color> _tabColors = [
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this)..addListener(_onTabChanged);
    _searchCtrl.addListener(_onSearchChanged);
    for (int i = 0; i < 4; i++) {
      _loadTabData(i);
    }
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    _loadTabData(_tabCtrl.index);
  }

  Future<void> _loadTabData(int tabIndex) async {
    if (_getDataForTab(tabIndex) != null) return;

    setState(() => _loading[tabIndex] = true);

    try {
      final supabase = Supabase.instance.client;
      List<dynamic> raw = [];

      switch (tabIndex) {
        case 0:
          if (_isProAccess) {
            raw = await supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
          } else if (widget.userLokasiId != null) {
            raw = await supabase.from('lokasi').select('id_lokasi, nama_lokasi').eq('id_lokasi', widget.userLokasiId!);
          }
          break;

        case 1:
          if (_isProAccess) {
            raw = await supabase.from('unit').select('id_unit, nama_unit, id_lokasi').order('nama_unit');
          } else if (widget.userLokasiId != null) {
            if (widget.userUnitId != null) {
              raw = await supabase.from('unit').select('id_unit, nama_unit, id_lokasi')
                  .eq('id_lokasi', widget.userLokasiId!).eq('id_unit', widget.userUnitId!).order('nama_unit');
            } else {
              raw = await supabase.from('unit').select('id_unit, nama_unit, id_lokasi')
                  .eq('id_lokasi', widget.userLokasiId!).order('nama_unit');
            }
          }
          break;

        case 2:
          if (_isProAccess) {
            raw = await supabase.from('subunit').select('id_subunit, nama_subunit, id_unit, id_lokasi').order('nama_subunit');
          } else if (widget.userLokasiId != null) {
            var q = supabase.from('subunit').select('id_subunit, nama_subunit, id_unit, id_lokasi')
                .eq('id_lokasi', widget.userLokasiId!);
            if (widget.userUnitId != null) q = q.eq('id_unit', widget.userUnitId!);
            if (widget.userSubunitId != null) q = q.eq('id_subunit', widget.userSubunitId!);
            raw = await q.order('nama_subunit');
          }
          break;

        case 3:
          if (_isProAccess) {
            raw = await supabase.from('area').select('id_area, nama_area, id_subunit, id_unit, id_lokasi').order('nama_area');
          } else if (widget.userLokasiId != null) {
            var q = supabase.from('area').select('id_area, nama_area, id_subunit, id_unit, id_lokasi')
                .eq('id_lokasi', widget.userLokasiId!);
            if (widget.userUnitId != null) q = q.eq('id_unit', widget.userUnitId!);
            if (widget.userSubunitId != null) q = q.eq('id_subunit', widget.userSubunitId!);
            if (widget.userAreaId != null) q = q.eq('id_area', widget.userAreaId!);
            raw = await q.order('nama_area');
          }
          break;
      }

      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(raw);
      setState(() {
        switch (tabIndex) {
          case 0: _lokasiData = list; break;
          case 1: _unitData = list; break;
          case 2: _subunitData = list; break;
          case 3: _areaData = list; break;
        }
        _loading[tabIndex] = false;
      });
    } catch (e) {
      debugPrint('Error load tab $tabIndex: $e');
      if (mounted) setState(() => _loading[tabIndex] = false);
    }
  }

  List<Map<String, dynamic>>? _getDataForTab(int index) {
    return [_lokasiData, _unitData, _subunitData, _areaData][index];
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _onSearchChanged() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() { _searchResults = null; _isSearching = false; });
      return;
    }

    setState(() => _isSearching = true);

    for (int i = 0; i < 4; i++) {
      await _loadTabData(i);
    }

    final qLow = q.toLowerCase();
    final results = <_LocationSearchResult>[];

    void addFromList(List<Map<String, dynamic>>? data, int tabIndex, String idKey, String nameKey, String levelLabel) {
      if (data == null) return;
      for (final item in data) {
        final name = (item[nameKey] ?? '').toString();
        if (name.toLowerCase().contains(qLow)) {
          results.add(_LocationSearchResult(
            tabIndex: tabIndex,
            id: item[idKey]?.toString() ?? '',
            name: name,
            levelLabel: levelLabel,
            raw: item,
          ));
        }
      }
    }

    addFromList(_lokasiData, 0, 'id_lokasi', 'nama_lokasi', _t('Lokasi', 'Location', '地点'));
    addFromList(_unitData, 1, 'id_unit', 'nama_unit', 'Unit');
    addFromList(_subunitData, 2, 'id_subunit', 'nama_subunit', 'Sub-Unit');
    addFromList(_areaData, 3, 'id_area', 'nama_area', 'Area');

    if (mounted) setState(() { _searchResults = results; _isSearching = false; });
  }

  void _selectItem({required int tabIndex, required Map<String, dynamic> raw}) {
    final Map<String, dynamic> result = {};
    final parts = <String>[];

    switch (tabIndex) {
      case 0:
        result['id_lokasi'] = raw['id_lokasi'];
        parts.add(raw['nama_lokasi'] ?? '');
        break;
      case 1:
        result['id_lokasi'] = raw['id_lokasi'];
        result['id_unit'] = raw['id_unit'];
        parts.add(raw['nama_unit'] ?? '');
        break;
      case 2:
        result['id_lokasi'] = raw['id_lokasi'];
        result['id_unit'] = raw['id_unit'];
        result['id_subunit'] = raw['id_subunit'];
        parts.add(raw['nama_subunit'] ?? '');
        break;
      case 3:
        result['id_lokasi'] = raw['id_lokasi'];
        result['id_unit'] = raw['id_unit'];
        result['id_subunit'] = raw['id_subunit'];
        result['id_area'] = raw['id_area'];
        parts.add(raw['nama_area'] ?? '');
        break;
    }

    result['nama'] = parts.join(' / ');
    Navigator.pop(context, result);
  }

  Widget _buildItem({
    required int tabIndex,
    required Map<String, dynamic> raw,
    required String displayName,
    required bool isSelected,
  }) {
    final color = _tabColors[tabIndex];
    final labels = [_t('Lokasi', 'Location', '地点'), 'Unit', 'Sub-Unit', 'Area'];
    final initials = displayName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return GestureDetector(
      onTap: () => _selectItem(tabIndex: tabIndex, raw: raw),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF1D72F3) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha:0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                initials,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha:0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tabIcons[tabIndex], size: 10, color: color),
                        const SizedBox(width: 3),
                        Text(
                          labels[tabIndex],
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return _buildShimmerList();
    }

    final results = _searchResults ?? [];
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 44, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(_t('Tidak ada hasil', 'No results found', '没有结果'),
                  style: GoogleFonts.inter(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    final labels = [_t('Lokasi', 'Location', '地点'), 'Unit', 'Sub-Unit', 'Area'];
    final grouped = <int, List<_LocationSearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.tabIndex, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Row(children: [
              Icon(_tabIcons[entry.key], size: 13, color: const Color(0xFF1D72F3)),
              const SizedBox(width: 6),
              Text(labels[entry.key],
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF1D72F3).withValues(alpha:0.08), borderRadius: BorderRadius.circular(10)),
                child: Text('${entry.value.length}',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1D72F3))),
              ),
            ]),
          ),
          for (final r in entry.value)
            _buildItem(tabIndex: r.tabIndex, raw: r.raw, displayName: r.name, isSelected: false),
        ],
      ],
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final isLoading = _loading[tabIndex] == true;
    final data = _getDataForTab(tabIndex);

    if (isLoading || data == null) {
      return _buildShimmerList();
    }

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 44, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(_t('Data tidak tersedia', 'No data available', '没有数据'),
                  style: GoogleFonts.inter(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    final keys = [
      ('id_lokasi', 'nama_lokasi'),
      ('id_unit', 'nama_unit'),
      ('id_subunit', 'nama_subunit'),
      ('id_area', 'nama_area'),
    ];
    final preSelected = [
      widget.preSelectedLokasiId,
      widget.preSelectedUnitId,
      widget.preSelectedSubunitId,
      widget.preSelectedAreaId,
    ];
    final (idKey, nameKey) = keys[tabIndex];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final item = data[i];
        final id = item[idKey]?.toString() ?? '';
        final name = item[nameKey]?.toString() ?? '';
        return _buildItem(
          tabIndex: tabIndex,
          raw: item,
          displayName: name,
          isSelected: id == preSelected[tabIndex],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearchActive = _searchCtrl.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 480,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_rounded, color: Color(0xFF1D72F3), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('PILIH LOKASI', 'SELECT LOCATION', '选择地点'),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1D72F3),
                            ),
                          ),
                          if (!_isProAccess)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D72F3).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF1D72F3).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.my_location_rounded,
                                      size: 11, color: Color(0xFF1D72F3)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _t('Lokasi Saya', 'My Location', '我的位置'),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1D72F3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),

              // TABS
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AnimatedBuilder(
                  animation: _tabCtrl,
                  builder: (context, _) {
                    final labels = [_t('Lokasi', 'Location', '地点'), 'Unit', 'Sub-Unit', 'Area'];
                    return Row(
                      children: List.generate(4, (index) {
                        final isActive = _tabCtrl.index == index;
                        final color = _tabColors[index];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _tabCtrl.animateTo(index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive ? color : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isActive ? color : const Color(0xFFE2E8F0)),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha:0.30),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_tabIcons[index], size: 15, color: isActive ? Colors.white : color),
                                  const SizedBox(height: 3),
                                  Text(
                                    labels[index],
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isActive ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              Container(height: 1, color: const Color(0xFFF1F5F9)),

              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSearchActive ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0284C7)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0C4A6E)),
                          decoration: InputDecoration(
                            hintText: _t(
                              'Cari lokasi, unit, sub-unit, area...',
                              'Search location, unit, sub-unit, area...',
                              '搜索地点、单位、子单位、区域...',
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ),
                      if (isSearchActive)
                        GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha:0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0284C7)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Container(height: 1, color: const Color(0xFFF1F5F9)),

              // CONTENT
              Expanded(
                child: isSearchActive
                    ? _buildSearchResults()
                    : TabBarView(
                        controller: _tabCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(4, _buildTabContent),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSearchResult {
  final int tabIndex;
  final String id;
  final String name;
  final String levelLabel;
  final Map<String, dynamic> raw;

  const _LocationSearchResult({
    required this.tabIndex,
    required this.id,
    required this.name,
    required this.levelLabel,
    required this.raw,
  });
}