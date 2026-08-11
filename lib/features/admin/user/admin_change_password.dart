import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminChangePasswordScreen extends StatefulWidget {
  final String lang;
  const AdminChangePasswordScreen({super.key, required this.lang});

  @override
  State<AdminChangePasswordScreen> createState() => _AdminChangePasswordScreenState();
}

class _AdminChangePasswordScreenState extends State<AdminChangePasswordScreen> {
  static const _primary = Color(0xFF6366F1);
  static const _bg = Color(0xFFF8FAFC);

  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _search = '';
  String? _processingId;
  final Set<String> _visiblePasswordIds = {};
  final TextEditingController _searchCtrl = TextEditingController();

  String get _lang => widget.lang;

  static const List<String> _monthNamesId = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
  static const List<String> _monthNamesEn = ['January','February','March','April','May','June','July','August','September','October','November','December'];

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

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _sb
          .from('password_reset_request')
          .select('id_request, id_user, email, new_password, new_password_hash, bukti_identitas_url, status, requested_at')
          .eq('status', 'pending')
          .order('requested_at');
      if (mounted) {
        setState(() {
          _allRequests = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading password requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_allRequests);
    if (q.isNotEmpty) {
      result = result.where((r) => (r['email'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    _filtered = result;
  }

  String _monthName(int month) {
    if (_lang == 'EN') return _monthNamesEn[month - 1];
    if (_lang == 'ZH') return '$month月';
    return _monthNamesId[month - 1];
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '-';
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$dd ${_monthName(dt.month)} ${dt.year} · $hh:$mm';
  }

  Future<void> _approveRequest(Map<String, dynamic> req) async {
    final String requestId = req['id_request'];
    final String? userId = req['id_user'] as String?;
    final String newPassword = req['new_password'] as String;
    final String newPasswordHash = req['new_password_hash'] as String;

    if (userId == null) {
      _showResultPopup(
        false,
        _lang == 'EN' ? 'User not found.' : _lang == 'ZH' ? '未找到用户。' : 'Pengguna tidak ditemukan.',
      );
      return;
    }

    setState(() => _processingId = requestId);
    try {
      try {
        await _sb.functions.invoke(
          'update-user-password',
          body: {'user_id': userId, 'new_password': newPassword},
        );
      } catch (fnErr) {
        debugPrint('Edge function error (non-fatal): $fnErr');
      }

      await _sb.from('User').update({'pass': newPasswordHash}).eq('id_user', userId);

      await _sb.from('password_reset_request').update({
        'status': 'approved',
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id_request', requestId);

      if (mounted) {
        setState(() {
          _allRequests.removeWhere((r) => r['id_request'] == requestId);
          _applyFilter();
          _processingId = null;
        });
        _showResultPopup(true, req['email']?.toString() ?? '-');
      }
    } catch (e) {
      debugPrint('Error approving password request: $e');
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> req) async {
    final String requestId = req['id_request'];
    setState(() => _processingId = requestId);
    try {
      await _sb.from('password_reset_request').update({
        'status': 'rejected',
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id_request', requestId);

      if (mounted) {
        setState(() {
          _allRequests.removeWhere((r) => r['id_request'] == requestId);
          _applyFilter();
          _processingId = null;
        });
        _showRejectedPopup();
      }
    } catch (e) {
      debugPrint('Error rejecting password request: $e');
      if (mounted) setState(() => _processingId = null);
    }
  }

  void _showResultPopup(bool success, String info) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'result',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.80, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _lang == 'EN' ? 'Approved!' : _lang == 'ZH' ? '已批准！' : 'Disetujui!',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lang == 'EN'
                        ? 'Password for $info has been changed.'
                        : _lang == 'ZH'
                            ? '$info 的密码已更改。'
                            : 'Password untuk $info berhasil diganti.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRejectedPopup() {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'rejected',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.80, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _lang == 'EN' ? 'Rejected' : _lang == 'ZH' ? '已拒绝' : 'Ditolak',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lang == 'EN'
                        ? 'Request rejected. Password remains unchanged.'
                        : _lang == 'ZH'
                            ? '请求已拒绝，密码未更改。'
                            : 'Permintaan ditolak. Password tidak berubah.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openProofImageViewer(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _IdentityProofViewer(imageUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _buildSearchField(),
          ),
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        color: _primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildRequestCard(_filtered[i]),
                        ),
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
        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14),
        decoration: InputDecoration(
          isCollapsed: true,
          hintText: _lang == 'EN' ? 'Search by email...' : _lang == 'ZH' ? '按邮箱搜索...' : 'Cari berdasarkan email...',
          hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
          suffixIcon: _search.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() {
                      _search = '';
                      _applyFilter();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 230,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final bool isFiltering = _search.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 150,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.06), shape: BoxShape.circle),
                child: Icon(Icons.password_rounded, size: 56, color: _primary.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering
                  ? (_lang == 'EN' ? 'No Matching Requests' : _lang == 'ZH' ? '未找到匹配的请求' : 'Permintaan Tidak Ditemukan')
                  : (_lang == 'EN' ? 'No password change requests' : _lang == 'ZH' ? '没有密码更改请求' : 'Tidak ada permintaan ganti password'),
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 6),
              Text(
                _lang == 'EN'
                    ? 'Try adjusting your search.'
                    : _lang == 'ZH'
                        ? '请尝试调整搜索条件。'
                        : 'Coba ubah kata kunci pencarian kamu.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() {
                  _searchCtrl.clear();
                  _search = '';
                  _applyFilter();
                }),
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
                      const Icon(Icons.refresh_rounded, size: 15, color: _primary),
                      const SizedBox(width: 6),
                      Text(
                        _lang == 'EN'
                            ? 'Clear search'
                            : _lang == 'ZH'
                                ? '清除搜索'
                                : 'Hapus pencarian',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
                      ),
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
    final String requestId = req['id_request'];
    final String email = req['email'] ?? '-';
    final String newPassword = req['new_password'] ?? '-';
    final String? proofUrl = req['bukti_identitas_url'] as String?;
    final bool isProcessing = _processingId == requestId;
    final bool isPassVisible = _visiblePasswordIds.contains(requestId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: proofUrl != null ? () => _openProofImageViewer(proofUrl) : null,
            child: Container(
              height: 140,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primary.withValues(alpha: 0.25), width: 1.3),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: proofUrl != null
                        ? CachedNetworkImage(
                            imageUrl: proofUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey.shade100),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                          ),
                  ),
                  if (proofUrl != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_rounded, size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.password_rounded, size: 13, color: Color(0xFF7C3AED)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isPassVisible ? newPassword : '•' * newPassword.length.clamp(6, 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF6D28D9)),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    if (isPassVisible) {
                      _visiblePasswordIds.remove(requestId);
                    } else {
                      _visiblePasswordIds.add(requestId);
                    }
                  }),
                  child: Icon(
                    isPassVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 15,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDate(req['requested_at']),
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: isProcessing ? null : () => _rejectRequest(req),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      foregroundColor: const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      _lang == 'EN' ? 'Reject' : _lang == 'ZH' ? '拒绝' : 'Tolak',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : () => _approveRequest(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isProcessing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      _lang == 'EN' ? 'Approve' : _lang == 'ZH' ? '批准' : 'Setujui',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
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

class _IdentityProofViewer extends StatelessWidget {
  final String imageUrl;
  const _IdentityProofViewer({required this.imageUrl});

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
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
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