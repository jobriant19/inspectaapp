import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

class AdminPoinScreen extends StatefulWidget {
  final String lang;
  const AdminPoinScreen({super.key, required this.lang});

  @override
  State<AdminPoinScreen> createState() => _AdminPoinScreenState();
}

class _AdminPoinScreenState extends State<AdminPoinScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  // ── Teks multi-bahasa ──
  String _t(String key) {
    const txt = {
      'ID': {
        'title': 'Konfigurasi Poin',
        'add': 'Tambah Konfigurasi',
        'edit': 'Edit Konfigurasi',
        'delete_confirm': 'Hapus konfigurasi ini?',
        'delete_desc': 'Tindakan ini tidak dapat dibatalkan.',
        'cancel': 'Batal',
        'delete': 'Hapus',
        'save': 'Simpan',
        'kode': 'Kode',
        'nama': 'Nama',
        'poin': 'Poin',
        'deskripsi': 'Template Deskripsi',
        'keterangan': 'Keterangan (opsional)',
        'aktif': 'Aktif',
        'empty': 'Belum ada konfigurasi poin.',
        'success_add': 'Konfigurasi berhasil ditambahkan.',
        'success_edit': 'Konfigurasi berhasil diperbarui.',
        'success_delete': 'Konfigurasi berhasil dihapus.',
        'error': 'Terjadi kesalahan.',
        'required': 'Wajib diisi',
        'poin_invalid': 'Poin harus berupa angka',
      },
      'EN': {
        'title': 'Point Configuration',
        'add': 'Add Configuration',
        'edit': 'Edit Configuration',
        'delete_confirm': 'Delete this configuration?',
        'delete_desc': 'This action cannot be undone.',
        'cancel': 'Cancel',
        'delete': 'Delete',
        'save': 'Save',
        'kode': 'Code',
        'nama': 'Name',
        'poin': 'Points',
        'deskripsi': 'Description Template',
        'keterangan': 'Note (optional)',
        'aktif': 'Active',
        'empty': 'No point configurations yet.',
        'success_add': 'Configuration added successfully.',
        'success_edit': 'Configuration updated successfully.',
        'success_delete': 'Configuration deleted successfully.',
        'error': 'An error occurred.',
        'required': 'Required',
        'poin_invalid': 'Points must be a number',
      },
      'ZH': {
        'title': '积分配置',
        'add': '添加配置',
        'edit': '编辑配置',
        'delete_confirm': '删除此配置？',
        'delete_desc': '此操作无法撤销。',
        'cancel': '取消',
        'delete': '删除',
        'save': '保存',
        'kode': '代码',
        'nama': '名称',
        'poin': '积分',
        'deskripsi': '描述模板',
        'keterangan': '备注（可选）',
        'aktif': '启用',
        'empty': '暂无积分配置。',
        'success_add': '配置添加成功。',
        'success_edit': '配置更新成功。',
        'success_delete': '配置删除成功。',
        'error': '发生错误。',
        'required': '必填',
        'poin_invalid': '积分必须为数字',
      },
    };
    return txt[widget.lang]?[key] ?? txt['ID']![key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('konfigurasi_poin')
          .select()
          .order('id', ascending: true);
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(_t('error'), isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Form tambah / edit ──
  void _showForm({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final kodeCtrl = TextEditingController(text: item?['kode'] ?? '');
    final namaCtrl = TextEditingController(text: item?['nama'] ?? '');
    final poinCtrl = TextEditingController(text: item?['poin']?.toString() ?? '0');
    final deskCtrl = TextEditingController(text: item?['deskripsi_template'] ?? '');
    final ketCtrl  = TextEditingController(text: item?['keterangan'] ?? '');
    bool isAktif   = item?['is_aktif'] ?? true;
    final formKey  = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? _t('edit') : _t('add'),
                      style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _formField(kodeCtrl, _t('kode'), enabled: !isEdit),
                    const SizedBox(height: 12),
                    _formField(namaCtrl, _t('nama')),
                    const SizedBox(height: 12),
                    _formField(poinCtrl, _t('poin'), isNumber: true),
                    const SizedBox(height: 12),
                    _formField(deskCtrl, _t('deskripsi'), maxLines: 2),
                    const SizedBox(height: 12),
                    _formField(ketCtrl, _t('keterangan'), required: false, maxLines: 2),
                    const SizedBox(height: 12),
                    // Toggle aktif
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('aktif'), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
                        Switch(
                          value: isAktif,
                          activeColor: const Color(0xFF8B5CF6),
                          onChanged: (v) => setModalState(() => isAktif = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          await _saveItem(
                            isEdit: isEdit,
                            id: item?['id'],
                            kode: kodeCtrl.text.trim(),
                            nama: namaCtrl.text.trim(),
                            poin: int.tryParse(poinCtrl.text.trim()) ?? 0,
                            deskripsi: deskCtrl.text.trim(),
                            keterangan: ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
                            isAktif: isAktif,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_t('save'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField(TextEditingController ctrl, String label,
      {bool isNumber = false, bool required = true, int maxLines = 1, bool enabled = true}) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return _t('required');
        if (isNumber && v != null && int.tryParse(v.trim()) == null) return _t('poin_invalid');
        return null;
      },
    );
  }

  Future<void> _saveItem({
    required bool isEdit,
    int? id,
    required String kode,
    required String nama,
    required int poin,
    required String deskripsi,
    String? keterangan,
    required bool isAktif,
  }) async {
    try {
      final payload = {
        'kode': kode,
        'nama': nama,
        'poin': poin,
        'deskripsi_template': deskripsi,
        'keterangan': keterangan,
        'is_aktif': isAktif,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (isEdit && id != null) {
        await Supabase.instance.client.from('konfigurasi_poin').update(payload).eq('id', id);
        _showSnack(_t('success_edit'));
      } else {
        await Supabase.instance.client.from('konfigurasi_poin').insert(payload);
        _showSnack(_t('success_add'));
      }
      _fetchData();
    } catch (e) {
      _showSnack(_t('error'), isError: true);
    }
  }

  Future<void> _deleteItem(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_t('delete_confirm'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(_t('delete_desc'), style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(_t('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('konfigurasi_poin').delete().eq('id', id);
        _showSnack(_t('success_delete'));
        _fetchData();
      } catch (e) {
        _showSnack(_t('error'), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('title'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black.withOpacity(0.06)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_t('add'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF8B5CF6),
              child: _items.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _buildCard(_items[i]),
                    ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final isAktif = item['is_aktif'] as bool? ?? true;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAktif ? const Color(0xFF8B5CF6).withOpacity(0.2) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poin badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAktif
                      ? [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]
                      : [Colors.grey.shade400, Colors.grey.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                  Text(
                    '${item['poin']}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['nama'] ?? '',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isAktif ? const Color(0xFF10B981) : Colors.grey).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAktif ? (widget.lang == 'EN' ? 'Active' : widget.lang == 'ZH' ? '启用' : 'Aktif')
                                  : (widget.lang == 'EN' ? 'Inactive' : widget.lang == 'ZH' ? '禁用' : 'Nonaktif'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isAktif ? const Color(0xFF10B981) : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '[${item['kode']}]',
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['deskripsi_template'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item['keterangan'] != null && (item['keterangan'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['keterangan'],
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _actionBtn(Icons.edit_rounded, const Color(0xFF6366F1), () => _showForm(item: item)),
                      const SizedBox(width: 8),
                      _actionBtn(Icons.delete_rounded, const Color(0xFFEF4444), () => _deleteItem(item['id'] as int)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(_t('empty'), style: GoogleFonts.poppins(fontSize: 14, color: Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}