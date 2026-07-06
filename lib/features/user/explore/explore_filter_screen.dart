import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'explore_location_filter.dart';
import 'explore_section_filter.dart';
import 'explore_factor_filter.dart';

class ExploreFilterScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? initialLocationFilter;
  final String initialInspectionType;
  final String initialSortOrder;
  final String initialLocationName;
  final String initialJenisTemuan;
  final Map<String, dynamic>? initialSectionFilter;
  final String initialSectionName;
  final Map<String, dynamic>? initialCauseFactor;

  const ExploreFilterScreen({
    super.key,
    required this.lang,
    required this.initialLocationFilter,
    required this.initialInspectionType,
    required this.initialSortOrder,
    required this.initialLocationName,
    required this.initialJenisTemuan,
    this.initialSectionFilter,
    this.initialSectionName = '',
    this.initialCauseFactor,
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

  // ── State baru khusus KTS Production ──
  late Map<String, dynamic>? tempSectionFilter;
  late String tempSectionName;
  late Map<String, dynamic>? tempCauseFactor;

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
      'kuantitas': 'Kuantitas Terbanyak',
      'reset': 'Reset',
      'terapkan': 'Terapkan',
      'filter_5r': 'Temuan 5R',
      'filter_kts': 'KTS Produksi',
      'section_penyebab': 'Section Penyebab',
      'pilih_section': 'Pilih Section',
      'cause_factor': 'Faktor Penyebab',
      'pilih_faktor': 'Pilih Faktor Penyebab',
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
      'kuantitas': 'Most Quantity',
      'reset': 'Reset',
      'terapkan': 'Apply',
      'filter_5r': '5R Findings',
      'filter_kts': 'KTS Production',
      'section_penyebab': 'Cause Section',
      'pilih_section': 'Select Section',
      'cause_factor': 'Cause Factor',
      'pilih_faktor': 'Select Cause Factor',
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
      'kuantitas': '数量最多',
      'reset': '重置',
      'terapkan': '应用',
      'filter_5r': '5R发现',
      'filter_kts': 'KTS生产',
      'section_penyebab': '原因部门',
      'pilih_section': '选择部门',
      'cause_factor': '原因因素',
      'pilih_faktor': '选择原因因素',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  bool get _isKts => tempJenisTemuan == 'kts';

  @override
  void initState() {
    super.initState();
    tempLocationFilter = widget.initialLocationFilter;
    tempInspectionType = widget.initialInspectionType;
    tempSortOrder = widget.initialSortOrder;
    tempLocationName = widget.initialLocationName;
    // Default: 5R Findings jika belum ada nilai (mis. pertama kali dibuka)
    tempJenisTemuan = widget.initialJenisTemuan.isEmpty ? '5r' : widget.initialJenisTemuan;
    tempSectionFilter = widget.initialSectionFilter;
    tempSectionName = widget.initialSectionName;
    tempCauseFactor = widget.initialCauseFactor;
  }

  void _setJenisTemuan(String value) {
    setState(() {
      final newValue = tempJenisTemuan == value ? '' : value;
      tempJenisTemuan = newValue;

      if (newValue == 'kts') {
        // Pindah ke KTS -> bersihkan filter lokasi & inspeksi (khusus 5R)
        tempLocationFilter = null;
        tempLocationName = '';
        tempInspectionType = '';
      } else {
        // Pindah ke 5R / kosong -> bersihkan filter section & faktor (khusus KTS)
        tempSectionFilter = null;
        tempSectionName = '';
        tempCauseFactor = null;
      }
    });
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
                              onTap: () => _setJenisTemuan('5r'),
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
                              onTap: () => _setJenisTemuan('kts'),
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

                      // ── FINDING LOCATION (5R) atau SECTION CAUSE (KTS) ──
                      _filterLabel(_isKts ? getTxt('section_penyebab') : getTxt('lokasi_temuan')),
                      _isKts ? _buildSectionTile() : _buildLocationTile(),
                      const SizedBox(height: 18),

                      // ── INSPECTION FINDING (5R) atau CAUSE FACTOR (KTS) ──
                      _filterLabel(_isKts ? getTxt('cause_factor') : getTxt('temuan_inspeksi')),
                      _isKts
                          ? _buildCauseFactorTile()
                          : Row(
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
                          // Untuk KTS Production, opsi ini menjadi "Kuantitas Terbanyak"
                          _buildSortOption(
                            value: 'deadline',
                            label: _isKts ? getTxt('kuantitas') : getTxt('deadline'),
                            icon: _isKts ? Icons.leaderboard_rounded : Icons.timer_rounded,
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
                            'sectionFilter': tempSectionFilter,
                            'sectionName': tempSectionName,
                            'causeFactor': tempCauseFactor,
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

  // ── Tile Finding Location (5R, perilaku original dipertahankan) ──
  Widget _buildLocationTile() {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          builder: (ctx) => ExploreLocationFilterScreen(lang: widget.lang),
        );
        if (result != null) {
          setState(() {
            if (result['clear'] == true) {
              tempLocationFilter = null;
              tempLocationName = '';
            } else {
              tempLocationFilter = result;
              tempLocationName = result['name'];
            }
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
            const Icon(
              Icons.maps_home_work_rounded,
              size: 20,
              color: Color(0xFF0284C7),
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
                onTap: () {
                  Navigator.pop(context, {'action': 'reset'});
                },
                child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0284C7), size: 16),
          ],
        ),
      ),
    );
  }

  // ── Tile Section Cause (KTS Production) ──
  Widget _buildSectionTile() {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          builder: (ctx) => ExploreSectionFilterScreen(lang: widget.lang),
        );
        if (result != null) {
          setState(() {
            tempSectionFilter = result;
            tempSectionName = result['name'];
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: tempSectionName.isEmpty ? Colors.white : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tempSectionName.isEmpty
                ? const Color(0xFFCBD5E1)
                : const Color(0xFFD97706),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.square_foot_rounded,
              size: 20,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tempSectionName.isEmpty ? getTxt('pilih_section') : tempSectionName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: tempSectionName.isEmpty ? FontWeight.normal : FontWeight.w600,
                  color: tempSectionName.isEmpty ? Colors.grey : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tempSectionName.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, {'action': 'reset'});
                },
                child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD97706), size: 16),
          ],
        ),
      ),
    );
  }

  // ── Tile Cause Factor (KTS Production) ──
  Widget _buildCauseFactorTile() {
    final hasValue = tempCauseFactor != null && (tempCauseFactor!['name']?.toString().isNotEmpty ?? false);
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          builder: (ctx) => ExploreFactorFilterScreen(lang: widget.lang),
        );
        if (result != null) {
          setState(() {
            tempCauseFactor = result;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.category_rounded,
              size: 20,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? tempCauseFactor!['name'].toString() : getTxt('pilih_faktor'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? const Color(0xFF0F172A) : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context, {'action': 'reset'});
                },
                child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD97706), size: 16),
          ],
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