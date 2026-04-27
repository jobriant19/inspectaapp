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
            subkategoritemuan:id_subkategoritemuan_uuid(
              id_subkategoritemuan, nama_subkategoritemuan
            ),
            item_produksi:id_item(id_item, nama_item, gambar_item),
            lokasi:id_lokasi(nama_lokasi)
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

  Future<void> _deleteReport(int id) async {
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
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
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
          .from('temuan')
          .delete()
          .eq('id_temuan', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['deleted']!),
            backgroundColor: CupertinoColors.activeGreen));
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
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF2563EB)),
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
            icon: const Icon(CupertinoIcons.refresh, color: Color(0xFF2563EB)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _fetchReports,
              color: const Color(0xFFFBBF24),
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
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KtsProduksiFormScreen(lang: widget.lang),
          ),
        );
        if (result == true) _fetchReports();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFBBF24).withOpacity(0.4),
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
              child: const Icon(CupertinoIcons.hammer_fill,
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
                        ? '记录生产质量问题'
                        : widget.lang == 'EN'
                            ? 'Record production quality issues'
                            : 'Catat masalah kualitas produksi',
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
    final status = r['status_temuan'] ?? 'Belum';
    final isResolved = status == 'Closed' || status == 'Teratasi' || status == 'Selesai';
    final statusColor = isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg = isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6);
    final statusIcon = isResolved
        ? CupertinoIcons.check_mark_circled_solid
        : CupertinoIcons.clock_solid;
    final statusText = isResolved ? t['resolved']! : t['unresolved']!;

    final itemName = r['item_produksi']?['nama_item'] ?? r['nama_item_manual'] ?? '-';
    final subKategori = r['subkategoritemuan']?['nama_subkategoritemuan'] ?? '-';
    final dateStr = r['created_at'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(r['created_at']))
        : '-';
    final imageUrl = r['item_produksi']?['gambar_item'] ?? r['gambar_temuan'];
    final isOwner = r['id_user'] == _currentUserId;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KtsProduksiDetailScreen(
              ktsId: r['id_temuan'] as int,
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
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.08),
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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: imageUrl != null
                          ? Image.network(imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildItemIcon())
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
                            Expanded(
                              child: Text(r['judul_temuan'] ?? '-',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: const Color(0xFF1E293B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 11, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(statusText,
                                      style: GoogleFonts.inter(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(itemName,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildChip(
                              CupertinoIcons.tag,
                              '${t['order']}: ${r['no_order'] ?? '-'}',
                              const Color(0xFFFEF9C3),
                              const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            _buildChip(
                              CupertinoIcons.cube_box,
                              '${r['jumlah_item'] ?? 0} pcs',
                              const Color(0xFFF0FDF4),
                              const Color(0xFF22C55E),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.folder_fill,
                            size: 12, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(subKategori,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.calendar,
                          size: 12, color: Color.fromARGB(255, 6, 7, 7)),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color.fromARGB(255, 19, 20, 22), fontWeight: FontWeight.w600)),
                    ],
                  ),
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
                            builder: (_) => KtsProduksiFormScreen(
                              lang: widget.lang,
                              existingData: r,
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
                      onTap: () => _deleteReport(r['id_temuan']),
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
          border: Border.all(
              color: color.withOpacity(0.25), width: 1),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _buildItemIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(CupertinoIcons.hammer_fill,
          color: Color(0xFFD97706), size: 28),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.doc_text_search,
                size: 52, color: Color(0xFFD97706)),
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
      baseColor: const Color(0xFFFEF3C7),
      highlightColor: const Color(0xFFFFFBEB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer create button
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 28),
            // Shimmer history label
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 14),
            // Shimmer cards
            ...List.generate(3, (_) => Container(
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
// LAYAR FORM KTS PRODUKSI (CREATE & EDIT)
// ============================================================
class KtsProduksiFormScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? existingData;

  const KtsProduksiFormScreen(
      {super.key, required this.lang, this.existingData});

  @override
  State<KtsProduksiFormScreen> createState() =>
      _KtsProduksiFormScreenState();
}

class _KtsProduksiFormScreenState
    extends State<KtsProduksiFormScreen> {
  bool get _isEdit => widget.existingData != null;
  bool _isSaving = false;

  final _noOrderCtrl = TextEditingController();
  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _itemSearchCtrl = TextEditingController();

  int _qty = 1;

  Map<String, dynamic>? _selectedSubKategori;
  Map<String, dynamic>? _selectedItem;
  XFile? _imageFile;
  String? _existingImageUrl;
  List<Map<String, dynamic>> _itemSuggestions = [];
  bool _isSearchingItems = false;
  bool _showSuggestions = false;
  String? _ktsKategoriId;
  bool _isLoadingKategori = false;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'create_title': 'Buat Laporan',
      'edit_title': 'Edit Laporan',
      'no_order': 'No. Order',
      'no_order_hint': 'Masukkan nomor order...',
      'judul': 'Judul KTS',
      'judul_hint': 'Contoh: Part tidak sesuai',
      'kategori': 'Kategori KTS',
      'pick_kategori': 'Pilih Kategori',
      'item': 'Item Produksi',
      'item_hint': 'Cari item...',
      'qty': 'Jumlah',
      'photo': 'Foto Bukti',
      'add_photo': 'Tambah Foto',
      'desc': 'Deskripsi (Opsional)',
      'desc_hint': 'Jelaskan temuan secara detail...',
      'submit': 'Simpan Laporan',
      'update': 'Perbarui Laporan',
      'err_order': 'No. Order wajib diisi!',
      'err_judul': 'Judul wajib diisi!',
      'err_kategori': 'Kategori wajib dipilih!',
      'err_item': 'Item produksi wajib diisi!',
      'success': 'Laporan berhasil disimpan! +20 poin',
      'success_edit': 'Laporan berhasil diperbarui!',
      'fail': 'Gagal menyimpan laporan',
      'saving': 'Menyimpan...',
      'cancel': 'Batal',
    },
    'EN': {
      'create_title': 'Create Report',
      'edit_title': 'Edit Report',
      'no_order': 'Order No.',
      'no_order_hint': 'Enter order number...',
      'judul': 'KTS Title',
      'judul_hint': 'Example: Part mismatch',
      'kategori': 'Category',
      'pick_kategori': 'Select Category',
      'item': 'Production Item',
      'item_hint': 'Search item...',
      'qty': 'Qty',
      'photo': 'Evidence Photo',
      'add_photo': 'Add Photo',
      'desc': 'Description (Optional)',
      'desc_hint': 'Explain the finding...',
      'submit': 'Save Report',
      'update': 'Update Report',
      'err_order': 'Order No. is required!',
      'err_judul': 'Title is required!',
      'err_kategori': 'Category is required!',
      'err_item': 'Production item is required!',
      'success': 'Report saved! +20 points',
      'success_edit': 'Report updated!',
      'fail': 'Failed to save report',
      'saving': 'Saving...',
      'cancel': 'Cancel',
    },
    'ZH': {
      'create_title': '创建报告',
      'edit_title': '编辑报告',
      'no_order': '订单号',
      'no_order_hint': '输入订单号...',
      'judul': '标题',
      'judul_hint': '例如：零件不符',
      'kategori': '类别',
      'pick_kategori': '选择类别',
      'item': '生产项目',
      'item_hint': '搜索项目...',
      'qty': '数量',
      'photo': '证据照片',
      'add_photo': '添加照片',
      'desc': '描述（可选）',
      'desc_hint': '详细说明...',
      'submit': '保存报告',
      'update': '更新报告',
      'err_order': '订单号为必填项！',
      'err_judul': '标题为必填项！',
      'err_kategori': '类别为必选项！',
      'err_item': '生产项目为必填项！',
      'success': '报告已保存！+20积分',
      'success_edit': '报告已更新！',
      'fail': '保存报告失败',
      'saving': '保存中...',
      'cancel': '取消',
    },
  };

  @override
  void initState() {
    super.initState();
    _itemSearchCtrl.addListener(_onItemSearchChanged);
    _loadKtsKategoriId();
    if (_isEdit) _populateData();
  }

  Future<void> _loadKtsKategoriId() async {
    if (_isLoadingKategori || _ktsKategoriId != null) return;
    setState(() => _isLoadingKategori = true);
    try {
      final allData = await Supabase.instance.client
          .from('kategoritemuan')
          .select('id_kategoritemuan, nama_kategoritemuan');

      Map<String, dynamic>? ktsData;
      for (final item in allData) {
        final nama =
            item['nama_kategoritemuan'].toString().toLowerCase().trim();
        if (nama.contains('kts')) {
          ktsData = item;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _ktsKategoriId =
              ktsData?['id_kategoritemuan']?.toString();
          if (_ktsKategoriId == null &&
              _isEdit &&
              widget.existingData!['kategoritemuan'] != null) {
            _ktsKategoriId = widget.existingData!['kategoritemuan']
                ['id_kategoritemuan'];
          }
          _isLoadingKategori = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading KTS kategori id: $e');
      if (mounted) setState(() => _isLoadingKategori = false);
    }
  }

  void _showSubKategoriPicker() async {
    if (_isLoadingKategori) return;

    if (_ktsKategoriId == null) {
      await _loadKtsKategoriId();
      if (_ktsKategoriId == null) return;
    }

    try {
      final data = await Supabase.instance.client
          .from('subkategoritemuan')
          .select(
              'id_subkategoritemuan, nama_subkategoritemuan, deskripsi_subkategoritemuan')
          .eq('id_kategoritemuan', _ktsKategoriId!)
          .order('nama_subkategoritemuan');

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, ctrl) => Column(
            children: [
              Container(
                margin:
                    const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(t['pick_kategori']!,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB))),
                ),
              ),
              const Divider(color: CupertinoColors.systemGrey5),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: data.length,
                  itemBuilder: (_, i) {
                    final sk =
                        Map<String, dynamic>.from(data[i]);
                    final isSelected =
                        _selectedSubKategori?['id_subkategoritemuan'] ==
                            sk['id_subkategoritemuan'];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                      title: Text(
                          sk['nama_subkategoritemuan'],
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 15)),
                      subtitle: sk[
                                  'deskripsi_subkategoritemuan'] !=
                              null
                          ? Text(
                              sk['deskripsi_subkategoritemuan'],
                              style: GoogleFonts.inter(
                                  color: CupertinoColors
                                      .systemGrey,
                                  fontSize: 13))
                          : null,
                      trailing: isSelected
                          ? const Icon(
                              CupertinoIcons.check_mark,
                              color: const Color(0xFF2563EB))
                          : null,
                      onTap: () {
                        setState(
                            () => _selectedSubKategori = sk);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error loading subkategori KTS: $e');
    }
  }

  void _populateData() {
    final d = widget.existingData!;
    _noOrderCtrl.text = d['no_order'] ?? '';
    _judulCtrl.text = d['judul_temuan'] ?? '';
    _descCtrl.text = d['deskripsi_temuan']?.toString() ?? '';
    _qty = d['jumlah_item'] ?? 1;
    _existingImageUrl = d['gambar_temuan'];

    if (d['kategoritemuan'] != null) {
      _ktsKategoriId = d['kategoritemuan']['id_kategoritemuan'];
    }

    if (d['subkategoritemuan'] != null &&
        d['subkategoritemuan'] is Map) {
      _selectedSubKategori =
          Map<String, dynamic>.from(d['subkategoritemuan']);
    }
    if (d['item_produksi'] != null &&
        d['item_produksi'] is Map) {
      _selectedItem =
          Map<String, dynamic>.from(d['item_produksi']);
      _itemSearchCtrl.text = _selectedItem?['nama_item'] ?? '';
    } else if (d['nama_item_manual'] != null) {
      _itemSearchCtrl.text = d['nama_item_manual'];
    }
  }

  @override
  void dispose() {
    _noOrderCtrl.dispose();
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _itemSearchCtrl.dispose();
    super.dispose();
  }

  void _onItemSearchChanged() {
    final q = _itemSearchCtrl.text.trim();

    if (_selectedItem != null &&
        _selectedItem!['nama_item'] != q) {
      _selectedItem = null;
    }

    if (q.isEmpty) {
      setState(() {
        _itemSuggestions = [];
        _showSuggestions = false;
        _selectedItem = null;
      });
      return;
    }

    if (_selectedItem != null &&
        _selectedItem!['nama_item'] == q) return;
    _searchItems(q);
  }

  Future<void> _searchItems(String query) async {
    setState(() => _isSearchingItems = true);
    try {
      final data = await Supabase.instance.client
          .from('item_produksi')
          .select('id_item, nama_item, gambar_item, kode_item')
          .eq('is_active', true)
          .ilike('nama_item', '%$query%')
          .limit(8);
      if (mounted) {
        setState(() {
          _itemSuggestions =
              List<Map<String, dynamic>>.from(data);
          _showSuggestions = true;
          _isSearchingItems = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearchingItems = false);
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
            // Handle bar
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
            // Option: Camera
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final img = await _openKtsCameraScreen();
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
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
                              fontSize: 12, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 16, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
            // Option: Gallery
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
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill,
                          color: Colors.white, size: 22),
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
                              fontSize: 12, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 16, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Cancel
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
                    t['cancel']!,
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

  Future<XFile?> _openKtsCameraScreen() async {
    return await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(builder: (_) => const _KtsCameraScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: CupertinoColors.destructiveRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _submit() async {
    if (_noOrderCtrl.text.trim().isEmpty)
      return _showError(t['err_order']!);
    if (_judulCtrl.text.trim().isEmpty)
      return _showError(t['err_judul']!);
    if (_selectedSubKategori == null)
      return _showError(t['err_kategori']!);
    if (_itemSearchCtrl.text.trim().isEmpty)
      return _showError(t['err_item']!);

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName =
            '${user.id}/kts_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(
            fileName, bytes,
            fileOptions: const FileOptions(
                contentType: 'image/jpeg'));
        imageUrl = supabase.storage
            .from('temuan_images')
            .getPublicUrl(fileName);
      }

      final data = {
        'no_order': _noOrderCtrl.text.trim(),
        'judul_temuan': _judulCtrl.text.trim(),
        'id_subkategoritemuan_uuid':
            _selectedSubKategori!['id_subkategoritemuan'],
        'id_kategoritemuan_uuid': _ktsKategoriId,
        'id_item': _selectedItem?['id_item'],
        'nama_item_manual': _selectedItem == null
            ? _itemSearchCtrl.text.trim()
            : null,
        'jumlah_item': _qty,
        'gambar_temuan': imageUrl,
        'deskripsi_temuan': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'jenis_temuan': 'KTS Production',
        'poin_temuan': 20,
        'status_temuan': 'Belum',
      };

      if (_isEdit) {
        final updateData = Map<String, dynamic>.from(data);
        updateData.remove('jenis_temuan');
        updateData.remove('poin_temuan');
        updateData.remove('status_temuan');

        await supabase
            .from('temuan')
            .update(updateData)
            .eq('id_temuan', widget.existingData!['id_temuan']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t['success_edit']!),
              backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
        }
      } else {
        await supabase.from('temuan').insert({
          ...data,
          'id_user': user.id,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t['success']!),
              backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
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
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF2563EB)),
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
          child: Container(color: CupertinoColors.systemGrey5, height: 1),
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
                _buildSectionCard(children: [
                  _buildLabel(t['no_order']!, isRequired: true),
                  _buildTextField(_noOrderCtrl,
                      t['no_order_hint']!, CupertinoIcons.number),
                  const SizedBox(height: 20),
                  _buildLabel(t['judul']!, isRequired: true),
                  _buildTextField(_judulCtrl, t['judul_hint']!,
                      CupertinoIcons.text_cursor),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['kategori']!, isRequired: true),
                  _buildTapField(
                    icon: CupertinoIcons.folder_fill,
                    text: _selectedSubKategori?[
                            'nama_subkategoritemuan'] ??
                        t['pick_kategori']!,
                    hasValue: _selectedSubKategori != null,
                    onTap: _showSubKategoriPicker,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildLabel(t['item']!,
                                isRequired: true),
                            _buildItemSearchField(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildLabel(t['qty']!,
                                isRequired: true),
                            _buildQtyField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['photo']!, isRequired: false),
                  _buildPhotoWidget(),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['desc']!, isRequired: false),
                  _buildTextField(
                      _descCtrl,
                      t['desc_hint']!,
                      CupertinoIcons.doc_text,
                      maxLines: 4),
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
                border: Border(
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
                      color: const Color(0xFF3B82F6).withOpacity(0.4),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16)),
                  ),
                  child: Text(
                      _isEdit
                          ? t['update']!
                          : t['submit']!,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
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
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
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

  Widget _buildLabel(String label,
      {bool isRequired = false}) {
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

  Widget _buildTextField(TextEditingController ctrl,
      String hint, IconData icon,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: const Color(0xFFCBD5E1), fontSize: 15),
        prefixIcon: maxLines == 1
            ? Icon(icon,
                color: const Color(0xFF2563EB), size: 20)
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

  Widget _buildTapField(
      {required IconData icon,
      required String text,
      required VoidCallback onTap,
      bool hasValue = false}) {
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
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE0E7FF),
              width: hasValue ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: hasValue
                    ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
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
            Icon(CupertinoIcons.chevron_down, color: const Color(0xFF2563EB), size: 18),
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
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFE0E7FF), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_qty > 1) setState(() => _qty--);
              },
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12)),
              child: Center(
                  child: Icon(CupertinoIcons.minus,
                      size: 16,
                      color: _qty > 1 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1))),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFE0E7FF),
          ),
          Expanded(
            child: Center(
              child: Text('$_qty',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB))),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFE0E7FF),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _qty++),
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12)),
              child: const Center(
                  child: Icon(CupertinoIcons.add,
                      size: 16,
                      color: const Color(0xFF2563EB))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _itemSearchCtrl,
          style:
              GoogleFonts.inter(fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            hintText: t['item_hint']!,
            hintStyle: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1), fontSize: 15),
            prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF2563EB), size: 20),
            suffixIcon: _isSearchingItems
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF2563EB))))
                : _selectedItem != null
                    ? IconButton(
                        icon: const Icon(
                            CupertinoIcons.clear_thick,
                            size: 16,
                            color: CupertinoColors.systemGrey),
                        onPressed: () {
                          setState(() {
                            _selectedItem = null;
                            _itemSearchCtrl.clear();
                            _showSuggestions = false;
                          });
                        },
                      )
                    : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
           enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
        if (_showSuggestions && _itemSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E7FF)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: _itemSuggestions.map((item) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item['gambar_item'] != null
                        ? Image.network(item['gambar_item'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildItemPlaceholder())
                        : _buildItemPlaceholder(),
                  ),
                  title: Text(item['nama_item'],
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  subtitle: item['kode_item'] != null
                      ? Text(item['kode_item'],
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedItem = item;
                      _itemSearchCtrl.text =
                          item['nama_item'];
                      _showSuggestions = false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(CupertinoIcons.cube_box,
          color: Color(0xFF2563EB), size: 20),
    );
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
                color: const Color(0xFFE0E7FF),
                width: 1.5,
                style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.camera,
                    color: const Color(0xFF2563EB), size: 28),
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
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon KTS dengan animasi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.hammer_fill,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const CupertinoActivityIndicator(
                radius: 12,
                color: Color(0xFFD97706),
              ),
              const SizedBox(height: 14),
              Text(
                t['saving']!,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B)),
              ),
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
                    fontSize: 13, color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.star_fill,
                          color: Color(0xFFD97706), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'EN'
                            ? 'You will earn +20 points!'
                            : widget.lang == 'ZH'
                                ? '您将获得+20积分！'
                                : 'Anda akan mendapat +20 poin!',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97706)),
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
// LAYAR DETAIL KTS PRODUKSI
// ============================================================
class KtsProduksiDetailScreen extends StatefulWidget {
  final int ktsId;
  final String lang;

  const KtsProduksiDetailScreen(
      {super.key, required this.ktsId, required this.lang});

  @override
  State<KtsProduksiDetailScreen> createState() =>
      _KtsProduksiDetailScreenState();
}

class _KtsProduksiDetailScreenState
    extends State<KtsProduksiDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isSavingResolution = false;
  String? _currentUserId;
  bool _isDataChanged = false;

  final _tindakanCtrl = TextEditingController();
  final _biayaCtrl = TextEditingController();
  XFile? _resImageFile;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Detail KTS Produksi',
      'order': 'No. Order',
      'item': 'Item Produksi',
      'qty': 'Jumlah',
      'kategori': 'Kategori KTS',
      'status': 'Status',
      'reported': 'Dilaporkan',
      'desc': 'Deskripsi',
      'resolution_title': 'Penyelesaian',
      'resolution_done': 'KTS Sudah Teratasi',
      'upload_photo': 'Foto Penyelesaian',
      'tindakan': 'Tindakan',
      'tindakan_hint': 'Jelaskan tindakan...',
      'biaya': 'Biaya (Opsional)',
      'biaya_hint': 'Contoh: 50000',
      'save_resolution': 'Simpan Penyelesaian',
      'err_tindakan': 'Tindakan wajib diisi!',
      'err_photo': 'Foto penyelesaian wajib diunggah!',
      'success_res': 'KTS berhasil diselesaikan! +10 poin',
      'fail_res': 'Gagal menyimpan penyelesaian',
      'resolved': 'Teratasi',
      'unresolved': 'Belum Teratasi',
      'resolved_by': 'Diselesaikan oleh',
      'resolved_at': 'Selesai pada',
      'cost': 'Biaya',
      'edit': 'Edit',
      'evidence_photo': 'Foto Bukti',
      'reported_by': 'Dilaporkan oleh',
      'delete': 'Hapus',
      'delete_confirm': 'Hapus laporan KTS ini?',
      'cancel': 'Batal',
      'deleted': 'Laporan KTS dihapus',
      'kts_badge': 'KTS PRODUKSI',
    },
    'EN': {
      'title': 'KTS Detail',
      'order': 'Order No.',
      'item': 'Production Item',
      'qty': 'Quantity',
      'kategori': 'Category',
      'status': 'Status',
      'reported': 'Reported',
      'desc': 'Description',
      'resolution_title': 'Resolution Form',
      'resolution_done': 'Resolved',
      'upload_photo': 'Resolution Photo',
      'tindakan': 'Action Taken',
      'tindakan_hint': 'Explain action...',
      'biaya': 'Cost (Optional)',
      'biaya_hint': 'Example: 50000',
      'save_resolution': 'Save Resolution',
      'err_tindakan': 'Action description required!',
      'err_photo': 'Resolution photo required!',
      'success_res': 'KTS resolved! +10 points',
      'fail_res': 'Failed to save',
      'resolved': 'Resolved',
      'unresolved': 'Unresolved',
      'resolved_by': 'Resolved by',
      'resolved_at': 'Completed on',
      'cost': 'Cost',
      'edit': 'Edit',
      'evidence_photo': 'Evidence Photo',
      'reported_by': 'Reported by',
      'delete': 'Delete',
      'delete_confirm': 'Delete this report?',
      'cancel': 'Cancel',
      'deleted': 'Report deleted',
      'kts_badge': 'KTS PRODUCTION',
    },
    'ZH': {
      'title': 'KTS详情',
      'order': '订单号',
      'item': '生产项目',
      'qty': '数量',
      'kategori': '类别',
      'status': '状态',
      'reported': '报告时间',
      'desc': '描述',
      'resolution_title': '解决方案',
      'resolution_done': '已解决',
      'upload_photo': '照片',
      'tindakan': '行动',
      'tindakan_hint': '说明行动...',
      'biaya': '费用（可选）',
      'biaya_hint': '例如：50000',
      'save_resolution': '保存方案',
      'err_tindakan': '行动必填！',
      'err_photo': '照片必填！',
      'success_res': '已解决！+10积分',
      'fail_res': '保存失败',
      'resolved': '已解决',
      'unresolved': '未解决',
      'resolved_by': '解决者',
      'resolved_at': '完成时间',
      'cost': '费用',
      'edit': '编辑',
      'evidence_photo': '证据照片',
      'reported_by': '报告人',
      'delete': '删除',
      'delete_confirm': '删除报告？',
      'cancel': '取消',
      'deleted': '已删除',
      'kts_badge': 'KTS生产',
    },
  };

  @override
  void initState() {
    super.initState();
    _currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    _loadData();
  }

  @override
  void dispose() {
    _tindakanCtrl.dispose();
    _biayaCtrl.dispose();
    super.dispose();
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
            subkategoritemuan:id_subkategoritemuan_uuid(
              id_subkategoritemuan,
              nama_subkategoritemuan
            ),
            kategoritemuan:id_kategoritemuan_uuid(
              id_kategoritemuan,
              nama_kategoritemuan
            ),
            item_produksi:id_item(
              id_item, nama_item, gambar_item, kode_item
            ),
            lokasi:id_lokasi(nama_lokasi)
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
              .select(
                  'id_penyelesaian, gambar_penyelesaian, catatan_penyelesaian, tanggal_selesai, poin_penyelesaian, additional_cost, id_user')
              .eq('id_penyelesaian', idPenyelesaian)
              .maybeSingle();
          if (penyelesaianData != null &&
              penyelesaianData['id_user'] != null) {
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
          _data = {
            ...data,
            'pelapor': pelaporData,
            'penyelesaian': penyelesaianData,
          };
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
        title: Text(t['delete_confirm']!,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content:
            const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t['cancel']!,
                style: const TextStyle(
                    color: CupertinoColors.systemBlue)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(t['delete']!),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('temuan')
          .delete()
          .eq('id_temuan', widget.ktsId);
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

  Future<void> _pickResImage() async {
    final img = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
          builder: (_) => const _KtsCameraScreen()),
    );
    if (img != null && mounted)
      setState(() => _resImageFile = img);
  }

  Future<void> _saveResolution() async {
    if (_resImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t['err_photo']!),
          backgroundColor: CupertinoColors.destructiveRed));
      return;
    }
    if (_tindakanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t['err_tindakan']!),
          backgroundColor: CupertinoColors.destructiveRed));
      return;
    }
    setState(() => _isSavingResolution = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final bytes = await _resImageFile!.readAsBytes();
      final fileName =
          '${user.id}/kts_res_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('temuan_images').uploadBinary(
          fileName, bytes,
          fileOptions: const FileOptions(
              contentType: 'image/jpeg'));
      final imageUrl = supabase.storage
          .from('temuan_images')
          .getPublicUrl(fileName);

      final biayaValue = _biayaCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_biayaCtrl.text.trim());

      final insertRes = await supabase
          .from('penyelesaian')
          .insert({
            'gambar_penyelesaian': imageUrl,
            'catatan_penyelesaian': _tindakanCtrl.text.trim(),
            'additional_cost': biayaValue,
            'tanggal_selesai': DateTime.now().toIso8601String(),
            'id_user': user.id,
            'poin_penyelesaian': 10,
          })
          .select('id_penyelesaian')
          .single();

      final newPenyelesaianId =
          insertRes['id_penyelesaian'] as int;

      await supabase.from('temuan').update({
        'status_temuan': 'Selesai',
        'id_penyelesaian': newPenyelesaianId,
      }).eq('id_temuan', widget.ktsId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['success_res']!),
            backgroundColor: CupertinoColors.activeGreen));
        _isDataChanged = true;
        _loadData();
        setState(() => _isSavingResolution = false);
      }
    } catch (e) {
      debugPrint('Resolution error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${t['fail_res']!}: $e'),
            backgroundColor: CupertinoColors.destructiveRed));
        setState(() => _isSavingResolution = false);
      }
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try {
      return DateFormat('dd MMM yyyy, HH:mm')
          .format(DateTime.parse(d).toLocal());
    } catch (_) {
      return d;
    }
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
          actions: _data != null &&
                  _data!['id_user'] == _currentUserId
              ? [
                  _buildAppBarActionButton(
                    icon: CupertinoIcons.pencil_ellipsis_rectangle,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KtsProduksiFormScreen(
                              lang: widget.lang,
                              existingData: _data!),
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer gambar header
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            // Shimmer badge row
            Row(
              children: [
                Container(
                  height: 24,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Shimmer judul
            Container(
              height: 28,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            // Shimmer info card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // item row
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: 140,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 12,
                              width: 80,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // info rows
                  ...List.generate(4, (_) => Column(
                    children: [
                      Container(height: 1, color: const Color(0xFFF1F5F9)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(height: 14, width: 80, color: Colors.white),
                            Container(height: 14, width: 100, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Shimmer resolution section title
            Container(
              height: 20,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            // Shimmer resolution form card
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
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
          border:
              Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final status = d['status_temuan'] ?? 'Open';
    final isResolved =
        status == 'Closed' || status == 'Teratasi';
    final statusColor = isResolved
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final statusBg = isResolved
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFE4E6);
    final statusIcon = isResolved
        ? CupertinoIcons.check_mark_circled_solid
        : CupertinoIcons.clock_solid;
    final statusText =
        isResolved ? t['resolved']! : t['unresolved']!;

    final itemName = d['item_produksi']?['nama_item'] ??
        d['nama_item_manual'] ??
        '-';
    final itemImg = d['item_produksi']?['gambar_item'];
    final itemKode = d['item_produksi']?['kode_item'] ?? '';
    final subKategori =
        d['subkategoritemuan']?['nama_subkategoritemuan'] ?? '-';
    final pelapor = d['pelapor'] as Map<String, dynamic>?;
    final penyelesaian =
        d['penyelesaian'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Header
          if (d['gambar_temuan'] != null)
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
                  d['gambar_temuan'],
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (d['gambar_temuan'] != null)
            const SizedBox(height: 20),

          // Badge
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
                child: Text(t['kts_badge']!,
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon,
                        size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusText,
                        style: GoogleFonts.inter(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(d['judul_temuan'] ?? '-',
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
              border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Item header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(14),
                          child: itemImg != null
                              ? Image.network(itemImg,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover)
                              : _buildItemPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(itemName,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: const Color(
                                        0xFF0F172A))),
                            if (itemKode.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFEFF6FF),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(itemKode,
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(
                                            0xFF6366F1),
                                        fontWeight:
                                            FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(CupertinoIcons.tag,
                    t['order']!, d['no_order'] ?? '-'),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(CupertinoIcons.cube_box,
                    t['qty']!, '${d['jumlah_item'] ?? 0} pcs'),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(CupertinoIcons.folder_fill,
                    t['kategori']!, subKategori),
                Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9)),
                _buildInfoRow(CupertinoIcons.calendar,
                    t['reported']!, _formatDate(d['created_at'])),
                if (pelapor != null) ...[
                  Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.person_fill,
                            color: const Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 12),
                        Text(t['reported_by']!,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF475569))),
                        const Spacer(),
                        Row(
                          children: [
                            Text(pelapor['nama'] ?? '-',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color:
                                        const Color(0xFF0F172A))),
                            const SizedBox(width: 8),
                            pelapor['gambar_user'] != null
                                ? CircleAvatar(
                                    radius: 14,
                                    backgroundImage: NetworkImage(
                                        pelapor['gambar_user']))
                                : Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        CupertinoIcons
                                            .person_fill,
                                        size: 14,
                                        color: const Color(0xFF2563EB)),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Deskripsi
          if (d['deskripsi_temuan'] != null &&
              d['deskripsi_temuan'].toString().isNotEmpty) ...[
            _buildSectionTitle(
                CupertinoIcons.doc_text, t['desc']!),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
              ),
              child: Text(d['deskripsi_temuan'],
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF334155),
                      height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // Penyelesaian
          _buildSectionTitle(
              isResolved
                  ? CupertinoIcons.checkmark_shield_fill
                  : CupertinoIcons.wrench_fill,
              t['resolution_title']!,
              color: isResolved
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706)),
          const SizedBox(height: 10),
          if (isResolved && penyelesaian != null)
            _buildResolutionResult(penyelesaian)
          else if (!isResolved)
            _buildResolutionForm(),

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

  Widget _buildItemPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(CupertinoIcons.cube_box,
          color: Color(0xFF2563EB), size: 28),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value) {
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

  Widget _buildResolutionResult(Map<String, dynamic> p) {
    final solver = p['solver'] as Map<String, dynamic>?;
    final biaya = p['additional_cost'] as num?;
    final biayaStr = biaya != null && biaya > 0
        ? NumberFormat.currency(
                locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
            .format(biaya)
        : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFDCFCE7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['gambar_penyelesaian'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              child: Image.network(p['gambar_penyelesaian'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                          CupertinoIcons
                              .checkmark_seal_fill,
                          color: Color(0xFF16A34A),
                          size: 18),
                      const SizedBox(width: 8),
                      Text(t['resolution_done']!,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF16A34A))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(t['tindakan']!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Text(p['catatan_penyelesaian'] ?? '-',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF0F172A),
                        height: 1.5)),
                if (biaya != null && biaya > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFED7AA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                            CupertinoIcons.money_dollar_circle,
                            color: Color(0xFFEA580C),
                            size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(t['cost']!,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(
                                        0xFF92400E),
                                    fontWeight:
                                        FontWeight.w600)),
                            Text(biayaStr,
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(
                                        0xFFEA580C))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (solver != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        solver['gambar_user'] != null
                            ? CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                    solver['gambar_user']))
                            : Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    CupertinoIcons.person_fill,
                                    size: 20,
                                    color: Color(0xFFD97706)),
                              ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(t['resolved_by']!,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(
                                        0xFF94A3B8),
                                    fontWeight:
                                        FontWeight.w600)),
                            Text(solver['nama'] ?? '-',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: const Color(
                                        0xFF0F172A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (p['tanggal_selesai'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.clock_fill,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                          '${t['resolved_at']}: ${_formatDate(p['tanggal_selesai'])}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t['upload_photo']!,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF475569))),
              const Text(' *',
                  style: TextStyle(
                      color: CupertinoColors.destructiveRed)),
            ],
          ),
          const SizedBox(height: 8),
          _resImageFile == null
              ? GestureDetector(
                  onTap: _pickResImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFDE68A),
                          width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              CupertinoIcons.camera,
                              color: const Color(0xFFD97706),
                              size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text('Ambil Foto',
                            style: GoogleFonts.inter(
                                color:
                                    const Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(
                              _resImageFile!.path,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover)
                          : Image.file(
                              File(_resImageFile!.path),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: _pickResImage,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.black
                                  .withOpacity(0.6),
                              borderRadius:
                                  BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              const Icon(
                                  CupertinoIcons.camera_rotate,
                                  color: Colors.white,
                                  size: 14),
                              const SizedBox(width: 6),
                              Text('Ganti',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(t['tindakan']!,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF475569))),
              const Text(' *',
                  style: TextStyle(
                      color: CupertinoColors.destructiveRed)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tindakanCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: t['tindakan_hint']!,
              hintStyle: GoogleFonts.inter(
                  color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFFDE68A), width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFD97706),
                      width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          Text(t['biaya']!,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          TextFormField(
            controller: _biayaCtrl,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: t['biaya_hint']!,
              prefixText: 'Rp ',
              hintStyle: GoogleFonts.inter(
                  color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFFDE68A), width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFD97706),
                      width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: _isSavingResolution
                    ? null
                    : const LinearGradient(
                        colors: [
                            Color(0xFFFBBF24),
                            Color(0xFFD97706)
                          ]),
                color: _isSavingResolution
                    ? const Color(0xFFE2E8F0)
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isSavingResolution
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFFFBBF24)
                              .withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isSavingResolution
                    ? null
                    : _saveResolution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14)),
                ),
                child: _isSavingResolution
                    ? const CupertinoActivityIndicator(
                        color: Colors.white)
                    : Text(t['save_resolution']!,
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KAMERA KHUSUS KTS PRODUKSI
// ============================================================
class _KtsCameraScreen extends StatefulWidget {
  const _KtsCameraScreen();

  @override
  State<_KtsCameraScreen> createState() =>
      _KtsCameraScreenState();
}

class _KtsCameraScreenState extends State<_KtsCameraScreen>
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('FOTO KTS',
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
                        _ctrl!.value.isTakingPicture) return;
                    try {
                      final pic =
                          await _ctrl!.takePicture();
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