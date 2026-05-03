import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        : ['Lokasi', 'Unit', 'Sub-Unit', 'Area'];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        title: Text(
          _lang == 'EN' ? 'Location Management' : 'Kelola Lokasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1E3A8A)),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: Colors.black38,
          indicatorWeight: 3,
          tabs: List.generate(
            4,
            (i) => Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_tabIcons[i], size: 16),
                  const SizedBox(width: 6),
                  Text(tabLabels[i],
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
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
          .select('id_lokasi, nama_lokasi, deskripsi_lokasi, is_star')
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

    showDialog(
      context: context,
      builder: (ctx) => _AdminFormDialog(
        title: isEdit
            ? (widget.lang == 'EN' ? 'Edit Location' : 'Edit Lokasi')
            : (widget.lang == 'EN' ? 'Add Location' : 'Tambah Lokasi'),
        icon: Icons.location_city_rounded,
        color: _primary,
        fields: [
          _FormField(
            label: widget.lang == 'EN' ? 'Location Name' : 'Nama Lokasi',
            controller: namaCtrl,
            icon: Icons.location_city_rounded,
          ),
          _FormField(
            label: widget.lang == 'EN' ? 'Description' : 'Deskripsi',
            controller: descCtrl,
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
        lang: widget.lang,
        onSave: () async {
          if (namaCtrl.text.trim().isEmpty) return;
          final data = {
            'nama_lokasi': namaCtrl.text.trim(),
            'deskripsi_lokasi': descCtrl.text.trim().isEmpty
                ? null
                : descCtrl.text.trim(),
          };
          if (isEdit) {
            await Supabase.instance.client
                .from('lokasi')
                .update(data)
                .eq('id_lokasi', item!['id_lokasi']);
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
            .select('id_unit, nama_unit, deskripsi_unit, id_lokasi, lokasi(nama_lokasi)')
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
    String? selectedLokasiId = item?['id_lokasi']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _AdminFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Unit' : 'Edit Unit')
              : (widget.lang == 'EN' ? 'Add Unit' : 'Tambah Unit'),
          icon: Icons.business_rounded,
          color: _primary,
          lang: widget.lang,
          fields: [
            _FormField(
              label: widget.lang == 'EN' ? 'Unit Name' : 'Nama Unit',
              controller: namaCtrl,
              icon: Icons.business_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Description' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
          ],
          extraWidget: _buildParentDropdown(
            label: widget.lang == 'EN' ? 'Location' : 'Lokasi',
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
              'id_lokasi': selectedLokasiId,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('unit')
                  .update(data)
                  .eq('id_unit', item!['id_unit']);
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
            .select('id_subunit, nama_subunit, deskripsi_subunit, id_unit, unit(nama_unit)')
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
    String? selectedUnitId = item?['id_unit']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _AdminFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Sub-Unit' : 'Edit Sub-Unit')
              : (widget.lang == 'EN' ? 'Add Sub-Unit' : 'Tambah Sub-Unit'),
          icon: Icons.layers_rounded,
          color: _primary,
          lang: widget.lang,
          fields: [
            _FormField(
              label: widget.lang == 'EN' ? 'Sub-Unit Name' : 'Nama Sub-Unit',
              controller: namaCtrl,
              icon: Icons.layers_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Description' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
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
              'deskripsi_subunit': descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              'id_unit': selectedUnitId,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('subunit')
                  .update(data)
                  .eq('id_subunit', item!['id_subunit']);
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
            .select('id_area, nama_area, deskripsi_area, id_subunit, subunit(nama_subunit)')
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
    String? selectedSubunitId = item?['id_subunit']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _AdminFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Area' : 'Edit Area')
              : (widget.lang == 'EN' ? 'Add Area' : 'Tambah Area'),
          icon: Icons.place_rounded,
          color: _primary,
          lang: widget.lang,
          fields: [
            _FormField(
              label: widget.lang == 'EN' ? 'Area Name' : 'Nama Area',
              controller: namaCtrl,
              icon: Icons.place_rounded,
            ),
            _FormField(
              label: widget.lang == 'EN' ? 'Description' : 'Deskripsi',
              controller: descCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
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
              'deskripsi_area': descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              'id_subunit': selectedSubunitId,
            };
            if (isEdit) {
              await Supabase.instance.client
                  .from('area')
                  .update(data)
                  .eq('id_area', item!['id_area']);
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
    );
  }
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
                hintText: lang == 'EN' ? 'Search...' : 'Cari...',
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
              '${data.length} ${lang == 'EN' ? 'items' : 'data'}',
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
                        lang == 'EN' ? 'No data found' : 'Tidak ada data',
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
                          return Container(
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
                          );
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
            lang == 'EN' ? 'Delete?' : 'Hapus?',
            style: GoogleFonts.poppins(
                color: const Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${lang == 'EN' ? 'Delete' : 'Hapus'} "$name"?',
            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(lang == 'EN' ? 'Cancel' : 'Batal',
                  style: const TextStyle(color: Colors.black38)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(lang == 'EN' ? 'Delete' : 'Hapus',
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
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E293B),
            hint: Text('Select $label',
                style: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 13)),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item[idKey]?.toString(),
                child: Text(
                  item[nameKey] ?? '-',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
            iconEnabledColor: Colors.white38,
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
      backgroundColor: Colors.white,
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
            const SizedBox(height: 24),

            // Fields
            ...fields.map((f) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(f.label,
                          style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    TextField(
                      controller: f.controller,
                      maxLines: f.maxLines,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: f.maxLines == 1
                            ? Icon(f.icon, color: Colors.white38, size: 18)
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: color, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                )),

            // Extra widget (dropdown)
            if (extraWidget != null) ...[
              extraWidget!,
              const SizedBox(height: 24),
            ],

            // Buttons
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
}