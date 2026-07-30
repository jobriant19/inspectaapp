import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_edit_subcategory.dart';

class AdminSubcategoryDetailDialog extends StatelessWidget {
  final String lang;
  final bool isKts;
  final Color color;
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> kategoriList;
  final Future<void> Function() onSaved;
  final Future<void> Function(String id, String name) onDelete;

  const AdminSubcategoryDetailDialog({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
    required this.item,
    required this.kategoriList,
    required this.onSaved,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required String lang,
    required bool isKts,
    required Color color,
    required Map<String, dynamic> item,
    required List<Map<String, dynamic>> kategoriList,
    required Future<void> Function() onSaved,
    required Future<void> Function(String id, String name) onDelete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AdminSubcategoryDetailDialog(
        lang: lang,
        isKts: isKts,
        color: color,
        item: item,
        kategoriList: kategoriList,
        onSaved: onSaved,
        onDelete: onDelete,
      ),
    );
  }

  static const Color _kategoriColor = Color(0xFF1D72F3);
  static const Color _poinColor = Color(0xFF16A34A);
  static const Color _poinTextColor = Color(0xFF15803D);

  String get _nama {
    switch (lang) {
      case 'EN':
        return (item['nama_subkategoritemuan_en'] ??
                item['nama_subkategoritemuan'] ??
                '-')
            .toString();
      case 'ZH':
        return (item['nama_subkategoritemuan_zh'] ??
                item['nama_subkategoritemuan'] ??
                '-')
            .toString();
      default:
        return (item['nama_subkategoritemuan'] ?? '-').toString();
    }
  }

  String get _desk {
    String raw;
    switch (lang) {
      case 'EN':
        raw = (item['deskripsi_subkategoritemuan_en'] ??
                item['deskripsi_subkategoritemuan'] ??
                '')
            .toString();
        break;
      case 'ZH':
        raw = (item['deskripsi_subkategoritemuan_zh'] ??
                item['deskripsi_subkategoritemuan'] ??
                '')
            .toString();
        break;
      default:
        raw = (item['deskripsi_subkategoritemuan'] ?? '').toString();
    }
    return raw.isEmpty ? '-' : raw;
  }

  String get _kategoriNama {
    final parent = item['kategoritemuan'];
    if (parent == null) return '-';
    switch (lang) {
      case 'EN':
        return (parent['nama_kategoritemuan_en'] ??
                parent['nama_kategoritemuan'] ??
                '-')
            .toString();
      case 'ZH':
        return (parent['nama_kategoritemuan_zh'] ??
                parent['nama_kategoritemuan'] ??
                '-')
            .toString();
      default:
        return (parent['nama_kategoritemuan'] ?? '-').toString();
    }
  }

  String get _kategoriDesk {
    final parent = item['kategoritemuan'];
    if (parent == null) return '';
    switch (lang) {
      case 'EN':
        return (parent['deskripsi_kategoritemuan_en'] ??
                parent['deskripsi_kategoritemuan'] ??
                '')
            .toString();
      case 'ZH':
        return (parent['deskripsi_kategoritemuan_zh'] ??
                parent['deskripsi_kategoritemuan'] ??
                '')
            .toString();
      default:
        return (parent['deskripsi_kategoritemuan'] ?? '').toString();
    }
  }

  String get _typeLabel => isKts ? 'KTS Production' : '5R Finding';
  IconData get _typeIcon =>
      isKts ? Icons.precision_manufacturing_rounded : Icons.cleaning_services_rounded;

  @override
  Widget build(BuildContext context) {
    final parent = item['kategoritemuan'];
    final parentPoin = parent?['poin_kategoritemuan'] ?? 0;
    final poin = item['poin_subkategoritemuan'] ?? 0;
    final parentDesc = _kategoriDesk.isEmpty ? '-' : _kategoriDesk;

    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight * 0.65).clamp(440.0, 560.0);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: SizedBox(
        height: dialogHeight,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, poin),
                    _buildCategorySection(parentPoin, parentDesc),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.grey.shade100, thickness: 1, height: 1),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic poin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(Icons.list_alt_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _nama,
                  style: GoogleFonts.poppins(
                      color: color, fontWeight: FontWeight.w800, fontSize: 19),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6)
                      ]),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          if (_desk != '-') ...[
            const SizedBox(height: 10),
            Text(_desk,
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.5)),
          ],
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _detailChip('$poin pt', _poinColor, Icons.star_rounded),
            _detailChip(_typeLabel, color, _typeIcon),
          ]),
        ],
      ),
    );
  }

  Widget _buildCategorySection(dynamic parentPoin, String parentDesc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.account_tree_rounded, size: 13, color: Colors.black45),
                const SizedBox(width: 5),
                Text(
                  lang == 'EN' ? 'Category' : lang == 'ZH' ? '分类' : 'Kategori',
                  style: GoogleFonts.poppins(
                      color: Colors.black45,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
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
                  colors: [
                    _kategoriColor.withValues(alpha: 0.08),
                    _kategoriColor.withValues(alpha: 0.02)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kategoriColor.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: _kategoriColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.category_rounded, color: _kategoriColor, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_kategoriNama,
                            style: GoogleFonts.poppins(
                                color: _kategoriColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5)),
                        if (parentDesc != '-') ...[
                          const SizedBox(height: 3),
                          Text(parentDesc,
                              style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                  height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: _poinColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, size: 11, color: _poinTextColor),
                      const SizedBox(width: 3),
                      Text('$parentPoin pt',
                          style: GoogleFonts.poppins(
                              color: _poinTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
              label: Text(lang == 'EN' ? 'Edit' : lang == 'ZH' ? '编辑' : 'Ubah',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (dctx) => AdminEditSubcategoryDialog(
                    lang: lang,
                    isKts: isKts,
                    color: color,
                    item: item,
                    kategoriList: kategoriList,
                    onSaved: onSaved,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
              label: Text(lang == 'EN' ? 'Delete' : lang == 'ZH' ? '删除' : 'Hapus',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await onDelete(
                  item['id_subkategoritemuan'],
                  item['nama_subkategoritemuan'] ?? '',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}