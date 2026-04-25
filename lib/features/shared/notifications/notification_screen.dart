import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../user/finding/finding_detail_screen.dart';
import '../../user/home/finding_card.dart';

class NotificationScreen extends StatefulWidget {
  final String lang;
  const NotificationScreen({super.key, required this.lang});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'title': 'Notifications',
      'tab_findings': 'Assigned Findings',
      'tab_activity': 'Activity Log',
      'empty_findings': 'No assigned findings',
      'empty_findings_sub': 'Findings assigned to you will appear here.',
      'empty_activity': 'No activity yet',
      'empty_activity_sub': 'Your point history will appear here.',
      'status_done': 'Completed',
      'status_pending': 'Pending',
      'points': 'Points',
      'total_points': 'Total Points',
    },
    'ID': {
      'title': 'Notifikasi',
      'tab_findings': 'Temuan Ditugaskan',
      'tab_activity': 'Log Aktivitas',
      'empty_findings': 'Tidak ada temuan ditugaskan',
      'empty_findings_sub': 'Temuan yang ditugaskan ke Anda akan muncul di sini.',
      'empty_activity': 'Belum ada aktivitas',
      'empty_activity_sub': 'Riwayat poin Anda akan muncul di sini.',
      'status_done': 'Selesai',
      'status_pending': 'Belum Selesai',
      'points': 'Poin',
      'total_points': 'Total Poin',
    },
    'ZH': {
      'title': '通知',
      'tab_findings': '已分配发现',
      'tab_activity': '活动日志',
      'empty_findings': '没有分配的发现',
      'empty_findings_sub': '分配给您的发现将显示在此处。',
      'empty_activity': '暂无活动',
      'empty_activity_sub': '您的积分历史将显示在此处。',
      'status_done': '完成',
      'status_pending': '待处理',
      'points': '积分',
      'total_points': '总积分',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getTipeColor(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama': return const Color(0xFFEC4899);
      case 'login_harian': return const Color(0xFF3B82F6);
      case 'login_pertama_hari_ini': return const Color(0xFFF59E0B);
      case 'penalti': return const Color(0xFFEF4444);
      default: return isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    }
  }

  IconData _getTipeIcon(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama': return Icons.celebration_rounded;
      case 'login_harian': return Icons.today_rounded;
      case 'login_pertama_hari_ini': return Icons.emoji_events_rounded;
      case 'penalti': return Icons.warning_amber_rounded;
      default: return isPositive ? Icons.star_rounded : Icons.remove_circle_outline_rounded;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          // ── HEADER TETAP (tidak ikut scroll) ──
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // AppBar custom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                size: 18, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _t('title'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), // balancer
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // TabBar tetap
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      tabAlignment: TabAlignment.fill,
                      indicator: BoxDecoration(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF0EA5E9),
                      labelStyle: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w500),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.assignment_ind_outlined, size: 15),
                              const SizedBox(width: 5),
                              Text(_t('tab_findings')),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_rounded, size: 15),
                              const SizedBox(width: 5),
                              Text(_t('tab_activity')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── KONTEN SCROLLABLE ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssignedFindingsTab(),
                _buildActivityLogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 1: Temuan yang ditugaskan ──
  Widget _buildAssignedFindingsTab() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return _buildEmpty(
        _t('empty_findings'),
        _t('empty_findings_sub'),
        Icons.assignment_ind_outlined,
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: Supabase.instance.client
          .from('temuan')
          .select(
            'id_temuan, judul_temuan, gambar_temuan, created_at, '
            'status_temuan, poin_temuan, target_waktu_selesai, '
            'jenis_temuan, id_lokasi, id_unit, id_subunit, id_area, '
            'id_penanggung_jawab, is_pro, is_visitor, is_eksekutif, '
            'lokasi(nama_lokasi), unit(nama_unit), '
            'subunit(nama_subunit), area(nama_area)',
          )
          .eq('id_penanggung_jawab', userId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmpty(
            _t('empty_findings'),
            _t('empty_findings_sub'),
            Icons.assignment_ind_outlined,
          );
        }

        final items =
            List<Map<String, dynamic>>.from(snapshot.data!);

        final pendingCount = items.where((e) {
          final s =
              (e['status_temuan'] ?? '').toString().toLowerCase();
          return !['selesai', 'done', 'completed', 'closed']
              .any((x) => s.contains(x));
        }).length;

        return Column(
          children: [
            // Banner pending — tetap di atas, tidak scroll
            if (pendingCount > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFFDC2626).withOpacity(0.08),
                    const Color(0xFFEF4444).withOpacity(0.05),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.pending_actions_rounded,
                      color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.lang == 'ID'
                          ? '$pendingCount temuan masih menunggu penyelesaian Anda'
                          : '$pendingCount findings are waiting for your action',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ]),
              ),

            // List scrollable
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return FindingCard(
                    data: item,
                    lang: widget.lang,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FindingDetailScreen(
                            initialData: item,
                            lang: widget.lang,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── TAB 2: Activity Log ──
  Widget _buildActivityLogTab() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return _buildEmpty(
        _t('empty_activity'),
        _t('empty_activity_sub'),
        Icons.history_rounded,
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        Supabase.instance.client
            .from('User')
            .select('poin')
            .eq('id_user', userId)
            .single(),
        Supabase.instance.client
            .from('log_poin')
            .select('poin, deskripsi, tipe_aktivitas, created_at')
            .eq('id_user', userId)
            .order('created_at', ascending: false)
            .limit(50),
      ]).then((results) => {
            'userPoin': results[0],
            'logs': results[1],
          }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        }
        if (!snapshot.hasData) {
          return _buildEmpty(
            _t('empty_activity'),
            _t('empty_activity_sub'),
            Icons.history_rounded,
          );
        }

        final int actualPoin =
            (snapshot.data!['userPoin'] as Map<String, dynamic>)['poin']
                    as int? ??
                0;
        final List<dynamic> logs =
            snapshot.data!['logs'] as List<dynamic>;

        if (logs.isEmpty) {
          return _buildEmpty(
            _t('empty_activity'),
            _t('empty_activity_sub'),
            Icons.history_rounded,
          );
        }

        return Column(
          children: [
            // Summary card — tetap di atas, tidak scroll
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('total_points'),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.white70)),
                    Text(
                      '$actualPoin ${_t('points')}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text('${logs.length} log',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white60)),
              ]),
            ),

            // List scrollable
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: logs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildActivityLogCard(
                        logs[index] as Map<String, dynamic>),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityLogCard(Map<String, dynamic> log) {
    final int poin = (log['poin'] as num).toInt();
    final bool isPositive = poin >= 0;
    final String tipe = (log['tipe_aktivitas'] ?? '').toString();
    final String desc = (log['deskripsi'] ?? '').toString();
    final String tanggal = _formatDate(log['created_at']);
    final Color color = _getTipeColor(tipe, isPositive);
    final IconData icon = _getTipeIcon(tipe, isPositive);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          // Deskripsi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A), height: 1.4)),
                const SizedBox(height: 3),
                Text(tanggal, style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade400)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Poin badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              isPositive ? '+$poin' : '$poin',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00C9E4).withOpacity(0.08)),
            child: Icon(icon, size: 36, color: const Color(0xFF00C9E4).withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}