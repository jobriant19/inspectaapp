import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _primary   = Color(0xFF0EA5E9);
const Color _dark      = Color(0xFF0C4A6E);
const Color _secondary = Color(0xFF64748B);
const Color _surface   = Color(0xFFF0F9FF);
const Color _border    = Color(0xFFBAE6FD);

class UserProfileModal extends StatefulWidget {
  final ScrollController controller;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int userRank;

  const UserProfileModal({
    super.key,
    required this.controller,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.userRank,
  });

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchUserDetail(String userId) async {
    final user = await Supabase.instance.client
        .from('User')
        .select('poin, jabatan(nama_jabatan), gambar_user, id_lokasi, id_unit, id_subunit, id_area')
        .eq('id_user', userId)
        .single();
    return user;
  }

  Color _medalColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFB0BEC5);
    if (rank == 3) return const Color(0xFFCD7F32);
    return _primary;
  }

  Color _tipeColor(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':         return const Color(0xFFEC4899);
      case 'login_harian':          return const Color(0xFF3B82F6);
      case 'login_pertama_hari_ini':return const Color(0xFFF59E0B);
      case 'penalti':               return const Color(0xFFEF4444);
      default: return isPositive    ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    }
  }

  IconData _tipeIcon(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':         return Icons.celebration_rounded;
      case 'login_harian':          return Icons.today_rounded;
      case 'login_pertama_hari_ini':return Icons.emoji_events_rounded;
      case 'penalti':               return Icons.warning_amber_rounded;
      default: return isPositive    ? Icons.star_rounded : Icons.remove_circle_outline_rounded;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inHours < 1)    return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1)     return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)     return '${diff.inDays} hari lalu';
    return DateFormat('d MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ──
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // ── Header user ──
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserDetail(widget.userId),
            builder: (context, snap) {
              final poin   = snap.data?['poin'] as int? ?? 0;
              final jabatan = snap.data?['jabatan']?['nama_jabatan'] as String? ?? '';
              return _buildHeader(poin, jabatan);
            },
          ),
          // ── Tab bar ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: _secondary,
              labelStyle: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'Log Aktivitas'),
                Tab(text: 'Temuan'),
                Tab(text: 'Penyelesaian'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityTab(),
                _buildListTab('temuan'),
                _buildListTab('penyelesaian'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int poin, String jabatan) {
    final rank = widget.userRank;
    final medalColor = _medalColor(rank);
    final isTop3 = rank <= 3;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTop3
              ? [_dark, _primary]
              : [_surface, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop3 ? medalColor.withOpacity(0.5) : _border,
          width: isTop3 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTop3
                ? medalColor.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isTop3 ? medalColor : _border,
                    width: isTop3 ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isTop3 ? medalColor : _primary).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: _primary.withOpacity(0.15),
                  backgroundImage: widget.userAvatarUrl != null
                      ? NetworkImage(widget.userAvatarUrl!)
                      : null,
                  child: widget.userAvatarUrl == null
                      ? Text(
                          widget.userName.trim().split(' ').take(2)
                              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                              .join(),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: _primary),
                        )
                      : null,
                ),
              ),
              // Medali badge
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isTop3 ? medalColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Text(
                    rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank',
                    style: TextStyle(
                      fontSize: rank <= 3 ? 12 : 9,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? Colors.white : _dark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: isTop3 ? Colors.white : _dark,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                if (jabatan.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    jabatan,
                    style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w500,
                      color: isTop3 ? Colors.white70 : _secondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                // Poin badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTop3
                        ? Colors.white.withOpacity(0.2)
                        : _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isTop3
                          ? Colors.white.withOpacity(0.4)
                          : _primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 14,
                          color: isTop3 ? Colors.amber : _primary),
                      const SizedBox(width: 4),
                      Text(
                        '$poin Poin',
                        style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: isTop3 ? Colors.white : _primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rank besar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isTop3
                  ? medalColor.withOpacity(0.25)
                  : _surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isTop3 ? medalColor.withOpacity(0.6) : _border,
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  fontSize: rank >= 10 ? 12 : 14,
                  fontWeight: FontWeight.w900,
                  color: isTop3 ? Colors.white : _dark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Log Aktivitas — sinkron dengan NotificationScreen ────────────────
  Widget _buildActivityTab() {
    return FutureBuilder<List<dynamic>>(
      future: Supabase.instance.client
          .from('log_poin')
          .select('poin, deskripsi, tipe_aktivitas, created_at')
          .eq('id_user', widget.userId)
          .order('created_at', ascending: false)
          .limit(50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmpty('Belum ada aktivitas', Icons.history_rounded);
        }

        final logs = snapshot.data!;
        // ✅ Total poin dari User.poin — fetch terpisah
        return FutureBuilder<int>(
          future: Supabase.instance.client
              .from('User')
              .select('poin')
              .eq('id_user', widget.userId)
              .single()
              .then((r) => (r['poin'] as int?) ?? 0),
          builder: (context, poinSnap) {
            final totalPoin = poinSnap.data ?? 0;

            return Column(
              children: [
                // ✅ Summary card — sama persis dengan NotificationScreen
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.25),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Total Poin',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.white70)),
                      Text('$totalPoin Poin',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ]),
                    const Spacer(),
                    Text('${logs.length} log',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.white60)),
                  ]),
                ),
                // List log
                Expanded(
                  child: ListView.separated(
                    controller: widget.controller,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildLogCard(logs[i]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Log card — format sinkron dengan NotificationScreen ──────────────────
  Widget _buildLogCard(Map<String, dynamic> log) {
    final int poin      = (log['poin'] as num).toInt();
    final bool isPos    = poin >= 0;
    final String tipe   = (log['tipe_aktivitas'] ?? '').toString();
    final String desc   = (log['deskripsi'] ?? '').toString();
    final String date   = _formatDate(log['created_at']);
    final Color color   = _tipeColor(tipe, isPos);
    final IconData icon = _tipeIcon(tipe, isPos);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A), height: 1.4)),
                const SizedBox(height: 2),
                Text(date,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Text(
              isPos ? '+$poin' : '$poin',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Temuan & Penyelesaian ─────────────────────────────────────────────
  Widget _buildListTab(String type) {
    late final Future<List<dynamic>> future;

    if (type == 'temuan') {
      future = Supabase.instance.client
          .from('temuan')
          .select('*, lokasi(*), area(*)')
          .eq('id_user', widget.userId)
          .order('created_at', ascending: false);
    } else {
      future = Supabase.instance.client
          .from('penyelesaian')
          .select('*, temuan!inner(*, lokasi(*), area(*))')
          .eq('id_user', widget.userId)
          .order('tanggal_selesai', ascending: false);
    }

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }
        if (snapshot.hasError) {
          return _buildEmpty('Gagal memuat data', Icons.error_outline);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmpty(
            type == 'temuan' ? 'Belum ada temuan' : 'Belum ada penyelesaian',
            type == 'temuan'
                ? Icons.search_off_rounded
                : Icons.check_circle_outline_rounded,
          );
        }

        return ListView.separated(
          controller: widget.controller,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final item = snapshot.data![i];
            String? title, location, imageUrl;
            DateTime? date;

            if (type == 'temuan') {
              title    = item['judul_temuan'];
              location = item['lokasi']?['nama_lokasi'] ?? item['area']?['nama_area'];
              imageUrl = item['gambar_temuan'];
              date     = DateTime.tryParse(item['created_at'] ?? '');
            } else {
              final temuanList = item['temuan'] as List<dynamic>?;
              final temuanData = (temuanList != null && temuanList.isNotEmpty)
                  ? temuanList.first as Map<String, dynamic>
                  : null;
              title    = temuanData?['judul_temuan'];
              location = temuanData?['lokasi']?['nama_lokasi']
                  ?? temuanData?['area']?['nama_area'];
              imageUrl = item['gambar_penyelesaian'];
              date     = DateTime.tryParse(item['tanggal_selesai'] ?? '');
            }

            return _buildItemCard(
              title: title ?? 'Tanpa Judul',
              location: location ?? 'Lokasi tidak diketahui',
              imageUrl: imageUrl,
              date: date,
              type: type,
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard({
    required String title,
    required String location,
    String? imageUrl,
    DateTime? date,
    required String type,
  }) {
    final Color accent = type == 'temuan'
        ? const Color(0xFF0EA5E9)
        : const Color(0xFF16A34A);
    final IconData typeIcon = type == 'temuan'
        ? Icons.search_rounded
        : Icons.check_circle_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Gambar
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(15)),
            child: SizedBox(
              width: 80, height: 90,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(accent))
                  : _imagePlaceholder(accent),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A), height: 1.3)),
                  const SizedBox(height: 5),
                  Row(children: [
                    Icon(Icons.place_rounded,
                        size: 11, color: _secondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 10.5, color: _secondary)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 10, color: accent),
                          const SizedBox(width: 3),
                          Text(
                            type == 'temuan' ? 'Temuan' : 'Selesai',
                            style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: accent),
                          ),
                        ],
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(date),
                        style: GoogleFonts.poppins(
                            fontSize: 9.5, color: Colors.grey.shade400),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(Color accent) {
    return Container(
      color: accent.withOpacity(0.08),
      child: Icon(Icons.image_outlined,
          color: accent.withOpacity(0.4), size: 28),
    );
  }

  Widget _buildEmpty(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primary.withOpacity(0.08),
            ),
            child: Icon(icon, color: _primary.withOpacity(0.4), size: 30),
          ),
          const SizedBox(height: 12),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: _secondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}