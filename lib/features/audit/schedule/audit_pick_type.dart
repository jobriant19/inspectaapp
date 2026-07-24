import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kPrimary   = Color(0xFF8B5CF6);
const Color _kPrimaryLt = Color(0xFFEDE9FE);
const Color _kTextMain  = Color(0xFF1E3A8A);
const Color _kTextSub   = Color(0xFF64748B);
const Color _kNameColor = Color(0xFF1D72F3);

Future<Map<String, dynamic>?> showAuditTypePicker({
  required BuildContext context,
  required String lang,
  required List<Map<String, dynamic>> jenisAuditList,
  required String? selectedId,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => _AuditTypePickerDialog(
      lang: lang,
      jenisAuditList: jenisAuditList,
      selectedId: selectedId,
    ),
  );
}

class _AuditTypePickerDialog extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> jenisAuditList;
  final String? selectedId;

  const _AuditTypePickerDialog({
    required this.lang,
    required this.jenisAuditList,
    required this.selectedId,
  });

  @override
  State<_AuditTypePickerDialog> createState() => _AuditTypePickerDialogState();
}

class _AuditTypePickerDialogState extends State<_AuditTypePickerDialog> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _label(Map<String, dynamic> j) {
    if (widget.lang == 'EN') return j['nama_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return j['nama_zh']?.toString() ?? '-';
    return j['nama_id']?.toString() ?? '-';
  }

  @override
  void initState() {
    super.initState();
    _filtered = widget.jenisAuditList;
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.jenisAuditList
          : widget.jenisAuditList
              .where((j) => _label(j).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.75,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: 480,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _kPrimaryLt, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.assignment_rounded, color: _kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('SELECT AUDIT TYPE', 'PILIH JENIS AUDIT', '选择审计类型'),
                        style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w800, color: _kPrimary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              // SEARCH
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 18, color: _kPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kTextMain),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: _t('Search audit type…', 'Cari jenis audit…', '搜索审计类型…'),
                            hintStyle: GoogleFonts.poppins(fontSize: 12, color: _kTextSub),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              // LIST
              Expanded(
                child: _filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final j = _filtered[i];
                          final id = j['id_jenis_audit'].toString();
                          final isSelected = widget.selectedId == id;
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, j),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              decoration: BoxDecoration(
                                color: isSelected ? _kPrimary.withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected ? _kPrimary : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _kPrimary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.assignment_turned_in_rounded,
                                        size: 16, color: _kPrimary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _label(j),
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? _kPrimary : _kTextMain),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 130,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: _kPrimaryLt, shape: BoxShape.circle),
                child: const Icon(Icons.search_off_rounded, size: 40, color: _kPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t('No Audit Type Found', 'Jenis Audit Tidak Ditemukan', '未找到审计类型'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: _kNameColor),
            ),
            const SizedBox(height: 6),
            Text(
              _t('Try a different keyword or check the spelling.',
                  'Coba kata kunci lain atau periksa ejaannya.',
                  '请尝试其他关键字或检查拼写。'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500, color: _kTextSub),
            ),
          ],
        ),
      ),
    );
  }
}