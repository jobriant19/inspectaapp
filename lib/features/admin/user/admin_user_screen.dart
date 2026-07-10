import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'admin_add_user.dart';
import 'admin_delete_user.dart';
import 'admin_detail_user.dart';
import 'admin_edit_user.dart';
import 'filter/admin_user_filter.dart';

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

  // FILTER STATE
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

  String? get _activeLocationLevel {
    if (_filterAreaId != null) return 'Area';
    if (_filterSubunitId != null) return 'Subunit';
    if (_filterUnitId != null) return 'Unit';
    if (_filterLokasiId != null) return 'Lokasi';
    return null;
  }

  String? get _activeLocationId {
    if (_filterAreaId != null) return _filterAreaId;
    if (_filterSubunitId != null) return _filterSubunitId;
    if (_filterUnitId != null) return _filterUnitId;
    if (_filterLokasiId != null) return _filterLokasiId;
    return null;
  }

  String? get _activeLocationChipLabel {
    if (_filterAreaName != null) return _filterAreaName;
    if (_filterSubunitName != null) return _filterSubunitName;
    if (_filterUnitName != null) return _filterUnitName;
    if (_filterLokasiName != null) return _filterLokasiName;
    return null;
  }

  final Map<String, int> _monthlyPoints = {};
  Map<String, String> _sectionNameMap = {};

  static const _primary = Color(0xFF6366F1);
  static const _bg = Color(0xFFF8FAFC);
  static const _appBarColor = Color(0xFF6366F1);
  static const _appBarFg = Colors.white;

  String get _langCode => widget.lang;

  @override
  void initState() {
    super.initState();
    _loadSectionNameMap();
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
      ]);

      if (mounted) {
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
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSectionNameMap() async {
    try {
      final res = await Supabase.instance.client
          .from('section')
          .select('nama_section_id, nama_section_en, nama_section_zh');
      final rows = List<Map<String, dynamic>>.from(res);
      final map = <String, String>{};
      for (final r in rows) {
        final idName = (r['nama_section_id'] as String?)?.trim();
        if (idName == null || idName.isEmpty) continue;
        map[idName.toLowerCase()] = idName;
        final enName = (r['nama_section_en'] as String?)?.trim();
        if (enName != null && enName.isNotEmpty) map[enName.toLowerCase()] = idName;
        final zhName = (r['nama_section_zh'] as String?)?.trim();
        if (zhName != null && zhName.isNotEmpty) map[zhName.toLowerCase()] = idName;
      }
      if (mounted) setState(() => _sectionNameMap = map);
    } catch (e) {
      debugPrint('loadSectionNameMap error: $e');
    }
  }

  String _resolveSectionName(String raw) {
    final key = raw.trim().toLowerCase();
    return _sectionNameMap[key] ?? raw.trim();
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
    AdminUserDetailSheet.show(
      context: context,
      user: user,
      lang: widget.lang,
      monthlyPoin: _monthlyPoints[user['id_user']?.toString() ?? ''] ?? 0,
      onEdit: () => _showUserDialog(user: user),
      onDelete: () => _deleteUser(user['id_user'], user['nama'] ?? '-'),
    );
  }

  // ADD & EDIT USER
  void _showUserDialog({Map<String, dynamic>? user}) {
    if (user == null) {
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
        shadowColor: Colors.black.withValues(alpha:0.08),
        title: Text(
          _langCode == 'EN'
              ? 'User Management'
              : _langCode == 'ZH'
                  ? '用户管理'
                  : 'Kelola Pengguna',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
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
          // FILTER BUTTONS + ADD USER BUTTON
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: _buildFilterButtons(),
                ),
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
                            color: _primary.withValues(alpha:0.35),
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
                              color: Colors.white.withValues(alpha:0.25),
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
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha:0.85)),
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
          // ACTIVE FILTER CHIPS
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
                  if (_activeLocationChipLabel != null)
                    _buildActiveFilterChip('📍 $_activeLocationChipLabel',
                      () => setState(() {
                        _filterLokasiId = null; _filterLokasiName = null;
                        _filterUnitId = null; _filterUnitName = null;
                        _filterSubunitId = null; _filterSubunitName = null;
                        _filterAreaId = null; _filterAreaName = null;
                        _applyFilter();
                      })),
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
          // USER LIST
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
        border: Border.all(color: Colors.black.withValues(alpha:0.08)),
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

    // ROLE COLORS
    Color roleColor = const Color(0xFF6366F1);
    final idJabatan = user['id_jabatan'];
    if (idJabatan == 1) roleColor = const Color(0xFFDC2626); // Eksekutif
    if (idJabatan == 2) roleColor = const Color(0xFF7C3AED); // Manager
    if (idJabatan == 3) roleColor = const Color(0xFF0891B2); // Kasie
    if (idJabatan == 6) roleColor = const Color(0xFF059669); // Admin

    final bool isKasie = idJabatan == 3;
    final String bagianKasieRaw = (user['bagian_kasie'] as String?)?.trim() ?? '';
    final String bagianKasieName = bagianKasieRaw.isEmpty ? '' : _resolveSectionName(bagianKasieRaw);

    return GestureDetector(
      onTap: () => _showUserDetail(user),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha:0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // AVATAR
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: roleColor.withValues(alpha:0.12),
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
              // POINT BADGE
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

          // INFO
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
                // LINE 1: ROLE + VISITOR/VERIF BADGE
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
                // LINE 2: SPESIFIC LOCATION
                if (specificLocation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildChip(
                    specificLocation,
                    _locationChipColor(user),
                    Icons.location_on_outlined,
                  ),
                ],
                // LINE 3: KASIE SECTION
                if (isKasie && bagianKasieName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildChip(
                    bagianKasieName,
                    const Color(0xFF0891B2),
                    Icons.apartment_outlined,
                  ),
                ],
              ],
            ),
          ),

          // ACTION BUTTON
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
    if (user['area']?['nama_area'] != null &&
        (user['area']!['nama_area'] as String).isNotEmpty) {
      return const Color(0xFFF472B6);
    }
    if (user['subunit']?['nama_subunit'] != null &&
        (user['subunit']!['nama_subunit'] as String).isNotEmpty) {
      return const Color(0xFFFBBF24);
    }
    if (user['unit']?['nama_unit'] != null &&
        (user['unit']!['nama_unit'] as String).isNotEmpty) {
      return const Color(0xFF6366F1);
    }
    return const Color(0xFF10B981);
  }

  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.25)),
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
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha:0.18)),
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
              color: _primary.withValues(alpha:0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline,
                size: 56, color: _primary.withValues(alpha:0.4)),
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
        color: _primary.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha:0.3)),
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
            icon: Icons.map,
            isActive: hasLokasiFilter,
            onTap: _openLocationFilter,
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
            onTap: _openRoleFilter,
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
            onTap: _openSortFilter,
          ),
        ),
      ],
    );
  }

  Future<void> _openLocationFilter() async {
    final result = await showAdminUserLocationFilterDialog(
      context,
      lang: widget.lang,
      initialLevel: _activeLocationLevel,
      initialId: _activeLocationId,
    );
    if (result == null) return;
    final level = result['level'];
    final id = result['id'];
    final name = result['name'];
    setState(() {
      // reset semua level dulu, karena hanya 1 level filter aktif
      _filterLokasiId = null; _filterLokasiName = null;
      _filterUnitId = null; _filterUnitName = null;
      _filterSubunitId = null; _filterSubunitName = null;
      _filterAreaId = null; _filterAreaName = null;

      if (id != null) {
        switch (level) {
          case 'Unit':
            _filterUnitId = id; _filterUnitName = name;
            break;
          case 'Subunit':
            _filterSubunitId = id; _filterSubunitName = name;
            break;
          case 'Area':
            _filterAreaId = id; _filterAreaName = name;
            break;
          default:
            _filterLokasiId = id; _filterLokasiName = name;
        }
      }
      _applyFilter();
    });
  }

  Future<void> _openRoleFilter() async {
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

  Future<void> _openSortFilter() async {
    final result = await showAdminUserSortFilterDialog(
      context,
      lang: widget.lang,
      currentSort: _sortOrder,
    );
    if (result == null) return;
    setState(() {
      _sortOrder = result;
      _applyFilter();
    });
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
                    color: primary.withValues(alpha:0.2),
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