import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/jabatan_helper.dart';

class _SupervisorPickerColors {
  static const primary = Color(0xFF8B5CF6);
  static const primaryLight = Color(0xFFF3E8FF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFF1F5F9);
}

const double _kSupervisorDialogWidth = 340;
const double _kSupervisorDialogHeightFactor = 0.72;

const List<String> _supervisorLevels = ['Lokasi', 'Unit', 'Subunit', 'Area'];

const List<Color> _supervisorTabColors = [
  Color(0xFF10B981),
  Color(0xFF6366F1),
  Color(0xFFFBBF24),
  Color(0xFFF472B6),
];

String _supervisorLevelLabel(String level, String lang) {
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

IconData _supervisorLevelIcon(String level) {
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

/// Membuka popup pemilih supervisor.
///
/// Return value:
/// - `null`            -> dialog ditutup tanpa perubahan (pertahankan selection lama)
/// - `<String,dynamic>{}` (map kosong) -> user memilih "Tanpa supervisor"
/// - `{...}`            -> map data supervisor yang dipilih (berisi id_user, nama, dst)
Future<Map<String, dynamic>?> showAdminPickSupervisorDialog(
  BuildContext context, {
  required String lang,
  required List<Map<String, dynamic>> supervisorList,
  String? selectedSupervisorId,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _AdminSupervisorPickerDialog(
      lang: lang,
      supervisorList: supervisorList,
      selectedSupervisorId: selectedSupervisorId,
    ),
  );
}

/// Kartu "Select Supervisor" yang tampil di form (menggantikan DropdownButton).
/// Tap kartu ini untuk membuka [showAdminPickSupervisorDialog].
class AdminSupervisorPickerCard extends StatelessWidget {
  final String lang;
  final Map<String, dynamic>? selectedSupervisor;
  final VoidCallback onTap;

  const AdminSupervisorPickerCard({
    super.key,
    required this.lang,
    required this.selectedSupervisor,
    required this.onTap,
  });

  String get _placeholderText {
    switch (lang) {
      case 'EN':
        return 'Select supervisor (optional)';
      case 'ZH':
        return '选择主管（可选）';
      default:
        return 'Pilih supervisor (opsional)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedSupervisor != null;
    final name = selectedSupervisor?['nama']?.toString() ?? '';
    final avatarUrl = selectedSupervisor?['gambar_user']?.toString();
    final idJabatan = selectedSupervisor?['id_jabatan'] as int?;
    final isVerificator = selectedSupervisor?['is_verificator'] as bool?;
    final jabatanRaw = selectedSupervisor?['jabatan'];
    final jabatanNama =
        jabatanRaw is Map ? jabatanRaw['nama_jabatan']?.toString() : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? _SupervisorPickerColors.primary.withValues(alpha: 0.05)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? _SupervisorPickerColors.primary.withValues(alpha: 0.45)
                : const Color(0xFFCBD5E1),
            width: hasValue ? 1.4 : 1.2,
          ),
        ),
        child: hasValue
            ? Row(
                children: [
                  if (avatarUrl != null && avatarUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _SupervisorPickerColors.primaryLight,
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (_, __) {},
                    )
                  else
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _SupervisorPickerColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _SupervisorPickerColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (idJabatan != null || jabatanNama != null) ...[
                          const SizedBox(height: 4),
                          _buildJabatanBadge(
                            idJabatan: idJabatan,
                            jabatanNama: jabatanNama,
                            isVerificator: isVerificator,
                            lang: lang,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: _SupervisorPickerColors.primary),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.person_search_outlined,
                      size: 16, color: Colors.black26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _placeholderText,
                      style: GoogleFonts.poppins(
                          color: Colors.black38, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.black45),
                ],
              ),
      ),
    );
  }
}

Color _pickerRoleColor(int? idJabatan) {
  if (idJabatan == 6) return const Color(0xFF059669);
  return JabatanHelper.getPrimaryColor(
      isVerificatorFlag: false, idJabatan: idJabatan);
}

IconData _pickerRoleIcon(int? idJabatan) {
  if (idJabatan == 6) return Icons.admin_panel_settings_rounded;
  return JabatanHelper.getRoleIcon(
      isVerificatorFlag: false, idJabatan: idJabatan);
}

Widget _buildJabatanBadge({
  required int? idJabatan,
  required String? jabatanNama,
  required bool? isVerificator,
  required String lang,
}) {
  final label = JabatanHelper.getDisplayRole(
    isVerificatorFlag: isVerificator,
    idJabatan: idJabatan,
    jabatanFromDb: jabatanNama,
    lang: lang,
  );
  if (label.isEmpty) return const SizedBox.shrink();
  final color = _pickerRoleColor(idJabatan);
  final icon = _pickerRoleIcon(idJabatan);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color),
      const SizedBox(width: 3),
      Text(label,
          style:
              TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

Widget _buildSupervisorShimmerList() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      itemCount: 5,
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

class _AdminSupervisorPickerDialog extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> supervisorList;
  final String? selectedSupervisorId;

  const _AdminSupervisorPickerDialog({
    required this.lang,
    required this.supervisorList,
    this.selectedSupervisorId,
  });

  @override
  State<_AdminSupervisorPickerDialog> createState() =>
      _AdminSupervisorPickerDialogState();
}

class _AdminSupervisorPickerDialogState
    extends State<_AdminSupervisorPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  String _locLevel = 'Lokasi';
  String? _locId;
  String? _locName;

  // Loading dipertahankan agar tampilan/perilaku (shimmer) identik dengan
  // finding_pick_pic.dart, meskipun data supervisor di sini sudah tersedia
  // dari parent screen (tidak perlu query ulang ke Supabase).
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _filtered = List<Map<String, dynamic>>.from(widget.supervisorList);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Select Supervisor';
      case 'ZH':
        return '选择主管';
      default:
        return 'Pilih Supervisor';
    }
  }

  String get _searchHint {
    switch (widget.lang) {
      case 'EN':
        return 'Search supervisor...';
      case 'ZH':
        return '搜索主管...';
      default:
        return 'Cari supervisor...';
    }
  }

  String get _emptyText {
    switch (widget.lang) {
      case 'EN':
        return 'No supervisors found';
      case 'ZH':
        return '未找到主管';
      default:
        return 'Supervisor tidak ditemukan';
    }
  }

  String get _noSupervisorLabel {
    switch (widget.lang) {
      case 'EN':
        return '— No supervisor —';
      case 'ZH':
        return '— 无主管 —';
      default:
        return '— Tanpa supervisor —';
    }
  }

  String get _memberCountLabel {
    final n = _filtered.length;
    switch (widget.lang) {
      case 'EN':
        return '$n supervisors';
      case 'ZH':
        return '$n 位主管';
      default:
        return '$n supervisor';
    }
  }

  void _applySearch(String q) {
    final query = q.trim().toLowerCase();
    const idMap = {
      'Lokasi': 'id_lokasi',
      'Unit': 'id_unit',
      'Subunit': 'id_subunit',
      'Area': 'id_area',
    };
    final idCol = idMap[_locLevel] ?? 'id_lokasi';

    setState(() {
      _filtered = widget.supervisorList.where((e) {
        final matchesQuery = query.isEmpty ||
            (e['nama'] ?? '').toString().toLowerCase().contains(query);
        final matchesLocation =
            _locId == null || e[idCol]?.toString() == _locId;
        return matchesQuery && matchesLocation;
      }).toList();
    });
  }

  Future<void> _openLocationFilter() async {
    final result = await _showAdminSupervisorLocationFilterDialog(
      context,
      lang: widget.lang,
      initialLevel: _locLevel,
      initialId: _locId,
    );
    if (result != null) {
      setState(() {
        _locLevel = result['level'] ?? _locLevel;
        _locId = result['id'];
        _locName = result['name'];
      });
      _applySearch(_searchCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kSupervisorDialogWidth,
        height: screenHeight * _kSupervisorDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _SupervisorPickerColors.primaryLight, width: 1.5),
        ),
        child: Column(children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _SupervisorPickerColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_search_rounded,
                    color: _SupervisorPickerColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _SupervisorPickerColors.primary,
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
          // SEARCH + LOCATION FILTER
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _SupervisorPickerColors.primary
                          .withValues(alpha: 0.35),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _SupervisorPickerColors.primary
                            .withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _applySearch,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _SupervisorPickerColors.textPrimary,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _searchHint,
                      hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: _SupervisorPickerColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _SupervisorPickerColors.primary, size: 19),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openLocationFilter,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _locId != null
                        ? _SupervisorPickerColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _locId != null
                          ? _SupervisorPickerColors.primary
                          : _SupervisorPickerColors.primary
                              .withValues(alpha: 0.35),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _SupervisorPickerColors.primary
                            .withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.map,
                      color: _locId != null
                          ? Colors.white
                          : _SupervisorPickerColors.primary,
                      size: 20),
                ),
              ),
            ]),
          ),
          // INFO COUNT + ACTIVE LOCATION
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
            child: Row(children: [
              Text(_memberCountLabel,
                  style: const TextStyle(
                      fontSize: 11, color: _SupervisorPickerColors.textSecondary)),
              if (_locName != null) ...[
                const Spacer(),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _SupervisorPickerColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _locName!,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _SupervisorPickerColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ]),
          ),
          const Divider(height: 1, color: _SupervisorPickerColors.divider),
          // LIST
          Expanded(
            child: _loading
                ? _buildSupervisorShimmerList()
                : ListView(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    children: [
                      _buildNoSupervisorCard(),
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(_emptyText,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color:
                                        _SupervisorPickerColors.textSecondary)),
                          ),
                        )
                      else
                        ..._filtered
                            .map((item) => _buildSupervisorItemCard(item)),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildNoSupervisorCard() {
    final isSel = widget.selectedSupervisorId == null;
    return InkWell(
      onTap: () => Navigator.pop(context, <String, dynamic>{}),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? _SupervisorPickerColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel
                ? _SupervisorPickerColors.primary
                : _SupervisorPickerColors.divider,
            width: isSel ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.remove_circle_outline_rounded,
                size: 18, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _noSupervisorLabel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel
                    ? _SupervisorPickerColors.primary
                    : _SupervisorPickerColors.textPrimary,
              ),
            ),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded,
                color: _SupervisorPickerColors.primary, size: 18),
        ]),
      ),
    );
  }

  Widget _buildSupervisorItemCard(Map<String, dynamic> item) {
    final name = (item['nama'] ?? '').toString();
    final id = item['id_user']?.toString();
    final avatarUrl = item['gambar_user'] as String?;
    final idJabatan = item['id_jabatan'] as int?;
    final isVerificator = item['is_verificator'] as bool?;
    final jabatanRaw = item['jabatan'];
    final jabatanNama =
        jabatanRaw is Map ? jabatanRaw['nama_jabatan']?.toString() : null;
    final isSelected = id != null && id == widget.selectedSupervisorId;

    return InkWell(
      onTap: () => Navigator.pop(context, item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? _SupervisorPickerColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _SupervisorPickerColors.primary
                : _SupervisorPickerColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          if (avatarUrl != null && avatarUrl.isNotEmpty)
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(avatarUrl),
              onBackgroundImageError: (_, __) {},
              backgroundColor: _SupervisorPickerColors.primaryLight,
            )
          else
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected
                  ? _SupervisorPickerColors.primary
                  : _SupervisorPickerColors.primaryLight,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color:
                      isSelected ? Colors.white : _SupervisorPickerColors.primary,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? _SupervisorPickerColors.primary
                        : _SupervisorPickerColors.textPrimary,
                  ),
                ),
                if (idJabatan != null || jabatanNama != null) ...[
                  const SizedBox(height: 4),
                  _buildJabatanBadge(
                    idJabatan: idJabatan,
                    jabatanNama: jabatanNama,
                    isVerificator: isVerificator,
                    lang: widget.lang,
                  ),
                ],
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: _SupervisorPickerColors.primary, size: 18),
        ]),
      ),
    );
  }
}

Future<Map<String, String?>?> _showAdminSupervisorLocationFilterDialog(
  BuildContext parentContext, {
  required String lang,
  required String initialLevel,
  String? initialId,
}) {
  return showDialog<Map<String, String?>>(
    context: parentContext,
    barrierColor: Colors.transparent,
    builder: (ctx) => _AdminSupervisorLocationFilterDialog(
      lang: lang,
      initialLevel: initialLevel,
      initialId: initialId,
    ),
  );
}

class _AdminSupervisorLocationFilterDialog extends StatefulWidget {
  final String lang;
  final String initialLevel;
  final String? initialId;

  const _AdminSupervisorLocationFilterDialog({
    required this.lang,
    required this.initialLevel,
    this.initialId,
  });

  @override
  State<_AdminSupervisorLocationFilterDialog> createState() =>
      _AdminSupervisorLocationFilterDialogState();
}

class _AdminSupervisorLocationFilterDialogState
    extends State<_AdminSupervisorLocationFilterDialog> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  static const Map<String, String> _idColByLevel = {
    'lokasi': 'id_lokasi',
    'unit': 'id_unit',
    'subunit': 'id_subunit',
    'area': 'id_area',
  };
  static const Map<String, String> _nameColByLevel = {
    'lokasi': 'nama_lokasi',
    'unit': 'nama_unit',
    'subunit': 'nama_subunit',
    'area': 'nama_area',
  };

  String _level = 'Lokasi';
  String? _selectedId;
  final Map<String, List<Map<String, String>>> _dataByLevel = {
    'Lokasi': [],
    'Unit': [],
    'Subunit': [],
    'Area': [],
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _selectedId = widget.initialId;
    _searchCtrl.addListener(() => setState(() {}));
    _fetchAllLevels();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Select Location';
      case 'ZH':
        return '选择位置';
      default:
        return 'Pilih Lokasi';
    }
  }

  String get _searchHint {
    switch (widget.lang) {
      case 'EN':
        return 'Search...';
      case 'ZH':
        return '搜索...';
      default:
        return 'Cari...';
    }
  }

  String get _allLabel {
    switch (widget.lang) {
      case 'EN':
        return 'All (${_supervisorLevelLabel(_level, widget.lang)})';
      case 'ZH':
        return '全部 (${_supervisorLevelLabel(_level, widget.lang)})';
      default:
        return 'Semua (${_supervisorLevelLabel(_level, widget.lang)})';
    }
  }

  String get _emptyLabel {
    switch (widget.lang) {
      case 'EN':
        return 'No data at this level';
      case 'ZH':
        return '该级别没有数据';
      default:
        return 'Tidak ada data pada level ini';
    }
  }

  Future<void> _fetchAllLevels() async {
    setState(() => _loading = true);
    try {
      for (final lvl in _supervisorLevels) {
        final levelLower = lvl.toLowerCase();
        final idCol = _idColByLevel[levelLower] ?? 'id_lokasi';
        final nameCol = _nameColByLevel[levelLower] ?? 'nama_lokasi';
        final res =
            await _supabase.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        _dataByLevel[lvl] = List<Map<String, dynamic>>.from(res)
            .map((e) => {
                  'id': e[idCol]?.toString() ?? '',
                  'name': e[nameCol]?.toString() ?? '-'
                })
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetch location filter (Supervisor): $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Map<String, String>> filtered;

    if (q.isEmpty) {
      filtered = _dataByLevel[_level] ?? [];
    } else {
      final currentMatches = (_dataByLevel[_level] ?? [])
          .where((e) => e['name']!.toLowerCase().contains(q))
          .toList();
      if (currentMatches.isNotEmpty) {
        filtered = currentMatches;
      } else {
        String? matchLevel;
        List<Map<String, String>> matchResult = [];
        for (final lvl in _supervisorLevels) {
          if (lvl == _level) continue;
          final matches = (_dataByLevel[lvl] ?? [])
              .where((e) => e['name']!.toLowerCase().contains(q))
              .toList();
          if (matches.isNotEmpty) {
            matchLevel = lvl;
            matchResult = matches;
            break;
          }
        }
        filtered = matchResult;
        if (matchLevel != null) {
          final resolvedLevel = matchLevel;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _level != resolvedLevel) {
              setState(() {
                _level = resolvedLevel;
                _selectedId = null;
              });
            }
          });
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kSupervisorDialogWidth,
        height: screenHeight * _kSupervisorDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _SupervisorPickerColors.primaryLight, width: 1.5),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _SupervisorPickerColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: _SupervisorPickerColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _SupervisorPickerColors.primary,
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
          // TAB LEVEL
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: List.generate(_supervisorLevels.length, (index) {
                final lvl = _supervisorLevels[index];
                final isActive = lvl == _level;
                final color = _supervisorTabColors[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _level = lvl;
                        _selectedId = null;
                        _searchCtrl.clear();
                      });
                    },
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
                          Icon(_supervisorLevelIcon(lvl),
                              size: 15, color: isActive ? Colors.white : color),
                          const SizedBox(height: 3),
                          Text(
                            _supervisorLevelLabel(lvl, widget.lang),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color:
                                  isActive ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ],
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
                    color: _SupervisorPickerColors.primary.withValues(alpha: 0.35),
                    width: 1.3),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(
                    fontSize: 13, color: _SupervisorPickerColors.textPrimary),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle:
                      TextStyle(fontSize: 12.5, color: _SupervisorPickerColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _SupervisorPickerColors.primary, size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: _SupervisorPickerColors.divider),
          Expanded(
            child: _loading
                ? _buildSupervisorShimmerList()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    children: [
                      _buildSupervisorLocationAllCard(),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(_emptyLabel,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _SupervisorPickerColors.textSecondary)),
                          ),
                        )
                      else
                        ...filtered.map((item) => _buildSupervisorLocationItemCard(item)),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  int get _levelColorIndex => _supervisorLevels.indexOf(_level);

  Widget _buildSupervisorLocationAllCard() {
    final isSel = _selectedId == null;
    final color = _supervisorTabColors[_levelColorIndex];
    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': null, 'name': null}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? _SupervisorPickerColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? _SupervisorPickerColors.primary : const Color(0xFFE2E8F0),
            width: isSel ? 1.5 : 1,
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
            child: Icon(Icons.apps_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _allLabel,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
            ),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded, color: _SupervisorPickerColors.primary, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Widget _buildSupervisorLocationItemCard(Map<String, String> item) {
    final isSel = item['id'] == _selectedId;
    final color = _supervisorTabColors[_levelColorIndex];
    final name = item['name'] ?? '-';
    final initials =
        name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': item['id'], 'name': item['name']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? _SupervisorPickerColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? _SupervisorPickerColors.primary : const Color(0xFFE2E8F0),
            width: isSel ? 1.5 : 1,
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
            child: Text(initials, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
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
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_supervisorLevelIcon(_level), size: 10, color: color),
                    const SizedBox(width: 3),
                    Text(_supervisorLevelLabel(_level, widget.lang),
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
                  ]),
                ),
              ],
            ),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded, color: _SupervisorPickerColors.primary, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}