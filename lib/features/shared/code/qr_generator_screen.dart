import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_logo_cache.dart';

class QRGeneratorScreen extends StatefulWidget {
  final String lang;
  final String levelName;
  final String levelId;
  final String itemName;
  final String? picName;
  final String? picImage;

  const QRGeneratorScreen({
    super.key,
    required this.lang,
    required this.levelName,
    required this.levelId,
    required this.itemName,
    this.picName,
    this.picImage,
  });

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  late final String _qrData;
  bool _isSaving = false;
  bool _isPreparing = true;
  bool _successPopupHandled = false;

  static const Map<String, Color> _levelColorMap = {
    'lokasi': Color(0xFF10B981),
    'unit': Color(0xFF6366F1),
    'subunit': Color(0xFFFBBF24),
    'area': Color(0xFFF472B6),
    'section': Color(0xFF1D72F3),
  };

  static const Map<String, IconData> _levelIconMap = {
    'lokasi': Icons.location_city_rounded,
    'unit': Icons.business_rounded,
    'subunit': Icons.layers_rounded,
    'area': Icons.place_rounded,
    'section': Icons.dashboard_customize_rounded,
  };

  Color get _levelColor => _levelColorMap[widget.levelName] ?? const Color(0xFF1D72F3);
  IconData get _levelIcon => _levelIconMap[widget.levelName] ?? Icons.qr_code_2_rounded;

  final Map<String, Map<String, String>> texts = {
    'EN': {
      'title': 'Generate QR Code',
      'save_button': 'Save QR Code',
      'saving': 'Saving...',
      'save_success': 'QR Code successfully saved!',
      'save_failed': 'Failed to save QR Code. Please try again.',
      'info': 'This QR code can be scanned to instantly select this location when submitting a 5R finding report.',
      'info_section': 'This QR code can be scanned to instantly select this section when reporting a Cause on KTS Production or scheduling a Preventive Maintenance task.',
      'pic': 'Person in Charge',
      'no_pic': 'No PIC',
    },
    'ID': {
      'title': 'Buat Kode QR',
      'save_button': 'Simpan Kode QR',
      'saving': 'Menyimpan...',
      'save_success': 'Kode QR berhasil disimpan!',
      'save_failed': 'Gagal menyimpan Kode QR. Silakan coba lagi.',
      'info': 'Kode QR ini dapat dipindai untuk langsung memilih lokasi ini saat membuat laporan temuan 5R.',
      'info_section': 'Kode QR ini dapat dipindai untuk langsung memilih section ini saat melaporkan Cause pada KTS Production maupun penjadwalan Preventive Maintenance.',
      'pic': 'Penanggung Jawab',
      'no_pic': 'Belum ada PIC',
    },
    'ZH': {
      'title': '生成二维码',
      'save_button': '保存二维码',
      'saving': '保存中...',
      'save_success': '二维码已成功保存！',
      'save_failed': '二维码保存失败。请再试一次。',
      'info': '扫描此二维码即可在提交5R发现报告时直接选择此位置。',
      'info_section': '扫描此二维码可在报告KTS Production原因或安排预防性维护时直接选择此部门。',
      'pic': '负责人',
      'no_pic': '无负责人',
    }
  };
  String getTxt(String key) => texts[widget.lang]?[key] ?? key;
  String get _infoText => widget.levelName == 'section' ? getTxt('info_section') : getTxt('info');

  @override
  void initState() {
    super.initState();
    _prepareQrData();
    AppLogoCache.prefetch(onUpdated: () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _prepareQrData() async {
    final supabase = Supabase.instance.client;
    String? idL, idU, idS, idA;

    try {
      switch (widget.levelName) {
        case 'lokasi':
          idL = widget.levelId;
          break;
        case 'unit':
          final d = await supabase.from('unit')
              .select('id_lokasi').eq('id_unit', widget.levelId).single();
          idL = d['id_lokasi']?.toString();
          idU = widget.levelId;
          break;
        case 'subunit':
          final d = await supabase.from('subunit')
              .select('id_lokasi, id_unit').eq('id_subunit', widget.levelId).single();
          idL = d['id_lokasi']?.toString();
          idU = d['id_unit']?.toString();
          idS = widget.levelId;
          break;
        case 'area':
          final d = await supabase.from('area')
              .select('id_lokasi, id_unit, id_subunit').eq('id_area', widget.levelId).single();
          idL = d['id_lokasi']?.toString();
          idU = d['id_unit']?.toString();
          idS = d['id_subunit']?.toString();
          idA = widget.levelId;
          break;
      }
    } catch (e) {
      debugPrint('Error preparing QR hierarchy: $e');
    }

    final data = {
      'v': 2,
      'type': widget.levelName,
      'id': widget.levelId,
      'name': widget.itemName,
      'idL': idL,
      'idU': idU,
      'idS': idS,
      'idA': idA,
    };

    if (mounted) {
      setState(() {
        _qrData = jsonEncode(data);
        _isPreparing = false;
      });
    }
  }

  Future<void> _saveQrCode() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      await supabase.from(widget.levelName).update({
        'qrcode': _qrData,
      }).eq('id_${widget.levelName}', widget.levelId);

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccessPopup(getTxt('save_success'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${getTxt('save_failed')}: $e'),
              backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessPopup(String message) {
    if (!mounted) return;
    _successPopupHandled = false;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        void finish() {
          if (_successPopupHandled) return;
          _successPopupHandled = true;
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
          if (mounted) Navigator.pop(context, true);
        }

        Future.delayed(const Duration(milliseconds: 2000), finish);

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                          width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.lang == 'EN'
                        ? 'Success!'
                        : widget.lang == 'ZH'
                            ? '成功！'
                            : 'Berhasil!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2000),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppLogo() {
    final url = AppLogoCache.cachedUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        height: 64,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/logo1.PNG',
          height: 64,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }
    return Image.asset(
      'assets/images/logo1.PNG',
      height: 64,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPic = widget.picName != null && widget.picName!.isNotEmpty;
    final hasPicImage = widget.picImage != null && widget.picImage!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTxt('title'),
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D72F3),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _levelColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _levelColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_rounded, size: 18, color: _levelColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _infoText,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _levelColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _levelColor.withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _levelColor.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildAppLogo(),
                    const SizedBox(height: 16),
                    _isPreparing
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.grey.shade50,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 220.0,
                          ),
                    if (!_isPreparing) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_levelIcon, size: 16, color: _levelColor),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.itemName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _levelColor,
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
                            '${getTxt('pic')} : ',
                            style: GoogleFonts.poppins(
                              color: _levelColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: _levelColor.withValues(alpha: 0.15),
                            backgroundImage: hasPicImage ? NetworkImage(widget.picImage!) : null,
                            child: !hasPicImage
                                ? Icon(Icons.person_rounded, color: _levelColor, size: 13)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              hasPic ? widget.picName! : getTxt('no_pic'),
                              style: GoogleFonts.poppins(
                                color: Colors.black87,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
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
              const SizedBox(height: 36),
              _isSaving
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveQrCode,
                        icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                        label: Text(getTxt('save_button')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D72F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                          shadowColor: const Color(0xFF1D72F3).withValues(alpha: 0.35),
                          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}