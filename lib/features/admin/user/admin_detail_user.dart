import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminUserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final String lang;
  final int monthlyPoin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminUserDetailSheet({
    super.key,
    required this.user,
    required this.lang,
    required this.monthlyPoin,
    required this.onEdit,
    required this.onDelete,
  });

  static const _primary = Color(0xFF6366F1);

  static void show({
    required BuildContext context,
    required Map<String, dynamic> user,
    required String lang,
    required int monthlyPoin,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminUserDetailSheet(
        user: user,
        lang: lang,
        monthlyPoin: monthlyPoin,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
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

  String get _specificLocation {
    final areaName = user['area']?['nama_area'];
    final subunitName = user['subunit']?['nama_subunit'];
    final unitName = user['unit']?['nama_unit'];
    final lokasiName = user['lokasi']?['nama_lokasi'];
    if (areaName != null && areaName.toString().isNotEmpty) return areaName.toString();
    if (subunitName != null && subunitName.toString().isNotEmpty) return subunitName.toString();
    if (unitName != null && unitName.toString().isNotEmpty) return unitName.toString();
    if (lokasiName != null && lokasiName.toString().isNotEmpty) return lokasiName.toString();
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final name = user['nama'] ?? '-';
    final email = user['email'] ?? '-';
    final phone = user['phone'] ?? '-';
    final jabatan = user['jabatan']?['nama_jabatan'] ?? '-';
    final isVisitor = user['is_visitor'] == true;
    final isVerif = user['is_verificator'] == true;
    final avatarUrl = user['gambar_user'] as String?;
    final idUser = user['id_user'] ?? '-';

    return DraggableScrollableSheet(
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
            _buildHeader(context, name, email, jabatan, isVisitor, isVerif, avatarUrl),

            // SCROLLABLE CONTENT
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _buildSection(
                    lang == 'EN' ? 'Personal Information' : lang == 'ZH' ? '个人信息' : 'Informasi Pribadi',
                  ),
                  const SizedBox(height: 12),
                  _buildRow(Icons.badge_outlined,
                    lang == 'EN' ? 'User ID' : lang == 'ZH' ? '用户ID' : 'ID Pengguna',
                    idUser.toString(), const Color(0xFF6366F1), small: true),
                  _buildRow(Icons.phone_outlined,
                    lang == 'EN' ? 'Phone' : lang == 'ZH' ? '电话' : 'Telepon',
                    phone.toString().isEmpty || phone == '-' ? '-' : phone.toString(),
                    const Color(0xFF10B981)),
                  _buildRow(Icons.location_on_outlined,
                    lang == 'EN' ? 'Location' : lang == 'ZH' ? '位置' : 'Lokasi',
                    _specificLocation, const Color(0xFF0891B2)),
                  _buildRow(Icons.star_outline_rounded,
                    lang == 'EN' ? 'Points This Month' : lang == 'ZH' ? '本月积分' : 'Poin Bulan Ini',
                    '$monthlyPoin pts', const Color(0xFFF59E0B)),

                  const SizedBox(height: 16),
                  _buildSection(
                    lang == 'EN' ? 'Activity' : lang == 'ZH' ? '活动记录' : 'Aktivitas',
                  ),
                  const SizedBox(height: 12),
                  _buildRow(Icons.calendar_today_outlined,
                    lang == 'EN' ? 'Registered' : lang == 'ZH' ? '注册时间' : 'Terdaftar',
                    _formatDate(user['timestamp']), const Color(0xFF6366F1)),
                  _buildRow(Icons.login_rounded,
                    lang == 'EN' ? 'First Login' : lang == 'ZH' ? '首次登录' : 'Login Pertama',
                    _formatDate(user['first_login']), const Color(0xFF8B5CF6)),
                  _buildRow(Icons.access_time_rounded,
                    lang == 'EN' ? 'Last Login' : lang == 'ZH' ? '最后登录' : 'Login Terakhir',
                    _formatDate(user['log_login']), const Color(0xFF10B981)),

                  const SizedBox(height: 20),

                  // EDIT & DELETE BUTTON
                  Row(
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Spacer(),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: _primary.withValues(alpha:0.12),
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
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '$monthlyPoin',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                      Text(name,
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(email,
                          style: GoogleFonts.poppins(color: Colors.black45, fontSize: 12)),
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
          Divider(color: Colors.grey.shade100, thickness: 1.5, height: 1),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value, Color color, {bool small = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1E3A8A),
                        fontSize: small ? 11 : 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ],
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
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.25)),
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