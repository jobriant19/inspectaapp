import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../finding/detail/finding_detail_screen.dart';
import '../ktsproduksi/kts_detail_screen.dart';
import 'card/finding_card.dart';
import 'card/kts_finding_card.dart';

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

class HomeLatestActivity extends StatefulWidget {
  final String lang;
  final VoidCallback? onRequestRefresh;
  final VoidCallback onRefresh;
  final bool shouldRefreshFindings;
  final VoidCallback? onRefreshDone;

  const HomeLatestActivity({
    super.key,
    required this.lang,
    required this.onRefresh,
    this.onRequestRefresh,
    this.shouldRefreshFindings = false,
    this.onRefreshDone,
  });

  @override
  State<HomeLatestActivity> createState() => HomeLatestActivityState();
}

class HomeLatestActivityState extends State<HomeLatestActivity> {
  Set<String> _activeTabs = {'my'};
  String _activeTypeFilter = '';
  Future<List<Map<String, dynamic>>>? _findingsFuture;
  final Map<String, List<Map<String, dynamic>>> _findingsCache = {};

  String get _cacheKey =>
      '${(_activeTabs.toList()..sort()).join(",")}_$_activeTypeFilter';

  static const int _kMaxHomeCards = 5;
  static const double _kCardGap = 12;

  // Dictionary
  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'recent_findings': 'Latest Activity',
      'tab_my': 'My Findings',
      'tab_assigned': 'Assigned to Me',
      'tab_resolved': 'Resolved by Me',
      'no_findings_title': 'No Recent Findings',
      'no_findings_subtitle':
          'Recent findings you create or are involved in will appear here.',
      'tab_5r': '5R Findings',
      'tab_kts': 'KTS Production',
      'view_all': 'View All',
    },
    'ID': {
      'recent_findings': 'Aktivitas Terbaru',
      'tab_my': 'Temuan Saya',
      'tab_assigned': 'Ditugaskan ke Saya',
      'tab_resolved': 'Diselesaikan Saya',
      'no_findings_title': 'Belum Ada Temuan',
      'no_findings_subtitle':
          'Temuan terbaru yang Anda buat atau terlibat di dalamnya akan muncul di sini.',
      'tab_5r': 'Temuan 5R',
      'tab_kts': 'KTS Produksi',
      'view_all': 'Lihat Semua',
    },
    'ZH': {
      'recent_findings': '最新活动',
      'tab_my': '我的发现',
      'tab_assigned': '分配给我',
      'tab_resolved': '我已解决',
      'no_findings_title': '暂无最新发现',
      'no_findings_subtitle': '您创建或参与的最新发现将显示在此处。',
      'tab_5r': '5R发现',
      'tab_kts': 'KTS生产',
      'view_all': '查看全部',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _findingsFuture = _buildFindingsFuture();
  }

  @override
  void didUpdateWidget(HomeLatestActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldRefreshFindings && !oldWidget.shouldRefreshFindings) {
      setState(() {
        _findingsCache.clear();
        _findingsFuture = _buildFindingsFuture();
      });
      widget.onRefreshDone?.call();
    }
  }

  // Refresh Findings (reset ke tab 'my') — dipanggil dari luar (mis. setelah simpan temuan baru)
  void refreshFindings() {
    if (!mounted) return;
    setState(() {
      _findingsCache.clear(); 
      _activeTabs = {'my'};
      _findingsFuture = _buildFindingsFuture();
    });
  }

  // Refresh Findings tanpa reset tab — dipanggil setelah kembali dari detail/KTS Produksi
  void refreshFindingsQuietly() {
    if (!mounted) return;
    setState(() {
      _findingsCache.clear(); 
      _findingsFuture = _buildFindingsFuture();
    });
  }

  // Findings
  Future<List<Map<String, dynamic>>> _buildFindingsFuture() {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return Future.value([]);

    final cacheKey = _cacheKey;
    if (_findingsCache.containsKey(cacheKey)) {
      return Future.value(_findingsCache[cacheKey]);
    }

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

    return Future.wait(futures).then((lists) {
      final merged = _mergeAndSort(lists);
      _findingsCache[cacheKey] = merged;
      return merged;
    });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: findings.length,
              separatorBuilder: (_, __) => const SizedBox(height: _kCardGap),
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
                      refreshFindingsQuietly();
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
                    refreshFindingsQuietly();
                    widget.onRefresh();
                  },
                );
              },
            ),
            if (hasMore) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: widget.onRequestRefresh,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF1D72F3).withValues(alpha:0.4), width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_t('view_all'),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1D72F3))),
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
          color: isActive ? const Color(0xFF1D72F3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF1D72F3) : Colors.grey.shade300, width: 1.5,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF1D72F3).withValues(alpha:0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800,
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
              ? [BoxShadow(color: color.withValues(alpha:0.35), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : color,
            ),
          ),
        ),
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
}

// Reusable Section Label
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black54),
    );
  }
}