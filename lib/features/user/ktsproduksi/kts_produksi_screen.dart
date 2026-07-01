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
import 'kts_create_report.dart';

// ============================================================
// LAYAR DAFTAR KTS PRODUKSI
// ============================================================
class KtsProduksiListScreen extends StatefulWidget {
  final String lang;
  const KtsProduksiListScreen({super.key, required this.lang});

  @override
  State<KtsProduksiListScreen> createState() => _KtsProduksiListScreenState();
}

class _KtsProduksiListScreenState extends State<KtsProduksiListScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  bool get wantKeepAlive => true;

  // ── Blue theme constants ──
  static const Color _kPrimary     = Color(0xFF1D4ED8);
  static const Color _kPrimaryDark = Color(0xFF1E3A8A);
  static const Color _kPrimaryLight= Color(0xFFEFF6FF);
  static const Color _kBorder      = Color(0xFFBFDBFE);
  static const Color _kBg          = Color(0xFFF0F4FF);

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'KTS Produksi',
      'add': 'Buat Laporan KTS',
      'empty_title': 'Belum Ada Laporan KTS',
      'empty_sub': 'Buat laporan KTS Produksi pertama Anda.',
      'resolved': 'Teratasi',
      'unresolved': 'Belum Teratasi',
      'delete': 'Hapus',
      'cancel': 'Batal',
      'delete_confirm': 'Hapus laporan KTS ini?',
      'deleted': 'Laporan KTS dihapus',
      'order': 'No. Order',
      'qty': 'Jumlah',
      'edit': 'Edit',
      'history_title': 'Histori Laporan KTS Anda',
    },
    'EN': {
      'title': 'Production KTS',
      'add': 'Create KTS Report',
      'empty_title': 'No KTS Reports Yet',
      'empty_sub': 'Create your first Production KTS report.',
      'resolved': 'Resolved',
      'unresolved': 'Unresolved',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'delete_confirm': 'Delete this KTS report?',
      'deleted': 'KTS report deleted',
      'order': 'Order No.',
      'qty': 'Quantity',
      'edit': 'Edit',
      'history_title': 'Your KTS Report History',
    },
    'ZH': {
      'title': '生产KTS',
      'add': '创建KTS报告',
      'empty_title': '暂无KTS报告',
      'empty_sub': '创建您的第一份生产KTS报告。',
      'resolved': '已解决',
      'unresolved': '未解决',
      'delete': '删除',
      'cancel': '取消',
      'delete_confirm': '删除此KTS报告？',
      'deleted': 'KTS报告已删除',
      'order': '订单号',
      'qty': '数量',
      'edit': '编辑',
      'history_title': '您的KTS报告历史',
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
          .from('temuan')
          .select('''
            id_temuan, no_order, judul_temuan, status_temuan,
            poin_temuan, created_at, jumlah_item, id_user,
            nama_item_manual, gambar_temuan, jenis_temuan,
            id_penanggung_jawab, deskripsi_temuan,
            subkategoritemuan:id_subkategoritemuan_uuid(
              id_subkategoritemuan, nama_subkategoritemuan
            ),
            item_produksi:id_item(id_item, nama_item, gambar_item),
            lokasi:id_lokasi(nama_lokasi),
            penanggung_jawab:id_penanggung_jawab(id_user, nama, gambar_user)
          ''')
          .eq('id_user', userId)
          .eq('jenis_temuan', 'KTS Production')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching KTS: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkAtmiOrBlock() async {
    final result = await LocationService.instance.checkUserAtAtmi(forceRefresh: true);
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

  Future<void> _deleteReport(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha:0.12), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFFFF1F2), shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.trash_fill, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              Text(t['delete_confirm']!,
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                widget.lang == 'EN' ? 'This action cannot be undone.'
                    : widget.lang == 'ZH' ? '此操作无法撤销。'
                    : 'Tindakan ini tidak dapat dibatalkan.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(t['cancel']!, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF475569)))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Center(child: Text(t['delete']!, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('temuan').delete().eq('id_temuan', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['deleted']!), backgroundColor: CupertinoColors.activeGreen));
        _fetchReports();
      }
    } catch (e) {
      debugPrint('Error deleting KTS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t['title']!, style: GoogleFonts.inter(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _fetchReports, icon: const Icon(CupertinoIcons.refresh, color: _kPrimary)),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: _kBorder, height: 1)),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _fetchReports,
              color: _kPrimary,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreateButton(),
                    const SizedBox(height: 28),
                    Text(t['history_title']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
                    const SizedBox(height: 14),
                    if (_reports.isEmpty)
                      _buildEmpty()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reports.length,
                        itemBuilder: (_, i) => _buildCard(_reports[i]),
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
        if (!await _checkAtmiOrBlock()) return;
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => KtsProduksiFormScreen(lang: widget.lang)));
        if (result == true) _fetchReports();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha:0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.25), borderRadius: BorderRadius.circular(14)),
              child: const Icon(CupertinoIcons.hammer_fill, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['add']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    widget.lang == 'ZH' ? '记录生产质量问题'
                        : widget.lang == 'EN' ? 'Record production quality issues'
                        : 'Catat masalah kualitas produksi',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha:0.85)),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final status = r['status_temuan'] ?? 'Belum';
    final isResolved = status == 'Closed' || status == 'Teratasi' || status == 'Selesai';
    final statusColor = isResolved ? const Color(0xFF16A34A) : const Color.fromARGB(255, 216, 29, 29);
    final statusBg = isResolved ? const Color(0xFFDCFCE7) : const Color.fromARGB(255, 255, 239, 239);
    final statusIcon = isResolved ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.clock_solid;
    final statusText = isResolved ? t['resolved']! : t['unresolved']!;

    final itemName = r['item_produksi']?['nama_item'] ?? r['nama_item_manual'] ?? '-';
    final subKategori = r['subkategoritemuan']?['nama_subkategoritemuan'] ?? '-';
    final dateStr = r['created_at'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(r['created_at'])) : '-';
    final imageUrl = r['item_produksi']?['gambar_item'] ?? r['gambar_temuan'];
    final isOwner = r['id_user'] == _currentUserId;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => KtsProduksiDetailScreen(ktsId: r['id_temuan'].toString(), lang: widget.lang)));
        if (result == true) _fetchReports();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder, width: 1.5),
          boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha:0.07), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: imageUrl != null
                          ? Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildItemIcon())
                          : _buildItemIcon(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(r['judul_temuan'] ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 11, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(statusText, style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(itemName, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildChip(CupertinoIcons.tag, '${t['order']}: ${r['no_order'] ?? '-'}', _kPrimaryLight, _kPrimary),
                            const SizedBox(width: 8),
                            _buildChip(CupertinoIcons.cube_box, '${r['jumlah_item'] ?? 0} pcs', const Color(0xFFF0FDF4), const Color(0xFF22C55E)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.folder_fill, size: 12, color: _kPrimary),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(subKategori, style: GoogleFonts.inter(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(CupertinoIcons.calendar, size: 12, color: _kPrimaryDark),
                      const SizedBox(width: 4),
                      Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: _kPrimaryDark, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 10),
                    _buildActionButton(
                      icon: CupertinoIcons.pencil_ellipsis_rectangle,
                      color: _kPrimary,
                      bgColor: _kPrimaryLight,
                      onTap: () async {
                        if (!await _checkAtmiOrBlock()) return;
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => KtsProduksiFormScreen(lang: widget.lang, existingData: r)));
                        if (result == true) _fetchReports();
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: CupertinoIcons.trash,
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFFF1F2),
                      onTap: () async {
                        if (!await _checkAtmiOrBlock()) return;
                        _deleteReport(r['id_temuan'].toString());
                      },
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

  Widget _buildChip(IconData icon, String label, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required Color bgColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha:0.25), width: 1)),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildItemIcon() {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFBFDBFE)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14)),
      child: const Icon(CupertinoIcons.hammer_fill, color: _kPrimary, size: 28),
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
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFBFDBFE)], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.doc_text_search, size: 52, color: _kPrimary),
          ),
          const SizedBox(height: 24),
          Text(t['empty_title']!, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(t['empty_sub']!, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFBFDBFE),
      highlightColor: const Color(0xFFEFF6FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 28),
            Container(height: 16, width: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 14),
            ...List.generate(3, (_) => Container(margin: const EdgeInsets.only(bottom: 16), height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LAYAR DETAIL KTS PRODUKSI
// ============================================================
class KtsProduksiDetailScreen extends StatefulWidget {
  final String ktsId;
  final String lang;
  const KtsProduksiDetailScreen({super.key, required this.ktsId, required this.lang});

  @override
  State<KtsProduksiDetailScreen> createState() => _KtsProduksiDetailScreenState();
}

class _KtsProduksiDetailScreenState extends State<KtsProduksiDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isSavingResolution = false;
  String? _currentUserId;
  bool _isDataChanged = false;

  final _tindakanCtrl = TextEditingController();
  final _biayaCtrl    = TextEditingController();
  XFile? _resImageFile;
  final _penyebabCtrl = TextEditingController();
  List<Map<String, dynamic>> _subKategoriList = [];
  Map<String, dynamic>? _selectedSubKategori;
  String? _selectedBagian;

  static const Color _kPrimary      = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight = Color(0xFFEFF6FF);
  static const Color _kBorder       = Color(0xFFBFDBFE);
  static const Color _kBg           = Color(0xFFF0F4FF);

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Detail KTS Produksi',
      'order': 'No. Order', 'item': 'Item Produksi', 'qty': 'Jumlah',
      'kategori': 'Kategori KTS', 'status': 'Status', 'reported': 'Dilaporkan',
      'desc': 'Deskripsi',
      'solution_title': 'Solusi',              // ← "Solution" bukan "Resolution"
      'solution_done': 'KTS Sudah Teratasi',
      'upload_photo': 'Foto Solusi',
      'cause': 'Penyebab',
      'cause_hint': 'Jelaskan penyebab...',
      'cause_factor': 'Faktor Penyebab',
      'bagian': 'Bagian',
      'pick_bagian': 'Pilih Bagian',
      'tindakan': 'Tindakan',
      'tindakan_hint': 'Jelaskan tindakan...',
      'biaya': 'Biaya (Opsional)', 'biaya_hint': 'Contoh: 50000',
      'save_solution': 'Simpan Solusi',
      'err_tindakan': 'Tindakan wajib diisi!',
      'err_photo': 'Foto solusi wajib diunggah!',
      'success_res': 'KTS berhasil diselesaikan! +10 poin',
      'fail_res': 'Gagal menyimpan solusi',
      'resolved': 'Teratasi', 'unresolved': 'Belum Teratasi',
      'resolved_by': 'Diselesaikan oleh', 'resolved_at': 'Selesai pada',
      'cost': 'Biaya', 'edit': 'Edit', 'evidence_photo': 'Foto Bukti',
      'reported_by': 'Dilaporkan oleh',
      'pic_label': 'Penanggung Jawab',
      'delete': 'Hapus', 'delete_confirm': 'Hapus laporan KTS ini?',
      'cancel': 'Batal', 'deleted': 'Laporan KTS dihapus',
      'kts_badge': 'KTS PRODUKSI',
    },
    'EN': {
      'title': 'KTS Detail',
      'order': 'Order No.', 'item': 'Production Item', 'qty': 'Quantity',
      'kategori': 'Category', 'status': 'Status', 'reported': 'Reported',
      'desc': 'Description',
      'solution_title': 'Solution',
      'solution_done': 'Resolved',
      'upload_photo': 'Solution Photo',
      'cause': 'Cause',
      'cause_hint': 'Describe the cause...',
      'cause_factor': 'Cause Factor',
      'bagian': 'Section',
      'pick_bagian': 'Select Section',
      'tindakan': 'Action Taken',
      'tindakan_hint': 'Explain action...',
      'biaya': 'Cost (Optional)', 'biaya_hint': 'Example: 50000',
      'save_solution': 'Save Solution',
      'err_tindakan': 'Action description required!',
      'err_photo': 'Solution photo required!',
      'success_res': 'KTS resolved! +10 points',
      'fail_res': 'Failed to save',
      'resolved': 'Resolved', 'unresolved': 'Unresolved',
      'resolved_by': 'Resolved by', 'resolved_at': 'Completed on',
      'cost': 'Cost', 'edit': 'Edit', 'evidence_photo': 'Evidence Photo',
      'reported_by': 'Reported by',
      'pic_label': 'Person in Charge',
      'delete': 'Delete', 'delete_confirm': 'Delete this report?',
      'cancel': 'Cancel', 'deleted': 'Report deleted',
      'kts_badge': 'KTS PRODUCTION',
    },
    'ZH': {
      'title': 'KTS详情',
      'order': '订单号', 'item': '生产项目', 'qty': '数量',
      'kategori': '类别', 'status': '状态', 'reported': '报告时间',
      'desc': '描述',
      'solution_title': '解决方案',
      'solution_done': '已解决',
      'upload_photo': '解决照片',
      'cause': '原因',
      'cause_hint': '说明原因...',
      'cause_factor': '原因因素',
      'bagian': '部门',
      'pick_bagian': '选择部门',
      'tindakan': '行动',
      'tindakan_hint': '说明行动...',
      'biaya': '费用（可选）', 'biaya_hint': '例如：50000',
      'save_solution': '保存方案',
      'err_tindakan': '行动必填！',
      'err_photo': '照片必填！',
      'success_res': '已解决！+10积分',
      'fail_res': '保存失败',
      'resolved': '已解决', 'unresolved': '未解决',
      'resolved_by': '解决者', 'resolved_at': '完成时间',
      'cost': '费用', 'edit': '编辑', 'evidence_photo': '证据照片',
      'reported_by': '报告人',
      'pic_label': '负责人',
      'delete': '删除', 'delete_confirm': '删除报告？',
      'cancel': '取消', 'deleted': '已删除',
      'kts_badge': 'KTS生产',
    },
  };

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadSubKategoriKtsProduksi();
    _loadData();
  }

  @override
  void dispose() {
    _tindakanCtrl.dispose();
    _biayaCtrl.dispose();
    _penyebabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubKategoriKtsProduksi() async {
    try {
      // Ambil id kategoritemuan dengan nama_kategoritemuan = 'KTS Produksi'
      final katData = await Supabase.instance.client
          .from('kategoritemuan')
          .select('id_kategoritemuan')
          .eq('nama_kategoritemuan', 'KTS Produksi')
          .maybeSingle();
      if (katData == null) return;
      final String katId = katData['id_kategoritemuan'].toString();

      final data = await Supabase.instance.client
          .from('subkategoritemuan')
          .select('id_subkategoritemuan, nama_subkategoritemuan')
          .eq('id_kategoritemuan', katId)
          .order('nama_subkategoritemuan');
      if (mounted) {
        setState(() => _subKategoriList = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint('Error load subkategori KTS Produksi: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('temuan')
          .select('''
            id_temuan, no_order, judul_temuan, deskripsi_temuan,
            gambar_temuan, status_temuan, poin_temuan,
            jumlah_item, nama_item_manual, jenis_temuan,
            created_at, id_user, id_penyelesaian,
            id_penanggung_jawab,
            subkategoritemuan:id_subkategoritemuan_uuid(
              id_subkategoritemuan, nama_subkategoritemuan
            ),
            item_produksi:id_item(id_item, nama_item, gambar_item, kode_item),
            lokasi:id_lokasi(nama_lokasi),
            penanggung_jawab:id_penanggung_jawab(id_user, nama, gambar_user)
          ''')
          .eq('id_temuan', widget.ktsId)
          .single();

      Map<String, dynamic>? pelaporData;
      if (data['id_user'] != null) {
        try {
          pelaporData = await Supabase.instance.client
              .from('User')
              .select('nama, gambar_user')
              .eq('id_user', data['id_user'])
              .maybeSingle();
        } catch (_) {}
      }

      Map<String, dynamic>? penyelesaianData;
      final idPenyelesaian = data['id_penyelesaian'];
      if (idPenyelesaian != null) {
        try {
          penyelesaianData = await Supabase.instance.client
              .from('penyelesaian')
              .select('id_penyelesaian, gambar_penyelesaian, catatan_penyelesaian, tanggal_selesai, poin_penyelesaian, additional_cost, id_user, penyebab, bagian, id_faktor_penyebab, faktor_penyebab_kts:id_faktor_penyebab(id_faktor, nama_faktor)')
              .eq('id_penyelesaian', idPenyelesaian)
              .maybeSingle();
          if (penyelesaianData != null && penyelesaianData['id_user'] != null) {
            final solverRes = await Supabase.instance.client
                .from('User')
                .select('nama, gambar_user')
                .eq('id_user', penyelesaianData['id_user'])
                .maybeSingle();
            penyelesaianData['solver'] = solverRes;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _data = {...data, 'pelapor': pelaporData, 'penyelesaian': penyelesaianData};
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading KTS detail: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(t['delete_confirm']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context, false), child: Text(t['cancel']!, style: const TextStyle(color: CupertinoColors.systemBlue))),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context, true), child: Text(t['delete']!)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('temuan').delete().eq('id_temuan', widget.ktsId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['deleted']!), backgroundColor: CupertinoColors.activeGreen));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }

  Future<void> _pickResImage() async {
    if (kIsWeb) {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (img != null && mounted) setState(() => _resImageFile = img);
      return;
    }
    final img = await Navigator.push<XFile?>(context, MaterialPageRoute(builder: (_) => const KtsCameraScreen()));
    if (img != null && mounted) setState(() => _resImageFile = img);
  }

  Future<void> _showSectionPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _KtsSectionPickerSheet(lang: widget.lang),
    );
    if (result != null) {
      final name = widget.lang == 'EN'
          ? (result['nama_section_en']?.toString() ?? result['nama_section_id']?.toString())
          : widget.lang == 'ZH'
              ? (result['nama_section_zh']?.toString() ?? result['nama_section_id']?.toString())
              : result['nama_section_id']?.toString();
      setState(() => _selectedBagian = name);
    }
  }

  Future<void> _saveResolution() async {
    final locResult = await LocationService.instance.checkUserAtAtmi(forceRefresh: true);
    if (!locResult.isAtAtmi) {
      if (!mounted) return;
      final msg = widget.lang == 'EN'
          ? 'Resolution can only be submitted within PT ATMI Solo area.'
          : widget.lang == 'ZH' ? '解决方案只能在PT ATMI Solo区域内提交。'
          : 'Penyelesaian hanya dapat dilakukan di area PT ATMI Solo.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.location_off_rounded, color: Colors.white, size: 16), const SizedBox(width: 8), Expanded(child: Text(msg))]),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    if (_resImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['err_photo']!), backgroundColor: CupertinoColors.destructiveRed));
      return;
    }
    if (_tindakanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['err_tindakan']!), backgroundColor: CupertinoColors.destructiveRed));
      return;
    }

    setState(() => _isSavingResolution = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final bytes = await _resImageFile!.readAsBytes();
      final fileName = '${user.id}/kts_res_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('temuan_images').uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);

      final biayaValue = _biayaCtrl.text.trim().isEmpty ? null : double.tryParse(_biayaCtrl.text.trim());

      final insertRes = await supabase.from('penyelesaian').insert({
        'gambar_penyelesaian': imageUrl,
        'catatan_penyelesaian': _tindakanCtrl.text.trim(),
        'additional_cost': biayaValue,
        'tanggal_selesai': DateTime.now().toIso8601String(),
        'id_user': user.id,
        'poin_penyelesaian': 10,
        'penyebab': _penyebabCtrl.text.trim().isEmpty
            ? (_selectedSubKategori != null ? _selectedSubKategori!['nama_subkategoritemuan'] : null)
            : _penyebabCtrl.text.trim(),
        'bagian': _selectedBagian,
        'id_subkategoritemuan_penyebab': _selectedSubKategori?['id_subkategoritemuan'],
      }).select('id_penyelesaian').single();

      final String newPenyelesaianId = insertRes['id_penyelesaian'].toString();
      await supabase.from('temuan').update({'status_temuan': 'Selesai', 'id_penyelesaian': newPenyelesaianId}).eq('id_temuan', widget.ktsId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['success_res']!), backgroundColor: CupertinoColors.activeGreen));
        _isDataChanged = true;
        _loadData();
        setState(() => _isSavingResolution = false);
      }
    } catch (e) {
      debugPrint('Resolution error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t['fail_res']!}: $e'), backgroundColor: CupertinoColors.destructiveRed));
        setState(() => _isSavingResolution = false);
      }
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try { return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(d).toLocal()); } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _isDataChanged);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(icon: const Icon(CupertinoIcons.back, color: _kPrimary), onPressed: () => Navigator.pop(context, _isDataChanged)),
          title: Text(t['title']!, style: GoogleFonts.inter(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
          centerTitle: true,
          actions: _data != null && _data!['id_user'] == _currentUserId
              ? [
                  _buildAppBarBtn(CupertinoIcons.pencil_ellipsis_rectangle, _kPrimary, _kPrimaryLight, () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => KtsProduksiFormScreen(lang: widget.lang, existingData: _data!)));
                    if (result == true) { _isDataChanged = true; _loadData(); }
                  }),
                  const SizedBox(width: 4),
                  _buildAppBarBtn(CupertinoIcons.trash, const Color(0xFFEF4444), const Color(0xFFFFF1F2), _deleteReport),
                  const SizedBox(width: 8),
                ]
              : null,
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: _kBorder, height: 1)),
        ),
        body: _isLoading
            ? _buildDetailShimmer()
            : _data == null
                ? Center(child: Text('Data tidak ditemukan', style: GoogleFonts.inter(color: CupertinoColors.systemGrey)))
                : _buildContent(),
      ),
    );
  }

  Widget _buildAppBarBtn(IconData icon, Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha:0.3), width: 1)),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }

  Widget _buildDetailShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 240, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Row(children: [
              Container(height: 24, width: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 8),
              Container(height: 24, width: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            ]),
            const SizedBox(height: 12),
            Container(height: 28, width: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(height: 300, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final status = d['status_temuan'] ?? 'Open';
    final isResolved = status == 'Closed' || status == 'Teratasi' || status == 'Selesai';
    final statusColor = isResolved ? const Color(0xFF16A34A) : _kPrimary;
    final statusBg = isResolved ? const Color(0xFFDCFCE7) : _kPrimaryLight;
    final statusIcon = isResolved ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.clock_solid;
    final statusText = isResolved ? t['resolved']! : t['unresolved']!;

    final itemName = d['item_produksi']?['nama_item'] ?? d['nama_item_manual'] ?? '-';
    final itemImg = d['item_produksi']?['gambar_item'];
    final itemKode = d['item_produksi']?['kode_item'] ?? '';
    final pelapor = d['pelapor'] as Map<String, dynamic>?;
    final picData = d['penanggung_jawab'] as Map<String, dynamic>?;
    final penyelesaian = d['penyelesaian'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Header
          if (d['gambar_temuan'] != null) ...[
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 16, offset: const Offset(0, 6))]),
              child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(d['gambar_temuan'], width: double.infinity, height: 240, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 20),
          ],

          // Badges
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(10)),
              child: Text(t['kts_badge']!, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withValues(alpha:0.3), width: 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(statusText, style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(d['judul_temuan'] ?? '-', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 24),

          // Info Card
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kBorder, width: 1.5), boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha:0.06), blurRadius: 16, offset: const Offset(0, 4))]),
            child: Column(
              children: [
                // Item header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: itemImg != null
                            ? Image.network(itemImg, width: 60, height: 60, fit: BoxFit.cover)
                            : _buildItemPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(itemName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A))),
                        if (itemKode.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(6)),
                            child: Text(itemKode, style: GoogleFonts.inter(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    )),
                  ]),
                ),
                _divider(),
                _buildInfoRow(CupertinoIcons.tag, t['order']!, d['no_order'] ?? '-'),
                _divider(),
                _buildInfoRow(CupertinoIcons.cube_box, t['qty']!, '${d['jumlah_item'] ?? 0} pcs'),
                _divider(),
                _buildInfoRow(CupertinoIcons.calendar, t['reported']!, _formatDate(d['created_at'])),
                // ── Person in Charge ──
                if (picData != null) ...[
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      const Icon(CupertinoIcons.person_fill, color: _kPrimary, size: 18),
                      const SizedBox(width: 12),
                      Text(t['pic_label']!, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
                      const Spacer(),
                      Row(children: [
                        Text(picData['nama'] ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A))),
                        const SizedBox(width: 8),
                        picData['gambar_user'] != null
                            ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(picData['gambar_user']))
                            : Container(width: 28, height: 28, decoration: const BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle), child: const Icon(CupertinoIcons.person_fill, size: 14, color: _kPrimary)),
                      ]),
                    ]),
                  ),
                ],
                // ── Reported By ──
                if (pelapor != null) ...[
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      const Icon(CupertinoIcons.person_2_fill, color: _kPrimary, size: 18),
                      const SizedBox(width: 12),
                      Text(t['reported_by']!, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
                      const Spacer(),
                      Row(children: [
                        Text(pelapor['nama'] ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A))),
                        const SizedBox(width: 8),
                        pelapor['gambar_user'] != null
                            ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(pelapor['gambar_user']))
                            : Container(width: 28, height: 28, decoration: const BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle), child: const Icon(CupertinoIcons.person_fill, size: 14, color: _kPrimary)),
                      ]),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Deskripsi
          if (d['deskripsi_temuan'] != null && d['deskripsi_temuan'].toString().isNotEmpty) ...[
            _buildSectionTitle(CupertinoIcons.doc_text, t['desc']!),
            const SizedBox(height: 10),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder, width: 1.5)),
              child: Text(d['deskripsi_temuan'], style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF334155), height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // Solution section
          _buildSectionTitle(
            isResolved ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.wrench_fill,
            t['solution_title']!,
            color: isResolved ? const Color(0xFF16A34A) : _kPrimary,
          ),
          const SizedBox(height: 10),
          if (isResolved && penyelesaian != null)
            _buildSolutionResult(penyelesaian)
          else if (!isResolved)
            _buildSolutionForm(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0xFFF1F5F9));

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: _kPrimary, size: 18),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
        const Spacer(),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A)))),
      ]),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, {Color color = _kPrimary}) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
    ]);
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 60, height: 60,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFBFDBFE)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: const Icon(CupertinoIcons.cube_box, color: _kPrimary, size: 28),
    );
  }

  // ── Solution Result (tampilkan bagian, penyebab, faktor) ──
  Widget _buildSolutionResult(Map<String, dynamic> p) {
    final solver = p['solver'] as Map<String, dynamic>?;
    final biaya = p['additional_cost'] as num?;
    final biayaStr = biaya != null && biaya > 0
        ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(biaya)
        : '-';
    final String? penyebab = p['penyebab']?.toString();
    final String? bagian = p['bagian']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha:0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['gambar_penyelesaian'] != null)
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network(p['gambar_penyelesaian'], width: double.infinity, height: 200, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    Text(t['solution_done']!, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF16A34A))),
                  ]),
                ),
                const SizedBox(height: 16),
                // Bagian
                if (bagian != null && bagian.isNotEmpty) ...[
                  _resultRow(CupertinoIcons.square_grid_2x2_fill, t['bagian']!, bagian),
                  const SizedBox(height: 12),
                ],
                // Faktor Penyebab (nama subkategori yang disimpan di penyebab)
                if (penyebab != null && penyebab.isNotEmpty) ...[
                  _resultRow(CupertinoIcons.tag_fill, t['cause_factor']!, penyebab),
                  const SizedBox(height: 12),
                ],
                // Tindakan
                Text(t['tindakan']!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Text(p['catatan_penyelesaian'] ?? '-', style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF0F172A), height: 1.5)),

                if (biaya != null && biaya > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFED7AA))),
                    child: Row(children: [
                      const Icon(CupertinoIcons.money_dollar_circle, color: Color(0xFFEA580C), size: 18),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t['cost']!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), fontWeight: FontWeight.w600)),
                        Text(biayaStr, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
                      ]),
                    ]),
                  ),
                ],
                if (solver != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                    child: Row(children: [
                      solver['gambar_user'] != null
                          ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(solver['gambar_user']))
                          : Container(width: 40, height: 40, decoration: const BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle), child: const Icon(CupertinoIcons.person_fill, size: 20, color: _kPrimary)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t['resolved_by']!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                        Text(solver['nama'] ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
                      ]),
                    ]),
                  ),
                ],
                if (p['tanggal_selesai'] != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(CupertinoIcons.clock_fill, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text('${t['resolved_at']}: ${_formatDate(p['tanggal_selesai'])}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 14, color: _kPrimary),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // ── Solution Form ──
  Widget _buildSolutionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha:0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto
          Row(children: [
            Text(t['upload_photo']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
            const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed)),
          ]),
          const SizedBox(height: 8),
          _resImageFile == null
              ? GestureDetector(
                  onTap: _pickResImage,
                  child: Container(
                    height: 140, width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder, width: 1.5)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle), child: const Icon(CupertinoIcons.camera, color: _kPrimary, size: 26)),
                      const SizedBox(height: 10),
                      Text(widget.lang == 'EN' ? 'Take Photo' : widget.lang == 'ZH' ? '拍照' : 'Ambil Foto', style: GoogleFonts.inter(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    ]),
                  ),
                )
              : Stack(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(14), child: kIsWeb ? Image.network(_resImageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover) : Image.file(File(_resImageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover)),
                    Positioned(right: 12, bottom: 12, child: GestureDetector(
                      onTap: _pickResImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.6), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [const Icon(CupertinoIcons.camera_rotate, color: Colors.white, size: 14), const SizedBox(width: 6), Text(widget.lang == 'EN' ? 'Retake' : 'Ganti', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))]),
                      ),
                    )),
                  ],
                ),
          const SizedBox(height: 16),

          // ── BAGIAN (dari tabel section) ──
          Text(
            t['bagian']!,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showSectionPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedBagian != null ? _kPrimary : _kBorder,
                  width: _selectedBagian != null ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.square_grid_2x2_fill,
                    size: 18,
                    color: _selectedBagian != null ? _kPrimary : const Color(0xFFBFDBFE),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedBagian ?? t['pick_bagian']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: _selectedBagian != null ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedBagian != null ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 15,
                    color: _selectedBagian != null ? _kPrimary : const Color(0xFFBFDBFE),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── PENYEBAB (text) ──
          Text(t['cause']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          TextFormField(
            controller: _penyebabCtrl,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: t['cause_hint']!,
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          // ── FAKTOR PENYEBAB (dari subkategoritemuan KTS Produksi) ──
          Text(
            t['cause_factor']!,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          _subKategoriList.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: Row(children: [
                    const CupertinoActivityIndicator(radius: 8),
                    const SizedBox(width: 10),
                    Text(
                      widget.lang == 'EN'
                          ? 'Loading...'
                          : widget.lang == 'ZH'
                              ? '加载中...'
                              : 'Memuat...',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
                    ),
                  ]),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedSubKategori != null
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFFBFDBFE),
                      width: _selectedSubKategori != null ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        value: _selectedSubKategori,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        menuMaxHeight: 320,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(children: [
                            const Icon(CupertinoIcons.tag, size: 16, color: Color(0xFFBFDBFE)),
                            const SizedBox(width: 10),
                            Text(
                              widget.lang == 'ZH'
                                  ? '选择类别（可选）'
                                  : widget.lang == 'EN'
                                      ? 'Select category (optional)'
                                      : 'Pilih kategori (opsional)',
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFCBD5E1)),
                            ),
                          ]),
                        ),
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            _selectedSubKategori != null
                                ? CupertinoIcons.chevron_up_chevron_down
                                : CupertinoIcons.chevron_down,
                            size: 15,
                            color: _selectedSubKategori != null
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFFBFDBFE),
                          ),
                        ),
                        selectedItemBuilder: (context) => _subKategoriList.map((f) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(children: [
                            const Icon(CupertinoIcons.tag_fill, size: 16, color: Color(0xFF1D4ED8)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f['nama_subkategoritemuan'] ?? '',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        )).toList(),
                        items: _subKategoriList.map((f) {
                          final isSelected = _selectedSubKategori?['id_subkategoritemuan'] == f['id_subkategoritemuan'];
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: f,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(CupertinoIcons.tag_fill, size: 14, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    f['nama_subkategoritemuan'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(CupertinoIcons.checkmark_circle_fill, size: 18, color: Color(0xFF1D4ED8)),
                              ]),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSubKategori = val),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 16),

          // ── TINDAKAN ──
          Row(children: [
            Text(t['tindakan']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
            const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed)),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tindakanCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: t['tindakan_hint']!,
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          // ── BIAYA ──
          Text(t['biaya']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          TextFormField(
            controller: _biayaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: t['biaya_hint']!,
              prefixText: 'Rp ',
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          // ── TOMBOL SIMPAN ──
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: _isSavingResolution ? null : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                color: _isSavingResolution ? const Color(0xFFE2E8F0) : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isSavingResolution ? null : [BoxShadow(color: _kPrimary.withValues(alpha:0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: _isSavingResolution ? null : _saveResolution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSavingResolution
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(t['save_solution']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KtsSectionPickerSheet extends StatefulWidget {
  final String lang;
  const _KtsSectionPickerSheet({required this.lang});

  @override
  State<_KtsSectionPickerSheet> createState() => _KtsSectionPickerSheetState();
}

class _KtsSectionPickerSheetState extends State<_KtsSectionPickerSheet> {
  static const Color _kPrimary      = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight = Color(0xFFEFF6FF);
  static const Color _kBorder       = Color(0xFFBFDBFE);

  List<Map<String, dynamic>> _lokasiList = [];
  List<Map<String, dynamic>> _unitList = [];
  List<Map<String, dynamic>> _subunitList = [];
  List<Map<String, dynamic>> _areaList = [];

  String? _selLokasiId;
  String? _selUnitId;
  String? _selSubunitId;
  String? _selAreaId;
  String? _selLokasiName;
  String? _selUnitName;
  String? _selSubunitName;
  String? _selAreaName;

  List<Map<String, dynamic>> _allSections = [];
  List<Map<String, dynamic>> _filteredSections = [];
  bool _isLoadingLocations = true;
  bool _isLoadingSections = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadLocations();
    _loadSections();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _nameOf(Map<String, dynamic> s) {
    if (widget.lang == 'EN') return s['nama_section_en']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    if (widget.lang == 'ZH') return s['nama_section_zh']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    return s['nama_section_id']?.toString() ?? '-';
  }

  String _locationBadge(Map<String, dynamic> s) {
    final parts = <String>[];
    if (s['lokasi']?['nama_lokasi'] != null) parts.add(s['lokasi']['nama_lokasi']);
    if (s['unit']?['nama_unit'] != null) parts.add(s['unit']['nama_unit']);
    if (s['subunit']?['nama_subunit'] != null) parts.add(s['subunit']['nama_subunit']);
    if (s['area']?['nama_area'] != null) parts.add(s['area']['nama_area']);
    return parts.isEmpty ? '' : parts.join(' • ');
  }

  Future<void> _loadLocations() async {
    try {
      final data = await Supabase.instance.client.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
      if (mounted) setState(() { _lokasiList = List<Map<String, dynamic>>.from(data); _isLoadingLocations = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUnit(String lokasiId) async {
    final res = await Supabase.instance.client.from('unit').select('id_unit, nama_unit').eq('id_lokasi', lokasiId).order('nama_unit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchSubunit(String unitId) async {
    final res = await Supabase.instance.client.from('subunit').select('id_subunit, nama_subunit').eq('id_unit', unitId).order('nama_subunit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchArea(String subunitId) async {
    final res = await Supabase.instance.client.from('area').select('id_area, nama_area').eq('id_subunit', subunitId).order('nama_area');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _loadSections({String? lokasiId, String? unitId, String? subunitId, String? areaId}) async {
    setState(() => _isLoadingSections = true);
    try {
      dynamic query = Supabase.instance.client
          .from('section')
          .select('*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)');
      if (areaId != null) {
        query = query.eq('id_area', areaId);
      } else if (subunitId != null) {
        query = query.eq('id_subunit', subunitId);
      } else if (unitId != null) {
        query = query.eq('id_unit', unitId);
      } else if (lokasiId != null) {
        query = query.eq('id_lokasi', lokasiId);
      }

      final data = await query.order('urutan', ascending: true);
      final sections = List<Map<String, dynamic>>.from(data);
      if (mounted) {
        setState(() {
          _allSections = sections;
          _filteredSections = _applySearch(sections);
          _isLoadingSections = false;
        });
      }
    } catch (e) {
      debugPrint('Error load section: $e');
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> src) {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return src;
    return src.where((s) => _nameOf(s).toLowerCase().contains(q)).toList();
  }

  void _onSearch() => setState(() => _filteredSections = _applySearch(_allSections));

  void _applyFilter() => _loadSections(lokasiId: _selLokasiId, unitId: _selUnitId, subunitId: _selSubunitId, areaId: _selAreaId);

  int get _activeFilterCount {
    int c = 0;
    if (_selLokasiId != null) c++;
    if (_selUnitId != null) c++;
    if (_selSubunitId != null) c++;
    if (_selAreaId != null) c++;
    return c;
  }

  Widget _activeFilterChip({required IconData icon, required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kPrimary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(CupertinoIcons.xmark_circle_fill, size: 15, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  void _removeLokasiFilter() {
    setState(() {
      _selLokasiId = null; _selLokasiName = null;
      _selUnitId = null; _selUnitName = null;
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _unitList = []; _subunitList = []; _areaList = [];
    });
    _loadSections();
  }

  void _removeUnitFilter() {
    setState(() {
      _selUnitId = null; _selUnitName = null;
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _subunitList = []; _areaList = [];
    });
    _applyFilter();
  }

  void _removeSubunitFilter() {
    setState(() {
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _areaList = [];
    });
    _applyFilter();
  }

  void _removeAreaFilter() {
    setState(() {
      _selAreaId = null; _selAreaName = null;
    });
    _applyFilter();
  }

  Future<void> _openFilterDialog() async {
    String? tLokasiId = _selLokasiId;
    String? tLokasiName = _selLokasiName;
    String? tUnitId = _selUnitId;
    String? tUnitName = _selUnitName;
    String? tSubunitId = _selSubunitId;
    String? tSubunitName = _selSubunitName;
    String? tAreaId = _selAreaId;
    String? tAreaName = _selAreaName;
    List<Map<String, dynamic>> tUnitList = List.from(_unitList);
    List<Map<String, dynamic>> tSubunitList = List.from(_subunitList);
    List<Map<String, dynamic>> tAreaList = List.from(_areaList);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: _kPrimaryLight.withValues(alpha:0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.slider_horizontal_3, color: _kPrimary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.lang == 'EN' ? 'Filter Location' : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(CupertinoIcons.xmark, size: 15, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isLoadingLocations
                            ? const Center(child: CupertinoActivityIndicator())
                            : _buildFilterChips(
                                label: widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi',
                                icon: CupertinoIcons.building_2_fill,
                                items: _lokasiList,
                                idKey: 'id_lokasi', nameKey: 'nama_lokasi',
                                selectedId: tLokasiId,
                                onSelect: (id) async {
                                  final selected = _lokasiList.firstWhere((e) => e['id_lokasi'].toString() == id);
                                  final units = await _fetchUnit(id);
                                  setDlg(() {
                                    tLokasiId = id;
                                    tLokasiName = selected['nama_lokasi']?.toString();
                                    tUnitId = null; tUnitName = null;
                                    tSubunitId = null; tSubunitName = null;
                                    tAreaId = null; tAreaName = null;
                                    tUnitList = units; tSubunitList = []; tAreaList = [];
                                  });
                                },
                              ),
                        if (tLokasiId != null && tUnitList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Unit', icon: CupertinoIcons.squares_below_rectangle,
                            items: tUnitList, idKey: 'id_unit', nameKey: 'nama_unit',
                            selectedId: tUnitId,
                            onSelect: (id) async {
                              final selected = tUnitList.firstWhere((e) => e['id_unit'].toString() == id);
                              final subs = await _fetchSubunit(id);
                              setDlg(() {
                                tUnitId = id;
                                tUnitName = selected['nama_unit']?.toString();
                                tSubunitId = null; tSubunitName = null;
                                tAreaId = null; tAreaName = null;
                                tSubunitList = subs; tAreaList = [];
                              });
                            },
                          ),
                        ],
                        if (tUnitId != null && tSubunitList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Sub-Unit', icon: CupertinoIcons.layers_alt_fill,
                            items: tSubunitList, idKey: 'id_subunit', nameKey: 'nama_subunit',
                            selectedId: tSubunitId,
                            onSelect: (id) async {
                              final selected = tSubunitList.firstWhere((e) => e['id_subunit'].toString() == id);
                              final areas = await _fetchArea(id);
                              setDlg(() {
                                tSubunitId = id;
                                tSubunitName = selected['nama_subunit']?.toString();
                                tAreaId = null; tAreaName = null;
                                tAreaList = areas;
                              });
                            },
                          ),
                        ],
                        if (tSubunitId != null && tAreaList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Area', icon: CupertinoIcons.location_fill,
                            items: tAreaList, idKey: 'id_area', nameKey: 'nama_area',
                            selectedId: tAreaId,
                            onSelect: (id) {
                              final selected = tAreaList.firstWhere((e) => e['id_area'].toString() == id);
                              setDlg(() {
                                tAreaId = id;
                                tAreaName = selected['nama_area']?.toString();
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 6, offset: const Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setDlg(() {
                              tLokasiId = null; tLokasiName = null;
                              tUnitId = null; tUnitName = null;
                              tSubunitId = null; tSubunitName = null;
                              tAreaId = null; tAreaName = null;
                              tUnitList = []; tSubunitList = []; tAreaList = [];
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kBorder),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            widget.lang == 'EN' ? 'Reset' : widget.lang == 'ZH' ? '重置' : 'Reset',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selLokasiId = tLokasiId; _selLokasiName = tLokasiName;
                              _selUnitId = tUnitId; _selUnitName = tUnitName;
                              _selSubunitId = tSubunitId; _selSubunitName = tSubunitName;
                              _selAreaId = tAreaId; _selAreaName = tAreaName;
                              _unitList = tUnitList; _subunitList = tSubunitList; _areaList = tAreaList;
                            });
                            Navigator.pop(dialogCtx);
                            _applyFilter();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            widget.lang == 'EN' ? 'Apply' : widget.lang == 'ZH' ? '应用' : 'Terapkan',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips({
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required String? selectedId,
    required Function(String id) onSelect,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 13, color: _kPrimary), const SizedBox(width: 6), Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) {
            final id = item[idKey].toString();
            final name = item[nameKey] as String;
            final isSelected = selectedId == id;
            return GestureDetector(
              onTap: () => onSelect(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? _kPrimary : _kBorder),
                  boxShadow: isSelected ? [BoxShadow(color: _kPrimary.withValues(alpha:0.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF1E293B))),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kPrimary, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.lang == 'ZH' ? '选择部门' : widget.lang == 'EN' ? 'Select Section' : 'Pilih Bagian', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
              IconButton(icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF94A3B8), size: 20), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Container(
            color: const Color(0xFFF8FAFF),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: _openFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _activeFilterCount > 0 ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _activeFilterCount > 0 ? _kPrimary : _kBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.slider_horizontal_3, size: 15, color: _activeFilterCount > 0 ? Colors.white : _kPrimary),
                          const SizedBox(width: 6),
                          Text(
                            widget.lang == 'EN' ? 'Filter Location' : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _activeFilterCount > 0 ? Colors.white : _kPrimary),
                          ),
                          if (_activeFilterCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Text('$_activeFilterCount', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: _kPrimary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_activeFilterCount > 0)
                    GestureDetector(
                      onTap: _removeLokasiFilter,
                      child: Text(
                        widget.lang == 'EN' ? 'Reset all' : widget.lang == 'ZH' ? '全部重置' : 'Reset Semua',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), decoration: TextDecoration.underline),
                      ),
                    ),
                ]),
                if (_activeFilterCount > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      if (_selLokasiId != null)
                        _activeFilterChip(icon: CupertinoIcons.building_2_fill, label: _selLokasiName ?? '-', onRemove: _removeLokasiFilter),
                      if (_selUnitId != null)
                        _activeFilterChip(icon: CupertinoIcons.squares_below_rectangle, label: _selUnitName ?? '-', onRemove: _removeUnitFilter),
                      if (_selSubunitId != null)
                        _activeFilterChip(icon: CupertinoIcons.layers_alt_fill, label: _selSubunitName ?? '-', onRemove: _removeSubunitFilter),
                      if (_selAreaId != null)
                        _activeFilterChip(icon: CupertinoIcons.location_fill, label: _selAreaName ?? '-', onRemove: _removeAreaFilter),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xFFE0E7FF), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextFormField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.lang == 'ZH' ? '搜索部门...' : widget.lang == 'EN' ? 'Search section...' : 'Cari bagian...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14),
                prefixIcon: const Icon(CupertinoIcons.search, color: _kPrimary, size: 18),
                filled: true, fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(children: [
              const Icon(CupertinoIcons.square_grid_2x2, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text('${_filteredSections.length} ${widget.lang == 'EN' ? 'sections' : widget.lang == 'ZH' ? '个部门' : 'bagian'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            ]),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 12),
          Expanded(
            child: _isLoadingSections
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredSections.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(CupertinoIcons.square_grid_2x2, size: 48, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        Text(widget.lang == 'EN' ? 'No sections found' : widget.lang == 'ZH' ? '未找到部门' : 'Tidak ada bagian', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: _filteredSections.length,
                        itemBuilder: (_, i) {
                          final s = _filteredSections[i];
                          final name = _nameOf(s);
                          final badge = _locationBadge(s);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(context, s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kPrimary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                                        if (badge.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(badge, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                                ]),
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