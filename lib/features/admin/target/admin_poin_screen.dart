import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'admin_edit_point.dart';

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
    final isAktif = item['is_aktif'] as bool? ?? true;
    final poin = (item['poin'] as int?) ?? 0;
    final isBonus = poin >= 0;
    final pointColor = isBonus ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final pointColorDark = isBonus ? const Color(0xFF16A34A) : const Color(0xFFB91C1C);
    final nama = _localizedNama(item);
    final deskripsi = _localizedDeskripsi(item);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pointColor.withValues(alpha:0.25)),
        boxShadow: [
          BoxShadow(color: pointColor.withValues(alpha:0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // POINT BADGE — hijau (bonus) / merah (penalti)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pointColor, pointColorDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: pointColor.withValues(alpha:0.4), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isBonus ? Icons.add_circle_rounded : Icons.remove_circle_rounded, color: Colors.white, size: 16),
                  const SizedBox(height: 2),
                  Text(
                    '${isBonus ? '+' : ''}$poin',
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
                          nama,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1D72F3)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAktif ? const Color(0xFF22C55E).withValues(alpha:0.12) : Colors.grey.withValues(alpha:0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isAktif ? const Color(0xFF22C55E).withValues(alpha:0.5) : Colors.grey.withValues(alpha:0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isAktif ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                                size: 11, color: isAktif ? const Color(0xFF16A34A) : Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              isAktif
                                  ? (widget.lang == 'EN' ? 'Active' : widget.lang == 'ZH' ? '启用' : 'Aktif')
                                  : (widget.lang == 'EN' ? 'Inactive' : widget.lang == 'ZH' ? '禁用' : 'Nonaktif'),
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: isAktif ? const Color(0xFF16A34A) : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // KODE — code chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(7)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.code_rounded, size: 11, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 5),
                        Text(
                          item['kode'] ?? '',
                          style: GoogleFonts.robotoMono(fontSize: 11, color: const Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // DESKRIPSI — aksen kutip di kiri
                  if (deskripsi.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D72F3).withValues(alpha:0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(left: BorderSide(color: const Color(0xFF1D72F3).withValues(alpha:0.4), width: 3)),
                      ),
                      child: Text(
                        deskripsi,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => AdminEditPointDialog.show(
                          context,
                          lang: widget.lang,
                          item: item,
                          onSaved: _fetchData,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D72F3).withValues(alpha:0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha:0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF1D72F3)),
                              const SizedBox(width: 5),
                              Text(
                                widget.lang == 'EN' ? 'Edit' : widget.lang == 'ZH' ? '编辑' : 'Ubah',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3)),
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

  String _localizedNama(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['nama_en'] ?? item['nama'] ?? '').toString();
      case 'ZH':
        return (item['nama_zh'] ?? item['nama'] ?? '').toString();
      default:
        return (item['nama'] ?? '').toString();
    }
  }

  String _localizedDeskripsi(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['deskripsi_template_en'] ?? item['deskripsi_template'] ?? '').toString();
      case 'ZH':
        return (item['deskripsi_template_zh'] ?? item['deskripsi_template'] ?? '').toString();
      default:
        return (item['deskripsi_template'] ?? '').toString();
    }
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