import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
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

class _AccidentReportListScreenState extends State<AccidentReportListScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;

  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Laporan Kecelakaan',
      'empty_title': 'Belum Ada Laporan',
      'empty_sub': 'Buat laporan kecelakaan pertama Anda.',
      'add': 'Buat Laporan',
      'status_waiting': 'Menunggu',
      'status_review': 'Ditinjau',
      'status_done': 'Selesai',
      'delete_confirm': 'Hapus laporan ini?',
      'delete': 'Hapus',
      'cancel': 'Batal',
      'deleted': 'Laporan dihapus',
    },
    'EN': {
      'title': 'Accident Reports',
      'empty_title': 'No Reports Yet',
      'empty_sub': 'Create your first accident report.',
      'add': 'Create Report',
      'status_waiting': 'Pending',
      'status_review': 'Under Review',
      'status_done': 'Completed',
      'delete_confirm': 'Delete this report?',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'deleted': 'Report deleted',
    },
    'ZH': {
      'title': '事故报告',
      'empty_title': '暂无报告',
      'empty_sub': '创建您的第一份事故报告。',
      'add': '创建报告',
      'status_waiting': '等待中',
      'status_review': '审核中',
      'status_done': '已完成',
      'delete_confirm': '删除此报告？',
      'delete': '删除',
      'cancel': '取消',
      'deleted': '报告已删除',
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('laporan_kecelakaan')
          .select('''
            id_laporan, judul, deskripsi, foto_bukti, tanggal_kejadian,
            waktu_kejadian, penyebab, tingkat_keparahan, departemen_terdampak,
            tindakan_diambil, status, poin_laporan, created_at,
            lokasi(nama_lokasi)
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

  Future<void> _deleteReport(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t['delete_confirm']!,
            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t['delete']!, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('laporan_kecelakaan')
          .delete()
          .eq('id_laporan', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t['deleted']!), backgroundColor: Colors.green),
        );
        _fetchReports();
      }
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Ditinjau': return const Color(0xFFF97316);
      case 'Selesai': return const Color(0xFF16A34A);
      default: return const Color(0xFF3B82F6);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Ditinjau': return const Color(0xFFFFF7ED);
      case 'Selesai': return const Color(0xFFF0FDF4);
      default: return const Color(0xFFEFF6FF);
    }
  }

  Color _severityColor(String sev) {
    switch (sev) {
      case 'Berat': return const Color(0xFFDC2626);
      case 'Menengah': return const Color(0xFFF97316);
      default: return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t['title']!,
          style: GoogleFonts.poppins(
              color: const Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _fetchReports,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00C9E4)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : _reports.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetchReports,
                  color: const Color(0xFF00C9E4),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _reports.length,
                    itemBuilder: (_, i) => _buildCard(_reports[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccidentReportFormScreen(lang: widget.lang),
            ),
          );
          if (result == true) _fetchReports();
        },
        backgroundColor: const Color(0xFF00C9E4),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(t['add']!,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final status = r['status'] ?? 'Menunggu';
    final severity = r['tingkat_keparahan'] ?? '';
    final locName = r['lokasi']?['nama_lokasi'] ?? '-';
    final dateStr = r['tanggal_kejadian'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(r['tanggal_kejadian']))
        : '-';

    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade50, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9E4).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header berwarna
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.05),
                    const Color(0xFF00C9E4).withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFF1E3A8A), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r['judul'] ?? '-',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF1E3A8A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge severity
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _severityColor(severity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _severityColor(severity).withOpacity(0.3)),
                    ),
                    child: Text(
                      severity,
                      style: TextStyle(
                          color: _severityColor(severity),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(locName,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const Spacer(),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusBg(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Poin badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${r['poin_laporan']} P',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _deleteReport(r['id_laporan']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 14, color: Colors.red.shade400),
                              const SizedBox(width: 4),
                              Text(t['delete']!,
                                  style: TextStyle(
                                      color: Colors.red.shade400, fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF00C9E4).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_outlined,
                size: 64, color: Color(0xFF00C9E4)),
          ),
          const SizedBox(height: 20),
          Text(t['empty_title']!,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          Text(t['empty_sub']!,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
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

  const AccidentReportFormScreen({
    super.key,
    required this.lang,
    this.existingReport,
  });

  @override
  State<AccidentReportFormScreen> createState() =>
      _AccidentReportFormScreenState();
}

class _AccidentReportFormScreenState extends State<AccidentReportFormScreen> {
  bool get _isEdit => widget.existingReport != null;
  bool _isSaving = false;

  // Form fields
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
  bool _isVictimLocked = false;

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
      'detail_sub': 'Berikan bukti foto, deskripsi terperinci, kapan dan di mana kejadian',
      'photo': 'Foto Bukti',
      'add_photo': 'Tambah Foto Bukti',
      'required_label': 'Wajib',
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
      'pick_cause': 'Pilih Penyebab Kecelakaan',
      'severity': 'Tingkat Keparahan Kecelakaan',
      'pick_severity': 'Pilih Tingkat Keparahan Kecelakaan',
      'dept': 'Departemen Pihak Terdampak',
      'dept_hint': 'Contoh: Marketing',
      'action': 'Tindakan yang Diambil',
      'action_hint': 'Contoh: Pihak terdampak dibawa ke rumah sakit',
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
      'optional': 'Opsional',
    },
    'EN': {
      'create_title': 'Create Accident Report',
      'edit_title': 'Edit Accident Report',
      'who_involved': 'Who Was Involved',
      'who_sub': 'Identify who was injured and who witnessed the event',
      'victim': 'Affected Party',
      'select_victim': 'Select Affected Party',
      'supervisor': 'Supervisor',
      'select_supervisor': 'Select Supervisor',
      'supervisor_hint': 'Please select affected party first',
      'witness': 'Witness',
      'select_witness': 'Select Witness',
      'detail_title': 'Accident Details',
      'detail_sub': 'Provide photo evidence, detailed description, when and where it happened',
      'photo': 'Evidence Photo',
      'add_photo': 'Add Evidence Photo',
      'required_label': 'Required',
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
      'pick_cause': 'Select Accident Cause',
      'severity': 'Severity Level',
      'pick_severity': 'Select Severity Level',
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
      'optional': 'Optional',
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
      'detail_sub': '提供照片证据、详细描述、发生时间和地点',
      'photo': '证据照片',
      'add_photo': '添加证据照片',
      'required_label': '必填',
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
      'pick_cause': '选择事故原因',
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
      'optional': '可选',
    },
  };

  static const List<Map<String, String>> _causesID = [
    {'key': 'Mesin', 'desc': 'Kecelakaan di tempat kerja potensial karena terjebak di alat'},
    {'key': 'Benda Berat', 'desc': 'Kecelakaan di tempat kerja potensial karena terbentur oleh objek berat'},
    {'key': 'Kendaraan / Alat Angkut', 'desc': 'Kecelakaan di tempat kerja potensial karena alat transportasi'},
    {'key': 'Jatuh', 'desc': 'Kecelakaan di tempat kerja potensial karena jatuh dari ketinggian'},
    {'key': 'Listrik', 'desc': 'Kecelakaan di tempat kerja potensial karena kejutan listrik'},
    {'key': 'Panas / Api', 'desc': 'Kecelakaan di tempat kerja potensial karena objek panas'},
    {'key': 'Perkakas', 'desc': 'Kecelakaan di tempat kerja potensial karena terbentur/tergores/terkena sisi tajam dari peralatan kerja'},
    {'key': 'Benda Tajam', 'desc': 'Kecelakaan tempat kerja potensial karena tergores benda tajam'},
    {'key': 'Bahan Kimia', 'desc': 'Kecelakaan di tempat kerja potensial karena paparan bahan kimia berbahaya'},
    {'key': 'Lainnya', 'desc': 'Penyebab kecelakaan lainnya'},
  ];

  static const List<Map<String, dynamic>> _severities = [
    {
      'key': 'Ringan',
      'desc': 'Keparahan Ringan - dampak rendah',
      'highlight': 'Cedera Tanpa Kehilangan Waktu Kerja',
      'note': 'Cukup Ditinjau Komite.',
      'color': 0xFF16A34A,
    },
    {
      'key': 'Menengah',
      'desc': 'Keparahan Menengah - dampak Sedang',
      'highlight': 'Cedera Kehilangan Waktu Kerja',
      'note': 'Wajib ditinjau Komite. Status tinjauan Supervisor ditetapkan oleh Komite (wajib atau tidak).',
      'color': 0xFFF97316,
    },
    {
      'key': 'Berat',
      'desc': 'Keparahan Berat/Kritis - dampak tinggi',
      'highlight': 'Cedera Berat atau Fatality',
      'note': 'Wajib ditinjau Supervisor dan Komite.',
      'color': 0xFFDC2626,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) _populateExistingData();
  }

  void _populateExistingData() {
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9E4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF00C9E4)),
              ),
              title: Text(
                widget.lang == 'EN' ? 'Camera' : widget.lang == 'ZH' ? '相机' : 'Kamera',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context); // Tutup bottom sheet dulu
                // Navigasi ke kamera menggunakan flow yang sama dengan CameraFindingScreen
                final XFile? img = await _openCameraScreen();
                if (img != null && mounted) setState(() => _imageFile = img);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
              ),
              title: Text(
                widget.lang == 'EN' ? 'Gallery' : widget.lang == 'ZH' ? '相册' : 'Galeri',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final XFile? img = await picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (img != null && mounted) setState(() => _imageFile = img);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Buka kamera menggunakan CameraController langsung (sama seperti CameraFindingScreen)
  Future<XFile?> _openCameraScreen() async {
    return await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AccidentCameraScreen(),
      ),
    );
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
            primary: Color(0xFF00C9E4),
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
            primary: Color(0xFF00C9E4),
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                t['pick_cause']!,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A)),
              ),
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
                            ? const Color(0xFF00C9E4).withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00C9E4)
                              : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['key']!,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF00C9E4)
                                      : const Color(0xFF1E3A8A))),
                          const SizedBox(height: 3),
                          Text(c['desc']!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
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
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              t['pick_severity']!,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A)),
            ),
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
                  color: color.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['key'],
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: color)),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        children: [
                          TextSpan(text: '${s['desc']} '),
                          TextSpan(
                            text: '(${s['highlight']})',
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(s['note'],
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
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

  Future<void> _showUserPicker({required String role, required Function(Map<String, dynamic>) onSelected}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UserPickerSheet(
        lang: widget.lang,
        role: role,
        onSelected: onSelected,
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccidentLocationPicker(lang: widget.lang),
    );
    if (result != null) setState(() => _selectedLocation = result);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submit() async {
    // Validasi
    if (_titleCtrl.text.trim().isEmpty) { _showError(t['err_title']!); return; }
    if (_selectedVictim == null && !_isEdit) { _showError(t['err_victim']!); return; }
    if (_descCtrl.text.trim().isEmpty) { _showError(t['err_desc']!); return; }
    if (_incidentDate == null) { _showError(t['err_date']!); return; }
    if (_incidentTime == null) { _showError(t['err_time']!); return; }
    if (_selectedLocation == null) { _showError(t['err_location']!); return; }
    if (_selectedCause == null) { _showError(t['err_cause']!); return; }
    if (_selectedSeverity == null) { _showError(t['err_severity']!); return; }
    if (_imageFile == null && _existingImageUrl == null) { _showError(t['err_photo']!); return; }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? imageUrl = _existingImageUrl;

      // Upload foto jika ada file baru
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName = '${user.id}/accident_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(
          fileName, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);
      }

      final timeStr =
          '${_incidentTime!.hour.toString().padLeft(2, '0')}:${_incidentTime!.minute.toString().padLeft(2, '0')}:00';

      final data = {
        'judul': _titleCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'foto_bukti': imageUrl,
        'tanggal_kejadian': DateFormat('yyyy-MM-dd').format(_incidentDate!),
        'waktu_kejadian': timeStr,
        'id_lokasi': _selectedLocation!['id_lokasi'],
        'id_unit': _selectedLocation!['id_unit'],
        'id_subunit': _selectedLocation!['id_subunit'],
        'id_area': _selectedLocation!['id_area'],
        'penyebab': _selectedCause,
        'tingkat_keparahan': _selectedSeverity,
        'departemen_terdampak': _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
        'tindakan_diambil': _actionCtrl.text.trim().isEmpty ? null : _actionCtrl.text.trim(),
      };

      if (_isEdit) {
        await supabase.from('laporan_kecelakaan')
            .update({...data, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id_laporan', widget.existingReport!['id_laporan']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['success_edit']!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
          Navigator.pop(context, true);
        }
      } else {
        await supabase.from('laporan_kecelakaan').insert({
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
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
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
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? t['edit_title']! : t['create_title']!,
          style: GoogleFonts.poppins(
              color: const Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SECTION 1: Siapa yang Terlibat ──
                if (!_isEdit) ...[
                  _buildSectionHeader(
                    t['who_involved']!,
                    t['who_sub']!,
                    Icons.people_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildUserPicker(
                    label: t['victim']!,
                    value: _selectedVictim?['nama'],
                    placeholder: t['select_victim']!,
                    icon: Icons.person_outline,
                    isRequired: true,
                    onTap: () => _showUserPicker(
                      role: 'victim',
                      onSelected: (u) {
                        setState(() {
                          _selectedVictim = u;
                          _selectedSupervisor = null;
                          _isVictimLocked = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Supervisor (locked jika victim belum dipilih)
                  _buildUserPicker(
                    label: t['supervisor']!,
                    value: _selectedSupervisor?['nama'],
                    placeholder: _selectedVictim == null
                        ? t['supervisor_hint']!
                        : t['select_supervisor']!,
                    icon: Icons.supervisor_account_outlined,
                    isRequired: false,
                    isLocked: _selectedVictim == null,
                    warningText: _selectedVictim == null ? t['supervisor_hint'] : null,
                    onTap: _selectedVictim == null
                        ? null
                        : () => _showUserPicker(
                              role: 'supervisor',
                              onSelected: (u) => setState(() => _selectedSupervisor = u),
                            ),
                  ),
                  const SizedBox(height: 10),
                  _buildUserPicker(
                    label: t['witness']!,
                    value: _selectedWitness?['nama'],
                    placeholder: t['select_witness']!,
                    icon: Icons.visibility_outlined,
                    isRequired: false,
                    onTap: () => _showUserPicker(
                      role: 'witness',
                      onSelected: (u) => setState(() => _selectedWitness = u),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── SECTION 2: Detail Kecelakaan ──
                _buildSectionHeader(
                  t['detail_title']!,
                  t['detail_sub']!,
                  Icons.camera_alt_outlined,
                ),
                const SizedBox(height: 14),

                // Foto Bukti
                _buildLabel(t['photo']!, isRequired: true),
                _buildPhotoWidget(),
                const SizedBox(height: 16),

                // Judul
                _buildLabel(t['title_field']!, isRequired: true),
                _buildTextField(_titleCtrl, t['title_hint']!, Icons.label_outline),
                const SizedBox(height: 16),

                // Deskripsi
                _buildLabel(t['desc']!, isRequired: true),
                _buildTextField(_descCtrl, t['desc_hint']!, Icons.notes_outlined, maxLines: 4),
                const SizedBox(height: 16),

                // Tanggal & Waktu
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(t['date']!, isRequired: true),
                          _buildTapField(
                            icon: Icons.calendar_today_outlined,
                            text: _incidentDate != null
                                ? DateFormat('dd/MM/yyyy').format(_incidentDate!)
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(t['time']!, isRequired: true),
                          _buildTapField(
                            icon: Icons.access_time_outlined,
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
                const SizedBox(height: 16),

                // Lokasi
                _buildLabel(t['location']!, isRequired: true),
                _buildTapField(
                  icon: Icons.location_on_outlined,
                  text: _selectedLocation?['nama'] ?? t['pick_location']!,
                  hasValue: _selectedLocation != null,
                  onTap: _showLocationPicker,
                ),
                const SizedBox(height: 16),

                // Penyebab
                _buildLabel(t['cause']!, isRequired: true),
                _buildTapField(
                  icon: Icons.warning_amber_outlined,
                  text: _selectedCause ?? t['pick_cause']!,
                  hasValue: _selectedCause != null,
                  onTap: _showCausePicker,
                ),
                const SizedBox(height: 16),

                // Tingkat Keparahan
                _buildLabel(t['severity']!, isRequired: true),
                _buildTapField(
                  icon: Icons.health_and_safety_outlined,
                  text: _selectedSeverity ?? t['pick_severity']!,
                  hasValue: _selectedSeverity != null,
                  onTap: _showSeverityPicker,
                  severityColor: _selectedSeverity != null
                      ? Color(_severities.firstWhere(
                              (s) => s['key'] == _selectedSeverity,
                              orElse: () => {'color': 0xFF00C9E4})['color'] as int)
                      : null,
                ),
                const SizedBox(height: 16),

                // Departemen
                _buildLabel(t['dept']!, isRequired: false),
                _buildTextField(_deptCtrl, t['dept_hint']!, Icons.business_outlined),
                const SizedBox(height: 16),

                // Tindakan
                _buildLabel(t['action']!, isRequired: false),
                _buildTextField(_actionCtrl, t['action_hint']!, Icons.medical_services_outlined, maxLines: 3),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Loading overlay
          if (_isSaving) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _isSaving
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9E4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shadowColor: const Color(0xFF00C9E4).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isEdit ? t['update']! : t['submit']!,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animasi cahaya senter biru
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lingkaran luar berdenyut
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 900),
                      builder: (_, v, __) => Transform.scale(
                        scale: v,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00C9E4).withOpacity(0.08),
                          ),
                        ),
                      ),
                    ),
                    // Lingkaran tengah
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00C9E4).withOpacity(0.15),
                      ),
                    ),
                    const CircularProgressIndicator(
                      color: Color(0xFF00C9E4),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t['saving']!,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.05),
            const Color(0xFF00C9E4).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C9E4).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00C9E4).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00C9E4), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF1E3A8A))),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xFF1E3A8A))),
          if (isRequired)
            const Text(' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C9E4), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    final activeColor = severityColor ?? const Color(0xFF00C9E4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? activeColor.withOpacity(0.5) : Colors.grey.shade200,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: hasValue ? activeColor : const Color(0xFF1E3A8A), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: hasValue ? Colors.black87 : Colors.grey.shade400,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal)),
            ),
            Icon(Icons.arrow_drop_down,
                color: hasValue ? activeColor : Colors.grey.shade400),
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
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF00C9E4).withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF00C9E4).withOpacity(0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9E4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF00C9E4), size: 30),
              ),
              const SizedBox(height: 10),
              Text(t['add_photo']!,
                  style: const TextStyle(
                      color: Color(0xFF00C9E4), fontWeight: FontWeight.w600)),
              Text(t['required_label']!,
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _imageFile != null
              ? (kIsWeb
                  ? Image.network(_imageFile!.path,
                      height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(_imageFile!.path),
                      height: 200, width: double.infinity, fit: BoxFit.cover))
              : Image.network(_existingImageUrl!,
                  height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(widget.lang == 'EN' ? 'Retake' : 'Ganti',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
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
    String? warningText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value != null
                    ? const Color(0xFF00C9E4).withOpacity(0.5)
                    : Colors.grey.shade200,
                width: value != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: isLocked
                        ? Colors.grey.shade400
                        : value != null
                            ? const Color(0xFF00C9E4)
                            : const Color(0xFF1E3A8A),
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                        fontSize: 13,
                        color: value != null
                            ? Colors.black87
                            : isLocked
                                ? Colors.grey.shade400
                                : Colors.grey.shade400,
                        fontWeight:
                            value != null ? FontWeight.w500 : FontWeight.normal),
                  ),
                ),
                isLocked
                    ? Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 18)
                    : const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
              ],
            ),
          ),
        ),
        if (warningText != null && isLocked)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 12, color: Color(0xFFF97316)),
                const SizedBox(width: 4),
                Text(warningText,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFF97316))),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Widget pemilih user untuk kecelakaan ──
class _UserPickerSheet extends StatefulWidget {
  final String lang;
  final String role;
  final Function(Map<String, dynamic>) onSelected;

  const _UserPickerSheet({
    required this.lang,
    required this.role,
    required this.onSelected,
  });

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
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
            .where((u) => u['nama'].toString().toLowerCase().contains(q))
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
          .eq('id_lokasi', 1)
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: widget.lang == 'EN' ? 'Search...' : 'Cari...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final u = _filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00C9E4).withOpacity(0.12),
                          child: Text(u['nama'][0].toUpperCase(),
                              style: const TextStyle(
                                  color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(u['nama'],
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(u['jabatan']?['nama_jabatan'] ?? ''),
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

// ── Pemilih Lokasi untuk Accident Report ──
// ── Pemilih Lokasi untuk Accident Report (Full Hierarchy + Shimmer) ──
class _AccidentLocationPicker extends StatefulWidget {
  final String lang;
  const _AccidentLocationPicker({required this.lang});

  @override
  State<_AccidentLocationPicker> createState() => _AccidentLocationPickerState();
}

class _AccidentLocationPickerState extends State<_AccidentLocationPicker> {
  int _level = 0; // 0=lokasi, 1=unit, 2=subunit, 3=area
  bool _isLoading = true;
  List<dynamic> _data = [];
  List<dynamic> _filtered = [];
  final List<Map<String, dynamic>> _history = [];
  final _searchCtrl = TextEditingController();

  // Nama tabel & kolom per level
  static const _tables  = ['lokasi', 'unit', 'subunit', 'area'];
  static const _idCols  = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'];
  static const _namCols = ['nama_lokasi', 'nama_unit', 'nama_subunit', 'nama_area'];
  // Kolom foreign key yang digunakan untuk filter ke level berikutnya
  static const _fkCols  = ['id_lokasi', 'id_unit', 'id_subunit']; // dipakai oleh level 1,2,3

  String get _table  => _tables[_level];
  String get _idCol  => _idCols[_level];
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
          : _data.where((item) =>
              item[_nameCol].toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _fetch({int? parentId}) async {
    setState(() => _isLoading = true);
    _searchCtrl.clear();
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];

      if (_level == 0) {
        // Ambil SEMUA lokasi
        data = await supabase
            .from('lokasi')
            .select('id_lokasi, nama_lokasi')
            .order('nama_lokasi');
      } else if (_level == 1) {
        // Unit berdasarkan id_lokasi dari level 0
        data = await supabase
            .from('unit')
            .select('id_unit, nama_unit')
            .eq('id_lokasi', parentId!)
            .order('nama_unit');
      } else if (_level == 2) {
        // Subunit berdasarkan id_unit dari level 1
        data = await supabase
            .from('subunit')
            .select('id_subunit, nama_subunit')
            .eq('id_unit', parentId!)
            .order('nama_subunit');
      } else if (_level == 3) {
        // Area berdasarkan id_subunit dari level 2
        data = await supabase
            .from('area')
            .select('id_area, nama_area')
            .eq('id_subunit', parentId!)
            .order('nama_area');
      }

      if (mounted) {
        setState(() {
          _data     = data;
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
      'id':    item[_idCol],
      'name':  item[_nameCol],
    });
    setState(() => _level++);
    _fetch(parentId: item[_idCols[_level - 1]]);
  }

  void _select(Map<String, dynamic> item) {
    // Bangun result dengan semua id hierarki
    final result = <String, dynamic>{};
    for (final h in _history) {
      result[_idCols[h['level'] as int]] = h['id'];
    }
    result[_idCol] = item[_idCol];

    // Nama lengkap dari root ke item ini
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
    _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
  }

  // ── Shimmer saat loading ──
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Label level (breadcrumb sederhana)
  String get _levelLabel {
    const labels = {
      'EN': ['Location', 'Unit', 'Sub-Unit', 'Area'],
      'ID': ['Lokasi', 'Unit', 'Sub-Unit', 'Area'],
      'ZH': ['地点', '单位', '子单位', '区域'],
    };
    final list = labels[widget.lang] ?? labels['ID']!;
    return list[_level];
  }

  String get _searchHint {
    const hints = {
      'EN': ['Search location...', 'Search unit...', 'Search sub-unit...', 'Search area...'],
      'ID': ['Cari lokasi...', 'Cari unit...', 'Cari sub-unit...', 'Cari area...'],
      'ZH': ['搜索地点...', '搜索单位...', '搜索子单位...', '搜索区域...'],
    };
    final list = hints[widget.lang] ?? hints['ID']!;
    return list[_level];
  }

  String get _selectLabel => widget.lang == 'EN' ? 'Select' : widget.lang == 'ZH' ? '选择' : 'Pilih';
  String get _emptyLabel  => widget.lang == 'EN' ? 'No data found' : widget.lang == 'ZH' ? '未找到数据' : 'Data tidak ditemukan';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // App bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _history.isEmpty ? Icons.close : Icons.arrow_back_ios_new,
                    color: const Color(0xFF1E3A8A), size: 20,
                  ),
                  onPressed: _goBack,
                ),
                Expanded(
                  child: Text(
                    _history.isEmpty
                        ? _levelLabel
                        : _history.last['name'].toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // badge jumlah item
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filtered.length}',
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Breadcrumb level indicator
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(4, (i) {
                const lvlKeys = {
                  'EN': ['Location', 'Unit', 'Sub-Unit', 'Area'],
                  'ID': ['Lokasi', 'Unit', 'Sub-Unit', 'Area'],
                  'ZH': ['地点', '单位', '子单位', '区域'],
                };
                final labels = lvlKeys[widget.lang] ?? lvlKeys['ID']!;
                final isActive = i == _level;
                final isPast   = i < _level;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: isPast ? () {
                        final steps = _level - i;
                        for (int s = 0; s < steps; s++) {
                          if (_history.isNotEmpty) _history.removeLast();
                        }
                        setState(() => _level = i);
                        _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
                      } : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1E3A8A)
                              : isPast
                                  ? const Color(0xFF1E3A8A).withOpacity(0.12)
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : isPast
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.grey.shade400,
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    if (i < 3)
                      Icon(Icons.chevron_right,
                          size: 14,
                          color: i < _level
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade300),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: _searchHint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A), size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF00C9E4), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text(_emptyLabel,
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final name = item[_nameCol]?.toString() ?? '-';
                          final isLastLevel = _level == 3;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: isLastLevel
                                    ? () => _select(item)
                                    : () => _goDeeper(item),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          [Icons.location_city, Icons.business,
                                           Icons.layers_outlined, Icons.place][_level],
                                          color: const Color(0xFF1E3A8A),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                      ),
                                      // Tombol Pilih
                                      TextButton(
                                        onPressed: () => _select(item),
                                        style: TextButton.styleFrom(
                                          backgroundColor: const Color(0xFFE0F7FA),
                                          foregroundColor: const Color(0xFF0891B2),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(_selectLabel,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      // Panah drill-down (jika bukan level terakhir)
                                      if (!isLastLevel) ...[
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _goDeeper(item),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.chevron_right,
                                                color: Colors.grey.shade500, size: 18),
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

// ── Kamera khusus untuk Accident Report (sama persis seperti CameraFindingScreen) ──
class _AccidentCameraScreen extends StatefulWidget {
  const _AccidentCameraScreen();

  @override
  State<_AccidentCameraScreen> createState() => _AccidentCameraScreenState();
}

class _AccidentCameraScreenState extends State<_AccidentCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setCamera(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _setCamera(int index) async {
    await _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } on CameraException catch (e) {
      debugPrint('Set camera error: ${e.code} ${e.description}');
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });
    _setCamera(_selectedCameraIndex);
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized ||
        _cameraController == null ||
        _cameraController!.value.isTakingPicture) return;
    try {
      final picture = await _cameraController!.takePicture();
      if (mounted) Navigator.pop(context, picture);
    } on CameraException catch (e) {
      debugPrint('Take picture error: ${e.code}');
    }
  }

  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (img != null && mounted) Navigator.pop(context, img);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_cameraController!)),

          // Back button
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'FOTO BUKTI',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Galeri
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library, color: Colors.white),
                  ),
                ),
                // Shutter
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 75, height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                // Flip
                GestureDetector(
                  onTap: _switchCamera,
                  child: Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.flip_camera_ios, color: Colors.white),
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