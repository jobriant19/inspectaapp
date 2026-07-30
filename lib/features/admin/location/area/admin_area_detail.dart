import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/code/qr_generator_screen.dart';
import '../../../user/finding/finding_pick_pic.dart';

class _C {
  static const red = Color(0xFFEF4444);
}

class AdminAreaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String lang;
  final Color primaryColor;
  final Color unitColor;
  final Color subunitColor;
  final IconData icon;
  final String Function(Map<String, dynamic>) nameFn;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const AdminAreaDetailScreen({
    super.key,
    required this.item,
    required this.lang,
    required this.primaryColor,
    required this.unitColor,
    required this.subunitColor,
    required this.icon,
    required this.nameFn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AdminAreaDetailScreen> createState() => _AdminAreaDetailScreenState();
}

class _AdminAreaDetailScreenState extends State<AdminAreaDetailScreen> {
  late Map<String, dynamic> _item;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  String get _localizedDesc {
    switch (widget.lang) {
      case 'EN':
        return (_item['deskripsi_area_en'] ?? _item['deskripsi_area'] ?? '').toString();
      case 'ZH':
        return (_item['deskripsi_area_zh'] ?? _item['deskripsi_area'] ?? '').toString();
      default:
        return (_item['deskripsi_area'] ?? '').toString();
    }
  }

  Future<void> _openQrGenerator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRGeneratorScreen(
          lang: widget.lang,
          levelName: 'area',
          levelId: _item['id_area'].toString(),
          itemName: widget.nameFn(_item),
        ),
      ),
    );
    if (result == true) {
      setState(() => _isRefreshing = true);
      try {
        final refreshed = await Supabase.instance.client
            .from('area')
            .select(
                '*, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi), User!fk_area_pic(nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan))')
            .eq('id_area', _item['id_area'].toString())
            .maybeSingle();
        if (refreshed != null && mounted) {
          setState(() => _item = {..._item, ...refreshed});
        }
      } catch (e) {
        debugPrint('Refresh QR error: $e');
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
        pageBuilder: (_, __, ___) => _AreaDetailFullscreenViewer(imageUrl: url),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 15, color: widget.primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: widget.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _breadcrumbPill({required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    final name = widget.nameFn(_item);
    final deskripsi = _localizedDesc;
    final isStar = (_item['is_star'] ?? 0) as int;
    final qrcode = _item['qrcode'] as String?;
    final gambarUrl = _item['gambar_area'] as String?;
    final subunitName = _item['subunit']?['nama_subunit'] as String?;
    final unitName = _item['unit']?['nama_unit'] as String?;
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN'
              ? 'Area Detail'
              : widget.lang == 'ZH'
                  ? '区域详情'
                  : 'Detail Area',
          style: GoogleFonts.poppins(
            color: widget.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
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
                      color: widget.primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: hasImage
                          ? Border.all(color: widget.primaryColor.withValues(alpha: 0.25), width: 1.5)
                          : null,
                    ),
                    child: hasImage
                        ? Image.network(
                            gambarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(widget.icon, color: const Color(0xFFBE185D), size: 30),
                          )
                        : Icon(widget.icon, color: const Color(0xFFBE185D), size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (subunitName != null && subunitName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _breadcrumbPill(
                              icon: Icons.layers_rounded,
                              color: widget.subunitColor,
                              label: subunitName,
                            ),
                            if (unitName != null && unitName.isNotEmpty)
                              _breadcrumbPill(
                                icon: Icons.business_rounded,
                                color: widget.unitColor,
                                label: unitName,
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isStar > 0 ? const Color(0xFFFEF3C7) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isStar > 0 ? const Color(0xFFFBBF24) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isStar > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 12,
                              color: isStar > 0 ? const Color(0xFFFBBF24) : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isStar > 0
                                  ? (widget.lang == 'EN' ? 'Starred' : widget.lang == 'ZH' ? '已加星标' : 'Bintang')
                                  : (widget.lang == 'EN' ? 'No Star' : widget.lang == 'ZH' ? '无星标' : 'Tanpa Bintang'),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isStar > 0 ? const Color(0xFFF59E0B) : Colors.grey,
                              ),
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

            _sectionLabel(
              Icons.notes_rounded,
              widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                deskripsi.isEmpty ? '-' : deskripsi,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.5,
                ),
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
                  color: widget.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: widget.primaryColor.withValues(alpha: 0.20),
                      backgroundImage: (picImage != null && picImage.isNotEmpty)
                          ? NetworkImage(picImage)
                          : null,
                      child: (picImage == null || picImage.isEmpty)
                          ? const Icon(Icons.person_rounded, color: Color(0xFFBE185D), size: 22)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            picName,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_off_rounded, size: 16, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.lang == 'EN'
                            ? 'No PIC assigned yet'
                            : widget.lang == 'ZH'
                                ? '尚未分配负责人'
                                : 'Belum ada PIC yang ditugaskan',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB45309),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            _sectionLabel(Icons.qr_code_2_rounded, 'QR Code'),
            const SizedBox(height: 10),
            if (_isRefreshing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (qrcode != null && qrcode.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(data: qrcode, version: QrVersions.auto, size: 220),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openQrGenerator,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        widget.lang == 'EN' ? 'Regenerate QR' : widget.lang == 'ZH' ? '重新生成二维码' : 'Buat Ulang QR',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBE185D),
                        side: BorderSide(color: widget.primaryColor),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      widget.lang == 'EN'
                          ? 'QR Code has not been generated yet.'
                          : widget.lang == 'ZH'
                              ? '二维码尚未生成。'
                              : 'Kode QR belum dibuat.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openQrGenerator,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(
                        widget.lang == 'EN' ? 'Generate QR Code' : widget.lang == 'ZH' ? '生成二维码' : 'Buat Kode QR',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: widget.primaryColor.withValues(alpha: 0.3),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            widget.lang == 'EN' ? 'Edit' : widget.lang == 'ZH' ? '编辑' : 'Edit',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            widget.lang == 'EN' ? 'Delete' : widget.lang == 'ZH' ? '删除' : 'Hapus',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
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

class _AreaDetailFullscreenViewer extends StatelessWidget {
  final String imageUrl;

  const _AreaDetailFullscreenViewer({required this.imageUrl});

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