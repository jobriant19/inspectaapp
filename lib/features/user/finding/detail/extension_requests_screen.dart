import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/jabatan_helper.dart';
import '../../home/card/finding_card.dart';
import '../../ktsproduksi/kts_detail_screen.dart';
import 'finding_detail_screen.dart';

class ExtensionRequestsScreen extends StatefulWidget {
  final String lang;
  const ExtensionRequestsScreen({super.key, required this.lang});

  @override
  State<ExtensionRequestsScreen> createState() => _ExtensionRequestsScreenState();
}

class _ExtensionRequestsScreenState extends State<ExtensionRequestsScreen> {
  static const Color _primary = Color(0xFF1D72F3);
  static const Color _bg = Color(0xFFF5F7FA);
  static const int _perPage = 5;

  final _sb = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _search = '';
  int _currentPage = 1;
  String? _processingId;

  final Map<String, String> _rejectedReasons = {};

  String get _lang => widget.lang;

  int get _totalPages {
    if (_filtered.isEmpty) return 1;
    return (_filtered.length / _perPage).ceil();
  }

  List<Map<String, dynamic>> get _pagedRequests {
    if (_filtered.isEmpty) return [];
    final start = (_currentPage - 1) * _perPage;
    if (start >= _filtered.length) return [];
    final end = (start + _perPage).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _lt(String id, String en, String zh) {
    if (_lang == 'EN') return en;
    if (_lang == 'ZH') return zh;
    return id;
  }

  String _localeFor(String lang) {
    switch (lang) {
      case 'EN':
        return 'en_US';
      case 'ZH':
        return 'zh_CN';
      default:
        return 'id_ID';
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await _sb
          .from('perpanjang')
          .select('''
            id_perpanjang, waktu_perpanjang, alasan_perpanjang, tanggal_selesai,
            deadline_lama, status, created_at, id_temuan, id_user_pengaju,
            temuan:id_temuan(
              id_temuan, judul_temuan, deskripsi_temuan, jenis_temuan, gambar_temuan, created_at,
              status_temuan, poin_temuan, target_waktu_selesai,
              id_lokasi, id_unit, id_subunit, id_area,
              id_penanggung_jawab, id_penyelesaian, is_pro, is_visitor, is_eksekutif,
              no_order, jumlah_item, nama_item_manual,
              lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
              kategoritemuan(nama_kategoritemuan),
              item_produksi:id_item(id_item, nama_item, gambar_item, kode_item),
              subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan),
              User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
              User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
              penyelesaian!temuan_id_penyelesaian_fkey(*,
                User_Solver:User!id_user(nama, gambar_user),
                section:id_section(nama_section_id, nama_section_en, nama_section_zh),
                faktor_penyebab:id_subkategoritemuan_penyebab(id_subkategoritemuan, nama_subkategoritemuan))
            ),
            pengaju:User!perpanjang_id_user_pengaju_fkey(
              id_user, nama, gambar_user, id_jabatan, is_verificator,
              jabatan!User_id_jabatan_fkey(nama_jabatan)
            )
          ''')
          .eq('id_user_penerima', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allRequests = List<Map<String, dynamic>>.from(data);
          _rejectedReasons.clear();
          _isLoading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading extension requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_allRequests);
    if (q.isNotEmpty) {
      result = result.where((r) {
        final judul = (r['temuan']?['judul_temuan'] ?? '').toString().toLowerCase();
        final nama = (r['pengaju']?['nama'] ?? '').toString().toLowerCase();
        return judul.contains(q) || nama.contains(q);
      }).toList();
    }
    _filtered = result;
    _currentPage = 1;
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _search = '';
      _applyFilter();
    });
  }

  String _formatDate(dynamic raw, {String format = 'dd MMM yyyy'}) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '-';
    return DateFormat(format, _localeFor(_lang)).format(dt);
  }

  Future<void> _notifyPengaju(Map<String, dynamic> req,
      {required bool approved, String? reason}) async {
    try {
      final idPengaju = req['id_user_pengaju']?.toString();
      if (idPengaju == null) return;
      final data = await _sb
          .from('User')
          .select('fcm_token')
          .eq('id_user', idPengaju)
          .maybeSingle();
      final token = data?['fcm_token']?.toString();
      if (token == null || token.trim().isEmpty) return;

      final judul = req['temuan']?['judul_temuan']?.toString() ?? '';
      final title = approved
          ? (_lang == 'EN'
              ? '✅ Extension Approved'
              : _lang == 'ZH'
                  ? '✅ 延期已批准'
                  : '✅ Perpanjangan Disetujui')
          : (_lang == 'EN'
              ? '❌ Extension Rejected'
              : _lang == 'ZH'
                  ? '❌ 延期已拒绝'
                  : '❌ Perpanjangan Ditolak');
      final body = (!approved && reason != null && reason.trim().isNotEmpty)
          ? '$judul - $reason'
          : judul;

      await _sb.functions.invoke('send-fcm-v1', body: {
        'token': token.trim(),
        'title': title,
        'body': body,
        'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK', 'route': 'findings'},
      });
    } catch (e) {
      debugPrint('FCM notify pengaju error: $e');
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> req) async {
    final idPerpanjang = req['id_perpanjang'].toString();
    setState(() => _processingId = idPerpanjang);
    try {
      final user = _sb.auth.currentUser;
      final idTemuan = req['id_temuan'].toString();
      final newDate = req['tanggal_selesai'];

      await _sb.from('perpanjang').update({
        'status': 'approved',
        'responded_at': DateTime.now().toIso8601String(),
        'id_user_responder': user?.id,
      }).eq('id_perpanjang', idPerpanjang);

      await _sb.from('temuan').update({
        'id_perpanjang': idPerpanjang,
        'target_waktu_selesai': newDate,
      }).eq('id_temuan', idTemuan);

      await _notifyPengaju(req, approved: true);

      if (mounted) {
        setState(() {
          _allRequests.removeWhere((r) => r['id_perpanjang'] == req['id_perpanjang']);
          _applyFilter();
          _processingId = null;
        });
        _showResultPopup(
            approved: true, title: req['temuan']?['judul_temuan']?.toString() ?? '-');
      }
    } catch (e) {
      debugPrint('Error approving extension: $e');
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> req, String reason) async {
    final idPerpanjang = req['id_perpanjang'].toString();
    setState(() => _processingId = idPerpanjang);
    try {
      final user = _sb.auth.currentUser;

      await _sb.from('perpanjang').update({
        'status': 'rejected',
        'alasan_tolak': reason.trim().isEmpty ? null : reason.trim(),
        'responded_at': DateTime.now().toIso8601String(),
        'id_user_responder': user?.id,
      }).eq('id_perpanjang', idPerpanjang);

      await _notifyPengaju(req, approved: false, reason: reason);

      if (mounted) {
        setState(() {
          _rejectedReasons[idPerpanjang] = reason.trim().isEmpty
              ? _lt('Tidak ada alasan diberikan', 'No reason given', '未提供原因')
              : reason.trim();
          _processingId = null;
        });
      }
    } catch (e) {
      debugPrint('Error rejecting extension: $e');
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _showRejectDialog(Map<String, dynamic> req) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.block_rounded,
                              color: Color(0xFFEF4444), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _lt('Tolak Pengajuan', 'Reject Request', '拒绝申请'),
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _lt(
                        'Berikan alasan penolakan (opsional)',
                        'Give a reason for rejecting (optional)',
                        '提供拒绝原因（可选）',
                      ),
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: _lt('Tulis alasan...', 'Write a reason...', '写下原因...'),
                        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFFEF2F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(_lt('Tolak Pengajuan', 'Reject Request', '拒绝申请'),
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _rejectRequest(req, reasonCtrl.text);
    }
  }

  void _showResultPopup({required bool approved, required String title}) {
    if (!mounted) return;
    final Color color = approved ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final IconData icon = approved ? Icons.check_circle_rounded : Icons.cancel_rounded;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'result',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 4,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.1),
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Icon(icon, color: color, size: 46),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    approved
                        ? _lt('Disetujui!', 'Approved!', '已批准！')
                        : _lt('Ditolak', 'Rejected', '已拒绝'),
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w800, color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _jabatanLabel(Map<String, dynamic> user) {
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final jabatanNama = (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
    return JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: _lang,
    );
  }

  Widget _buildJabatanBadge(Map<String, dynamic> user) {
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final label = _jabatanLabel(user);
    if (label.isEmpty) return const SizedBox.shrink();
    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon =
        JabatanHelper.getRoleIcon(isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _lt('Pengajuan Perpanjangan', 'Extension Requests', '延期申请'),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 17, color: _primary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchField(),
          ),
        ),
      ),
      body: _isLoading
          ? _buildShimmerList()
          : _filtered.isEmpty
              ? _buildEmpty()
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadRequests,
                      color: _primary,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          16, 12, 16,
                          _totalPages > 1 ? (100 + bottomInset) : 32,
                        ),
                        itemCount: _pagedRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _buildRequestCard(_pagedRequests[i]),
                      ),
                    ),
                    if (_totalPages > 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _ExtensionPageIndicator(
                          currentPage: _currentPage,
                          totalPages: _totalPages,
                          bottomInset: bottomInset,
                          onPageChanged: (p) => setState(() => _currentPage = p),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _searchCtrl,
        textAlignVertical: TextAlignVertical.center,
        onChanged: (v) => setState(() {
          _search = v;
          _applyFilter();
        }),
        style: GoogleFonts.poppins(color: _primary, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          hintText: _lt('Cari temuan atau nama pengaju...', 'Search finding or requester...', '搜索发现或申请人...'),
          hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
          suffixIcon: _search.isNotEmpty
              ? GestureDetector(
                  onTap: _clearSearch,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => Container(
          height: 260,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule_send_outlined,
                    size: 46, color: _primary.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _search.isNotEmpty
                  ? _lt('Tidak Ditemukan', 'No Matches Found', '未找到结果')
                  : _lt('Tidak Ada Pengajuan', 'No Requests', '没有申请'),
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _primary),
            ),
            const SizedBox(height: 6),
            Text(
              _search.isNotEmpty
                  ? _lt(
                      'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.',
                      "Try adjusting your search keyword to find what you're looking for.",
                      '尝试调整搜索关键词以查找您需要的内容。',
                    )
                  : _lt(
                      'Belum ada pengajuan perpanjangan deadline yang menunggu persetujuan Anda.',
                      'No deadline extension requests are waiting for your approval.',
                      '没有等待您批准的截止日期延期申请。',
                    ),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade500, height: 1.5),
            ),
            if (_search.isNotEmpty) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: _primary),
                      const SizedBox(width: 6),
                      Text(_lt('Hapus pencarian', 'Clear search', '清除搜索'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final pengaju = req['pengaju'] as Map<String, dynamic>?;
    final temuanRaw = req['temuan'] as Map<String, dynamic>?;
    final String idPerpanjang = req['id_perpanjang'].toString();
    final bool isProcessing = _processingId == idPerpanjang;
    final String? namaPengaju = pengaju?['nama']?.toString();
    final String? avatarPengaju = pengaju?['gambar_user']?.toString();
    final String? rejectedReason = _rejectedReasons[idPerpanjang];

    final Map<String, dynamic> cardData = temuanRaw ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FindingCard(
            data: cardData,
            lang: _lang,
            onTap: () async {
              final jenis = (cardData['jenis_temuan'] ?? '').toString();
              final bool isKts = jenis == 'KTS Production';
              if (isKts) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KtsDetailScreen(
                      ktsId: cardData['id_temuan'].toString(),
                      lang: _lang,
                      initialData: cardData,
                    ),
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FindingDetailScreen(
                      initialData: cardData,
                      lang: _lang,
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 14),

          // REQUESTER INFO
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _primary.withValues(alpha: 0.1),
                backgroundImage: avatarPengaju != null ? NetworkImage(avatarPengaju) : null,
                child: avatarPengaju == null
                    ? const Icon(Icons.person, color: _primary, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(namaPengaju ?? '-',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 13.5, color: const Color(0xFF0F172A))),
                    if (pengaju != null) ...[
                      const SizedBox(height: 3),
                      _buildJabatanBadge(pengaju),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // OLD DEADLINE -> NEW DEADLINE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_lt('Deadline Lama', 'Old Deadline', '旧截止日期'),
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                      const SizedBox(height: 3),
                      Text(_formatDate(req['deadline_lama']),
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: _primary, size: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_lt('Deadline Baru', 'New Deadline', '新截止日期'),
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, fontWeight: FontWeight.w600, color: _primary)),
                      const SizedBox(height: 3),
                      Text(_formatDate(req['tanggal_selesai']),
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w800, color: _primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // EXTENSION REASON
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: _primary),
              const SizedBox(width: 6),
              Text(_lt('Alasan Perpanjangan', 'Extension Reason', '延期原因'),
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withValues(alpha: 0.15)),
            ),
            child: Text(
              req['alasan_perpanjang']?.toString() ?? '-',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
          const SizedBox(height: 16),

          // ACTION BUTTONS OR REJECTED REASON
          if (rejectedReason != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lt('Pengajuan Ditolak', 'Request Rejected', '申请已拒绝'),
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rejectedReason,
                          style: GoogleFonts.poppins(
                              fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF7F1D1D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : () => _showRejectDialog(req),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(_lt('Tolak', 'Reject', '拒绝'),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _approveRequest(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(_lt('Setuju', 'Approve', '批准'),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ExtensionPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final double bottomInset;
  final ValueChanged<int> onPageChanged;

  const _ExtensionPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.bottomInset,
    required this.onPageChanged,
  });

  static const Color _primary = Color(0xFF1D72F3);
  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          _arrowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: canPrev,
            onTap: () {
              if (canPrev) onPageChanged(currentPage - 1);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (final p in pageNumbers) ...[
                  Expanded(child: _pageButton(p)),
                  if (p != pageNumbers.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _arrowButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: canNext,
            onTap: () {
              if (canNext) onPageChanged(currentPage + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page != currentPage) onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _primary : _primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: _primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
              color: isActive ? Colors.white : _primary, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: enabled ? _primary.withValues(alpha: 0.14) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? _primary : Colors.grey.shade400),
      ),
    );
  }
}