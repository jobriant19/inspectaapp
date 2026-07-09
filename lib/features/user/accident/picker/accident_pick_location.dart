import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// POPUP PEMILIH LOKASI KEJADIAN (Accident Incident Location)
// Tampilan & interaksi identik dengan FindingLocationFilterScreen:
// tab Lokasi/Unit/Sub-Unit/Area bisa diklik bebas, setiap tab
// menampilkan SEMUA data level tsb, tap kartu = langsung pilih.
// ============================================================
class AccidentPickLocationScreen extends StatefulWidget {
  final String lang;
  const AccidentPickLocationScreen({super.key, required this.lang});

  @override
  State<AccidentPickLocationScreen> createState() =>
      _AccidentPickLocationScreenState();
}

class _AccidentPickLocationScreenState
    extends State<AccidentPickLocationScreen>
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
          raw = await supabase.from('lokasi')
              .select('id_lokasi, nama_lokasi, unit(id_unit)')
              .order('nama_lokasi');
          break;
        case 1:
          raw = await supabase.from('unit')
              .select('id_unit, nama_unit, id_lokasi, lokasi(nama_lokasi), subunit(id_subunit)')
              .order('nama_unit');
          break;
        case 2:
          raw = await supabase.from('subunit')
              .select('id_subunit, nama_subunit, id_unit, id_lokasi, unit(nama_unit), area(id_area)')
              .order('nama_subunit');
          break;
        case 3:
          raw = await supabase.from('area')
              .select('id_area, nama_area, id_subunit, id_unit, id_lokasi, subunit(nama_subunit), unit(nama_unit)')
              .order('nama_area');
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
      debugPrint('AccidentPickLocation load tab $tabIndex error: $e');
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

  // Hasil select membawa: id per level, nama (nama item terpilih),
  // nama_unit (untuk autofill Departemen Terdampak),
  // nama_spesifik + level (untuk render ikon di kolom Incident Location)
  void _selectItem({required int tabIndex, required Map<String, dynamic> raw}) {
    final result = <String, dynamic>{};
    String specific = '';

    switch (tabIndex) {
      case 0:
        result['id_lokasi'] = raw['id_lokasi'];
        specific = raw['nama_lokasi']?.toString() ?? '';
        break;
      case 1:
        result['id_lokasi'] = raw['id_lokasi'];
        result['id_unit'] = raw['id_unit'];
        specific = raw['nama_unit']?.toString() ?? '';
        result['nama_unit'] = specific;
        break;
      case 2:
        result['id_lokasi'] = raw['id_lokasi'];
        result['id_unit'] = raw['id_unit'];
        result['id_subunit'] = raw['id_subunit'];
        specific = raw['nama_subunit']?.toString() ?? '';
        result['nama_unit'] = raw['unit']?['nama_unit']?.toString();
        break;
      case 3:
        result['id_lokasi'] = raw['id_lokasi'];
        result['id_unit'] = raw['id_unit'];
        result['id_subunit'] = raw['id_subunit'];
        result['id_area'] = raw['id_area'];
        specific = raw['nama_area']?.toString() ?? '';
        result['nama_unit'] = raw['unit']?['nama_unit']?.toString();
        break;
    }

    result['nama'] = specific;
    result['nama_spesifik'] = specific;
    result['level'] = tabIndex;

    Navigator.pop(context, result);
  }

  Widget _buildItem({
    required int tabIndex,
    required Map<String, dynamic> raw,
    required String displayName,
  }) {
    final color = _tabColors[tabIndex];
    final labels = [_t('Lokasi', 'Location', '地点'), 'Unit', 'Sub-Unit', 'Area'];
    final IconData levelIcon = _tabIcons[tabIndex];

    Widget pill({required IconData icon, required String label, required Color pillColor}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: pillColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pillColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: pillColor),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: pillColor),
              ),
            ),
          ],
        ),
      );
    }

    String? breadcrumb;
    if (tabIndex == 1) breadcrumb = raw['lokasi']?['nama_lokasi']?.toString();
    if (tabIndex == 2) breadcrumb = raw['unit']?['nama_unit']?.toString();
    if (tabIndex == 3) breadcrumb = raw['subunit']?['nama_subunit']?.toString();

    Widget? breadcrumbPill;
    if (breadcrumb != null && breadcrumb.isNotEmpty && tabIndex > 0) {
      final parentColor = _tabColors[tabIndex - 1];
      breadcrumbPill = pill(icon: _tabIcons[tabIndex - 1], label: breadcrumb, pillColor: parentColor);
    }

    Widget? subCountPill;
    switch (tabIndex) {
      case 0:
        final units = raw['unit'] as List?;
        subCountPill = pill(icon: _tabIcons[1], label: '${units?.length ?? 0} Unit', pillColor: _tabColors[1]);
        break;
      case 1:
        final subunits = raw['subunit'] as List?;
        subCountPill = pill(icon: _tabIcons[2], label: '${subunits?.length ?? 0} Sub-Unit', pillColor: _tabColors[2]);
        break;
      case 2:
        final areas = raw['area'] as List?;
        subCountPill = pill(icon: _tabIcons[3], label: '${areas?.length ?? 0} Area', pillColor: _tabColors[3]);
        break;
      default:
        subCountPill = null;
    }

    return GestureDetector(
      onTap: () => _selectItem(tabIndex: tabIndex, raw: raw),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                child: Container(
                  width: 80,
                  color: color.withValues(alpha: 0.1),
                  child: Center(child: Icon(levelIcon, color: color, size: 28)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                          height: 1.25,
                        ),
                      ),
                      if (breadcrumbPill != null) ...[
                        const SizedBox(height: 6),
                        breadcrumbPill,
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          pill(icon: levelIcon, label: labels[tabIndex], pillColor: color),
                          if (subCountPill != null) subCountPill,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Center(child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right_rounded, color: color, size: 20),
              )),
            ],
          ),
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
                decoration: BoxDecoration(color: const Color(0xFF1D72F3).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Text('${entry.value.length}',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1D72F3))),
              ),
            ]),
          ),
          for (final r in entry.value)
            _buildItem(tabIndex: r.tabIndex, raw: r.raw, displayName: r.name),
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
      final color = _tabColors[tabIndex];
      final emptyMessages = [
        _t('Lokasi tidak ditemukan', 'Location not found', '未找到位置'),
        _t('Unit tidak ditemukan', 'Unit not found', '未找到单位'),
        _t('Subunit tidak ditemukan', 'Subunit not found', '未找到子单位'),
        _t('Area tidak ditemukan', 'Area not found', '未找到区域'),
      ];
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 80, color: color.withValues(alpha: 0.55)),
              const SizedBox(height: 16),
              Text(
                emptyMessages[tabIndex],
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: color),
                textAlign: TextAlign.center,
              ),
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
    final (idKey, nameKey) = keys[tabIndex];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final item = data[i];
        final name = item[nameKey]?.toString() ?? '';
        return _buildItem(tabIndex: tabIndex, raw: item, displayName: name);
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
                      child: Text(
                        _t('PILIH LOKASI', 'SELECT LOCATION', '选择地点'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1D72F3),
                        ),
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
                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
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