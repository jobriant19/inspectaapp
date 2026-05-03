import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// ADMIN CATEGORY SCREEN — CRUD Kategori & Sub-Kategori per jenis_temuan
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

  static const _bg = Color(0xFFF8FAFC);
  static const _card = Color(0xFFFFFFFF);
  static const _primary = Color(0xFFF59E0B);

  // Daftar jenis_temuan yang tersedia
  static const List<String> _jenisList = [
    '5R',
    'KTS Production',
    'Safety',
    'Quality',
    'Environment',
    'Lainnya',
  ];

  final List<Color> _jenisBgColors = [
    const Color(0xFF1E40AF),
    const Color(0xFF065F46),
    const Color(0xFF7C2D12),
    const Color(0xFF5B21B6),
    const Color(0xFF064E3B),
    const Color(0xFF374151),
  ];

  final List<Color> _jenisColors = [
    const Color(0xFF60A5FA),
    const Color(0xFF34D399),
    const Color(0xFFFB923C),
    const Color(0xFFA78BFA),
    const Color(0xFF6EE7B7),
    const Color(0xFF9CA3AF),
  ];

  String _selectedJenis = '5R';
  List<Map<String, dynamic>> _kategoriList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadKategori();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    setState(() => _isLoading = true);
    try {
      // Ambil semua kategori beserta subkategori
      final res = await Supabase.instance.client
          .from('kategoritemuan')
          .select('id_kategoritemuan, nama_kategoritemuan, deskripsi_kategoritemuan, poin_kategoritemuan, subkategoritemuan(*)')
          .order('nama_kategoritemuan');
      if (mounted) {
        setState(() {
          _kategoriList = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading kategori: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        title: Text(
          widget.lang == 'EN' ? 'Category Management' : 'Kelola Kategori',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFF1E3A8A)),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: Colors.black38,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                      widget.lang == 'EN' ? 'Categories' : 'Kategori',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                      widget.lang == 'EN' ? 'Sub-Categories' : 'Sub-Kategori',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Jenis temuan filter pills
          _buildJenisPills(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _KategoriTab(
                  lang: widget.lang,
                  selectedJenis: _selectedJenis,
                  onRefresh: _loadKategori,
                ),
                _SubkategoriTab(
                  lang: widget.lang,
                  selectedJenis: _selectedJenis,
                  onRefresh: _loadKategori,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisPills() {
    return Container(
      color: Colors.white, // ← putih
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.lang == 'EN'
                  ? 'Finding Type Filter:'
                  : 'Filter Jenis Temuan:',
              style: GoogleFonts.poppins(
                  color: Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _jenisList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final jenis = _jenisList[i];
                final isSelected = jenis == _selectedJenis;
                final color = _jenisColors[i];
                final bgColor = _jenisBgColors[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedJenis = jenis),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? bgColor : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      jenis,
                      style: GoogleFonts.poppins(
                        color: isSelected ? color : Colors.white38,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB: KATEGORI TEMUAN
// ─────────────────────────────────────────
class _KategoriTab extends StatefulWidget {
  final String lang;
  final String selectedJenis;
  final VoidCallback onRefresh;

  const _KategoriTab({
    required this.lang,
    required this.selectedJenis,
    required this.onRefresh,
  });

  @override
  State<_KategoriTab> createState() => _KategoriTabState();
}

class _KategoriTabState extends State<_KategoriTab> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  static const _primary = Color(0xFFF59E0B);
  static const _bg = Color(0xFFF8FAFC);
  static const _card = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_KategoriTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedJenis != widget.selectedJenis) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Note: jenis_temuan disimpan di subkategoritemuan atau di level kategori
      // Karena skema yang ada, kita filter kategori berdasarkan nama yang mengandung jenis
      // atau simpan jenis di field deskripsi. 
      // Untuk fleksibilitas, kita tambahkan kolom jenis_temuan ke kategoritemuan via query khusus.
      // Di sini kita ambil semua dan filter by deskripsi yang menyertakan jenis.
      // Pendekatan terbaik: simpan jenis_temuan di deskripsi_kategoritemuan field
      // Format: "JENIS:5R|Deskripsi normal"
      final res = await Supabase.instance.client
          .from('kategoritemuan')
          .select('id_kategoritemuan, nama_kategoritemuan, deskripsi_kategoritemuan, poin_kategoritemuan, subkategoritemuan(count)')
          .order('nama_kategoritemuan');

      final all = List<Map<String, dynamic>>.from(res);
      // Filter berdasarkan jenis yang tersimpan di deskripsi
      final filtered = all.where((item) {
        final desc = (item['deskripsi_kategoritemuan'] ?? '').toString();
        if (desc.startsWith('JENIS:')) {
          final jenisPart = desc.split('|').first.replaceFirst('JENIS:', '');
          return jenisPart == widget.selectedJenis;
        }
        // Jika tidak ada tag jenis, tampilkan di '5R' sebagai default
        return widget.selectedJenis == '5R';
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

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_kategoritemuan'] ?? '');
    final descRaw = (item?['deskripsi_kategoritemuan'] ?? '').toString();
    final descDisplay = descRaw.startsWith('JENIS:')
        ? descRaw.split('|').skip(1).join('|')
        : descRaw;
    final descCtrl = TextEditingController(text: descDisplay);
    final poinCtrl = TextEditingController(
        text: (item?['poin_kategoritemuan'] ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        title: isEdit
            ? (widget.lang == 'EN' ? 'Edit Category' : 'Edit Kategori')
            : (widget.lang == 'EN' ? 'Add Category' : 'Tambah Kategori'),
        icon: Icons.category_rounded,
        color: _primary,
        lang: widget.lang,
        selectedJenis: widget.selectedJenis,
        namaCtrl: namaCtrl,
        descCtrl: descCtrl,
        poinCtrl: poinCtrl,
        onSave: () async {
          if (namaCtrl.text.trim().isEmpty) return;
          // Simpan jenis di deskripsi dengan format: "JENIS:{jenis}|{desc}"
          final descToSave =
              'JENIS:${widget.selectedJenis}|${descCtrl.text.trim()}';
          final data = {
            'nama_kategoritemuan': namaCtrl.text.trim(),
            'deskripsi_kategoritemuan': descToSave,
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
          widget.onRefresh();
        },
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _confirmDelete(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client
        .from('kategoritemuan')
        .delete()
        .eq('id_kategoritemuan', id);
    _load();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          widget.lang == 'EN' ? 'Add Category' : 'Tambah Kategori',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
            )
          : _data.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined, size: 48, color: Colors.white12),
                      const SizedBox(height: 12),
                      Text(
                        widget.lang == 'EN'
                            ? 'No categories for "${widget.selectedJenis}"'
                            : 'Belum ada kategori untuk "${widget.selectedJenis}"',
                        style: GoogleFonts.poppins(color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.lang == 'EN'
                            ? 'Tap + to add a new category'
                            : 'Tekan + untuk menambah kategori baru',
                        style:
                            GoogleFonts.poppins(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildCard(_data[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final subcount = (item['subkategoritemuan'] as List?)?.length ?? 0;
    final poin = item['poin_kategoritemuan'] ?? 0;
    final descRaw = (item['deskripsi_kategoritemuan'] ?? '').toString();
    final desc = descRaw.startsWith('JENIS:')
        ? descRaw.split('|').skip(1).join('|')
        : descRaw;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // ← putih
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_rounded,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nama_kategoritemuan'] ?? '-',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    if (desc.isNotEmpty)
                      Text(desc,
                          style: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Edit & Delete
              _iconBtn(
                  Icons.edit_outlined, const Color(0xFF6366F1),
                  () => _showDialog(item: item)),
              const SizedBox(width: 8),
              _iconBtn(
                  Icons.delete_outline_rounded, const Color(0xFFEF4444),
                  () => _delete(item['id_kategoritemuan'],
                      item['nama_kategoritemuan'] ?? '')),
            ],
          ),
          const SizedBox(height: 12),
          // Info chips
          Row(
            children: [
              _chip('${widget.lang == 'EN' ? 'Sub' : 'Sub'}: $subcount',
                  const Color(0xFF22D3EE)),
              const SizedBox(width: 8),
              _chip('${widget.lang == 'EN' ? 'Points' : 'Poin'}: $poin',
                  const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              _chip(widget.selectedJenis, const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB: SUB-KATEGORI TEMUAN
// ─────────────────────────────────────────
class _SubkategoriTab extends StatefulWidget {
  final String lang;
  final String selectedJenis;
  final VoidCallback onRefresh;

  const _SubkategoriTab({
    required this.lang,
    required this.selectedJenis,
    required this.onRefresh,
  });

  @override
  State<_SubkategoriTab> createState() => _SubkategoriTabState();
}

class _SubkategoriTabState extends State<_SubkategoriTab> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _kategoriFiltered = [];
  List<Map<String, dynamic>> _allKategori = [];
  bool _isLoading = true;
  String _search = '';

  static const _primary = Color(0xFF8B5CF6);
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SubkategoriTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedJenis != widget.selectedJenis) _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('subkategoritemuan')
            .select('id_subkategoritemuan, id_kategoritemuan, nama_subkategoritemuan, deskripsi_subkategoritemuan, poin_subkategoritemuan, kategoritemuan(id_kategoritemuan, nama_kategoritemuan, deskripsi_kategoritemuan)')
            .order('nama_subkategoritemuan'),
        Supabase.instance.client
            .from('kategoritemuan')
            .select('id_kategoritemuan, nama_kategoritemuan, deskripsi_kategoritemuan')
            .order('nama_kategoritemuan'),
      ]);

      final allSub = List<Map<String, dynamic>>.from(results[0] as List);
      final allKat = List<Map<String, dynamic>>.from(results[1] as List);

      // Filter subkategori yang parentnya termasuk jenis ini
      final filteredSub = allSub.where((sub) {
        final desc = (sub['kategoritemuan']?['deskripsi_kategoritemuan'] ?? '').toString();
        if (desc.startsWith('JENIS:')) {
          final jenisPart = desc.split('|').first.replaceFirst('JENIS:', '');
          return jenisPart == widget.selectedJenis;
        }
        return widget.selectedJenis == '5R';
      }).toList();

      // Filter kategori untuk dropdown
      final filteredKat = allKat.where((k) {
        final desc = (k['deskripsi_kategoritemuan'] ?? '').toString();
        if (desc.startsWith('JENIS:')) {
          final jenisPart = desc.split('|').first.replaceFirst('JENIS:', '');
          return jenisPart == widget.selectedJenis;
        }
        return widget.selectedJenis == '5R';
      }).toList();

      if (mounted) {
        setState(() {
          _data = filteredSub;
          _allKategori = filteredKat;
          _kategoriFiltered = filteredKat;
          _applySearch();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error load subkategori: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    final q = _search.toLowerCase();
    if (q.isEmpty) return;
    _data = _data
        .where((d) =>
            (d['nama_subkategoritemuan'] ?? '').toLowerCase().contains(q))
        .toList();
  }

  void _showDialog({Map<String, dynamic>? item}) {
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.list_alt_rounded,
                          color: _primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit
                          ? (widget.lang == 'EN'
                              ? 'Edit Sub-Category'
                              : 'Edit Sub-Kategori')
                          : (widget.lang == 'EN'
                              ? 'Add Sub-Category'
                              : 'Tambah Sub-Kategori'),
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Kategori parent dropdown
                _buildDlgLabel(
                    widget.lang == 'EN' ? 'Parent Category' : 'Kategori Induk'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedKatId,
                      isExpanded: true,
                      dropdownColor: _card,
                      hint: Text(
                        widget.lang == 'EN'
                            ? 'Select category'
                            : 'Pilih kategori',
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 13),
                      ),
                      items: _allKategori.map((k) {
                        return DropdownMenuItem<String>(
                          value: k['id_kategoritemuan'].toString(),
                          child: Text(
                            k['nama_kategoritemuan'] ?? '-',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setDlg(() => selectedKatId = v),
                      iconEnabledColor: Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildDlgLabel(widget.lang == 'EN'
                    ? 'Sub-Category Name'
                    : 'Nama Sub-Kategori'),
                _buildTextField(namaCtrl, Icons.list_alt_rounded),
                const SizedBox(height: 16),

                _buildDlgLabel(widget.lang == 'EN' ? 'Description' : 'Deskripsi'),
                _buildTextField(descCtrl, Icons.notes_rounded, maxLines: 3),
                const SizedBox(height: 16),

                _buildDlgLabel(widget.lang == 'EN' ? 'Points' : 'Poin'),
                _buildTextField(poinCtrl, Icons.star_rounded,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 24),

                // Info chip jenis
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primary.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.lang == 'EN' ? 'Finding Type' : 'Jenis Temuan'}: ${widget.selectedJenis}',
                          style: GoogleFonts.poppins(
                              color: _primary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          foregroundColor: Colors.white54,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                            widget.lang == 'EN' ? 'Cancel' : 'Batal',
                            style: GoogleFonts.poppins()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (namaCtrl.text.trim().isEmpty ||
                              selectedKatId == null) return;
                          Navigator.pop(ctx);
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
                          widget.onRefresh();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                            widget.lang == 'EN' ? 'Save' : 'Simpan',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _confirmDelete(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client
        .from('subkategoritemuan')
        .delete()
        .eq('id_subkategoritemuan', id);
    _load();
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          widget.lang == 'EN' ? 'Add Sub-Cat' : 'Tambah Sub',
          style: GoogleFonts.poppins(
              color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                onChanged: (v) => setState(() {
                  _search = v;
                  _load();
                }),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.lang == 'EN'
                      ? 'Search sub-categories...'
                      : 'Cari sub-kategori...',
                  hintStyle:
                      GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white38, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_data.length} ${widget.lang == 'EN' ? 'sub-categories' : 'sub-kategori'}',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primary))
                : _data.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list_alt_outlined,
                                size: 48, color: Colors.white12),
                            const SizedBox(height: 12),
                            Text(
                              widget.lang == 'EN'
                                  ? 'No sub-categories for "${widget.selectedJenis}"'
                                  : 'Belum ada sub-kategori untuk "${widget.selectedJenis}"',
                              style: GoogleFonts.poppins(color: Colors.white38),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _data.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildCard(_data[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final parentName =
        item['kategoritemuan']?['nama_kategoritemuan'] ?? '-';
    final poin = item['poin_subkategoritemuan'] ?? 0;
    final desc = item['deskripsi_subkategoritemuan'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.list_alt_rounded, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama_subkategoritemuan'] ?? '-',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.category_rounded,
                        size: 11, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(parentName,
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc,
                      style: GoogleFonts.poppins(
                          color: Colors.white24, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFFFBBF24).withOpacity(0.25)),
                  ),
                  child: Text(
                    '${widget.lang == 'EN' ? 'Points' : 'Poin'}: $poin',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _iconBtn(Icons.edit_outlined, const Color(0xFF6366F1),
                  () => _showDialog(item: item)),
              const SizedBox(height: 6),
              _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444),
                  () => _delete(
                      item['id_subkategoritemuan'],
                      item['nama_subkategoritemuan'] ?? '')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDlgLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _buildTextField(
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.white38, size: 18)
              : null,
          filled: true,
          fillColor: const Color(0xFF0F172A),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
      );
}

// ─────────────────────────────────────────
// SHARED: Form dialog for kategori
// ─────────────────────────────────────────
class _CategoryFormDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String lang;
  final String selectedJenis;
  final TextEditingController namaCtrl;
  final TextEditingController descCtrl;
  final TextEditingController poinCtrl;
  final Future<void> Function() onSave;

  const _CategoryFormDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.lang,
    required this.selectedJenis,
    required this.namaCtrl,
    required this.descCtrl,
    required this.poinCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    const card = Color(0xFF1E293B);

    return Dialog(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Jenis badge (read-only info)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_rounded, color: color, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '${lang == 'EN' ? 'Finding Type' : 'Jenis Temuan'}: $selectedJenis',
                    style: GoogleFonts.poppins(color: color, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _lbl(lang == 'EN' ? 'Category Name' : 'Nama Kategori'),
            _tf(namaCtrl, Icons.category_rounded, color),
            const SizedBox(height: 16),

            _lbl(lang == 'EN' ? 'Description' : 'Deskripsi'),
            _tf(descCtrl, Icons.notes_rounded, color, maxLines: 3),
            const SizedBox(height: 16),

            _lbl(lang == 'EN' ? 'Points' : 'Poin'),
            _tf(poinCtrl, Icons.star_rounded, color,
                keyboardType: TextInputType.number),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(lang == 'EN' ? 'Cancel' : 'Batal',
                        style: GoogleFonts.poppins()),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(lang == 'EN' ? 'Save' : 'Simpan',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lbl(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _tf(
    TextEditingController ctrl,
    IconData icon,
    Color activeColor, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.white38, size: 18)
              : null,
          filled: true,
          fillColor: const Color(0xFF0F172A),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: activeColor, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );
}

// ─────────────────────────────────────────
// SHARED: Konfirmasi hapus
// ─────────────────────────────────────────
Future<bool> _confirmDelete(
    BuildContext context, String name, String lang) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(lang == 'EN' ? 'Delete?' : 'Hapus?',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('${lang == 'EN' ? 'Delete' : 'Hapus'} "$name"?',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(lang == 'EN' ? 'Cancel' : 'Batal',
                  style: const TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text(lang == 'EN' ? 'Delete' : 'Hapus',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ??
      false;
}