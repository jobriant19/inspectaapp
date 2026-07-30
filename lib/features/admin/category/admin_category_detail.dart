import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_category_indicator.dart';
import 'admin_edit_category.dart';

class AdminCategoryDetailDialog extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;
  final Map<String, dynamic> item;
  final Future<void> Function() onSaved;
  final Future<void> Function(String id, String name) onDelete;

  const AdminCategoryDetailDialog({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
    required this.item,
    required this.onSaved,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required String lang,
    required bool isKts,
    required Color color,
    required Map<String, dynamic> item,
    required Future<void> Function() onSaved,
    required Future<void> Function(String id, String name) onDelete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AdminCategoryDetailDialog(
        lang: lang,
        isKts: isKts,
        color: color,
        item: item,
        onSaved: onSaved,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<AdminCategoryDetailDialog> createState() =>
      _AdminCategoryDetailDialogState();
}

class _AdminCategoryDetailDialogState
    extends State<AdminCategoryDetailDialog> {
  static const int _pageSize = 5;
  int _currentPage = 1;

  static const Color _subColor = Color(0xFF1D72F3);
  static const Color _poinColor = Color(0xFF16A34A);
  static const Color _poinTextColor = Color(0xFF15803D);

  String get _nama {
    switch (widget.lang) {
      case 'EN':
        return (widget.item['nama_kategoritemuan_en'] ??
                widget.item['nama_kategoritemuan'] ??
                '-')
            .toString();
      case 'ZH':
        return (widget.item['nama_kategoritemuan_zh'] ??
                widget.item['nama_kategoritemuan'] ??
                '-')
            .toString();
      default:
        return (widget.item['nama_kategoritemuan'] ?? '-').toString();
    }
  }

  String get _desk {
    String raw;
    switch (widget.lang) {
      case 'EN':
        raw = (widget.item['deskripsi_kategoritemuan_en'] ??
                widget.item['deskripsi_kategoritemuan'] ??
                '')
            .toString();
        break;
      case 'ZH':
        raw = (widget.item['deskripsi_kategoritemuan_zh'] ??
                widget.item['deskripsi_kategoritemuan'] ??
                '')
            .toString();
        break;
      default:
        raw = (widget.item['deskripsi_kategoritemuan'] ?? '').toString();
    }
    return raw.isEmpty ? '-' : raw;
  }

  String get _typeLabel => widget.isKts ? 'KTS Production' : '5R Finding';
  IconData get _typeIcon =>
      widget.isKts ? Icons.precision_manufacturing_rounded : Icons.cleaning_services_rounded;

  @override
  Widget build(BuildContext context) {
    final subs = List<Map<String, dynamic>>.from(
        widget.item['subkategoritemuan'] as List? ?? []);
    final poin = widget.item['poin_kategoritemuan'] ?? 0;

    final totalPages =
        subs.isEmpty ? 1 : (subs.length / _pageSize).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _pageSize;
    final endIdx = (startIdx + _pageSize) > subs.length
        ? subs.length
        : startIdx + _pageSize;
    final pageItems =
        subs.isEmpty ? <Map<String, dynamic>>[] : subs.sublist(startIdx, endIdx);

    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight * 0.78).clamp(520.0, 660.0);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: SizedBox(
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(subs.length, poin),
            Expanded(
              child: subs.isEmpty
                  ? _buildEmptySubs()
                  : _buildSubList(pageItems, safePage),
            ),
            if (subs.isNotEmpty && totalPages > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AdminCategoryPageIndicator(
                  currentPage: safePage,
                  totalPages: totalPages,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  color: widget.color,
                  horizontalMargin: 0,
                ),
              ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int subsCount, dynamic poin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color.withValues(alpha: 0.14),
            widget.color.withValues(alpha: 0.04)
          ],
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
                  color: widget.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: widget.color.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(Icons.category_rounded, color: widget.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _nama,
                  style: GoogleFonts.poppins(
                      color: widget.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 19),
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
          const SizedBox(height: 10),
          Text(
            _desk,
            style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detailChip(
                  '${widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin'}: $poin',
                  _poinColor,
                  Icons.star_rounded),
              _detailChip('$subsCount Subcategory', _subColor, Icons.list_alt_rounded),
              _detailChip(_typeLabel, widget.color, _typeIcon),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubList(List<Map<String, dynamic>> pageItems, int safePage) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: pageItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final sub = pageItems[i];
        final globalIndex = (safePage - 1) * _pageSize + i + 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _subColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('$globalIndex',
                    style: GoogleFonts.poppins(
                        color: _subColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sub['nama_subkategoritemuan'] ?? '-',
                  style: GoogleFonts.poppins(
                      color: _subColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _poinColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: _poinTextColor),
                    const SizedBox(width: 3),
                    Text('${sub['poin_subkategoritemuan'] ?? 0} pt',
                        style: GoogleFonts.poppins(
                            color: _poinTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySubs() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/team_illustration.png',
                width: 150, fit: BoxFit.contain),
            const SizedBox(height: 12),
            Text(
              widget.lang == 'EN'
                  ? 'No sub-categories yet'
                  : widget.lang == 'ZH'
                      ? '暂无子分类'
                      : 'Belum ada sub-kategori',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.lang == 'EN'
                  ? 'Add sub-categories to organize this category better'
                  : widget.lang == 'ZH'
                      ? '添加子分类以更好地组织此分类'
                      : 'Tambahkan sub-kategori untuk mengelompokkan kategori ini',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
              label: Text(
                  widget.lang == 'EN' ? 'Edit' : widget.lang == 'ZH' ? '编辑' : 'Ubah',
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
                  builder: (dctx) => AdminEditCategoryDialog(
                    lang: widget.lang,
                    isKts: widget.isKts,
                    color: widget.color,
                    item: widget.item,
                    onSaved: widget.onSaved,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
              label: Text(
                  widget.lang == 'EN' ? 'Delete' : widget.lang == 'ZH' ? '删除' : 'Hapus',
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
                await widget.onDelete(
                  widget.item['id_kategoritemuan'],
                  widget.item['nama_kategoritemuan'] ?? '',
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