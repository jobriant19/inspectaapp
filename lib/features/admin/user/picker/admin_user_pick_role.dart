import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../filter/admin_user_filter.dart' show adminRoleColor, adminRoleIcon;

class _RolePickerColors {
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFFEEF2FF);
  static const textPrimary = Color(0xFF1E3A8A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFF1F5F9);
}

const double _kRoleDialogWidth = 340;
const double _kRoleDialogHeightFactor = 0.72;

Future<Map<String, dynamic>?> showAdminPickRoleDialog(
  BuildContext context, {
  required String lang,
  required List<Map<String, dynamic>> jabatanList,
  int? selectedJabatanId,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _AdminRolePickerDialog(
      lang: lang,
      jabatanList: jabatanList,
      selectedJabatanId: selectedJabatanId,
    ),
  );
}

class AdminRolePickerCard extends StatelessWidget {
  final String lang;
  final Map<String, dynamic>? selectedRole;
  final VoidCallback onTap;

  const AdminRolePickerCard({
    super.key,
    required this.lang,
    required this.selectedRole,
    required this.onTap,
  });

  String get _placeholderText {
    switch (lang) {
      case 'EN':
        return 'Select role';
      case 'ZH':
        return '选择角色';
      default:
        return 'Pilih role';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedRole != null;
    final id = selectedRole?['id_jabatan'] as int?;
    final nama = selectedRole?['nama_jabatan']?.toString() ?? '';
    final color = hasValue ? adminRoleColor(id) : _RolePickerColors.primary;
    final icon = hasValue ? adminRoleIcon(id) : Icons.work_outline_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue ? color.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? color.withValues(alpha: 0.45) : const Color(0xFFCBD5E1),
            width: hasValue ? 1.4 : 1.2,
          ),
        ),
        child: hasValue
            ? Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 15, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nama,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: color),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.work_outline_rounded, size: 16, color: Colors.black26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _placeholderText,
                      style: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                ],
              ),
      ),
    );
  }
}

class _AdminRolePickerDialog extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> jabatanList;
  final int? selectedJabatanId;

  const _AdminRolePickerDialog({
    required this.lang,
    required this.jabatanList,
    this.selectedJabatanId,
  });

  @override
  State<_AdminRolePickerDialog> createState() => _AdminRolePickerDialogState();
}

class _AdminRolePickerDialogState extends State<_AdminRolePickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _sorted = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _sorted = List<Map<String, dynamic>>.from(widget.jabatanList)
      ..sort((a, b) => (a['id_jabatan'] as int).compareTo(b['id_jabatan'] as int));
    _filtered = List<Map<String, dynamic>>.from(_sorted);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Select Role';
      case 'ZH':
        return '选择角色';
      default:
        return 'Pilih Role';
    }
  }

  String get _searchHint {
    switch (widget.lang) {
      case 'EN':
        return 'Search role...';
      case 'ZH':
        return '搜索角色...';
      default:
        return 'Cari role...';
    }
  }

  String get _emptyText {
    switch (widget.lang) {
      case 'EN':
        return 'No roles found';
      case 'ZH':
        return '未找到角色';
      default:
        return 'Role tidak ditemukan';
    }
  }

  String get _memberCountLabel {
    final n = _filtered.length;
    switch (widget.lang) {
      case 'EN':
        return '$n roles';
      case 'ZH':
        return '$n 个角色';
      default:
        return '$n role';
    }
  }

  void _applySearch(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? List<Map<String, dynamic>>.from(_sorted)
          : _sorted
              .where((e) =>
                  (e['nama_jabatan'] ?? '').toString().toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kRoleDialogWidth,
        height: screenHeight * _kRoleDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _RolePickerColors.primaryLight, width: 1.5),
        ),
        child: Column(children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _RolePickerColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_rounded,
                    color: _RolePickerColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _RolePickerColors.primary,
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
          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _RolePickerColors.primary.withValues(alpha: 0.35),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _RolePickerColors.primary.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _applySearch,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _RolePickerColors.textPrimary,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle:
                      TextStyle(fontSize: 12.5, color: _RolePickerColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _RolePickerColors.primary, size: 19),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // INFO COUNT
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
            child: Row(children: [
              Text(_memberCountLabel,
                  style: const TextStyle(
                      fontSize: 11, color: _RolePickerColors.textSecondary)),
            ]),
          ),
          const Divider(height: 1, color: _RolePickerColors.divider),
          // LIST
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(_emptyText,
                        style: const TextStyle(
                            fontSize: 12.5, color: _RolePickerColors.textSecondary)),
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    children: _filtered.map((item) => _buildRoleItemCard(item)).toList(),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildRoleItemCard(Map<String, dynamic> item) {
    final id = item['id_jabatan'] as int?;
    final nama = item['nama_jabatan']?.toString() ?? '-';
    final isSelected = id != null && id == widget.selectedJabatanId;
    final color = adminRoleColor(id);
    final icon = adminRoleIcon(id);

    return InkWell(
      onTap: () => Navigator.pop(context, item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : _RolePickerColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nama,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : _RolePickerColors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: color, size: 18),
        ]),
      ),
    );
  }
}