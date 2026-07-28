import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/jabatan_helper.dart';
import 'accident_report_form_screen.dart';
import 'accident_result_popup.dart';
import 'solution/accident_solution_screen.dart';
import 'picker/accident_pick_cause.dart';
import 'picker/accident_pick_severity.dart';

class AccidentReportDetailScreen extends StatefulWidget {
  final String reportId;
  final String lang;

  const AccidentReportDetailScreen(
      {super.key, required this.reportId, required this.lang});

  @override
  State<AccidentReportDetailScreen> createState() =>
      _AccidentReportDetailScreenState();
}

class _AccidentReportDetailScreenState
    extends State<AccidentReportDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isDataChanged = false;
  bool _hasSolution = false;
  String? _currentUserId;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Detail Laporan Kecelakaan',
      'judul': 'Judul',
      'desc': 'Deskripsi Detail',
      'date': 'Tanggal Kejadian',
      'time': 'Waktu Kejadian',
      'location': 'Lokasi Kejadian',
      'cause': 'Penyebab Kecelakaan',
      'severity': 'Tingkat Keparahan',
      'dept': 'Departemen Terdampak',
      'action': 'Tindakan Diambil',
      'status': 'Status',
      'reporter': 'Dilaporkan oleh',
      'victim': 'Pihak Terdampak',
      'supervisor': 'Supervisor',
      'witness': 'Saksi',
      'badge': 'LAPORAN KECELAKAAN',
      'delete': 'Hapus',
      'cancel': 'Batal',
      'delete_confirm': 'Hapus laporan ini?',
      'deleted': 'Laporan dihapus',
      'points': 'Poin',
      'status_waiting': 'Belum Selesai',
      'status_review': 'Ditinjau',
      'status_done': 'Selesai',
    },
    'EN': {
      'title': 'Accident Report Detail',
      'judul': 'Title',
      'desc': 'Detailed Description',
      'date': 'Incident Date',
      'time': 'Incident Time',
      'location': 'Incident Location',
      'cause': 'Accident Cause',
      'severity': 'Severity',
      'dept': 'Affected Department',
      'action': 'Action Taken',
      'status': 'Status',
      'reporter': 'Reported by',
      'victim': 'Affected Party',
      'supervisor': 'Supervisor',
      'witness': 'Witness',
      'badge': 'ACCIDENT REPORT',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'delete_confirm': 'Delete this report?',
      'deleted': 'Report deleted',
      'points': 'Points',
      'status_waiting': 'Unfinished',
      'status_review': 'Under Review',
      'status_done': 'Finished',
    },
    'ZH': {
      'title': '事故报告详情',
      'judul': '标题',
      'desc': '详细描述',
      'date': '事故日期',
      'time': '事故时间',
      'location': '事故地点',
      'cause': '事故原因',
      'severity': '严重程度',
      'dept': '受影响部门',
      'action': '采取的措施',
      'status': '状态',
      'reporter': '报告人',
      'victim': '受影响方',
      'supervisor': '主管',
      'witness': '目击者',
      'badge': '事故报告',
      'delete': '删除',
      'cancel': '取消',
      'delete_confirm': '删除此报告？',
      'deleted': '已删除',
      'points': '积分',
      'status_waiting': '未完成',
      'status_review': '审核中',
      'status_done': '已完成',
    },
  };

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
        .from('accident_report')
        .select('''
          id_laporan, judul, deskripsi, foto_bukti,
          tanggal_kejadian, waktu_kejadian, penyebab,
          tingkat_keparahan, departemen_terdampak,
          tindakan_diambil, status,
          created_at, id_pelapor,
          id_lokasi, id_unit, id_subunit, id_area,
          nama_pihak_terdampak, nama_saksi,
          lokasi:id_lokasi(nama_lokasi),
          pelapor:accident_report_id_pelapor_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
          pihak_terdampak:accident_report_id_pihak_terdampak_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
          supervisor_user:accident_report_id_supervisor_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
          saksi_user:accident_report_id_saksi_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan))
        ''')
        .eq('id_laporan', widget.reportId)
        .single();

      bool hasSolution = false;
      if ((data['status'] ?? '') == 'Selesai') {
        final resolutionCheck = await Supabase.instance.client
            .from('resolution_accident')
            .select('id_resolution')
            .eq('id_laporan', widget.reportId)
            .maybeSingle();
        hasSolution = resolutionCheck != null;
      }

      if (mounted) {
        setState(() {
          _data = data;
          _hasSolution = hasSolution;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading detail: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
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
                    shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.trash_fill,
                    color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              Text(t['delete_confirm']!,
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                widget.lang == 'EN'
                    ? 'This action cannot be undone.'
                    : widget.lang == 'ZH'
                        ? '此操作无法撤销。'
                        : 'Tindakan ini tidak dapat dibatalkan.',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8)),
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
                            borderRadius:
                                BorderRadius.circular(14)),
                        child: Center(
                          child: Text(t['cancel']!,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      const Color(0xFF475569))),
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
                          gradient: const LinearGradient(colors: [
                            Color(0xFFEF4444),
                            Color(0xFFDC2626)
                          ]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(t['delete']!,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
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
          .eq('id_laporan', widget.reportId);
      if (mounted) {
        await showResultPopup(
          context,
          icon: CupertinoIcons.trash_fill,
          iconColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFFFF1F2),
          message: t['deleted']!,
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
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
        return const Color(0xFFFFF1F2);
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Ditinjau':
        return Icons.search_rounded;
      case 'Selesai':
        return Icons.check_circle_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try {
      return DateFormat('dd MMM yyyy')
          .format(DateTime.parse(d).toLocal());
    } catch (_) {
      return d;
    }
  }

  void _openAccidentImageViewer(String? url) {
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _AccidentDetailImageViewer(imageUrl: url),
      ),
    );
  }

  Widget _buildAppBarActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withValues(alpha:0.3), width: 1),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _data != null &&
        _data!['id_pelapor'] == _currentUserId;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _isDataChanged);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back,
                color: Color(0xFF2563EB)),
            onPressed: () =>
                Navigator.pop(context, _isDataChanged),
          ),
          title: Text(t['title']!,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
          centerTitle: true,
          actions: isOwner
              ? [
                  _buildAppBarActionButton(
                    icon: CupertinoIcons
                        .pencil_ellipsis_rectangle,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AccidentReportFormScreen(
                            lang: widget.lang,
                            existingReport: _data!,
                          ),
                        ),
                      );
                      if (result == true) {
                        _isDataChanged = true;
                        _loadData();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildAppBarActionButton(
                    icon: CupertinoIcons.trash,
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFFF1F2),
                    onTap: _deleteReport,
                  ),
                  const SizedBox(width: 8),
                ]
              : null,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
                color: CupertinoColors.systemGrey5, height: 1),
          ),
        ),
        body: _isLoading
            ? _buildDetailShimmer()
            : _data == null
                ? Center(
                    child: Text('Data tidak ditemukan',
                        style: GoogleFonts.inter(
                            color: CupertinoColors.systemGrey)))
                : _buildContent(),
      ),
    );
  }

  Widget _buildDetailShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFFFCDD2),
      highlightColor: const Color(0xFFFFEBEE),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                    height: 24,
                    width: 120,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(10))),
                const SizedBox(width: 8),
                Container(
                    height: 24,
                    width: 80,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(10))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
                height: 28,
                width: 220,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Container(
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard(Map<String, dynamic> d, String status,
      String severity, String? rawSeverity, Color sevColor) {
    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);
    final statusIcon = _statusIcon(status);
    final statusText = _statusLabel(status);
    const badgeColor = Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LINE 1: TITLE (LEFT) + BADGE ACCIDENT REPORT (TOP RIGHT)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d['judul'] ?? '-',
                  style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.3),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: badgeColor, width: 1.2),
                ),
                child: Text(t['badge']!,
                    style: GoogleFonts.inter(
                        color: badgeColor, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // LINE 2: SEVERITY (LEFT) + STATUS (RIGHT)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sevColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(AccidentSeverityData.iconOf(rawSeverity),
                        size: 13, color: sevColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        severity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: sevColor),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 5),
                  Text(statusText,
                      style: GoogleFonts.inter(
                          fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final status = d['status'] ?? 'Menunggu';
    final rawSeverity = d['tingkat_keparahan'] as String?;
    final severity = AccidentSeverityData.labelOf(rawSeverity, widget.lang);
    final sevColor = AccidentSeverityData.colorOf(rawSeverity);
    final locName = d['lokasi']?['nama_lokasi'] ?? '-';

    Map<String, dynamic>? getUserMap(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    }

    final pelapor = getUserMap(d['pelapor']);
    final victim = getUserMap(d['pihak_terdampak']);
    final supervisor = getUserMap(d['supervisor_user']);
    final witness = getUserMap(d['saksi_user']);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PHOTO
          if (d['foto_bukti'] != null)
            GestureDetector(
              onTap: () => _openAccidentImageViewer(d['foto_bukti']?.toString()),
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        d['foto_bukti'],
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fullscreen_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (d['foto_bukti'] != null)
            const SizedBox(height: 20),

          // TITLE CARD BARU
           _buildTitleCard(d, status, severity, rawSeverity, sevColor),
          const SizedBox(height: 20),

          // DESCRIPTION
          if (d['deskripsi'] != null &&
              d['deskripsi'].toString().isNotEmpty) ...[
            _buildSectionTitle(
                Icons.description_outlined, t['desc']!),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE0E7FF), width: 1.5),
              ),
              child: Text(d['deskripsi'],
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // ACTION TAKEN
          if (d['tindakan_diambil'] != null &&
              d['tindakan_diambil'].toString().isNotEmpty) ...[
            _buildSectionTitle(Icons.medical_services_outlined,
                t['action']!,
                color: const Color(0xFF1D72F3)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFDCFCE7), width: 1.5),
              ),
              child: Text(d['tindakan_diambil'],
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // INVOLVED PARTIES 
          _buildSectionTitle(
              CupertinoIcons.person_2_fill,
              widget.lang == 'EN'
                  ? 'Involved Parties'
                  : widget.lang == 'ZH'
                      ? '涉及人员'
                      : 'Pihak Terlibat'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFE0E7FF), width: 1.5),
            ),
            child: Column(
              children: [
                if (pelapor != null)
                  _buildPersonRow(t['reporter']!, pelapor,
                      CupertinoIcons.person_fill),

                if (victim != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['victim']!, victim,
                      Icons.person_outline),
                ] else if (d['nama_pihak_terdampak'] != null &&
                    d['nama_pihak_terdampak'].toString().isNotEmpty) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildManualPersonRow(
                    t['victim']!,
                    d['nama_pihak_terdampak'].toString(),
                    Icons.person_outline,
                  ),
                ],

                if (supervisor != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['supervisor']!, supervisor,
                      Icons.supervisor_account_outlined),
                ],

                if (witness != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['witness']!, witness,
                      Icons.visibility_outlined),
                ] else if (d['nama_saksi'] != null &&
                    d['nama_saksi'].toString().isNotEmpty) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildManualPersonRow(
                    t['witness']!,
                    d['nama_saksi'].toString(),
                    Icons.visibility_outlined,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // INFO CARD
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFE0E7FF), width: 1.5),
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
                _buildInfoRowBadge(
                    Icons.location_on_outlined,
                    t['location']!,
                    _buildValueBadge(Icons.location_city_rounded, locName,
                        const Color(0xFF10B981))),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(
                    Icons.calendar_today_outlined,
                    t['date']!,
                    _formatDate(d['tanggal_kejadian'])),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(Icons.access_time_rounded,
                    t['time']!,
                    d['waktu_kejadian']?.substring(0, 5) ?? '-'),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRowBadge(
                    Icons.warning_amber_rounded,
                    t['cause']!,
                    _buildValueBadge(
                        AccidentCauseData.iconOf(d['penyebab']),
                        AccidentCauseData.labelOf(d['penyebab'], widget.lang),
                        AccidentCauseData.colorOf(d['penyebab']))),
                if (d['departemen_terdampak'] != null) ...[
                  Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9)),
                  _buildInfoRowBadge(
                      Icons.business_outlined,
                      t['dept']!,
                      _buildValueBadge(Icons.business_rounded,
                          d['departemen_terdampak'], const Color(0xFF6366F1))),
                ],
              ],
            ),
          ),

          if (_hasSolution) ...[
            const SizedBox(height: 24),

            // VIEW SOLUTION BUTTON
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccidentResolutionScreen(
                      reportId: widget.reportId,
                      lang: widget.lang,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
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
                      child: const Icon(CupertinoIcons.checkmark_shield_fill,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lang == 'EN'
                                ? 'View Solution'
                                : widget.lang == 'ZH'
                                    ? '查看解决方案'
                                    : 'Lihat Solusi',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.lang == 'EN'
                                ? 'See HRD corrective & preventive actions'
                                : widget.lang == 'ZH'
                                    ? '查看HRD纠正和预防措施'
                                    : 'Lihat tindakan korektif & preventif HRD',
                            style: GoogleFonts.inter(
                                fontSize: 12,
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

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title,
      {Color color = const Color(0xFF1D72F3)}) {
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
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D72F3))),
      ],
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon,
              color: const Color(0xFF1D72F3), size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D72F3))),
          const Spacer(),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowBadge(
      IconData icon, String label, Widget valueBadge) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon,
              color: const Color(0xFF1D72F3), size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D72F3))),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueBadge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBadge(IconData icon, String label, Color color) {
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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
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

  Widget _buildPersonRow(String label,
      Map<String, dynamic> user, IconData icon) {
    final jabatanText = _jabatanLabel(user);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon,
              color: const Color(0xFF1D72F3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D72F3))),
          ),
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                user['gambar_user'] != null
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(user['gambar_user']))
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.person_fill,
                            size: 20, color: Color(0xFF1D72F3)),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nama'] ?? '-',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black),
                      ),
                      if (jabatanText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildJabatanBadge(user),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _jabatanLabel(Map<String, dynamic> user) {
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final jabatanNama =
        (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
    return JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
  }

  Widget _buildJabatanBadge(Map<String, dynamic> user) {
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final label = _jabatanLabel(user);
    if (label.isEmpty) return const SizedBox.shrink();
    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildManualPersonRow(
      String label, String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1D72F3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D72F3))),
          ),
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.person_fill,
                      size: 20, color: Color(0xFF1D72F3)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black),
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

class _AccidentDetailImageViewer extends StatelessWidget {
  final String imageUrl;
  const _AccidentDetailImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}