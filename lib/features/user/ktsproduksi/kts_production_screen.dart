import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../home/popup/location_permission_popup.dart';
import 'kts_create_report.dart';
import 'kts_detail_screen.dart';

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
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => KtsDetailScreen(ktsId: r['id_temuan'].toString(), lang: widget.lang, initialData: r)));
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