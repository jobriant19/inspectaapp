import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/code/app_logo_cache.dart';
import '../../../shared/code/qr_generator_screen.dart';
import '../../../shared/code/qr_print_helper.dart';
import '../../../user/finding/finding_pick_pic.dart';

class AdminLocationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String lang;
  final Color primaryColor;
  final IconData icon;
  final String nameKey;
  final String Function(Map<String, dynamic>) nameFn;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const AdminLocationDetailScreen({
    super.key,
    required this.item,
    required this.lang,
    required this.primaryColor,
    required this.icon,
    required this.nameKey,
    required this.nameFn,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AdminLocationDetailScreen> createState() => _AdminLocationDetailScreenState();
}

class _AdminLocationDetailScreenState extends State<AdminLocationDetailScreen> {
  late Map<String, dynamic> _item;
  bool _isRefreshing = false;
  final GlobalKey _qrCardKey = GlobalKey();
  int? _favoriteCount;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadFavoriteCount();
    AppLogoCache.prefetch(onUpdated: () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadFavoriteCount() async {
    try {
      final idValue = _item['id_${widget.nameKey}'].toString();
      final rows = await Supabase.instance.client
          .from('favorit_lokasi')
          .select('id_favorit')
          .eq('level_type', widget.nameKey)
          .eq('level_id', idValue);
      if (mounted) setState(() => _favoriteCount = (rows as List).length);
    } catch (e) {
      debugPrint('Load favorite count error: $e');
      if (mounted) setState(() => _favoriteCount = 0);
    }
  }

  String get _localizedDesc {
    switch (widget.lang) {
      case 'EN':
        return (_item['deskripsi_lokasi_en'] ?? _item['deskripsi_lokasi'] ?? '').toString();
      case 'ZH':
        return (_item['deskripsi_lokasi_zh'] ?? _item['deskripsi_lokasi'] ?? '').toString();
      default:
        return (_item['deskripsi_lokasi'] ?? '').toString();
    }
  }

  Future<void> _openQrGenerator() async {
    final picData = _item['User'] as Map<String, dynamic>?;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRGeneratorScreen(
          lang: widget.lang,
          levelName: widget.nameKey,
          levelId: _item['id_${widget.nameKey}'].toString(),
          itemName: widget.nameFn(_item),
          picName: picData?['nama'] as String?,
          picImage: picData?['gambar_user'] as String?,
        ),
      ),
    );
    if (result == true) {
      setState(() => _isRefreshing = true);
      try {
        final refreshed = await Supabase.instance.client
            .from(widget.nameKey)
            .select('*, User!fk_lokasi_pic(nama, gambar_user, jabatan(nama_jabatan))')
            .eq('id_${widget.nameKey}', _item['id_${widget.nameKey}'].toString())
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

  Future<void> _printQrCard() async {
    await QrPrintHelper.printQrCard(_qrCardKey, fileName: 'qr_lokasi');
  }

  void _openFullImage(String url) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _LocationDetailFullscreenViewer(
          imageUrl: url,
          accentColor: widget.primaryColor,
        ),
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

  @override
  Widget build(BuildContext context) {
    final name = widget.nameFn(_item);
    final deskripsi = _localizedDesc;
    final qrcode = _item['qrcode'] as String?;
    final gambarUrl = _item['gambar_lokasi'] as String?;
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
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN'
              ? 'Location Detail'
              : widget.lang == 'ZH'
                  ? '位置详情'
                  : 'Detail Lokasi',
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
                          width: 64,
                          height: 64,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: hasImage
                                ? Border.all(color: widget.primaryColor.withValues(alpha: 0.25), width: 1.5)
                                : null,
                          ),
                          child: hasImage
                              ? Image.network(
                                  gambarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(widget.icon, color: widget.primaryColor, size: 28),
                                )
                              : Icon(widget.icon, color: widget.primaryColor, size: 28),
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
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFBBF24)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _favoriteCount == null
                                        ? '...'
                                        : '$_favoriteCount ${widget.lang == 'EN' ? 'Favorites' : widget.lang == 'ZH' ? '收藏' : 'Favorit'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFF59E0B),
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
                      color: widget.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      deskripsi.isEmpty ? '-' : deskripsi,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                        color: widget.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: widget.primaryColor.withValues(alpha: 0.15),
                            backgroundImage: (picImage != null && picImage.isNotEmpty)
                                ? NetworkImage(picImage)
                                : null,
                            child: (picImage == null || picImage.isEmpty)
                                ? Icon(Icons.person_rounded, color: widget.primaryColor, size: 22)
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        widget.lang == 'EN'
                            ? 'No PIC assigned'
                            : widget.lang == 'ZH'
                                ? '未分配负责人'
                                : 'Belum ada PIC',
                        style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
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
                        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primaryColor.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_rounded, size: 18, color: widget.primaryColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.lang == 'EN'
                                        ? 'This QR code is used to scan and submit a 5R finding report at this specific location.'
                                        : widget.lang == 'ZH'
                                            ? '此二维码用于扫描并在该特定位置提交5R发现报告。'
                                            : 'Kode QR ini digunakan untuk discan guna membuat laporan temuan 5R pada lokasi spesifik ini.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: widget.primaryColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          RepaintBoundary(
                            key: _qrCardKey,
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                children: [
                                  (AppLogoCache.cachedUrl != null && AppLogoCache.cachedUrl!.isNotEmpty)
                                      ? Image.network(
                                          AppLogoCache.cachedUrl!,
                                          height: 64,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Image.asset(
                                            'assets/images/logo1.PNG',
                                            height: 64,
                                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/images/logo1.PNG',
                                          height: 64,
                                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                        ),
                                  const SizedBox(height: 16),
                                  QrImageView(data: qrcode, version: QrVersions.auto, size: 220),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(widget.icon, size: 16, color: widget.primaryColor),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          name,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: widget.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'PIC : ',
                                        style: GoogleFonts.poppins(
                                            color: widget.primaryColor, fontSize: 12.5, fontWeight: FontWeight.w700),
                                      ),
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: widget.primaryColor.withValues(alpha: 0.15),
                                        backgroundImage: (picImage != null && picImage.isNotEmpty)
                                            ? NetworkImage(picImage)
                                            : null,
                                        child: (picImage == null || picImage.isEmpty)
                                            ? Icon(Icons.person_rounded, color: widget.primaryColor, size: 13)
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          (picName != null && picName.isNotEmpty)
                                              ? picName
                                              : (widget.lang == 'EN' ? 'No PIC' : widget.lang == 'ZH' ? '无负责人' : 'Belum ada PIC'),
                                          style: GoogleFonts.poppins(
                                              color: Colors.black87, fontSize: 12.5, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openQrGenerator,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: Text(
                                    widget.lang == 'EN' ? 'Regenerate' : widget.lang == 'ZH' ? '重新生成' : 'Buat Ulang',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: widget.primaryColor,
                                    side: BorderSide(color: widget.primaryColor),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _printQrCard,
                                  icon: const Icon(Icons.print_rounded, size: 16),
                                  label: Text(
                                    widget.lang == 'EN' ? 'Print' : widget.lang == 'ZH' ? '打印' : 'Cetak',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
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

class _LocationDetailFullscreenViewer extends StatelessWidget {
  final String imageUrl;
  final Color accentColor;

  const _LocationDetailFullscreenViewer({
    required this.imageUrl,
    required this.accentColor,
  });

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
                    color: const Color(0xFFEF4444).withValues(alpha: 0.85),
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