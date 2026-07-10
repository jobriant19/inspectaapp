import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../picker/accident_pick_cause.dart';
import '../picker/accident_pick_severity.dart';
import 'accident_add_solution.dart';
import 'accident_edit_solution.dart';

class AccidentSolutionManagementScreen extends StatefulWidget {
  final String lang;
  const AccidentSolutionManagementScreen({super.key, required this.lang});

  @override
  State<AccidentSolutionManagementScreen> createState() =>
      _AccidentSolutionManagementScreenState();
}

class _AccidentSolutionManagementScreenState
    extends State<AccidentSolutionManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'Menunggu';
  int _currentPage = 1;
  static const int _itemsPerPage = 6;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('accident_report')
          .select('''
            id_laporan, judul, tingkat_keparahan, status, penyebab,
            tanggal_kejadian, foto_bukti, created_at,
            lokasi:id_lokasi(nama_lokasi)
          ''')
          .inFilter('status', ['Menunggu', 'Ditinjau', 'Selesai'])
          .order('created_at', ascending: false);

      final reportsList = List<Map<String, dynamic>>.from(data);

      final reportIds =
          reportsList.map((r) => r['id_laporan'] as String).toList();
      final Map<String, Map<String, dynamic>> resolutionMap = {};
      if (reportIds.isNotEmpty) {
        final resolutions = await supabase
            .from('resolution_accident')
            .select('''
              id_resolution, id_laporan, judul_resolusi, deskripsi_resolusi,
              tindakan_korektif, tindakan_preventif,
              tanggal_resolusi, created_at, foto_resolusi,
              hrd:resolution_accident_id_hrd_fkey(nama, gambar_user)
            ''')
            .inFilter('id_laporan', reportIds);
        for (final r in List<Map<String, dynamic>>.from(resolutions)) {
          resolutionMap[r['id_laporan'].toString()] = r;
        }
      }

      for (final r in reportsList) {
        r['_resolution'] = resolutionMap[r['id_laporan'].toString()];
      }

      if (mounted) {
        setState(() {
          _reports = reportsList;
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      debugPrint('Error fetching HRD reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredReports {
    final q = _searchQuery.trim().toLowerCase();
    return _reports.where((r) {
      if ((r['status'] ?? '') != _selectedStatus) return false;
      if (q.isEmpty) return true;
      final judul = (r['judul'] ?? '').toString().toLowerCase();
      final lokasi = (r['lokasi']?['nama_lokasi'] ?? '').toString().toLowerCase();
      final penyebabLabel =
          AccidentCauseData.labelOf(r['penyebab'] as String?, widget.lang).toLowerCase();
      final severityLabel =
          AccidentSeverityData.labelOf(r['tingkat_keparahan'] as String?, widget.lang).toLowerCase();
      return judul.contains(q) ||
          lokasi.contains(q) ||
          penyebabLabel.contains(q) ||
          severityLabel.contains(q);
    }).toList();
  }

  int get _totalPages {
    final len = _filteredReports.length;
    if (len == 0) return 1;
    return (len / _itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> get _paginatedReports {
    final filtered = _filteredReports;
    final start = (_currentPage - 1) * _itemsPerPage;
    if (start >= filtered.length) return [];
    final end = (start + _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  String _searchHint() {
    switch (widget.lang) {
      case 'EN':
        return 'Search reports...';
      case 'ZH':
        return '搜索报告...';
      default:
        return 'Cari laporan...';
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
              _currentPage = 1;
            });
          },
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
          decoration: InputDecoration(
            hintText: _searchHint(),
            hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF16A34A), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(CupertinoIcons.clear_circled_solid,
                        color: Color(0xFF94A3B8), size: 20),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _currentPage = 1;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    const statuses = ['Menunggu', 'Ditinjau', 'Selesai'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          for (final st in statuses) ...[
            Expanded(child: _buildStatusTab(st)),
            if (st != statuses.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTab(String status) {
    final isActive = _selectedStatus == status;
    final color = _statusColor(status);
    final bg = _statusBg(status);
    final icon = _statusIconFor(status);
    final label = _statusLabelFor(status);
    final count = _reports.where((r) => (r['status'] ?? '') == status).length;

    return GestureDetector(
      onTap: () {
        if (isActive) return;
        setState(() {
          _selectedStatus = status;
          _currentPage = 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? color : bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: isActive ? 1 : 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.white : color),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white.withValues(alpha: 0.85) : color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final totalPages = _totalPages;
    if (totalPages <= 1) return const SizedBox.shrink();
    const Color mainColor = Color(0xFF16A34A);
    final bool canPrev = _currentPage > 1;
    final bool canNext = _currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers(totalPages);

    return Container(
      margin: EdgeInsets.fromLTRB(15, 0, 15, 12 + MediaQuery.of(context).padding.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: mainColor.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _buildArrowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: canPrev,
            mainColor: mainColor,
            onTap: () {
              if (!canPrev) return;
              setState(() => _currentPage -= 1);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (final p in pageNumbers) ...[
                  Expanded(child: _buildPageNumberButton(p, mainColor)),
                  if (p != pageNumbers.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildArrowButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: canNext,
            mainColor: mainColor,
            onTap: () {
              if (!canNext) return;
              setState(() => _currentPage += 1);
            },
          ),
        ],
      ),
    );
  }

  List<int> _visiblePageNumbers(int totalPages) {
    const int maxVisible = 5;
    if (totalPages <= maxVisible) return List.generate(totalPages, (i) => i + 1);
    int start = _currentPage - 2;
    int end = _currentPage + 2;
    if (start < 1) {
      start = 1;
      end = maxVisible;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (maxVisible - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  Widget _buildPageNumberButton(int page, Color mainColor) {
    final bool isActive = page == _currentPage;
    return GestureDetector(
      onTap: () {
        if (page == _currentPage) return;
        setState(() => _currentPage = page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? mainColor : mainColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: mainColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(color: isActive ? Colors.white : mainColor, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool enabled,
    required Color mainColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? mainColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? mainColor : Colors.grey.shade400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF16A34A)),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          widget.lang == 'EN'
              ? 'Solution Management'
              : widget.lang == 'ZH'
                  ? '解决方案管理'
                  : 'Manajemen Solusi',
          style: GoogleFonts.poppins(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : Column(
              children: [
                _buildSearchBar(),
                _buildStatusTabs(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchReports,
                    color: const Color(0xFF16A34A),
                    child: _paginatedReports.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _paginatedReports.length,
                            itemBuilder: (_, i) => _buildReportCard(_paginatedReports[i]),
                          ),
                  ),
                ),
                _buildPaginationBar(),
              ],
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ditinjau':
        return const Color(0xFF2563EB);
      case 'Selesai':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFDC2626);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Ditinjau':
        return const Color(0xFFEFF6FF);
      case 'Selesai':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFFEF2F2);
    }
  }

  IconData _statusIconFor(String status) {
    switch (status) {
      case 'Ditinjau':
        return Icons.visibility_rounded;
      case 'Selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _statusLabelFor(String status) {
    switch (status) {
      case 'Ditinjau':
        return widget.lang == 'EN'
            ? 'Under Review'
            : widget.lang == 'ZH'
                ? '审核中'
                : 'Ditinjau';
      case 'Selesai':
        return widget.lang == 'EN'
            ? 'Completed'
            : widget.lang == 'ZH'
                ? '已完成'
                : 'Selesai';
      default:
        return widget.lang == 'EN'
            ? 'Pending'
            : widget.lang == 'ZH'
                ? '等待中'
                : 'Menunggu';
    }
  }

  Widget _buildChip(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> r) {
    final severityKey = r['tingkat_keparahan'] as String?;
    final severityLabel = AccidentSeverityData.labelOf(severityKey, widget.lang);
    final severityIcon = AccidentSeverityData.iconOf(severityKey);
    final sevColor = AccidentSeverityData.colorOf(severityKey);
    final status = r['status'] ?? '';
    final locName = r['lokasi']?['nama_lokasi'] ?? '-';
    final penyebabKey = r['penyebab'] as String?;
    final penyebabLabel = AccidentCauseData.labelOf(penyebabKey, widget.lang);
    final penyebabIcon = AccidentCauseData.iconOf(penyebabKey);
    final penyebabColor = AccidentCauseData.colorOf(penyebabKey);

    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);
    final statusIcon = _statusIconFor(status);
    final statusLabel = _statusLabelFor(status);

    return GestureDetector(
      onTap: () async {
        final existingSolution = r['_resolution'] as Map<String, dynamic>?;
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => existingSolution == null
                ? AccidentAddSolutionScreen(
                    reportId: r['id_laporan'] as String,
                    reportTitle: r['judul'] ?? '-',
                    lang: widget.lang,
                  )
                : HrdSolutionDetailScreen(
                    reportId: r['id_laporan'] as String,
                    reportTitle: r['judul'] ?? '-',
                    lang: widget.lang,
                    existingSolution: existingSolution,
                  ),
          ),
        );
        if (changed == true) _fetchReports();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF16A34A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withValues(alpha:0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PHOTO
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: sevColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08), width: 1.2),
              ),
              child: r['foto_bukti'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: Image.network(r['foto_bukti'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.warning_amber_rounded,
                              color: sevColor,
                              size: 32)))
                  : Icon(Icons.warning_amber_rounded,
                      color: sevColor, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r['judul'] ?? '-',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: const Color(0xFF1E293B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(statusLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_city_rounded,
                            size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(locName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip(
                        penyebabIcon,
                        penyebabLabel,
                        penyebabColor.withValues(alpha:0.1),
                        penyebabColor,
                      ),
                      const SizedBox(width: 6),
                      _buildChip(
                        severityIcon,
                        severityLabel,
                        sevColor.withValues(alpha:0.1),
                        sevColor,
                      ),
                      const Spacer(),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 14,
                          color: Color(0xFF16A34A)),
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

  String _emptyMessageFor(String status) {
    switch (status) {
      case 'Ditinjau':
        return widget.lang == 'EN'
            ? 'No reports under review'
            : widget.lang == 'ZH'
                ? '没有正在审核的报告'
                : 'Belum ada laporan yang sedang ditinjau';
      case 'Selesai':
        return widget.lang == 'EN'
            ? 'No completed reports yet'
            : widget.lang == 'ZH'
                ? '还没有已完成的报告'
                : 'Belum ada laporan yang selesai';
      default:
        return widget.lang == 'EN'
            ? 'No pending reports'
            : widget.lang == 'ZH'
                ? '没有等待中的报告'
                : 'Belum ada laporan yang menunggu';
    }
  }

  Widget _buildEmpty() {
    final color = _statusColor(_selectedStatus);
    final bg = _statusBg(_selectedStatus);
    final icon = _statusIconFor(_selectedStatus);
    final message = _emptyMessageFor(_selectedStatus);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, size: 44, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFDCFCE7),
      highlightColor: const Color(0xFFF0FDF4),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}