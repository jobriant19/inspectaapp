import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'audit_pick_auditor.dart';
import 'audit_pick_location.dart';

const Color _kPrimary   = Color(0xFF8B5CF6);
const Color _kPrimaryLt = Color(0xFFEDE9FE);
const Color _kNameColor = Color(0xFF1D72F3);
const Color _kRed       = Color(0xFFEF4444);
const Color _kTextMain  = Color(0xFF1E3A8A);
const Color _kTextSub   = Color(0xFF64748B);

const int kAssignAuditorPerPage = 4;

class _JabatanStyle {
  final Color color;
  final IconData icon;
  const _JabatanStyle(this.color, this.icon);
}

_JabatanStyle _jabatanStyle(String? jabatan) {
  final j = (jabatan ?? '').toLowerCase();
  if (j.contains('eksekutif')) {
    return const _JabatanStyle(Color(0xFFDC2626), Icons.workspace_premium_rounded);
  } else if (j.contains('manager')) {
    return const _JabatanStyle(Color(0xFF2563EB), Icons.badge_rounded);
  } else if (j.contains('kasie')) {
    return const _JabatanStyle(Color(0xFF7C3AED), Icons.supervisor_account_rounded);
  } else if (j.contains('hrd')) {
    return const _JabatanStyle(Color(0xFFF59E0B), Icons.groups_2_rounded);
  }
  return const _JabatanStyle(Color(0xFF64748B), Icons.person_rounded);
}

bool _shouldShowJabatan(String? jabatan) {
  if (jabatan == null || jabatan.trim().isEmpty) return false;
  return !jabatan.toLowerCase().contains('admin');
}

String _cardT(String lang, String en, String id, String zh) {
  if (lang == 'EN') return en;
  if (lang == 'ZH') return zh;
  return id;
}

String _levelLabel(String levelType, String lang) {
  const map = {
    'lokasi': {'EN': 'Location', 'ID': 'Lokasi', 'ZH': '位置'},
    'unit': {'EN': 'Unit', 'ID': 'Unit', 'ZH': '单元'},
    'subunit': {'EN': 'Sub-Unit', 'ID': 'Sub-Unit', 'ZH': '子单元'},
    'area': {'EN': 'Area', 'ID': 'Area', 'ZH': '区域'},
  };
  return map[levelType]?[lang] ?? map[levelType]?['ID'] ?? levelType;
}

class AuditAssignmentCard extends StatelessWidget {
  final AuditAssignmentData assignment;
  final String lang;
  final VoidCallback? onRemove;

  const AuditAssignmentCard({
    super.key,
    required this.assignment,
    required this.lang,
    this.onRemove,
  });

  static const double _avatarDiameter = 40;

  @override
  Widget build(BuildContext context) {
    final auditor      = assignment.auditor;
    final auditorName  = auditor['nama']?.toString() ?? '-';
    final jabatanRaw    = (auditor['jabatan'] as Map<String, dynamic>?)?['nama_jabatan']?.toString();
    final jabatan       = _shouldShowJabatan(jabatanRaw) ? jabatanRaw : null;
    final jStyle        = _jabatanStyle(jabatan);
    final levelIdx      = kAuditLevelKeys.indexOf(assignment.levelType);
    final levelColor    = levelIdx >= 0 ? kAuditLevelColors[levelIdx] : _kPrimary;
    final levelIcon     = levelIdx >= 0 ? kAuditLevelIcons[levelIdx] : Icons.place_rounded;
    final levelLabel    = _levelLabel(assignment.levelType, lang);

    final initials = auditorName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: _avatarDiameter / 2,
                backgroundColor: _kPrimaryLt,
                backgroundImage: auditor['gambar_user'] != null
                    ? NetworkImage(auditor['gambar_user'] as String)
                    : null,
                child: auditor['gambar_user'] == null
                    ? Text(initials,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _kPrimary))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auditorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _kNameColor),
                    ),
                    if (jabatan != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: jStyle.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: jStyle.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(jStyle.icon, size: 10, color: jStyle.color),
                            const SizedBox(width: 4),
                            Text(jabatan,
                                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: jStyle.color)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: _kRed),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: _avatarDiameter + 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.assignment_ind_rounded, size: 11, color: _kTextSub),
                const SizedBox(width: 4),
                Text(
                  '${_cardT(lang, 'Audit Location', 'Lokasi Audit', '审计位置')}: ',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _kTextSub),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: levelColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(levelIcon, size: 10, color: levelColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$levelLabel: ${assignment.locationName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: levelColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<AuditAssignmentData>?> showAuditAssignAuditorPopup({
  required BuildContext context,
  required String lang,
  required List<AuditAssignmentData> initialAssignments,
}) {
  return showDialog<List<AuditAssignmentData>>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => _AuditAssignAuditorDialog(
      lang: lang,
      initialAssignments: initialAssignments,
    ),
  );
}

class _AuditAssignAuditorDialog extends StatefulWidget {
  final String lang;
  final List<AuditAssignmentData> initialAssignments;
  const _AuditAssignAuditorDialog({
    required this.lang,
    required this.initialAssignments,
  });

  @override
  State<_AuditAssignAuditorDialog> createState() => _AuditAssignAuditorDialogState();
}

class _AuditAssignAuditorDialogState extends State<_AuditAssignAuditorDialog> {
  late List<AuditAssignmentData> _assignments;
  int _currentPage = 1;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _assignments = List<AuditAssignmentData>.from(widget.initialAssignments);
  }

  int get _totalPages {
    final p = (_assignments.length / kAssignAuditorPerPage).ceil();
    return p < 1 ? 1 : p;
  }

  List<AuditAssignmentData> get _pageItems {
    final start = (_currentPage - 1) * kAssignAuditorPerPage;
    if (start >= _assignments.length) return [];
    final end = (start + kAssignAuditorPerPage) > _assignments.length
        ? _assignments.length
        : (start + kAssignAuditorPerPage);
    return _assignments.sublist(start, end);
  }

  void _goToPage(int page) => setState(() => _currentPage = page);

  void _removeAssignment(String userId) {
    setState(() {
      _assignments.removeWhere((a) => a.auditor['id_user']?.toString() == userId);
      if (_currentPage > _totalPages) _currentPage = _totalPages;
    });
  }

  Future<void> _openAddAuditor() async {
    final result = await showAuditPickAuditorPopup(
      context: context,
      lang: widget.lang,
      initialAssignments: _assignments,
    );
    if (result != null) {
      setState(() {
        _assignments = result;
        if (_currentPage > _totalPages) _currentPage = _totalPages;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(Icons.groups_rounded, color: _kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_t('All Auditors', 'Semua Auditor', '所有审计员')} (${_assignments.length})',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _kPrimary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, _assignments),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration:
                            BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),

              // LIST
              Flexible(
                child: _assignments.isEmpty
                    ? _buildEmptyAssignmentsState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        shrinkWrap: true,
                        children: _pageItems
                            .map((a) => AuditAssignmentCard(
                                  assignment: a,
                                  lang: widget.lang,
                                  onRemove: () =>
                                      _removeAssignment(a.auditor['id_user']?.toString() ?? ''),
                                ))
                            .toList(),
                      ),
              ),

              // ADD AUDITOR BUTTON
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: GestureDetector(
                  onTap: _openAddAuditor,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add_alt_1_rounded, color: _kPrimary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _t('Add Auditor', 'Tambah Auditor', '添加审计员'),
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // BOTTOM PAGE INDICATOR
              if (_assignments.length > kAssignAuditorPerPage)
                _PageIndicator(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageChanged: _goToPage,
                ),

              // FOOTER
              Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _assignments),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_t('Done', 'Selesai', '完成'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAssignmentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 130,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: _kPrimaryLt, shape: BoxShape.circle),
                child: const Icon(Icons.groups_rounded, size: 40, color: _kPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t('No Auditors Assigned Yet', 'Belum Ada Auditor Ditugaskan', '尚未分配审计员'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextMain),
            ),
            const SizedBox(height: 6),
            Text(
              _t(
                'Tap "Add Auditor" below to assign your first auditor to a location.',
                'Ketuk "Tambah Auditor" di bawah untuk menugaskan auditor pertama Anda ke lokasi.',
                '点击下方"添加审计员"以将您的第一位审计员分配到某个位置。',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500, color: _kTextSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  static const Color _mainColor = Color(0xFF6366F1);
  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _mainColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            _arrowButton(
              icon: Icons.arrow_back_ios_new_rounded,
              enabled: canPrev,
              onTap: () {
                if (!canPrev) return;
                onPageChanged(currentPage - 1);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  for (final p in pageNumbers) ...[
                    Expanded(child: _pageNumberButton(p)),
                    if (p != pageNumbers.last) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _arrowButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: canNext,
              onTap: () {
                if (!canNext) return;
                onPageChanged(currentPage + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageNumberButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _mainColor : _mainColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: _mainColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(color: isActive ? Colors.white : _mainColor, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? _mainColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 13, color: enabled ? _mainColor : Colors.grey.shade400),
      ),
    );
  }
}