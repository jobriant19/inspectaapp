import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../admin/user/filter/admin_user_filter.dart';
import 'audit_pick_location.dart';

const Color _kPrimary   = Color(0xFF8B5CF6);
const Color _kPrimaryLt = Color(0xFFEDE9FE);
const Color _kTextMain  = Color(0xFF1E3A8A);
const Color _kTextSub   = Color(0xFF64748B);
const Color _kGreen     = Color(0xFF10B981);
const Color _kNameColor = Color(0xFF1D72F3);

const int kPickAuditorPerPage = 5;

const int kAdminJabatanId = 6;

const Color _kVerificatorColor = Color(0xFF0EA5E9);
const IconData _kVerificatorIcon = Icons.verified_rounded;

const String kVerificatorFilterKey = '__verificator__';

bool _shouldShowJabatan(String? jabatan) {
  if (jabatan == null || jabatan.trim().isEmpty) return false;
  return !jabatan.toLowerCase().contains('admin');
}

class _JabatanFilterOption {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _JabatanFilterOption({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}

class AuditAssignmentData {
  final Map<String, dynamic> auditor;
  final String levelType;
  final String idRef;
  final String locationName;
  const AuditAssignmentData({
    required this.auditor,
    required this.levelType,
    required this.idRef,
    required this.locationName,
  });
}

Future<List<AuditAssignmentData>?> showAuditPickAuditorPopup({
  required BuildContext context,
  required String lang,
  required List<AuditAssignmentData> initialAssignments,
}) {
  return showDialog<List<AuditAssignmentData>>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => _AuditPickAuditorDialog(
      lang: lang,
      initialAssignments: initialAssignments,
    ),
  );
}

class _AuditPickAuditorDialog extends StatefulWidget {
  final String lang;
  final List<AuditAssignmentData> initialAssignments;
  const _AuditPickAuditorDialog({
    required this.lang,
    required this.initialAssignments,
  });

  @override
  State<_AuditPickAuditorDialog> createState() => _AuditPickAuditorDialogState();
}

class _AuditPickAuditorDialogState extends State<_AuditPickAuditorDialog> {
  final _supabase   = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allAuditors = [];
  List<Map<String, dynamic>> _filtered    = [];
  late List<AuditAssignmentData> _assignments;
  bool _loading = true;
  bool _locationFieldsAvailable = true;
  int _currentPage = 1;

  String? _filterJabatan;
  String? _filterLevelType;
  String? _filterLevelId;
  String? _filterLevelName;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _assignments = List<AuditAssignmentData>.from(widget.initialAssignments);
    _searchCtrl.addListener(_applyFilters);
    _loadAuditors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAuditors() async {
    List<dynamic> rows;
    try {
      rows = await _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, id_lokasi, id_unit, id_subunit, id_area, is_verificator, '
              'jabatan!User_id_jabatan_fkey(id_jabatan, nama_jabatan)')
          .order('nama');
    } catch (_) {
      _locationFieldsAvailable = false;
      rows = await _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, is_verificator, '
              'jabatan!User_id_jabatan_fkey(id_jabatan, nama_jabatan)')
          .order('nama');
    }

    if (!mounted) return;

    final filteredRows = List<Map<String, dynamic>>.from(rows).where((u) {
      final j = u['jabatan'] as Map<String, dynamic>?;
      final rawId = j?['id_jabatan'];
      final idJabatan = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      final namaJabatan = (j?['nama_jabatan']?.toString() ?? '').toLowerCase();
      final isAdmin = idJabatan == kAdminJabatanId || namaJabatan.contains('admin');
      return !isAdmin;
    }).toList();

    setState(() {
      _allAuditors = filteredRows;
      _filtered    = _allAuditors;
      _loading     = false;
    });
  }

  int get _totalPages {
    final p = (_filtered.length / kPickAuditorPerPage).ceil();
    return p < 1 ? 1 : p;
  }

  List<Map<String, dynamic>> get _pageItems {
    final start = (_currentPage - 1) * kPickAuditorPerPage;
    if (start >= _filtered.length) return [];
    final end = (start + kPickAuditorPerPage) > _filtered.length
        ? _filtered.length
        : start + kPickAuditorPerPage;
    return _filtered.sublist(start, end);
  }

  void _goToPage(int page) => setState(() => _currentPage = page);

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _allAuditors.where((u) {
        if (q.isNotEmpty && !(u['nama'] ?? '').toString().toLowerCase().contains(q)) {
          return false;
        }
        if (_filterJabatan != null) {
          if (_filterJabatan == kVerificatorFilterKey) {
            if (u['is_verificator'] != true) return false;
          } else {
            final j = (u['jabatan'] as Map<String, dynamic>?)?['nama_jabatan']?.toString();
            if (j != _filterJabatan) return false;
          }
        }
        if (_filterLevelType != null && _filterLevelId != null) {
          final idCol = 'id_$_filterLevelType';
          if (u[idCol]?.toString() != _filterLevelId) return false;
        }
        return true;
      }).toList();
      _currentPage = 1;
    });
  }

  AuditAssignmentData? _assignmentFor(String userId) {
    for (final a in _assignments) {
      if (a.auditor['id_user']?.toString() == userId) return a;
    }
    return null;
  }

  Future<void> _pickLocationFor(Map<String, dynamic> auditor) async {
    final used = _assignments
        .map((a) => AuditUsedLocation(
              levelType: a.levelType,
              idRef: a.idRef,
              auditorName: a.auditor['nama']?.toString() ?? '-',
            ))
        .toList();

    final result = await showAuditLocationPicker(
      context: context,
      lang: widget.lang,
      auditor: auditor,
      usedLocations: used,
    );

    if (result != null) {
      setState(() {
        _assignments.add(AuditAssignmentData(
          auditor: Map<String, dynamic>.from(auditor),
          levelType: result.levelType,
          idRef: result.idRef,
          locationName: result.locationName,
        ));
      });
    }
  }

  void _removeAssignment(String userId) {
    setState(() {
      _assignments.removeWhere((a) => a.auditor['id_user']?.toString() == userId);
    });
  }

  Future<void> _openJabatanFilter() async {
    List<dynamic> jabatanRows = [];
    try {
      jabatanRows = await _supabase
          .from('jabatan')
          .select('id_jabatan, nama_jabatan')
          .order('id_jabatan');
    } catch (e) {
      debugPrint('Error loading jabatan list: $e');
    }

    final options = <_JabatanFilterOption>[
      for (final row in jabatanRows)
        if ((row as Map<String, dynamic>)['id_jabatan'] != kAdminJabatanId &&
            !(row['nama_jabatan']?.toString().toLowerCase().contains('admin') ?? false))
          _JabatanFilterOption(
            value: row['nama_jabatan'].toString(),
            label: row['nama_jabatan'].toString(),
            color: adminRoleColor(row['id_jabatan'] as int?),
            icon: adminRoleIcon(row['id_jabatan'] as int?),
          ),
      _JabatanFilterOption(
        value: kVerificatorFilterKey,
        label: _t('Verificator', 'Verifikator', '核查员'),
        color: _kVerificatorColor,
        icon: _kVerificatorIcon,
      ),
    ];

    final picked = await showDialog<String?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => _FilterOptionsDialog(
        lang: widget.lang,
        title: _t('Filter by Position', 'Filter Jabatan', '按职位筛选'),
        icon: Icons.badge_rounded,
        selected: _filterJabatan,
        options: options,
      ),
    );

    if (picked != 'no_change') {
      setState(() => _filterJabatan = picked);
      _applyFilters();
    }
  }

  Future<void> _openLocationFilter() async {
    if (!_locationFieldsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('Specific location filter unavailable', 'Filter lokasi spesifik tidak tersedia', '具体位置筛选不可用')),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final result = await showDialog<AuditLocationResult?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => _LocationFilterDialog(lang: widget.lang),
    );

    if (result != null) {
      setState(() {
        _filterLevelType = result.levelType;
        _filterLevelId   = result.idRef;
        _filterLevelName = result.locationName;
      });
      _applyFilters();
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
                      child: const Icon(Icons.person_add_alt_1_rounded, color: _kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('Add Auditor', 'Tambah Auditor', '添加审计员'),
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _kPrimary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, _assignments),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                            hintText: _t('Search auditor…', 'Cari auditor…', '搜索审计员…'),
                            hintStyle: GoogleFonts.poppins(fontSize: 12, color: _kTextSub),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // FILTER CHIPS
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _filterChip(
                        icon: Icons.badge_rounded,
                        label: _filterJabatan ?? _t('Position', 'Jabatan', '职位'),
                        active: _filterJabatan != null,
                        onTap: _openJabatanFilter,
                        onClear: _filterJabatan == null
                            ? null
                            : () {
                                setState(() => _filterJabatan = null);
                                _applyFilters();
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _filterChip(
                        icon: Icons.map_rounded,
                        label: _filterLevelName ?? _t('Specific Location', 'Lokasi Spesifik', '具体位置'),
                        active: _filterLevelId != null,
                        onTap: _openLocationFilter,
                        onClear: _filterLevelId == null
                            ? null
                            : () {
                                setState(() {
                                  _filterLevelType = null;
                                  _filterLevelId   = null;
                                  _filterLevelName = null;
                                });
                                _applyFilters();
                              },
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              // AUDITOR LIST
              Expanded(
                child: _loading
                    ? _buildAuditorListShimmer()
                    : _filtered.isEmpty
                        ? _buildAuditorEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            itemCount: _pageItems.length,
                            itemBuilder: (_, i) {
                              final u = _pageItems[i];
                              final userId = u['id_user']?.toString() ?? '';
                              final assignment = _assignmentFor(userId);
                              return _auditorCard(u, assignment);
                            },
                          ),
              ),
              // PAGE INDICATOR 
              if (!_loading && _filtered.length > kPickAuditorPerPage)
                _AuditorPageIndicator(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageChanged: _goToPage,
                ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              // FOOTER
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 14),
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
                    child: Text(
                      '${_t('Done', 'Selesai', '完成')} (${_assignments.length})',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _kPrimary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _kPrimary : Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: active ? _kPrimary : _kTextSub),
                if (onClear != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded, size: 13, color: _kPrimary.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: active ? _kPrimary : _kTextSub)),
          ],
        ),
      ),
    );
  }

  Widget _auditorCard(Map<String, dynamic> user, AuditAssignmentData? assignment) {
    final jData = user['jabatan'] as Map<String, dynamic>?;
    final jabatanRaw = jData?['nama_jabatan']?.toString();
    final rawJabatanId = jData?['id_jabatan'];
    final jabatanId = rawJabatanId is int ? rawJabatanId : int.tryParse(rawJabatanId?.toString() ?? '');
    final jabatan = _shouldShowJabatan(jabatanRaw) ? jabatanRaw : null;
    final isVerificator = user['is_verificator'] == true;
    final isAssigned = assignment != null;
    final levelIdx = isAssigned ? kAuditLevelKeys.indexOf(assignment.levelType) : -1;
    final levelColor = levelIdx >= 0 ? kAuditLevelColors[levelIdx] : _kGreen;
    final levelIcon  = levelIdx >= 0 ? kAuditLevelIcons[levelIdx] : Icons.verified_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAssigned ? levelColor.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAssigned ? levelColor.withValues(alpha: 0.35) : Colors.grey.shade200,
          width: isAssigned ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _kPrimaryLt,
            backgroundImage: user['gambar_user'] != null
                ? NetworkImage(user['gambar_user'] as String)
                : null,
            child: user['gambar_user'] == null
                ? Text(
                    (user['nama'] as String? ?? '?').isNotEmpty
                        ? (user['nama'] as String)[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _kPrimary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['nama'] ?? '-',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: _kNameColor)),
                if (jabatan != null && !isVerificator) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: adminRoleColor(jabatanId).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: adminRoleColor(jabatanId).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(adminRoleIcon(jabatanId), size: 10, color: adminRoleColor(jabatanId)),
                        const SizedBox(width: 4),
                        Text(jabatan,
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.w700, color: adminRoleColor(jabatanId))),
                      ],
                    ),
                  ),
                ],
                if (isVerificator) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kVerificatorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _kVerificatorColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_kVerificatorIcon, size: 10, color: _kVerificatorColor),
                        const SizedBox(width: 4),
                        Text(_t('Verificator', 'Verifikator', '核查员'),
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.w700, color: _kVerificatorColor)),
                      ],
                    ),
                  ),
                ],
                if (isAssigned) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(levelIcon, size: 11, color: levelColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(assignment.locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: levelColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isAssigned)
            GestureDetector(
              onTap: () => _removeAssignment(user['id_user']?.toString() ?? ''),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _pickLocationFor(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_t('Assign', 'Tugaskan', '分配'),
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildAuditorListShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 76,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildAuditorEmptyState() {
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
                child: const Icon(Icons.person_search_rounded, size: 40, color: _kPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t('No Auditors Found', 'Auditor Tidak Ditemukan', '未找到审计员'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _kNameColor),
            ),
            const SizedBox(height: 6),
            Text(
              _t(
                'Try a different name, or adjust your position and location filters.',
                'Coba nama lain, atau ubah filter jabatan dan lokasi Anda.',
                '请尝试其他姓名，或调整职位与位置筛选条件。',
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

class _AuditorPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _AuditorPageIndicator({
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

class _FilterOptionsDialog extends StatelessWidget {
  final String lang;
  final String title;
  final IconData icon;
  final String? selected;
  final List<_JabatanFilterOption> options;

  const _FilterOptionsDialog({
    required this.lang,
    required this.title,
    required this.icon,
    required this.selected,
    required this.options,
  });

  String _t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _kPrimaryLt, borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: _kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title,
                          style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w800, color: _kPrimary)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, 'no_change'),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  shrinkWrap: true,
                  children: [
                    _optionTile(context, null),
                    ...options.map((o) => _optionTile(context, o)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(BuildContext context, _JabatanFilterOption? option) {
    final isSelected = selected == option?.value;
    final color = option?.color ?? _kPrimary;
    final iconData = option?.icon ?? Icons.apps_rounded;
    final label = option?.label ?? _t('All', 'Semua', '全部');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, option?.value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : _kTextMain)),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LocationFilterDialog extends StatefulWidget {
  final String lang;
  const _LocationFilterDialog({required this.lang});

  @override
  State<_LocationFilterDialog> createState() => _LocationFilterDialogState();
}

class _LocationFilterDialogState extends State<_LocationFilterDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _supabase = Supabase.instance.client;
  final Map<int, List<Map<String, dynamic>>> _data = {};
  final Map<int, bool> _loading = {0: true, 1: true, 2: true, 3: true};
  final Map<int, int> _currentPage = {0: 1, 1: 1, 2: 1, 3: 1};

  static const int _kPerPage = 5;

  static const _tables   = ['lokasi', 'unit', 'subunit', 'area'];
  static const _idCols   = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'];
  static const _nameCols = ['nama_lokasi', 'nama_unit', 'nama_subunit', 'nama_area'];
  static const _fkHints = [
    'fk_lokasi_pic',
    'fk_unit_pic',
    'fk_subunit_pic',
    'fk_area_pic',
  ];

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    for (int i = 0; i < 4; i++) {
      _loadTab(i);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTab(int index) async {
    List<dynamic> rows;
    try {
      rows = await _supabase
          .from(_tables[index])
          .select(
              '${_idCols[index]}, ${_nameCols[index]}, id_pic, User_PIC:User!${_fkHints[index]}(nama, gambar_user)')
          .order(_nameCols[index]);
    } catch (_) {
      rows = await _supabase
          .from(_tables[index])
          .select('${_idCols[index]}, ${_nameCols[index]}')
          .order(_nameCols[index]);
    }
    if (!mounted) return;
    setState(() {
      _data[index]    = List<Map<String, dynamic>>.from(rows);
      _loading[index] = false;
    });
  }

  int _totalPagesFor(int index) {
    final len = (_data[index] ?? []).length;
    final p = (len / _kPerPage).ceil();
    return p < 1 ? 1 : p;
  }

  List<Map<String, dynamic>> _pageItemsFor(int index) {
    final list = _data[index] ?? [];
    final page = _currentPage[index] ?? 1;
    final start = (page - 1) * _kPerPage;
    if (start >= list.length) return [];
    final end = (start + _kPerPage) > list.length ? list.length : start + _kPerPage;
    return list.sublist(start, end);
  }

  void _goToPageFor(int index, int page) => setState(() => _currentPage[index] = page);

  Widget _locationFilterCard(int index, Map<String, dynamic> item) {
    final color = kAuditLevelColors[index];
    final icon  = kAuditLevelIcons[index];
    final id    = item[_idCols[index]]?.toString() ?? '';
    final name  = item[_nameCols[index]]?.toString() ?? '-';

    final picData  = item['User_PIC'] as Map<String, dynamic>?;
    final picName  = picData?['nama']?.toString();
    final picImage = picData?['gambar_user']?.toString();

    return GestureDetector(
      onTap: () => Navigator.pop(
          context, AuditLocationResult(levelType: _tables[index], idRef: id, locationName: name)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: color.withValues(alpha: 0.14),
                        backgroundImage: picImage != null ? NetworkImage(picImage) : null,
                        child: picImage == null
                            ? Icon(picName != null ? Icons.person_rounded : Icons.person_off_rounded,
                                size: 11, color: picName != null ? color : Colors.grey.shade400)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: picName != null
                            ? RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${_t('PIC', 'PIC', '负责人')} : ',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black),
                                    ),
                                    TextSpan(
                                      text: picName,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1D72F3)),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                _t('No PIC', 'Belum ada PIC', '暂无负责人'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5, fontWeight: FontWeight.w600, color: _kTextSub),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _kPrimaryLt, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.map_rounded, color: _kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_t('Filter by Specific Location', 'Filter Lokasi Spesifik', '按具体位置筛选'),
                          style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w800, color: _kPrimary)),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: AnimatedBuilder(
                  animation: _tabCtrl,
                  builder: (context, _) {
                    final labels = [
                      _t('Location', 'Lokasi', '位置'),
                      'Unit',
                      _t('Sub-Unit', 'Sub-Unit', '子单位'),
                      _t('Area', 'Area', '区域'),
                    ];
                    return Row(
                      children: List.generate(4, (index) {
                        final isActive = _tabCtrl.index == index;
                        final color = kAuditLevelColors[index];
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
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(kAuditLevelIcons[index], size: 15, color: isActive ? Colors.white : color),
                                  const SizedBox(height: 3),
                                  Text(labels[index],
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: isActive ? Colors.white : const Color(0xFF475569))),
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
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, (index) {
                    if (_loading[index] == true) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade100,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          itemCount: 6,
                          itemBuilder: (_, __) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            height: 56,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      );
                    }
                    final list = _data[index] ?? [];
                    if (list.isEmpty) {
                      return Center(
                        child: Text(_t('No data found', 'Data tidak ditemukan', '未找到数据'),
                            style: GoogleFonts.poppins(color: _kTextSub, fontWeight: FontWeight.w600)),
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                            itemCount: _pageItemsFor(index).length,
                            itemBuilder: (_, i) => _locationFilterCard(index, _pageItemsFor(index)[i]),
                          ),
                        ),
                        if (list.length > _kPerPage)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AuditorPageIndicator(
                              currentPage: _currentPage[index] ?? 1,
                              totalPages: _totalPagesFor(index),
                              onPageChanged: (p) => _goToPageFor(index, p),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}