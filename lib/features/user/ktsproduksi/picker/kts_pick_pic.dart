import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/jabatan_helper.dart';

Future<Map<String, dynamic>?> showKtsPickPicDialog(
  BuildContext context, {
  required String lang,
  String? currentUserId,
  String? selectedUserId,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _KtsAssigneePickerDialog(
      lang: lang,
      currentUserId: currentUserId,
      selectedUserId: selectedUserId,
    ),
  );
}

class _KtsAssigneePickerDialog extends StatefulWidget {
  final String lang;
  final String? currentUserId;
  final String? selectedUserId;

  const _KtsAssigneePickerDialog({
    required this.lang,
    this.currentUserId,
    this.selectedUserId,
  });

  @override
  State<_KtsAssigneePickerDialog> createState() => _KtsAssigneePickerDialogState();
}

class _KtsAssigneePickerDialogState extends State<_KtsAssigneePickerDialog> {
  static const Color _kPrimary       = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight  = Color(0xFFEFF6FF);
  static const Color _kBorder        = Color(0xFFBFDBFE);
  static const Color _kTextPrimary   = Color(0xFF0F172A);
  static const Color _kTextSecondary = Color(0xFF64748B);
  static const Color _kTextMuted     = Color(0xFFBDBDBD);

  static const double _kDialogWidth = 340;
  static const double _kDialogHeightFactor = 0.72;

  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  String _locLevel = 'Lokasi';
  String? _locId;
  String? _locName;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN': return 'Select Person in Charge';
      case 'ZH': return '选择负责人';
      default: return 'Pilih Penanggung Jawab';
    }
  }

  String get _searchHint {
    switch (widget.lang) {
      case 'EN': return 'Search member...';
      case 'ZH': return '搜索成员...';
      default: return 'Cari anggota...';
    }
  }

  String get _emptyText {
    switch (widget.lang) {
      case 'EN': return 'No users found';
      case 'ZH': return '未找到用户';
      default: return 'Pengguna tidak ditemukan';
    }
  }

  String get _memberCountLabel {
    final n = _filtered.length;
    switch (widget.lang) {
      case 'EN': return '$n members';
      case 'ZH': return '$n 位成员';
      default: return '$n anggota';
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      var query = _supabase
          .from('User')
          .select('id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)');
      if (_locId != null) {
        const idMap = {
          'Lokasi': 'id_lokasi',
          'Unit': 'id_unit',
          'Subunit': 'id_subunit',
          'Area': 'id_area',
        };
        final idCol = idMap[_locLevel] ?? 'id_lokasi';
        query = query.eq(idCol, _locId!);
      }
      final res = await query.order('nama');
      _items = List<Map<String, dynamic>>.from(res);
      if (widget.currentUserId != null) {
        _items.sort((a, b) {
          if (a['id_user'] == widget.currentUserId) return -1;
          if (b['id_user'] == widget.currentUserId) return 1;
          return (a['nama'] ?? '').toString().compareTo((b['nama'] ?? '').toString());
        });
      }
    } catch (e) {
      debugPrint('Error load users (KTS PIC): $e');
      _items = [];
    }
    _applySearch();
    if (mounted) setState(() => _loading = false);
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_items)
        : _items.where((e) => (e['nama'] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  Future<void> _openLocationFilter() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => _KtsLocationFilterDialog(
        lang: widget.lang,
        initialLevel: _locLevel,
        initialId: _locId,
      ),
    );
    if (result != null) {
      setState(() {
        _locLevel = result['level'] ?? _locLevel;
        _locId = result['id'];
        _locName = result['name'];
      });
      await _loadUsers();
    }
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildRoleBadge({
    required int? idJabatan,
    required String? jabatanNama,
    required bool? isVerificator,
  }) {
    final label = JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
    if (label.isEmpty) return const SizedBox.shrink();
    final color = JabatanHelper.getPrimaryColor(isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(isVerificatorFlag: isVerificator, idJabatan: idJabatan);
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
        Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kDialogWidth,
        height: screenHeight * _kDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kPrimaryLight, width: 1.5),
        ),
        child: Column(children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_search_rounded, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: _kPrimary)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
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
                    border: Border.all(color: _kPrimary.withValues(alpha: 0.35), width: 1.3),
                    boxShadow: [
                      BoxShadow(color: _kPrimary.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(_applySearch),
                    style: GoogleFonts.inter(fontSize: 13, color: _kTextPrimary, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _searchHint,
                      hintStyle: TextStyle(fontSize: 12.5, color: _kTextMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: _kPrimary, size: 19),
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
                    color: _locId != null ? _kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _locId != null ? _kPrimary : _kPrimary.withValues(alpha: 0.35),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(color: _kPrimary.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(Icons.map, color: _locId != null ? Colors.white : _kPrimary, size: 20),
                ),
              ),
            ]),
          ),
          // COUNT + ACTIVE LOCATION
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
            child: Row(children: [
              Text(_memberCountLabel, style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
              if (_locName != null) ...[
                const Spacer(),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _locName!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ]),
          ),
          Divider(height: 1, color: _kBorder.withValues(alpha: 0.5)),
          // LIST USER
          Expanded(
            child: _loading
                ? _buildShimmerList()
                : _filtered.isEmpty
                    ? Center(child: Text(_emptyText, style: const TextStyle(fontSize: 12.5, color: _kTextSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final name = (item['nama'] ?? '').toString();
                          final id = item['id_user']?.toString();
                          final avatarUrl = item['gambar_user'] as String?;
                          final idJabatan = item['id_jabatan'] as int?;
                          final isVerificator = item['is_verificator'] as bool?;
                          final jabatanRaw = item['jabatan'];
                          final jabatanNama = jabatanRaw is Map ? jabatanRaw['nama_jabatan']?.toString() : null;
                          final isSelected = id != null && id == widget.selectedUserId;

                          return InkWell(
                            onTap: () => Navigator.pop(context, item),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? _kPrimaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? _kPrimary : _kBorder, width: isSelected ? 1.5 : 1),
                              ),
                              child: Row(children: [
                                if (avatarUrl != null && avatarUrl.isNotEmpty)
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(avatarUrl),
                                    backgroundColor: _kPrimaryLight,
                                    onBackgroundImageError: (_, __) {},
                                  )
                                else
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected ? _kPrimary : _kPrimaryLight,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isSelected ? Colors.white : _kPrimary,
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
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isSelected ? _kPrimary : _kTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      _buildRoleBadge(
                                        idJabatan: idJabatan,
                                        jabatanNama: jabatanNama,
                                        isVerificator: isVerificator,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected) const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 18),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}

class _KtsLocationFilterDialog extends StatefulWidget {
  final String lang;
  final String initialLevel;
  final String? initialId;

  const _KtsLocationFilterDialog({
    required this.lang,
    required this.initialLevel,
    this.initialId,
  });

  @override
  State<_KtsLocationFilterDialog> createState() => _KtsLocationFilterDialogState();
}

class _KtsLocationFilterDialogState extends State<_KtsLocationFilterDialog> {
  static const Color _kPrimary       = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight  = Color(0xFFEFF6FF);
  static const Color _kTextPrimary   = Color(0xFF0F172A);
  static const Color _kTextSecondary = Color(0xFF64748B);
  static const Color _kTextMuted     = Color(0xFFBDBDBD);

  static const double _kDialogWidth = 340;
  static const double _kDialogHeightFactor = 0.72;

  static const List<String> _kLevels = ['Lokasi', 'Unit', 'Subunit', 'Area'];
  static const List<Color> _kLevelColors = [
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
  ];

  static const Map<String, String> _idColByLevel = {
    'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area',
  };
  static const Map<String, String> _nameColByLevel = {
    'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area',
  };

  final _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  String _level = 'Lokasi';
  String? _selectedId;
  final Map<String, List<Map<String, String>>> _dataByLevel = {
    'Lokasi': [], 'Unit': [], 'Subunit': [], 'Area': [],
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
      case 'EN': return 'Select Specific Location';
      case 'ZH': return '选择具体位置';
      default: return 'Pilih Lokasi Spesifik';
    }
  }

  String get _searchHint {
    switch (widget.lang) {
      case 'EN': return 'Search...';
      case 'ZH': return '搜索...';
      default: return 'Cari...';
    }
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'Unit': return widget.lang == 'ZH' ? '部门' : 'Unit';
      case 'Subunit': return widget.lang == 'ZH' ? '子部门' : 'Sub-Unit';
      case 'Area': return widget.lang == 'ZH' ? '区域' : 'Area';
      default: return widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi';
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'Unit': return Icons.business_rounded;
      case 'Subunit': return Icons.layers_rounded;
      case 'Area': return Icons.place_rounded;
      default: return Icons.location_city_rounded;
    }
  }

  String get _allLabel {
    switch (widget.lang) {
      case 'EN': return 'All (${_levelLabel(_level)})';
      case 'ZH': return '全部 (${_levelLabel(_level)})';
      default: return 'Semua (${_levelLabel(_level)})';
    }
  }

  String get _emptyLabel {
    switch (widget.lang) {
      case 'EN': return 'No data at this level';
      case 'ZH': return '该级别没有数据';
      default: return 'Tidak ada data pada level ini';
    }
  }

  Future<void> _fetchAllLevels() async {
    setState(() => _loading = true);
    try {
      for (final lvl in _kLevels) {
        final levelLower = lvl.toLowerCase();
        final idCol = _idColByLevel[levelLower] ?? 'id_lokasi';
        final nameCol = _nameColByLevel[levelLower] ?? 'nama_lokasi';
        final res = await _supabase.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        _dataByLevel[lvl] = List<Map<String, dynamic>>.from(res)
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'})
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetch location filter (KTS PIC): $e');
    }
    if (mounted) setState(() => _loading = false);
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  int get _levelColorIndex => _kLevels.indexOf(_level);

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Map<String, String>> filtered;

    if (q.isEmpty) {
      filtered = _dataByLevel[_level] ?? [];
    } else {
      final currentMatches = (_dataByLevel[_level] ?? []).where((e) => e['name']!.toLowerCase().contains(q)).toList();
      if (currentMatches.isNotEmpty) {
        filtered = currentMatches;
      } else {
        String? matchLevel;
        List<Map<String, String>> matchResult = [];
        for (final lvl in _kLevels) {
          if (lvl == _level) continue;
          final matches = (_dataByLevel[lvl] ?? []).where((e) => e['name']!.toLowerCase().contains(q)).toList();
          if (matches.isNotEmpty) { matchLevel = lvl; matchResult = matches; break; }
        }
        filtered = matchResult;
        if (matchLevel != null) {
          final resolvedLevel = matchLevel;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _level != resolvedLevel) {
              setState(() { _level = resolvedLevel; _selectedId = null; });
            }
          });
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kDialogWidth,
        height: screenHeight * _kDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kPrimaryLight, width: 1.5),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.map, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: _kPrimary)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
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
              children: List.generate(_kLevels.length, (index) {
                final lvl = _kLevels[index];
                final isActive = lvl == _level;
                final color = _kLevelColors[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _level = lvl; _selectedId = null; _searchCtrl.clear(); }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isActive ? color : const Color(0xFFE2E8F0)),
                        boxShadow: isActive
                            ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_levelIcon(lvl), size: 15, color: isActive ? Colors.white : color),
                          const SizedBox(height: 3),
                          Text(
                            _levelLabel(lvl),
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
                border: Border.all(color: _kPrimary.withValues(alpha: 0.35), width: 1.3),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 13, color: _kTextPrimary),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle: TextStyle(fontSize: 12.5, color: _kTextMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: _kPrimary, size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFEFF6FF)),
          Expanded(
            child: _loading
                ? _buildShimmerList()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    children: [
                      _buildAllCard(),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(_emptyLabel, style: const TextStyle(fontSize: 12.5, color: _kTextSecondary)),
                          ),
                        )
                      else
                        ...filtered.map((item) => _buildItemCard(item)),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAllCard() {
    final isSel = _selectedId == null;
    final color = _kLevelColors[_levelColorIndex];
    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': null, 'name': null}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? _kPrimary : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.apps_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_allLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  Widget _buildItemCard(Map<String, String> item) {
    final isSel = item['id'] == _selectedId;
    final color = _kLevelColors[_levelColorIndex];
    final name = item['name'] ?? '-';
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return GestureDetector(
      onTap: () => Navigator.pop(context, {'level': _level, 'id': item['id'], 'name': item['name']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? _kPrimary : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
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
                    Icon(_levelIcon(_level), size: 10, color: color),
                    const SizedBox(width: 3),
                    Text(_levelLabel(_level), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
                  ]),
                ),
              ],
            ),
          ),
          if (isSel)
            const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20)
          else
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ]),
      ),
    );
  }
}