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

  static const _bg    = Color(0xFFF8FAFC);
  static const _primary = Color(0xFF6366F1);

  // 0 = 5R Finding, 1 = KTS Production
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() => _selectedTab = _tabCtrl.index);
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
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.06),
        title: Text(
          widget.lang == 'EN' ? 'Category Management' : 'Kelola Kategori',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: Colors.black38,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cleaning_services_rounded, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '5R Finding',
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
                  const Icon(Icons.precision_manufacturing_rounded, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'KTS Production',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 0: 5R — semua kategori KECUALI KTS Produksi
          _CategoryTabView(
            lang: widget.lang,
            isKts: false,
          ),
          // Tab 1: KTS Production — hanya KTS Produksi
          _CategoryTabView(
            lang: widget.lang,
            isKts: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB VIEW: Kategori + Sub-Kategori dalam satu layar
// ============================================================
class _CategoryTabView extends StatefulWidget {
  final String lang;
  final bool isKts; // true = KTS Produksi saja, false = semua kecuali KTS

  const _CategoryTabView({
    required this.lang,
    required this.isKts,
  });

  @override
  State<_CategoryTabView> createState() => _CategoryTabViewState();
}

class _CategoryTabViewState extends State<_CategoryTabView>
    with SingleTickerProviderStateMixin {
  late TabController _innerTab;

  static const _primaryKts   = Color(0xFF0891B2); // biru KTS
  static const _primary5r    = Color(0xFF6366F1); // ungu 5R
  static const _bg           = Color(0xFFF8FAFC);

  Color get _color => widget.isKts ? _primaryKts : _primary5r;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Inner Tab: Kategori / Sub-Kategori ──
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _innerTab,
            indicatorColor: _color,
            labelColor: _color,
            unselectedLabelColor: Colors.black38,
            indicatorWeight: 2.5,
            tabs: [
              Tab(
                child: Text(
                  widget.lang == 'EN' ? 'Categories' : 'Kategori',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Tab(
                child: Text(
                  widget.lang == 'EN' ? 'Sub-Categories' : 'Sub-Kategori',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTab,
            children: [
              _KategoriList(
                lang: widget.lang,
                isKts: widget.isKts,
                color: _color,
              ),
              _SubkategoriList(
                lang: widget.lang,
                isKts: widget.isKts,
                color: _color,
              ),
            ],
          ),
        ),
      ],
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

class _KategoriListState extends State<_KategoriList> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _search = '';

  static const _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_KategoriList old) {
    super.didUpdateWidget(old);
    if (old.isKts != widget.isKts) _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('kategoritemuan')
          .select(
            'id_kategoritemuan, nama_kategoritemuan, '
            'deskripsi_kategoritemuan, poin_kategoritemuan, '
            'subkategoritemuan(id_subkategoritemuan, '
            'nama_subkategoritemuan, poin_subkategoritemuan)',
          )
          .order('nama_kategoritemuan');

      final all = List<Map<String, dynamic>>.from(res);

      // Filter:
      // isKts=true  → hanya "KTS Produksi"
      // isKts=false → semua KECUALI "KTS Produksi"
      final filtered = all.where((item) {
        final nama =
            (item['nama_kategoritemuan'] ?? '').toString().toLowerCase();
        final isKtsItem = nama.contains('kts');
        return widget.isKts ? isKtsItem : !isKtsItem;
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
    if (q.isEmpty) return _data;
    return _data
        .where((d) => (d['nama_kategoritemuan'] ?? '')
            .toString()
            .toLowerCase()
            .contains(q))
        .toList();
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(
        text: item?['nama_kategoritemuan'] ?? '');
    final descCtrl = TextEditingController(
        text: item?['deskripsi_kategoritemuan'] ?? '');
    final poinCtrl = TextEditingController(
        text: (item?['poin_kategoritemuan'] ?? 0).toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LightFormDialog(
        title: isEdit
            ? (widget.lang == 'EN' ? 'Edit Category' : 'Edit Kategori')
            : (widget.lang == 'EN'
                ? 'Add Category'
                : 'Tambah Kategori'),
        icon: Icons.category_rounded,
        color: widget.color,
        lang: widget.lang,
        badge: widget.isKts ? 'KTS Production' : '5R Finding',
        fields: [
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Category Name' : 'Nama Kategori',
            ctrl: namaCtrl,
            icon: Icons.category_rounded,
          ),
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Description' : 'Deskripsi',
            ctrl: descCtrl,
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Points' : 'Poin',
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
            'poin_kategoritemuan':
                int.tryParse(poinCtrl.text.trim()) ?? 0,
          };
          if (isEdit) {
            await Supabase.instance.client
                .from('kategoritemuan')
                .update(data)
                .eq('id_kategoritemuan', item!['id_kategoritemuan']);
          } else {
            await Supabase.instance.client
                .from('kategoritemuan')
                .insert(data);
          }
          _load();
        },
      ),
    );
  }

  // ── Detail Dialog saat card diklik ──
  void _showDetail(Map<String, dynamic> item) {
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
            // ── Header berwarna ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
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
                        child: Icon(Icons.category_rounded,
                            color: widget.color, size: 22),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
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
                  Text(
                    nama,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                        color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _detailChip(
                        '${widget.lang == 'EN' ? 'Points' : 'Poin'}: $poin',
                        const Color(0xFFFBBF24),
                        Icons.star_rounded,
                      ),
                      const SizedBox(width: 8),
                      _detailChip(
                        '${subs.length} ${widget.lang == 'EN' ? 'sub-cat' : 'sub-kat'}',
                        widget.color,
                        Icons.list_alt_rounded,
                      ),
                      const SizedBox(width: 8),
                      _detailChip(
                        widget.isKts ? 'KTS' : '5R',
                        widget.isKts
                            ? const Color(0xFF0891B2)
                            : const Color(0xFF6366F1),
                        Icons.label_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Sub-kategori list ──
            Flexible(
              child: subs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 48,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            widget.lang == 'EN'
                                ? 'No sub-categories yet'
                                : 'Belum ada sub-kategori',
                            style: GoogleFonts.poppins(
                                color: Colors.black38, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: subs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final sub = subs[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    widget.color.withOpacity(0.12)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      widget.color.withOpacity(0.10),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.list_alt_rounded,
                                    color: widget.color, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  sub['nama_subkategoritemuan'] ??
                                      '-',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1E3A8A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBBF24)
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${sub['poin_subkategoritemuan'] ?? 0} pt',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFD97706),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ── Action buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.edit_outlined,
                          size: 16, color: widget.color),
                      label: Text(
                        widget.lang == 'EN' ? 'Edit' : 'Ubah',
                        style: GoogleFonts.poppins(
                            color: widget.color,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: widget.color),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddEditDialog(item: item);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.white),
                      label: Text(
                        widget.lang == 'EN' ? 'Delete' : 'Hapus',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _deleteItem(
                          item['id_kategoritemuan'],
                          item['nama_kategoritemuan'] ?? '',
                        );
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String id, String name) async {
    final ok = await _confirmDeleteDialog(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client
        .from('kategoritemuan')
        .delete()
        .eq('id_kategoritemuan', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: widget.color,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          widget.lang == 'EN' ? 'Add Category' : 'Tambah Kategori',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.lang == 'EN'
                      ? 'Search categories...'
                      : 'Cari kategori...',
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} ${widget.lang == 'EN' ? 'categories' : 'kategori'}',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.color,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              16, 8, 16, 100),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final subs = List<Map<String, dynamic>>.from(
        item['subkategoritemuan'] as List? ?? []);
    final poin = item['poin_kategoritemuan'] ?? 0;
    final desc = item['deskripsi_kategoritemuan'] ?? '';
    final nama = item['nama_kategoritemuan'] ?? '-';

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ikon ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.category_rounded,
                  color: widget.color, size: 22),
            ),
            const SizedBox(width: 14),

            // ── Konten ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: GoogleFonts.poppins(
                          color: Colors.black45, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip(
                        '${subs.length} ${widget.lang == 'EN' ? 'sub' : 'sub'}',
                        widget.color,
                        Icons.list_alt_rounded,
                      ),
                      _chip(
                        '$poin pt',
                        const Color(0xFFFBBF24),
                        Icons.star_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tap hint ──
            Icon(Icons.chevron_right_rounded,
                color: Colors.black26, size: 20),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category_outlined,
                size: 48, color: widget.color.withOpacity(0.4)),
          ),
          const SizedBox(height: 12),
          Text(
            widget.lang == 'EN'
                ? 'No categories yet'
                : 'Belum ada kategori',
            style: GoogleFonts.poppins(
                color: Colors.black38,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            widget.lang == 'EN'
                ? 'Tap + to add'
                : 'Tekan + untuk menambah',
            style: GoogleFonts.poppins(
                color: Colors.black26, fontSize: 12),
          ),
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

class _SubkategoriListState extends State<_SubkategoriList> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _allKategori = [];
  bool _isLoading = true;
  String _search = '';

  static const _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SubkategoriList old) {
    super.didUpdateWidget(old);
    if (old.isKts != widget.isKts) _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('subkategoritemuan')
            .select(
              'id_subkategoritemuan, id_kategoritemuan, '
              'nama_subkategoritemuan, deskripsi_subkategoritemuan, '
              'poin_subkategoritemuan, '
              'kategoritemuan(id_kategoritemuan, nama_kategoritemuan, '
              'deskripsi_kategoritemuan, poin_kategoritemuan)',
            )
            .order('nama_subkategoritemuan'),
        Supabase.instance.client
            .from('kategoritemuan')
            .select('id_kategoritemuan, nama_kategoritemuan')
            .order('nama_kategoritemuan'),
      ]);

      final allSub = List<Map<String, dynamic>>.from(results[0] as List);
      final allKat = List<Map<String, dynamic>>.from(results[1] as List);

      // Filter sub berdasarkan nama parent kategorinya
      final filteredSub = allSub.where((sub) {
        final parentNama = (sub['kategoritemuan']?['nama_kategoritemuan']
                    ?? '')
                .toString()
                .toLowerCase();
        final isKtsItem = parentNama.contains('kts');
        return widget.isKts ? isKtsItem : !isKtsItem;
      }).toList();

      // Filter kategori untuk dropdown
      final filteredKat = allKat.where((k) {
        final nama =
            (k['nama_kategoritemuan'] ?? '').toString().toLowerCase();
        final isKtsItem = nama.contains('kts');
        return widget.isKts ? isKtsItem : !isKtsItem;
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
    if (q.isEmpty) return _data;
    return _data
        .where((d) => (d['nama_subkategoritemuan'] ?? '')
            .toString()
            .toLowerCase()
            .contains(q))
        .toList();
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(
        text: item?['nama_subkategoritemuan'] ?? '');
    final descCtrl = TextEditingController(
        text: item?['deskripsi_subkategoritemuan'] ?? '');
    final poinCtrl = TextEditingController(
        text: (item?['poin_subkategoritemuan'] ?? 0).toString());
    String? selectedKatId = item?['id_kategoritemuan']?.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _LightFormDialog(
          title: isEdit
              ? (widget.lang == 'EN'
                  ? 'Edit Sub-Category'
                  : 'Edit Sub-Kategori')
              : (widget.lang == 'EN'
                  ? 'Add Sub-Category'
                  : 'Tambah Sub-Kategori'),
          icon: Icons.list_alt_rounded,
          color: widget.color,
          lang: widget.lang,
          badge: widget.isKts ? 'KTS Production' : '5R Finding',
          fields: [
            _FieldConfig(
              label: widget.lang == 'EN'
                  ? 'Sub-Category Name'
                  : 'Nama Sub-Kategori',
              ctrl: namaCtrl,
              icon: Icons.list_alt_rounded,
            ),
            _FieldConfig(
              label: widget.lang == 'EN' ? 'Description' : 'Deskripsi',
              ctrl: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            _FieldConfig(
              label: widget.lang == 'EN' ? 'Points' : 'Poin',
              ctrl: poinCtrl,
              icon: Icons.star_rounded,
              keyboardType: TextInputType.number,
            ),
          ],
          // Dropdown parent kategori
          extraWidget: _KategoriDropdown(
            lang: widget.lang,
            color: widget.color,
            items: _allKategori,
            selectedId: selectedKatId,
            onChanged: (v) => setDlg(() => selectedKatId = v),
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty || selectedKatId == null) {
              return;
            }
            final data = {
              'id_kategoritemuan': selectedKatId,
              'nama_subkategoritemuan': namaCtrl.text.trim(),
              'deskripsi_subkategoritemuan':
                  descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
              'poin_subkategoritemuan':
                  int.tryParse(poinCtrl.text.trim()) ?? 0,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('subkategoritemuan')
                  .update(data)
                  .eq('id_subkategoritemuan',
                      item!['id_subkategoritemuan']);
            } else {
              await Supabase.instance.client
                  .from('subkategoritemuan')
                  .insert(data);
            }
            _load();
          },
        ),
      ),
    );
  }

  // ── Detail Dialog saat card diklik ──
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.07),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
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
                          child: Icon(Icons.list_alt_rounded,
                              color: widget.color, size: 22),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.close,
                                size: 18,
                                color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      nama,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    if (desc != '-') ...[
                      const SizedBox(height: 4),
                      Text(desc,
                          style: GoogleFonts.poppins(
                              color: Colors.black54, fontSize: 13)),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _detailChip('$poin pt',
                            const Color(0xFFFBBF24), Icons.star_rounded),
                        _detailChip(
                          widget.isKts ? 'KTS' : '5R',
                          widget.color,
                          Icons.label_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Parent info ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  widget.lang == 'EN'
                      ? 'Parent Category'
                      : 'Kategori Induk',
                  style: GoogleFonts.poppins(
                    color: Colors.black45,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.category_rounded,
                            color: Color(0xFF6366F1), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parentNama,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (parentDesc != '-') ...[
                              const SizedBox(height: 2),
                              Text(parentDesc,
                                  style: GoogleFonts.poppins(
                                      color: Colors.black38,
                                      fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$parentPoin pt',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFFD97706),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Divider ──
              Divider(
                  color: Colors.grey.shade100,
                  thickness: 1,
                  height: 1),

              // ── Action buttons ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.edit_outlined,
                            size: 16, color: widget.color),
                        label: Text(
                          widget.lang == 'EN' ? 'Edit' : 'Ubah',
                          style: GoogleFonts.poppins(
                              color: widget.color,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: widget.color),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddEditDialog(item: item);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.white),
                        label: Text(
                          widget.lang == 'EN' ? 'Delete' : 'Hapus',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _deleteItem(
                            item['id_subkategoritemuan'],
                            item['nama_subkategoritemuan'] ?? '',
                          );
                        },
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _deleteItem(String id, String name) async {
    final ok = await _confirmDeleteDialog(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client
        .from('subkategoritemuan')
        .delete()
        .eq('id_subkategoritemuan', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: widget.color,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          widget.lang == 'EN' ? 'Add Sub-Cat' : 'Tambah Sub',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.lang == 'EN'
                      ? 'Search sub-categories...'
                      : 'Cari sub-kategori...',
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} sub-${widget.lang == 'EN' ? 'categories' : 'kategori'}',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.color,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              16, 8, 16, 100),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final parentNama =
        item['kategoritemuan']?['nama_kategoritemuan'] ?? '-';
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
          border:
              Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.list_alt_rounded,
                  color: widget.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.category_rounded,
                          size: 11, color: Colors.black38),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          parentNama,
                          style: GoogleFonts.poppins(
                              color: Colors.black38, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc,
                        style: GoogleFonts.poppins(
                            color: Colors.black26, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFBBF24).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFFFBBF24)
                              .withOpacity(0.25)),
                    ),
                    child: Text(
                      '$poin pt',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFD97706),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.black26, size: 20),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
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
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.list_alt_outlined,
                size: 48, color: widget.color.withOpacity(0.4)),
          ),
          const SizedBox(height: 12),
          Text(
            widget.lang == 'EN'
                ? 'No sub-categories yet'
                : 'Belum ada sub-kategori',
            style: GoogleFonts.poppins(
                color: Colors.black38,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            widget.lang == 'EN'
                ? 'Tap + to add'
                : 'Tekan + untuk menambah',
            style: GoogleFonts.poppins(
                color: Colors.black26, fontSize: 12),
          ),
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
          lang == 'EN' ? 'Parent Category' : 'Kategori Induk',
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
                lang == 'EN' ? 'Select category' : 'Pilih kategori',
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
                      lang == 'EN' ? 'Cancel' : 'Batal',
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
                      lang == 'EN' ? 'Save' : 'Simpan',
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
            lang == 'EN' ? 'Delete?' : 'Hapus?',
            style: GoogleFonts.poppins(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${lang == 'EN' ? 'Delete' : 'Hapus'} "$name"?',
            style:
                GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                lang == 'EN' ? 'Cancel' : 'Batal',
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
                lang == 'EN' ? 'Delete' : 'Hapus',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ) ??
      false;
}