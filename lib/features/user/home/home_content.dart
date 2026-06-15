import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../audit/audit_form_screen.dart';
import '../../audit/audit_selfie_screen.dart';
import '../finding/finding_detail_screen.dart';
import '../ktsproduksi/kts_detail_screen.dart';
import 'location_screen.dart';
import '../ktsproduksi/kts_produksi_screen.dart';
import '../accident/accident_report_screen.dart';
import 'finding_card.dart';
import 'choose_mode_sheet.dart';
import 'verification_intro_screen.dart';
import 'kts_finding_card.dart';

// Supabase shorthand
final _sb = Supabase.instance.client;

// Shared select clause
const _kTemuanSelect =
    'id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan, '
    'poin_temuan, target_waktu_selesai, id_lokasi, id_unit, id_subunit, '
    'id_area, id_penanggung_jawab, jenis_temuan, no_order, jumlah_item, '
    'nama_item_manual, lokasi(nama_lokasi), unit(nama_unit), '
    'subunit(nama_subunit), area(nama_area), is_pro, is_visitor, '
    'is_eksekutif, item_produksi:id_item(id_item, nama_item, gambar_item), '
    'subkategoritemuan:id_subkategoritemuan_uuid('
    'id_subkategoritemuan, nama_subkategoritemuan)';

class HomeContent extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;
  final bool isUserDataLoading;
  final bool isAtAtmi;
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
    required this.isAtAtmi,
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
  Future<List<Map<String, dynamic>>>? _pendingAuditsFuture;

  static const int _kMaxHomeCards = 5;

  // Dictionary
  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'inspeksi': 'Inspection',
      'choose_mode': 'Choose Mode',
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
      'view_all': 'View All',
      'audit_tasks': 'Pending Audit Tasks',
    },
    'ID': {
      'inspeksi': 'Inspeksi',
      'choose_mode': 'Pilih Mode',
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
      'view_all': 'Lihat Semua',
      'audit_tasks': 'Tugas Audit',
    },
    'ZH': {
      'inspeksi': '检查',
      'choose_mode': '选择模式',
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
      'view_all': '查看全部',
      'audit_tasks': '待完成审计任务',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _findingsFuture = _buildFindingsFuture();
    _pendingAuditsFuture = _fetchPendingAudits();
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldRefreshFindings && !oldWidget.shouldRefreshFindings) {
      setState(() => _findingsFuture = _buildFindingsFuture());
      widget.onRefreshDone?.call();
    }
  }

  // Refresh Findings
  void refreshFindings() {
    if (!mounted) return;
    setState(() {
      _activeTabs = {'my'};
      _findingsFuture = _buildFindingsFuture();
    });
  }

  // Findings
  Future<List<Map<String, dynamic>>> _buildFindingsFuture() {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return Future.value([]);

    final tabs = _activeTabs.isEmpty ? {'my'} : _activeTabs;
    final futures = <Future<List<Map<String, dynamic>>>>[];

    // Tab: My Findings
    if (tabs.contains('my')) {
      futures.add(_queryTemuan(filter: (q) => q.eq('id_user', userId)));
    }

    // Tab: Assigned to Me
    if (tabs.contains('assigned')) {
      futures.add(_queryTemuan(filter: (q) => q.eq('id_penanggung_jawab', userId)));
    }

    // Tab: Resolved by Me
    if (tabs.contains('resolved')) {
      futures.add(_queryResolved(userId));
    }

    if (futures.isEmpty) return Future.value([]);

    return Future.wait(futures).then(_mergeAndSort);
  }

  // Helper: Findings Query + Filter
  Future<List<Map<String, dynamic>>> _queryTemuan({
    required dynamic Function(dynamic) filter,
  }) async {
    var q = filter(_sb.from('temuan').select(_kTemuanSelect));
    if (_activeTypeFilter == '5r') q = q.neq('jenis_temuan', 'KTS Production');
    if (_activeTypeFilter == 'kts') q = q.eq('jenis_temuan', 'KTS Production');
    final v = await q.order('created_at', ascending: false).limit(10);
    return List<Map<String, dynamic>>.from(v);
  }

  // Helper: Query Findings Resolved
  Future<List<Map<String, dynamic>>> _queryResolved(String userId) async {
    final v = await _sb
        .from('penyelesaian')
        .select(
          'id_penyelesaian, '
          'temuan!temuan_id_penyelesaian_fkey($_kTemuanSelect)',
        )
        .eq('id_user', userId)
        .order('tanggal_selesai', ascending: false)
        .limit(10);

    final result = <Map<String, dynamic>>[];
    for (final item in v) {
      final raw = item['temuan'];
      if (raw == null) continue;
      final t = raw is List
          ? (raw.isEmpty ? null : Map<String, dynamic>.from(raw.first))
          : Map<String, dynamic>.from(raw as Map);
      if (t == null) continue;
      if (_activeTypeFilter == '5r' && t['jenis_temuan'] == 'KTS Production') continue;
      if (_activeTypeFilter == 'kts' && t['jenis_temuan'] != 'KTS Production') continue;
      result.add(t);
    }
    return result;
  }

  // Helper: Merge + Dedup + Sort by created_at 
  List<Map<String, dynamic>> _mergeAndSort(List<List<Map<String, dynamic>>> lists) {
    final seen = <String>{};
    final combined = <Map<String, dynamic>>[];
    for (final list in lists) {
      for (final item in list) {
        final id = item['id_temuan']?.toString();
        if (id != null && seen.add(id)) combined.add(item);
      }
    }
    combined.sort((a, b) {
      final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });
    return combined;
  }

  // Fetch Pending Audit Tasks
  Future<List<Map<String, dynamic>>> _fetchPendingAudits() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final rows = await _sb
          .from('audit_schedule')
          .select(
              'id_schedule, level_type, id_ref, periode_mulai, periode_selesai, status, '
              'id_jenis_audit, JenisAudit:jenis_audit(nama_id, nama_en, nama_zh)') // ✅ BARU
          .eq('id_auditor', userId)
          .inFilter('status', ['pending', 'in_progress'])
          .lte('periode_mulai', today)
          .gte('periode_selesai', today);

      if (rows.isEmpty) return [];

      // Group by Level Fetch Location Name
      final byLevel = <String, List<String>>{};
      for (final r in rows) {
        final level = r['level_type'] as String;
        byLevel.putIfAbsent(level, () => []).add(r['id_ref'].toString());
      }

      // Fetch All Paralel Location Name per Level
      final nameMap = <String, String>{};
      await Future.wait(byLevel.entries.map((e) async {
        final level = e.key;
        final ids = e.value;
        try {
          final res = await _sb
              .from(level)
              .select('id_$level, nama_$level')
              .inFilter('id_$level', ids);
          for (final r in res) {
            nameMap[r['id_$level'].toString()] = r['nama_$level']?.toString() ?? r['id_$level'].toString();
          }
        } catch (_) {}
      }));

      return List<Map<String, dynamic>>.from(rows).map((row) {
        // ✅ BARU: label jenis audit sesuai bahasa
        String? jenisLabel;
        final jenisData = row['JenisAudit'] as Map<String, dynamic>?;
        if (jenisData != null) {
          jenisLabel = widget.lang == 'EN'
              ? jenisData['nama_en']?.toString()
              : widget.lang == 'ZH'
                  ? jenisData['nama_zh']?.toString()
                  : jenisData['nama_id']?.toString();
        }
        return {
          ...row,
          'location_name': nameMap[row['id_ref'].toString()] ?? row['id_ref'].toString(),
          'jenis_audit_label': jenisLabel, // ✅ BARU
        };
      }).toList();
    } catch (e) {
      debugPrint('Pending audits error: $e');
      return [];
    }
  }

  // Refresh Findings
  void _refreshFindings() {
    if (!mounted) return;
    final future = _buildFindingsFuture();
    setState(() {
      _findingsFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          widget.isUserDataLoading ? _buildInfoCardSkeleton() : widget.buildInfoCard(),

          // Inspection
          _SectionLabel(text: _t('inspeksi')),
          const SizedBox(height: 10),
          _buildChooseModeButton(),
          _buildPendingAuditSection(),

          if (widget.isExecVerificator) ...[
            const SizedBox(height: 10),
            _buildExecVerifButton(),
          ],

          const SizedBox(height: 25),

          // Browse & Manage
          _SectionLabel(text: _t('telusur')),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.location_on,
            iconColor: Colors.lightBlue,
            iconBg: Colors.blue.withOpacity(0.1),
            label: _t('lokasi'),
            onTap: () => _push(LocationScreen(
              lang: widget.lang,
              isProMode: widget.isProMode,
              userRole: widget.userRole,
              userUnitId: widget.userUnitId,
              userLokasiId: widget.userLokasiId,
            )),
          ),
          const SizedBox(height: 12),
          _buildNavTile(
            icon: Icons.factory_outlined,
            iconColor: Colors.lightBlue,
            iconBg: Colors.blue.withOpacity(0.1),
            label: _t('kts_produksi'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KtsProduksiListScreen(lang: widget.lang)),
              );
              _refreshFindings();
              widget.onRefresh();
            },
          ),
          const SizedBox(height: 12),
          _buildNavTile(
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            iconBg: Colors.red.withOpacity(0.1),
            label: _t('laporan'),
            onTap: () => _push(AccidentReportListScreen(lang: widget.lang)),
          ),

          const SizedBox(height: 25),

          // Recent Findings
          _SectionLabel(text: _t('recent_findings')),
          const SizedBox(height: 10),
          _buildTypeFilterBar(),
          const SizedBox(height: 10),
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
            key: ValueKey('findings_${_activeTabs.join("_")}_$_activeTypeFilter'),
            child: _buildFindingsTab(),
          ),
        ],
      ),
    );
  }

  // Navigator Helper with Slide Transition
  void _push(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        maintainState: true,
      ),
    );
  }

  // Findings Tab
  Widget _buildFindingsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _findingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRecentFindingsLoader();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyFindings();
        }

        final all = snapshot.data!;
        final findings = all.take(_kMaxHomeCards).toList();
        final hasMore = all.length > _kMaxHomeCards;

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: findings.length,
              itemBuilder: (_, i) {
                final item = findings[i];
                final isKts = item['jenis_temuan'] == 'KTS Production';
                if (isKts) {
                  return KtsFindingCard(
                    data: item,
                    lang: widget.lang,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KtsDetailScreen(
                            ktsId: item['id_temuan'].toString(),
                            lang: widget.lang,
                            initialData: item,
                          ),
                        ),
                      );
                      _refreshFindings();
                      widget.onRefresh();
                    },
                  );
                }
                return FindingCard(
                  data: item,
                  lang: widget.lang,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FindingDetailScreen(initialData: item, lang: widget.lang),
                      ),
                    );
                    _refreshFindings();
                    widget.onRefresh();
                  },
                );
              },
            ),
            if (hasMore) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: widget.onRequestRefresh,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00C9E4).withOpacity(0.4), width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_t('view_all'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF00C9E4))),
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

  Widget _buildEmptyFindings() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.search_off, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(_t('no_findings_title'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(_t('no_findings_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Tab Chip
  Widget _buildTabChip(String tabKey, String label) {
    final isActive = _activeTabs.contains(tabKey);
    return GestureDetector(
      onTap: () => setState(() {
        if (isActive && _activeTabs.length > 1) {
          _activeTabs.remove(tabKey);
        } else if (!isActive) {
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
            color: isActive ? const Color(0xFF00C9E4) : Colors.grey.shade300, width: 1.5,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF00C9E4).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
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

  // Type Filter Bar (5R / KTS)
  Widget _buildTypeFilterBar() {
    return Row(
      children: [
        Expanded(child: _buildFilterButton('5r', _t('tab_5r'), const Color(0xFF38BDF8))),
        const SizedBox(width: 10),
        Expanded(child: _buildFilterButton('kts', _t('tab_kts'), const Color(0xFFFBBF24))),
      ],
    );
  }

  Widget _buildFilterButton(String key, String label, Color color) {
    final isActive = _activeTypeFilter == key;
    return GestureDetector(
      onTap: () => setState(() {
        _activeTypeFilter = isActive ? '' : key;
        _findingsFuture = _buildFindingsFuture();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? color : const Color(0xFFCBD5E1), width: 1.5),
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  // Choose Mode Button
  Widget _buildChooseModeButton() {
    final anyActive = widget.isProMode || widget.isVisitorMode;
    return GestureDetector(
      onTap: () => showChooseModeSheet(
        context: context,
        isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        lang: widget.lang,
        onProModeChanged: widget.onProModeChanged,
        onVisitorModeChanged: widget.onVisitorModeChanged,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: anyActive
              ? const LinearGradient(
                  colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                )
              : null,
          color: anyActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: anyActive ? Colors.transparent : const Color(0xFF00C9E4).withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9E4).withOpacity(anyActive ? 0.25 : 0.08),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: anyActive ? Colors.white.withOpacity(0.2) : const Color(0xFF00C9E4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded, size: 20, color: anyActive ? Colors.white : const Color(0xFF00C9E4)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('choose_mode'),
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: anyActive ? Colors.white : const Color(0xFF1E3A8A),
                    ),
                  ),
                  if (anyActive) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (widget.isProMode) _ModeBadge(label: _modeBadgeLabel('pro'), color: const Color(0xFF4ADE80)),
                        if (widget.isProMode && widget.isVisitorMode) const SizedBox(width: 6),
                        if (widget.isVisitorMode) _ModeBadge(label: _modeBadgeLabel('visitor'), color: const Color(0xFFFBBF24)),
                      ],
                    ),
                  ] else
                    Text(
                      widget.lang == 'ZH' ? '点击以自定义模式'
                          : widget.lang == 'ID' ? 'Ketuk untuk atur mode'
                          : 'Tap to customize mode',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: anyActive ? Colors.white70 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _modeBadgeLabel(String type) {
    if (type == 'pro') return 'Pro';
    return widget.lang == 'ZH' ? '访客' : widget.lang == 'ID' ? 'Pengunjung' : 'Visitor';
  }

  // Pending Audit Section
  // Pending Audit Section
  Widget _buildPendingAuditSection() {
    // ✅ BARU: sembunyikan jika tidak berada di PT ATMI Solo
    if (!widget.isAtAtmi) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pendingAuditsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            _SectionLabel(text: _t('audit_tasks')),
            const SizedBox(height: 10),
            ...tasks.map(_buildAuditTaskCard),
          ],
        );
      },
    );
  }

  Widget _buildAuditTaskCard(Map<String, dynamic> task) {
    const teal = Color(0xFF14B8A6);
    final level = task['level_type'] as String;
    final locationName = task['location_name'] as String;
    final from = task['periode_mulai']?.toString() ?? '';
    final to = task['periode_selesai']?.toString() ?? '';

    final levelLabel = {
      'unit': 'Unit', 'subunit': 'Sub-Unit', 'area': 'Area',
    }[level] ?? (widget.lang == 'EN' ? 'Location' : 'Lokasi');

    return GestureDetector(
      onTap: () async {
        // Step 1: Selfie dulu
        final selfieUrl = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => AuditSelfieScreen(
              lang: widget.lang,
              locationName: locationName,
              levelType: level,
              idRef: task['id_ref'].toString(),
            ),
          ),
        );
        // Jika user cancel selfie, batalkan navigasi ke form
        if (selfieUrl == null || !mounted) return;

        // Step 2: Buka form audit dengan selfieUrl
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuditFormScreen(
              lang: widget.lang,
              levelType: level,
              idRef: task['id_ref'].toString(),
              locationName: locationName,
              idSchedule: task['id_schedule'].toString(),
              selfieUrl: selfieUrl,
              idJenisAudit: task['id_jenis_audit']?.toString(),
            ),
          ),
        );
        if (mounted) {
          setState(() {
            _pendingAuditsFuture = _fetchPendingAudits();
          });
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: teal.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.fact_check_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locationName,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  // ✅ BARU: Badge jenis audit
                  if (task['jenis_audit_label'] != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task['jenis_audit_label'].toString(),
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text('$levelLabel  •  $from → $to',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // Executive Verification Button
  Widget _buildExecVerifButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => VerificationIntroScreen(
            lang: widget.lang,
            userJabatanId: widget.userJabatanId,
            onPointEarned: widget.onVerifPointEarned,
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF0891B2)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.verified_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('verifikasi'),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(_t('verifikasi_sub'),
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // Nav Tile
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
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }

  // Recent Findings Loader
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
      child: Container(
        height: 140,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

// Reusable Section Label
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54),
      ),
    );
  }
}

// Mode Badge
class _ModeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ModeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}