import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreFilterScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? initialLocationFilter;
  final String initialInspectionType;
  final String initialSortOrder;
  final String initialLocationName;
  final String initialJenisTemuan;

  const ExploreFilterScreen({
    super.key,
    required this.lang,
    required this.initialLocationFilter,
    required this.initialInspectionType,
    required this.initialSortOrder,
    required this.initialLocationName,
    required this.initialJenisTemuan,
  });

  @override
  State<ExploreFilterScreen> createState() => _ExploreFilterScreenState();
}

class _ExploreFilterScreenState extends State<ExploreFilterScreen> {
  late Map<String, dynamic>? tempLocationFilter;
  late String tempInspectionType;
  late String tempSortOrder;
  late String tempLocationName;
  late String tempJenisTemuan;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'filter_title': 'Urutkan & Filter Temuan',
      'filter_by': 'Filter berdasarkan',
      'lokasi_temuan': 'Lokasi temuan',
      'pilih_lokasi': 'Pilih Lokasi',
      'temuan_inspeksi': 'Temuan Inspeksi',
      'sort_by': 'Urutkan berdasarkan',
      'jenis_temuan': 'Jenis Temuan',
      'waktu': 'Waktu',
      'terlama': 'Temuan Terlama',
      'terbaru': 'Temuan Terbaru',
      'deadline': 'Deadline Terdekat',
      'reset': 'Reset',
      'terapkan': 'Terapkan',
      'filter_5r': 'Temuan 5R',
      'filter_kts': 'KTS Produksi',
    },
    'EN': {
      'filter_title': 'Sort & Filter Findings',
      'filter_by': 'Filter by',
      'lokasi_temuan': 'Finding Location',
      'pilih_lokasi': 'Select Location',
      'temuan_inspeksi': 'Inspection Finding',
      'sort_by': 'Sort by',
      'jenis_temuan': 'Finding Type',
      'waktu': 'Time',
      'terlama': 'Oldest Findings',
      'terbaru': 'Newest Findings',
      'deadline': 'Nearest Deadline',
      'reset': 'Reset',
      'terapkan': 'Apply',
      'filter_5r': '5R Findings',
      'filter_kts': 'KTS Production',
    },
    'ZH': {
      'filter_title': '排序和过滤发现',
      'filter_by': '过滤依据',
      'lokasi_temuan': '发现位置',
      'pilih_lokasi': '选择位置',
      'temuan_inspeksi': '检查发现',
      'sort_by': '排序依据',
      'jenis_temuan': '发现类型',
      'waktu': '时间',
      'terlama': '最旧的发现',
      'terbaru': '最新发现',
      'deadline': '最近的截止日期',
      'reset': '重置',
      'terapkan': '应用',
      'filter_5r': '5R发现',
      'filter_kts': 'KTS生产',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    tempLocationFilter = widget.initialLocationFilter;
    tempInspectionType = widget.initialInspectionType;
    tempSortOrder = widget.initialSortOrder;
    tempLocationName = widget.initialLocationName;
    tempJenisTemuan = widget.initialJenisTemuan;
  }

  @override
  Widget build(BuildContext context) {
    final inspLabel = {
      'ID': {'visitor': 'Visitor', 'eksekutif': 'Eksekutif', 'profesional': 'Profesional'},
      'EN': {'visitor': 'Visitor', 'eksekutif': 'Executive', 'profesional': 'Professional'},
      'ZH': {'visitor': '访客', 'eksekutif': '行政', 'profesional': '专业'},
    }[widget.lang] ?? {'visitor': 'Visitor', 'eksekutif': 'Executive', 'profesional': 'Professional'};

    const inspColors = {
      'visitor': Color(0xFF3B82F6),
      'eksekutif': Color(0xFFEF4444),
      'profesional': Color(0xFFF59E0B),
    };

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
              // HEADER + CLOSE BUTTON (X)
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
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        getTxt('filter_title'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
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

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _filterSectionHeader(getTxt('filter_by')),
                      const SizedBox(height: 14),

                      _filterLabel(getTxt('jenis_temuan')),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                tempJenisTemuan = tempJenisTemuan == '5r' ? '' : '5r';
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: tempJenisTemuan == '5r'
                                      ? const Color(0xFF38BDF8)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: tempJenisTemuan == '5r'
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                  boxShadow: tempJenisTemuan == '5r'
                                      ? [BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha:0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3))]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    getTxt('filter_5r'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: tempJenisTemuan == '5r'
                                          ? Colors.white
                                          : const Color(0xFF38BDF8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                tempJenisTemuan = tempJenisTemuan == 'kts' ? '' : 'kts';
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: tempJenisTemuan == 'kts'
                                      ? const Color(0xFFFBBF24)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: tempJenisTemuan == 'kts'
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                  boxShadow: tempJenisTemuan == 'kts'
                                      ? [BoxShadow(
                                          color: const Color(0xFFFBBF24).withValues(alpha:0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3))]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    getTxt('filter_kts'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: tempJenisTemuan == 'kts'
                                          ? Colors.white
                                          : const Color(0xFFFBBF24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      _filterLabel(getTxt('lokasi_temuan')),
                      GestureDetector(
                        onTap: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            barrierDismissible: true,
                            builder: (ctx) => FilterLocationBottomSheet(lang: widget.lang),
                          );
                          if (result != null) {
                            setState(() {
                              tempLocationFilter = result;
                              tempLocationName = result['name'];
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: tempLocationName.isEmpty ? Colors.white : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: tempLocationName.isEmpty
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF0284C7),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.maps_home_work_rounded,
                                size: 20,
                                color: const Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tempLocationName.isEmpty ? getTxt('pilih_lokasi') : tempLocationName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: tempLocationName.isEmpty ? FontWeight.normal : FontWeight.w600,
                                    color: tempLocationName.isEmpty ? Colors.grey : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (tempLocationName.isNotEmpty)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    tempLocationFilter = null;
                                    tempLocationName = '';
                                  }),
                                  child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                )
                              else
                                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0284C7), size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      _filterLabel(getTxt('temuan_inspeksi')),
                      Row(
                        children: ['visitor', 'eksekutif', 'profesional'].map((val) {
                          final isActive = tempInspectionType == val;
                          final color = inspColors[val]!;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                tempInspectionType = isActive ? '' : val;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: EdgeInsets.only(right: val != 'profesional' ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isActive ? color : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isActive ? color : const Color(0xFFCBD5E1), width: 1.5),
                                  boxShadow: isActive
                                      ? [BoxShadow(color: color.withValues(alpha:0.25), blurRadius: 8, offset: const Offset(0, 3))]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    inspLabel[val]!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isActive ? Colors.white : color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      _filterSectionHeader(getTxt('sort_by')),
                      const SizedBox(height: 14),

                      _filterLabel(getTxt('waktu')),
                      Column(
                        children: [
                          _buildSortOption(
                            value: 'terbaru',
                            label: getTxt('terbaru'),
                            icon: Icons.arrow_downward_rounded,
                            currentValue: tempSortOrder,
                            onTap: (v) => setState(() => tempSortOrder = v),
                          ),
                          const SizedBox(height: 8),
                          _buildSortOption(
                            value: 'terlama',
                            label: getTxt('terlama'),
                            icon: Icons.arrow_upward_rounded,
                            currentValue: tempSortOrder,
                            onTap: (v) => setState(() => tempSortOrder = v),
                          ),
                          const SizedBox(height: 8),
                          _buildSortOption(
                            value: 'deadline',
                            label: getTxt('deadline'),
                            icon: Icons.timer_rounded,
                            currentValue: tempSortOrder,
                            onTap: (v) => setState(() => tempSortOrder = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ACTION BUTTONS
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context, {'action': 'reset'});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.redAccent.withValues(alpha:0.3)),
                          ),
                          child: Center(
                            child: Text(
                              getTxt('reset'),
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context, {
                            'action': 'apply',
                            'locationFilter': tempLocationFilter,
                            'inspectionType': tempInspectionType,
                            'sortOrder': tempSortOrder,
                            'locationName': tempLocationName,
                            'jenisTemuan': tempJenisTemuan,
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha:0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              getTxt('terapkan'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterSectionHeader(String text) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _filterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSortOption({
    required String value,
    required String label,
    required IconData icon,
    required String currentValue,
    required Function(String) onTap,
  }) {
    final isActive = currentValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha:0.15), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0284C7) : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: isActive ? Colors.white : const Color(0xFF0284C7)),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0284C7) : const Color(0xFF334155),
              ),
            ),
            const Spacer(),
            if (isActive)
              const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF0284C7)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET POPUP FILTER LOKASI: HIERARKI LOKASI (bergaya ranking_location_filter)
// ============================================================================
class _LevelMeta {
  final IconData icon;
  final Color color;
  const _LevelMeta({required this.icon, required this.color});
}

class FilterLocationBottomSheet extends StatefulWidget {
  final String lang;
  const FilterLocationBottomSheet({super.key, required this.lang});

  @override
  State<FilterLocationBottomSheet> createState() => _FilterLocationBottomSheetState();
}

class _FilterLocationBottomSheetState extends State<FilterLocationBottomSheet> {
  int _level = 0;
  bool _isLoading = true;
  List<dynamic> _data = [];
  List<dynamic> _filtered = [];
  final List<Map<String, dynamic>> _history = [];
  final _searchCtrl = TextEditingController();

  static const _idCols = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'];
  static const _namCols = ['nama_lokasi', 'nama_unit', 'nama_subunit', 'nama_area'];

  static const List<_LevelMeta> _levelMeta = [
    _LevelMeta(icon: Icons.location_city_rounded, color: Color(0xFF10B981)), // Lokasi
    _LevelMeta(icon: Icons.business_rounded, color: Color(0xFF6366F1)),      // Unit
    _LevelMeta(icon: Icons.layers_rounded, color: Color(0xFFFBBF24)),        // Subunit
    _LevelMeta(icon: Icons.place_rounded, color: Color(0xFFF472B6)),         // Area
  ];

  String get _idCol => _idCols[_level];
  String get _nameCol => _namCols[_level];
  _LevelMeta get _currentMeta => _levelMeta[_level];

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_data)
          : _data.where((item) => item[_nameCol].toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _fetch({dynamic parentId}) async {
    setState(() => _isLoading = true);
    _searchCtrl.clear();
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];
      if (_level == 0) {
        data = await supabase
            .from('lokasi')
            .select('id_lokasi, nama_lokasi')
            .not('nama_lokasi', 'is', null)
            .order('nama_lokasi');
      } else if (_level == 1 && parentId != null) {
        data = await supabase
            .from('unit')
            .select('id_unit, nama_unit')
            .eq('id_lokasi', parentId.toString())
            .not('nama_unit', 'is', null)
            .order('nama_unit');
      } else if (_level == 2 && parentId != null) {
        data = await supabase
            .from('subunit')
            .select('id_subunit, nama_subunit')
            .eq('id_unit', parentId.toString())
            .not('nama_subunit', 'is', null)
            .order('nama_subunit');
      } else if (_level == 3 && parentId != null) {
        data = await supabase
            .from('area')
            .select('id_area, nama_area')
            .eq('id_subunit', parentId.toString())
            .not('nama_area', 'is', null)
            .order('nama_area');
      }
      if (mounted) {
        setState(() {
          _data = data;
          _filtered = List.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goDeeper(Map<String, dynamic> item) {
    if (_level >= 3) return;
    _history.add({'level': _level, 'id': item[_idCol], 'name': item[_nameCol]});
    setState(() => _level++);
    _fetch(parentId: item[_idCols[_level - 1]]);
  }

  void _select(Map<String, dynamic> item) {
    final parts = [..._history.map((h) => h['name'] as String), item[_nameCol].toString()];
    Navigator.pop(context, {
      'id': item[_idCol],
      'name': parts.join(' / '),
      'level': _level,
    });
  }

  void _goToLevel(int i) {
    final steps = _level - i;
    for (int s = 0; s < steps; s++) {
      if (_history.isNotEmpty) _history.removeLast();
    }
    setState(() => _level = i);
    _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
  }

  @override
  Widget build(BuildContext context) {
    final lvlLabels = {
      'EN': ['Location', 'Unit', 'Sub-Unit', 'Area'],
      'ID': ['Lokasi', 'Unit', 'Sub-Unit', 'Area'],
      'ZH': ['地点', '单位', '子单位', '区域'],
    };
    final labels = lvlLabels[widget.lang] ?? lvlLabels['ID']!;

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
              // Header + Tombol Back/Close
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _history.isEmpty
                          ? () => Navigator.pop(context)
                          : () => _goToLevel(_level - 1),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _history.isEmpty ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                          color: const Color(0xFF0284C7),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _history.isEmpty ? labels[_level] : _history.last['name'].toString(),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filtered.length}',
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),

              // Search + Breadcrumb Tabs (FIXED, tidak ikut scroll)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 10),
                    _buildBreadcrumbTabs(labels),
                  ],
                ),
              ),

              // List hasil (HANYA bagian ini yang scroll)
              Expanded(
                child: _isLoading
                    ? _buildShimmerList()
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              widget.lang == 'EN'
                                  ? 'No results found'
                                  : widget.lang == 'ZH'
                                      ? '未找到结果'
                                      : 'Tidak ada hasil ditemukan',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildItemCard(_filtered[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final hint = widget.lang == 'EN'
        ? 'Search...'
        : widget.lang == 'ZH'
            ? '搜索...'
            : 'Cari...';
    final isFocused = _searchCtrl.text.isNotEmpty;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isFocused ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
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
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
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
    );
  }

  Widget _buildBreadcrumbTabs(List<String> labels) {
    return Row(
      children: List.generate(4, (i) {
        final meta = _levelMeta[i];
        final isActive = i == _level;
        final isPast = i < _level;
        return Expanded(
          child: GestureDetector(
            onTap: isPast ? () => _goToLevel(i) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? meta.color
                    : isPast
                        ? meta.color.withValues(alpha: 0.12)
                        : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? meta.color
                      : isPast
                          ? meta.color.withValues(alpha: 0.4)
                          : const Color(0xFFE2E8F0),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: meta.color.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    meta.icon,
                    size: 15,
                    color: isActive
                        ? Colors.white
                        : isPast
                            ? meta.color
                            : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[i],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : isPast
                              ? meta.color
                              : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 16, width: 70, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final name = item[_nameCol]?.toString() ?? '-';
    final isLastLevel = _level == 3;
    final meta = _currentMeta;

    return GestureDetector(
      onTap: isLastLevel ? () => _select(item) : () => _goDeeper(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: meta.color.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meta.icon, color: meta.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: meta.color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      widget.lang == 'EN'
                          ? ['Location', 'Unit', 'Sub-Unit', 'Area'][_level]
                          : widget.lang == 'ZH'
                              ? ['地点', '单位', '子单位', '区域'][_level]
                              : ['Lokasi', 'Unit', 'Sub-Unit', 'Area'][_level],
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: meta.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _select(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: meta.color),
                ),
                child: Text(
                  widget.lang == 'EN'
                      ? 'Select'
                      : widget.lang == 'ZH'
                          ? '选择'
                          : 'Pilih',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: meta.color),
                ),
              ),
            ),
            if (!isLastLevel) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _goDeeper(item),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_right, color: meta.color, size: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}