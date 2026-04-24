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
    extends State<AccidentReportListScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _currentUserId;

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

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchReports();
  }

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['deleted']!),
            backgroundColor: CupertinoColors.activeGreen));
        _fetchReports();
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
        title: Text(t['title']!,
            style: GoogleFonts.inter(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchReports,
            icon: const Icon(CupertinoIcons.refresh,
                color: Color(0xFF2563EB)),
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
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
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AccidentReportFormScreen(lang: widget.lang),
          ),
        );
        if (result == true) _fetchReports();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color.fromARGB(246, 246, 59, 59), Color.fromARGB(255, 216, 29, 29)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 246, 59, 59).withOpacity(0.4),
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
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
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
// LAYAR FORM LAPORAN KECELAKAAN (CREATE & EDIT)
// ============================================================
class AccidentReportFormScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? existingReport;

  const AccidentReportFormScreen(
      {super.key, required this.lang, this.existingReport});

  @override
  State<AccidentReportFormScreen> createState() =>
      _AccidentReportFormScreenState();
}

class _AccidentReportFormScreenState
    extends State<AccidentReportFormScreen> {
  bool get _isEdit => widget.existingReport != null;
  bool _isSaving = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();

  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;
  String? _selectedCause;
  String? _selectedSeverity;
  Map<String, dynamic>? _selectedLocation;
  Map<String, dynamic>? _selectedVictim;
  Map<String, dynamic>? _selectedSupervisor;
  Map<String, dynamic>? _selectedWitness;
  XFile? _imageFile;
  String? _existingImageUrl;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'create_title': 'Buat Laporan Kecelakaan',
      'edit_title': 'Edit Laporan Kecelakaan',
      'who_involved': 'Siapa yang Terlibat',
      'who_sub': 'Identifikasi pihak yang terluka dan yang menyaksikan',
      'victim': 'Pihak Terdampak',
      'select_victim': 'Pilih Pihak Terdampak',
      'supervisor': 'Supervisor',
      'select_supervisor': 'Pilih Supervisor',
      'supervisor_hint': 'Pilih pihak terdampak terlebih dahulu',
      'witness': 'Saksi',
      'select_witness': 'Pilih Saksi',
      'detail_title': 'Detail Kecelakaan',
      'detail_sub': 'Berikan bukti foto dan detail kejadian',
      'photo': 'Foto Bukti',
      'add_photo': 'Tambah Foto Bukti',
      'title_field': 'Judul',
      'title_hint': 'Contoh: Tergelincir di area gudang',
      'desc': 'Deskripsi Detail Kejadian',
      'desc_hint': 'Ceritakan kejadian secara rinci...',
      'date': 'Tanggal Kejadian',
      'pick_date': 'Pilih Tanggal',
      'time': 'Waktu Kejadian',
      'pick_time': 'Pilih Waktu',
      'location': 'Lokasi Kejadian',
      'pick_location': 'Pilih Lokasi',
      'cause': 'Penyebab Kecelakaan',
      'pick_cause': 'Pilih Penyebab',
      'severity': 'Tingkat Keparahan',
      'pick_severity': 'Pilih Tingkat Keparahan',
      'dept': 'Departemen Terdampak',
      'dept_hint': 'Contoh: Marketing',
      'action': 'Tindakan yang Diambil',
      'action_hint': 'Contoh: Dibawa ke rumah sakit',
      'submit': 'Kirim Laporan',
      'update': 'Perbarui Laporan',
      'err_title': 'Judul wajib diisi!',
      'err_victim': 'Pihak terdampak wajib dipilih!',
      'err_date': 'Tanggal kejadian wajib diisi!',
      'err_time': 'Waktu kejadian wajib diisi!',
      'err_location': 'Lokasi kejadian wajib diisi!',
      'err_cause': 'Penyebab wajib dipilih!',
      'err_severity': 'Tingkat keparahan wajib dipilih!',
      'err_desc': 'Deskripsi wajib diisi!',
      'err_photo': 'Foto bukti wajib diunggah!',
      'success': 'Laporan berhasil dikirim! +30 poin',
      'success_edit': 'Laporan berhasil diperbarui!',
      'fail': 'Gagal mengirim laporan',
      'saving': 'Mengirim laporan...',
      'cancel': 'Batal',
    },
    'EN': {
      'create_title': 'Create Accident Report',
      'edit_title': 'Edit Accident Report',
      'who_involved': 'Who Was Involved',
      'who_sub': 'Identify who was injured and who witnessed',
      'victim': 'Affected Party',
      'select_victim': 'Select Affected Party',
      'supervisor': 'Supervisor',
      'select_supervisor': 'Select Supervisor',
      'supervisor_hint': 'Please select affected party first',
      'witness': 'Witness',
      'select_witness': 'Select Witness',
      'detail_title': 'Accident Details',
      'detail_sub': 'Provide photo evidence and incident details',
      'photo': 'Evidence Photo',
      'add_photo': 'Add Evidence Photo',
      'title_field': 'Title',
      'title_hint': 'Example: Slipped in warehouse area',
      'desc': 'Detailed Description',
      'desc_hint': 'Describe the incident in detail...',
      'date': 'Incident Date',
      'pick_date': 'Pick Date',
      'time': 'Incident Time',
      'pick_time': 'Pick Time',
      'location': 'Incident Location',
      'pick_location': 'Pick Location',
      'cause': 'Accident Cause',
      'pick_cause': 'Select Cause',
      'severity': 'Severity Level',
      'pick_severity': 'Select Severity',
      'dept': 'Affected Department',
      'dept_hint': 'Example: Marketing',
      'action': 'Action Taken',
      'action_hint': 'Example: Victim taken to hospital',
      'submit': 'Submit Report',
      'update': 'Update Report',
      'err_title': 'Title is required!',
      'err_victim': 'Affected party is required!',
      'err_date': 'Incident date is required!',
      'err_time': 'Incident time is required!',
      'err_location': 'Incident location is required!',
      'err_cause': 'Cause is required!',
      'err_severity': 'Severity is required!',
      'err_desc': 'Description is required!',
      'err_photo': 'Evidence photo is required!',
      'success': 'Report submitted! +30 points',
      'success_edit': 'Report updated successfully!',
      'fail': 'Failed to submit report',
      'saving': 'Submitting report...',
      'cancel': 'Cancel',
    },
    'ZH': {
      'create_title': '创建事故报告',
      'edit_title': '编辑事故报告',
      'who_involved': '涉及人员',
      'who_sub': '确认受伤人员和目击者',
      'victim': '受影响方',
      'select_victim': '选择受影响方',
      'supervisor': '主管',
      'select_supervisor': '选择主管',
      'supervisor_hint': '请先选择受影响方',
      'witness': '目击者',
      'select_witness': '选择目击者',
      'detail_title': '事故详情',
      'detail_sub': '提供照片证据和事故详情',
      'photo': '证据照片',
      'add_photo': '添加证据照片',
      'title_field': '标题',
      'title_hint': '例如：在仓库区域滑倒',
      'desc': '详细描述',
      'desc_hint': '详细描述事故经过...',
      'date': '事故日期',
      'pick_date': '选择日期',
      'time': '事故时间',
      'pick_time': '选择时间',
      'location': '事故地点',
      'pick_location': '选择地点',
      'cause': '事故原因',
      'pick_cause': '选择原因',
      'severity': '严重程度',
      'pick_severity': '选择严重程度',
      'dept': '受影响部门',
      'dept_hint': '例如：市场部',
      'action': '采取的措施',
      'action_hint': '例如：受害者被送往医院',
      'submit': '提交报告',
      'update': '更新报告',
      'err_title': '标题为必填项！',
      'err_victim': '受影响方为必选项！',
      'err_date': '事故日期为必填项！',
      'err_time': '事故时间为必填项！',
      'err_location': '事故地点为必填项！',
      'err_cause': '原因为必选项！',
      'err_severity': '严重程度为必选项！',
      'err_desc': '描述为必填项！',
      'err_photo': '证据照片为必填项！',
      'success': '报告已提交！+30积分',
      'success_edit': '报告更新成功！',
      'fail': '提交报告失败',
      'saving': '正在提交报告...',
      'cancel': '取消',
    },
  };

  static const List<Map<String, String>> _causesID = [
    {'key': 'Mesin', 'desc': 'Kecelakaan karena terjebak di alat'},
    {'key': 'Benda Berat', 'desc': 'Kecelakaan karena terbentur objek berat'},
    {'key': 'Kendaraan / Alat Angkut', 'desc': 'Kecelakaan karena alat transportasi'},
    {'key': 'Jatuh', 'desc': 'Kecelakaan karena jatuh dari ketinggian'},
    {'key': 'Listrik', 'desc': 'Kecelakaan karena kejutan listrik'},
    {'key': 'Panas / Api', 'desc': 'Kecelakaan karena objek panas'},
    {'key': 'Perkakas', 'desc': 'Kecelakaan karena peralatan kerja'},
    {'key': 'Benda Tajam', 'desc': 'Kecelakaan karena tergores benda tajam'},
    {'key': 'Bahan Kimia', 'desc': 'Kecelakaan karena bahan kimia berbahaya'},
    {'key': 'Lainnya', 'desc': 'Penyebab kecelakaan lainnya'},
  ];

  static const List<Map<String, dynamic>> _severities = [
    {
      'key': 'Ringan',
      'desc': 'Cedera Tanpa Kehilangan Waktu Kerja',
      'color': 0xFF16A34A,
    },
    {
      'key': 'Menengah',
      'desc': 'Cedera Kehilangan Waktu Kerja',
      'color': 0xFFF97316,
    },
    {
      'key': 'Berat',
      'desc': 'Cedera Berat atau Fatality',
      'color': 0xFFDC2626,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) _populateData();
  }

  void _populateData() {
    final r = widget.existingReport!;
    _titleCtrl.text = r['judul'] ?? '';
    _descCtrl.text = r['deskripsi'] ?? '';
    _deptCtrl.text = r['departemen_terdampak'] ?? '';
    _actionCtrl.text = r['tindakan_diambil'] ?? '';
    _selectedCause = r['penyebab'];
    _selectedSeverity = r['tingkat_keparahan'];
    _existingImageUrl = r['foto_bukti'];
    if (r['tanggal_kejadian'] != null) {
      _incidentDate = DateTime.tryParse(r['tanggal_kejadian']);
    }
    if (r['waktu_kejadian'] != null) {
      final parts = r['waktu_kejadian'].split(':');
      if (parts.length >= 2) {
        _incidentTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    if (r['lokasi'] != null) {
      _selectedLocation = {
        'id_lokasi': r['id_lokasi'],
        'nama': r['lokasi']['nama_lokasi'] ?? '',
      };
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _deptCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: CupertinoColors.destructiveRed,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2563EB),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _incidentTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2563EB),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentTime = picked);
  }

  void _showCausePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(t['pick_cause']!,
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB))),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _causesID.length,
                itemBuilder: (_, i) {
                  final c = _causesID[i];
                  final isSelected = _selectedCause == c['key'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCause = c['key']);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEFF6FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE0E7FF),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['key']!,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF1E293B))),
                          const SizedBox(height: 3),
                          Text(c['desc']!,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8))),
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
    );
  }

  void _showSeverityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(t['pick_severity']!,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB))),
          ),
          ...(_severities.map((s) {
            final color = Color(s['color'] as int);
            return GestureDetector(
              onTap: () {
                setState(() => _selectedSeverity = s['key']);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['key'],
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: color)),
                          Text(s['desc'],
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    if (_selectedSeverity == s['key'])
                      Icon(CupertinoIcons.check_mark,
                          color: color, size: 16),
                  ],
                ),
              ),
            );
          })).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _showUserPicker(
      {required String role,
      required Function(Map<String, dynamic>) onSelected}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AccidentUserPickerSheet(
        lang: widget.lang,
        role: role,
        onSelected: onSelected,
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final result =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccidentLocationPicker(lang: widget.lang),
    );
    if (result != null) setState(() => _selectedLocation = result);
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
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
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
                  ? 'Add Evidence Photo'
                  : widget.lang == 'ZH'
                      ? '添加证据照片'
                      : 'Tambah Foto Bukti',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final img = await Navigator.push<XFile?>(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const _AccidentCameraScreen()),
                );
                if (img != null && mounted)
                  setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFE0E7FF), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
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
                        size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (img != null && mounted)
                  setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFE0E7FF), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          CupertinoIcons
                              .photo_fill_on_rectangle_fill,
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
                        size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                  child: Text(t['cancel']!,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF64748B))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showError(t['err_title']!);
      return;
    }
    if (_selectedVictim == null && !_isEdit) {
      _showError(t['err_victim']!);
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _showError(t['err_desc']!);
      return;
    }
    if (_incidentDate == null) {
      _showError(t['err_date']!);
      return;
    }
    if (_incidentTime == null) {
      _showError(t['err_time']!);
      return;
    }
    if (_selectedLocation == null) {
      _showError(t['err_location']!);
      return;
    }
    if (_selectedCause == null) {
      _showError(t['err_cause']!);
      return;
    }
    if (_selectedSeverity == null) {
      _showError(t['err_severity']!);
      return;
    }
    if (_imageFile == null && _existingImageUrl == null) {
      _showError(t['err_photo']!);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName =
            '${user.id}/accident_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(
            fileName, bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg'));
        imageUrl = supabase.storage
            .from('temuan_images')
            .getPublicUrl(fileName);
      }

      final timeStr =
          '${_incidentTime!.hour.toString().padLeft(2, '0')}:${_incidentTime!.minute.toString().padLeft(2, '0')}:00';

      final data = {
        'judul': _titleCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'foto_bukti': imageUrl,
        'tanggal_kejadian':
            DateFormat('yyyy-MM-dd').format(_incidentDate!),
        'waktu_kejadian': timeStr,
        'id_lokasi': _selectedLocation!['id_lokasi'],
        'id_unit': _selectedLocation!['id_unit'],
        'id_subunit': _selectedLocation!['id_subunit'],
        'id_area': _selectedLocation!['id_area'],
        'penyebab': _selectedCause,
        'tingkat_keparahan': _selectedSeverity,
        'departemen_terdampak': _deptCtrl.text.trim().isEmpty
            ? null
            : _deptCtrl.text.trim(),
        'tindakan_diambil': _actionCtrl.text.trim().isEmpty
            ? null
            : _actionCtrl.text.trim(),
      };

      if (_isEdit) {
        await supabase
            .from('accident_report')
            .update({
              ...data,
              'updated_at': DateTime.now().toIso8601String()
            })
            .eq('id_laporan',
                widget.existingReport!['id_laporan']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t['success_edit']!),
              backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
        }
      } else {
        await supabase.from('accident_report').insert({
          ...data,
          'id_pelapor': user.id,
          'id_pihak_terdampak': _selectedVictim!['id_user'],
          'id_supervisor': _selectedSupervisor?['id_user'],
          'id_saksi': _selectedWitness?['id_user'],
          'poin_laporan': 30,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t['success']!),
              backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        _showError('${t['fail']!}: $e');
        setState(() => _isSaving = false);
      }
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
            _isEdit ? t['edit_title']! : t['create_title']!,
            style: GoogleFonts.inter(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SECTION 1: Siapa yang Terlibat ──
                if (!_isEdit) ...[
                  _buildSectionHeader(
                    t['who_involved']!,
                    t['who_sub']!,
                    CupertinoIcons.person_2_fill,
                  ),
                  const SizedBox(height: 14),
                  _buildUserPicker(
                    label: t['victim']!,
                    value: _selectedVictim?['nama'],
                    placeholder: t['select_victim']!,
                    icon: CupertinoIcons.person_fill,
                    isRequired: true,
                    onTap: () => _showUserPicker(
                      role: 'victim',
                      onSelected: (u) => setState(() {
                        _selectedVictim = u;
                        _selectedSupervisor = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildUserPicker(
                    label: t['supervisor']!,
                    value: _selectedSupervisor?['nama'],
                    placeholder: _selectedVictim == null
                        ? t['supervisor_hint']!
                        : t['select_supervisor']!,
                    icon: CupertinoIcons.person_badge_plus,
                    isRequired: false,
                    isLocked: _selectedVictim == null,
                    onTap: _selectedVictim == null
                        ? null
                        : () => _showUserPicker(
                              role: 'supervisor',
                              onSelected: (u) => setState(
                                  () => _selectedSupervisor = u),
                            ),
                  ),
                  const SizedBox(height: 10),
                  _buildUserPicker(
                    label: t['witness']!,
                    value: _selectedWitness?['nama'],
                    placeholder: t['select_witness']!,
                    icon: CupertinoIcons.eye_fill,
                    isRequired: false,
                    onTap: () => _showUserPicker(
                      role: 'witness',
                      onSelected: (u) =>
                          setState(() => _selectedWitness = u),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── SECTION 2: Detail Kecelakaan ──
                _buildSectionHeader(
                  t['detail_title']!,
                  t['detail_sub']!,
                  CupertinoIcons.doc_text_fill,
                ),
                const SizedBox(height: 14),

                _buildSectionCard(children: [
                  _buildLabel(t['photo']!, isRequired: true),
                  _buildPhotoWidget(),
                ]),
                const SizedBox(height: 16),

                _buildSectionCard(children: [
                  _buildLabel(t['title_field']!, isRequired: true),
                  _buildTextField(_titleCtrl, t['title_hint']!,
                      CupertinoIcons.text_cursor),
                  const SizedBox(height: 16),
                  _buildLabel(t['desc']!, isRequired: true),
                  _buildTextField(_descCtrl, t['desc_hint']!,
                      CupertinoIcons.doc_text,
                      maxLines: 4),
                ]),
                const SizedBox(height: 16),

                _buildSectionCard(children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildLabel(t['date']!,
                                isRequired: true),
                            _buildTapField(
                              icon: CupertinoIcons.calendar,
                              text: _incidentDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_incidentDate!)
                                  : t['pick_date']!,
                              hasValue: _incidentDate != null,
                              onTap: _pickDate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildLabel(t['time']!,
                                isRequired: true),
                            _buildTapField(
                              icon: CupertinoIcons.clock_fill,
                              text: _incidentTime != null
                                  ? _incidentTime!.format(context)
                                  : t['pick_time']!,
                              hasValue: _incidentTime != null,
                              onTap: _pickTime,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),

                _buildSectionCard(children: [
                  _buildLabel(t['location']!, isRequired: true),
                  _buildTapField(
                    icon: CupertinoIcons.location_fill,
                    text: _selectedLocation?['nama'] ??
                        t['pick_location']!,
                    hasValue: _selectedLocation != null,
                    onTap: _showLocationPicker,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(t['cause']!, isRequired: true),
                  _buildTapField(
                    icon: CupertinoIcons.exclamationmark_triangle_fill,
                    text: _selectedCause ?? t['pick_cause']!,
                    hasValue: _selectedCause != null,
                    onTap: _showCausePicker,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(t['severity']!, isRequired: true),
                  _buildTapField(
                    icon: Icons.health_and_safety_outlined,
                    text: _selectedSeverity ?? t['pick_severity']!,
                    hasValue: _selectedSeverity != null,
                    onTap: _showSeverityPicker,
                    severityColor: _selectedSeverity != null
                        ? Color(_severities.firstWhere(
                                (s) => s['key'] == _selectedSeverity,
                                orElse: () =>
                                    {'color': 0xFF2563EB})['color']
                            as int)
                        : null,
                  ),
                ]),
                const SizedBox(height: 16),

                _buildSectionCard(children: [
                  _buildLabel(t['dept']!, isRequired: false),
                  _buildTextField(_deptCtrl, t['dept_hint']!,
                      CupertinoIcons.building_2_fill),
                  const SizedBox(height: 16),
                  _buildLabel(t['action']!, isRequired: false),
                  _buildTextField(_actionCtrl, t['action_hint']!,
                      CupertinoIcons.bandage_fill,
                      maxLines: 3),
                ]),
              ],
            ),
          ),
          if (_isSaving) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _isSaving
          ? null
          : Container(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                    top: BorderSide(
                        color: CupertinoColors.systemGrey5,
                        width: 1)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                      _isEdit ? t['update']! : t['submit']!,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(
      String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(icon, color: const Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF1E293B))),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFE0E7FF), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF475569))),
          if (isRequired)
            const Text(' *',
                style: TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style:
          GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: const Color(0xFFCBD5E1), fontSize: 15),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: const Color(0xFF2563EB), size: 20)
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFFE0E7FF), width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF2563EB), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTapField({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool hasValue = false,
    Color? severityColor,
  }) {
    final activeColor = severityColor ?? const Color(0xFF2563EB);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasValue
                  ? activeColor
                  : const Color(0xFFE0E7FF),
              width: hasValue ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: hasValue
                    ? activeColor
                    : const Color(0xFFCBD5E1),
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      color: hasValue
                          ? Colors.black87
                          : const Color(0xFFCBD5E1),
                      fontWeight: hasValue
                          ? FontWeight.w500
                          : FontWeight.normal)),
            ),
            Icon(CupertinoIcons.chevron_down,
                color: const Color(0xFF2563EB), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPicker({
    required String label,
    required String? value,
    required String placeholder,
    required IconData icon,
    required bool isRequired,
    VoidCallback? onTap,
    bool isLocked = false,
  }) {
    return _buildSectionCard(children: [
      _buildLabel(label, isRequired: isRequired),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isLocked
                ? const Color(0xFFF8FAFF)
                : const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value != null
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE0E7FF),
              width: value != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isLocked
                      ? const Color(0xFFCBD5E1)
                      : value != null
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? placeholder,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      color: value != null
                          ? Colors.black87
                          : const Color(0xFFCBD5E1),
                      fontWeight: value != null
                          ? FontWeight.w500
                          : FontWeight.normal),
                ),
              ),
              isLocked
                  ? const Icon(CupertinoIcons.lock_fill,
                      color: Color(0xFFCBD5E1), size: 18)
                  : const Icon(CupertinoIcons.chevron_forward,
                      color: Color(0xFF2563EB), size: 18),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildPhotoWidget() {
    final hasPhoto =
        _imageFile != null || _existingImageUrl != null;
    if (!hasPhoto) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFE0E7FF), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.camera,
                    color: Color(0xFF2563EB), size: 28),
              ),
              const SizedBox(height: 12),
              Text(t['add_photo']!,
                  style: GoogleFonts.inter(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
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
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover)
                  : Image.file(File(_imageFile!.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover))
              : Image.network(_existingImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.camera_rotate,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                      widget.lang == 'EN' ? 'Retake' : 'Ganti',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(
              vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.health_and_safety_outlined,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const CupertinoActivityIndicator(
                  radius: 12, color: Color(0xFF2563EB)),
              const SizedBox(height: 14),
              Text(t['saving']!,
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text(
                _isEdit
                    ? (widget.lang == 'EN'
                        ? 'Updating your report...'
                        : widget.lang == 'ZH'
                            ? '正在更新报告...'
                            : 'Memperbarui laporan Anda...')
                    : (widget.lang == 'EN'
                        ? 'Uploading & saving report...'
                        : widget.lang == 'ZH'
                            ? '正在上传并保存...'
                            : 'Mengunggah & menyimpan laporan...'),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.star_fill,
                          color: Color(0xFF2563EB), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'EN'
                            ? 'You will earn +30 points!'
                            : widget.lang == 'ZH'
                                ? '您将获得+30积分！'
                                : 'Anda akan mendapat +30 poin!',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
          tindakan_diambil, status, poin_laporan,
          created_at, id_pelapor,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['deleted']!),
            backgroundColor: CupertinoColors.activeGreen));
        Navigator.pop(context, true);
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
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFF),
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
                // Poin
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.star_fill,
                          color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 12),
                      Text(t['points']!,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF475569))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                            '+${d['poin_laporan'] ?? 30}',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color:
                                    const Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                ),
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
              CupertinoIcons.person_2_fill, 'Pihak Terlibat'),
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
                  _buildPersonRow(
                      t['reporter']!, pelapor, CupertinoIcons.person_fill),
                if (victim != null) ...[
                  Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['victim']!, victim,
                      CupertinoIcons.person_crop_circle_fill),
                ],
                if (supervisor != null) ...[
                  Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['supervisor']!, supervisor,
                      CupertinoIcons.person_badge_plus),
                ],
                if (witness != null) ...[
                  Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9)),
                  _buildPersonRow(t['witness']!, witness,
                      CupertinoIcons.eye_fill),
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
}

// ============================================================
// WIDGET PEMILIH USER
// ============================================================
class _AccidentUserPickerSheet extends StatefulWidget {
  final String lang;
  final String role;
  final Function(Map<String, dynamic>) onSelected;

  const _AccidentUserPickerSheet({
    required this.lang,
    required this.role,
    required this.onSelected,
  });

  @override
  State<_AccidentUserPickerSheet> createState() =>
      _AccidentUserPickerSheetState();
}

class _AccidentUserPickerSheetState
    extends State<_AccidentUserPickerSheet> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = _users
            .where((u) =>
                u['nama'].toString().toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await Supabase.instance.client
          .from('User')
          .select('id_user, nama, jabatan(nama_jabatan)')
          .order('nama');
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _filtered = _users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextFormField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.lang == 'EN'
                    ? 'Search...'
                    : widget.lang == 'ZH'
                        ? '搜索...'
                        : 'Cari...',
                hintStyle: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1)),
                prefixIcon: const Icon(CupertinoIcons.search,
                    color: Color(0xFF2563EB), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                        color: Color(0xFFE0E7FF))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                        color: Color(0xFF2563EB), width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CupertinoActivityIndicator(
                        radius: 14,
                        color: Color(0xFF2563EB)))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final u = _filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFFEFF6FF),
                          child: Text(
                            u['nama'][0].toUpperCase(),
                            style: GoogleFonts.inter(
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u['nama'],
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            u['jabatan']?['nama_jabatan'] ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color:
                                    const Color(0xFF94A3B8))),
                        onTap: () {
                          widget.onSelected(u);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PEMILIH LOKASI
// ============================================================
class _AccidentLocationPicker extends StatefulWidget {
  final String lang;
  const _AccidentLocationPicker({required this.lang});

  @override
  State<_AccidentLocationPicker> createState() =>
      _AccidentLocationPickerState();
}

class _AccidentLocationPickerState
    extends State<_AccidentLocationPicker> {
  int _level = 0;
  bool _isLoading = true;
  List<dynamic> _data = [];
  List<dynamic> _filtered = [];
  final List<Map<String, dynamic>> _history = [];
  final _searchCtrl = TextEditingController();

  static const _tables = ['lokasi', 'unit', 'subunit', 'area'];
  static const _idCols = [
    'id_lokasi',
    'id_unit',
    'id_subunit',
    'id_area'
  ];
  static const _namCols = [
    'nama_lokasi',
    'nama_unit',
    'nama_subunit',
    'nama_area'
  ];

  String get _idCol => _idCols[_level];
  String get _nameCol => _namCols[_level];

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_data)
          : _data
              .where((item) => item[_nameCol]
                  .toString()
                  .toLowerCase()
                  .contains(q))
              .toList();
    });
  }

  Future<void> _fetch({int? parentId}) async {
    setState(() => _isLoading = true);
    _searchCtrl.clear();
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];
      if (_level == 0) {
        data = await supabase
            .from('lokasi')
            .select('id_lokasi, nama_lokasi')
            .order('nama_lokasi');
      } else if (_level == 1) {
        data = await supabase
            .from('unit')
            .select('id_unit, nama_unit')
            .eq('id_lokasi', parentId!)
            .order('nama_unit');
      } else if (_level == 2) {
        data = await supabase
            .from('subunit')
            .select('id_subunit, nama_subunit')
            .eq('id_unit', parentId!)
            .order('nama_subunit');
      } else if (_level == 3) {
        data = await supabase
            .from('area')
            .select('id_area, nama_area')
            .eq('id_subunit', parentId!)
            .order('nama_area');
      }
      if (mounted) {
        setState(() {
          _data = data;
          _filtered = List.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goDeeper(Map<String, dynamic> item) {
    if (_level >= 3) return;
    _history.add({
      'level': _level,
      'id': item[_idCol],
      'name': item[_nameCol],
    });
    setState(() => _level++);
    _fetch(parentId: item[_idCols[_level - 1]]);
  }

  void _select(Map<String, dynamic> item) {
    final result = <String, dynamic>{};
    for (final h in _history) {
      result[_idCols[h['level'] as int]] = h['id'];
    }
    result[_idCol] = item[_idCol];
    final parts = [
      ..._history.map((h) => h['name'] as String),
      item[_nameCol].toString(),
    ];
    result['nama'] = parts.join(' / ');
    Navigator.pop(context, result);
  }

  void _goBack() {
    if (_history.isEmpty) {
      Navigator.pop(context);
      return;
    }
    _history.removeLast();
    setState(() => _level--);
    _fetch(
        parentId:
            _history.isEmpty ? null : _history.last['id']);
  }

  @override
  Widget build(BuildContext context) {
    final lvlLabels = {
      'EN': ['Location', 'Unit', 'Sub-Unit', 'Area'],
      'ID': ['Lokasi', 'Unit', 'Sub-Unit', 'Area'],
      'ZH': ['地点', '单位', '子单位', '区域'],
    };
    final labels =
        lvlLabels[widget.lang] ?? lvlLabels['ID']!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _history.isEmpty
                        ? CupertinoIcons.xmark
                        : CupertinoIcons.back,
                    color: const Color(0xFF2563EB),
                    size: 20,
                  ),
                  onPressed: _goBack,
                ),
                Expanded(
                  child: Text(
                    _history.isEmpty
                        ? labels[_level]
                        : _history.last['name'].toString(),
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_filtered.length}',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          // Breadcrumb
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(4, (i) {
                final isActive = i == _level;
                final isPast = i < _level;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: isPast
                          ? () {
                              final steps = _level - i;
                              for (int s = 0;
                                  s < steps;
                                  s++) {
                                if (_history.isNotEmpty)
                                  _history.removeLast();
                              }
                              setState(() => _level = i);
                              _fetch(
                                  parentId: _history.isEmpty
                                      ? null
                                      : _history.last['id']);
                            }
                          : null,
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2563EB)
                              : isPast
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF8FAFF),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          labels[i],
                          style: GoogleFonts.inter(
                            color: isActive
                                ? Colors.white
                                : isPast
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFCBD5E1),
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    if (i < 3)
                      Icon(CupertinoIcons.chevron_right,
                          size: 12,
                          color: i < _level
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFCBD5E1)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.lang == 'EN'
                    ? 'Search...'
                    : widget.lang == 'ZH'
                        ? '搜索...'
                        : 'Cari...',
                hintStyle: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 13),
                prefixIcon: const Icon(CupertinoIcons.search,
                    color: Color(0xFF2563EB), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                        color: Color(0xFFE0E7FF))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                        color: Color(0xFF2563EB), width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? Shimmer.fromColors(
                    baseColor: const Color(0xFFE2E8F0),
                    highlightColor: const Color(0xFFF8FAFF),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 6,
                      itemBuilder: (_, __) => Container(
                        margin: const EdgeInsets.only(
                            bottom: 10),
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                                CupertinoIcons.location_slash,
                                size: 48,
                                color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 8),
                            Text(
                                widget.lang == 'EN'
                                    ? 'No data found'
                                    : widget.lang == 'ZH'
                                        ? '未找到数据'
                                        : 'Data tidak ditemukan',
                                style: GoogleFonts.inter(
                                    color: const Color(
                                        0xFF94A3B8),
                                    fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 4, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final name =
                              item[_nameCol]?.toString() ??
                                  '-';
                          final isLastLevel = _level == 3;
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(
                                      0xFFE0E7FF)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(14),
                              child: InkWell(
                                onTap: isLastLevel
                                    ? () => _select(item)
                                    : () => _goDeeper(item),
                                borderRadius:
                                    BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 14,
                                      vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .all(8),
                                        decoration:
                                            BoxDecoration(
                                          color: const Color(
                                                  0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      10),
                                        ),
                                        child: Icon(
                                          [
                                            CupertinoIcons
                                                .building_2_fill,
                                            CupertinoIcons
                                                .squares_below_rectangle,
                                            CupertinoIcons
                                                .layers_alt_fill,
                                            CupertinoIcons
                                                .location_fill,
                                          ][_level],
                                          color: const Color(
                                              0xFF2563EB),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style:
                                              GoogleFonts.inter(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 14,
                                            color: const Color(
                                                0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            _select(item),
                                        child: Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                          decoration:
                                              BoxDecoration(
                                            color: const Color(
                                                0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                                        20),
                                            border: Border.all(
                                                color: const Color(
                                                    0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            widget.lang == 'EN'
                                                ? 'Select'
                                                : widget.lang ==
                                                        'ZH'
                                                    ? '选择'
                                                    : 'Pilih',
                                            style:
                                                GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                    color: const Color(
                                                        0xFF2563EB)),
                                          ),
                                        ),
                                      ),
                                      if (!isLastLevel) ...[
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () =>
                                              _goDeeper(item),
                                          child: Container(
                                            padding:
                                                const EdgeInsets
                                                    .all(6),
                                            decoration:
                                                BoxDecoration(
                                              color: const Color(
                                                  0xFFF8FAFF),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          8),
                                            ),
                                            child: const Icon(
                                                CupertinoIcons
                                                    .chevron_right,
                                                color: Color(
                                                    0xFF94A3B8),
                                                size: 16),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KAMERA KHUSUS ACCIDENT REPORT
// ============================================================
class _AccidentCameraScreen extends StatefulWidget {
  const _AccidentCameraScreen();

  @override
  State<_AccidentCameraScreen> createState() =>
      _AccidentCameraScreenState();
}

class _AccidentCameraScreenState
    extends State<_AccidentCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _ctrl;
  List<CameraDescription>? _cameras;
  int _camIndex = 0;
  bool _ready = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _ctrl!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _init() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      await _setCamera(_camIndex);
    }
  }

  Future<void> _setCamera(int i) async {
    await _ctrl?.dispose();
    _ctrl = CameraController(_cameras![i], ResolutionPreset.high,
        enableAudio: false);
    try {
      await _ctrl!.initialize();
      if (mounted) setState(() => _ready = true);
    } on CameraException catch (e) {
      debugPrint('Camera error: ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: CupertinoActivityIndicator(
                  color: Colors.white, radius: 16)));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_ctrl!)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                color: Colors.black.withOpacity(0.4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.back,
                          color: Colors.white),
                      onPressed: () =>
                          Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('FOTO BUKTI',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80);
                    if (img != null && mounted)
                      Navigator.pop(context, img);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(CupertinoIcons.photo,
                        color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (_ctrl == null ||
                        _ctrl!.value.isTakingPicture)
                      return;
                    try {
                      final pic = await _ctrl!.takePicture();
                      if (mounted)
                        Navigator.pop(context, pic);
                    } on CameraException catch (e) {
                      debugPrint('Snap error: ${e.code}');
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 4)),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle)),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_cameras == null ||
                        _cameras!.length < 2) return;
                    setState(() {
                      _ready = false;
                      _camIndex =
                          (_camIndex + 1) % _cameras!.length;
                    });
                    _setCamera(_camIndex);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(
                        CupertinoIcons.switch_camera,
                        color: Colors.white),
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
            tanggal_resolusi, created_at,
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
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFF),
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