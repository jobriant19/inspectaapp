import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/jabatan_helper.dart';
import '../../home/popup/location_permission_popup.dart';
import '../camera/camera_finding_screen.dart';
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
  Map<String, dynamic>? _rejectedExtensionInfo;

  late Map<String, String> _texts;

  @override
  void initState() {
    super.initState();
    _setupTranslations();
    CameraWarmupService.instance.warmUp();
    _loadRejectedExtension();
  }

  Future<void> _loadRejectedExtension() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final idTemuan = widget.findingData['id_temuan'].toString();
      final data = await Supabase.instance.client
          .from('perpanjang')
          .select('id_perpanjang, tanggal_selesai, alasan_tolak, responded_at')
          .eq('id_temuan', idTemuan)
          .eq('id_user_pengaju', user.id)
          .eq('status', 'rejected')
          .order('responded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _rejectedExtensionInfo = data);
      }
    } catch (e) {
      debugPrint('Error loading rejected extension: $e');
    }
  }

  @override
  void dispose() {
    _resolutionNotesController.dispose();
    _resolutionCostController.dispose();
    _extensionReasonController.dispose();
    CameraWarmupService.instance.release();
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
    if (mounted) CameraWarmupService.instance.warmUp();
  }

  void _openResolutionImageViewer({XFile? file, String? url}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) =>
            _ResolutionImageViewer(imageFile: file, imageUrl: url),
      ),
    );
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
      _showExtensionResultPopup(
          success: false, message: _texts['extension_err_date_past']!);
      return;
    }

    setState(() => _isExtending = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final String idTemuan = widget.findingData['id_temuan'].toString();
      final String? idCreator = widget.findingData['id_user']?.toString();

      await supabase.from('perpanjang').insert({
        'id_temuan': idTemuan,
        'id_user_pengaju': user.id,
        'id_user_penerima': idCreator,
        'waktu_perpanjang': DateTime.now().toIso8601String(),
        'alasan_perpanjang': _extensionReasonController.text.trim(),
        'tanggal_selesai': _extensionNewDate!.toIso8601String(),
        'deadline_lama': widget.findingData['target_waktu_selesai'],
        'status': 'pending',
      });

      if (idCreator != null && idCreator != user.id) {
        try {
          final creatorData = await supabase
              .from('User')
              .select('fcm_token, nama')
              .eq('id_user', idCreator)
              .maybeSingle();
          final fcmToken = creatorData?['fcm_token']?.toString();
          if (fcmToken != null && fcmToken.trim().isNotEmpty) {
            final notifTitle = widget.lang == 'EN'
                ? '⏳ Deadline Extension Request'
                : widget.lang == 'ZH'
                    ? '⏳ 截止日期延期请求'
                    : '⏳ Pengajuan Perpanjangan Deadline';
            final notifBody = widget.findingData['judul_temuan']?.toString() ?? '';
            await supabase.functions.invoke(
              'send-fcm-v1',
              body: {
                'token': fcmToken.trim(),
                'title': notifTitle,
                'body': notifBody,
                'data': {
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'route': 'extension_requests',
                },
              },
            );
          }
        } catch (e) {
          debugPrint('❌ FCM extension request error: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _showExtensionResultPopup(
            success: true, message: _texts['extension_request_sent']!);
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

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 640),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D72F3).withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D72F3).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.schedule_rounded,
                                  color: Color(0xFF1D72F3), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _texts['extension']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D72F3),
                                ),
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
                                    widget.lang == 'EN'
                                        ? 'Current deadline: ${_formatDateTime(data['target_waktu_selesai'], format: 'dd MMM yyyy')}'
                                        : widget.lang == 'ZH'
                                            ? '当前截止日期：${_formatDateTime(data['target_waktu_selesai'], format: 'dd MMM yyyy')}'
                                            : 'Deadline saat ini: ${_formatDateTime(data['target_waktu_selesai'], format: 'dd MMM yyyy')}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 15, color: Color(0xFF1D72F3)),
                            const SizedBox(width: 6),
                            Text(_texts['extension_reason']!,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: const Color(0xFF1D72F3))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _extensionReasonController,
                          maxLines: 3,
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                          decoration: InputDecoration(
                            hintText: _texts['extension_reason_hint']!,
                            hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.normal),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1D72F3), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1D72F3), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 15, color: Color(0xFF1D72F3)),
                            const SizedBox(width: 6),
                            Text(_texts['extension_new_date']!,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: const Color(0xFF1D72F3))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await _showExtensionDatePicker(
                              dialogCtx,
                              widget.lang,
                              _extensionNewDate,
                            );
                            if (picked != null) {
                              setModalState(() => _extensionNewDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _extensionNewDate != null
                                    ? const Color(0xFF1D72F3).withValues(alpha: 0.5)
                                    : Colors.grey.shade200,
                                width: _extensionNewDate != null ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    color: _extensionNewDate != null
                                        ? const Color(0xFF1D72F3)
                                        : const Color(0xFF1E3A8A),
                                    size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _extensionNewDate != null
                                        ? DateFormat('EEEE, d MMMM yyyy', _localeFor(widget.lang)).format(_extensionNewDate!)
                                        : (_texts['extension_new_date']!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: _extensionNewDate != null
                                          ? Colors.black
                                          : Colors.grey.shade500,
                                      fontWeight: _extensionNewDate != null
                                          ? FontWeight.w800
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down,
                                    color: _extensionNewDate != null
                                        ? const Color(0xFF1D72F3)
                                        : Colors.grey.shade400),
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
                              backgroundColor: const Color(0xFF1D72F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isExtending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
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
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
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

  Future<DateTime?> _showExtensionDatePicker(
    BuildContext context,
    String lang,
    DateTime? initialDate,
  ) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => _ExtensionDeadlineCalendarDialog(
        lang: lang,
        initialDate: initialDate,
      ),
    );
  }

  Future<void> _finishFinding({bool createNewAfter = false}) async {
    final locResult = await LocationPermissionPopup.requestWithPopup(context, lang: widget.lang);

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

      final data = widget.findingData;
      final String jenisTemuan = (data['jenis_temuan'] ?? '').toString();

      int poinPenyelesaian;
      String? kodePoinResolve;
      Map<String, dynamic>? konfigResolve;

      if (jenisTemuan == '5R') {
        final bool isVisitorR = data['is_visitor'] == true;
        final bool isEksekutifR = data['is_eksekutif'] == true;
        final bool isProR = data['is_pro'] == true;
        final int comboR =
            (isVisitorR ? 1 : 0) + (isEksekutifR ? 1 : 0) + (isProR ? 1 : 0);

        kodePoinResolve = comboR >= 3
            ? '5R_RESOLVE_COMBO3'
            : comboR == 2
                ? '5R_RESOLVE_COMBO2'
                : isVisitorR
                    ? '5R_RESOLVE_VISITOR'
                    : isEksekutifR
                        ? '5R_RESOLVE_EXECUTIVE'
                        : isProR
                            ? '5R_RESOLVE_PROFESSIONAL'
                            : '5R_RESOLVE_BASE';

        konfigResolve = await supabase
            .from('konfigurasi_poin')
            .select('poin, deskripsi_template, deskripsi_template_en, deskripsi_template_zh')
            .eq('kode', kodePoinResolve)
            .maybeSingle();

        poinPenyelesaian = (konfigResolve?['poin'] as num?)?.toInt() ?? 15;

        final idKategoriR = data['id_kategoritemuan_uuid'];
        if (idKategoriR != null) {
          final kR = await supabase
              .from('kategoritemuan')
              .select('poin_kategoritemuan')
              .eq('id_kategoritemuan', idKategoriR)
              .maybeSingle();
          poinPenyelesaian += (kR?['poin_kategoritemuan'] as num?)?.toInt() ?? 0;
        }

        final idSubkategoriR = data['id_subkategoritemuan_uuid'];
        if (idSubkategoriR != null) {
          final skR = await supabase
              .from('subkategoritemuan')
              .select('poin_subkategoritemuan')
              .eq('id_subkategoritemuan', idSubkategoriR)
              .maybeSingle();
          poinPenyelesaian += (skR?['poin_subkategoritemuan'] as num?)?.toInt() ?? 0;
        }
      } else {
        final temuanData = await supabase
            .from('temuan')
            .select('poin_temuan')
            .eq('id_temuan', idTemuan)
            .maybeSingle();
        poinPenyelesaian = (temuanData?['poin_temuan'] as num?)?.toInt() ?? 0;
      }

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

      if (poinPenyelesaian > 0) {
        String judulTemuan = data['judul_temuan']?.toString() ?? 'Penyelesaian temuan';
        String deskripsiId, deskripsiEn, deskripsiZh, tipeAktivitas;

        if (jenisTemuan == '5R' && kodePoinResolve != null) {
          final bool isVisitorR = data['is_visitor'] == true;
          final bool isEksekutifR = data['is_eksekutif'] == true;
          final bool isProR = data['is_pro'] == true;

          List<String> rId = [], rEn = [], rZh = [];
          if (isVisitorR) { rId.add('Visitor'); rEn.add('Visitor'); rZh.add('访客'); }
          if (isEksekutifR) { rId.add('Eksekutif'); rEn.add('Executive'); rZh.add('高管'); }
          if (isProR) { rId.add('Profesional'); rEn.add('Professional'); rZh.add('专业人员'); }
          final roleId = rId.isEmpty ? 'Reguler' : rId.join(' & ');
          final roleEn = rEn.isEmpty ? 'Regular' : rEn.join(' & ');
          final roleZh = rZh.isEmpty ? '常规' : rZh.join(' & ');

          String isi(String? tmpl, String fallback, String role) => (tmpl ?? fallback)
              .replaceAll('{judul}', judulTemuan)
              .replaceAll('{role}', role)
              .replaceAll('{poin}', poinPenyelesaian.toString());

          deskripsiId = isi(konfigResolve?['deskripsi_template'],
              'Penyelesaian temuan 5R "{judul}" ({role}) berhasil dan mendapatkan {poin} poin', roleId);
          deskripsiEn = isi(konfigResolve?['deskripsi_template_en'],
              'Resolution of 5R finding "{judul}" ({role}) completed and earned {poin} poin', roleEn);
          deskripsiZh = isi(konfigResolve?['deskripsi_template_zh'],
              '5R发现"{judul}"（{role}）问题解决成功，获得{poin}积分', roleZh);
          tipeAktivitas = kodePoinResolve;
        } else {
          deskripsiId = 'Penyelesaian: $judulTemuan';
          deskripsiEn = deskripsiId;
          deskripsiZh = deskripsiId;
          tipeAktivitas = 'penyelesaian';
        }

        await supabase.from('log_poin').insert({
          'id_user': user.id,
          'poin': poinPenyelesaian,
          'deskripsi': deskripsiId,
          'deskripsi_en': deskripsiEn,
          'deskripsi_zh': deskripsiZh,
          'tipe_aktivitas': tipeAktivitas,
        });

        final userRow = await supabase
            .from('User')
            .select('poin')
            .eq('id_user', user.id)
            .maybeSingle();
        final currentPoin = (userRow?['poin'] as num?)?.toInt() ?? 0;
        await supabase
            .from('User')
            .update({'poin': currentPoin + poinPenyelesaian})
            .eq('id_user', user.id);
      }

      final String? idCreatorSolusi = data['id_user']?.toString();
      if (idCreatorSolusi != null && idCreatorSolusi != user.id) {
        try {
          final creatorSolusiData = await supabase
              .from('User')
              .select('fcm_token, nama')
              .eq('id_user', idCreatorSolusi)
              .maybeSingle();
          final fcmTokenCreator = creatorSolusiData?['fcm_token']?.toString();
          if (fcmTokenCreator != null && fcmTokenCreator.trim().isNotEmpty) {
            final notifTitleSolusi = widget.lang == 'EN'
                ? '✅ Your Finding Has Been Resolved'
                : widget.lang == 'ZH'
                    ? '✅ 您的发现已解决'
                    : '✅ Temuan Anda Telah Diselesaikan';
            final notifBodySolusi = data['judul_temuan']?.toString() ?? '';
            await supabase.functions.invoke(
              'send-fcm-v1',
              body: {
                'token': fcmTokenCreator.trim(),
                'title': notifTitleSolusi,
                'body': notifBodySolusi,
                'data': {
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                  'route': 'findings',
                },
              },
            );
            debugPrint('✅ FCM sent to finding creator: ${creatorSolusiData?['nama']}');
          }
        } catch (e) {
          debugPrint('❌ FCM creator (resolution) error: $e');
        }
      }

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

  String _localeFor(String lang) {
    switch (lang) {
      case 'EN':
        return 'en_US';
      case 'ZH':
        return 'zh_CN';
      default:
        return 'id_ID';
    }
  }

  String _formatDateTime(String? dateStr, {String format = 'dd MMM yyyy, HH:mm'}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final locale = _localeFor(widget.lang);
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat(format, locale).format(dt);
    } catch (e) {
      try {
        final parsableDateStr = dateStr.replaceFirst(' ', 'T');
        final dt = DateTime.parse(parsableDateStr).toLocal();
        return DateFormat(format, locale).format(dt);
      } catch (e2) {
        return dateStr.substring(0, 19).replaceAll('T', ' ');
      }
    }
  }

  void _showExtensionResultPopup({required bool success, required String message}) {
    if (!mounted) return;
    final Color color = success ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'extension_result',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        Future.delayed(Duration(milliseconds: success ? 2000 : 2500), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
                    ),
                    child: Icon(icon, color: color, size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    success
                        ? (widget.lang == 'EN'
                            ? 'Success!'
                            : widget.lang == 'ZH'
                                ? '成功！'
                                : 'Berhasil!')
                        : (widget.lang == 'EN'
                            ? 'Failed!'
                            : widget.lang == 'ZH'
                                ? '失败！'
                                : 'Gagal!'),
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w800, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        if (_rejectedExtensionInfo != null) ...[
          _buildRejectedExtensionBanner(),
          const SizedBox(height: 16),
        ],
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
                  const Icon(Icons.photo_camera_rounded, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    _texts['upload_proof']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  Text(' *',
                      style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
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
                    GestureDetector(
                      onTap: () => _openResolutionImageViewer(file: _resolutionImageFile),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            kIsWeb
                                ? Image.network(_resolutionImageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                                : Image.file(File(_resolutionImageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
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
              Row(
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    _texts['resolution_notes']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  Text(' *',
                      style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resolutionNotesController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.black),
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
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    _texts['resolution_cost']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
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

  Widget _buildRejectedExtensionBanner() {
    final reason = _rejectedExtensionInfo?['alasan_tolak']?.toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lang == 'EN'
                      ? 'Extension Request Rejected'
                      : widget.lang == 'ZH'
                          ? '延期申请已被拒绝'
                          : 'Pengajuan Perpanjangan Ditolak',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C)),
                ),
                if (reason != null && reason.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF7F1D1D)),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _rejectedExtensionInfo = null),
            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFB91C1C)),
          ),
        ],
      ),
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
                GestureDetector(
                  onTap: () => _openResolutionImageViewer(url: imageUrl),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Stack(
                      children: [
                        Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: 220),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_pin_rounded,
                                size: 16, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _texts['resolved_by']!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFDCFCE7),
                              backgroundImage:
                                  solverAvatarUrl != null ? NetworkImage(solverAvatarUrl) : null,
                              child: solverAvatarUrl == null
                                  ? const Icon(Icons.person, color: Color(0xFF16A34A))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    solverName,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: const Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildSolverJabatanBadge(solver),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (completedDate != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.event_available_rounded,
                                  size: 16, color: Color(0xFF16A34A)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_texts['completed_on']!,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF16A34A))),
                                  const SizedBox(height: 2),
                                  Text(_formatDateTime(completedDate),
                                      style: GoogleFonts.poppins(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.sticky_note_2_outlined,
                              size: 16, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Text(
                            _texts['resolution_notes']!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          Text(' *',
                              style: GoogleFonts.poppins(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          notes,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF166534),
                            height: 1.6,
                            fontSize: 14,
                          ),
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

  Widget _buildSolverJabatanBadge(Map<String, dynamic> solver) {
    final idJabatan = solver['id_jabatan'] as int?;
    final isVerificator = solver['is_verificator'] as bool?;
    final jabatanNama =
        (solver['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;

    final label = JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
    if (label.isEmpty) return const SizedBox.shrink();

    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
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
        'resolution_notes': 'Catatan Penyelesaian',
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
        'extension_request_sent': 'Pengajuan terkirim! Menunggu persetujuan pembuat temuan.',
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
        'resolution_notes': 'Solution Notes',
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
        'extension_request_sent': 'Request sent! Waiting for the finding creator\'s approval.',
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
        'resolution_notes': '解决方案说明',
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
        'extension_request_sent': '申请已发送！等待发现创建者批准。',
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

class _ExtensionDeadlineCalendarDialog extends StatefulWidget {
  final String lang;
  final DateTime? initialDate;

  const _ExtensionDeadlineCalendarDialog({
    required this.lang,
    required this.initialDate,
  });

  @override
  State<_ExtensionDeadlineCalendarDialog> createState() =>
      _ExtensionDeadlineCalendarDialogState();
}

class _ExtensionDeadlineCalendarDialogState
    extends State<_ExtensionDeadlineCalendarDialog> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  static const Color _kBrand = Color(0xFF1D72F3);

  static const List<String> _monthLabelsId = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<String> get _weekdayLabels {
    if (widget.lang == 'EN') return const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    if (widget.lang == 'ZH') return const ['日', '一', '二', '三', '四', '五', '六'];
    return const ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
  }

  String _monthTitle(DateTime d) {
    if (widget.lang == 'EN') return DateFormat('MMMM yyyy').format(d);
    if (widget.lang == 'ZH') return '${d.year}年 ${d.month}月';
    return '${_monthLabelsId[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final minSelectable = DateTime(today.year, today.month, today.day);
    final maxSelectable = today.add(const Duration(days: 365));

    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmptyDays = firstDayOfMonth.weekday % 7;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kBrand.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_available_rounded,
                      color: _kBrand, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  _t('PILIH TANGGAL BARU', 'SELECT NEW DATE', '选择新日期'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kBrand,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('EEE, d MMM yyyy').format(_selected),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _monthTitle(_visibleMonth),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _changeMonth(-1),
                      child: const Icon(Icons.chevron_left_rounded, color: _kBrand),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _changeMonth(1),
                      child: const Icon(Icons.chevron_right_rounded, color: _kBrand),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: _weekdayLabels
                  .map((w) => Expanded(
                        child: Center(
                          child: Text(
                            w,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysInMonth + leadingEmptyDays,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyDays) return const SizedBox.shrink();
                final day = index - leadingEmptyDays + 1;
                final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                final isSelected = date.year == _selected.year &&
                    date.month == _selected.month &&
                    date.day == _selected.day;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isDisabled =
                    date.isBefore(minSelectable) || date.isAfter(maxSelectable);

                return GestureDetector(
                  onTap: isDisabled ? null : () => setState(() => _selected = date),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _kBrand
                          : (isToday ? _kBrand.withValues(alpha: 0.1) : Colors.transparent),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$day',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isDisabled
                            ? Colors.grey.shade300
                            : isSelected
                                ? Colors.white
                                : (isToday ? _kBrand : const Color(0xFF334155)),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    _t('Batal', 'Cancel', '取消'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBrand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolutionImageViewer extends StatelessWidget {
  final XFile? imageFile;
  final String? imageUrl;
  const _ResolutionImageViewer({this.imageFile, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (imageFile != null) {
      content = kIsWeb
          ? Image.network(imageFile!.path, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
          : Image.file(File(imageFile!.path), fit: BoxFit.contain, width: double.infinity, height: double.infinity);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
      );
    } else {
      content = const Icon(Icons.image_not_supported, color: Colors.white54, size: 60);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4,
              child: Center(child: content),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}