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
        backgroundColor: isError ? Colors.red : const Color(0xFFEAB308),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ADD & EDIT FORM
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha:0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_rounded : Icons.add_rounded,
                            color: const Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEdit ? _t('edit') : _t('add'),
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB), // biru cerah
                          ),
                        ),
                      ],
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
                    // ACTIVE TOGGLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('aktif'), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                        Switch(
                          value: isAktif,
                          activeColor: const Color(0xFF22C55E),
                          activeTrackColor: const Color(0xFFBBF7D0),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade200,
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
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 3,
                          shadowColor: const Color(0xFF2563EB).withValues(alpha:0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _t('save'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color.fromARGB(255, 245, 241, 11))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color.fromARGB(255, 245, 244, 1),
              child: _items.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _buildCard(_items[i]),
                    ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    const primaryColor = Color.fromARGB(255, 245, 244, 1);
    const primaryDark  = Color.fromARGB(255, 213, 210, 7);

    final isAktif = item['is_aktif'] as bool? ?? true;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAktif
              ? primaryColor.withValues(alpha:0.35)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isAktif
                ? primaryColor.withValues(alpha:0.10)
                : Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // POINT BADGE
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAktif
                      ? [primaryColor, primaryDark]
                      : [Colors.grey.shade400, Colors.grey.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isAktif
                    ? [BoxShadow(
                        color: primaryColor.withValues(alpha:0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3))]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                  const SizedBox(height: 2),
                  Text(
                    '${item['poin']}',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
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
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAktif
                              ? const Color(0xFF22C55E).withValues(alpha:0.15)
                              : Colors.grey.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAktif
                                ? const Color(0xFF22C55E).withValues(alpha:0.5)
                                : Colors.grey.withValues(alpha:0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isAktif
                              ? (widget.lang == 'EN'
                                  ? 'Active'
                                  : widget.lang == 'ZH'
                                      ? '启用'
                                      : 'Aktif')
                              : (widget.lang == 'EN'
                                  ? 'Inactive'
                                  : widget.lang == 'ZH'
                                      ? '禁用'
                                      : 'Nonaktif'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isAktif
                                ? const Color(0xFF16A34A)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '[${item['kode']}]',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black87,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['deskripsi_template'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item['keterangan'] != null &&
                      (item['keterangan'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['keterangan'],
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // EDIT BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => _showForm(item: item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha:0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha:0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded,
                                  size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 5),
                              Text(
                                widget.lang == 'EN'
                                    ? 'Edit'
                                    : widget.lang == 'ZH'
                                        ? '编辑'
                                        : 'Ubah',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB)),
                              ),
                            ],
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
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 251, 255, 6).withValues(alpha:0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_outlined,
                size: 56,
                color: const Color.fromARGB(255, 245, 245, 11).withValues(alpha:0.5)),
          ),
          const SizedBox(height: 12),
          Text(_t('empty'),
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black38,
                  fontWeight: FontWeight.w500)),
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
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}