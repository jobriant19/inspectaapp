import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserLocationSelection {
  final String? idLokasi;
  final String? namaLokasi;
  final String? idUnit;
  final String? namaUnit;
  final String? idSubunit;
  final String? namaSubunit;
  final String? idArea;
  final String? namaArea;

  const AdminUserLocationSelection({
    this.idLokasi,
    this.namaLokasi,
    this.idUnit,
    this.namaUnit,
    this.idSubunit,
    this.namaSubunit,
    this.idArea,
    this.namaArea,
  });

  bool get isEmpty => idLokasi == null;
}

const List<String> _pickLevels = ['Lokasi', 'Unit', 'Subunit', 'Area'];

const List<Color> _pickLevelColors = [
  Color(0xFF10B981),
  Color(0xFF6366F1),
  Color(0xFFFBBF24),
  Color(0xFFF472B6),
];

IconData _pickLevelIcon(String level) {
  switch (level) {
    case 'Unit':
      return Icons.business_rounded;
    case 'Subunit':
      return Icons.layers_rounded;
    case 'Area':
      return Icons.place_rounded;
    default:
      return Icons.location_city_rounded;
  }
}

String _pickLevelLabel(String level, String lang) {
  switch (level) {
    case 'Unit':
      return lang == 'ZH' ? '部门' : 'Unit';
    case 'Subunit':
      return lang == 'ZH' ? '子部门' : 'Sub-Unit';
    case 'Area':
      return lang == 'ZH' ? '区域' : 'Area';
    default:
      return lang == 'EN' ? 'Location' : lang == 'ZH' ? '位置' : 'Lokasi';
  }
}

const Map<String, String> _pickTableByLevel = {
  'Lokasi': 'lokasi',
  'Unit': 'unit',
  'Subunit': 'subunit',
  'Area': 'area',
};
const Map<String, String> _pickIdColByLevel = {
  'Lokasi': 'id_lokasi',
  'Unit': 'id_unit',
  'Subunit': 'id_subunit',
  'Area': 'id_area',
};
const Map<String, String> _pickNameColByLevel = {
  'Lokasi': 'nama_lokasi',
  'Unit': 'nama_unit',
  'Subunit': 'nama_subunit',
  'Area': 'nama_area',
};
const Map<String, String> _pickParentColByLevel = {
  'Unit': 'id_lokasi',
  'Subunit': 'id_unit',
  'Area': 'id_subunit',
};

Future<AdminUserLocationSelection> resolveAdminUserLocationSelection({
  String? idLokasi,
  String? idUnit,
  String? idSubunit,
  String? idArea,
}) async {
  final supabase = Supabase.instance.client;
  String? namaLokasi, namaUnit, namaSubunit, namaArea;

  try {
    if (idLokasi != null) {
      final res = await supabase
          .from('lokasi')
          .select('nama_lokasi')
          .eq('id_lokasi', idLokasi)
          .maybeSingle();
      namaLokasi = res?['nama_lokasi'] as String?;
    }
    if (idUnit != null) {
      final res = await supabase
          .from('unit')
          .select('nama_unit')
          .eq('id_unit', idUnit)
          .maybeSingle();
      namaUnit = res?['nama_unit'] as String?;
    }
    if (idSubunit != null) {
      final res = await supabase
          .from('subunit')
          .select('nama_subunit')
          .eq('id_subunit', idSubunit)
          .maybeSingle();
      namaSubunit = res?['nama_subunit'] as String?;
    }
    if (idArea != null) {
      final res = await supabase
          .from('area')
          .select('nama_area')
          .eq('id_area', idArea)
          .maybeSingle();
      namaArea = res?['nama_area'] as String?;
    }
  } catch (e) {
    debugPrint('Error resolving location selection: $e');
  }

  return AdminUserLocationSelection(
    idLokasi: idLokasi,
    namaLokasi: namaLokasi,
    idUnit: idUnit,
    namaUnit: namaUnit,
    idSubunit: idSubunit,
    namaSubunit: namaSubunit,
    idArea: idArea,
    namaArea: namaArea,
  );
}

Future<AdminUserLocationSelection?> showAdminUserPickLocationDialog(
  BuildContext context, {
  required String lang,
  AdminUserLocationSelection? initial,
  int targetLevel = 0,
}) {
  return showDialog<AdminUserLocationSelection>(
    context: context,
    builder: (ctx) => _AdminUserPickLocationDialog(
      lang: lang,
      initial: initial ?? const AdminUserLocationSelection(),
      targetLevel: targetLevel,
    ),
  );
}

class _AdminUserPickLocationDialog extends StatefulWidget {
  final String lang;
  final AdminUserLocationSelection initial;
  final int targetLevel;

  const _AdminUserPickLocationDialog({
    required this.lang,
    required this.initial,
    this.targetLevel = 0,
  });

  @override
  State<_AdminUserPickLocationDialog> createState() =>
      _AdminUserPickLocationDialogState();
}

class _AdminUserPickLocationDialogState
    extends State<_AdminUserPickLocationDialog> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  String? _idLokasi, _namaLokasi;
  String? _idUnit, _namaUnit;
  String? _idSubunit, _namaSubunit;
  String? _idArea, _namaArea;

  int _activeLevel = 0;
  int _unlockedUpTo = 0;

  final Map<String, List<Map<String, String>>> _dataByLevel = {
    'Lokasi': [],
    'Unit': [],
    'Subunit': [],
    'Area': [],
  };

  bool _loadingLokasi = true;
  bool _loadingChild = false;

  String get _lang => widget.lang;

  @override
  void initState() {
    super.initState();
    _idLokasi = widget.initial.idLokasi;
    _namaLokasi = widget.initial.namaLokasi;
    _idUnit = widget.initial.idUnit;
    _namaUnit = widget.initial.namaUnit;
    _idSubunit = widget.initial.idSubunit;
    _namaSubunit = widget.initial.namaSubunit;
    _idArea = widget.initial.idArea;
    _namaArea = widget.initial.namaArea;

    if (_idArea != null || _idSubunit != null) {
      _unlockedUpTo = 3;
    } else if (_idUnit != null) {
      _unlockedUpTo = 2;
    } else if (_idLokasi != null) {
      _unlockedUpTo = 1;
    }
    _activeLevel = widget.targetLevel.clamp(0, _unlockedUpTo);

    _searchCtrl.addListener(() => setState(() {}));
    _initialLoad();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    await _fetchLevel('Lokasi');
    if (mounted) setState(() => _loadingLokasi = false);
    if (_idLokasi != null) await _fetchLevel('Unit', parentId: _idLokasi);
    if (_idUnit != null) await _fetchLevel('Subunit', parentId: _idUnit);
    if (_idSubunit != null) await _fetchLevel('Area', parentId: _idSubunit);
  }

  Future<void> _fetchLevel(String level, {String? parentId}) async {
    final table = _pickTableByLevel[level]!;
    final idCol = _pickIdColByLevel[level]!;
    final nameCol = _pickNameColByLevel[level]!;
    final parentCol = _pickParentColByLevel[level];
    try {
      final res = (parentCol != null && parentId != null)
          ? await _supabase
              .from(table)
              .select('$idCol, $nameCol')
              .eq(parentCol, parentId)
              .order(nameCol)
          : await _supabase.from(table).select('$idCol, $nameCol').order(nameCol);
      final list = List<Map<String, dynamic>>.from(res)
          .map((e) => {
                'id': e[idCol]?.toString() ?? '',
                'name': e[nameCol]?.toString() ?? '-',
              })
          .toList();
      if (mounted) setState(() => _dataByLevel[level] = list);
    } catch (e) {
      debugPrint('Error fetch $level (pick location): $e');
    }
  }

  void _onTabTap(int level) {
    if (level > _unlockedUpTo) return;
    setState(() {
      _activeLevel = level;
      _searchCtrl.clear();
    });
  }

  Future<void> _selectItem(Map<String, String> item) async {
    switch (_activeLevel) {
      case 0:
        setState(() {
          _idLokasi = item['id'];
          _namaLokasi = item['name'];
          _idUnit = _namaUnit = null;
          _idSubunit = _namaSubunit = null;
          _idArea = _namaArea = null;
          _dataByLevel['Unit'] = [];
          _dataByLevel['Subunit'] = [];
          _dataByLevel['Area'] = [];
          _unlockedUpTo = 1;
          _activeLevel = 1;
          _loadingChild = true;
        });
        await _fetchLevel('Unit', parentId: _idLokasi);
        if (mounted) setState(() => _loadingChild = false);
        break;
      case 1:
        setState(() {
          _idUnit = item['id'];
          _namaUnit = item['name'];
          _idSubunit = _namaSubunit = null;
          _idArea = _namaArea = null;
          _dataByLevel['Subunit'] = [];
          _dataByLevel['Area'] = [];
          _unlockedUpTo = 2;
          _activeLevel = 2;
          _loadingChild = true;
        });
        await _fetchLevel('Subunit', parentId: _idUnit);
        if (mounted) setState(() => _loadingChild = false);
        break;
      case 2:
        setState(() {
          _idSubunit = item['id'];
          _namaSubunit = item['name'];
          _idArea = _namaArea = null;
          _dataByLevel['Area'] = [];
          _unlockedUpTo = 3;
          _activeLevel = 3;
          _loadingChild = true;
        });
        await _fetchLevel('Area', parentId: _idSubunit);
        if (mounted) setState(() => _loadingChild = false);
        break;
      case 3:
        setState(() {
          _idArea = item['id'];
          _namaArea = item['name'];
        });
        Navigator.pop(context, _buildResult());
        break;
    }
  }

  AdminUserLocationSelection _buildResult() => AdminUserLocationSelection(
        idLokasi: _idLokasi,
        namaLokasi: _namaLokasi,
        idUnit: _idUnit,
        namaUnit: _namaUnit,
        idSubunit: _idSubunit,
        namaSubunit: _namaSubunit,
        idArea: _idArea,
        namaArea: _namaArea,
      );

  String? _selectedIdForLevel(int level) {
    switch (level) {
      case 0:
        return _idLokasi;
      case 1:
        return _idUnit;
      case 2:
        return _idSubunit;
      case 3:
        return _idArea;
      default:
        return null;
    }
  }

  String get _title {
    switch (_lang) {
      case 'EN':
        return 'Location Assignment';
      case 'ZH':
        return '位置分配';
      default:
        return 'Penempatan Lokasi';
    }
  }

  String get _searchHint {
    switch (_lang) {
      case 'EN':
        return 'Search...';
      case 'ZH':
        return '搜索...';
      default:
        return 'Cari...';
    }
  }

  String get _emptyLabel {
    switch (_lang) {
      case 'EN':
        return 'No data at this level';
      case 'ZH':
        return '该级别没有数据';
      default:
        return 'Tidak ada data pada level ini';
    }
  }

  String get _lockedHint {
    switch (_lang) {
      case 'EN':
        return 'Select the previous level first';
      case 'ZH':
        return '请先选择上一级';
      default:
        return 'Pilih level sebelumnya terlebih dahulu';
    }
  }

  String get _finishLabel {
    switch (_lang) {
      case 'EN':
        return 'Done';
      case 'ZH':
        return '完成';
      default:
        return 'Selesai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _pickLevels[_activeLevel];
    final q = _searchCtrl.text.trim().toLowerCase();
    final rawList = _dataByLevel[level] ?? [];
    final filtered = q.isEmpty
        ? rawList
        : rawList.where((e) => e['name']!.toLowerCase().contains(q)).toList();
    final selectedId = _selectedIdForLevel(_activeLevel);
    final screenHeight = MediaQuery.of(context).size.height;
    final isLocked = _activeLevel > _unlockedUpTo;
    final canFinish = _idLokasi != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 340,
        height: screenHeight * 0.72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEF2FF), width: 1.5),
        ),
        child: Column(children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map,
                    color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF6366F1),
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
                  child: const Icon(Icons.close_rounded,
                      color: Color(0xFF64748B), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // TAB LEVEL (terkunci berurutan)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: List.generate(_pickLevels.length, (index) {
                final lvl = _pickLevels[index];
                final isActive = index == _activeLevel;
                final isUnlocked = index <= _unlockedUpTo;
                final color = _pickLevelColors[index];
                final hasSelection = _selectedIdForLevel(index) != null;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTap(index),
                    child: Opacity(
                      opacity: isUnlocked ? 1 : 0.4,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? color : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isActive ? color : const Color(0xFFE2E8F0)),
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
                            Icon(
                              isUnlocked
                                  ? _pickLevelIcon(lvl)
                                  : Icons.lock_outline_rounded,
                              size: 15,
                              color: isActive ? Colors.white : color,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _pickLevelLabel(lvl, _lang),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    isActive ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                            if (hasSelection) ...[
                              const SizedBox(height: 2),
                              Icon(Icons.check_circle_rounded,
                                  size: 10,
                                  color: isActive ? Colors.white : color),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),

          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    width: 1.3),
              ),
              child: TextField(
                controller: _searchCtrl,
                enabled: !isLocked,
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E3A8A)),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFBDBDBD)),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF6366F1), size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // LIST
          Expanded(
            child: isLocked
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _lockedHint,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, color: const Color(0xFF64748B)),
                      ),
                    ),
                  )
                : (_loadingLokasi || _loadingChild)
                    ? _buildShimmerList()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                        children: [
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(_emptyLabel,
                                    style: const TextStyle(
                                        fontSize: 12.5, color: Color(0xFF64748B))),
                              ),
                            )
                          else
                            ...filtered.map((item) => _buildItemCard(
                                  item,
                                  isSelected: item['id'] == selectedId,
                                  color: _pickLevelColors[_activeLevel],
                                  icon: _pickLevelIcon(level),
                                )),
                        ],
                      ),
          ),

          // FOOTER - Selesai
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canFinish
                    ? () => Navigator.pop(context, _buildResult())
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _finishLabel,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
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

  Widget _buildItemCard(
    Map<String, String> item, {
    required bool isSelected,
    required Color color,
    required IconData icon,
  }) {
    final name = item['name'] ?? '-';
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return GestureDetector(
      onTap: () => _selectItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(initials,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E3A8A)),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1), size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}

class AdminLocationAssignmentCard extends StatelessWidget {
  final String lang;
  final AdminUserLocationSelection selection;
  final VoidCallback onTap;

  const AdminLocationAssignmentCard({
    super.key,
    required this.lang,
    required this.selection,
    required this.onTap,
  });

  String get _emptyLabel {
    switch (lang) {
      case 'EN':
        return 'Select location assignment';
      case 'ZH':
        return '选择位置分配';
      default:
        return 'Pilih penempatan lokasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF10B981);
    final hasValue = selection.idLokasi != null;
    final parts = <String>[
      if (selection.namaLokasi != null) selection.namaLokasi!,
      if (selection.namaUnit != null) selection.namaUnit!,
      if (selection.namaSubunit != null) selection.namaSubunit!,
      if (selection.namaArea != null) selection.namaArea!,
    ];
    final displayText = parts.isEmpty ? _emptyLabel : parts.join(' \u203a ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasValue ? color.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? color.withValues(alpha: 0.5) : const Color(0xFFCBD5E1),
            width: hasValue ? 1.4 : 1.2,
          ),
        ),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: hasValue ? color : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.location_city_rounded,
                size: 15, color: hasValue ? Colors.white : color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayText,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                color: hasValue ? color : Colors.black38,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: hasValue ? color : Colors.black26),
        ]),
      ),
    );
  }
}