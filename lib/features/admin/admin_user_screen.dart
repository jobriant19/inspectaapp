import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'user/admin_add_user.dart';
import 'user/admin_delete_user.dart';
import 'user/admin_edit_user.dart';

class AdminUserScreen extends StatefulWidget {
  final String lang;
  const AdminUserScreen({super.key, required this.lang});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _jabatanList = [];
  bool _isLoading = true;
  String _search = '';

  // Filter state
  String? _filterLokasiId;
  String? _filterLokasiName;
  String? _filterUnitId;
  String? _filterUnitName;
  String? _filterSubunitId;
  String? _filterSubunitName;
  String? _filterAreaId;
  String? _filterAreaName;
  int? _filterJabatanId;
  String? _filterJabatanName;
  String _sortOrder = 'none';

  List<Map<String, dynamic>> _allLokasiFilter = [];
  List<Map<String, dynamic>> _allUnitFilter = [];
  List<Map<String, dynamic>> _allSubunitFilter = [];
  List<Map<String, dynamic>> _allAreaFilter = [];
  // ignore: unused_field
  bool _filterDataLoaded = false;

  final Map<String, int> _monthlyPoints = {};

  static const _primary = Color(0xFF6366F1);
  static const _bg = Color(0xFFF8FAFC);
  static const _appBarColor = Color(0xFF6366F1);
  static const _appBarFg = Colors.white;

  String get _langCode => widget.lang;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final monthEnd = DateTime(now.year, now.month + 1, 1).toIso8601String();

      final results = await Future.wait([
        Supabase.instance.client
            .from('User')
            .select(
              'id_user, nama, email, poin, gambar_user, is_visitor, phone, '
              'is_verificator, id_supervisor, id_jabatan, timestamp, log_login, first_login, '
              'id_lokasi, id_unit, id_subunit, id_area, bagian_kasie, '
              'jabatan(nama_jabatan), '
              'lokasi!fk_user_lokasi(nama_lokasi), '
              'unit!user_id_unit_fkey(nama_unit), '
              'subunit!fk_user_subunit(nama_subunit), '
              'area!fk_user_area(nama_area)',
            )
            .order('nama'),
        Supabase.instance.client
            .from('jabatan')
            .select('id_jabatan, nama_jabatan')
            .order('id_jabatan'),
        Supabase.instance.client
            .from('log_poin')
            .select('id_user, poin')
            .gte('created_at', monthStart)
            .lt('created_at', monthEnd),
        Supabase.instance.client
            .from('lokasi')
            .select('id_lokasi, nama_lokasi')
            .order('nama_lokasi'),
        Supabase.instance.client
            .from('unit')
            .select('id_unit, nama_unit, id_lokasi')
            .order('nama_unit'),
        Supabase.instance.client
            .from('subunit')
            .select('id_subunit, nama_subunit, id_unit')
            .order('nama_subunit'),
        Supabase.instance.client
            .from('area')
            .select('id_area, nama_area, id_subunit')
            .order('nama_area'),
      ]);

      if (mounted) {
        // Build monthly points map
        final logList = List<Map<String, dynamic>>.from(results[2] as List);
        final Map<String, int> pMap = {};
        for (final log in logList) {
          final uid = log['id_user']?.toString() ?? '';
          pMap[uid] = (pMap[uid] ?? 0) + (log['poin'] as int? ?? 0);
        }

        setState(() {
          _users = List<Map<String, dynamic>>.from(results[0] as List);
          _jabatanList = List<Map<String, dynamic>>.from(results[1] as List);
          _monthlyPoints.clear();
          _monthlyPoints.addAll(pMap);
          _allLokasiFilter   = List<Map<String, dynamic>>.from(results[3] as List);
          _allUnitFilter     = List<Map<String, dynamic>>.from(results[4] as List);
          _allSubunitFilter  = List<Map<String, dynamic>>.from(results[5] as List);
          _allAreaFilter     = List<Map<String, dynamic>>.from(results[6] as List);
          _filterDataLoaded  = true;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_users);

    if (q.isNotEmpty) {
      result = result.where((u) {
        return (u['nama'] ?? '').toLowerCase().contains(q) ||
            (u['email'] ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // Filter hierarki lokasi (Area → Subunit → Unit → Lokasi)
    if (_filterAreaId != null) {
      result = result.where((u) => u['id_area']?.toString() == _filterAreaId).toList();
    } else if (_filterSubunitId != null) {
      result = result.where((u) => u['id_subunit']?.toString() == _filterSubunitId).toList();
    } else if (_filterUnitId != null) {
      result = result.where((u) => u['id_unit']?.toString() == _filterUnitId).toList();
    } else if (_filterLokasiId != null) {
      result = result.where((u) => u['id_lokasi']?.toString() == _filterLokasiId).toList();
    }

    if (_filterJabatanId != null) {
      result = result.where((u) => u['id_jabatan'] == _filterJabatanId).toList();
    }

    if (_sortOrder == 'asc') {
      result.sort((a, b) => (a['nama'] ?? '').compareTo(b['nama'] ?? ''));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => (b['nama'] ?? '').compareTo(a['nama'] ?? ''));
    }

    _filtered = result;
  }

  void _showUserDetail(Map<String, dynamic> user) {
    final langCode = widget.lang;
    final name = user['nama'] ?? '-';
    final email = user['email'] ?? '-';
    final phone = user['phone'] ?? '-';
    final jabatan = user['jabatan']?['nama_jabatan'] ?? '-';
    final isVisitor = user['is_visitor'] == true;
    final isVerif = user['is_verificator'] == true;
    final avatarUrl = user['gambar_user'] as String?;
    final idUser = user['id_user'] ?? '-';
    final timestamp = user['timestamp'];
    final logLogin = user['log_login'];
    final firstLogin = user['first_login'];
    final lokasiName = user['lokasi']?['nama_lokasi'];
    final unitName = user['unit']?['nama_unit'];
    final subunitName = user['subunit']?['nama_subunit'];
    final areaName = user['area']?['nama_area'];

    // Monthly points from cache
    final monthlyPoin = _monthlyPoints[idUser.toString()] ?? 0;

    // Specific location string: area > subunit > unit > lokasi
    String specificLocation = '-';
    if (areaName != null && areaName.toString().isNotEmpty) {
      specificLocation = areaName.toString();
    } else if (subunitName != null && subunitName.toString().isNotEmpty) {
      specificLocation = subunitName.toString();
    } else if (unitName != null && unitName.toString().isNotEmpty) {
      specificLocation = unitName.toString();
    } else if (lokasiName != null && lokasiName.toString().isNotEmpty) {
      specificLocation = lokasiName.toString();
    }

    String _formatDate(dynamic raw) {
      if (raw == null) return '-';
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        return '${dt.day.toString().padLeft(2, '0')}/'
            '${dt.month.toString().padLeft(2, '0')}/'
            '${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return raw.toString();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Fixed Header ──
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle bar + close button row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar + name header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: _primary.withOpacity(0.12),
                                backgroundImage: avatarUrl != null
                                    ? CachedNetworkImageProvider(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.poppins(
                                          color: _primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 26,
                                        ),
                                      )
                                    : null,
                              ),
                              // Badge poin bulan ini
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBBF24),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Text(
                                    '$monthlyPoin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black45,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _buildDetailChip(
                                        jabatan, _primary, Icons.work_outline),
                                    if (isVisitor)
                                      _buildDetailChip(
                                        langCode == 'EN'
                                            ? 'Visitor'
                                            : langCode == 'ZH'
                                                ? '访客'
                                                : 'Pengunjung',
                                        const Color(0xFF0891B2),
                                        Icons.visibility_outlined,
                                      ),
                                    if (isVerif)
                                      _buildDetailChip(
                                        langCode == 'EN'
                                            ? 'Verificator'
                                            : langCode == 'ZH'
                                                ? '验证员'
                                                : 'Verifikator',
                                        const Color(0xFFF59E0B),
                                        Icons.verified_user_outlined,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey.shade100, thickness: 1.5, height: 1),
                  ],
                ),
              ),
              // ── Scrollable Content ──
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _buildDetailSection(
                      langCode == 'EN'
                          ? 'Personal Information'
                          : langCode == 'ZH'
                              ? '个人信息'
                              : 'Informasi Pribadi',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.badge_outlined,
                      langCode == 'EN'
                          ? 'User ID'
                          : langCode == 'ZH'
                              ? '用户ID'
                              : 'ID Pengguna',
                      idUser.toString(),
                      const Color(0xFF6366F1),
                      small: true,
                    ),
                    _buildDetailRow(
                      Icons.phone_outlined,
                      langCode == 'EN'
                          ? 'Phone'
                          : langCode == 'ZH'
                              ? '电话'
                              : 'Telepon',
                      phone == '-' || phone.toString().isEmpty ? '-' : phone.toString(),
                      const Color(0xFF10B981),
                    ),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      langCode == 'EN'
                          ? 'Location'
                          : langCode == 'ZH'
                              ? '位置'
                              : 'Lokasi',
                      specificLocation,
                      const Color(0xFF0891B2),
                    ),
                    _buildDetailRow(
                      Icons.star_outline_rounded,
                      langCode == 'EN'
                          ? 'Points This Month'
                          : langCode == 'ZH'
                              ? '本月积分'
                              : 'Poin Bulan Ini',
                      '$monthlyPoin pts',
                      const Color(0xFFF59E0B),
                    ),

                    const SizedBox(height: 16),
                    _buildDetailSection(
                      langCode == 'EN'
                          ? 'Activity'
                          : langCode == 'ZH'
                              ? '活动记录'
                              : 'Aktivitas',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.calendar_today_outlined,
                      langCode == 'EN'
                          ? 'Registered'
                          : langCode == 'ZH'
                              ? '注册时间'
                              : 'Terdaftar',
                      _formatDate(timestamp),
                      const Color(0xFF6366F1),
                    ),
                    _buildDetailRow(
                      Icons.login_rounded,
                      langCode == 'EN'
                          ? 'First Login'
                          : langCode == 'ZH'
                              ? '首次登录'
                              : 'Login Pertama',
                      _formatDate(firstLogin),
                      const Color(0xFF8B5CF6),
                    ),
                    _buildDetailRow(
                      Icons.access_time_rounded,
                      langCode == 'EN'
                          ? 'Last Login'
                          : langCode == 'ZH'
                              ? '最后登录'
                              : 'Login Terakhir',
                      _formatDate(logLogin),
                      const Color(0xFF10B981),
                    ),

                    const SizedBox(height: 20),

                    // ── Tombol Edit & Delete ──
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showUserDialog(user: user);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                            label: Text(
                              langCode == 'EN' ? 'Edit' : langCode == 'ZH' ? '编辑' : 'Edit',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteUser(user['id_user'], name);
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: Colors.white),
                            label: Text(
                              langCode == 'EN'
                                  ? 'Delete'
                                  : langCode == 'ZH'
                                      ? '删除'
                                      : 'Hapus',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
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
      ),
    );
  }

  Widget _buildDetailSection(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E3A8A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color,
      {bool small = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.black45,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A),
                    fontSize: small ? 11 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIALOG: Edit User saja (Add sudah dipindah ke AdminAddUserScreen) ───
  void _showUserDialog({Map<String, dynamic>? user}) {
    if (user == null) {
      // Add User → arahkan ke AdminAddUserScreen (tidak berubah)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminAddUserScreen(
            lang: widget.lang,
            jabatanList: _jabatanList,
            onUserAdded: _loadData,
          ),
        ),
      );
      return;
    }

    // Edit User → arahkan ke AdminEditUserScreen (file baru)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditUserScreen(
          lang: widget.lang,
          user: user,
          jabatanList: _jabatanList,
          onUserUpdated: _loadData,
        ),
      ),
    );
  }

  Future<void> _deleteUser(String userId, String nama) async {
    await AdminDeleteUser.confirmAndDelete(
      context: context,
      userId: userId,
      userName: nama,
      lang: _langCode,
      onDeleted: _loadData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _appBarFg,
        foregroundColor: _appBarColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        shadowColor: Colors.black.withOpacity(0.08),
        title: Text(
          _langCode == 'EN'
              ? 'User Management'
              : _langCode == 'ZH'
                  ? '用户管理'
                  : 'Kelola Pengguna',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _appBarColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _buildSearchField(),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Sticky white section: filter buttons + Add User button ──
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Filter buttons row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: _buildFilterButtons(),
                ),
                // Add User banner button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: GestureDetector(
                    onTap: () => _showUserDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _langCode == 'EN'
                                      ? 'Add New User'
                                      : _langCode == 'ZH'
                                          ? '添加新用户'
                                          : 'Tambah Pengguna Baru',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                                Text(
                                  _langCode == 'EN'
                                      ? 'Register a new user account'
                                      : _langCode == 'ZH'
                                          ? '注册新用户账户'
                                          : 'Daftarkan akun pengguna baru',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color:
                                          Colors.white.withOpacity(0.85)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Active filter chips ──
          if (_filterLokasiId != null || _filterUnitId != null ||
              _filterSubunitId != null || _filterAreaId != null ||
              _filterJabatanId != null || _sortOrder != 'none')
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_filterAreaName != null)
                    _buildActiveFilterChip('📍 $_filterAreaName',
                      () => setState(() { _filterAreaId = null; _filterAreaName = null; _applyFilter(); })),
                  if (_filterSubunitName != null)
                    _buildActiveFilterChip('📍 $_filterSubunitName',
                      () => setState(() { _filterSubunitId = null; _filterSubunitName = null; _applyFilter(); })),
                  if (_filterUnitName != null)
                    _buildActiveFilterChip('📍 $_filterUnitName',
                      () => setState(() { _filterUnitId = null; _filterUnitName = null; _applyFilter(); })),
                  if (_filterLokasiName != null)
                    _buildActiveFilterChip('📍 $_filterLokasiName',
                      () => setState(() { _filterLokasiId = null; _filterLokasiName = null; _applyFilter(); })),
                  if (_filterJabatanName != null)
                    _buildActiveFilterChip('💼 $_filterJabatanName',
                      () => setState(() { _filterJabatanId = null; _filterJabatanName = null; _applyFilter(); })),
                  if (_sortOrder != 'none')
                    _buildActiveFilterChip(
                      _sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
                      () => setState(() { _sortOrder = 'none'; _applyFilter(); })),
                ],
              ),
            ),
          // ── User list ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: _primary,
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _buildUserCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // WIDGET HELPERS
  // ══════════════════════════════════════

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        onChanged: (v) => setState(() {
          _search = v;
          _applyFilter();
        }),
        style: GoogleFonts.poppins(
            color: const Color(0xFF1E3A8A), fontSize: 14),
        decoration: InputDecoration(
          hintText: _langCode == 'EN'
              ? 'Search by name or email...'
              : _langCode == 'ZH'
                  ? '按姓名或邮箱搜索...'
                  : 'Cari nama atau email...',
          hintStyle: GoogleFonts.poppins(
              color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(Icons.search,
              color: Colors.black38, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final jabatan = user['jabatan']?['nama_jabatan'] ?? '-';
    final isVerif = user['is_verificator'] == true;
    final isVisitor = user['is_visitor'] == true;
    final avatarUrl = user['gambar_user'] as String?;
    final name = user['nama'] ?? '';
    final monthlyPoin = _monthlyPoints[user['id_user']?.toString() ?? ''] ?? 0;

    // Specific location: area > subunit > unit > lokasi
    final areaName = user['area']?['nama_area'];
    final subunitName = user['subunit']?['nama_subunit'];
    final unitName = user['unit']?['nama_unit'];
    final lokasiName = user['lokasi']?['nama_lokasi'];
    String specificLocation = '';
    if (areaName != null && areaName.toString().isNotEmpty) {
      specificLocation = areaName.toString();
    } else if (subunitName != null && subunitName.toString().isNotEmpty) {
      specificLocation = subunitName.toString();
    } else if (unitName != null && unitName.toString().isNotEmpty) {
      specificLocation = unitName.toString();
    } else if (lokasiName != null && lokasiName.toString().isNotEmpty) {
      specificLocation = lokasiName.toString();
    }

    // Warna berdasarkan jabatan
    Color roleColor = const Color(0xFF6366F1);
    final idJabatan = user['id_jabatan'];
    if (idJabatan == 1) roleColor = const Color(0xFFDC2626); // Eksekutif
    if (idJabatan == 2) roleColor = const Color(0xFF7C3AED); // Manager
    if (idJabatan == 3) roleColor = const Color(0xFF0891B2); // Kasie
    if (idJabatan == 6) roleColor = const Color(0xFF059669); // Admin

    return GestureDetector(
      onTap: () => _showUserDetail(user),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ──
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: roleColor.withOpacity(0.12),
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              // Badge poin kecil
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '$monthlyPoin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                // ── Baris 1: Jabatan + badge visitor/verif ──
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    _buildChip(jabatan, roleColor, Icons.work_outline),
                    if (isVisitor)
                      _buildChip(
                        _langCode == 'EN' ? 'Visitor' : _langCode == 'ZH' ? '访客' : 'Pengunjung',
                        const Color(0xFF0891B2), Icons.visibility_outlined,
                      ),
                    if (isVerif)
                      _buildChip(
                        _langCode == 'EN' ? 'Verificator' : _langCode == 'ZH' ? '验证员' : 'Verifikator',
                        const Color(0xFFF59E0B), Icons.verified_user_outlined,
                      ),
                  ],
                ),
                // ── Baris 2: Lokasi spesifik (jika ada) ──
                if (specificLocation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildChip(
                    specificLocation,
                    _locationChipColor(user),   // ← warna per level
                    Icons.location_on_outlined,
                  ),
                ],
              ],
            ),
          ),

          // ── Action Buttons ──
          Column(
            children: [
              _buildIconBtn(
                Icons.edit_outlined,
                const Color(0xFF2563EB),
                () => _showUserDialog(user: user),
              ),
              const SizedBox(height: 8),
              _buildIconBtn(
                Icons.delete_outline_rounded,
                const Color(0xFFEF4444),
                () => _deleteUser(user['id_user'], name),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Color _locationChipColor(Map<String, dynamic> user) {
    // Warna sesuai level paling spesifik yang terisi
    if (user['area']?['nama_area'] != null &&
        (user['area']!['nama_area'] as String).isNotEmpty) {
      return const Color(0xFFF472B6); // Area — pink (sama dengan tab Area)
    }
    if (user['subunit']?['nama_subunit'] != null &&
        (user['subunit']!['nama_subunit'] as String).isNotEmpty) {
      return const Color(0xFFFBBF24); // Subunit — amber (sama dengan tab Subunit)
    }
    if (user['unit']?['nama_unit'] != null &&
        (user['unit']!['nama_unit'] as String).isNotEmpty) {
      return const Color(0xFF6366F1); // Unit — indigo (sama dengan tab Unit)
    }
    return const Color(0xFF10B981);   // Lokasi — hijau (sama dengan tab Lokasi)
  }

  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Icon(icon, color: color, size: 16),
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
              color: _primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline,
                size: 56, color: _primary.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            _langCode == 'EN'
                ? 'No users found'
                : _langCode == 'ZH'
                    ? '未找到用户'
                    : 'Tidak ada pengguna',
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

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: _primary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: _primary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final hasLokasiFilter = _filterLokasiId != null;
    final hasJabatanFilter = _filterJabatanId != null;
    final hasSortFilter = _sortOrder != 'none';

    return Row(
      children: [
        Expanded(
          child: _FilterButton(
            label: _langCode == 'EN'
                ? 'Location'
                : _langCode == 'ZH'
                    ? '位置'
                    : 'Lokasi',
            icon: Icons.location_on_outlined,
            isActive: hasLokasiFilter,
            onTap: () => _showFilterDialog('lokasi'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterButton(
            label: _langCode == 'EN'
                ? 'Position'
                : _langCode == 'ZH'
                    ? '职位'
                    : 'Jabatan',
            icon: Icons.work_outline,
            isActive: hasJabatanFilter,
            onTap: () => _showFilterDialog('jabatan'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterButton(
            label: _langCode == 'EN'
                ? 'Sort'
                : _langCode == 'ZH'
                    ? '排序'
                    : 'Urutan',
            icon: Icons.sort_by_alpha_rounded,
            isActive: hasSortFilter,
            onTap: () => _showFilterDialog('sort'),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(String type) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          String dialogTitle = '';
          if (type == 'lokasi') {
            dialogTitle = _langCode == 'EN' ? 'Filter by Location' : _langCode == 'ZH' ? '按位置筛选' : 'Filter Lokasi';
          } else if (type == 'jabatan') {
            dialogTitle = _langCode == 'EN' ? 'Filter by Position' : _langCode == 'ZH' ? '按职位筛选' : 'Filter Jabatan';
          } else {
            dialogTitle = _langCode == 'EN' ? 'Sort Order' : _langCode == 'ZH' ? '排序方式' : 'Urutan Abjad';
          }

          // State lokal untuk cascading lokasi
          String? tempLokasiId   = _filterLokasiId;
          String? tempUnitId     = _filterUnitId;
          String? tempSubunitId  = _filterSubunitId;
          String? tempAreaId     = _filterAreaId;

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.04),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type == 'lokasi' ? Icons.location_on_outlined
                            : type == 'jabatan' ? Icons.work_outline
                            : Icons.sort_by_alpha_rounded,
                        color: _primary, size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(dialogTitle,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A)))),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Options ──
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: type == 'lokasi'
                      // ── LOKASI: cascading StatefulBuilder ──
                      ? StatefulBuilder(
                          builder: (ctx2, setInner) {
                            final filteredUnits = tempLokasiId == null ? _allUnitFilter
                                : _allUnitFilter.where((u) => u['id_lokasi']?.toString() == tempLokasiId).toList();
                            final filteredSubunits = tempUnitId == null ? _allSubunitFilter
                                : _allSubunitFilter.where((s) => s['id_unit']?.toString() == tempUnitId).toList();
                            final filteredAreas = tempSubunitId == null ? _allAreaFilter
                                : _allAreaFilter.where((a) => a['id_subunit']?.toString() == tempSubunitId).toList();

                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Tab Lokasi ──
                                  _buildCascadeSection(
                                    label: _langCode == 'EN' ? 'Location' : 'Lokasi',
                                    color: const Color(0xFF10B981),
                                    items: _allLokasiFilter,
                                    idKey: 'id_lokasi',
                                    nameKey: 'nama_lokasi',
                                    selectedId: tempLokasiId,
                                    onReset: () => setInner(() {
                                      tempLokasiId = null; tempUnitId = null;
                                      tempSubunitId = null; tempAreaId = null;
                                    }),
                                    onSelect: (id, name) => setInner(() {
                                      tempLokasiId = id; tempUnitId = null;
                                      tempSubunitId = null; tempAreaId = null;
                                    }),
                                  ),
                                  if (tempLokasiId != null && filteredUnits.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildCascadeSection(
                                      label: 'Unit',
                                      color: const Color(0xFF6366F1),
                                      items: filteredUnits,
                                      idKey: 'id_unit',
                                      nameKey: 'nama_unit',
                                      selectedId: tempUnitId,
                                      onReset: () => setInner(() {
                                        tempUnitId = null; tempSubunitId = null; tempAreaId = null;
                                      }),
                                      onSelect: (id, name) => setInner(() {
                                        tempUnitId = id; tempSubunitId = null; tempAreaId = null;
                                      }),
                                    ),
                                  ],
                                  if (tempUnitId != null && filteredSubunits.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildCascadeSection(
                                      label: 'Sub-Unit',
                                      color: const Color(0xFFFBBF24),
                                      items: filteredSubunits,
                                      idKey: 'id_subunit',
                                      nameKey: 'nama_subunit',
                                      selectedId: tempSubunitId,
                                      onReset: () => setInner(() { tempSubunitId = null; tempAreaId = null; }),
                                      onSelect: (id, name) => setInner(() { tempSubunitId = id; tempAreaId = null; }),
                                    ),
                                  ],
                                  if (tempSubunitId != null && filteredAreas.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildCascadeSection(
                                      label: 'Area',
                                      color: const Color(0xFFF472B6),
                                      items: filteredAreas,
                                      idKey: 'id_area',
                                      nameKey: 'nama_area',
                                      selectedId: tempAreaId,
                                      onReset: () => setInner(() => tempAreaId = null),
                                      onSelect: (id, name) => setInner(() => tempAreaId = id),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Column(
                            children: [
                              _buildDialogOption(
                                label: _langCode == 'EN' ? 'All (No Filter)' : 'Semua (Tanpa Filter)',
                                isSelected: type == 'jabatan' ? _filterJabatanId == null : _sortOrder == 'none',
                                onTap: () {
                                  setState(() {
                                    if (type == 'jabatan') { _filterJabatanId = null; _filterJabatanName = null; }
                                    else { _sortOrder = 'none'; }
                                    _applyFilter();
                                  });
                                  Navigator.pop(ctx);
                                },
                              ),
                              if (type == 'jabatan') ...[
                                ..._jabatanList.map((jab) {
                                  final id = jab['id_jabatan'] as int;
                                  final nama = jab['nama_jabatan']?.toString() ?? '';
                                  return _buildDialogOption(
                                    label: nama,
                                    isSelected: _filterJabatanId == id,
                                    onTap: () {
                                      setState(() { _filterJabatanId = id; _filterJabatanName = nama; _applyFilter(); });
                                      Navigator.pop(ctx);
                                    },
                                  );
                                }),
                              ] else ...[
                                _buildDialogOption(
                                  label: _langCode == 'EN' ? 'A → Z (Ascending)' : 'A → Z (Ascending)',
                                  isSelected: _sortOrder == 'asc',
                                  onTap: () {
                                    setState(() { _sortOrder = 'asc'; _applyFilter(); });
                                    Navigator.pop(ctx);
                                  },
                                ),
                                _buildDialogOption(
                                  label: _langCode == 'EN' ? 'Z → A (Descending)' : 'Z → A (Descending)',
                                  isSelected: _sortOrder == 'desc',
                                  onTap: () {
                                    setState(() { _sortOrder = 'desc'; _applyFilter(); });
                                    Navigator.pop(ctx);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                ),

                // ── Apply button untuk lokasi ──
                if (type == 'lokasi')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Cari nama dari ID yang dipilih
                          final lokasiNama = _allLokasiFilter.firstWhere(
                            (l) => l['id_lokasi']?.toString() == tempLokasiId, orElse: () => {})['nama_lokasi']?.toString();
                          final unitNama = _allUnitFilter.firstWhere(
                            (u) => u['id_unit']?.toString() == tempUnitId, orElse: () => {})['nama_unit']?.toString();
                          final subNama = _allSubunitFilter.firstWhere(
                            (s) => s['id_subunit']?.toString() == tempSubunitId, orElse: () => {})['nama_subunit']?.toString();
                          final areaNama = _allAreaFilter.firstWhere(
                            (a) => a['id_area']?.toString() == tempAreaId, orElse: () => {})['nama_area']?.toString();

                          setState(() {
                            _filterLokasiId    = tempLokasiId;   _filterLokasiName   = lokasiNama;
                            _filterUnitId      = tempUnitId;     _filterUnitName     = unitNama;
                            _filterSubunitId   = tempSubunitId;  _filterSubunitName  = subNama;
                            _filterAreaId      = tempAreaId;     _filterAreaName     = areaNama;
                            _applyFilter();
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_langCode == 'EN' ? 'Apply' : 'Terapkan',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCascadeSection({
    required String label,
    required Color color,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required String? selectedId,
    required VoidCallback onReset,
    required void Function(String id, String name) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
            const Spacer(),
            if (selectedId != null)
              GestureDetector(
                onTap: onReset,
                child: Text(_langCode == 'EN' ? 'Reset' : 'Reset',
                  style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...items.map((item) {
              final id = item[idKey]?.toString() ?? '';
              final name = item[nameKey]?.toString() ?? '';
              final isSelected = selectedId == id;
              return GestureDetector(
                onTap: () => onSelect(id, name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(name, style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                  )),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDialogOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? _primary
                      : const Color(0xFF1E3A8A),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: _primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6366F1);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? primary : Colors.grey.shade200,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14, color: isActive ? Colors.white : primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}