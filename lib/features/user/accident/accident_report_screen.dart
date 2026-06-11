import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/services/location_service.dart';
import 'accident_report_form_screen.dart';
import 'accident_result_popup.dart';

// ============================================================
// LAYAR DAFTAR LAPORAN KECELAKAAN
// ============================================================
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

  // Tambah field di atas initState
  String? _currentUserJabatanId;

  // Ganti initState
  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchReports();
    _loadCurrentUserJabatan();
  }

  Future<bool> _checkAtmiOrBlock() async {
    final result = await LocationService.instance.checkUserAtAtmi(
      forceRefresh: true,
    );
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

  // Tambah method baru
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
            lokasi:id_lokasi(nama_lokasi)
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
                color: Colors.black.withOpacity(0.12),
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
                                  const Color(0xFFEF4444).withOpacity(0.3),
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
      case 'Ditinjau':
        return const Color(0xFFF97316);
      case 'Selesai':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Ditinjau':
        return const Color(0xFFFFF7ED);
      case 'Selesai':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFEFF6FF);
    }
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
            style: GoogleFonts.inter(
                color: const Color.fromARGB(255, 235, 37, 37),
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchReports,
            icon: const Icon(CupertinoIcons.refresh,
                color: Color.fromARGB(255, 235, 37, 37)),
          ),
        ],
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
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569)),
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
        // Tombol utama Create Report (semua user)
        GestureDetector(
          onTap: () async {
            // ── Cek lokasi sebelum buat laporan ──
            if (!await _checkAtmiOrBlock()) return;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccidentReportFormScreen(lang: widget.lang),
              ),
            );
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
                      const Color.fromARGB(255, 246, 59, 59).withOpacity(0.4),
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
                    color: Colors.white.withOpacity(0.25),
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
                            color: Colors.white.withOpacity(0.85)),
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

        // Tombol HRD Resolution — hanya muncul jika id_jabatan = 5
        if (_isHrd) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _HrdResolutionListScreen(
                    lang: widget.lang,
                  ),
                ),
              );
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
                    color: const Color(0xFF16A34A).withOpacity(0.35),
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
                      color: Colors.white.withOpacity(0.25),
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
                              ? 'Resolution Management'
                              : widget.lang == 'ZH'
                                  ? '解决方案管理'
                                  : 'Manajemen Penyelesaian',
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
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85)),
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
    final status = r['status'] ?? 'Menunggu';
    final severity = r['tingkat_keparahan'] ?? '';
    final locName = r['lokasi']?['nama_lokasi'] ?? '-';
    final dateStr = r['tanggal_kejadian'] != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(r['tanggal_kejadian']))
        : '-';
    final isOwner = r['id_pelapor'] == _currentUserId;
    final sevColor = _severityColor(severity);

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
              color: const Color(0xFFE0E7FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          sevColor.withOpacity(0.15),
                          sevColor.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: r['foto_bukti'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              r['foto_bukti'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  Icons.warning_amber_rounded,
                                  color: sevColor,
                                  size: 30),
                            ),
                          )
                        : Icon(Icons.warning_amber_rounded,
                            color: sevColor, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(r['judul'] ?? '-',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color:
                                          const Color(0xFF1E293B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusBg(status),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(status,
                                  style: GoogleFonts.inter(
                                      color: _statusColor(status),
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(locName,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B))),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildChip(
                              Icons.calendar_today_rounded,
                              dateStr,
                              const Color(0xFFEFF6FF),
                              const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 8),
                            _buildChip(
                              Icons.warning_amber_rounded,
                              severity,
                              sevColor.withOpacity(0.1),
                              sevColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            size: 12, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 4),
                        Text(r['penyebab'] ?? '-',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF7C3AED),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(CupertinoIcons.calendar,
                      size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8))),
                  if (isOwner) ...[
                    const SizedBox(width: 10),
                    _buildActionButton(
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
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: CupertinoIcons.trash,
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFFF1F2),
                      onTap: () =>
                          _deleteReport(r['id_laporan'] as String),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withOpacity(0.25), width: 1),
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
                  const Color.fromARGB(255, 246, 59, 59).withOpacity(0.1),
                  const Color.fromARGB(255, 216, 29, 29).withOpacity(0.05),
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

// ============================================================
// LAYAR DETAIL LAPORAN KECELAKAAN
// ============================================================
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
  String? _currentUserId;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Detail Laporan Kecelakaan',
      'judul': 'Judul',
      'desc': 'Deskripsi',
      'date': 'Tanggal Kejadian',
      'time': 'Waktu Kejadian',
      'location': 'Lokasi',
      'cause': 'Penyebab',
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
    },
    'EN': {
      'title': 'Accident Report Detail',
      'judul': 'Title',
      'desc': 'Description',
      'date': 'Incident Date',
      'time': 'Incident Time',
      'location': 'Location',
      'cause': 'Cause',
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
    },
    'ZH': {
      'title': '事故报告详情',
      'judul': '标题',
      'desc': '描述',
      'date': '事故日期',
      'time': '事故时间',
      'location': '地点',
      'cause': '原因',
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
          pelapor:accident_report_id_pelapor_fkey(nama, gambar_user),
          pihak_terdampak:accident_report_id_pihak_terdampak_fkey(nama, gambar_user),
          supervisor_user:accident_report_id_supervisor_fkey(nama, gambar_user),
          saksi_user:accident_report_id_saksi_fkey(nama, gambar_user)
        ''')
        .eq('id_laporan', widget.reportId)
        .single();
      if (mounted) {
        setState(() {
          _data = data;
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
                color: Colors.black.withOpacity(0.12),
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
                                  .withOpacity(0.3),
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
      case 'Ditinjau':
        return const Color(0xFFF97316);
      case 'Selesai':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Ditinjau':
        return const Color(0xFFFFF7ED);
      case 'Selesai':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFEFF6FF);
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
              color: color.withOpacity(0.3), width: 1),
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
              style: GoogleFonts.inter(
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

  Widget _buildContent() {
    final d = _data!;
    final status = d['status'] ?? 'Menunggu';
    final severity = d['tingkat_keparahan'] ?? '';
    final sevColor = _severityColor(severity);
    final locName = d['lokasi']?['nama_lokasi'] ?? '-';

    // Ambil data user terkait — Supabase join result bisa map atau null
    Map<String, dynamic>? _getUserMap(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return null;
    }

    final pelapor = _getUserMap(d['pelapor']);
    final victim = _getUserMap(d['pihak_terdampak']);
    final supervisor = _getUserMap(d['supervisor_user']);
    final witness = _getUserMap(d['saksi_user']);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto Header
          if (d['foto_bukti'] != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  d['foto_bukti'],
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (d['foto_bukti'] != null)
            const SizedBox(height: 20),

          // Badge Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF1E40AF),
                    Color(0xFF2563EB)
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(t['badge']!,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _statusColor(status).withOpacity(0.3),
                      width: 1),
                ),
                child: Text(status,
                    style: GoogleFonts.inter(
                        color: _statusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sevColor.withOpacity(0.3), width: 1),
                ),
                child: Text(severity,
                    style: GoogleFonts.inter(
                        color: sevColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(d['judul'] ?? '-',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 24),

          // Info Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFE0E7FF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow(CupertinoIcons.location_fill,
                    t['location']!, locName),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(
                    CupertinoIcons.calendar,
                    t['date']!,
                    _formatDate(d['tanggal_kejadian'])),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(CupertinoIcons.clock_fill,
                    t['time']!,
                    d['waktu_kejadian']?.substring(0, 5) ?? '-'),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    t['cause']!,
                    d['penyebab'] ?? '-'),
                if (d['departemen_terdampak'] != null) ...[
                  Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9)),
                  _buildInfoRow(CupertinoIcons.building_2_fill,
                      t['dept']!, d['departemen_terdampak']),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Deskripsi
          if (d['deskripsi'] != null &&
              d['deskripsi'].toString().isNotEmpty) ...[
            _buildSectionTitle(
                CupertinoIcons.doc_text, t['desc']!),
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
                      color: const Color(0xFF334155),
                      height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // Tindakan
          if (d['tindakan_diambil'] != null &&
              d['tindakan_diambil'].toString().isNotEmpty) ...[
            _buildSectionTitle(CupertinoIcons.bandage_fill,
                t['action']!,
                color: const Color(0xFF16A34A)),
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
                      color: const Color(0xFF334155),
                      height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // Pihak Terlibat
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
                // Pelapor
                if (pelapor != null)
                  _buildPersonRow(t['reporter']!, pelapor,
                      CupertinoIcons.person_fill),

                // Victim — dari relasi atau nama manual
                if (victim != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['victim']!, victim,
                      CupertinoIcons.person_crop_circle_fill),
                ] else if (d['nama_pihak_terdampak'] != null &&
                    d['nama_pihak_terdampak'].toString().isNotEmpty) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildManualPersonRow(
                    t['victim']!,
                    d['nama_pihak_terdampak'].toString(),
                    CupertinoIcons.person_crop_circle_fill,
                  ),
                ],

                // Supervisor
                if (supervisor != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['supervisor']!, supervisor,
                      CupertinoIcons.person_badge_plus),
                ],

                // Witness — dari relasi atau nama manual
                if (witness != null) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['witness']!, witness,
                      CupertinoIcons.eye_fill),
                ] else if (d['nama_saksi'] != null &&
                    d['nama_saksi'].toString().isNotEmpty) ...[
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
                  _buildManualPersonRow(
                    t['witness']!,
                    d['nama_saksi'].toString(),
                    CupertinoIcons.eye_fill,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol Lihat Penyelesaian
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
                    color: const Color(0xFF16A34A).withOpacity(0.35),
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
                      color: Colors.white.withOpacity(0.25),
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
                          _data!['lokasi'] != null
                              ? (widget.lang == 'EN'
                                  ? 'View Resolution'
                                  : widget.lang == 'ZH'
                                      ? '查看解决方案'
                                      : 'Lihat Penyelesaian')
                              : (widget.lang == 'EN'
                                  ? 'View Resolution'
                                  : widget.lang == 'ZH'
                                      ? '查看解决方案'
                                      : 'Lihat Penyelesaian'),
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
                              color: Colors.white.withOpacity(0.85)),
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

          const SizedBox(height: 40),
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
            color: color.withOpacity(0.1),
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

  Widget _buildInfoRow(
      IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon,
              color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF475569))),
          const Spacer(),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow(String label,
      Map<String, dynamic> user, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon,
              color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF475569))),
          const Spacer(),
          Row(
            children: [
              Text(user['nama'] ?? '-',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF0F172A))),
              const SizedBox(width: 8),
              user['gambar_user'] != null
                  ? CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(
                          user['gambar_user']))
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
    );
  }

  Widget _buildManualPersonRow(
      String label, String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF475569))),
          const Spacer(),
          Text(name,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

// ============================================================
// LAYAR DETAIL RESOLUSI LAPORAN KECELAKAAN
// ============================================================
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
      'title': 'Penyelesaian Laporan',
      'no_resolution': 'Belum Ada Penyelesaian',
      'no_resolution_sub':
          'HRD belum memberikan penyelesaian untuk laporan ini.',
      'judul': 'Judul Penyelesaian',
      'desc': 'Deskripsi Penyelesaian',
      'korektif': 'Tindakan Korektif',
      'preventif': 'Tindakan Preventif',
      'date': 'Tanggal Penyelesaian',
      'by': 'Diselesaikan oleh',
      'badge': 'PENYELESAIAN HRD',
    },
    'EN': {
      'title': 'Report Resolution',
      'no_resolution': 'No Resolution Yet',
      'no_resolution_sub':
          'HRD has not provided a resolution for this report.',
      'judul': 'Resolution Title',
      'desc': 'Resolution Description',
      'korektif': 'Corrective Action',
      'preventif': 'Preventive Action',
      'date': 'Resolution Date',
      'by': 'Resolved by',
      'badge': 'HRD RESOLUTION',
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
        // Badge
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

        // Judul
        Text(
          r['judul_resolusi'] ?? '-',
          style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 20),

        // Info Card: tanggal & HRD
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.06),
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

        // Foto Resolusi
        if (r['foto_resolusi'] != null &&
            r['foto_resolusi'].toString().isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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

        // Deskripsi
        _buildSectionTitle(
            CupertinoIcons.doc_text_fill, t['desc']!),
        const SizedBox(height: 10),
        _buildTextCard(r['deskripsi_resolusi']),
        const SizedBox(height: 20),

        // Tindakan Korektif
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

        // Tindakan Preventif
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
            color: color.withOpacity(0.1),
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

// ============================================================
// LAYAR MANAJEMEN RESOLUSI — KHUSUS HRD (id_jabatan = 5)
// ============================================================
class _HrdResolutionListScreen extends StatefulWidget {
  final String lang;
  const _HrdResolutionListScreen({required this.lang});

  @override
  State<_HrdResolutionListScreen> createState() =>
      _HrdResolutionListScreenState();
}

class _HrdResolutionListScreenState
    extends State<_HrdResolutionListScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      // Ambil semua laporan yang statusnya Ditinjau atau sudah selesai
      // agar HRD bisa mengelola resolusi
      final data = await Supabase.instance.client
          .from('accident_report')
          .select('''
            id_laporan, judul, tingkat_keparahan, status,
            tanggal_kejadian, foto_bukti, created_at,
            lokasi:id_lokasi(nama_lokasi)
          ''')
          .inFilter('status', ['Menunggu', 'Ditinjau', 'Selesai'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching HRD reports: $e');
      if (mounted) setState(() => _isLoading = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN'
              ? 'Resolution Management'
              : widget.lang == 'ZH'
                  ? '解决方案管理'
                  : 'Manajemen Penyelesaian',
          style: GoogleFonts.inter(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchReports,
            icon: const Icon(CupertinoIcons.refresh,
                color: Color(0xFF16A34A)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _fetchReports,
              color: const Color(0xFF16A34A),
              child: _reports.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _reports.length,
                      itemBuilder: (_, i) =>
                          _buildReportCard(_reports[i]),
                    ),
            ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> r) {
    final severity = r['tingkat_keparahan'] ?? '';
    final sevColor = _severityColor(severity);
    final status = r['status'] ?? '';
    final locName = r['lokasi']?['nama_lokasi'] ?? '-';

    final Color statusColor = status == 'Selesai'
        ? const Color(0xFF16A34A)
        : const Color(0xFFF97316);
    final Color statusBg = status == 'Selesai'
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFFF7ED);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _HrdResolutionDetailScreen(
              reportId: r['id_laporan'] as String,
              reportTitle: r['judul'] ?? '-',
              lang: widget.lang,
            ),
          ),
        );
        _fetchReports();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFFDCFCE7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: r['foto_bukti'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(r['foto_bukti'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.warning_amber_rounded,
                              color: sevColor,
                              size: 28)))
                  : Icon(Icons.warning_amber_rounded,
                      color: sevColor, size: 28),
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status,
                            style: GoogleFonts.inter(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(locName,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: sevColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(severity,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: sevColor,
                                fontWeight: FontWeight.w700)),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.checkmark_shield,
              size: 64, color: Color(0xFF16A34A)),
          const SizedBox(height: 16),
          Text(
            widget.lang == 'EN'
                ? 'No reports to resolve'
                : widget.lang == 'ZH'
                    ? '无需解决的报告'
                    : 'Belum ada laporan untuk diselesaikan',
            style: GoogleFonts.inter(
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

// ============================================================
// LAYAR DETAIL RESOLUSI UNTUK HRD — CRUD RESOLUSI
// ============================================================
class _HrdResolutionDetailScreen extends StatefulWidget {
  final String reportId;
  final String reportTitle;
  final String lang;

  const _HrdResolutionDetailScreen({
    required this.reportId,
    required this.reportTitle,
    required this.lang,
  });

  @override
  State<_HrdResolutionDetailScreen> createState() =>
      _HrdResolutionDetailScreenState();
}

class _HrdResolutionDetailScreenState
    extends State<_HrdResolutionDetailScreen> {
  Map<String, dynamic>? _resolution;
  bool _isLoading = true;
  bool _isSaving = false;

  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _korektifCtrl = TextEditingController();
  final _preventifCtrl = TextEditingController();

  // ── Foto resolusi ──
  XFile? _imageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadResolution();
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _korektifCtrl.dispose();
    _preventifCtrl.dispose();
    super.dispose();
  }

  Future<bool> _checkAtmiOrBlock() async {
    final result = await LocationService.instance.checkUserAtAtmi(
      forceRefresh: true,
    );
    if (result.isAtAtmi) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.location_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.lang == 'EN'
                  ? 'Resolution can only be saved within PT ATMI Solo area.'
                  : widget.lang == 'ZH'
                      ? '解决方案只能在PT ATMI Solo区域内保存。'
                      : 'Penyelesaian hanya dapat disimpan di area PT ATMI Solo.',
            ),
          ),
        ]),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    return false;
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
          if (data != null) {
            _judulCtrl.text = data['judul_resolusi'] ?? '';
            _descCtrl.text = data['deskripsi_resolusi'] ?? '';
            _korektifCtrl.text = data['tindakan_korektif'] ?? '';
            _preventifCtrl.text = data['tindakan_preventif'] ?? '';
            _existingImageUrl = data['foto_resolusi'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading resolution: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.lang == 'EN'
                  ? 'Add Resolution Photo'
                  : widget.lang == 'ZH'
                      ? '添加解决方案照片'
                      : 'Tambah Foto Penyelesaian',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 20),
            // Kamera
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final img = await Navigator.push<XFile?>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccidentCameraScreen()),
                );
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFDCFCE7), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.camera_fill,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lang == 'EN'
                              ? 'Take Photo'
                              : widget.lang == 'ZH'
                                  ? '拍照'
                                  : 'Ambil Foto',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          widget.lang == 'EN'
                              ? 'Open camera directly'
                              : widget.lang == 'ZH'
                                  ? '直接打开相机'
                                  : 'Buka kamera langsung',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
            // Galeri
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFDCFCE7), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15803D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          CupertinoIcons.photo_fill_on_rectangle_fill,
                          color: Colors.white,
                          size: 22),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lang == 'EN'
                              ? 'Choose from Gallery'
                              : widget.lang == 'ZH'
                                  ? '从相册选择'
                                  : 'Pilih dari Galeri',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          widget.lang == 'EN'
                              ? 'Select existing photo'
                              : widget.lang == 'ZH'
                                  ? '选择现有照片'
                                  : 'Pilih foto yang sudah ada',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 16, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Batal
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.lang == 'EN'
                        ? 'Cancel'
                        : widget.lang == 'ZH'
                            ? '取消'
                            : 'Batal',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget() {
    final hasPhoto = _imageFile != null || _existingImageUrl != null;
    if (!hasPhoto) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.camera,
                    color: Color(0xFF16A34A), size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                widget.lang == 'EN'
                    ? 'Add Resolution Photo'
                    : widget.lang == 'ZH'
                        ? '添加解决方案照片'
                        : 'Tambah Foto Penyelesaian',
                style: GoogleFonts.inter(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              Text(
                widget.lang == 'EN'
                    ? 'Optional'
                    : widget.lang == 'ZH'
                        ? '可选'
                        : 'Opsional',
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imageFile != null
              ? (kIsWeb
                  ? Image.network(_imageFile!.path,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover)
                  : Image.file(File(_imageFile!.path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover))
              : Image.network(_existingImageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.camera_rotate,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    widget.lang == 'EN'
                        ? 'Retake'
                        : widget.lang == 'ZH'
                            ? '重拍'
                            : 'Ganti',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveResolution() async {
    if (_judulCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.lang == 'ZH'
            ? '标题和描述为必填项！'
            : widget.lang == 'EN'
                ? 'Title and description required!'
                : 'Judul dan deskripsi wajib diisi!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // Upload foto jika ada file baru
      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName =
            '$userId/resolution_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(
            fileName, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imageUrl =
            supabase.storage.from('temuan_images').getPublicUrl(fileName);
      }

      if (_resolution == null) {
        await supabase.from('resolution_accident').insert({
          'id_laporan': widget.reportId,
          'id_hrd': userId,
          'judul_resolusi': _judulCtrl.text.trim(),
          'deskripsi_resolusi': _descCtrl.text.trim(),
          'tindakan_korektif': _korektifCtrl.text.trim().isEmpty
              ? null
              : _korektifCtrl.text.trim(),
          'tindakan_preventif': _preventifCtrl.text.trim().isEmpty
              ? null
              : _preventifCtrl.text.trim(),
          'tanggal_resolusi':
              DateTime.now().toIso8601String().substring(0, 10),
          'foto_resolusi': imageUrl,
        });
        await supabase
            .from('accident_report')
            .update({'status': 'Selesai'}).eq('id_laporan', widget.reportId);
      } else {
        await supabase.from('resolution_accident').update({
          'judul_resolusi': _judulCtrl.text.trim(),
          'deskripsi_resolusi': _descCtrl.text.trim(),
          'tindakan_korektif': _korektifCtrl.text.trim().isEmpty
              ? null
              : _korektifCtrl.text.trim(),
          'tindakan_preventif': _preventifCtrl.text.trim().isEmpty
              ? null
              : _preventifCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
          'foto_resolusi': imageUrl,
        }).eq('id_resolution', _resolution!['id_resolution']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.lang == 'ZH'
              ? '解决方案保存成功！'
              : widget.lang == 'EN'
                  ? 'Resolution saved successfully!'
                  : 'Penyelesaian berhasil disimpan!'),
          backgroundColor: const Color(0xFF16A34A),
        ));
        await _loadResolution();
      }
    } catch (e) {
      debugPrint('Save resolution error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildFormField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    int maxLines = 1,
    Color borderColor = const Color(0xFF16A34A),
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569))),
            if (isRequired)
              const Text(' *',
                  style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: borderColor.withOpacity(0.3), width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = _resolution != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF16A34A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN'
              ? (isEdit ? 'Edit Resolution' : 'Add Resolution')
              : widget.lang == 'ZH'
                  ? (isEdit ? '编辑解决方案' : '添加解决方案')
                  : (isEdit ? 'Edit Penyelesaian' : 'Tambah Penyelesaian'),
          style: GoogleFonts.inter(
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
          ? const Center(
              child: CupertinoActivityIndicator(
                  radius: 14, color: Color(0xFF16A34A)))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info laporan
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_outlined,
                                color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(widget.reportTitle,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Foto Resolusi ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.lang == 'EN'
                                      ? 'Resolution Photo'
                                      : widget.lang == 'ZH'
                                          ? '解决方案照片'
                                          : 'Foto Penyelesaian',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.lang == 'EN'
                                        ? 'Optional'
                                        : widget.lang == 'ZH'
                                            ? '可选'
                                            : 'Opsional',
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF16A34A),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildPhotoWidget(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form judul & deskripsi
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            _buildFormField(
                              ctrl: _judulCtrl,
                              label: widget.lang == 'ID'
                                  ? 'Judul Penyelesaian'
                                  : widget.lang == 'ZH'
                                      ? '解决方案标题'
                                      : 'Resolution Title',
                              hint: widget.lang == 'ID'
                                  ? 'Contoh: Penanganan Insiden Gudang'
                                  : widget.lang == 'ZH'
                                      ? '例如：仓库事故处理'
                                      : 'e.g. Warehouse Incident Handling',
                              borderColor: const Color(0xFF16A34A),
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              ctrl: _descCtrl,
                              label: widget.lang == 'ID'
                                  ? 'Deskripsi Penyelesaian'
                                  : widget.lang == 'ZH'
                                      ? '解决方案描述'
                                      : 'Resolution Description',
                              hint: widget.lang == 'ID'
                                  ? 'Jelaskan penyelesaian secara rinci...'
                                  : widget.lang == 'ZH'
                                      ? '详细说明解决方案...'
                                      : 'Explain in detail...',
                              maxLines: 4,
                              borderColor: const Color(0xFF16A34A),
                              isRequired: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tindakan Korektif
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFFFF7ED), width: 1.5),
                        ),
                        child: _buildFormField(
                          ctrl: _korektifCtrl,
                          label: widget.lang == 'ID'
                              ? 'Tindakan Korektif'
                              : widget.lang == 'ZH'
                                  ? '纠正措施'
                                  : 'Corrective Action',
                          hint: widget.lang == 'ID'
                              ? 'Tindakan untuk mengatasi masalah...'
                              : widget.lang == 'ZH'
                                  ? '解决问题的措施...'
                                  : 'Actions to address the issue...',
                          maxLines: 3,
                          borderColor: const Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tindakan Preventif
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: _buildFormField(
                          ctrl: _preventifCtrl,
                          label: widget.lang == 'ID'
                              ? 'Tindakan Preventif'
                              : widget.lang == 'ZH'
                                  ? '预防措施'
                                  : 'Preventive Action',
                          hint: widget.lang == 'ID'
                              ? 'Tindakan untuk mencegah terulang...'
                              : widget.lang == 'ZH'
                                  ? '防止再次发生的措施...'
                                  : 'Actions to prevent recurrence...',
                          maxLines: 3,
                          borderColor: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CupertinoActivityIndicator(
                          radius: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: CupertinoColors.systemGrey5, width: 1)),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF15803D)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (!await _checkAtmiOrBlock()) return;
                    _saveResolution();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              isEdit
                  ? (widget.lang == 'ID'
                      ? 'Perbarui Penyelesaian'
                      : widget.lang == 'ZH'
                          ? '更新解决方案'
                          : 'Update Resolution')
                  : (widget.lang == 'ID'
                      ? 'Simpan Penyelesaian'
                      : widget.lang == 'ZH'
                          ? '保存解决方案'
                          : 'Save Resolution'),
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}