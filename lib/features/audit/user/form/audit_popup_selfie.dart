import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../selfie/audit_selfie_screen.dart';

Future<void> showAuditSelfiePopup(
  BuildContext context, {
  required String selfieUrl,
  required String lang,
  required String locationName,
  required String levelType,
  required String idRef,
  required ValueChanged<String> onRetake,
}) {
  String t(String en, String id, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (dialogContext) => _AuditSelfiePopupContent(
      selfieUrl: selfieUrl,
      lang: lang,
      locationName: locationName,
      levelType: levelType,
      idRef: idRef,
      onRetake: onRetake,
      t: t,
    ),
  );
}

class _AuditSelfiePopupContent extends StatefulWidget {
  final String selfieUrl;
  final String lang;
  final String locationName;
  final String levelType;
  final String idRef;
  final ValueChanged<String> onRetake;
  final String Function(String en, String id, String zh) t;

  const _AuditSelfiePopupContent({
    required this.selfieUrl,
    required this.lang,
    required this.locationName,
    required this.levelType,
    required this.idRef,
    required this.onRetake,
    required this.t,
  });

  @override
  State<_AuditSelfiePopupContent> createState() =>
      _AuditSelfiePopupContentState();
}

class _AuditSelfiePopupContentState extends State<_AuditSelfiePopupContent> {
  static const _teal = Color(0xFF14B8A6);

  late String _selfieUrl;
  bool _retaking = false;

  @override
  void initState() {
    super.initState();
    _selfieUrl = widget.selfieUrl;
  }

  Future<void> _handleRetake() async {
    setState(() => _retaking = true);

    final newUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AuditSelfieScreen(
          lang: widget.lang,
          locationName: widget.locationName,
          levelType: widget.levelType,
          idRef: widget.idRef,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _retaking = false);

    if (newUrl != null) {
      setState(() => _selfieUrl = newUrl);
      widget.onRetake(newUrl);
    }
  }

  bool get _isLocalSelfiePath =>
      !_selfieUrl.startsWith('http://') && !_selfieUrl.startsWith('https://');

  Widget _buildSelfieImage() {
    final fallback = SizedBox(
      height: 200,
      child: Center(
        child: Icon(Icons.broken_image_outlined,
            color: Colors.grey.shade400, size: 48),
      ),
    );
    if (!kIsWeb && _isLocalSelfiePath) {
      return Image.file(
        File(_selfieUrl),
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      _selfieUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: _teal,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxImageHeight = size.height * 0.55;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              color: _teal.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: _teal, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.t('Audit Location Proof', 'Bukti Lokasi Audit',
                          '审计位置证明'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF0F766E), size: 20),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // ── Foto — adaptif landscape maupun potrait, bisa di-zoom ──
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: maxImageHeight),
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: _buildSelfieImage(),
              ),
            ),

            // ── Info lokasi ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, color: _teal, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.locationName,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: Text(
                widget.t(
                  'This selfie was captured as proof of presence before the audit started.',
                  'Selfie ini diambil sebagai bukti kehadiran sebelum audit dimulai.',
                  '此自拍照是审计开始前拍摄的到场证明。',
                ),
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),

            // ── Tombol Retake ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _retaking ? null : _handleRetake,
                  icon: _retaking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _teal),
                        )
                      : const Icon(Icons.replay_rounded,
                          size: 18, color: _teal),
                  label: Text(
                    widget.t('Retake Selfie', 'Ambil Ulang Selfie', '重拍自拍照'),
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _teal),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _teal, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}