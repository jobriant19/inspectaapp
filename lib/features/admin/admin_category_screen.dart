import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  int _selectedTab = 0;

  static const _bg      = Color(0xFFF8FAFC);
  static const _primary = Color(0xFF6366F1);
  // Warna sesuai menu Category di admin_home_screen
  static const _katColor    = Color(0xFFF59E0B); // amber — Kategori tab
  static const _subKatColor = Color(0xFFF59E0B); // amber — Sub-Kategori tab
  // 0 = 5R Finding, 1 = KTS Production

  @override
  void initState() {
    super.initState();
    // Tab utama sekarang adalah Kategori/Sub-Kategori
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() {});
        }
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
        shadowColor: Colors.black.withOpacity(0.08),
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
                  lang: widget.lang,
                  isKts: _selectedTab == 1,
                  color: _selectedTab == 0
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFFBBF24),
                ),
                _SubkategoriList(
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

  // ── Filter Pills: 5R / KTS ──
  Widget _buildFilterPills() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedTab = 0;
                _tabCtrl.animateTo(0);
              }),
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
              onTap: () => setState(() {
                _selectedTab = 1;
                _tabCtrl.animateTo(0);
              }),
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
                        : const Color(0xFFFBBF24).withOpacity(0.5),
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

  static const _bg = Color(0xFFF8FAFC);

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
            'id_kategoritemuan, nama_kategoritemuan, '
            'deskripsi_kategoritemuan, poin_kategoritemuan, jenis_kategori, '
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
        });
      }
    } catch (e) {
      debugPrint('Error load kategori: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_data);

    if (q.isNotEmpty) {
      result = result.where((d) => (d['nama_kategoritemuan'] ?? '')
          .toString().toLowerCase().contains(q)).toList();
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
      result.sort((a, b) => (a['nama_kategoritemuan'] ?? '')
          .toString().compareTo((b['nama_kategoritemuan'] ?? '').toString()));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => (b['nama_kategoritemuan'] ?? '')
          .toString().compareTo((a['nama_kategoritemuan'] ?? '').toString()));
    }
    return result;
  }

  Widget? _buildActiveChips() {
    final chips = <Widget>[];
    if (_sortPoin != 'none') {
      chips.add(_buildFilterChip(
        _sortPoin == 'asc' ? '⭐ Poin ↑' : '⭐ Poin ↓',
        widget.color,
        () => setState(() { _sortPoin = 'none'; }),
      ));
    }
    if (_sortOrder != 'none') {
      chips.add(_buildFilterChip(
        _sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
        widget.color,
        () => setState(() { _sortOrder = 'none'; }),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
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
          setState(() => _sortPoin = v);
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
          setState(() => _sortOrder = v);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_kategoritemuan'] ?? '');
    final descCtrl = TextEditingController(text: item?['deskripsi_kategoritemuan'] ?? '');
    final poinCtrl = TextEditingController(
        text: (item?['poin_kategoritemuan'] ?? 0).toString());
    final String jenisKategori = widget.isKts ? 'KTS' : '5R';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LightFormDialog(
        title: isEdit
            ? (widget.lang == 'EN' ? 'Edit Category' : widget.lang == 'ZH' ? '编辑分类' : 'Edit Kategori')
            : (widget.lang == 'EN' ? 'Add Category' : widget.lang == 'ZH' ? '添加分类' : 'Tambah Kategori'),
        icon: Icons.category_rounded,
        color: widget.color,
        lang: widget.lang,
        badge: widget.isKts ? 'KTS Production' : '5R Finding',
        fields: [
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Category Name' : widget.lang == 'ZH' ? '分类名称' : 'Nama Kategori',
            ctrl: namaCtrl,
            icon: Icons.category_rounded,
          ),
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
            ctrl: descCtrl,
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin',
            ctrl: poinCtrl,
            icon: Icons.star_rounded,
            keyboardType: TextInputType.number,
          ),
        ],
        onSave: () async {
          if (namaCtrl.text.trim().isEmpty) return;
          final data = {
            'nama_kategoritemuan': namaCtrl.text.trim(),
            'deskripsi_kategoritemuan':
                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            'poin_kategoritemuan': int.tryParse(poinCtrl.text.trim()) ?? 0,
            'jenis_kategori': jenisKategori,
          };
          if (isEdit) {
            await Supabase.instance.client
                .from('kategoritemuan')
                .update(data)
                .eq('id_kategoritemuan', item!['id_kategoritemuan']);
          } else {
            await Supabase.instance.client.from('kategoritemuan').insert(data);
          }
          _load();
        },
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    // (sama persis, tidak berubah — salin dari versi asli)
    final subs = List<Map<String, dynamic>>.from(
        item['subkategoritemuan'] as List? ?? []);
    final poin = item['poin_kategoritemuan'] ?? 0;
    final desc = item['deskripsi_kategoritemuan'] ?? '-';
    final nama = item['nama_kategoritemuan'] ?? '-';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.category_rounded, color: widget.color, size: 22),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(nama, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(desc, style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _detailChip('${widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin'}: $poin', const Color(0xFFFBBF24), Icons.star_rounded),
                      const SizedBox(width: 8),
                      _detailChip('${subs.length} ${widget.lang == 'EN' ? 'sub-cat' : widget.lang == 'ZH' ? '子类' : 'sub-kat'}', widget.color, Icons.list_alt_rounded),
                      const SizedBox(width: 8),
                      _detailChip(widget.isKts ? 'KTS' : '5R', widget.isKts ? const Color(0xFF0891B2) : const Color(0xFF6366F1), Icons.label_rounded),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: subs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(widget.lang == 'EN' ? 'No sub-categories yet' : widget.lang == 'ZH' ? '暂无子分类' : 'Belum ada sub-kategori',
                              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 13)),
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
                            color: widget.color.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.color.withOpacity(0.12)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: widget.color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.list_alt_rounded, color: widget.color, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(sub['nama_subkategoritemuan'] ?? '-',
                                  style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.w500))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFFBBF24).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text('${sub['poin_subkategoritemuan'] ?? 0} pt',
                                    style: GoogleFonts.poppins(color: const Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w600)),
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
                      onPressed: () { Navigator.pop(ctx); _showAddEditDialog(item: item); },
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
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
    await Supabase.instance.client.from('kategoritemuan').delete().eq('id_kategoritemuan', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _filtered;
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
              onTap: () => _showAddEditDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
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
                          Text(addSubtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.85))),
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
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
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
              child: Text(
                '${data.length} ${widget.lang == 'EN' ? 'categories' : widget.lang == 'ZH' ? '个分类' : 'kategori'}',
                style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: data.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildCard(data[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final subs = List<Map<String, dynamic>>.from(item['subkategoritemuan'] as List? ?? []);
    final poin = item['poin_kategoritemuan'] ?? 0;
    final desc = item['deskripsi_kategoritemuan'] ?? '';
    final nama = item['nama_kategoritemuan'] ?? '-';

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: widget.color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.category_rounded, color: widget.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 14)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc, style: GoogleFonts.poppins(color: Colors.black45, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip('${subs.length} sub', widget.color, Icons.list_alt_rounded),
                      _chip('$poin pt', const Color(0xFFFBBF24), Icons.star_rounded),
                    ],
                  ),
                ],
              ),
            ),
            // ── Edit & chevron ──
            GestureDetector(
              onTap: () => _showAddEditDialog(item: item),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final ok = await _confirmDeleteDialog(context, nama, widget.lang);
                if (ok) await _deleteItem(item['id_kategoritemuan'], nama);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.10),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.20)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: widget.color.withOpacity(0.06), shape: BoxShape.circle),
            child: Icon(Icons.category_outlined, size: 48, color: widget.color.withOpacity(0.4)),
          ),
          const SizedBox(height: 12),
          Text(widget.lang == 'EN' ? 'No categories yet' : widget.lang == 'ZH' ? '暂无分类' : 'Belum ada kategori',
              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(widget.lang == 'EN' ? 'Tap + to add' : widget.lang == 'ZH' ? '点击+添加' : 'Tekan + untuk menambah',
              style: GoogleFonts.poppins(color: Colors.black26, fontSize: 12)),
        ],
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
              'nama_subkategoritemuan, deskripsi_subkategoritemuan, '
              'poin_subkategoritemuan, '
              'kategoritemuan(id_kategoritemuan, nama_kategoritemuan, '
              'deskripsi_kategoritemuan, poin_kategoritemuan, jenis_kategori)',
            )
            .order('nama_subkategoritemuan'),
        Supabase.instance.client
            .from('kategoritemuan')
            .select('id_kategoritemuan, nama_kategoritemuan, jenis_kategori')
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
        });
      }
    } catch (e) {
      debugPrint('Error load subkategori: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_data);

    if (q.isNotEmpty) {
      result = result.where((d) => (d['nama_subkategoritemuan'] ?? '')
          .toString().toLowerCase().contains(q)).toList();
    }
    if (_sortPoin == 'asc') {
      result.sort((a, b) => ((a['poin_subkategoritemuan'] ?? 0) as int)
          .compareTo((b['poin_subkategoritemuan'] ?? 0) as int));
    } else if (_sortPoin == 'desc') {
      result.sort((a, b) => ((b['poin_subkategoritemuan'] ?? 0) as int)
          .compareTo((a['poin_subkategoritemuan'] ?? 0) as int));
    }
    if (_sortOrder == 'asc') {
      result.sort((a, b) => (a['nama_subkategoritemuan'] ?? '')
          .toString().compareTo((b['nama_subkategoritemuan'] ?? '').toString()));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => (b['nama_subkategoritemuan'] ?? '')
          .toString().compareTo((a['nama_subkategoritemuan'] ?? '').toString()));
    }
    return result;
  }

  Widget? _buildActiveChips() {
    final chips = <Widget>[];
    if (_sortPoin != 'none') {
      chips.add(_buildFilterChip(
        _sortPoin == 'asc' ? '⭐ Poin ↑' : '⭐ Poin ↓',
        widget.color,
        () => setState(() => _sortPoin = 'none'),
      ));
    }
    if (_sortOrder != 'none') {
      chips.add(_buildFilterChip(
        _sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
        widget.color,
        () => setState(() => _sortOrder = 'none'),
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] : [],
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
        onSelect: (v) { setState(() => _sortPoin = v); Navigator.pop(ctx); },
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
        onSelect: (v) { setState(() => _sortOrder = v); Navigator.pop(ctx); },
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_subkategoritemuan'] ?? '');
    final descCtrl = TextEditingController(text: item?['deskripsi_subkategoritemuan'] ?? '');
    final poinCtrl = TextEditingController(text: (item?['poin_subkategoritemuan'] ?? 0).toString());
    String? selectedKatId = item?['id_kategoritemuan']?.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _LightFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Sub-Category' : widget.lang == 'ZH' ? '编辑子分类' : 'Edit Sub-Kategori')
              : (widget.lang == 'EN' ? 'Add Sub-Category' : widget.lang == 'ZH' ? '添加子分类' : 'Tambah Sub-Kategori'),
          icon: Icons.list_alt_rounded,
          color: widget.color,
          lang: widget.lang,
          badge: widget.isKts ? 'KTS Production' : '5R Finding',
          fields: [
            _FieldConfig(
              label: widget.lang == 'EN' ? 'Sub-Category Name' : widget.lang == 'ZH' ? '子分类名称' : 'Nama Sub-Kategori',
              ctrl: namaCtrl, icon: Icons.list_alt_rounded,
            ),
            _FieldConfig(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              ctrl: descCtrl, icon: Icons.notes_rounded, maxLines: 3,
            ),
            _FieldConfig(
              label: widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin',
              ctrl: poinCtrl, icon: Icons.star_rounded, keyboardType: TextInputType.number,
            ),
          ],
          extraWidget: _KategoriDropdown(
            lang: widget.lang,
            color: widget.color,
            items: _allKategori,
            selectedId: selectedKatId,
            onChanged: (v) => setDlg(() => selectedKatId = v),
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty || selectedKatId == null) return;
            final data = {
              'id_kategoritemuan': selectedKatId,
              'nama_subkategoritemuan': namaCtrl.text.trim(),
              'deskripsi_subkategoritemuan': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              'poin_subkategoritemuan': int.tryParse(poinCtrl.text.trim()) ?? 0,
            };
            if (isEdit) {
              await Supabase.instance.client.from('subkategoritemuan').update(data).eq('id_subkategoritemuan', item!['id_subkategoritemuan']);
            } else {
              await Supabase.instance.client.from('subkategoritemuan').insert(data);
            }
            _load();
          },
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    final parent = item['kategoritemuan'];
    final parentNama = parent?['nama_kategoritemuan'] ?? '-';
    final parentDesc = parent?['deskripsi_kategoritemuan'] ?? '-';
    final parentPoin = parent?['poin_kategoritemuan'] ?? 0;
    final poin = item['poin_subkategoritemuan'] ?? 0;
    final desc = item['deskripsi_subkategoritemuan'] ?? '-';
    final nama = item['nama_subkategoritemuan'] ?? '-';

    showDialog(
      context: context,
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.07),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: widget.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.list_alt_rounded, color: widget.color, size: 22),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(nama, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w800, fontSize: 18)),
                    if (desc != '-') ...[
                      const SizedBox(height: 4),
                      Text(desc, style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13)),
                    ],
                    const SizedBox(height: 12),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      _detailChip('$poin pt', const Color(0xFFFBBF24), Icons.star_rounded),
                      _detailChip(widget.isKts ? 'KTS' : '5R', widget.color, Icons.label_rounded),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(widget.lang == 'EN' ? 'Parent Category' : widget.lang == 'ZH' ? '父分类' : 'Kategori Induk',
                    style: GoogleFonts.poppins(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.category_rounded, color: Color(0xFF6366F1), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(parentNama, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13)),
                          if (parentDesc != '-') ...[
                            const SizedBox(height: 2),
                            Text(parentDesc, style: GoogleFonts.poppins(color: Colors.black38, fontSize: 11)),
                          ],
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFBBF24).withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                        child: Text('$parentPoin pt',
                            style: GoogleFonts.poppins(color: const Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w600)),
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
                        onPressed: () { Navigator.pop(ctx); _showAddEditDialog(item: item); },
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
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
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
    await Supabase.instance.client.from('subkategoritemuan').delete().eq('id_subkategoritemuan', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _filtered;
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
              onTap: () => _showAddEditDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(addTitle, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text(addSubtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.85))),
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
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
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
              child: Text(
                '${data.length} sub-${widget.lang == 'EN' ? 'categories' : widget.lang == 'ZH' ? '分类' : 'kategori'}',
                style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: data.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildCard(data[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final parentNama = item['kategoritemuan']?['nama_kategoritemuan'] ?? '-';
    final poin = item['poin_subkategoritemuan'] ?? 0;
    final desc = item['deskripsi_subkategoritemuan'] ?? '';
    final nama = item['nama_subkategoritemuan'] ?? '-';

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: widget.color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.list_alt_rounded, color: widget.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.category_rounded, size: 11, color: Colors.black38),
                    const SizedBox(width: 4),
                    Expanded(child: Text(parentNama,
                        style: GoogleFonts.poppins(color: Colors.black38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc, style: GoogleFonts.poppins(color: Colors.black26, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.25)),
                    ),
                    child: Text('$poin pt', style: GoogleFonts.poppins(color: const Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showAddEditDialog(item: item),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final ok = await _confirmDeleteDialog(context, nama, widget.lang);
                if (ok) await _deleteItem(item['id_subkategoritemuan'], nama);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: widget.color.withOpacity(0.06), shape: BoxShape.circle),
            child: Icon(Icons.list_alt_outlined, size: 48, color: widget.color.withOpacity(0.4)),
          ),
          const SizedBox(height: 12),
          Text(widget.lang == 'EN' ? 'No sub-categories yet' : widget.lang == 'ZH' ? '暂无子分类' : 'Belum ada sub-kategori',
              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(widget.lang == 'EN' ? 'Tap + to add' : widget.lang == 'ZH' ? '点击+添加' : 'Tekan + untuk menambah',
              style: GoogleFonts.poppins(color: Colors.black26, fontSize: 12)),
        ],
      ),
    );
  }
}

// ============================================================
// SHARED: Dropdown Kategori untuk form sub-kategori
// ============================================================
class _KategoriDropdown extends StatelessWidget {
  final String lang;
  final Color color;
  final List<Map<String, dynamic>> items;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _KategoriDropdown({
    required this.lang,
    required this.color,
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang == 'EN' ? 'Parent Category' : lang == 'ZH' ? '父分类' : 'Kategori Induk',
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedId,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.black45),
              hint: Text(
                lang == 'EN' ? 'Select category' : lang == 'ZH' ? '选择分类' : 'Pilih kategori',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 13),
              ),
              items: items.map((k) {
                return DropdownMenuItem<String>(
                  value: k['id_kategoritemuan'].toString(),
                  child: Text(
                    k['nama_kategoritemuan'] ?? '-',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SHARED: Light Form Dialog (cerah, konsisten)
// ============================================================
class _FieldConfig {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _FieldConfig({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });
}

class _LightFormDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String lang;
  final String badge;
  final List<_FieldConfig> fields;
  final Widget? extraWidget;
  final Future<void> Function() onSave;

  const _LightFormDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.lang,
    required this.badge,
    required this.fields,
    required this.onSave,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close,
                        size: 18, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Badge jenis ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_rounded, color: color, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    badge,
                    style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100, thickness: 1.5),
            const SizedBox(height: 14),

            // ── Extra widget (dropdown parent) ──
            if (extraWidget != null) ...[
              extraWidget!,
              const SizedBox(height: 16),
            ],

            // ── Fields ──
            ...fields.map((f) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.label,
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: f.ctrl,
                        maxLines: f.maxLines,
                        keyboardType: f.keyboardType,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: f.label,
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.black26, fontSize: 13),
                          prefixIcon: f.maxLines == 1
                              ? Icon(f.icon,
                                  color: Colors.black38, size: 18)
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                )),

            // ── Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.grey.shade600,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      lang == 'EN' ? 'Cancel' : lang == 'ZH' ? '取消' : 'Batal',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await onSave();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: color.withOpacity(0.3),
                    ),
                    child: Text(
                      lang == 'EN' ? 'Save' : lang == 'ZH' ? '保存' : 'Simpan',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            lang == 'EN' ? 'Delete?' : lang == 'ZH' ? '删除？' : 'Hapus?',
            style: GoogleFonts.poppins(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${lang == 'EN' ? 'Delete' : lang == 'ZH' ? '删除' : 'Hapus'} "$name"?',
            style:
                GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                lang == 'EN' ? 'Cancel' : lang == 'ZH' ? '取消' : 'Batal',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                lang == 'EN' ? 'Delete' : lang == 'ZH' ? '删除' : 'Hapus',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
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
            color: color.withOpacity(0.04),
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
                    color: isSelected ? color.withOpacity(0.08) : Colors.white,
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