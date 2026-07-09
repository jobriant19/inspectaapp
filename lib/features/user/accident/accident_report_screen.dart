import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/popup/location_permission_popup.dart';
import 'accident_detail_screen.dart';
import 'accident_report_form_screen.dart';
import 'accident_result_popup.dart';
import 'accident_resolution_management_screen.dart';

class AccidentReportListScreen extends StatefulWidget {
  final String lang;
  const AccidentReportListScreen({super.key, required this.lang});

  @override
  State<AccidentReportListScreen> createState() =>
      _AccidentReportListScreenState();
}

class _AccidentReportListScreenState
    extends State<AccidentReportListScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  bool _isOpeningForm = false;
  String? _currentUserId;

  @override
  bool get wantKeepAlive => true;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Laporan Kecelakaan',
      'add': 'Buat Laporan',
      'history_title': 'Histori Laporan Anda',
      'empty_title': 'Belum Ada Laporan',
      'empty_sub': 'Buat laporan kecelakaan pertama Anda.',
      'delete': 'Hapus',
      'cancel': 'Batal',
      'delete_confirm': 'Hapus laporan ini?',
      'deleted': 'Laporan dihapus',
      'status_waiting': 'Menunggu',
      'status_review': 'Ditinjau',
      'status_done': 'Selesai',
      'severity': 'Keparahan',
      'location': 'Lokasi',
      'date': 'Tanggal',
    },
    'EN': {
      'title': 'Accident Reports',
      'add': 'Create Report',
      'history_title': 'Your Report History',
      'empty_title': 'No Reports Yet',
      'empty_sub': 'Create your first accident report.',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'delete_confirm': 'Delete this report?',
      'deleted': 'Report deleted',
      'status_waiting': 'Pending',
      'status_review': 'Under Review',
      'status_done': 'Completed',
      'severity': 'Severity',
      'location': 'Location',
      'date': 'Date',
    },
    'ZH': {
      'title': '事故报告',
      'add': '创建报告',
      'history_title': '您的报告历史',
      'empty_title': '暂无报告',
      'empty_sub': '创建您的第一份事故报告。',
      'delete': '删除',
      'cancel': '取消',
      'delete_confirm': '删除此报告？',
      'deleted': '报告已删除',
      'status_waiting': '等待中',
      'status_review': '审核中',
      'status_done': '已完成',
      'severity': '严重程度',
      'location': '地点',
      'date': '日期',
    },
  };

  String? _currentUserJabatanId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchReports();
    _loadCurrentUserJabatan();
  }

  Future<bool> _checkAtmiOrBlock() async {
    final result = await LocationPermissionPopup.requestWithPopup(context, lang: widget.lang);
    if (result.isAtAtmi) return true;

    if (!mounted) return false;
    final msg = widget.lang == 'EN'
        ? 'This action can only be done within PT ATMI Solo area.'
        : widget.lang == 'ZH'
            ? '此操作只能在PT ATMI Solo区域内进行。'
            : 'Aksi ini hanya dapat dilakukan di area PT ATMI Solo.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.location_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    return false;
  }

  Future<void> _loadCurrentUserJabatan() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('User')
          .select('id_jabatan')
          .eq('id_user', userId)
          .single();
      if (mounted) {
        setState(() {
          _currentUserJabatanId = data['id_jabatan']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading jabatan: $e');
    }
  }

  bool get _isHrd => _currentUserJabatanId == '5';

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('accident_report')
          .select('''
            id_laporan, judul, deskripsi, foto_bukti,
            tanggal_kejadian, waktu_kejadian, penyebab,
            tingkat_keparahan, departemen_terdampak,
            tindakan_diambil, status, poin_laporan,
            created_at, id_pelapor,
            id_lokasi, id_unit, id_subunit, id_area,
            lokasi:id_lokasi(nama_lokasi),
            unit:id_unit(nama_unit),
            subunit:id_subunit(nama_subunit),
            area:id_area(nama_area)
          ''')
          .eq('id_pelapor', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.trash_fill,
                    color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                t['delete_confirm']!,
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.lang == 'EN'
                    ? 'This action cannot be undone.'
                    : widget.lang == 'ZH'
                        ? '此操作无法撤销。'
                        : 'Tindakan ini tidak dapat dibatalkan.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            t['cancel']!,
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEF4444),
                              Color(0xFFDC2626)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFEF4444).withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            t['delete']!,
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('accident_report')
          .delete()
          .eq('id_laporan', id);
      if (mounted) {
        await showResultPopup(
          context,
          icon: CupertinoIcons.trash_fill,
          iconColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFFFF1F2),
          message: t['deleted']!,
        );
        if (mounted) _fetchReports();
      }
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }

  Color _severityColor(String sev) {
    switch (sev) {
      case 'Berat':
        return const Color(0xFFDC2626);
      case 'Menengah':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF16A34A);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return const Color(0xFFDC2626);
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
      case 'Menunggu':
        return const Color(0xFFFEF2F2);
      case 'Ditinjau':
        return const Color(0xFFEFF6FF);
      case 'Selesai':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFFEF2F2);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Ditinjau':
        return Icons.visibility_rounded;
      case 'Selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Ditinjau':
        return t['status_review']!;
      case 'Selesai':
        return t['status_done']!;
      default:
        return t['status_waiting']!;
    }
  }

  Map<String, dynamic> _locationBadgeInfo(Map<String, dynamic> r) {
    if (r['area'] != null && r['area']['nama_area'] != null) {
      return {
        'label': r['area']['nama_area'].toString(),
        'icon': Icons.place_rounded,
        'color': const Color(0xFFF472B6),
      };
    }
    if (r['subunit'] != null && r['subunit']['nama_subunit'] != null) {
      return {
        'label': r['subunit']['nama_subunit'].toString(),
        'icon': Icons.layers_rounded,
        'color': const Color(0xFFFBBF24),
      };
    }
    if (r['unit'] != null && r['unit']['nama_unit'] != null) {
      return {
        'label': r['unit']['nama_unit'].toString(),
        'icon': Icons.business_rounded,
        'color': const Color(0xFF6366F1),
      };
    }
    if (r['lokasi'] != null && r['lokasi']['nama_lokasi'] != null) {
      return {
        'label': r['lokasi']['nama_lokasi'].toString(),
        'icon': Icons.location_city_rounded,
        'color': const Color(0xFF10B981),
      };
    }
    return {
      'label': '-',
      'icon': Icons.location_off_rounded,
      'color': const Color(0xFF94A3B8),
    };
  }

  Widget _buildLocationBadge(Map<String, dynamic> r) {
    final loc = _locationBadgeInfo(r);
    final Color color = loc['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(loc['icon'] as IconData, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              loc['label'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back,
              color: Color.fromARGB(255, 235, 37, 37)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t['title']!,
            style: GoogleFonts.poppins(
                color: const Color.fromARGB(255, 235, 37, 37),
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _fetchReports,
              color: const Color(0xFF2563EB),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreateButton(),
                    const SizedBox(height: 28),
                    Text(
                      t['history_title']!,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444)),
                    ),
                    const SizedBox(height: 14),
                    if (_reports.isEmpty)
                      _buildEmpty()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reports.length,
                        itemBuilder: (_, i) =>
                            _buildCard(_reports[i]),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCreateButton() {
    return Column(
      children: [
        // CREATE REPORT BUTTON
        GestureDetector(
          onTap: () async {
            if (_isOpeningForm) return;
            _isOpeningForm = true;

            // CHECK LOCATION
            if (!await _checkAtmiOrBlock()) {
              _isOpeningForm = false;
              return;
            }

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccidentReportFormScreen(lang: widget.lang),
              ),
            );
            _isOpeningForm = false;
            if (result == true) _fetchReports();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(246, 246, 59, 59),
                  Color.fromARGB(255, 216, 29, 29)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color.fromARGB(255, 246, 59, 59).withValues(alpha:0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.health_and_safety_outlined,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['add']!,
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.lang == 'ZH'
                            ? '记录工作场所事故'
                            : widget.lang == 'EN'
                                ? 'Record workplace accidents'
                                : 'Catat kecelakaan di tempat kerja',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha:0.85)),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),

        // HRD SOLUTION BUTTON ONLY id_jabatan = 5
        if (_isHrd) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccidentResolutionManagementScreen(
                    lang: widget.lang,
                  ),
                ),
              );
              _fetchReports();
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha:0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                        CupertinoIcons.checkmark_shield_fill,
                        color: Colors.white,
                        size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lang == 'EN'
                              ? 'Solution Management'
                              : widget.lang == 'ZH'
                                  ? '解决方案管理'
                                  : 'Manajemen Solusi',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.lang == 'EN'
                              ? 'Manage corrective & preventive actions'
                              : widget.lang == 'ZH'
                                  ? '管理纠正和预防措施'
                                  : 'Kelola tindakan korektif & preventif',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha:0.85)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final status = (r['status'] ?? 'Menunggu').toString();
    final severity = r['tingkat_keparahan'] ?? '';
    final penyebab = r['penyebab'] ?? '-';
    final dateStr = r['tanggal_kejadian'] != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(r['tanggal_kejadian']))
        : '-';
    final isOwner = r['id_pelapor'] == _currentUserId;
    final sevColor = _severityColor(severity);
    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);
    final statusIcon = _statusIcon(status);
    final statusText = _statusLabel(status);

    const double imgSize = 85;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccidentReportDetailScreen(
              reportId: r['id_laporan'] as String,
              lang: widget.lang,
            ),
          ),
        );
        if (result == true) _fetchReports();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFEF4444), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 246, 59, 59).withValues(alpha:0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN: IMAGE + BOTTOM EDIT/DELETE BUTTON
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: imgSize,
                    height: imgSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          sevColor.withValues(alpha:0.15),
                          sevColor.withValues(alpha:0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.black.withValues(alpha:0.15),
                          width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: r['foto_bukti'] != null
                          ? Image.network(
                              r['foto_bukti'],
                              width: imgSize,
                              height: imgSize,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  Icons.warning_amber_rounded,
                                  color: sevColor,
                                  size: 30),
                            )
                          : Icon(Icons.warning_amber_rounded,
                              color: sevColor, size: 30),
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: imgSize,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: CupertinoIcons.pencil_ellipsis_rectangle,
                              color: const Color(0xFF2563EB),
                              bgColor: const Color(0xFFEFF6FF),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AccidentReportFormScreen(
                                      lang: widget.lang,
                                      existingReport: r,
                                    ),
                                  ),
                                );
                                if (result == true) _fetchReports();
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildActionButton(
                              icon: CupertinoIcons.trash,
                              color: const Color(0xFFEF4444),
                              bgColor: const Color(0xFFFFF1F2),
                              onTap: () =>
                                  _deleteReport(r['id_laporan'] as String),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 12),

              // RIGHT COLUMN: CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE + SEVERITY BADGE (POSISI POIN BADGE PADA KTS)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            r['judul'] ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.3,
                                color: const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: sevColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: sevColor, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 11, color: sevColor),
                              const SizedBox(width: 3),
                              Text(severity,
                                  style: GoogleFonts.inter(
                                      color: sevColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // LOCATION BADGE (PENGGANTI "PT ATMI SOLO")
                    _buildLocationBadge(r),
                    const SizedBox(height: 6),

                    // CHIPS: MESIN (PENYEBAB) & TINGKAT KEPARAHAN
                    Row(
                      children: [
                        Flexible(
                          child: _buildChip(
                            Icons.medical_services_outlined,
                            penyebab,
                            const Color(0xFFF5F3FF),
                            const Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildChip(
                          Icons.warning_amber_rounded,
                          severity,
                          sevColor.withValues(alpha:0.1),
                          sevColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // TIME BADGE: TANGGAL (KIRI) + STATUS (KANAN)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1.1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Text(dateStr,
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
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
                                Icon(statusIcon, size: 13, color: statusColor),
                                const SizedBox(width: 4),
                                Text(statusText,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor)),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildChip(
      IconData icon, String label, Color bg, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(13),
          border:
              Border.all(color: color.withValues(alpha:0.25), width: 1.1),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 246, 59, 59).withValues(alpha:0.1),
                  const Color.fromARGB(255, 216, 29, 29).withValues(alpha:0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_outlined,
                size: 52, color: Color.fromARGB(255, 235, 37, 37)),
          ),
          const SizedBox(height: 24),
          Text(t['empty_title']!,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(t['empty_sub']!,
              style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFFFCDD2),
      highlightColor: const Color(0xFFFFEBEE),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(
                3,
                (_) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}

class AccidentResolutionScreen extends StatefulWidget {
  final String reportId;
  final String lang;

  const AccidentResolutionScreen({
    super.key,
    required this.reportId,
    required this.lang,
  });

  @override
  State<AccidentResolutionScreen> createState() =>
      _AccidentResolutionScreenState();
}

class _AccidentResolutionScreenState
    extends State<AccidentResolutionScreen> {
  Map<String, dynamic>? _resolution;
  bool _isLoading = true;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Solusi Laporan',
      'no_resolution': 'Belum Ada Solusi',
      'no_resolution_sub':
          'HRD belum memberikan solusi untuk laporan ini.',
      'judul': 'Judul Solusi',
      'desc': 'Deskripsi Solusi',
      'korektif': 'Tindakan Korektif',
      'preventif': 'Tindakan Preventif',
      'date': 'Tanggal Solusi',
      'by': 'Diselesaikan oleh',
      'badge': 'SOLUSI HRD',
    },
    'EN': {
      'title': 'Report Solution',
      'no_resolution': 'No Solution Yet',
      'no_resolution_sub':
          'HRD has not provided a solution for this report.',
      'judul': 'Solution Title',
      'desc': 'Solution Description',
      'korektif': 'Corrective Action',
      'preventif': 'Preventive Action',
      'date': 'Solution Date',
      'by': 'Resolved by',
      'badge': 'HRD SOLUTION',
    },
    'ZH': {
      'title': '报告解决方案',
      'no_resolution': '暂无解决方案',
      'no_resolution_sub': 'HRD尚未提供此报告的解决方案。',
      'judul': '解决方案标题',
      'desc': '解决方案描述',
      'korektif': '纠正措施',
      'preventif': '预防措施',
      'date': '解决日期',
      'by': '解决人',
      'badge': 'HRD解决方案',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadResolution();
  }

  Future<void> _loadResolution() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('resolution_accident')
          .select('''
            id_resolution, judul_resolusi, deskripsi_resolusi,
            tindakan_korektif, tindakan_preventif,
            tanggal_resolusi, created_at, foto_resolusi,
            hrd:resolution_accident_id_hrd_fkey(nama, gambar_user)
          ''')
          .eq('id_laporan', widget.reportId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _resolution = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading resolution: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
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
          icon: const Icon(CupertinoIcons.back,
              color: Color(0xFF2563EB)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t['title']!,
          style: GoogleFonts.inter(
              color: const Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _loadResolution,
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: _resolution == null
                    ? _buildEmpty()
                    : _buildContent(),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.doc_text_search,
                size: 52,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t['no_resolution']!,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                t['no_resolution_sub']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _resolution!;
    final hrd = r['hrd'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BADGE
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF15803D)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            t['badge']!,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 14),

        // SOLUTION TITLE
        Text(
          r['judul_resolusi'] ?? '-',
          style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 20),

        // INFO CARD: TIME & HRD
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha:0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(
                CupertinoIcons.calendar,
                t['date']!,
                _formatDate(r['tanggal_resolusi']),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.person_fill,
                        color: Color(0xFF2563EB), size: 18),
                    const SizedBox(width: 12),
                    Text(t['by']!,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF475569))),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          hrd?['nama'] ?? '-',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        hrd?['gambar_user'] != null
                            ? CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(
                                    hrd!['gambar_user']),
                              )
                            : Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    CupertinoIcons.person_fill,
                                    size: 14,
                                    color: Color(0xFF2563EB)),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // SOLUTION PHOTO
        if (r['foto_resolusi'] != null &&
            r['foto_resolusi'].toString().isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                r['foto_resolusi'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.photo,
                        size: 40, color: Color(0xFF16A34A)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // SOLUTION DESCRIPTION
        _buildSectionTitle(
            CupertinoIcons.doc_text_fill, t['desc']!),
        const SizedBox(height: 10),
        _buildTextCard(r['deskripsi_resolusi']),
        const SizedBox(height: 20),

        // CORRECTIVE ACTION
        if (r['tindakan_korektif'] != null &&
            r['tindakan_korektif'].toString().isNotEmpty) ...[
          _buildSectionTitle(
            CupertinoIcons.wrench_fill,
            t['korektif']!,
            color: const Color(0xFFF97316),
          ),
          const SizedBox(height: 10),
          _buildTextCard(r['tindakan_korektif'],
              borderColor: const Color(0xFFFFF7ED),
              bgColor: const Color(0xFFFFFBF5)),
          const SizedBox(height: 20),
        ],

        // PREVENTIF ACTION
        if (r['tindakan_preventif'] != null &&
            r['tindakan_preventif'].toString().isNotEmpty) ...[
          _buildSectionTitle(
            CupertinoIcons.shield_fill,
            t['preventif']!,
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _buildTextCard(r['tindakan_preventif'],
              borderColor: const Color(0xFFDCFCE7),
              bgColor: const Color(0xFFF0FDF4)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF475569))),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title,
      {Color color = const Color(0xFF2563EB)}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildTextCard(
    String? text, {
    Color borderColor = const Color(0xFFE0E7FF),
    Color bgColor = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        text ?? '-',
        style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF334155),
            height: 1.6),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFFFCDD2),
      highlightColor: const Color(0xFFFFEBEE),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 28,
                width: 140,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 14),
            Container(
                height: 32,
                width: 260,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 20),
            Container(
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(
                height: 120,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }
}