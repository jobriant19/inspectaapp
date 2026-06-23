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
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
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
                        boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
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
          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
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
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85)),
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
          boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
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
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.25), width: 1)),
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
// LAYAR FORM KTS PRODUKSI (CREATE & EDIT)
// ============================================================
class KtsProduksiFormScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? existingData;
  const KtsProduksiFormScreen({super.key, required this.lang, this.existingData});

  @override
  State<KtsProduksiFormScreen> createState() => _KtsProduksiFormScreenState();
}

class _KtsProduksiFormScreenState extends State<KtsProduksiFormScreen> {
  bool get _isEdit => widget.existingData != null;
  bool _isSaving = false;

  final _noOrderCtrl  = TextEditingController();
  final _judulCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _itemSearchCtrl = TextEditingController();

  Map<String, dynamic>? _selectedAssignee;

  int _qty = 1;
  XFile? _imageFile;
  String? _existingImageUrl;
  final _qtyCtrl = TextEditingController(text: '1');

  static const Color _kPrimary      = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight = Color(0xFFEFF6FF);
  static const Color _kBorder       = Color(0xFFBFDBFE);
  static const Color _kBg           = Color(0xFFF0F4FF);

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'create_title': 'Buat Laporan', 'edit_title': 'Edit Laporan',
      'no_order': 'No. Order', 'no_order_hint': 'Masukkan nomor order...',
      'judul': 'Judul KTS', 'judul_hint': 'Contoh: Part tidak sesuai',
      'item': 'Item Produksi', 'item_hint': 'Cari item...',
      'qty': 'Jumlah', 'photo': 'Foto Bukti', 'add_photo': 'Tambah Foto',
      'desc': 'Deskripsi (Opsional)', 'desc_hint': 'Jelaskan temuan secara detail...',
      'submit': 'Simpan Laporan', 'update': 'Perbarui Laporan',
      'err_order': 'No. Order wajib diisi!', 'err_judul': 'Judul wajib diisi!',
      'err_item': 'Item produksi wajib diisi!',
      'success': 'Laporan berhasil disimpan! +20 poin', 'success_edit': 'Laporan berhasil diperbarui!',
      'fail': 'Gagal menyimpan laporan', 'saving': 'Menyimpan...', 'cancel': 'Batal',
    },
    'EN': {
      'create_title': 'Create Report', 'edit_title': 'Edit Report',
      'no_order': 'Order No.', 'no_order_hint': 'Enter order number...',
      'judul': 'KTS Title', 'judul_hint': 'Example: Part mismatch',
      'item': 'Production Item', 'item_hint': 'Search item...',
      'qty': 'Qty', 'photo': 'Evidence Photo', 'add_photo': 'Add Photo',
      'desc': 'Description (Optional)', 'desc_hint': 'Explain the finding...',
      'submit': 'Save Report', 'update': 'Update Report',
      'err_order': 'Order No. is required!', 'err_judul': 'Title is required!',
      'err_item': 'Production item is required!',
      'success': 'Report saved! +20 points', 'success_edit': 'Report updated!',
      'fail': 'Failed to save report', 'saving': 'Saving...', 'cancel': 'Cancel',
    },
    'ZH': {
      'create_title': '创建报告', 'edit_title': '编辑报告',
      'no_order': '订单号', 'no_order_hint': '输入订单号...',
      'judul': '标题', 'judul_hint': '例如：零件不符',
      'item': '生产项目', 'item_hint': '搜索项目...',
      'qty': '数量', 'photo': '证据照片', 'add_photo': '添加照片',
      'desc': '描述（可选）', 'desc_hint': '详细说明...',
      'submit': '保存报告', 'update': '更新报告',
      'err_order': '订单号为必填项！', 'err_judul': '标题为必填项！',
      'err_item': '生产项目为必填项！',
      'success': '报告已保存！+20积分', 'success_edit': '报告已更新！',
      'fail': '保存报告失败', 'saving': '保存中...', 'cancel': '取消',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (_isEdit) _populateData();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('User')
          .select('id_user, nama, id_jabatan, id_lokasi, id_unit, id_subunit, id_area, jabatan!User_id_jabatan_fkey(nama_jabatan), gambar_user')
          .eq('id_user', user.id)
          .single();
      if (mounted && _selectedAssignee == null) {
        setState(() {
          _selectedAssignee = {
            'id_user': profile['id_user'],
            'nama': profile['nama'],
            'jabatan': profile['jabatan'],
            'gambar_user': profile['gambar_user'],
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  void _showAssigneePicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _KtsAssigneePickerSheet(lang: widget.lang, currentUserId: _selectedAssignee?['id_user']?.toString()),
    );
    if (result != null) setState(() => _selectedAssignee = result);
  }

  void _populateData() {
    final d = widget.existingData!;
    _noOrderCtrl.text = d['no_order'] ?? '';
    _judulCtrl.text = d['judul_temuan'] ?? '';
    _descCtrl.text = d['deskripsi_temuan']?.toString() ?? '';
    _qtyCtrl.text = (d['jumlah_item'] ?? 1).toString();
    _existingImageUrl = d['gambar_temuan'];
    _itemSearchCtrl.text = d['nama_item_manual'] ?? d['item_produksi']?['nama_item'] ?? '';
    if (d['penanggung_jawab'] != null) {
      _selectedAssignee = Map<String, dynamic>.from(d['penanggung_jawab']);
    } else if (d['id_penanggung_jawab'] != null) {
      _loadAssigneeById(d['id_penanggung_jawab'].toString());
    }
  }

  Future<void> _loadAssigneeById(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('User')
          .select('id_user, nama, jabatan!User_id_jabatan_fkey(nama_jabatan), gambar_user')
          .eq('id_user', userId)
          .single();
      if (mounted) setState(() => _selectedAssignee = data);
    } catch (e) {
      debugPrint('Error loading assignee: $e');
    }
  }

  @override
  void dispose() {
    _noOrderCtrl.dispose();
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _itemSearchCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 20), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            Text(
              widget.lang == 'EN' ? 'Add Evidence Photo' : widget.lang == 'ZH' ? '添加证据照片' : 'Tambah Foto Bukti',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 20),
            // Camera option
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                XFile? img;
                if (kIsWeb) {
                  // Web: gunakan image_picker langsung
                  img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                } else {
                  img = await _openKtsCameraScreen();
                }
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder, width: 1.5)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)), child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 22)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lang == 'EN' ? 'Take Photo' : widget.lang == 'ZH' ? '拍照' : 'Ambil Foto', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B))),
                        Text(widget.lang == 'EN' ? 'Open camera directly' : widget.lang == 'ZH' ? '直接打开相机' : 'Buka kamera langsung', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right, size: 16, color: _kPrimary),
                  ],
                ),
              ),
            ),
            // Gallery option
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                // Gunakan ImageSource.gallery tanpa preferGallery agar tidak memilih Google Photos
                final img = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder, width: 1.5)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(12)), child: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, color: _kPrimary, size: 22)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lang == 'EN' ? 'Choose from Gallery' : widget.lang == 'ZH' ? '从相册选择' : 'Pilih dari Galeri', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B))),
                        Text(widget.lang == 'EN' ? 'Select existing photo' : widget.lang == 'ZH' ? '选择现有照片' : 'Pilih foto yang sudah ada', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right, size: 16, color: _kPrimary),
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
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(t['cancel']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF64748B)))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<XFile?> _openKtsCameraScreen() async {
    if (kIsWeb) return null;
    return await Navigator.push<XFile?>(context, MaterialPageRoute(builder: (_) => const _KtsCameraScreen()));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: CupertinoColors.destructiveRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _submit() async {
    if (_noOrderCtrl.text.trim().isEmpty) return _showError(t['err_order']!);
    if (_judulCtrl.text.trim().isEmpty) return _showError(t['err_judul']!);
    if (_itemSearchCtrl.text.trim().isEmpty) return _showError(t['err_item']!);

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName = '${user.id}/kts_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);
      }

      final data = {
        'no_order': _noOrderCtrl.text.trim(),
        'judul_temuan': _judulCtrl.text.trim(),
        'id_subkategoritemuan_uuid': null,
        'id_kategoritemuan_uuid': null,
        'id_item': null,
        'nama_item_manual': _itemSearchCtrl.text.trim(),
        'id_penanggung_jawab': _selectedAssignee?['id_user'],
        'jumlah_item': int.tryParse(_qtyCtrl.text.trim()) ?? 1,
        'gambar_temuan': imageUrl,
        'deskripsi_temuan': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'jenis_temuan': 'KTS Production',
        'poin_temuan': 20,
        'status_temuan': 'Belum',
      };

      if (_isEdit) {
        final updateData = Map<String, dynamic>.from(data);
        updateData.remove('jenis_temuan');
        updateData.remove('poin_temuan');
        updateData.remove('status_temuan');
        await supabase.from('temuan').update(updateData).eq('id_temuan', widget.existingData!['id_temuan']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['success_edit']!), backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
        }
      } else {
        await supabase.from('temuan').insert({...data, 'id_user': user.id});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['success']!), backgroundColor: CupertinoColors.activeGreen));
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('KTS submit error: $e');
      if (mounted) {
        _showError('${t['fail']!}: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(CupertinoIcons.back, color: _kPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? t['edit_title']! : t['create_title']!, style: GoogleFonts.inter(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: _kBorder, height: 1)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(children: [
                  _buildLabel(t['no_order']!, isRequired: true),
                  _buildTextField(_noOrderCtrl, t['no_order_hint']!, CupertinoIcons.number),
                  const SizedBox(height: 20),
                  _buildLabel(t['judul']!, isRequired: true),
                  _buildTextField(_judulCtrl, t['judul_hint']!, CupertinoIcons.text_cursor),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(t['item']!, isRequired: true),
                            _buildTextField(_itemSearchCtrl, t['item_hint']!, CupertinoIcons.cube_box),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(t['qty']!, isRequired: true),
                            _buildQtyField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(widget.lang == 'ZH' ? '负责人' : widget.lang == 'EN' ? 'Person in Charge' : 'Penanggung Jawab', isRequired: false),
                  _buildTapField(icon: CupertinoIcons.person_fill, text: _selectedAssignee?['nama'] ?? (widget.lang == 'ZH' ? '选择负责人' : widget.lang == 'EN' ? 'Select PIC' : 'Pilih Penanggung Jawab'), hasValue: _selectedAssignee != null, onTap: _showAssigneePicker),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['photo']!, isRequired: false),
                  _buildPhotoWidget(),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['desc']!, isRequired: false),
                  _buildTextField(_descCtrl, t['desc_hint']!, CupertinoIcons.doc_text, maxLines: 4),
                ]),
                // ── Spacing proporsional sebelum tombol simpan ──
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isSaving) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(_isEdit ? t['update']! : t['submit']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
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
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF475569))),
          if (isRequired) const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
        prefixIcon: maxLines == 1 ? Icon(icon, color: _kPrimary, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTapField({required IconData icon, required String text, required VoidCallback onTap, bool hasValue = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? _kPrimary : _kBorder, width: hasValue ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasValue ? _kPrimary : const Color(0xFFCBD5E1), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 15, color: hasValue ? Colors.black87 : const Color(0xFFCBD5E1), fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal))),
            const Icon(CupertinoIcons.chevron_down, color: _kPrimary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              final current = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
              if (current > 1) {
                _qtyCtrl.text = (current - 1).toString();
              }
            },
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: SizedBox(
              width: 44,
              height: 52,
              child: Center(child: Icon(CupertinoIcons.minus, size: 16, color: _kPrimary)),
            ),
          ),
          Container(width: 1, height: 28, color: _kBorder),
          Expanded(
            child: TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed < 1) {
                  _qtyCtrl.text = '1';
                  _qtyCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _qtyCtrl.text.length),
                  );
                }
              },
            ),
          ),
          Container(width: 1, height: 28, color: _kBorder),
          InkWell(
            onTap: () {
              final current = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
              _qtyCtrl.text = (current + 1).toString();
            },
            borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
            child: SizedBox(
              width: 44,
              height: 52,
              child: const Center(child: Icon(CupertinoIcons.add, size: 16, color: _kPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget() {
    final hasPhoto = _imageFile != null || _existingImageUrl != null;
    if (!hasPhoto) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder, width: 1.5)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle), child: const Icon(CupertinoIcons.camera, color: _kPrimary, size: 28)),
              const SizedBox(height: 12),
              Text(t['add_photo']!, style: GoogleFonts.inter(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
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
                  ? Image.network(_imageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(_imageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover))
              : Image.network(_existingImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          right: 12, bottom: 12,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.camera_rotate, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(widget.lang == 'EN' ? 'Retake' : 'Ganti', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
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
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(CupertinoIcons.hammer_fill, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const CupertinoActivityIndicator(radius: 12, color: _kPrimary),
              const SizedBox(height: 14),
              Text(t['saving']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text(
                _isEdit
                    ? (widget.lang == 'EN' ? 'Updating your report...' : widget.lang == 'ZH' ? '正在更新报告...' : 'Memperbarui laporan Anda...')
                    : (widget.lang == 'EN' ? 'Uploading & saving report...' : widget.lang == 'ZH' ? '正在上传并保存...' : 'Mengunggah & menyimpan laporan...'),
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.star_fill, color: _kPrimary, size: 16),
                      const SizedBox(width: 6),
                      Text(widget.lang == 'EN' ? 'You will earn +20 points!' : widget.lang == 'ZH' ? '您将获得+20积分！' : 'Anda akan mendapat +20 poin!', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
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

  // Bagian list (gambar 3)
  static const List<String> _bagianList = [
    'Laser', 'Mesin', 'Spot', 'Las', 'Ftw', 'Cat',
    'Assy', 'Ekspedisi & Packing', 'Purchasing', 'Engineering', 'PPIC',
  ];
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
      // Web: pakai image_picker langsung
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (img != null && mounted) setState(() => _resImageFile = img);
      return;
    }
    final img = await Navigator.push<XFile?>(context, MaterialPageRoute(builder: (_) => const _KtsCameraScreen()));
    if (img != null && mounted) setState(() => _resImageFile = img);
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
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3), width: 1)),
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
    final subKategori = d['subkategoritemuan']?['nama_subkategoritemuan'] ?? '-';
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
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6))]),
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
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withOpacity(0.3), width: 1)),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kBorder, width: 1.5), boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))]),
            child: Column(
              children: [
                // Item header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
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
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
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
    final String? faktorNama = p['penyebab']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
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
        boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
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
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [const Icon(CupertinoIcons.camera_rotate, color: Colors.white, size: 14), const SizedBox(width: 6), Text(widget.lang == 'EN' ? 'Retake' : 'Ganti', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))]),
                      ),
                    )),
                  ],
                ),
          const SizedBox(height: 16),

          // ── BAGIAN (gambar 3) ──
          Text(
            t['bagian']!,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedBagian != null
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFBFDBFE),
                width: _selectedBagian != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedBagian,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  menuMaxHeight: 320,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(children: [
                      const Icon(
                        CupertinoIcons.square_grid_2x2,
                        size: 16,
                        color: Color(0xFFBFDBFE),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t['pick_bagian']!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                    ]),
                  ),
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      _selectedBagian != null
                          ? CupertinoIcons.chevron_up_chevron_down
                          : CupertinoIcons.chevron_down,
                      size: 15,
                      color: _selectedBagian != null
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  selectedItemBuilder: (context) => _bagianList.map((b) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(children: [
                      const Icon(
                        CupertinoIcons.square_grid_2x2_fill,
                        size: 16,
                        color: Color(0xFF1D4ED8),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        b,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ]),
                  )).toList(),
                  items: _bagianList.map((b) {
                    final isSelected = _selectedBagian == b;
                    return DropdownMenuItem<String>(
                      value: b,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.square_grid_2x2_fill,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              b,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              size: 18,
                              color: Color(0xFF1D4ED8),
                            ),
                        ]),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBagian = val),
                ),
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
                        color: Colors.black.withOpacity(0.04),
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
                boxShadow: _isSavingResolution ? null : [BoxShadow(color: _kPrimary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
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

// ============================================================
// KAMERA KHUSUS KTS PRODUKSI (Android only)
// ============================================================
class _KtsCameraScreen extends StatefulWidget {
  const _KtsCameraScreen();
  @override
  State<_KtsCameraScreen> createState() => _KtsCameraScreenState();
}

class _KtsCameraScreenState extends State<_KtsCameraScreen> with WidgetsBindingObserver {
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
    if (_cameras != null && _cameras!.isNotEmpty) await _setCamera(_camIndex);
  }

  Future<void> _setCamera(int i) async {
    await _ctrl?.dispose();
    _ctrl = CameraController(_cameras![i], ResolutionPreset.high, enableAudio: false);
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
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 16)));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_ctrl!)),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black.withOpacity(0.4),
                child: Row(children: [
                  IconButton(icon: const Icon(CupertinoIcons.back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  Expanded(child: Center(child: Text('FOTO KTS', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
                  const SizedBox(width: 48),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Galeri — gunakan image_picker dengan gallery source (bukan Google Photos)
                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (img != null && mounted) Navigator.pop(context, img);
                  },
                  child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(CupertinoIcons.photo, color: Colors.white)),
                ),
                // Tombol Capture
                GestureDetector(
                  onTap: () async {
                    if (_ctrl == null || _ctrl!.value.isTakingPicture) return;
                    try {
                      final pic = await _ctrl!.takePicture();
                      if (mounted) Navigator.pop(context, pic);
                    } on CameraException catch (e) {
                      debugPrint('Snap error: ${e.code}');
                    }
                  },
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    child: Padding(padding: const EdgeInsets.all(4), child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                  ),
                ),
                // Switch camera
                GestureDetector(
                  onTap: () {
                    if (_cameras == null || _cameras!.length < 2) return;
                    setState(() { _ready = false; _camIndex = (_camIndex + 1) % _cameras!.length; });
                    _setCamera(_camIndex);
                  },
                  child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(CupertinoIcons.switch_camera, color: Colors.white)),
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
// ASSIGNEE PICKER SHEET
// ============================================================
class _KtsAssigneePickerSheet extends StatefulWidget {
  final String lang;
  final String? currentUserId;
  const _KtsAssigneePickerSheet({required this.lang, this.currentUserId});

  @override
  State<_KtsAssigneePickerSheet> createState() => _KtsAssigneePickerSheetState();
}

class _KtsAssigneePickerSheetState extends State<_KtsAssigneePickerSheet> {
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

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoadingLocations = true;
  bool _isLoadingUsers = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadLocations();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  Future<void> _loadUsers({String? lokasiId, String? unitId, String? subunitId, String? areaId}) async {
    setState(() => _isLoadingUsers = true);
    try {
      dynamic query = Supabase.instance.client.from('User').select('id_user, nama, jabatan!User_id_jabatan_fkey(nama_jabatan), gambar_user');
      if (areaId != null) query = query.eq('id_area', areaId);
      else if (subunitId != null) query = query.eq('id_subunit', subunitId);
      else if (unitId != null) query = query.eq('id_unit', unitId);
      else if (lokasiId != null) query = query.eq('id_lokasi', lokasiId);

      final data = await query.order('nama');
      List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(data);

      if (widget.currentUserId != null) {
        users.sort((a, b) {
          if (a['id_user'] == widget.currentUserId) return -1;
          if (b['id_user'] == widget.currentUserId) return 1;
          return (a['nama'] as String).compareTo(b['nama'] as String);
        });
      }

      if (mounted) setState(() { _allUsers = users; _filteredUsers = users; _isLoadingUsers = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() { _filteredUsers = _allUsers.where((u) => u['nama'].toString().toLowerCase().contains(q)).toList(); });
  }

  void _applyFilter() => _loadUsers(lokasiId: _selLokasiId, unitId: _selUnitId, subunitId: _selSubunitId, areaId: _selAreaId);

  Widget _buildFilterChips({required String label, required IconData icon, required List<Map<String, dynamic>> items, required String idKey, required String nameKey, required String? selectedId, required Function(String id) onSelect}) {
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
                  boxShadow: isSelected ? [BoxShadow(color: _kPrimary.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
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
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(CupertinoIcons.person_2_fill, color: _kPrimary, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.lang == 'ZH' ? '选择负责人' : widget.lang == 'EN' ? 'Select Person in Charge' : 'Pilih Penanggung Jawab', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
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
                  const Icon(CupertinoIcons.location, size: 14, color: _kPrimary),
                  const SizedBox(width: 6),
                  Text(widget.lang == 'EN' ? 'Filter Location' : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  const Spacer(),
                  if (_selLokasiId != null)
                    GestureDetector(
                      onTap: () {
                        setState(() { _selLokasiId = null; _selUnitId = null; _selSubunitId = null; _selAreaId = null; _unitList = []; _subunitList = []; _areaList = []; });
                        _loadUsers();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kPrimary.withOpacity(0.3))),
                        child: Text(widget.lang == 'EN' ? 'Reset' : 'Reset', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                _isLoadingLocations
                    ? const CupertinoActivityIndicator()
                    : _buildFilterChips(
                        label: widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi',
                        icon: CupertinoIcons.building_2_fill,
                        items: _lokasiList,
                        idKey: 'id_lokasi', nameKey: 'nama_lokasi',
                        selectedId: _selLokasiId,
                        onSelect: (id) async {
                          final units = await _fetchUnit(id);
                          setState(() { _selLokasiId = id; _selUnitId = null; _selSubunitId = null; _selAreaId = null; _unitList = units; _subunitList = []; _areaList = []; });
                          _applyFilter();
                        },
                      ),
                if (_selLokasiId != null && _unitList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFilterChips(label: 'Unit', icon: CupertinoIcons.squares_below_rectangle, items: _unitList, idKey: 'id_unit', nameKey: 'nama_unit', selectedId: _selUnitId, onSelect: (id) async {
                    final subs = await _fetchSubunit(id);
                    setState(() { _selUnitId = id; _selSubunitId = null; _selAreaId = null; _subunitList = subs; _areaList = []; });
                    _applyFilter();
                  }),
                ],
                if (_selUnitId != null && _subunitList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFilterChips(label: 'Sub-Unit', icon: CupertinoIcons.layers_alt_fill, items: _subunitList, idKey: 'id_subunit', nameKey: 'nama_subunit', selectedId: _selSubunitId, onSelect: (id) async {
                    final areas = await _fetchArea(id);
                    setState(() { _selSubunitId = id; _selAreaId = null; _areaList = areas; });
                    _applyFilter();
                  }),
                ],
                if (_selSubunitId != null && _areaList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFilterChips(label: 'Area', icon: CupertinoIcons.location_fill, items: _areaList, idKey: 'id_area', nameKey: 'nama_area', selectedId: _selAreaId, onSelect: (id) { setState(() => _selAreaId = id); _applyFilter(); }),
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
                hintText: widget.lang == 'ZH' ? '搜索成员...' : widget.lang == 'EN' ? 'Search member...' : 'Cari anggota...',
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
              const Icon(CupertinoIcons.person_2, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text('${_filteredUsers.length} ${widget.lang == 'EN' ? 'members' : 'anggota'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            ]),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 12),
          Expanded(
            child: _isLoadingUsers
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredUsers.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(CupertinoIcons.person_crop_circle_badge_xmark, size: 48, color: Color(0xFFE2E8F0)), const SizedBox(height: 12), Text(widget.lang == 'EN' ? 'No users found' : 'Tidak ada pengguna', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14))]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (_, i) {
                          final user = _filteredUsers[i];
                          final isMe = user['id_user'] == widget.currentUserId;
                          final String name = user['nama'] ?? '';
                          final String role = user['jabatan']?['nama_jabatan'] ?? '';
                          final String? avatarUrl = user['gambar_user'];
                          final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(context, user),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isMe ? _kPrimaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isMe ? _kPrimary.withOpacity(0.25) : const Color(0xFFF1F5F9)),
                                ),
                                child: Row(children: [
                                  Stack(children: [
                                    CircleAvatar(radius: 22, backgroundColor: _kPrimaryLight, backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null, child: avatarUrl == null ? Text(initial, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold)) : null),
                                    if (isMe)
                                      Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 10))),
                                  ]),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B)))),
                                        if (isMe)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                                            child: Text(widget.lang == 'EN' ? 'Me' : 'Saya', style: GoogleFonts.inter(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w700)),
                                          ),
                                      ]),
                                      if (role.isNotEmpty) Text(role, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                                    ],
                                  )),
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