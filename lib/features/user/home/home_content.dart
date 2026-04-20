import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'location_screen.dart';
import '../ktsproduksi/kts_produksi_screen.dart';
import '../accident/accident_report_screen.dart';
import 'finding_card.dart';

class HomeContent extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;
  final bool isUserDataLoading;
  final String userName;
  final String userRole;
  final String userLocationName;
  final int userPoin;
  final int displayedPoin;
  final String? userImage;
  final int? userUnitId;
  final int? userLokasiId;
  final Map<String, dynamic>? latestLogPoin;
  final bool isLatestLogLoading;
  final VoidCallback onRefresh;
  final VoidCallback onViewActivityLog;
  final Function(bool) onProModeChanged;
  final Function(bool) onVisitorModeChanged;
  final Widget Function() buildInfoCard;

  const HomeContent({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.isVisitorMode,
    required this.isUserDataLoading,
    required this.userName,
    required this.userRole,
    required this.userLocationName,
    required this.userPoin,
    required this.displayedPoin,
    required this.onRefresh,
    required this.onViewActivityLog,
    required this.onProModeChanged,
    required this.onVisitorModeChanged,
    required this.buildInfoCard,
    this.userImage,
    this.userUnitId,
    this.userLokasiId,
    this.latestLogPoin,
    this.isLatestLogLoading = false,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String _activeTab = 'my';

  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'inspeksi': 'Inspection',
      'pro_mode': 'Professional Mode',
      'visitor_mode': 'Visitor Mode',
      'laporan_cepat': 'Quick Report',
      'telusur': 'Browse & Manage',
      'lokasi': 'Location',
      'laporan': 'Accident Report',
      'recent_findings': 'Recent Findings',
      'kts_produksi': 'Production KTS',
      'tab_my': 'My Findings',
      'tab_assigned': 'Assigned to Me',
      'tab_resolved': 'Resolved by Me',
      'no_findings_title': 'No Recent Findings',
      'no_findings_subtitle': 'Recent findings you create or are involved in will appear here.',
    },
    'ID': {
      'inspeksi': 'Inspeksi',
      'pro_mode': 'Mode Profesional',
      'visitor_mode': 'Mode Pengunjung',
      'laporan_cepat': 'Laporan Cepat',
      'telusur': 'Telusur & Atur',
      'lokasi': 'Lokasi',
      'laporan': 'Laporan Kecelakaan',
      'recent_findings': 'Temuan Terbaru',
      'kts_produksi': 'KTS Produksi',
      'tab_my': 'Temuan Saya',
      'tab_assigned': 'Ditugaskan ke Saya',
      'tab_resolved': 'Diselesaikan Saya',
      'no_findings_title': 'Belum Ada Temuan',
      'no_findings_subtitle': 'Temuan terbaru yang Anda buat atau terlibat di dalamnya akan muncul di sini.',
    },
    'ZH': {
      'inspeksi': '检查',
      'pro_mode': '专业模式',
      'visitor_mode': '访客模式',
      'laporan_cepat': '快速报告',
      'telusur': '浏览与管理',
      'lokasi': '地点',
      'laporan': '事故报告',
      'recent_findings': '最新发现',
      'kts_produksi': '生产KTS',
      'tab_my': '我的发现',
      'tab_assigned': '分配给我',
      'tab_resolved': '我已解决',
      'no_findings_title': '暂无最新发现',
      'no_findings_subtitle': '您创建或参与的最新发现将显示在此处。',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  Widget _buildTabChip(String tabKey, String label) {
    final bool isActive = _activeTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00C9E4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF00C9E4) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF00C9E4).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? Colors.white : Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildFindingsTab() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const SizedBox();

    Future<List<Map<String, dynamic>>> future;
    if (_activeTab == 'my') {
      future = Supabase.instance.client
          .from('temuan')
          .select('id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan, poin_temuan, target_waktu_selesai, id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), is_pro, is_visitor, is_eksekutif')
          .eq('id_user', userId)
          .order('created_at', ascending: false)
          .limit(10)
          .then((v) => List<Map<String, dynamic>>.from(v));
    } else if (_activeTab == 'assigned') {
      future = Supabase.instance.client
          .from('temuan')
          .select('id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan, poin_temuan, target_waktu_selesai, id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), is_pro, is_visitor, is_eksekutif')
          .eq('id_penanggung_jawab', userId)
          .order('created_at', ascending: false)
          .limit(10)
          .then((v) => List<Map<String, dynamic>>.from(v));
    } else {
      future = Supabase.instance.client
          .from('penyelesaian')
          .select('id_penyelesaian, temuan(id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan, poin_temuan, target_waktu_selesai, id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), is_pro, is_visitor, is_eksekutif)')
          .eq('id_user', userId)
          .order('tanggal_selesai', ascending: false)
          .limit(10)
          .then((v) {
            final List<Map<String, dynamic>> result = [];
            for (final item in v) {
              final temuanRaw = item['temuan'];
              if (temuanRaw == null) continue;
              if (temuanRaw is List && temuanRaw.isNotEmpty) {
                result.add(Map<String, dynamic>.from(temuanRaw.first));
              } else if (temuanRaw is Map) {
                result.add(Map<String, dynamic>.from(temuanRaw));
              }
            }
            return result;
          });
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRecentFindingsLoader();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  Image.asset('assets/images/team_illustration.png', height: 150, fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(Icons.search_off, size: 80, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text(_t('no_findings_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(_t('no_findings_subtitle'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          );
        }
        final findings = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: findings.length,
          itemBuilder: (context, index) => FindingCard(data: findings[index], lang: widget.lang, onTap: widget.onRefresh),
        );
      },
    );
  }

  Widget _buildRecentFindingsLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 116,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildInfoCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          widget.isUserDataLoading ? _buildInfoCardSkeleton() : widget.buildInfoCard(),

          // Inspeksi
          const SizedBox(height: 4),
          _buildSectionLabel(_t('inspeksi')),
          const SizedBox(height: 8),
          _buildSwitchTile(
            icon: Icons.assignment_ind_outlined,
            label: _t('pro_mode'),
            value: widget.isProMode,
            bgColor: const Color(0xFFFFF8EE),
            borderColor: Colors.orange.shade200,
            activeTrackColor: Colors.orange.shade300,
            onChanged: widget.onProModeChanged,
          ),
          const SizedBox(height: 25),

          // Laporan Cepat (Visitor Mode)
          _buildSectionLabel(_t('laporan_cepat')),
          const SizedBox(height: 8),
          _buildSwitchTile(
            icon: Icons.visibility_outlined,
            label: _t('visitor_mode'),
            value: widget.isVisitorMode,
            bgColor: const Color(0xFFE6F7F9),
            borderColor: Colors.cyan.shade200,
            activeTrackColor: Colors.cyan.shade300,
            onChanged: widget.onVisitorModeChanged,
          ),
          const SizedBox(height: 25),

          // Telusur & Atur
          _buildSectionLabel(_t('telusur')),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.location_on,
            iconColor: Colors.lightBlue,
            iconBg: Colors.blue.withOpacity(0.1),
            label: _t('lokasi'),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => LocationScreen(lang: widget.lang, isProMode: widget.isProMode, userRole: widget.userRole, userUnitId: widget.userUnitId, userLokasiId: widget.userLokasiId),
            )),
          ),
          const SizedBox(height: 12),
          _buildNavTile(
            icon: Icons.factory_outlined,
            iconColor: Colors.orange,
            iconBg: Colors.orange.withOpacity(0.1),
            label: _t('kts_produksi'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KtsProduksiListScreen(lang: widget.lang))),
          ),
          const SizedBox(height: 12),
          _buildNavTile(
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            iconBg: Colors.red.withOpacity(0.1),
            label: _t('laporan'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccidentReportListScreen(lang: widget.lang))),
          ),
          const SizedBox(height: 25),

          // Recent Findings
          _buildSectionLabel(_t('recent_findings')),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _buildTabChip('my', _t('tab_my')),
              const SizedBox(width: 8),
              _buildTabChip('assigned', _t('tab_assigned')),
              const SizedBox(width: 8),
              _buildTabChip('resolved', _t('tab_resolved')),
            ]),
          ),
          const SizedBox(height: 12),
          KeyedSubtree(
            key: ValueKey('findings_tab_$_activeTab'),
            child: _buildFindingsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54));

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required Color bgColor,
    required Color borderColor,
    required Color activeTrackColor,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: 1.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          ]),
          Switch.adaptive(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: activeTrackColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 1.5)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 24)),
        title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }
}