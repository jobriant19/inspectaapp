import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import 'filter/admin_user_filter.dart';
import 'picker/admin_user_indicator.dart';

class AdminUnblockScreen extends StatefulWidget {
  final String lang;
  const AdminUnblockScreen({super.key, required this.lang});

  @override
  State<AdminUnblockScreen> createState() => _AdminUnblockScreenState();
}

class _AdminUnblockScreenState extends State<AdminUnblockScreen> {
  static const _primary = Color(0xFFDC2626);
  static const _bg = Color(0xFFF8FAFC);
  static const int _perPage = 5;

  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _jabatanList = [];
  bool _isLoading = true;
  String _search = '';
  int? _filterJabatanId;
  String? _filterJabatanName;
  int _currentPage = 1;
  String? _processingUserId;

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

  static const List<String> _dayNamesId = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
  static const List<String> _monthNamesId = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
  static const List<String> _dayNamesEn = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  static const List<String> _monthNamesEn = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  static const List<String> _dayNamesZh = ['星期一','星期二','星期三','星期四','星期五','星期六','星期日'];

  @override
  void initState() {
    super.initState();
    _loadJabatanList();
    _loadRequests();
  }

  Future<void> _loadJabatanList() async {
    try {
      final res = await _sb.from('jabatan').select('id_jabatan, nama_jabatan').order('id_jabatan');
      if (mounted) setState(() => _jabatanList = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Error loading jabatan list: $e');
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _sb
          .from('User')
          .select(
            'id_user, nama, email, gambar_user, poin, blocked_at, '
            'unblock_requested_at, id_jabatan, is_verificator, jabatan(nama_jabatan)',
          )
          .eq('unblock_requested', true)
          .order('unblock_requested_at');
      if (mounted) {
        setState(() {
          _allRequests = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading unblock requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_allRequests);

    if (q.isNotEmpty) {
      result = result.where((u) {
        return (u['nama'] ?? '').toString().toLowerCase().contains(q) ||
            (u['email'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }

    if (_filterJabatanId == kVerificatorFilterId) {
      result = result.where((u) => u['is_verificator'] == true).toList();
    } else if (_filterJabatanId != null) {
      result = result.where((u) => u['id_jabatan'] == _filterJabatanId).toList();
    }

    _filtered = result;
    _currentPage = 1;
  }

  Future<void> _unblockUser(Map<String, dynamic> user) async {
    final String userId = user['id_user'];
    setState(() => _processingUserId = userId);
    try {
      await _sb.from('User').update({
        'is_blocked': false,
        'unblock_requested': false,
        'block_popup_shown': false,
        'blocked_at': null,
        'unblock_requested_at': null,
        'current_streak': 1,
      }).eq('id_user', userId);

      await _notifyUser(user);

      if (mounted) {
        setState(() {
          _allRequests.removeWhere((u) => u['id_user'] == userId);
          _applyFilter();
          _processingUserId = null;
        });
        _showSuccessPopup(user['nama']?.toString() ?? '-');
      }
    } catch (e) {
      debugPrint('❌ [UNBLOCK] Error unblocking user: $e');
      if (mounted) setState(() => _processingUserId = null);
    }
  }

  Future<void> _notifyUser(Map<String, dynamic> user) async {
    try {
      final userId = user['id_user'];
      debugPrint('📤 [FCM-UNBLOCK] Menyiapkan notifikasi untuk user $userId...');
      final data = await _sb
          .from('User')
          .select('fcm_token')
          .eq('id_user', userId)
          .maybeSingle();
      final token = data?['fcm_token']?.toString();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [FCM-UNBLOCK] User $userId tidak punya fcm_token, notifikasi tidak terkirim');
        return;
      }

      final title = _lang == 'EN'
          ? '🔓 Account Unblocked'
          : _lang == 'ZH'
              ? '🔓 账户已解封'
              : '🔓 Akun Dibuka Blokirnya';
      final body = _lang == 'EN'
          ? 'Your account has been unblocked. You can use the app normally again.'
          : _lang == 'ZH'
              ? '您的账户已解封，您可以正常使用该应用了。'
              : 'Akun Anda telah dibuka blokirnya. Anda sudah bisa menggunakan aplikasi seperti biasa.';

      final ok = await NotificationService.sendFcmToToken(
        fcmToken: token,
        title: title,
        body: body,
        route: 'home',
      );
      if (ok) {
        debugPrint('✅ [FCM-UNBLOCK] Notifikasi berhasil terkirim ke user $userId');
      } else {
        debugPrint('❌ [FCM-UNBLOCK] Gagal mengirim notifikasi ke user $userId');
      }
    } catch (e) {
      debugPrint('❌ [FCM-UNBLOCK] Error notifying unblocked user: $e');
    }
  }

  void _showSuccessPopup(String userName) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
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
                      border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                          width: 2),
                    ),
                    child: const Icon(Icons.lock_open_rounded,
                        color: Color(0xFF16A34A), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _lang == 'EN'
                        ? 'Success!'
                        : _lang == 'ZH'
                            ? '成功！'
                            : 'Berhasil!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lang == 'EN'
                        ? '$userName has been unblocked.'
                        : _lang == 'ZH'
                            ? '$userName 已解封。'
                            : '$userName berhasil dibuka blokirnya.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _dayName(int weekday) {
    final idx = weekday - 1;
    if (_lang == 'EN') return _dayNamesEn[idx];
    if (_lang == 'ZH') return _dayNamesZh[idx];
    return _dayNamesId[idx];
  }

  String _monthName(int month) {
    final idx = month - 1;
    if (_lang == 'EN') return _monthNamesEn[idx];
    if (_lang == 'ZH') return '$month月';
    return _monthNamesId[idx];
  }

  String _formatRequestDate(dynamic raw) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '-';
    final dayName = _dayName(dt.weekday);
    final monthName = _monthName(dt.month);
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$dayName, $dd $monthName ${dt.year} · $hh:$mm';
  }

  Future<void> _openJabatanFilter() async {
    final result = await showAdminUserRoleFilterDialog(
      context,
      lang: widget.lang,
      jabatanList: _jabatanList,
      selectedJabatanId: _filterJabatanId,
    );
    if (result == null) return;
    setState(() {
      _filterJabatanId = result['id'] as int?;
      _filterJabatanName = result['name'] as String?;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _lang == 'EN'
              ? 'Unblock Requests'
              : _lang == 'ZH'
                  ? '解封请求'
                  : 'Pengajuan Buka Blokir',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 8),
                _buildJabatanFilterButton(),
              ],
            ),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildRequestCard(_pagedRequests[i]),
                      ),
                    ),
                    if (_totalPages > 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AdminUserIndicatorScreen(
                          currentPage: _currentPage,
                          totalPages: _totalPages,
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
        textAlignVertical: TextAlignVertical.center,
        onChanged: (v) => setState(() {
          _search = v;
          _applyFilter();
        }),
        style: GoogleFonts.poppins(color: const Color(0xFF7F1D1D), fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: _lang == 'EN'
              ? 'Search by name or email...'
              : _lang == 'ZH'
                  ? '按姓名或邮箱搜索...'
                  : 'Cari nama atau email...',
          hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildJabatanFilterButton() {
    final bool isActive = _filterJabatanId != null;
    final Color color = isActive ? adminRoleColor(_filterJabatanId) : _primary;
    return GestureDetector(
      onTap: _openJabatanFilter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.55) : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? adminRoleIcon(_filterJabatanId) : Icons.work_outline,
              size: 16,
              color: color,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                _filterJabatanName ?? '',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() {
                  _filterJabatanId = null;
                  _filterJabatanName = null;
                  _applyFilter();
                }),
                child: Icon(Icons.close_rounded, size: 14, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 200,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_open_outlined,
                size: 56, color: _primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            _lang == 'EN'
                ? 'No unblock requests'
                : _lang == 'ZH'
                    ? '没有解封请求'
                    : 'Tidak ada pengajuan buka blokir',
            style: GoogleFonts.poppins(
              color: Colors.black38,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> user) {
    final name = user['nama'] ?? '-';
    final email = user['email'] ?? '-';
    final avatarUrl = user['gambar_user'] as String?;
    final jabatanNama = user['jabatan']?['nama_jabatan'] as String?;
    final idJabatan = user['id_jabatan'] as int?;
    final isVerif = user['is_verificator'] as bool?;
    final bool isProcessing = _processingUserId == user['id_user'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _primary.withValues(alpha: 0.12),
                backgroundImage:
                    avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          color: _primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: const Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    buildAdminRoleBadge(
                      idJabatan: idJabatan,
                      jabatanNama: jabatanNama,
                      isVerificator: isVerif,
                      lang: _lang,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: _primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatRequestDate(user['unblock_requested_at']),
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: isProcessing ? null : () => _unblockUser(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: isProcessing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(
                _lang == 'EN'
                    ? 'Unblock'
                    : _lang == 'ZH'
                        ? '解封'
                        : 'Buka Blokir',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}