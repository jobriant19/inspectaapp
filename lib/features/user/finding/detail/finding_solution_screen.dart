import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/location_service.dart';
import '../camera_finding_screen.dart';
import '../resolution_camera_screen.dart';

class FindingSolutionScreen extends StatefulWidget {
  final Map<String, dynamic> findingData;
  final String lang;
  final bool isPIC;
  final VoidCallback onDataChanged;

  const FindingSolutionScreen({
    super.key,
    required this.findingData,
    required this.lang,
    required this.isPIC,
    required this.onDataChanged,
  });

  @override
  State<FindingSolutionScreen> createState() => _FindingSolutionScreenState();
}

class _FindingSolutionScreenState extends State<FindingSolutionScreen> {
  // SOLUTION STATE
  XFile? _resolutionImageFile;
  final _resolutionNotesController = TextEditingController();
  final _resolutionCostController = TextEditingController();
  bool _isFinishing = false;

  // EXTENSION STATE
  bool _isExtending = false;
  final _extensionReasonController = TextEditingController();
  DateTime? _extensionNewDate;

  late Map<String, String> _texts;

  @override
  void initState() {
    super.initState();
    _setupTranslations();
  }

  @override
  void dispose() {
    _resolutionNotesController.dispose();
    _resolutionCostController.dispose();
    _extensionReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickResolutionImage() async {
    final result = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (context) => ResolutionCameraScreen(lang: widget.lang),
      ),
    );
    if (result != null) {
      setState(() => _resolutionImageFile = result);
    }
  }

  Future<void> _submitExtension() async {
    if (_extensionReasonController.text.trim().isEmpty) {
      _showErrorSnackbar(_texts['extension_err_reason']!);
      return;
    }
    if (_extensionNewDate == null) {
      _showErrorSnackbar(_texts['extension_err_date']!);
      return;
    }

    final currentDeadline = DateTime.tryParse(
        widget.findingData['target_waktu_selesai']?.toString() ?? '');

    if (currentDeadline != null &&
        _extensionNewDate!.isBefore(currentDeadline)) {
      _showErrorSnackbar(_texts['extension_err_date_past']!);
      return;
    }

    setState(() => _isExtending = true);

    try {
      final supabase = Supabase.instance.client;

      final perpanjangResponse = await supabase
          .from('perpanjang')
          .insert({
            'waktu_perpanjang': DateTime.now().toIso8601String(),
            'alasan_perpanjang': _extensionReasonController.text.trim(),
            'tanggal_selesai': _extensionNewDate!.toIso8601String(),
          })
          .select()
          .single();

      final perpanjangId = perpanjangResponse['id_perpanjang'].toString();

      await supabase.from('temuan').update({
        'id_perpanjang': perpanjangId,
        'target_waktu_selesai': _extensionNewDate!.toIso8601String(),
      }).eq('id_temuan', widget.findingData['id_temuan'].toString());

      if (mounted) {
        Navigator.pop(context); 
        _showSuccessSnackbar(_texts['extension_success']!);
        widget.onDataChanged();
      }
    } catch (e) {
      debugPrint('Extension error: $e');
      if (mounted) {
        _showErrorSnackbar('${_texts['extension_fail']!}: $e');
      }
    } finally {
      if (mounted) setState(() => _isExtending = false);
    }
  }

  void _showExtensionBottomSheet() {
    final data = widget.findingData;
    _extensionReasonController.clear();
    _extensionNewDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
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
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.schedule_rounded,
                            color: Color(0xFF1E3A8A), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _texts['extension']!,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (data['target_waktu_selesai'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Deadline saat ini: ${_formatDateTime(data['target_waktu_selesai'], format: 'dd MMM yyyy')}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(_texts['extension_reason']!,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF475569))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _extensionReasonController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _texts['extension_reason_hint']!,
                      hintStyle:
                          GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_texts['extension_new_date']!,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF475569))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1E3A8A),
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() => _extensionNewDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _extensionNewDate != null
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _extensionNewDate != null
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade300,
                          width: _extensionNewDate != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Color(0xFF1E3A8A), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _extensionNewDate != null
                                ? DateFormat('EEEE, d MMMM yyyy').format(_extensionNewDate!)
                                : (_texts['extension_new_date']!),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: _extensionNewDate != null
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                              fontWeight: _extensionNewDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isExtending ? null : _submitExtension,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isExtending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.schedule_send_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(_texts['extension_submit']!,
                                    style: GoogleFonts.poppins(
                                        fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _finishFinding({bool createNewAfter = false}) async {
    final locResult = await LocationService.instance.checkUserAtAtmi(forceRefresh: true);

    if (!locResult.isAtAtmi) {
      if (!mounted) return;
      _showLocationBlockedSnackbar();
      return;
    }

    if (_resolutionImageFile == null) {
      _showErrorSnackbar(_texts['err_proof_required']!);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00C9E4)),
              const SizedBox(height: 20),
              Text(
                widget.lang == 'EN'
                    ? 'Saving resolution...'
                    : widget.lang == 'ZH'
                        ? '正在保存...'
                        : 'Menyimpan penyelesaian...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() => _isFinishing = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final idTemuan = widget.findingData['id_temuan'].toString();

      final imageBytes = await _resolutionImageFile!.readAsBytes();
      final fileName = 'resolution/$idTemuan/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('temuan_images').uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      final imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);

      final costText = _resolutionCostController.text.trim();
      final additionalCost = double.tryParse(costText);

      final temuanData = await supabase
          .from('temuan')
          .select('poin_temuan')
          .eq('id_temuan', idTemuan)
          .maybeSingle();

      final int poinPenyelesaian = (temuanData?['poin_temuan'] as num?)?.toInt() ?? 0;

      final penyelesaianResponse = await supabase
          .from('penyelesaian')
          .insert({
            'id_user': user.id,
            'gambar_penyelesaian': imageUrl,
            'catatan_penyelesaian': _resolutionNotesController.text.trim(),
            'additional_cost': additionalCost,
            'tanggal_selesai': DateTime.now().toIso8601String(),
            'poin_penyelesaian': poinPenyelesaian,
          })
          .select()
          .single();

      final penyelesaianId = penyelesaianResponse['id_penyelesaian'].toString();

      await supabase.from('temuan').update({
        'status_temuan': 'Selesai',
        'id_penyelesaian': penyelesaianId,
      }).eq('id_temuan', idTemuan);

      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      await _showFinishSuccessDialog();

      widget.onDataChanged();

      if (createNewAfter) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CameraFindingScreen(
              lang: widget.lang,
              isProMode: false,
              isVisitorMode: false,
              selectedLocationName: _formatLocation(widget.findingData),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showErrorSnackbar('${_texts['finish_fail']}: $e');
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  String _formatLocation(Map<String, dynamic> item) {
    if (item['area'] != null && item['area']['nama_area'] != null) {
      return item['area']['nama_area'].toString();
    }
    if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) {
      return item['subunit']['nama_subunit'].toString();
    }
    if (item['unit'] != null && item['unit']['nama_unit'] != null) {
      return item['unit']['nama_unit'].toString();
    }
    if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) {
      return item['lokasi']['nama_lokasi'].toString();
    }
    return 'Lokasi tidak diketahui';
  }

  String _formatDateTime(String? dateStr, {String format = 'dd MMM yyyy, HH:mm'}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat(format, 'id_ID').format(dt);
    } catch (e) {
      try {
        final parsableDateStr = dateStr.replaceFirst(' ', 'T');
        final dt = DateTime.parse(parsableDateStr).toLocal();
        return DateFormat(format, 'id_ID').format(dt);
      } catch (e2) {
        return dateStr.substring(0, 19).replaceAll('T', ' ');
      }
    }
  }

  void _showLocationBlockedSnackbar() {
    if (!mounted) return;
    final msg = widget.lang == 'EN'
        ? 'You must be at PT ATMI Solo to submit a resolution.'
        : widget.lang == 'ZH'
            ? '您必须在PT ATMI Solo区域内才能提交解决方案。'
            : 'Penyelesaian hanya dapat dilakukan di area PT ATMI Solo.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.location_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: GoogleFonts.poppins())),
        ]),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins()), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins()), backgroundColor: Colors.green),
    );
  }

  Future<void> _showFinishSuccessDialog() async {
    if (!mounted) return;
    final completer = Completer<void>();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
            if (!completer.isCompleted) completer.complete();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                      border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _texts['finish_success']!,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lang == 'EN'
                        ? 'The finding has been successfully resolved.'
                        : widget.lang == 'ZH'
                            ? '该发现已成功解决。'
                            : 'Temuan berhasil diselesaikan dan poin diberikan.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 3000),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.findingData;
    final s = (data['status_temuan'] as String? ?? '').toLowerCase();
    final isFinished = ['closed', 'selesai', 'done', 'completed'].any((e) => s.contains(e));
    final resolutionData = data['penyelesaian'] as Map<String, dynamic>?;

    if (isFinished && resolutionData != null) {
      return _buildCompletedResolutionSection(resolutionData);
    }

    if (!widget.isPIC) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResolutionSection(),
        const SizedBox(height: 16),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildResolutionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 105, 217, 6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build_circle_rounded,
                  size: 16, color: Color.fromARGB(255, 76, 217, 6)),
            ),
            const SizedBox(width: 10),
            Text(
              _texts['resolution']!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UPLOAD PHOTO
              Row(
                children: [
                  Text(
                    _texts['upload_proof']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  Text(' *', style: GoogleFonts.poppins(color: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 8),
              if (_resolutionImageFile == null)
                GestureDetector(
                  onTap: _pickResolutionImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration:
                              const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Color(0xFF16A34A), size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _texts['upload_proof']!,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _texts['upload_proof_subtitle']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF15803D),
                              fontWeight: FontWeight.w400,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(_resolutionImageFile!.path,
                              height: 200, width: double.infinity, fit: BoxFit.cover)
                          : Image.file(File(_resolutionImageFile!.path),
                              height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickResolutionImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              _texts['change_photo']!,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // NOTES
              Text(
                _texts['resolution_notes']!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resolutionNotesController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 14.5, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: _texts['resolution_notes_hint'],
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF0FDF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF86EFAC), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // COST
              Text(
                _texts['resolution_cost']!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resolutionCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(fontSize: 14.5, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: _texts['resolution_cost_hint'],
                  prefixText: 'Rp ',
                  prefixStyle: GoogleFonts.poppins(fontSize: 14.5, color: const Color(0xFF0F172A)),
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF0FDF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF86EFAC), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedResolutionSection(Map<String, dynamic> resolutionData) {
    final imageUrl = resolutionData['gambar_penyelesaian'] as String?;
    final notes = resolutionData['catatan_penyelesaian'] as String?;
    final cost = resolutionData['additional_cost'] as num?;
    final completedDate = resolutionData['tanggal_selesai'] as String?;
    final solver = resolutionData['User_Solver'] as Map<String, dynamic>?;
    final solverName = solver?['nama'] as String? ?? '...';
    final solverAvatarUrl = solver?['gambar_user'] as String?;

    String formattedCost = '-';
    if (cost != null && cost > 0) {
      formattedCost =
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(cost);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
            ),
            const SizedBox(width: 8),
            Text(
              _texts['resolution_result']!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child:
                      Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: 220),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _texts['resolved']!,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                    if (solver != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFDCFCE7),
                              backgroundImage:
                                  solverAvatarUrl != null ? NetworkImage(solverAvatarUrl) : null,
                              child: solverAvatarUrl == null
                                  ? const Icon(Icons.person, color: Color(0xFF16A34A), size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _texts['resolved_by']!,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  solverName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (completedDate != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_available_rounded,
                                size: 15, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_texts['completed_on']!,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(_formatDateTime(completedDate),
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _texts['notes']!,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF16A34A),
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(notes,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: const Color(0xFF166534), height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                    if (cost != null && cost > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: Color(0xFFEA580C), size: 18),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _texts['cost']!,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF92400E),
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  formattedCost,
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEA580C)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isFinishing ? null : () => _finishFinding(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D72F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shadowColor: const Color(0xFF1D72F3).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isFinishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(_texts['finish']!,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isFinishing ? null : () => _finishFinding(createNewAfter: true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1D72F3), width: 1.5),
              foregroundColor: const Color(0xFF1D72F3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 20),
                const SizedBox(width: 8),
                Text(_texts['finish_and_new']!,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isExtending ? null : _showExtensionBottomSheet,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
              foregroundColor: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded, size: 20),
                const SizedBox(width: 8),
                Text(_texts['btn_extend']!,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _setupTranslations() {
    const Map<String, Map<String, String>> translations = {
      'ID': {
        'resolution': 'Penyelesaian',
        'upload_proof': 'Unggah Bukti Penyelesaian',
        'upload_proof_subtitle': 'Ketuk untuk mengambil foto bukti penyelesaian temuan ini',
        'change_photo': 'Ganti Foto',
        'resolution_notes': 'Catatan Penyelesaian (Opsional)',
        'resolution_notes_hint':
            'Contoh: Barang sudah dirapikan dan area dibersihkan sesuai standar 5R.',
        'resolution_cost': 'Biaya Penyelesaian (Opsional)',
        'resolution_cost_hint': 'Contoh: Rp100.000',
        'err_proof_required': 'Bukti penyelesaian wajib diunggah!',
        'finish_success': 'Temuan berhasil diselesaikan!',
        'finish_fail': 'Gagal menyelesaikan temuan',
        'resolved_by': 'Diselesaikan oleh',
        'completed_on': 'Selesai pada',
        'resolution_result': 'Hasil Penyelesaian',
        'notes': 'Catatan:',
        'cost': 'Biaya yang Dikeluarkan:',
        'resolved': 'Temuan Selesai',
        'extension': 'Perpanjangan Deadline',
        'extension_reason': 'Alasan Perpanjangan',
        'extension_reason_hint':
            'Contoh: Menunggu kedatangan spare part dari supplier.',
        'extension_new_date': 'Tanggal Deadline Baru',
        'extension_submit': 'Ajukan Perpanjangan',
        'extension_success': 'Perpanjangan berhasil diajukan!',
        'extension_fail': 'Gagal mengajukan perpanjangan',
        'extension_err_reason': 'Alasan perpanjangan wajib diisi!',
        'extension_err_date': 'Tanggal baru wajib dipilih!',
        'extension_err_date_past': 'Tanggal baru harus setelah deadline saat ini!',
        'btn_extend': 'Perpanjang Deadline',
        'finish': 'Selesai',
        'finish_and_new': 'Selesaikan & Buat Temuan Baru',
      },
      'EN': {
        'resolution': 'Solution',
        'upload_proof': 'Upload Proof of Solution',
        'upload_proof_subtitle': 'Tap to take a photo as proof this finding is resolved',
        'change_photo': 'Change Photo',
        'resolution_notes': 'Solution Notes (Optional)',
        'resolution_notes_hint':
            'Example: Item has been organized and the area cleaned per 5R standard.',
        'resolution_cost': 'Cost (Optional)',
        'resolution_cost_hint': 'Example: Rp100.000',
        'err_proof_required': 'Proof of solution is required!',
        'finish_success': 'Finding finished successfully!',
        'finish_fail': 'Failed to finish finding',
        'resolved_by': 'Resolved by',
        'completed_on': 'Completed on',
        'resolution_result': 'Solution Result',
        'notes': 'Notes:',
        'cost': 'Cost Incurred:',
        'resolved': 'Finding Resolved',
        'extension': 'Deadline Extension',
        'extension_reason': 'Extension Reason',
        'extension_reason_hint': 'Example: Waiting for spare part delivery from supplier.',
        'extension_new_date': 'New Deadline Date',
        'extension_submit': 'Submit Extension',
        'extension_success': 'Extension submitted successfully!',
        'extension_fail': 'Failed to submit extension',
        'extension_err_reason': 'Extension reason is required!',
        'extension_err_date': 'New date is required!',
        'extension_err_date_past': 'New date must be after current deadline!',
        'btn_extend': 'Extend Deadline',
        'finish': 'Finish',
        'finish_and_new': 'Finish & Create New',
      },
      'ZH': {
        'resolution': '解决方案',
        'upload_proof': '上传解决方案证明',
        'upload_proof_subtitle': '点击拍摄照片，作为该问题已解决的证明',
        'change_photo': '更换照片',
        'resolution_notes': '解决方案说明（可选）',
        'resolution_notes_hint': '例如：物品已整理，区域已按照5R标准清理。',
        'resolution_cost': '费用（可选）',
        'resolution_cost_hint': '例如：Rp100.000',
        'err_proof_required': '必须上传解决方案证明！',
        'finish_success': '发现已成功完成！',
        'finish_fail': '完成发现失败',
        'resolved_by': '解决者',
        'completed_on': '完成于',
        'resolution_result': '解决方案结果',
        'notes': '笔记：',
        'cost': '产生的费用：',
        'resolved': '发现已完成',
        'extension': '截止日期延期',
        'extension_reason': '延期原因',
        'extension_reason_hint': '例如：等待供应商发货备件。',
        'extension_new_date': '新截止日期',
        'extension_submit': '提交延期',
        'extension_success': '延期申请成功！',
        'extension_fail': '延期申请失败',
        'extension_err_reason': '延期原因为必填项！',
        'extension_err_date': '新日期为必填项！',
        'extension_err_date_past': '新日期必须晚于当前截止日期！',
        'btn_extend': '延期截止日期',
        'finish': '完成',
        'finish_and_new': '完成并创建新的',
      },
    };
    _texts = translations[widget.lang] ?? translations['EN']!;
  }
}