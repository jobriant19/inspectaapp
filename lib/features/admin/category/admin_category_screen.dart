import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_add_category.dart';
import 'admin_add_subcategory.dart';
import 'admin_category_indicator.dart';
import 'admin_edit_category.dart';
import 'admin_edit_subcategory.dart';

// ============================================================
// ADMIN CATEGORY SCREEN
// ============================================================
class AdminCategoryScreen extends StatefulWidget {
  final String lang;
  const AdminCategoryScreen({super.key, required this.lang});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedTab = 0; // 0 = 5R Finding, 1 = KTS Production

  static const _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF59E0B),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        shadowColor: Colors.black.withValues(alpha:0.08),
        title: Text(
          widget.lang == 'EN'
              ? 'Category Management'
              : widget.lang == 'ZH'
                  ? '分类管理'
                  : 'Kelola Kategori',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFFF59E0B),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFFF59E0B),
              indicatorWeight: 3,
              labelColor: const Color(0xFFF59E0B),
              unselectedLabelColor: Colors.black38,
              isScrollable: false,
              tabAlignment: TabAlignment.fill,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'EN'
                            ? 'Categories'
                            : widget.lang == 'ZH'
                                ? '分类'
                                : 'Kategori',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list_alt_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'EN'
                            ? 'Sub-Categories'
                            : widget.lang == 'ZH'
                                ? '子分类'
                                : 'Sub-Kategori',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildFilterPills(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _KategoriList(
                  key: ValueKey('kat_$_selectedTab'),
                  lang: widget.lang,
                  isKts: _selectedTab == 1,
                  color: _selectedTab == 0
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFFBBF24),
                ),
                _SubkategoriList(
                  key: ValueKey('subkat_$_selectedTab'),
                  lang: widget.lang,
                  isKts: _selectedTab == 1,
                  color: _selectedTab == 0
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFFBBF24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 0
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFFBAE6FD),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cleaning_services_rounded,
                      size: 15,
                      color: _selectedTab == 0
                          ? Colors.white
                          : const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '5R Finding',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedTab == 0
                            ? Colors.white
                            : const Color(0xFF0EA5E9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 1
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFFBBF24).withValues(alpha:0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.precision_manufacturing_rounded,
                      size: 15,
                      color: _selectedTab == 1
                          ? Colors.white
                          : const Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'KTS Production',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedTab == 1
                            ? Colors.white
                            : const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DAFTAR KATEGORI
// ============================================================
class _KategoriList extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;

  const _KategoriList({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
  });

  @override
  State<_KategoriList> createState() => _KategoriListState();
}

class _KategoriListState extends State<_KategoriList>
  with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _search = '';
  String _sortPoin = 'none';   // 'none' | 'asc' | 'desc'
  String _sortOrder = 'none';  // 'none' | 'asc' | 'desc'
  int _currentPage = 1;

  static const _bg = Color(0xFFF8FAFC);
  static const _subColor = Color(0xFF8B5CF6);  // ungu khusus jumlah sub-kategori
  static const _poinColor = Color(0xFFF59E0B); // oranye khusus poin

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_KategoriList old) {
    super.didUpdateWidget(old);
    if (old.isKts != widget.isKts) _loadIfEmpty();
  }

  // Tambahkan method baru di bawahnya:
  Future<void> _loadIfEmpty() async {
    if (_data.isEmpty) {
      _load();
    } else {
      // Data sudah ada, langsung filter ulang tanpa loading
      setState(() {});
    }
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('kategoritemuan')
          .select(
            'id_kategoritemuan, nama_kategoritemuan, nama_kategoritemuan_en, '
            'nama_kategoritemuan_zh, deskripsi_kategoritemuan, '
            'deskripsi_kategoritemuan_en, deskripsi_kategoritemuan_zh, '
            'poin_kategoritemuan, jenis_kategori, '
            'subkategoritemuan(id_subkategoritemuan, '
            'nama_subkategoritemuan, poin_subkategoritemuan)',
          )
          .order('nama_kategoritemuan');

      final all = List<Map<String, dynamic>>.from(res);
      final filtered = all.where((item) {
        final jenis = (item['jenis_kategori'] ?? '').toString().toUpperCase();
        if (widget.isKts) return jenis == 'KTS';
        return jenis == '5R';
      }).toList();

      if (mounted) {
        setState(() {
          _data = filtered;
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      debugPrint('Error load kategori: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _localizedNama(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['nama_kategoritemuan_en'] ?? item['nama_kategoritemuan'] ?? '-').toString();
      case 'ZH':
        return (item['nama_kategoritemuan_zh'] ?? item['nama_kategoritemuan'] ?? '-').toString();
      default:
        return (item['nama_kategoritemuan'] ?? '-').toString();
    }
  }

  String _localizedDesk(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['deskripsi_kategoritemuan_en'] ?? item['deskripsi_kategoritemuan'] ?? '').toString();
      case 'ZH':
        return (item['deskripsi_kategoritemuan_zh'] ?? item['deskripsi_kategoritemuan'] ?? '').toString();
      default:
        return (item['deskripsi_kategoritemuan'] ?? '').toString();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_data);

    if (q.isNotEmpty) {
      result = result
          .where((d) => _localizedNama(d).toLowerCase().contains(q))
          .toList();
    }
    // Sort by poin
    if (_sortPoin == 'asc') {
      result.sort((a, b) => ((a['poin_kategoritemuan'] ?? 0) as int)
          .compareTo((b['poin_kategoritemuan'] ?? 0) as int));
    } else if (_sortPoin == 'desc') {
      result.sort((a, b) => ((b['poin_kategoritemuan'] ?? 0) as int)
          .compareTo((a['poin_kategoritemuan'] ?? 0) as int));
    }
    // Sort by name
    if (_sortOrder == 'asc') {
      result.sort((a, b) => _localizedNama(a).compareTo(_localizedNama(b)));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => _localizedNama(b).compareTo(_localizedNama(a)));
    }
    return result;
  }

  Widget? _buildActiveChips() {
    final chips = <Widget>[];
    if (_sortPoin != 'none') {
      chips.add(_buildFilterChip(
        _sortPoin == 'asc' ? '⭐ Poin ↑' : '⭐ Poin ↓',
        widget.color,
        () => setState(() { _sortPoin = 'none'; _currentPage = 1; }),
      ));
    }
    if (_sortOrder != 'none') {
      chips.add(_buildFilterChip(
        _sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
        widget.color,
        () => setState(() { _sortOrder = 'none'; _currentPage = 1; }),
      ));
    }
    if (chips.isEmpty) return null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildFilterChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            label: widget.lang == 'EN' ? 'Sort by Points' : widget.lang == 'ZH' ? '按积分排序' : 'Urut Poin',
            icon: Icons.star_rounded,
            isActive: _sortPoin != 'none',
            activeLabel: _sortPoin == 'asc' ? '↑' : _sortPoin == 'desc' ? '↓' : null,
            onTap: () => _showPoinSortDialog(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            label: widget.lang == 'EN' ? 'Sort' : widget.lang == 'ZH' ? '排序' : 'Urutan',
            icon: Icons.sort_by_alpha_rounded,
            isActive: _sortOrder != 'none',
            activeLabel: _sortOrder == 'asc' ? 'A→Z' : _sortOrder == 'desc' ? 'Z→A' : null,
            onTap: () => _showSortDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    String? activeLabel,
  }) {
    final color = widget.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade200,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: color.withValues(alpha:0.2), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                isActive && activeLabel != null ? '$label $activeLabel' : label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  void _showPoinSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSortOptionDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Sort by Points' : widget.lang == 'ZH' ? '按积分排序' : 'Urut berdasarkan Poin',
        icon: Icons.star_rounded,
        color: widget.color,
        currentValue: _sortPoin,
        options: [
          {'value': 'none', 'label': widget.lang == 'EN' ? 'Default' : widget.lang == 'ZH' ? '默认' : 'Default'},
          {'value': 'desc', 'label': widget.lang == 'EN' ? 'Highest Points First' : widget.lang == 'ZH' ? '积分从高到低' : 'Poin Terbesar Dulu'},
          {'value': 'asc', 'label': widget.lang == 'EN' ? 'Lowest Points First' : widget.lang == 'ZH' ? '积分从低到高' : 'Poin Terkecil Dulu'},
        ],
        onSelect: (v) {
          setState(() { _sortPoin = v; _currentPage = 1; });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSortOptionDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Sort Order' : widget.lang == 'ZH' ? '排序方式' : 'Urutan Abjad',
        icon: Icons.sort_by_alpha_rounded,
        color: widget.color,
        currentValue: _sortOrder,
        options: [
          {'value': 'none', 'label': widget.lang == 'EN' ? 'Default (No Sort)' : widget.lang == 'ZH' ? '默认' : 'Default (Tanpa Urutan)'},
          {'value': 'asc', 'label': 'A → Z (Ascending)'},
          {'value': 'desc', 'label': 'Z → A (Descending)'},
        ],
        onSelect: (v) {
          setState(() { _sortOrder = v; _currentPage = 1; });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    final subs = List<Map<String, dynamic>>.from(
        item['subkategoritemuan'] as List? ?? []);
    final poin = item['poin_kategoritemuan'] ?? 0;
    final descRaw = _localizedDesk(item);
    final desc = descRaw.isEmpty ? '-' : descRaw;
    final nama = _localizedNama(item);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color.withValues(alpha:0.14), widget.color.withValues(alpha:0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha:0.18),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: widget.color.withValues(alpha:0.25), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Icon(Icons.category_rounded, color: widget.color, size: 24),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 6)]),
                          child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(nama, style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w800, fontSize: 19)),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13.5, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _detailChip('${widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin'}: $poin', _poinColor, Icons.star_rounded),
                      _detailChip('${subs.length} ${widget.lang == 'EN' ? 'sub-cat' : widget.lang == 'ZH' ? '子类' : 'sub-kat'}', _subColor, Icons.list_alt_rounded),
                      _detailChip(widget.isKts ? 'KTS' : '5R', widget.isKts ? const Color(0xFF0891B2) : const Color(0xFF6366F1), Icons.label_rounded),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: subs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/team_illustration.png',
                            width: 150,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.lang == 'EN' ? 'No sub-categories yet' : widget.lang == 'ZH' ? '暂无子分类' : 'Belum ada sub-kategori',
                            style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.lang == 'EN'
                                ? 'Add sub-categories to organize this category better'
                                : widget.lang == 'ZH'
                                    ? '添加子分类以更好地组织此分类'
                                    : 'Tambahkan sub-kategori untuk mengelompokkan kategori ini',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: subs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final sub = subs[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.color.withValues(alpha:0.14)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30, height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _subColor.withValues(alpha:0.12),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text('${i + 1}', style: GoogleFonts.poppins(color: _subColor, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(sub['nama_subkategoritemuan'] ?? '-',
                                  style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.w600))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _poinColor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text('${sub['poin_subkategoritemuan'] ?? 0} pt',
                                    style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                      label: Text(widget.lang == 'EN' ? 'Edit' : widget.lang == 'ZH' ? '编辑' : 'Ubah',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (dctx) => AdminEditCategoryDialog(
                            lang: widget.lang,
                            isKts: widget.isKts,
                            color: widget.color,
                            item: item,
                            onSaved: _load,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
                      label: Text(widget.lang == 'EN' ? 'Delete' : widget.lang == 'ZH' ? '删除' : 'Hapus',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _deleteItem(item['id_kategoritemuan'], item['nama_kategoritemuan'] ?? '');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _deleteItem(String id, String name) async {
    final ok = await _confirmDeleteDialog(context, name, widget.lang);
    if (!ok) return;
    try {
      await Supabase.instance.client.from('kategoritemuan').delete().eq('id_kategoritemuan', id);
      if (mounted) {
        setState(() {
          _data.removeWhere((d) => d['id_kategoritemuan'] == id);
        });
      }
      _load();
    } catch (e) {
      debugPrint('Error delete kategori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lang == 'EN' ? 'Failed to delete' : widget.lang == 'ZH' ? '删除失败' : 'Gagal menghapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _filtered;
    final totalPages = data.isEmpty ? 1 : (data.length / kAdminCategoryListPageSize).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * kAdminCategoryListPageSize;
    final endIdx = (startIdx + kAdminCategoryListPageSize) > data.length ? data.length : startIdx + kAdminCategoryListPageSize;
    final pageItems = data.isEmpty ? <Map<String, dynamic>>[] : data.sublist(startIdx, endIdx);
    final addTitle = widget.lang == 'EN'
        ? 'Add New Category'
        : widget.lang == 'ZH' ? '添加新分类' : 'Tambah Kategori Baru';
    final addSubtitle = widget.lang == 'EN'
        ? 'Tap to add a new category'
        : widget.lang == 'ZH' ? '点击以添加新分类' : 'Ketuk untuk menambah kategori baru';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Banner Add Button ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (ctx) => AdminAddCategoryDialog(
                  lang: widget.lang,
                  isKts: widget.isKts,
                  color: widget.color,
                  onSaved: _load,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha:0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: widget.color.withValues(alpha:0.35), blurRadius: 12, offset: const Offset(0, 4)),
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
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(addTitle, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text(addSubtitle, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha:0.85))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha:0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() { _search = v; _currentPage = 1; }),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.lang == 'EN' ? 'Search categories...' : widget.lang == 'ZH' ? '搜索分类...' : 'Cari kategori...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // ── Filter Row ──
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterRow(),
          ),
          const SizedBox(height: 8),
          // ── Active chips ──
          if (_buildActiveChips() != null) _buildActiveChips()!,
          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.color.withValues(alpha:0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_rounded, size: 13, color: widget.color),
                    const SizedBox(width: 5),
                    Text(
                      '${data.length} ${widget.lang == 'EN' ? 'categories' : widget.lang == 'ZH' ? '个分类' : 'kategori'}',
                      style: GoogleFonts.poppins(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : data.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.color,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildCard(pageItems[i]),
                        ),
                      ),
          ),
          if (!_isLoading && data.isNotEmpty && totalPages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AdminCategoryPageIndicator(
                currentPage: safePage,
                totalPages: totalPages,
                onPageChanged: (p) => setState(() => _currentPage = p),
                color: widget.color,
                horizontalMargin: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final subs = List<Map<String, dynamic>>.from(item['subkategoritemuan'] as List? ?? []);
    final poin = item['poin_kategoritemuan'] ?? 0;
    final nama = _localizedNama(item);

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha:0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: widget.color.withValues(alpha:0.10), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.category_rounded, color: widget.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip('${subs.length} sub', _subColor, Icons.list_alt_rounded),
                      _chip('$poin pt', _poinColor, Icons.star_rounded),
                    ],
                  ),
                ],
              ),
            ),
            // ── Edit & chevron ──
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (ctx) => AdminEditCategoryDialog(
                  lang: widget.lang,
                  isKts: widget.isKts,
                  color: widget.color,
                  item: item,
                  onSaved: _load,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
              ),
            ),
            GestureDetector(
              onTap: () => _deleteItem(item['id_kategoritemuan'], nama),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.20)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(height: 88, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              width: 190,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(widget.lang == 'EN' ? 'No categories yet' : widget.lang == 'ZH' ? '暂无分类' : 'Belum ada kategori',
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(widget.lang == 'EN' ? 'Tap + to add your first category' : widget.lang == 'ZH' ? '点击+添加您的第一个分类' : 'Tekan + untuk menambah kategori pertama',
                style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DAFTAR SUB-KATEGORI
// ============================================================
class _SubkategoriList extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;

  const _SubkategoriList({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
  });

  @override
  State<_SubkategoriList> createState() => _SubkategoriListState();
}

class _SubkategoriListState extends State<_SubkategoriList>
  with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _allKategori = [];
  bool _isLoading = true;
  String _search = '';
  String _sortPoin = 'none';
  String _sortOrder = 'none';
  int _currentPage = 1;

  static const _bg = Color(0xFFF8FAFC);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SubkategoriList old) {
    super.didUpdateWidget(old);
    if (old.isKts != widget.isKts) _loadIfEmpty();
  }

  Future<void> _loadIfEmpty() async {
    if (_data.isEmpty) {
      _load();
    } else {
      setState(() {});
    }
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('subkategoritemuan')
            .select(
              'id_subkategoritemuan, id_kategoritemuan, '
              'nama_subkategoritemuan, nama_subkategoritemuan_en, '
              'nama_subkategoritemuan_zh, deskripsi_subkategoritemuan, '
              'deskripsi_subkategoritemuan_en, deskripsi_subkategoritemuan_zh, '
              'poin_subkategoritemuan, '
              'kategoritemuan(id_kategoritemuan, nama_kategoritemuan, '
              'nama_kategoritemuan_en, nama_kategoritemuan_zh, '
              'deskripsi_kategoritemuan, deskripsi_kategoritemuan_en, '
              'deskripsi_kategoritemuan_zh, poin_kategoritemuan, jenis_kategori)',
            )
            .order('nama_subkategoritemuan'),
        Supabase.instance.client
            .from('kategoritemuan')
            .select('id_kategoritemuan, nama_kategoritemuan, nama_kategoritemuan_en, nama_kategoritemuan_zh, jenis_kategori')
            .order('nama_kategoritemuan'),
      ]);

      final allSub = List<Map<String, dynamic>>.from(results[0] as List);
      final allKat = List<Map<String, dynamic>>.from(results[1] as List);

      final filteredSub = allSub.where((sub) {
        final jenis = (sub['kategoritemuan']?['jenis_kategori'] ?? '').toString().toUpperCase();
        if (widget.isKts) return jenis == 'KTS';
        return jenis == '5R';
      }).toList();

      final filteredKat = allKat.where((k) {
        final jenis = (k['jenis_kategori'] ?? '').toString().toUpperCase();
        if (widget.isKts) return jenis == 'KTS';
        return jenis == '5R';
      }).toList();

      if (mounted) {
        setState(() {
          _data = filteredSub;
          _allKategori = filteredKat;
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      debugPrint('Error load subkategori: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _localizedNama(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['nama_subkategoritemuan_en'] ?? item['nama_subkategoritemuan'] ?? '-').toString();
      case 'ZH':
        return (item['nama_subkategoritemuan_zh'] ?? item['nama_subkategoritemuan'] ?? '-').toString();
      default:
        return (item['nama_subkategoritemuan'] ?? '-').toString();
    }
  }

  String _localizedDesk(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['deskripsi_subkategoritemuan_en'] ?? item['deskripsi_subkategoritemuan'] ?? '').toString();
      case 'ZH':
        return (item['deskripsi_subkategoritemuan_zh'] ?? item['deskripsi_subkategoritemuan'] ?? '').toString();
      default:
        return (item['deskripsi_subkategoritemuan'] ?? '').toString();
    }
  }

  String _localizedParentNama(Map<String, dynamic> item) {
    final parent = item['kategoritemuan'];
    if (parent == null) return '-';
    switch (widget.lang) {
      case 'EN':
        return (parent['nama_kategoritemuan_en'] ?? parent['nama_kategoritemuan'] ?? '-').toString();
      case 'ZH':
        return (parent['nama_kategoritemuan_zh'] ?? parent['nama_kategoritemuan'] ?? '-').toString();
      default:
        return (parent['nama_kategoritemuan'] ?? '-').toString();
    }
  }

  String _localizedParentDesk(Map<String, dynamic> item) {
    final parent = item['kategoritemuan'];
    if (parent == null) return '';
    switch (widget.lang) {
      case 'EN':
        return (parent['deskripsi_kategoritemuan_en'] ?? parent['deskripsi_kategoritemuan'] ?? '').toString();
      case 'ZH':
        return (parent['deskripsi_kategoritemuan_zh'] ?? parent['deskripsi_kategoritemuan'] ?? '').toString();
      default:
        return (parent['deskripsi_kategoritemuan'] ?? '').toString();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_data);

    if (q.isNotEmpty) {
      result = result
          .where((d) => _localizedNama(d).toLowerCase().contains(q))
          .toList();
    }
    if (_sortPoin == 'asc') {
      result.sort((a, b) => ((a['poin_subkategoritemuan'] ?? 0) as int)
          .compareTo((b['poin_subkategoritemuan'] ?? 0) as int));
    } else if (_sortPoin == 'desc') {
      result.sort((a, b) => ((b['poin_subkategoritemuan'] ?? 0) as int)
          .compareTo((a['poin_subkategoritemuan'] ?? 0) as int));
    }
    if (_sortOrder == 'asc') {
      result.sort((a, b) => _localizedNama(a).compareTo(_localizedNama(b)));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => _localizedNama(b).compareTo(_localizedNama(a)));
    }
    return result;
  }

  Widget? _buildActiveChips() {
    final chips = <Widget>[];
    if (_sortPoin != 'none') {
      chips.add(_buildFilterChip(
        _sortPoin == 'asc' ? '⭐ Poin ↑' : '⭐ Poin ↓',
        widget.color,
        () => setState(() { _sortPoin = 'none'; _currentPage = 1; }),
      ));
    }
    if (_sortOrder != 'none') {
      chips.add(_buildFilterChip(
        _sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
        widget.color,
        () => setState(() { _sortOrder = 'none'; _currentPage = 1; }),
      ));
    }
    if (chips.isEmpty) return null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildFilterChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        GestureDetector(onTap: onRemove, child: Icon(Icons.close_rounded, size: 13, color: color)),
      ]),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            label: widget.lang == 'EN' ? 'Sort by Points' : widget.lang == 'ZH' ? '按积分排序' : 'Urut Poin',
            icon: Icons.star_rounded,
            isActive: _sortPoin != 'none',
            activeLabel: _sortPoin == 'asc' ? '↑' : _sortPoin == 'desc' ? '↓' : null,
            onTap: _showPoinSortDialog,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            label: widget.lang == 'EN' ? 'Sort' : widget.lang == 'ZH' ? '排序' : 'Urutan',
            icon: Icons.sort_by_alpha_rounded,
            isActive: _sortOrder != 'none',
            activeLabel: _sortOrder == 'asc' ? 'A→Z' : _sortOrder == 'desc' ? 'Z→A' : null,
            onTap: _showSortDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    String? activeLabel,
  }) {
    final color = widget.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : Colors.grey.shade200, width: isActive ? 1.5 : 1),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha:0.2), blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                isActive && activeLabel != null ? '$label $activeLabel' : label,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.white : color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  void _showPoinSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSortOptionDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Sort by Points' : widget.lang == 'ZH' ? '按积分排序' : 'Urut berdasarkan Poin',
        icon: Icons.star_rounded,
        color: widget.color,
        currentValue: _sortPoin,
        options: [
          {'value': 'none', 'label': widget.lang == 'EN' ? 'Default' : widget.lang == 'ZH' ? '默认' : 'Default'},
          {'value': 'desc', 'label': widget.lang == 'EN' ? 'Highest Points First' : widget.lang == 'ZH' ? '积分从高到低' : 'Poin Terbesar Dulu'},
          {'value': 'asc', 'label': widget.lang == 'EN' ? 'Lowest Points First' : widget.lang == 'ZH' ? '积分从低到高' : 'Poin Terkecil Dulu'},
        ],
        onSelect: (v) { setState(() { _sortPoin = v; _currentPage = 1; }); Navigator.pop(ctx); },
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSortOptionDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Sort Order' : widget.lang == 'ZH' ? '排序方式' : 'Urutan Abjad',
        icon: Icons.sort_by_alpha_rounded,
        color: widget.color,
        currentValue: _sortOrder,
        options: [
          {'value': 'none', 'label': widget.lang == 'EN' ? 'Default (No Sort)' : widget.lang == 'ZH' ? '默认' : 'Default (Tanpa Urutan)'},
          {'value': 'asc', 'label': 'A → Z (Ascending)'},
          {'value': 'desc', 'label': 'Z → A (Descending)'},
        ],
        onSelect: (v) { setState(() { _sortOrder = v; _currentPage = 1; }); Navigator.pop(ctx); },
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    final parent = item['kategoritemuan'];
    final parentNama = _localizedParentNama(item);
    final parentDescRaw = _localizedParentDesk(item);
    final parentDesc = parentDescRaw.isEmpty ? '-' : parentDescRaw;
    final parentPoin = parent?['poin_kategoritemuan'] ?? 0;
    final poin = item['poin_subkategoritemuan'] ?? 0;
    final descRaw = _localizedDesk(item);
    final desc = descRaw.isEmpty ? '-' : descRaw;
    final nama = _localizedNama(item);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color.withValues(alpha:0.14), widget.color.withValues(alpha:0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha:0.18),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: widget.color.withValues(alpha:0.25), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Icon(Icons.list_alt_rounded, color: widget.color, size: 24),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 6)]),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(nama, style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w800, fontSize: 19)),
                    if (desc != '-') ...[
                      const SizedBox(height: 8),
                      Text(desc, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13.5, height: 1.5)),
                    ],
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _detailChip('$poin pt', const Color(0xFFF59E0B), Icons.star_rounded),
                      _detailChip(widget.isKts ? 'KTS' : '5R', widget.color, Icons.label_rounded),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.account_tree_rounded, size: 13, color: Colors.black45),
                    const SizedBox(width: 5),
                    Text(widget.lang == 'EN' ? 'Parent Category' : widget.lang == 'ZH' ? '父分类' : 'Kategori Induk',
                        style: GoogleFonts.poppins(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF6366F1).withValues(alpha:0.08), const Color(0xFF6366F1).withValues(alpha:0.02)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha:0.18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha:0.14), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.category_rounded, color: Color(0xFF6366F1), size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(parentNama, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w700, fontSize: 13.5)),
                          if (parentDesc != '-') ...[
                            const SizedBox(height: 3),
                            Text(parentDesc, style: GoogleFonts.poppins(color: Colors.black54, fontSize: 11.5, height: 1.4)),
                          ],
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha:0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text('$parentPoin pt',
                            style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: Colors.grey.shade100, thickness: 1, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                        label: Text(widget.lang == 'EN' ? 'Edit' : widget.lang == 'ZH' ? '编辑' : 'Ubah',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (dctx) => AdminEditSubcategoryDialog(
                              lang: widget.lang,
                              isKts: widget.isKts,
                              color: widget.color,
                              item: item,
                              kategoriList: _allKategori,
                              onSaved: _load,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
                        label: Text(widget.lang == 'EN' ? 'Delete' : widget.lang == 'ZH' ? '删除' : 'Hapus',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async { Navigator.pop(ctx); await _deleteItem(item['id_subkategoritemuan'], item['nama_subkategoritemuan'] ?? ''); },
                      ),
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

  Widget _detailChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _deleteItem(String id, String name) async {
    final ok = await _confirmDeleteDialog(context, name, widget.lang);
    if (!ok) return;
    try {
      await Supabase.instance.client.from('subkategoritemuan').delete().eq('id_subkategoritemuan', id);
      if (mounted) {
        setState(() {
          _data.removeWhere((d) => d['id_subkategoritemuan'] == id);
        });
      }
      _load();
    } catch (e) {
      debugPrint('Error delete subkategori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lang == 'EN' ? 'Failed to delete' : widget.lang == 'ZH' ? '删除失败' : 'Gagal menghapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _filtered;
    final totalPages = data.isEmpty ? 1 : (data.length / kAdminCategoryListPageSize).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * kAdminCategoryListPageSize;
    final endIdx = (startIdx + kAdminCategoryListPageSize) > data.length ? data.length : startIdx + kAdminCategoryListPageSize;
    final pageItems = data.isEmpty ? <Map<String, dynamic>>[] : data.sublist(startIdx, endIdx);
    final addTitle = widget.lang == 'EN'
        ? 'Add New Sub-Category'
        : widget.lang == 'ZH' ? '添加新子分类' : 'Tambah Sub-Kategori Baru';
    final addSubtitle = widget.lang == 'EN'
        ? 'Tap to add a new sub-category'
        : widget.lang == 'ZH' ? '点击以添加新子分类' : 'Ketuk untuk menambah sub-kategori baru';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Banner Add Button ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (ctx) => AdminAddSubcategoryDialog(
                  lang: widget.lang,
                  isKts: widget.isKts,
                  color: widget.color,
                  kategoriList: _allKategori,
                  onSaved: _load,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha:0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: widget.color.withValues(alpha:0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.25), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(addTitle, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text(addSubtitle, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha:0.85))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha:0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() { _search = v; _currentPage = 1; }),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.lang == 'EN' ? 'Search sub-categories...' : widget.lang == 'ZH' ? '搜索子分类...' : 'Cari sub-kategori...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // ── Filter Row ──
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterRow(),
          ),
          const SizedBox(height: 8),
          // ── Active chips ──
          if (_buildActiveChips() != null) _buildActiveChips()!,
          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.color.withValues(alpha:0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt_rounded, size: 13, color: widget.color),
                    const SizedBox(width: 5),
                    Text(
                      '${data.length} sub-${widget.lang == 'EN' ? 'categories' : widget.lang == 'ZH' ? '分类' : 'kategori'}',
                      style: GoogleFonts.poppins(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : data.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.color,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildCard(pageItems[i]),
                        ),
                      ),
          ),
          if (!_isLoading && data.isNotEmpty && totalPages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AdminCategoryPageIndicator(
                currentPage: safePage,
                totalPages: totalPages,
                onPageChanged: (p) => setState(() => _currentPage = p),
                color: widget.color,
                horizontalMargin: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final parentNama = _localizedParentNama(item);
    final poin = item['poin_subkategoritemuan'] ?? 0;
    final nama = _localizedNama(item);

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha:0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: widget.color.withValues(alpha:0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.list_alt_rounded, color: widget.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha:0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha:0.20)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.category_rounded, size: 11, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(parentNama,
                            style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 10.5, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha:0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha:0.25)),
                    ),
                    child: Text('$poin pt', style: GoogleFonts.poppins(color: const Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (ctx) => AdminEditSubcategoryDialog(
                  lang: widget.lang,
                  isKts: widget.isKts,
                  color: widget.color,
                  item: item,
                  kategoriList: _allKategori,
                  onSaved: _load,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha:0.10), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
              ),
            ),
            GestureDetector(
              onTap: () => _deleteItem(item['id_subkategoritemuan'], nama),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha:0.10), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              width: 190,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(widget.lang == 'EN' ? 'No sub-categories yet' : widget.lang == 'ZH' ? '暂无子分类' : 'Belum ada sub-kategori',
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(widget.lang == 'EN' ? 'Tap + to add your first sub-category' : widget.lang == 'ZH' ? '点击+添加您的第一个子分类' : 'Tekan + untuk menambah sub-kategori pertama',
                style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHARED: Konfirmasi hapus
// ============================================================
Future<bool> _confirmDeleteDialog(
    BuildContext context, String name, String lang) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFEF4444),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  lang == 'EN'
                      ? 'Delete?'
                      : lang == 'ZH'
                          ? '删除？'
                          : 'Hapus?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${lang == 'EN' ? 'Are you sure to delete' : lang == 'ZH' ? '确定要删除' : 'Yakin menghapus'} "$name"?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.delete_forever_rounded,
                        color: Colors.white, size: 18),
                    label: Text(
                      lang == 'EN'
                          ? 'Delete'
                          : lang == 'ZH'
                              ? '删除'
                              : 'Hapus',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFE2E8F0), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      lang == 'EN'
                          ? 'Cancel'
                          : lang == 'ZH'
                              ? '取消'
                              : 'Batal',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

// ─────────────────────────────────────────
// SHARED: Sort option dialog (reusable)
// ─────────────────────────────────────────
Widget _buildSortOptionDialog({
  required BuildContext ctx,
  required String title,
  required IconData icon,
  required Color color,
  required String currentValue,
  required List<Map<String, String>> options,
  required void Function(String) onSelect,
}) {
  return Dialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)))),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: options.map((opt) {
              final isSelected = currentValue == opt['value'];
              return GestureDetector(
                onTap: () => onSelect(opt['value']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha:0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(opt['label']!, style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : const Color(0xFF1E3A8A)))),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}