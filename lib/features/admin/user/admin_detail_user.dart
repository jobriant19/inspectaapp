import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminUserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final String lang;
  final int monthlyPoin;
  final Map<String, dynamic>? supervisor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminUserDetailSheet({
    super.key,
    required this.user,
    required this.lang,
    required this.monthlyPoin,
    this.supervisor,
    required this.onEdit,
    required this.onDelete,
  });

  static const _primary = Color(0xFF6366F1);

  static void show({
    required BuildContext context,
    required Map<String, dynamic> user,
    required String lang,
    required int monthlyPoin,
    Map<String, dynamic>? supervisor,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailSheet(
          user: user,
          lang: lang,
          monthlyPoin: monthlyPoin,
          supervisor: supervisor,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }

  String _formatDateLocalized(dynamic raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final months = lang == 'EN'
          ? const [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ]
          : lang == 'ZH'
              ? const [
                  '一月', '二月', '三月', '四月', '五月', '六月',
                  '七月', '八月', '九月', '十月', '十一月', '十二月'
                ]
              : const [
                  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                ];
      final monthName = months[dt.month - 1];
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $monthName ${dt.year}  $hh:$mm';
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (user['nama'] ?? '-').toString();
    final email = (user['email'] ?? '-').toString();
    final phone = (user['phone'] ?? '-').toString();
    final jabatan = (user['jabatan']?['nama_jabatan'] ?? '-').toString();
    final isVisitor = user['is_visitor'] == true;
    final isVerif = user['is_verificator'] == true;
    final avatarUrl = user['gambar_user'] as String?;
    final idUser = (user['id_user'] ?? '-').toString();

    final idJabatan = user['id_jabatan'] as int?;
    final isKasie = idJabatan == 3;
    final bagianKasie = (user['bagian_kasie'] as String?)?.trim() ?? '';

    final namaLokasi = user['lokasi']?['nama_lokasi']?.toString();
    final namaUnit = user['unit']?['nama_unit']?.toString();
    final namaSubunit = user['subunit']?['nama_subunit']?.toString();
    final namaArea = user['area']?['nama_area']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          'Admin User Detail',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _primary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(context, name, email, jabatan, isVisitor, isVerif, avatarUrl),

          // SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PERSONAL INFORMATION
                  _buildSectionLabel(
                    lang == 'EN'
                        ? 'Personal Information'
                        : lang == 'ZH'
                            ? '个人信息'
                            : 'Informasi Pribadi',
                    Icons.person_outline,
                    _primary,
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                    lang == 'EN' ? 'User ID' : lang == 'ZH' ? '用户ID' : 'ID Pengguna',
                    Icons.badge_outlined,
                  ),
                  const SizedBox(height: 6),
                  _buildPlainField(idUser),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                    lang == 'EN' ? 'Phone' : lang == 'ZH' ? '电话' : 'Telepon',
                    Icons.phone_outlined,
                  ),
                  const SizedBox(height: 6),
                  _buildPlainField(phone.isEmpty || phone == '-' ? '-' : phone),

                  if (isKasie && bagianKasie.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildFieldLabel(
                      lang == 'EN'
                          ? 'Kasie Section'
                          : lang == 'ZH'
                              ? '科长部门'
                              : 'Bagian Kasie',
                      Icons.apartment_outlined,
                    ),
                    const SizedBox(height: 6),
                    _buildIconField(bagianKasie, Icons.apartment_outlined, const Color(0xFF0891B2)),
                  ],

                  const SizedBox(height: 20),

                  // LOCATION ASSIGNMENT
                  _buildSectionLabel(
                    lang == 'EN'
                        ? 'Location Assignment'
                        : lang == 'ZH'
                            ? '位置分配'
                            : 'Penempatan Lokasi',
                    Icons.map,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                    lang == 'EN' ? 'Location' : lang == 'ZH' ? '位置' : 'Lokasi',
                    Icons.location_city_rounded,
                  ),
                  const SizedBox(height: 6),
                  _buildIconField(namaLokasi, Icons.location_city_rounded, const Color(0xFF10B981)),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Unit', Icons.business_rounded),
                  const SizedBox(height: 6),
                  _buildIconField(namaUnit, Icons.business_rounded, _primary),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Sub-Unit', Icons.layers_rounded),
                  const SizedBox(height: 6),
                  _buildIconField(namaSubunit, Icons.layers_rounded, const Color(0xFFFBBF24)),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Area', Icons.place_rounded),
                  const SizedBox(height: 6),
                  _buildIconField(namaArea, Icons.place_rounded, const Color(0xFFF472B6)),

                  const SizedBox(height: 20),

                  // SUPERVISOR
                  _buildSectionLabel(
                    lang == 'EN'
                        ? 'Supervisor'
                        : lang == 'ZH'
                            ? '主管'
                            : 'Supervisor',
                    Icons.manage_accounts_outlined,
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),
                  _buildSupervisorField(),

                  const SizedBox(height: 20),

                  // ROLE & ACCESS 
                  _buildSectionLabel(
                    lang == 'EN'
                        ? 'Role & Access'
                        : lang == 'ZH'
                            ? '角色与权限'
                            : 'Peran & Akses',
                    Icons.shield_outlined,
                    const Color(0xFF0891B2),
                  ),
                  const SizedBox(height: 12),

                  _buildStaticToggleRow(
                    lang == 'EN' ? 'Visitor Mode' : lang == 'ZH' ? '访客模式' : 'Mode Pengunjung',
                    Icons.visibility_outlined,
                    isVisitor,
                    const Color(0xFF0891B2),
                  ),
                  const SizedBox(height: 10),
                  _buildStaticToggleRow(
                    lang == 'EN' ? 'Verificator' : lang == 'ZH' ? '验证员' : 'Verifikator',
                    Icons.verified_user_outlined,
                    isVerif,
                    const Color(0xFFF59E0B),
                  ),

                  const SizedBox(height: 20),

                  // ACTIVITY
                  _buildSectionLabel(
                    lang == 'EN' ? 'Activity' : lang == 'ZH' ? '活动记录' : 'Aktivitas',
                    Icons.history_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                    lang == 'EN' ? 'Registered' : lang == 'ZH' ? '注册时间' : 'Terdaftar',
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 6),
                  _buildIconField(_formatDateLocalized(user['timestamp']), Icons.calendar_today_outlined, _primary),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                    lang == 'EN' ? 'First Login' : lang == 'ZH' ? '首次登录' : 'Login Pertama',
                    Icons.login_rounded,
                  ),
                  const SizedBox(height: 6),
                  _buildIconField(_formatDateLocalized(user['first_login']), Icons.login_rounded, const Color(0xFF8B5CF6)),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                    lang == 'EN' ? 'Last Login' : lang == 'ZH' ? '最后登录' : 'Login Terakhir',
                    Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 6),
                  _buildIconField(_formatDateLocalized(user['log_login']), Icons.access_time_rounded, const Color(0xFF10B981)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // STICKY FOOTER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                    label: Text(
                      lang == 'EN' ? 'Edit' : lang == 'ZH' ? '编辑' : 'Edit',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
                    label: Text(
                      lang == 'EN' ? 'Delete' : lang == 'ZH' ? '删除' : 'Hapus',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String email,
    String jabatan,
    bool isVisitor,
    bool isVerif,
    String? avatarUrl,
  ) {
    final heroTag = 'admin_user_avatar_${user['id_user']}';

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          children: [
            Hero(
              tag: heroTag,
              child: GestureDetector(
                onTap: avatarUrl != null
                    ? () => _openAvatarImageViewer(context, avatarUrl, heroTag)
                    : null,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: _primary.withValues(alpha: 0.12),
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            color: _primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAME
                  Text(name,
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                  const SizedBox(height: 6),
                  // EMAIL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email_outlined, size: 12, color: Color(0xFF475569)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            email,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF475569),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildChip(jabatan, _primary, Icons.work_outline),
                      if (isVisitor)
                        _buildChip(
                          lang == 'EN' ? 'Visitor' : lang == 'ZH' ? '访客' : 'Pengunjung',
                          const Color(0xFF0891B2), Icons.visibility_outlined),
                      if (isVerif)
                        _buildChip(
                          lang == 'EN' ? 'Verificator' : lang == 'ZH' ? '验证员' : 'Verifikator',
                          const Color(0xFFF59E0B), Icons.verified_user_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAvatarImageViewer(BuildContext context, String url, String heroTag) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _ProfileImageViewer(imageUrl: url, heroTag: heroTag),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D72F3),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: _primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPlainField(String value) {
    return Container(
      width: double.infinity,
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.3),
      ),
      child: Text(
        value,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildIconField(String? value, IconData icon, Color color) {
    final hasValue = value != null && value.isNotEmpty && value != '-';
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: hasValue ? color.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue ? color.withValues(alpha: 0.5) : const Color(0xFFCBD5E1),
          width: hasValue ? 1.4 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: hasValue ? color : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: hasValue ? Colors.white : color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasValue ? value : '-',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                color: hasValue ? color : Colors.black38,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorField() {
    const supColor = Color(0xFF8B5CF6);

    if (supervisor == null) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: supColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.person_search_outlined, size: 15, color: supColor),
            ),
            const SizedBox(width: 12),
            Text('-',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black38)),
          ],
        ),
      );
    }

    final supName = (supervisor!['nama'] ?? '-').toString();
    final supRole = (supervisor!['jabatan']?['nama_jabatan'] ?? '-').toString();
    final supAvatar = supervisor!['gambar_user'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: supColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: supColor.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: supColor,
            backgroundImage: supAvatar != null ? CachedNetworkImageProvider(supAvatar) : null,
            child: supAvatar == null
                ? Text(supName.isNotEmpty ? supName[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supName,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700, color: supColor)),
                const SizedBox(height: 4),
                _buildChip(supRole, supColor, Icons.badge_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticToggleRow(String label, IconData icon, bool value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.25) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: value ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: value ? color : Colors.grey.shade400, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: value ? const Color(0xFF1E3A8A) : Colors.black45,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IgnorePointer(
            child: Switch(
              value: value,
              onChanged: (_) {},
              activeColor: color,
              activeTrackColor: color.withValues(alpha: 0.25),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _ProfileImageViewer({required this.imageUrl, required this.heroTag});

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
                child: Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
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