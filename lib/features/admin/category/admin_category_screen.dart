import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_add_category.dart';
import 'admin_add_subcategory.dart';
import 'admin_category_detail.dart';
import 'admin_category_filter.dart';
import 'admin_category_indicator.dart';
import 'admin_edit_category.dart';
import 'admin_edit_subcategory.dart';
import 'admin_subcategory_detail.dart';

class AdminCategoryScreen extends StatefulWidget {
  final String lang;
  const AdminCategoryScreen({super.key, required this.lang});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedTab = 0; 

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
                            ? 'Subcategories'
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
  String _sortPoin = 'none';
  String _sortOrder = 'none';
  int _currentPage = 1;
  final TextEditingController _searchCtrl = TextEditingController();

  static const _bg = Color(0xFFF8FAFC);
  static const _subColor = Color(0xFF8B5CF6);
  static const _poinColor = Color(0xFFF59E0B);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _search = '';
      _currentPage = 1;
    });
  }

  @override
  void didUpdateWidget(_KategoriList old) {
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

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_data);

    if (q.isNotEmpty) {
      result = result
          .where((d) => _localizedNama(d).toLowerCase().contains(q))
          .toList();
    }
    // SORT BY POINTS
    if (_sortPoin == 'asc') {
      result.sort((a, b) => ((a['poin_kategoritemuan'] ?? 0) as int)
          .compareTo((b['poin_kategoritemuan'] ?? 0) as int));
    } else if (_sortPoin == 'desc') {
      result.sort((a, b) => ((b['poin_kategoritemuan'] ?? 0) as int)
          .compareTo((a['poin_kategoritemuan'] ?? 0) as int));
    }
    // SORT BY NAME
    if (_sortOrder == 'asc') {
      result.sort((a, b) => _localizedNama(a).compareTo(_localizedNama(b)));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => _localizedNama(b).compareTo(_localizedNama(a)));
    }
    return result;
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
          // ADD BUTTON
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
          // SEARCH
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
                controller: _searchCtrl,
                onChanged: (v) => setState(() { _search = v; _currentPage = 1; }),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.lang == 'EN' ? 'Search categories...' : widget.lang == 'ZH' ? '搜索分类...' : 'Cari kategori...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha:0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // FILTER ROW
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdminCategoryFilterBar(
              lang: widget.lang,
              color: widget.color,
              sortPoin: _sortPoin,
              sortOrder: _sortOrder,
              onSortPoinChanged: (v) => setState(() { _sortPoin = v; _currentPage = 1; }),
              onSortOrderChanged: (v) => setState(() { _sortOrder = v; _currentPage = 1; }),
            ),
          ),
          const SizedBox(height: 8),
          // ACTIVE CHIPS
          AdminCategoryActiveChips(
            sortPoin: _sortPoin,
            sortOrder: _sortOrder,
            color: widget.color,
            onSortPoinChanged: (v) => setState(() { _sortPoin = v; _currentPage = 1; }),
            onSortOrderChanged: (v) => setState(() { _sortOrder = v; _currentPage = 1; }),
          ),
          // COUNT
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
          // LIST
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
      onTap: () => AdminCategoryDetailDialog.show(
        context: context,
        lang: widget.lang,
        isKts: widget.isKts,
        color: widget.color,
        item: item,
        onSaved: _load,
        onDelete: _deleteItem,
      ),
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
            // EDIT 
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
    final isSearching = _search.isNotEmpty;
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
            Text(
              isSearching
                  ? (widget.lang == 'EN' ? 'No matching categories' : widget.lang == 'ZH' ? '未找到匹配分类' : 'Kategori Tidak Ditemukan')
                  : (widget.lang == 'EN' ? 'No categories yet' : widget.lang == 'ZH' ? '暂无分类' : 'Belum ada kategori'),
              style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 15, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? (widget.lang == 'EN'
                      ? 'Try adjusting your search keyword to find what you\'re looking for.'
                      : widget.lang == 'ZH'
                          ? '尝试调整搜索关键词以查找您需要的内容。'
                          : 'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.')
                  : (widget.lang == 'EN' ? 'Tap + to add your first category' : widget.lang == 'ZH' ? '点击+添加您的第一个分类' : 'Tekan + untuk menambah kategori pertama'),
              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.color.withValues(alpha:0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: widget.color),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'EN' ? 'Clear search' : widget.lang == 'ZH' ? '清除搜索' : 'Hapus pencarian',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: widget.color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
  final TextEditingController _searchCtrl = TextEditingController();

  static const _bg = Color(0xFFF8FAFC);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _search = '';
      _currentPage = 1;
    });
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
        ? 'Add New Subcategory'
        : widget.lang == 'ZH' ? '添加新子分类' : 'Tambah Sub-Kategori Baru';
    final addSubtitle = widget.lang == 'EN'
        ? 'Tap to add a new subcategory'
        : widget.lang == 'ZH' ? '点击以添加新子分类' : 'Ketuk untuk menambah sub-kategori baru';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ADD BUTTON
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
          // SEARCH
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
                controller: _searchCtrl,
                onChanged: (v) => setState(() { _search = v; _currentPage = 1; }),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.lang == 'EN' ? 'Search subcategories...' : widget.lang == 'ZH' ? '搜索子分类...' : 'Cari sub-kategori...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha:0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // FILTER ROW
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AdminCategoryFilterBar(
              lang: widget.lang,
              color: widget.color,
              sortPoin: _sortPoin,
              sortOrder: _sortOrder,
              onSortPoinChanged: (v) => setState(() { _sortPoin = v; _currentPage = 1; }),
              onSortOrderChanged: (v) => setState(() { _sortOrder = v; _currentPage = 1; }),
            ),
          ),
          const SizedBox(height: 8),
          // ACTIVE CHIPS
          AdminCategoryActiveChips(
            sortPoin: _sortPoin,
            sortOrder: _sortOrder,
            color: widget.color,
            onSortPoinChanged: (v) => setState(() { _sortPoin = v; _currentPage = 1; }),
            onSortOrderChanged: (v) => setState(() { _sortOrder = v; _currentPage = 1; }),
          ),
          // COUNT
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
                      '${data.length} ${widget.lang == 'EN' ? 'subcategories' : widget.lang == 'ZH' ? '子分类' : 'sub-kategori'}',
                      style: GoogleFonts.poppins(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // LIST
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
      onTap: () => AdminSubcategoryDetailDialog.show(
        context: context,
        lang: widget.lang,
        isKts: widget.isKts,
        color: widget.color,
        item: item,
        kategoriList: _allKategori,
        onSaved: _load,
        onDelete: _deleteItem,
      ),
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
    final isSearching = _search.isNotEmpty;
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
            Text(
              isSearching
                  ? (widget.lang == 'EN' ? 'No matching subcategories' : widget.lang == 'ZH' ? '未找到匹配子分类' : 'Sub-Kategori Tidak Ditemukan')
                  : (widget.lang == 'EN' ? 'No subcategories yet' : widget.lang == 'ZH' ? '暂无子分类' : 'Belum ada sub-kategori'),
              style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 15, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? (widget.lang == 'EN'
                      ? 'Try adjusting your search keyword to find what you\'re looking for.'
                      : widget.lang == 'ZH'
                          ? '尝试调整搜索关键词以查找您需要的内容。'
                          : 'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.')
                  : (widget.lang == 'EN' ? 'Tap + to add your first subcategory' : widget.lang == 'ZH' ? '点击+添加您的第一个子分类' : 'Tekan + untuk menambah sub-kategori pertama'),
              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.color.withValues(alpha:0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: widget.color),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'EN' ? 'Clear search' : widget.lang == 'ZH' ? '清除搜索' : 'Hapus pencarian',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: widget.color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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