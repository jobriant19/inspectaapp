import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

class _KtsProduksiListScreenState extends State<KtsProduksiListScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

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
          .from('kts_produksi')
          .select('''
            id_kts, no_order, judul_kts, status_kts, poin_kts, created_at,
            jumlah_item, nama_item_manual, gambar_kts,
            kategori_kts(nama_kategori),
            item_produksi(nama_item, gambar_item),
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
      debugPrint('Error fetching KTS: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t['delete_confirm']!,
            style: const TextStyle(
                color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t['delete']!,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client
          .from('kts_produksi')
          .delete()
          .eq('id_kts', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['deleted']!),
            backgroundColor: Colors.green));
        _fetchReports();
      }
    } catch (e) {
      debugPrint('Error deleting KTS: $e');
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
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t['title']!,
            style: GoogleFonts.poppins(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchReports,
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF00C9E4)),
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
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _reports.length,
                    itemBuilder: (_, i) => _buildCard(_reports[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  KtsProduksiFormScreen(lang: widget.lang),
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
    final status = r['status_kts'] ?? 'Belum Teratasi';
    final isResolved = status == 'Teratasi';
    final statusColor =
        isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg =
        isResolved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusIcon = isResolved
        ? Icons.check_circle_rounded
        : Icons.pending_actions_rounded;
    final statusText =
        isResolved ? t['resolved']! : t['unresolved']!;

    final itemName = r['item_produksi']?['nama_item'] ??
        r['nama_item_manual'] ??
        '-';
    final kategori =
        r['kategori_kts']?['nama_kategori'] ?? '-';
    final dateStr = r['created_at'] != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(r['created_at']))
        : '-';
    final imageUrl = r['item_produksi']?['gambar_item'] ??
        r['gambar_kts'];

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KtsProduksiDetailScreen(
              ktsId: r['id_kts'],
              lang: widget.lang,
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
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF1E3A8A).withOpacity(0.05),
                  const Color(0xFFF97316).withOpacity(0.05),
                ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl != null
                        ? Image.network(imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildItemIcon())
                        : _buildItemIcon(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['judul_kts'] ?? '-',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF1E3A8A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(itemName,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon,
                            size: 12, color: statusColor),
                        const SizedBox(width: 3),
                        Text(statusText,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tag,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text('${t['order']}: ${r['no_order'] ?? '-'}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569))),
                      const Spacer(),
                      const Icon(Icons.inventory_2_outlined,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                          '${t['qty']}: ${r['jumlah_item'] ?? 0}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined,
                          size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(kategori,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569))),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFF97316),
                            Color(0xFFEA580C)
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('+${r['poin_kts']} P',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _deleteReport(r['id_kts']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline,
                                size: 13,
                                color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            Text(t['delete']!,
                                style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.factory_outlined,
          color: Colors.orange, size: 24),
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
              color: Colors.orange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.factory_outlined,
                size: 64, color: Colors.orange),
          ),
          const SizedBox(height: 20),
          Text(t['empty_title']!,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          Text(t['empty_sub']!,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13)),
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
          height: 130,
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

  // Controllers
  final _noOrderCtrl = TextEditingController();
  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _itemSearchCtrl = TextEditingController();

  // State
  Map<String, dynamic>? _selectedKategori;
  Map<String, dynamic>? _selectedItem;
  XFile? _imageFile;
  String? _existingImageUrl;
  List<Map<String, dynamic>> _itemSuggestions = [];
  bool _isSearchingItems = false;
  bool _showSuggestions = false;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'create_title': 'Buat Laporan KTS',
      'edit_title': 'Edit Laporan KTS',
      'no_order': 'No. Order',
      'no_order_hint': 'Masukkan nomor order produksi...',
      'judul': 'Judul KTS',
      'judul_hint': 'Contoh: Part tidak sesuai gambar',
      'kategori': 'Kategori KTS',
      'pick_kategori': 'Pilih Kategori KTS',
      'item': 'Item Produksi',
      'item_hint': 'Ketik nama item...',
      'qty': 'Jumlah Item',
      'photo': 'Foto Bukti',
      'add_photo': 'Tambah Foto',
      'desc': 'Deskripsi (Opsional)',
      'desc_hint': 'Jelaskan detail temuan...',
      'submit': 'Simpan Laporan KTS',
      'update': 'Perbarui Laporan',
      'err_order': 'No. Order wajib diisi!',
      'err_judul': 'Judul wajib diisi!',
      'err_kategori': 'Kategori wajib dipilih!',
      'err_item': 'Item produksi wajib diisi!',
      'success': 'Laporan KTS berhasil disimpan! +20 poin',
      'success_edit': 'Laporan KTS berhasil diperbarui!',
      'fail': 'Gagal menyimpan laporan KTS',
      'saving': 'Menyimpan laporan KTS...',
    },
    'EN': {
      'create_title': 'Create KTS Report',
      'edit_title': 'Edit KTS Report',
      'no_order': 'Order No.',
      'no_order_hint': 'Enter production order number...',
      'judul': 'KTS Title',
      'judul_hint': 'Example: Part does not match drawing',
      'kategori': 'KTS Category',
      'pick_kategori': 'Select KTS Category',
      'item': 'Production Item',
      'item_hint': 'Type item name...',
      'qty': 'Item Quantity',
      'photo': 'Evidence Photo',
      'add_photo': 'Add Photo',
      'desc': 'Description (Optional)',
      'desc_hint': 'Explain the finding in detail...',
      'submit': 'Save KTS Report',
      'update': 'Update Report',
      'err_order': 'Order No. is required!',
      'err_judul': 'Title is required!',
      'err_kategori': 'Category is required!',
      'err_item': 'Production item is required!',
      'success': 'KTS report saved! +20 points',
      'success_edit': 'KTS report updated!',
      'fail': 'Failed to save KTS report',
      'saving': 'Saving KTS report...',
    },
    'ZH': {
      'create_title': '创建KTS报告',
      'edit_title': '编辑KTS报告',
      'no_order': '订单号',
      'no_order_hint': '输入生产订单号...',
      'judul': 'KTS标题',
      'judul_hint': '例如：零件与图纸不符',
      'kategori': 'KTS类别',
      'pick_kategori': '选择KTS类别',
      'item': '生产项目',
      'item_hint': '输入项目名称...',
      'qty': '数量',
      'photo': '证据照片',
      'add_photo': '添加照片',
      'desc': '描述（可选）',
      'desc_hint': '详细说明发现...',
      'submit': '保存KTS报告',
      'update': '更新报告',
      'err_order': '订单号为必填项！',
      'err_judul': '标题为必填项！',
      'err_kategori': '类别为必选项！',
      'err_item': '生产项目为必填项！',
      'success': 'KTS报告已保存！+20积分',
      'success_edit': 'KTS报告已更新！',
      'fail': '保存KTS报告失败',
      'saving': '正在保存KTS报告...',
    },
  };

  @override
  void initState() {
    super.initState();
    _itemSearchCtrl.addListener(_onItemSearchChanged);
    if (_isEdit) _populateData();
  }

  void _populateData() {
    final d = widget.existingData!;
    _noOrderCtrl.text = d['no_order'] ?? '';
    _judulCtrl.text = d['judul_kts'] ?? '';
    _descCtrl.text = d['deskripsi'] ?? '';
    _qtyCtrl.text = (d['jumlah_item'] ?? 1).toString();
    _existingImageUrl = d['gambar_kts'];
    if (d['item_produksi'] != null) {
      _selectedItem = d['item_produksi'];
      _itemSearchCtrl.text =
          d['item_produksi']['nama_item'] ?? '';
    } else if (d['nama_item_manual'] != null) {
      _itemSearchCtrl.text = d['nama_item_manual'];
    }
  }

  @override
  void dispose() {
    _noOrderCtrl.dispose();
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _itemSearchCtrl.dispose();
    super.dispose();
  }

  // ── Pencarian item real-time ──
  void _onItemSearchChanged() {
    final q = _itemSearchCtrl.text.trim();
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.orange),
              ),
              title: Text(
                widget.lang == 'EN' ? 'Camera' : 'Kamera',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final img = await _openKtsCameraScreen();
                if (img != null && mounted)
                  setState(() => _imageFile = img);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library,
                    color: Color(0xFF1E3A8A)),
              ),
              title: Text(
                widget.lang == 'EN' ? 'Gallery' : 'Galeri',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80);
                if (img != null && mounted)
                  setState(() => _imageFile = img);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<XFile?> _openKtsCameraScreen() async {
    return await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
          builder: (_) => const _KtsCameraScreen()),
    );
  }

  void _showKategoriPicker() async {
    try {
      final data = await Supabase.instance.client
          .from('kategori_kts')
          .select('id_kategori, nama_kategori, deskripsi')
          .order('nama_kategori');
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, ctrl) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(t['pick_kategori']!,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A))),
              ),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.length,
                  itemBuilder: (_, i) {
                    final k =
                        Map<String, dynamic>.from(data[i]);
                    final isSelected = _selectedKategori?[
                            'id_kategori'] ==
                        k['id_kategori'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedKategori = k);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.withOpacity(0.08)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(k['nama_kategori'],
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isSelected
                                        ? Colors.orange
                                        : const Color(
                                            0xFF1E3A8A))),
                            if (k['deskripsi'] != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 3),
                                child: Text(k['deskripsi'],
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Colors.grey.shade600)),
                              ),
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
    } catch (e) {
      debugPrint('Error loading kategori: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _submit() async {
    // Validasi
    if (_noOrderCtrl.text.trim().isEmpty) {
      _showError(t['err_order']!);
      return;
    }
    if (_judulCtrl.text.trim().isEmpty) {
      _showError(t['err_judul']!);
      return;
    }
    if (_selectedKategori == null) {
      _showError(t['err_kategori']!);
      return;
    }
    if (_itemSearchCtrl.text.trim().isEmpty) {
      _showError(t['err_item']!);
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
            '${user.id}/kts_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(
              fileName, bytes,
              fileOptions:
                  const FileOptions(contentType: 'image/jpeg'));
        imageUrl = supabase.storage
            .from('temuan_images')
            .getPublicUrl(fileName);
      }

      final qty =
          int.tryParse(_qtyCtrl.text.trim()) ?? 1;

      final data = {
        'no_order': _noOrderCtrl.text.trim(),
        'judul_kts': _judulCtrl.text.trim(),
        'id_kategori': _selectedKategori!['id_kategori'],
        'id_item': _selectedItem?['id_item'],
        'nama_item_manual': _selectedItem == null
            ? _itemSearchCtrl.text.trim()
            : null,
        'jumlah_item': qty,
        'gambar_kts': imageUrl,
        'deskripsi': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      };

      if (_isEdit) {
        await supabase.from('kts_produksi').update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_kts', widget.existingData!['id_kts']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t['success_edit']!),
              backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        await supabase.from('kts_produksi').insert({
          ...data,
          'id_pelapor': user.id,
          'poin_kts': 20,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t['success']!),
              backgroundColor: Colors.green));
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
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E3A8A)),
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
          child:
              Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No. Order
                _buildLabel(t['no_order']!, isRequired: true),
                _buildTextField(_noOrderCtrl, t['no_order_hint']!,
                    Icons.tag_rounded),
                const SizedBox(height: 16),

                // Judul KTS
                _buildLabel(t['judul']!, isRequired: true),
                _buildTextField(_judulCtrl, t['judul_hint']!,
                    Icons.title_rounded),
                const SizedBox(height: 16),

                // Kategori
                _buildLabel(t['kategori']!, isRequired: true),
                _buildTapField(
                  icon: Icons.category_outlined,
                  text: _selectedKategori?['nama_kategori'] ??
                      t['pick_kategori']!,
                  hasValue: _selectedKategori != null,
                  accentColor: Colors.orange,
                  onTap: _showKategoriPicker,
                ),
                const SizedBox(height: 16),

                // Item Produksi dengan autocomplete
                _buildLabel(t['item']!, isRequired: true),
                _buildItemSearchField(),
                const SizedBox(height: 16),

                // Jumlah Item
                _buildLabel(t['qty']!, isRequired: true),
                _buildTextField(
                    _qtyCtrl, '1', Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),

                // Foto
                _buildLabel(t['photo']!, isRequired: false),
                _buildPhotoWidget(),
                const SizedBox(height: 16),

                // Deskripsi
                _buildLabel(t['desc']!, isRequired: false),
                _buildTextField(_descCtrl, t['desc_hint']!,
                    Icons.notes_outlined,
                    maxLines: 3),
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
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
              ),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shadowColor:
                      Colors.orange.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isEdit ? t['update']! : t['submit']!,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Widget Builders ──
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
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon:
            Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.orange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildTapField({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool hasValue = false,
    Color accentColor = const Color(0xFF00C9E4),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? accentColor.withOpacity(0.5)
                : Colors.grey.shade200,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: hasValue
                    ? accentColor
                    : const Color(0xFF1E3A8A),
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      color: hasValue
                          ? Colors.black87
                          : Colors.grey.shade400,
                      fontWeight: hasValue
                          ? FontWeight.w500
                          : FontWeight.normal)),
            ),
            Icon(Icons.arrow_drop_down,
                color: hasValue
                    ? accentColor
                    : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _itemSearchCtrl,
          decoration: InputDecoration(
            hintText: t['item_hint']!,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: const Icon(Icons.search,
                color: Color(0xFF1E3A8A), size: 20),
            suffixIcon: _isSearchingItems
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange)),
                  )
                : _selectedItem != null
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.grey),
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
            fillColor: _selectedItem != null
                ? Colors.orange.withOpacity(0.05)
                : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _selectedItem != null
                      ? Colors.orange.withOpacity(0.5)
                      : Colors.grey.shade200,
                  width: _selectedItem != null ? 1.5 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.orange, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
        // Suggestions dropdown
        if (_showSuggestions && _itemSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: _itemSuggestions.map((item) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedItem = item;
                      _itemSearchCtrl.text =
                          item['nama_item'];
                      _showSuggestions = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Gambar item (jika ada)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: item['gambar_item'] != null
                              ? Image.network(
                                  item['gambar_item'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildItemPlaceholder(),
                                )
                              : _buildItemPlaceholder(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(item['nama_item'],
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 13)),
                              if (item['kode_item'] != null)
                                Text(item['kode_item'],
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_circle_outline,
                            color: Colors.orange, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        // Jika tidak ada di database, teks saran
        if (_showSuggestions &&
            _itemSuggestions.isEmpty &&
            !_isSearchingItems)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.lang == 'EN'
                        ? 'Item not found in database. Will be saved as custom item.'
                        : 'Item tidak ditemukan di database. Akan disimpan sebagai item manual.',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.orange.withOpacity(0.1),
      child: const Icon(Icons.precision_manufacturing,
          color: Colors.orange, size: 20),
    );
  }

  Widget _buildPhotoWidget() {
    final hasPhoto =
        _imageFile != null || _existingImageUrl != null;
    if (!hasPhoto) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.orange.withOpacity(0.4),
                width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Colors.orange, size: 28),
              ),
              const SizedBox(height: 8),
              Text(t['add_photo']!,
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600)),
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
          right: 8,
          bottom: 8,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    widget.lang == 'EN' ? 'Retake' : 'Ganti',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
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
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin:
              const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 8),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.7, end: 1.15),
                      duration:
                          const Duration(milliseconds: 1000),
                      builder: (_, v, __) => Transform.scale(
                        scale: v,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange
                                .withOpacity(0.08),
                          ),
                        ),
                      ),
                    ),
                    const CircularProgressIndicator(
                        color: Colors.orange, strokeWidth: 3),
                    const Icon(Icons.factory_outlined,
                        color: Colors.orange, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(t['saving']!,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A)),
                  textAlign: TextAlign.center),
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

  // Resolusi
  final _tindakanCtrl = TextEditingController();
  final _biayaCtrl = TextEditingController();
  XFile? _resImageFile;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Detail KTS Produksi',
      'order': 'No. Order',
      'item': 'Item',
      'qty': 'Jumlah',
      'kategori': 'Kategori',
      'status': 'Status',
      'reported': 'Dilaporkan',
      'desc': 'Deskripsi',
      'resolution_title': 'Penyelesaian',
      'resolution_done': 'Sudah Teratasi',
      'upload_photo': 'Upload Foto Penyelesaian',
      'tindakan': 'Keterangan Tindakan',
      'tindakan_hint': 'Jelaskan tindakan yang dilakukan...',
      'biaya': 'Biaya Penyelesaian (Opsional)',
      'biaya_hint': 'Contoh: 50000',
      'save_resolution': 'Simpan Penyelesaian',
      'err_tindakan': 'Keterangan tindakan wajib diisi!',
      'err_photo': 'Foto penyelesaian wajib diunggah!',
      'success_res': 'KTS berhasil diselesaikan!',
      'fail_res': 'Gagal menyimpan penyelesaian',
      'resolved': 'Teratasi',
      'unresolved': 'Belum Teratasi',
      'resolved_by': 'Diselesaikan oleh',
      'resolved_at': 'Selesai pada',
      'cost': 'Biaya',
      'edit': 'Edit',
    },
    'EN': {
      'title': 'Production KTS Detail',
      'order': 'Order No.',
      'item': 'Item',
      'qty': 'Quantity',
      'kategori': 'Category',
      'status': 'Status',
      'reported': 'Reported',
      'desc': 'Description',
      'resolution_title': 'Resolution',
      'resolution_done': 'Already Resolved',
      'upload_photo': 'Upload Resolution Photo',
      'tindakan': 'Action Taken',
      'tindakan_hint': 'Explain the action taken...',
      'biaya': 'Cost (Optional)',
      'biaya_hint': 'Example: 50000',
      'save_resolution': 'Save Resolution',
      'err_tindakan': 'Action description is required!',
      'err_photo': 'Resolution photo is required!',
      'success_res': 'KTS resolved successfully!',
      'fail_res': 'Failed to save resolution',
      'resolved': 'Resolved',
      'unresolved': 'Unresolved',
      'resolved_by': 'Resolved by',
      'resolved_at': 'Completed on',
      'cost': 'Cost',
      'edit': 'Edit',
    },
    'ZH': {
      'title': '生产KTS详情',
      'order': '订单号',
      'item': '项目',
      'qty': '数量',
      'kategori': '类别',
      'status': '状态',
      'reported': '报告时间',
      'desc': '描述',
      'resolution_title': '解决方案',
      'resolution_done': '已解决',
      'upload_photo': '上传解决方案照片',
      'tindakan': '采取的行动',
      'tindakan_hint': '说明采取的行动...',
      'biaya': '费用（可选）',
      'biaya_hint': '例如：50000',
      'save_resolution': '保存解决方案',
      'err_tindakan': '行动描述为必填项！',
      'err_photo': '解决方案照片为必填项！',
      'success_res': 'KTS已成功解决！',
      'fail_res': '保存解决方案失败',
      'resolved': '已解决',
      'unresolved': '未解决',
      'resolved_by': '解决者',
      'resolved_at': '完成时间',
      'cost': '费用',
      'edit': '编辑',
    },
  };

  @override
  void initState() {
    super.initState();
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
          .from('kts_produksi')
          .select('''
            *,
            kategori_kts(nama_kategori),
            item_produksi(nama_item, gambar_item, kode_item),
            lokasi(nama_lokasi),
            User_Pelapor:id_pelapor(nama, gambar_user),
            penyelesaian_kts(
              id_penyelesaian, gambar_penyelesaian,
              keterangan_tindakan, biaya_penyelesaian, tanggal_selesai,
              User_Solver:id_user(nama, gambar_user)
            )
          ''')
          .eq('id_kts', widget.ktsId)
          .single();
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      debugPrint('Error loading KTS detail: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickResImage() async {
    final img = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(builder: (_) => const _KtsCameraScreen()),
    );
    if (img != null && mounted) setState(() => _resImageFile = img);
  }

  Future<void> _saveResolution() async {
    if (_resImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t['err_photo']!),
          backgroundColor: Colors.red));
      return;
    }
    if (_tindakanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t['err_tindakan']!),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSavingResolution = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Upload foto
      final bytes = await _resImageFile!.readAsBytes();
      final fileName =
          '${user.id}/kts_res_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('temuan_images').uploadBinary(
            fileName, bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg'));
      final imageUrl =
          supabase.storage.from('temuan_images').getPublicUrl(fileName);

      // Insert penyelesaian
      await supabase.from('penyelesaian_kts').insert({
        'id_kts': widget.ktsId,
        'id_user': user.id,
        'gambar_penyelesaian': imageUrl,
        'keterangan_tindakan': _tindakanCtrl.text.trim(),
        'biaya_penyelesaian': _biayaCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_biayaCtrl.text.trim()),
        'tanggal_selesai': DateTime.now().toIso8601String(),
      });

      // Update status KTS
      await supabase
          .from('kts_produksi')
          .update({'status_kts': 'Teratasi'})
          .eq('id_kts', widget.ktsId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['success_res']!),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Resolution error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${t['fail_res']!}: $e'),
            backgroundColor: Colors.red));
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F8FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(t['title']!,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1E3A8A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, __) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );
    }

    if (_data == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t['title']!),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context)),
        ),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final d = _data!;
    final status = d['status_kts'] ?? 'Belum Teratasi';
    final isResolved = status == 'Teratasi';
    final statusColor =
        isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg =
        isResolved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusIcon = isResolved
        ? Icons.check_circle_rounded
        : Icons.pending_actions_rounded;
    final statusText =
        isResolved ? t['resolved']! : t['unresolved']!;

    final itemName = d['item_produksi']?['nama_item'] ??
        d['nama_item_manual'] ??
        '-';
    final itemImg = d['item_produksi']?['gambar_item'];
    final kategori =
        d['kategori_kts']?['nama_kategori'] ?? '-';
    final pelapor =
        d['User_Pelapor'] as Map<String, dynamic>?;
    final penyelesaianList =
        d['penyelesaian_kts'] as List<dynamic>?;
    final penyelesaian = (penyelesaianList != null &&
            penyelesaianList.isNotEmpty)
        ? Map<String, dynamic>.from(penyelesaianList.first)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: CustomScrollView(
        slivers: [
          // App bar dengan gambar
          SliverAppBar(
            pinned: true,
            expandedHeight: itemImg != null ? 220 : 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Color(0xFF1E3A8A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(t['title']!,
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            centerTitle: true,
            actions: [
              // Tombol Edit
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: Color(0xFF1E3A8A)),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KtsProduksiFormScreen(
                        lang: widget.lang,
                        existingData: d,
                      ),
                    ),
                  );
                  if (result == true) _loadData();
                },
              ),
            ],
            flexibleSpace: itemImg != null
                ? FlexibleSpaceBar(
                    background: Image.network(itemImg,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade100)),
                  )
                : null,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul & Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(d['judul_kts'] ?? '-',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A8A))),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(statusText,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info Card
                  _buildInfoCard(d, itemName, kategori,
                      pelapor, isResolved),
                  const SizedBox(height: 20),

                  // Deskripsi
                  if (d['deskripsi'] != null &&
                      d['deskripsi'].toString().isNotEmpty) ...[
                    _buildSectionTitle(t['desc']!,
                        Icons.notes_outlined),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(d['deskripsi'],
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5)),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Foto KTS
                  if (d['gambar_kts'] != null) ...[
                    _buildSectionTitle(
                        widget.lang == 'EN' ? 'Evidence Photo' : 'Foto Bukti',
                        Icons.photo_camera_outlined),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(d['gambar_kts'],
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── SECTION PENYELESAIAN ──
                  _buildSectionTitle(
                      t['resolution_title']!,
                      isResolved
                          ? Icons.check_circle_outline
                          : Icons.build_outlined),
                  const SizedBox(height: 12),

                  if (isResolved && penyelesaian != null)
                    // Tampilkan hasil penyelesaian
                    _buildResolutionResult(penyelesaian)
                  else if (!isResolved)
                    // Form input penyelesaian
                    _buildResolutionForm(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.orange, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E3A8A))),
      ],
    );
  }

  Widget _buildInfoCard(
      Map<String, dynamic> d,
      String itemName,
      String kategori,
      Map<String, dynamic>? pelapor,
      bool isResolved) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow2(Icons.tag, t['order']!,
              d['no_order'] ?? '-', Colors.blue),
          const Divider(height: 20),
          _buildInfoRow2(Icons.precision_manufacturing_outlined,
              t['item']!, itemName, Colors.orange),
          const Divider(height: 20),
          _buildInfoRow2(Icons.inventory_2_outlined, t['qty']!,
              '${d['jumlah_item'] ?? 0} pcs', Colors.purple),
          const Divider(height: 20),
          _buildInfoRow2(Icons.category_outlined, t['kategori']!,
              kategori, Colors.teal),
          const Divider(height: 20),
          _buildInfoRow2(Icons.calendar_today_outlined,
              t['reported']!, _formatDate(d['created_at']),
              Colors.grey),
          // Pelapor
          if (pelapor != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Color(0xFF1E3A8A), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lang == 'EN'
                            ? 'Reported by'
                            : 'Dilaporkan oleh',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500),
                      ),
                      Text(pelapor['nama'] ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
                if (pelapor['gambar_user'] != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        NetworkImage(pelapor['gambar_user']),
                  )
                else
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Colors.orange.withOpacity(0.1),
                    child: const Icon(Icons.person,
                        color: Colors.orange, size: 16),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow2(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildResolutionResult(Map<String, dynamic> p) {
    final solver =
        p['User_Solver'] as Map<String, dynamic>?;
    final biaya = p['biaya_penyelesaian'] as num?;
    final biayaStr = biaya != null && biaya > 0
        ? NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0)
            .format(biaya)
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16A34A).withOpacity(0.05),
            const Color(0xFF16A34A).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF16A34A).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge selesai
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text(t['resolution_done']!,
                    style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Diselesaikan oleh
          if (solver != null)
            Row(
              children: [
                solver['gambar_user'] != null
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            NetworkImage(solver['gambar_user']))
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            Colors.green.withOpacity(0.1),
                        child: const Icon(Icons.person,
                            color: Colors.green, size: 18)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['resolved_by']!,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500)),
                    Text(solver['nama'] ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Foto penyelesaian
          if (p['gambar_penyelesaian'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(p['gambar_penyelesaian'],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),

          // Keterangan tindakan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['tindakan']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF1E3A8A))),
                const SizedBox(height: 4),
                Text(p['keterangan_tindakan'] ?? '-',
                    style: const TextStyle(
                        fontSize: 13, height: 1.5)),
              ],
            ),
          ),

          // Tanggal & Biaya
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Text(_formatDate(p['tanggal_selesai']),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600)),
              const Spacer(),
              if (biaya != null && biaya > 0) ...[
                const Icon(Icons.payments_outlined,
                    size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 5),
                Text(biayaStr,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A))),
              ],
            ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload foto
          _buildResLabel(t['upload_photo']!,
              isRequired: true),
          const SizedBox(height: 8),
          _resImageFile == null
              ? GestureDetector(
                  onTap: _pickResImage,
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.4),
                          width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            color: Colors.orange, size: 30),
                        const SizedBox(height: 6),
                        Text(t['upload_photo']!,
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(_resImageFile!.path,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover)
                          : Image.file(
                              File(_resImageFile!.path),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 8, bottom: 8,
                      child: GestureDetector(
                        onTap: _pickResImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius:
                                  BorderRadius.circular(20)),
                          child: Row(children: [
                            const Icon(Icons.camera_alt,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 5),
                            Text(
                                widget.lang == 'EN'
                                    ? 'Retake'
                                    : 'Ganti',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 16),

          // Keterangan tindakan
          _buildResLabel(t['tindakan']!, isRequired: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tindakanCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t['tindakan_hint']!,
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.orange, width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // Biaya
          _buildResLabel(t['biaya']!, isRequired: false),
          const SizedBox(height: 8),
          TextFormField(
            controller: _biayaCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: t['biaya_hint']!,
              prefixText: 'Rp ',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.orange, width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 20),

          // Tombol simpan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingResolution
                  ? null
                  : _saveResolution,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSavingResolution
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(t['save_resolution']!,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResLabel(String label,
      {bool isRequired = false}) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: const Color(0xFF1E3A8A))),
        if (isRequired)
          const Text(' *',
              style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold)),
      ],
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
            child:
                CircularProgressIndicator(color: Colors.white)),
      );
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
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('KTS PRODUKSI',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    width: 50, height: 50,
                    decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library,
                        color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (_ctrl == null ||
                        _ctrl!.value.isTakingPicture) return;
                    try {
                      final pic = await _ctrl!.takePicture();
                      if (mounted)
                        Navigator.pop(context, pic);
                    } on CameraException catch (e) {
                      debugPrint('Snap error: ${e.code}');
                    }
                  },
                  child: Container(
                    width: 75, height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle),
                      ),
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
                    width: 50, height: 50,
                    decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.flip_camera_ios,
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