import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../explore/explore_screen.dart';
import '../finding/finding_detail_screen.dart';
import '../ktsproduksi/kts_detail_screen.dart';
import 'location_screen.dart';
import '../ktsproduksi/kts_produksi_screen.dart';
import '../accident/accident_report_screen.dart';
import 'finding_card.dart';
import 'choose_mode_sheet.dart';
import 'executive_verification_screen.dart';
import 'verification_intro_screen.dart';
import 'kts_finding_card.dart';

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
  final String? userUnitId;
  final String? userLokasiId;
  final Map<String, dynamic>? latestLogPoin;
  final bool isLatestLogLoading;
  final VoidCallback? onRequestRefresh;
  final VoidCallback onRefresh;
  final VoidCallback onViewActivityLog;
  final Function(bool) onProModeChanged;
  final Function(bool) onVisitorModeChanged;
  final Widget Function() buildInfoCard;
  final Function(int)? onVerifPointEarned;

  // ── PARAMETER BARU ──
  final bool isExecVerificator;
  final int? userJabatanId;
  final bool shouldRefreshFindings;
  final VoidCallback? onRefreshDone;

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
    this.onVerifPointEarned,
    this.userImage,
    this.userUnitId,
    this.userLokasiId,
    this.latestLogPoin,
    this.isLatestLogLoading = false,
    // ── PARAMETER BARU (opsional, default false/null) ──
    this.isExecVerificator = false,
    this.userJabatanId,
    this.onRequestRefresh,
    this.shouldRefreshFindings = false,
    this.onRefreshDone,
  });

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  Set<String> _activeTabs = {'my'};
  String _activeTypeFilter = '';
  Future<List<Map<String, dynamic>>>? _findingsFuture;

  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'inspeksi': 'Inspection',
      'choose_mode': 'Choose Mode',
      'laporan_cepat': 'Quick Report',
      'telusur': 'Browse & Manage',
      'lokasi': 'Location',
      'laporan': 'Accident Report',
      'recent_findings': 'Latest Activity',
      'kts_produksi': 'Production KTS',
      'tab_my': 'My Findings',
      'tab_assigned': 'Assigned to Me',
      'tab_resolved': 'Resolved by Me',
      'no_findings_title': 'No Recent Findings',
      'no_findings_subtitle':
          'Recent findings you create or are involved in will appear here.',
      'verifikasi': 'Verification',
      'verifikasi_sub': 'Review pending reports',
      'tab_5r': '5R Findings',
      'tab_kts': 'KTS Production',
    },
    'ID': {
      'inspeksi': 'Inspeksi',
      'choose_mode': 'Pilih Mode',
      'laporan_cepat': 'Laporan Cepat',
      'telusur': 'Telusur & Atur',
      'lokasi': 'Lokasi',
      'laporan': 'Laporan Kecelakaan',
      'recent_findings': 'Aktivitas Terbaru',
      'kts_produksi': 'KTS Produksi',
      'tab_my': 'Temuan Saya',
      'tab_assigned': 'Ditugaskan ke Saya',
      'tab_resolved': 'Diselesaikan Saya',
      'no_findings_title': 'Belum Ada Temuan',
      'no_findings_subtitle':
          'Temuan terbaru yang Anda buat atau terlibat di dalamnya akan muncul di sini.',
      'verifikasi': 'Verifikasi',
      'verifikasi_sub': 'Tinjau laporan yang menunggu',
      'tab_5r': 'Temuan 5R',
      'tab_kts': 'KTS Produksi',
    },
    'ZH': {
      'inspeksi': '检查',
      'choose_mode': '选择模式',
      'laporan_cepat': '快速报告',
      'telusur': '浏览与管理',
      'lokasi': '地点',
      'laporan': '事故报告',
      'recent_findings': '最新活动',
      'kts_produksi': '生产KTS',
      'tab_my': '我的发现',
      'tab_assigned': '分配给我',
      'tab_resolved': '我已解决',
      'no_findings_title': '暂无最新发现',
      'no_findings_subtitle': '您创建或参与的最新发现将显示在此处。',
      'verifikasi': '验证',
      'verifikasi_sub': '查看待审报告',
      'tab_5r': '5R发现',
      'tab_kts': 'KTS生产',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _findingsFuture = _buildFindingsFuture();
    // Daftarkan refreshFindings ke parent melalui onRefresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onRefresh != null) {
        // Simpan referensi ke HomeScreen
      }
    });
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh findings jika dipicu dari luar
    if (widget.shouldRefreshFindings == true && 
        oldWidget.shouldRefreshFindings == false) {
      setState(() {
        _activeTabs = {'my'};
        _findingsFuture = _buildFindingsFuture();
      });
      widget.onRefreshDone?.call();
    }
  }

  Future<List<Map<String, dynamic>>> _buildFindingsFuture() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return Future.value([]);

    final List<Future<List<Map<String, dynamic>>>> futures = [];

    // Jika tidak ada tab yang dipilih, default tampilkan semua (my findings)
    final activeTabs = _activeTabs.isEmpty ? {'my'} : _activeTabs;

    if (activeTabs.contains('my')) {
      var q = Supabase.instance.client
          .from('temuan')
          .select('id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan, poin_temuan, target_waktu_selesai, id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, jenis_temuan, no_order, jumlah_item, nama_item_manual, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), is_pro, is_visitor, is_eksekutif, item_produksi:id_item(id_item, nama_item, gambar_item), subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan)')
          .eq('id_user', userId);
      if (_activeTypeFilter == '5r') q = q.neq('jenis_temuan', 'KTS Production');
      if (_activeTypeFilter == 'kts') q = q.eq('jenis_temuan', 'KTS Production');
      futures.add(q.order('created_at', ascending: false).limit(10).then((v) => List<Map<String, dynamic>>.from(v)));
    }

    if (activeTabs.contains('assigned')) {
      var q = Supabase.instance.client
          .from('temuan')
          .select('id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan, poin_temuan, target_waktu_selesai, id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, jenis_temuan, no_order, jumlah_item, nama_item_manual, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), is_pro, is_visitor, is_eksekutif, item_produksi:id_item(id_item, nama_item, gambar_item), subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan)')
          .eq('id_penanggung_jawab', userId);
      if (_activeTypeFilter == '5r') q = q.neq('jenis_temuan', 'KTS Production');
      if (_activeTypeFilter == 'kts') q = q.eq('jenis_temuan', 'KTS Production');
      futures.add(q.order('created_at', ascending: false).limit(10).then((v) => List<Map<String, dynamic>>.from(v)));
    }

    if (activeTabs.contains('resolved')) {
      futures.add(
        Supabase.instance.client
            .from('penyelesaian')
            .select('id_penyelesaian, temuan(id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan, poin_temuan, target_waktu_selesai, id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, jenis_temuan, no_order, jumlah_item, nama_item_manual, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), is_pro, is_visitor, is_eksekutif, item_produksi:id_item(id_item, nama_item, gambar_item), subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan))')
            .eq('id_user', userId)
            .order('tanggal_selesai', ascending: false)
            .limit(10)
            .then((v) {
          final result = <Map<String, dynamic>>[];
          for (final item in v) {
            final temuanRaw = item['temuan'];
            if (temuanRaw == null) continue;
            Map<String, dynamic> t;
            if (temuanRaw is List && temuanRaw.isNotEmpty) {
              t = Map<String, dynamic>.from(temuanRaw.first);
            } else if (temuanRaw is Map) {
              t = Map<String, dynamic>.from(temuanRaw);
            } else continue;
            if (_activeTypeFilter == '5r' && t['jenis_temuan'] == 'KTS Production') continue;
            if (_activeTypeFilter == 'kts' && t['jenis_temuan'] != 'KTS Production') continue;
            result.add(t);
          }
          return result;
        }),
      );
    }

    if (futures.isEmpty) return Future.value([]);

    return Future.wait(futures).then((lists) {
      final seen = <int>{};
      final combined = <Map<String, dynamic>>[];
      for (final list in lists) {
        for (final item in list) {
          final id = item['id_temuan'] as int?;
          if (id != null && seen.add(id)) combined.add(item);
        }
      }
      combined.sort((a, b) {
        final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });
      return combined;
    });
  }

  Widget _buildTabChip(String tabKey, String label) {
    final bool isActive = _activeTabs.contains(tabKey);
    return GestureDetector(
      onTap: () => setState(() {
        if (isActive && _activeTabs.length == 1) {
          
        } else if (isActive) {
          _activeTabs.remove(tabKey);
        } else {
          _activeTabs.add(tabKey);
        }
        _findingsFuture = _buildFindingsFuture();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilterBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _activeTypeFilter = _activeTypeFilter == '5r' ? '' : '5r';
              _findingsFuture = _buildFindingsFuture();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _activeTypeFilter == '5r'
                    ? const Color(0xFF38BDF8)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _activeTypeFilter == '5r'
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                boxShadow: _activeTypeFilter == '5r'
                    ? [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: Text(
                  _t('tab_5r'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _activeTypeFilter == '5r' ? Colors.white : const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _activeTypeFilter = _activeTypeFilter == 'kts' ? '' : 'kts';
              _findingsFuture = _buildFindingsFuture();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _activeTypeFilter == 'kts'
                    ? const Color(0xFFFBBF24)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _activeTypeFilter == 'kts'
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                boxShadow: _activeTypeFilter == 'kts'
                    ? [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: Text(
                  _t('tab_kts'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _activeTypeFilter == 'kts' ? Colors.white : const Color(0xFFFBBF24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const int _kMaxHomeCards = 5;
 
  String _lihatSemuaLabel() {
    switch (widget.lang) {
      case 'EN': return 'View All';
      case 'ZH': return '查看全部';
      default: return 'Lihat Semua';
    }
  }
  
  Widget _buildFindingsTab() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const SizedBox();
  
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('findings_future_${_activeTabs.join("_")}'),
      future: _findingsFuture,
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
                  Image.asset(
                    'assets/images/team_illustration.png',
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('no_findings_title'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t('no_findings_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
  
        final allFindings = snapshot.data!;
        // Batasi maksimum 5 card di home
        final findings = allFindings.take(_kMaxHomeCards).toList();
        final hasMore = allFindings.length > _kMaxHomeCards;
  
        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: findings.length,
              itemBuilder: (context, index) {
                final item = findings[index];
                final isKts = (item['jenis_temuan'] ?? '') == 'KTS Production';
  
                if (isKts) {
                  // Card KTS
                  return KtsFindingCard(
                    data: item,
                    lang: widget.lang,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KtsDetailScreen(
                            ktsId: item['id_temuan'] as int,
                            lang: widget.lang,
                            initialData: item,
                          ),
                        ),
                      );
                      setState(() { _findingsFuture = _buildFindingsFuture(); });
                      widget.onRefresh();
                    },
                  );
                }
  
                // Card 5R biasa
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
                    setState(() { _findingsFuture = _buildFindingsFuture(); });
                    widget.onRefresh();
                  },
                );
              },
            ),
  
            // Tombol "Lihat Semua" jika data > 5
            if (hasMore) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  widget.onRequestRefresh?.call();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00C9E4).withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _lihatSemuaLabel(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00C9E4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF00C9E4)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void refreshFindings() {
    if (!mounted) return;
    setState(() {
      _activeTabs = {'my'};
      _findingsFuture = _buildFindingsFuture();
    });
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
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildInfoCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
          height: 140,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24))),
    );
  }

  // ── WIDGET BARU: Choose Mode Button ──
  Widget _buildChooseModeButton() {
    final bool anyActive =
        widget.isProMode || widget.isVisitorMode;

    return GestureDetector(
      onTap: () {
        showChooseModeSheet(
          context: context,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
          lang: widget.lang,
          onProModeChanged: widget.onProModeChanged,
          onVisitorModeChanged: widget.onVisitorModeChanged,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: anyActive
              ? const LinearGradient(
                  colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: anyActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: anyActive
                ? Colors.transparent
                : const Color(0xFF00C9E4).withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9E4)
                  .withOpacity(anyActive ? 0.25 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ikon dengan container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: anyActive
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF00C9E4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: anyActive
                    ? Colors.white
                    : const Color(0xFF00C9E4),
              ),
            ),
            const SizedBox(width: 12),

            // Label & status badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('choose_mode'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: anyActive
                          ? Colors.white
                          : const Color(0xFF1E3A8A),
                    ),
                  ),
                  if (anyActive) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      if (widget.isProMode)
                        _ModeBadge(
                          label: widget.lang == 'ZH'
                              ? '专业'
                              : widget.lang == 'ID'
                                  ? 'Pro'
                                  : 'Pro',
                          color: const Color(0xFF4ADE80),
                        ),
                      if (widget.isProMode &&
                          widget.isVisitorMode)
                        const SizedBox(width: 6),
                      if (widget.isVisitorMode)
                        _ModeBadge(
                          label: widget.lang == 'ZH'
                              ? '访客'
                              : widget.lang == 'ID'
                                  ? 'Pengunjung'
                                  : 'Visitor',
                          color: const Color(0xFFFBBF24),
                        ),
                    ]),
                  ] else
                    Text(
                      widget.lang == 'ZH'
                          ? '点击以自定义模式'
                          : widget.lang == 'ID'
                              ? 'Ketuk untuk atur mode'
                              : 'Tap to customize mode',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: anyActive
                  ? Colors.white70
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGET BARU: Executive Verification Button ──
  Widget _buildExecVerifButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationIntroScreen(
              lang: widget.lang,
              userJabatanId: widget.userJabatanId,
              onPointEarned: widget.onVerifPointEarned, // TAMBAH INI
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF0891B2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ikon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('verifikasi'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _t('verifikasi_sub'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
          left: 20, right: 20, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info Card ──
          widget.isUserDataLoading
              ? _buildInfoCardSkeleton()
              : widget.buildInfoCard(),

          // ── Inspeksi Section ──
          _buildSectionLabel(_t('inspeksi')),
          const SizedBox(height: 10),

          // Choose Mode Button (menggantikan dua switch lama)
          _buildChooseModeButton(),

          // Executive Verification Button (hanya muncul jika eksekutif+verificator)
          if (widget.isExecVerificator) ...[
            const SizedBox(height: 10),
            _buildExecVerifButton(),
          ],

          const SizedBox(height: 25),

          // ── Telusur & Atur ──
          _buildSectionLabel(_t('telusur')),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.location_on,
            iconColor: Colors.lightBlue,
            iconBg: Colors.blue.withOpacity(0.1),
            label: _t('lokasi'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationScreen(
                  lang: widget.lang,
                  isProMode: widget.isProMode,
                  userRole: widget.userRole,
                  userUnitId: widget.userUnitId?.toString(),
                  userLokasiId: widget.userLokasiId?.toString(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildNavTile(
            icon: Icons.factory_outlined,
            iconColor: Colors.orange,
            iconBg: Colors.orange.withOpacity(0.1),
            label: _t('kts_produksi'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      KtsProduksiListScreen(lang: widget.lang)),
            ),
          ),
          const SizedBox(height: 12),
          _buildNavTile(
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            iconBg: Colors.red.withOpacity(0.1),
            label: _t('laporan'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AccidentReportListScreen(
                      lang: widget.lang)),
            ),
          ),
          const SizedBox(height: 25),

          // ── Recent Findings ──
          _buildSectionLabel(_t('recent_findings')),
          const SizedBox(height: 10),
          // Filter utama: 5R & KTS
          _buildTypeFilterBar(),
          const SizedBox(height: 10),
          // Filter tab: My / Assigned / Resolved
          Row(
            children: [
              Expanded(child: _buildTabChip('my', _t('tab_my'))),
              const SizedBox(width: 8),
              Expanded(child: _buildTabChip('assigned', _t('tab_assigned'))),
              const SizedBox(width: 8),
              Expanded(child: _buildTabChip('resolved', _t('tab_resolved'))),
            ],
          ),
          const SizedBox(height: 12),
          KeyedSubtree(
            key: ValueKey('findings_tab_${_activeTabs.join("_")}_$_activeTypeFilter'),
            child: _buildFindingsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black54),
      );

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.grey.shade200, width: 1.5)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24)),
        title: Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A))),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }
}

// ── Helper badge untuk mode aktif ──
class _ModeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ModeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}