import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../shared/code/qr_generator_screen.dart';

// ============================================================
// ADMIN LOCATION SCREEN — CRUD Lokasi → Unit → Subunit → Area
// ============================================================
class AdminLocationScreen extends StatefulWidget {
  final String lang;
  const AdminLocationScreen({super.key, required this.lang});

  @override
  State<AdminLocationScreen> createState() => _AdminLocationScreenState();
}

class _AdminLocationScreenState extends State<AdminLocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _primary = Color(0xFF10B981);
  static const _bg = Color(0xFFF8FAFC);
  static const _card = Color(0xFFFFFFFF);

  final List<IconData> _tabIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_rounded,
    Icons.place_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _lang => widget.lang;

  @override
  Widget build(BuildContext context) {
    final tabLabels = _lang == 'EN'
        ? ['Location', 'Unit', 'Sub-Unit', 'Area']
        : _lang == 'ZH'
            ? ['位置', '单位', '子单位', '区域']
            : ['Lokasi', 'Unit', 'Sub-Unit', 'Area'];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        shadowColor: Colors.black.withOpacity(0.08),
        title: Text(
          _lang == 'EN' ? 'Location Management' : _lang == 'ZH' ? '位置管理' : 'Kelola Lokasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E3A8A)),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: Colors.black38,
          indicatorWeight: 3,
          isScrollable: true,          // ← TAMBAH INI agar tidak overflow
          tabAlignment: TabAlignment.start, // ← rata kiri saat scrollable
          tabs: List.generate(
            4,
            (i) => Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tabIcons[i], size: 15),
                    const SizedBox(width: 5),
                    Text(
                      tabLabels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _LokasiTab(lang: _lang),
          _UnitTab(lang: _lang),
          _SubunitTab(lang: _lang),
          _AreaTab(lang: _lang),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB: LOKASI
// ─────────────────────────────────────────
class _LokasiTab extends StatefulWidget {
  final String lang;
  const _LokasiTab({required this.lang});

  @override
  State<_LokasiTab> createState() => _LokasiTabState();
}

class _LokasiTabState extends State<_LokasiTab> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _search = '';

  static const _primary = Color(0xFF10B981);
  static const _bg = Color(0xFF0F172A);
  static const _card = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
        .from('lokasi')
        .select('id_lokasi, nama_lokasi, deskripsi_lokasi, is_star, gambar_lokasi, kategori, qrcode, id_pic, User!fk_lokasi_pic(nama)')
        .order('nama_lokasi');
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(res);
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_data)
        : _data
            .where((d) => (d['nama_lokasi'] ?? '').toLowerCase().contains(q))
            .toList();
  }

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_lokasi'] ?? '');
    final descCtrl = TextEditingController(text: item?['deskripsi_lokasi'] ?? '');
    final kategoriCtrl = TextEditingController(text: item?['kategori'] ?? '');
    final gambarCtrl = TextEditingController(text: item?['gambar_lokasi'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => _AdminFormDialog(
        title: isEdit
            ? (widget.lang == 'EN' ? 'Edit Location' : widget.lang == 'ZH' ? '编辑位置' : 'Edit Lokasi')
            : (widget.lang == 'EN' ? 'Add Location' : widget.lang == 'ZH' ? '添加位置' : 'Tambah Lokasi'),
        icon: Icons.location_city_rounded,
        color: _primary,
        fields: [
          _FormField(
            label: widget.lang == 'EN' ? 'Location Name' : widget.lang == 'ZH' ? '位置名称' : 'Nama Lokasi',
            controller: namaCtrl,
            icon: Icons.location_city_rounded,
          ),
          _FormField(
            label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
            controller: descCtrl,
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          _FormField(
            label: widget.lang == 'EN' ? 'Category' : widget.lang == 'ZH' ? '类别' : 'Kategori',
            controller: kategoriCtrl,
            icon: Icons.category_rounded,
          ),
          _FormField(
            label: widget.lang == 'EN' ? 'Image URL' : widget.lang == 'ZH' ? '图片URL' : 'URL Gambar',
            controller: gambarCtrl,
            icon: Icons.image_outlined,
          ),
        ],
        lang: widget.lang,
        onSave: () async {
          if (namaCtrl.text.trim().isEmpty) return;
          final data = {
            'nama_lokasi': namaCtrl.text.trim(),
            'deskripsi_lokasi': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            'kategori': kategoriCtrl.text.trim().isEmpty ? null : kategoriCtrl.text.trim(),
            'gambar_lokasi': gambarCtrl.text.trim().isEmpty ? null : gambarCtrl.text.trim(),
          };
          if (isEdit) {
            await Supabase.instance.client
                .from('lokasi').update(data).eq('id_lokasi', item!['id_lokasi']);
          } else {
            await Supabase.instance.client.from('lokasi').insert(data);
          }
          _load();
        },
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _showConfirm(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client.from('lokasi').delete().eq('id_lokasi', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabContent(
      isLoading: _isLoading,
      search: _search,
      onSearch: (v) => setState(() {
        _search = v;
        _applyFilter();
      }),
      data: _filtered,
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_lokasi'] ?? '',
      subtitleFn: (item) => item['deskripsi_lokasi'] ?? '-',
      icon: Icons.location_city_rounded,
      onAdd: () => _showDialog(),
      onEdit: (item) => _showDialog(item: item),
      onDelete: (item) => _delete(item['id_lokasi'], item['nama_lokasi'] ?? ''),
      onRefresh: _load,
      onTapDetail: (item) => _showLocationDetailSheet(
        context: context,
        item: item,
        lang: widget.lang,
        primaryColor: _primary,
        icon: Icons.location_city_rounded,
        nameKey: 'lokasi',
        nameFn: (item) => item['nama_lokasi'] ?? '',
        subtitleFn: (item) => item['deskripsi_lokasi'] ?? '-',
        onEdit: (item) => _showDialog(item: item),
        onDelete: (item) => _delete(item['id_lokasi'], item['nama_lokasi'] ?? ''),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB: UNIT
// ─────────────────────────────────────────
class _UnitTab extends StatefulWidget {
  final String lang;
  const _UnitTab({required this.lang});

  @override
  State<_UnitTab> createState() => _UnitTabState();
}

class _UnitTabState extends State<_UnitTab> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _lokasiList = [];
  bool _isLoading = true;
  String _search = '';

  static const _primary = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('unit')
            .select('id_unit, nama_unit, deskripsi_unit, is_star, gambar_unit, kategori, qrcode, id_lokasi, id_pic, lokasi(nama_lokasi), User!fk_unit_pic(nama)')
            .order('nama_unit'),
        Supabase.instance.client
            .from('lokasi')
            .select('id_lokasi, nama_lokasi')
            .order('nama_lokasi'),
      ]);
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(results[0] as List);
          _lokasiList = List<Map<String, dynamic>>.from(results[1] as List);
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_data)
        : _data
            .where((d) => (d['nama_unit'] ?? '').toLowerCase().contains(q))
            .toList();
  }

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_unit'] ?? '');
    final descCtrl = TextEditingController(text: item?['deskripsi_unit'] ?? '');
    final kategoriCtrl = TextEditingController(text: item?['kategori'] ?? '');
    final gambarCtrl = TextEditingController(text: item?['gambar_unit'] ?? '');
    String? selectedLokasiId = item?['id_lokasi']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _AdminFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Unit' : widget.lang == 'ZH' ? '编辑单位' : 'Edit Unit')
              : (widget.lang == 'EN' ? 'Add Unit' : widget.lang == 'ZH' ? '添加单位' : 'Tambah Unit'),
          icon: Icons.business_rounded,
          color: _primary,
          lang: widget.lang,
          fields: [
            _FormField(
              label: widget.lang == 'EN' ? 'Unit Name' : widget.lang == 'ZH' ? '单位名称' : 'Nama Unit',
              controller: namaCtrl,
              icon: Icons.business_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Category' : widget.lang == 'ZH' ? '类别' : 'Kategori',
              controller: kategoriCtrl,
              icon: Icons.category_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Image URL' : widget.lang == 'ZH' ? '图片URL' : 'URL Gambar',
              controller: gambarCtrl,
              icon: Icons.image_outlined,
            ),
          ],
          extraWidget: _buildParentDropdown(
            label: widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi',
            items: _lokasiList,
            idKey: 'id_lokasi',
            nameKey: 'nama_lokasi',
            selectedId: selectedLokasiId,
            onChanged: (v) => setDlg(() => selectedLokasiId = v),
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty || selectedLokasiId == null) return;
            final data = {
              'nama_unit': namaCtrl.text.trim(),
              'deskripsi_unit': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              'kategori': kategoriCtrl.text.trim().isEmpty ? null : kategoriCtrl.text.trim(),
              'gambar_unit': gambarCtrl.text.trim().isEmpty ? null : gambarCtrl.text.trim(),
              'id_lokasi': selectedLokasiId,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('unit').update(data).eq('id_unit', item!['id_unit']);
            } else {
              await Supabase.instance.client.from('unit').insert(data);
            }
            _load();
          },
        ),
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _showConfirm(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client.from('unit').delete().eq('id_unit', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabContent(
      isLoading: _isLoading,
      search: _search,
      onSearch: (v) => setState(() {
        _search = v;
        _applyFilter();
      }),
      data: _filtered,
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_unit'] ?? '',
      subtitleFn: (item) => item['lokasi']?['nama_lokasi'] ?? '-',
      subtitleIcon: Icons.location_city_rounded,
      icon: Icons.business_rounded,
      onAdd: () => _showDialog(),
      onEdit: (item) => _showDialog(item: item),
      onDelete: (item) => _delete(item['id_unit'], item['nama_unit'] ?? ''),
      onRefresh: _load,
      onTapDetail: (item) => _showLocationDetailSheet(
        context: context,
        item: item,
        lang: widget.lang,
        primaryColor: _primary,
        icon: Icons.business_rounded,
        nameKey: 'unit',
        nameFn: (item) => item['nama_unit'] ?? '',
        subtitleFn: (item) => item['lokasi']?['nama_lokasi'] ?? '-',
        onEdit: (item) => _showDialog(item: item),
        onDelete: (item) => _delete(item['id_unit'], item['nama_unit'] ?? ''),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB: SUBUNIT
// ─────────────────────────────────────────
class _SubunitTab extends StatefulWidget {
  final String lang;
  const _SubunitTab({required this.lang});

  @override
  State<_SubunitTab> createState() => _SubunitTabState();
}

class _SubunitTabState extends State<_SubunitTab> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _unitList = [];
  bool _isLoading = true;
  String _search = '';

  static const _primary = Color(0xFFFBBF24);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('subunit')
            .select('id_subunit, nama_subunit, deskripsi_subunit, is_star, gambar_subunit, kategori, qrcode, id_unit, id_lokasi, id_pic, unit(nama_unit), lokasi(nama_lokasi), User!fk_subunit_pic(nama)')
            .order('nama_subunit'),
        Supabase.instance.client
            .from('unit')
            .select('id_unit, nama_unit')
            .order('nama_unit'),
      ]);
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(results[0] as List);
          _unitList = List<Map<String, dynamic>>.from(results[1] as List);
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_data)
        : _data
            .where((d) => (d['nama_subunit'] ?? '').toLowerCase().contains(q))
            .toList();
  }

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_subunit'] ?? '');
    final descCtrl = TextEditingController(text: item?['deskripsi_subunit'] ?? '');
    final kategoriCtrl = TextEditingController(text: item?['kategori'] ?? '');
    final gambarCtrl = TextEditingController(text: item?['gambar_subunit'] ?? '');
    String? selectedUnitId = item?['id_unit']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _AdminFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Sub-Unit' : widget.lang == 'ZH' ? '编辑子单位' : 'Edit Sub-Unit')
              : (widget.lang == 'EN' ? 'Add Sub-Unit' : widget.lang == 'ZH' ? '添加子单位' : 'Tambah Sub-Unit'),
          icon: Icons.layers_rounded,
          color: _primary,
          lang: widget.lang,
          fields: [
            _FormField(
              label: widget.lang == 'EN' ? 'Sub-Unit Name' : widget.lang == 'ZH' ? '子单位名称' : 'Nama Sub-Unit',
              controller: namaCtrl,
              icon: Icons.layers_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Category' : widget.lang == 'ZH' ? '类别' : 'Kategori',
              controller: kategoriCtrl,
              icon: Icons.category_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Image URL' : widget.lang == 'ZH' ? '图片URL' : 'URL Gambar',
              controller: gambarCtrl,
              icon: Icons.image_outlined,
            ),
          ],
          extraWidget: _buildParentDropdown(
            label: 'Unit',
            items: _unitList,
            idKey: 'id_unit',
            nameKey: 'nama_unit',
            selectedId: selectedUnitId,
            onChanged: (v) => setDlg(() => selectedUnitId = v),
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty || selectedUnitId == null) return;
            final data = {
              'nama_subunit': namaCtrl.text.trim(),
              'deskripsi_subunit': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              'kategori': kategoriCtrl.text.trim().isEmpty ? null : kategoriCtrl.text.trim(),
              'gambar_subunit': gambarCtrl.text.trim().isEmpty ? null : gambarCtrl.text.trim(),
              'id_unit': selectedUnitId,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('subunit').update(data).eq('id_subunit', item!['id_subunit']);
            } else {
              await Supabase.instance.client.from('subunit').insert(data);
            }
            _load();
          },
        ),
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _showConfirm(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client
        .from('subunit')
        .delete()
        .eq('id_subunit', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabContent(
      isLoading: _isLoading,
      search: _search,
      onSearch: (v) => setState(() {
        _search = v;
        _applyFilter();
      }),
      data: _filtered,
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_subunit'] ?? '',
      subtitleFn: (item) => item['unit']?['nama_unit'] ?? '-',
      subtitleIcon: Icons.business_rounded,
      icon: Icons.layers_rounded,
      onAdd: () => _showDialog(),
      onEdit: (item) => _showDialog(item: item),
      onDelete: (item) => _delete(item['id_subunit'], item['nama_subunit'] ?? ''),
      onRefresh: _load,
      onTapDetail: (item) => _showLocationDetailSheet(
        context: context,
        item: item,
        lang: widget.lang,
        primaryColor: _primary,
        icon: Icons.layers_rounded,
        nameKey: 'subunit',
        nameFn: (item) => item['nama_subunit'] ?? '',
        subtitleFn: (item) => item['unit']?['nama_unit'] ?? '-',
        onEdit: (item) => _showDialog(item: item),
        onDelete: (item) => _delete(item['id_subunit'], item['nama_subunit'] ?? ''),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB: AREA
// ─────────────────────────────────────────
class _AreaTab extends StatefulWidget {
  final String lang;
  const _AreaTab({required this.lang});

  @override
  State<_AreaTab> createState() => _AreaTabState();
}

class _AreaTabState extends State<_AreaTab> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _subunitList = [];
  bool _isLoading = true;
  String _search = '';

  static const _primary = Color(0xFFF472B6);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('area')
            .select('id_area, nama_area, deskripsi_area, is_star, gambar_area, kategori, qrcode, id_subunit, id_unit, id_lokasi, id_pic, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi), User!fk_area_pic(nama)')
            .order('nama_area'),
        Supabase.instance.client
            .from('subunit')
            .select('id_subunit, nama_subunit')
            .order('nama_subunit'),
      ]);
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(results[0] as List);
          _subunitList = List<Map<String, dynamic>>.from(results[1] as List);
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_data)
        : _data
            .where((d) => (d['nama_area'] ?? '').toLowerCase().contains(q))
            .toList();
  }

  void _showDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_area'] ?? '');
    final descCtrl = TextEditingController(text: item?['deskripsi_area'] ?? '');
    final kategoriCtrl = TextEditingController(text: item?['kategori'] ?? '');
    final gambarCtrl = TextEditingController(text: item?['gambar_area'] ?? '');
    String? selectedSubunitId = item?['id_subunit']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _AdminFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Area' : widget.lang == 'ZH' ? '编辑区域' : 'Edit Area')
              : (widget.lang == 'EN' ? 'Add Area' : widget.lang == 'ZH' ? '添加区域' : 'Tambah Area'),
          icon: Icons.place_rounded,
          color: _primary,
          lang: widget.lang,
          fields: [
            _FormField(
              label: widget.lang == 'EN' ? 'Area Name' : widget.lang == 'ZH' ? '区域名称' : 'Nama Area',
              controller: namaCtrl,
              icon: Icons.place_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Category' : widget.lang == 'ZH' ? '类别' : 'Kategori',
              controller: kategoriCtrl,
              icon: Icons.category_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Image URL' : widget.lang == 'ZH' ? '图片URL' : 'URL Gambar',
              controller: gambarCtrl,
              icon: Icons.image_outlined,
            ),
          ],
          extraWidget: _buildParentDropdown(
            label: 'Sub-Unit',
            items: _subunitList,
            idKey: 'id_subunit',
            nameKey: 'nama_subunit',
            selectedId: selectedSubunitId,
            onChanged: (v) => setDlg(() => selectedSubunitId = v),
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty || selectedSubunitId == null) return;
            final data = {
              'nama_area': namaCtrl.text.trim(),
              'deskripsi_area': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              'kategori': kategoriCtrl.text.trim().isEmpty ? null : kategoriCtrl.text.trim(),
              'gambar_area': gambarCtrl.text.trim().isEmpty ? null : gambarCtrl.text.trim(),
              'id_subunit': selectedSubunitId,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('area').update(data).eq('id_area', item!['id_area']);
            } else {
              await Supabase.instance.client.from('area').insert(data);
            }
            _load();
          },
        ),
      ),
    );
  }

  Future<void> _delete(String id, String name) async {
    final ok = await _showConfirm(context, name, widget.lang);
    if (!ok) return;
    await Supabase.instance.client.from('area').delete().eq('id_area', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _buildTabContent(
      isLoading: _isLoading,
      search: _search,
      onSearch: (v) => setState(() {
        _search = v;
        _applyFilter();
      }),
      data: _filtered,
      lang: widget.lang,
      primaryColor: _primary,
      nameFn: (item) => item['nama_area'] ?? '',
      subtitleFn: (item) => item['subunit']?['nama_subunit'] ?? '-',
      subtitleIcon: Icons.layers_rounded,
      icon: Icons.place_rounded,
      onAdd: () => _showDialog(),
      onEdit: (item) => _showDialog(item: item),
      onDelete: (item) => _delete(item['id_area'], item['nama_area'] ?? ''),
      onRefresh: _load,
      onTapDetail: (item) => _showLocationDetailSheet(
        context: context,
        item: item,
        lang: widget.lang,
        primaryColor: _primary,
        icon: Icons.place_rounded,
        nameKey: 'area',
        nameFn: (item) => item['nama_area'] ?? '',
        subtitleFn: (item) => item['subunit']?['nama_subunit'] ?? '-',
        onEdit: (item) => _showDialog(item: item),
        onDelete: (item) => _delete(item['id_area'], item['nama_area'] ?? ''),
      ),
    );
  }
}

void _showLocationDetailSheet({
  required BuildContext context,
  required Map<String, dynamic> item,
  required String lang,
  required Color primaryColor,
  required IconData icon,
  required String nameKey,
  required String Function(Map<String, dynamic>) nameFn,
  required String Function(Map<String, dynamic>) subtitleFn,
  required void Function(Map<String, dynamic>) onEdit,
  required void Function(Map<String, dynamic>) onDelete,
}) {
  final name = nameFn(item);
  final subtitle = subtitleFn(item);
  final deskripsi = (item['deskripsi_${nameKey}'] ?? item['deskripsi_lokasi'] ?? item['deskripsi_unit'] ?? item['deskripsi_subunit'] ?? item['deskripsi_area'] ?? '') as String;
  final isStar = (item['is_star'] ?? 0) as int;
  final kategori = item['kategori'] as String?;
  final qrcode = item['qrcode'] as String?;
  final picName = item['User']?['nama'] as String?;
  final gambar = (item['gambar_lokasi'] ?? item['gambar_unit'] ?? item['gambar_subunit'] ?? item['gambar_area']) as String?;

  // Info rows: kumpulkan semua relasi yang ada
  final List<Map<String, dynamic>> infoRows = [];

  if (item['lokasi']?['nama_lokasi'] != null) {
    infoRows.add({
      'icon': Icons.location_city_rounded,
      'label': lang == 'EN' ? 'Location' : lang == 'ZH' ? '位置' : 'Lokasi',
      'value': item['lokasi']['nama_lokasi'],
      'color': const Color(0xFF10B981),
    });
  }
  if (item['unit']?['nama_unit'] != null) {
    infoRows.add({
      'icon': Icons.business_rounded,
      'label': lang == 'EN' ? 'Unit' : lang == 'ZH' ? '单位' : 'Unit',
      'value': item['unit']['nama_unit'],
      'color': const Color(0xFF6366F1),
    });
  }
  if (item['subunit']?['nama_subunit'] != null) {
    infoRows.add({
      'icon': Icons.layers_rounded,
      'label': lang == 'EN' ? 'Sub-Unit' : lang == 'ZH' ? '子单位' : 'Sub-Unit',
      'value': item['subunit']['nama_subunit'],
      'color': const Color(0xFFFBBF24),
    });
  }
  if (kategori != null && kategori.isNotEmpty) {
    infoRows.add({
      'icon': Icons.category_rounded,
      'label': lang == 'EN' ? 'Category' : lang == 'ZH' ? '类别' : 'Kategori',
      'value': kategori,
      'color': const Color(0xFF8B5CF6),
    });
  }
  if (picName != null && picName.isNotEmpty) {
    infoRows.add({
      'icon': Icons.person_outline_rounded,
      'label': lang == 'EN' ? 'PIC' : lang == 'ZH' ? '负责人' : 'PIC',
      'value': picName,
      'color': const Color(0xFF0891B2),
    });
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            if (subtitle.isNotEmpty && subtitle != '-') ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Badge is_star
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isStar > 0
                                        ? const Color(0xFFFEF3C7)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isStar > 0
                                          ? const Color(0xFFFBBF24)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isStar > 0
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 12,
                                        color: isStar > 0
                                            ? const Color(0xFFFBBF24)
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isStar > 0
                                            ? (lang == 'EN'
                                                ? 'Starred'
                                                : lang == 'ZH'
                                                    ? '已加星标'
                                                    : 'Bintang')
                                            : (lang == 'EN'
                                                ? 'No Star'
                                                : lang == 'ZH'
                                                    ? '无星标'
                                                    : 'Tanpa Bintang'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isStar > 0
                                              ? const Color(0xFFF59E0B)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade100, thickness: 1.5),
                  const SizedBox(height: 16),

                  // ── Deskripsi ──
                  if (deskripsi.isNotEmpty) ...[
                    _locDetailSection(
                      lang == 'EN'
                          ? 'Description'
                          : lang == 'ZH'
                              ? '描述'
                              : 'Deskripsi',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.15)),
                      ),
                      child: Text(
                        deskripsi,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Info Rows ──
                  if (infoRows.isNotEmpty) ...[
                    _locDetailSection(
                      lang == 'EN'
                          ? 'Information'
                          : lang == 'ZH'
                              ? '信息'
                              : 'Informasi',
                    ),
                    const SizedBox(height: 10),
                    ...infoRows.map((row) => _locDetailRow(
                          icon: row['icon'] as IconData,
                          label: row['label'] as String,
                          value: row['value'] as String,
                          color: row['color'] as Color,
                        )),
                  ],

                  const SizedBox(height: 20),

                  // ── QR Code Section ──────────────────────────────────────
                  _locDetailSection('QR Code'),
                  const SizedBox(height: 10),
                
                  if (qrcode != null && qrcode.isNotEmpty) ...[
                    // QR sudah ada — tampilkan seperti location_screen.dart
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Preview QR ──
                          QrImageView(
                            data   : qrcode!,
                            version: QrVersions.auto,
                            size   : 220,
                          ),
                          const SizedBox(height: 16),
                
                          // ── Tombol Generate Ulang ──
                          OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QRGeneratorScreen(
                                    lang     : lang,
                                    levelName: nameKey,
                                    levelId  : item['id_$nameKey'].toString(),
                                    itemName : nameFn(item),
                                  ),
                                ),
                              );
                              if (result == true) {
                                try {
                                  final refreshed = await Supabase.instance.client
                                      .from(nameKey)
                                      .select('*, User!fk_${nameKey}_pic(nama)')
                                      .eq('id_$nameKey', item['id_$nameKey'].toString())
                                      .maybeSingle();
                                  if (refreshed != null && context.mounted) {
                                    item.addAll(refreshed);
                                    _showLocationDetailSheet(
                                      context    : context,
                                      item       : item,
                                      lang       : lang,
                                      primaryColor: primaryColor,
                                      icon       : icon,
                                      nameKey    : nameKey,
                                      nameFn     : nameFn,
                                      subtitleFn : subtitleFn,
                                      onEdit     : onEdit,
                                      onDelete   : onDelete,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Refresh QR error: $e');
                                }
                              }
                            },
                            icon : const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              lang == 'EN'
                                  ? 'Regenerate QR'
                                  : lang == 'ZH'
                                      ? '重新生成二维码'
                                      : 'Buat Ulang QR',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // QR belum ada — tampilkan tombol generate seperti location_screen.dart
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            lang == 'EN'
                                ? 'QR Code has not been generated yet.'
                                : lang == 'ZH'
                                    ? '二维码尚未生成。'
                                    : 'Kode QR belum dibuat.',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black45,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                
                          // ── Tombol Generate QR ──
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QRGeneratorScreen(
                                    lang     : lang,
                                    levelName: nameKey,
                                    levelId  : item['id_$nameKey'].toString(),
                                    itemName : nameFn(item),
                                  ),
                                ),
                              );
                              if (result == true) {
                                // Ambil data terbaru dari DB agar qrcode langsung tampil
                                try {
                                  final refreshed = await Supabase.instance.client
                                      .from(nameKey)
                                      .select('*, User!fk_${nameKey}_pic(nama)')
                                      .eq('id_$nameKey', item['id_$nameKey'].toString())
                                      .maybeSingle();
                                  if (refreshed != null && context.mounted) {
                                    item.addAll(refreshed);
                                    _showLocationDetailSheet(
                                      context    : context,
                                      item       : item,
                                      lang       : lang,
                                      primaryColor: primaryColor,
                                      icon       : icon,
                                      nameKey    : nameKey,
                                      nameFn     : nameFn,
                                      subtitleFn : subtitleFn,
                                      onEdit     : onEdit,
                                      onDelete   : onDelete,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Refresh QR error: $e');
                                }
                              }
                            },
                            icon : const Icon(Icons.add_circle_outline, size: 18),
                            label: Text(
                              lang == 'EN'
                                  ? 'Generate QR Code'
                                  : lang == 'ZH'
                                      ? '生成二维码'
                                      : 'Buat Kode QR',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              shadowColor: primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                
                  const SizedBox(height: 16),
                  // ── END QR Code Section ──────────────────────────────────

                  // ── Tombol Edit & Delete ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onEdit(item);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(
                            lang == 'EN'
                                ? 'Edit'
                                : lang == 'ZH'
                                    ? '编辑'
                                    : 'Edit',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDelete(item);
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.white),
                          label: Text(
                            lang == 'EN'
                                ? 'Delete'
                                : lang == 'ZH'
                                    ? '删除'
                                    : 'Hapus',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
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

Widget _locDetailSection(String title) {
  return Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: GoogleFonts.poppins(
          color: const Color(0xFF1E3A8A),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

Widget _locDetailRow({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.black45,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// SHARED: Tab content builder
// ─────────────────────────────────────────
Widget _buildTabContent({
  required bool isLoading,
  required String search,
  required ValueChanged<String> onSearch,
  required List<Map<String, dynamic>> data,
  required String lang,
  required Color primaryColor,
  required String Function(Map<String, dynamic>) nameFn,
  required String Function(Map<String, dynamic>) subtitleFn,
  IconData? subtitleIcon,
  required IconData icon,
  required VoidCallback onAdd,
  required void Function(Map<String, dynamic>) onEdit,
  required void Function(Map<String, dynamic>) onDelete,
  required Future<void> Function() onRefresh,
  void Function(Map<String, dynamic>)? onTapDetail,  // ← BARU
}) {
  const bg = Color(0xFFF8FAFC);   // ← cerah
  const card = Color(0xFFFFFFFF); // ← putih

  return Scaffold(
    backgroundColor: bg,
    floatingActionButton: FloatingActionButton(
      onPressed: onAdd,
      backgroundColor: primaryColor,
      child: const Icon(Icons.add_rounded, color: Colors.white),
    ),
    body: Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: TextField(
              onChanged: onSearch,
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A), fontSize: 14),
              decoration: InputDecoration(
                hintText: lang == 'EN' ? 'Search...' : lang == 'ZH' ? '搜索...' : 'Cari...',
                hintStyle:
                    GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.black38, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${data.length} ${lang == 'EN' ? 'items' : lang == 'ZH' ? '条数据' : 'data'}',
              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // List
        Expanded(
          child: isLoading
              // ← Shimmer saat loading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade50,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, __) => Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              : data.isEmpty
                  ? Center(
                      child: Text(
                        lang == 'EN' ? 'No data found' : lang == 'ZH' ? '未找到数据' : 'Tidak ada data',
                        style: GoogleFonts.poppins(color: Colors.black38),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: onRefresh,
                      color: primaryColor,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = data[i];
                          return GestureDetector(
                            onTap: onTapDetail != null ? () => onTapDetail(item) : null,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.black.withOpacity(0.06)),
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
                                    color: primaryColor.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child:
                                      Icon(icon, color: primaryColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nameFn(item),
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (subtitleFn(item) != '-') ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (subtitleIcon != null)
                                              Icon(subtitleIcon,
                                                  size: 12,
                                                  color: Colors.black38),
                                            if (subtitleIcon != null)
                                              const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                subtitleFn(item),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black38,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => onEdit(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.edit_outlined,
                                        color: Color(0xFF6366F1), size: 16),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => onDelete(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ));
                        },
                      ),
                    ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// SHARED: Konfirmasi hapus
// ─────────────────────────────────────────
Future<bool> _showConfirm(BuildContext context, String name, String lang) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white, // ← putih
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            lang == 'EN' ? 'Delete?' : lang == 'ZH' ? '删除？' : 'Hapus?',
            style: GoogleFonts.poppins(
                color: const Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${lang == 'EN' ? 'Delete' : lang == 'ZH' ? '删除' : 'Hapus'} "$name"?',
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(lang == 'EN' ? 'Cancel' : lang == 'ZH' ? '取消' : 'Batal',
                  style: const TextStyle(color: Colors.black38)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(lang == 'EN' ? 'Delete' : lang == 'ZH' ? '删除' : 'Hapus',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ??
      false;
}

// ─────────────────────────────────────────
// SHARED: Parent dropdown widget
// ─────────────────────────────────────────
Widget _buildParentDropdown({
  required String label,
  required List<Map<String, dynamic>> items,
  required String idKey,
  required String nameKey,
  required String? selectedId,
  required ValueChanged<String?> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.black54,       // ← TERBACA (bukan putih)
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),   // ← PUTIH/CERAH
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            dropdownColor: Colors.white,    // ← PUTIH
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.black45),
            hint: Text(
              'Select $label',
              style: GoogleFonts.poppins(
                  color: Colors.black38, fontSize: 13),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item[idKey]?.toString(),
                child: Text(
                  item[nameKey] ?? '-',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), // ← TERBACA
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

// ─────────────────────────────────────────
// SHARED: Admin Form Dialog
// ─────────────────────────────────────────
class _FormField {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
  });
}

class _AdminFormDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_FormField> fields;
  final Widget? extraWidget;
  final String lang;
  final Future<void> Function() onSave;

  const _AdminFormDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.fields,
    required this.lang,
    required this.onSave,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // ← PUTIH
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
                      color: const Color(0xFF1E3A8A), // ← GELAP TERBACA
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
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade100, thickness: 1.5),
            const SizedBox(height: 16),

            // ── Fields ──
            ...fields.map((f) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.label,
                      style: GoogleFonts.poppins(
                        color: Colors.black54, // ← TERBACA
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
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: f.controller,
                        maxLines: f.maxLines,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A), // ← TERBACA
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

            // ── Extra widget (dropdown parent) ──
            if (extraWidget != null) ...[
              extraWidget!,
              const SizedBox(height: 20),
            ],

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