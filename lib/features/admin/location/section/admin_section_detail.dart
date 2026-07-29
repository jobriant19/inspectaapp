import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/code/qr_generator_screen.dart';
import '../../../user/finding/finding_pick_pic.dart';

class _C {
  static const primary   = Color(0xFF1D72F3);
  static const red       = Color(0xFFEF4444);
}

class AdminSectionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String lang;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const AdminSectionDetailScreen({
    super.key,
    required this.item,
    required this.lang,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AdminSectionDetailScreen> createState() => _AdminSectionDetailScreenState();
}

class _AdminSectionDetailScreenState extends State<AdminSectionDetailScreen> {
  late Map<String, dynamic> _item;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String get _name {
    if (widget.lang == 'EN') {
      return _item['nama_section_en']?.toString() ?? _item['nama_section_id']?.toString() ?? '-';
    }
    if (widget.lang == 'ZH') {
      return _item['nama_section_zh']?.toString() ?? _item['nama_section_id']?.toString() ?? '-';
    }
    return _item['nama_section_id']?.toString() ?? '-';
  }

  String get _desc {
    if (widget.lang == 'EN') {
      return (_item['deskripsi_section_en'] ?? _item['deskripsi_section'] ?? '').toString();
    }
    if (widget.lang == 'ZH') {
      return (_item['deskripsi_section_zh'] ?? _item['deskripsi_section'] ?? '').toString();
    }
    return (_item['deskripsi_section'] ?? '').toString();
  }

  Future<void> _openQrGenerator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRGeneratorScreen(
          lang: widget.lang,
          levelName: 'section',
          levelId: _item['id_section'].toString(),
          itemName: _name,
        ),
      ),
    );
    if (result == true) {
      setState(() => _isRefreshing = true);
      try {
        final refreshed = await Supabase.instance.client
            .from('section')
            .select(
                '*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area), User!fk_section_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
            .eq('id_section', _item['id_section'].toString())
            .maybeSingle();
        if (refreshed != null && mounted) {
          setState(() => _item = {..._item, ...refreshed});
        }
      } catch (e) {
        debugPrint('Refresh QR section error: $e');
      } finally {
        if (mounted) setState(() => _isRefreshing = false);
      }
    }
  }

  void _openFullImage(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _SectionDetailFullscreenViewer(imageUrl: url),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _C.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(color: _C.primary, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _mappingBadge({required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gambarUrl = _item['gambar_section'] as String?;
    final isStar = (_item['is_star'] ?? 0) as int;
    final qrcode = _item['qrcode'] as String?;
    final lokasiName = _item['lokasi']?['nama_lokasi'] as String?;
    final unitName = _item['unit']?['nama_unit'] as String?;
    final subunitName = _item['subunit']?['nama_subunit'] as String?;
    final areaName = _item['area']?['nama_area'] as String?;
    final picData = _item['User'] as Map<String, dynamic>?;
    final picName = picData?['nama'] as String?;
    final picImage = picData?['gambar_user'] as String?;
    final picJabatan = picData?['jabatan']?['nama_jabatan'] as String?;
    final picIdJabatan = picData?['id_jabatan'] as int?;
    final picIsVerificator = picData?['is_verificator'] as bool?;
    final hasImage = gambarUrl != null && gambarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Section Detail', 'Detail Section', '部门详情'),
          style: GoogleFonts.poppins(color: _C.primary, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: hasImage ? () => _openFullImage(gambarUrl) : null,
                  child: Container(
                    width: 96,
                    height: 96,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: hasImage
                          ? Border.all(color: _C.primary.withValues(alpha: 0.25), width: 1.5)
                          : null,
                    ),
                    child: hasImage
                        ? Image.network(
                            gambarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 30),
                          )
                        : const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      if (lokasiName != null || unitName != null || subunitName != null || areaName != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (lokasiName != null && lokasiName.isNotEmpty)
                              _mappingBadge(icon: Icons.location_city_rounded, color: const Color(0xFF10B981), label: lokasiName),
                            if (unitName != null && unitName.isNotEmpty)
                              _mappingBadge(icon: Icons.business_rounded, color: const Color(0xFF6366F1), label: unitName),
                            if (subunitName != null && subunitName.isNotEmpty)
                              _mappingBadge(icon: Icons.layers_rounded, color: const Color(0xFFFBBF24), label: subunitName),
                            if (areaName != null && areaName.isNotEmpty)
                              _mappingBadge(icon: Icons.place_rounded, color: const Color(0xFFF472B6), label: areaName),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isStar > 0 ? const Color(0xFFFEF3C7) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isStar > 0 ? const Color(0xFFFBBF24) : Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isStar > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 12, color: isStar > 0 ? const Color(0xFFFBBF24) : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              isStar > 0 ? _t('Starred', 'Bintang', '已加星标') : _t('No Star', 'Tanpa Bintang', '无星标'),
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w600, color: isStar > 0 ? const Color(0xFFF59E0B) : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade100, thickness: 1.5),
            const SizedBox(height: 16),

            _sectionLabel(Icons.notes_rounded, _t('Description', 'Deskripsi', '描述')),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.primary.withValues(alpha: 0.20)),
              ),
              child: Text(
                _desc.isEmpty ? '-' : _desc,
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel(Icons.badge_rounded, 'PIC'),
            const SizedBox(height: 10),
            if (picName != null && picName.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _C.primary.withValues(alpha: 0.18),
                      backgroundImage: (picImage != null && picImage.isNotEmpty) ? NetworkImage(picImage) : null,
                      child: (picImage == null || picImage.isEmpty)
                          ? const Icon(Icons.person_rounded, color: _C.primary, size: 22)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(picName, style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          buildJabatanBadge(
                            idJabatan: picIdJabatan,
                            jabatanNama: picJabatan,
                            isVerificator: picIsVerificator,
                            lang: widget.lang,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFBBF24).withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.person_off_rounded, size: 16, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('No PIC assigned yet', 'Belum ada PIC yang ditugaskan', '尚未分配负责人'),
                        style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            _sectionLabel(Icons.qr_code_2_rounded, 'QR Code'),
            const SizedBox(height: 10),
            if (_isRefreshing)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (qrcode != null && qrcode.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.25)),
                  boxShadow: [BoxShadow(color: _C.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    QrImageView(data: qrcode, version: QrVersions.auto, size: 220),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openQrGenerator,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(_t('Regenerate QR', 'Buat Ulang QR', '重新生成二维码'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.primary,
                        side: const BorderSide(color: _C.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      _t('QR Code has not been generated yet.', 'Kode QR belum dibuat.', '二维码尚未生成。'),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openQrGenerator,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(_t('Generate QR Code', 'Buat Kode QR', '生成二维码'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: _C.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onEdit(_item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
                          const SizedBox(width: 6),
                          Text(_t('Edit', 'Edit', '编辑'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete(_item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 6),
                          Text(_t('Delete', 'Hapus', '删除'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                        ],
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

class _SectionDetailFullscreenViewer extends StatelessWidget {
  final String imageUrl;

  const _SectionDetailFullscreenViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withValues(alpha: 0.95)),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.red.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}