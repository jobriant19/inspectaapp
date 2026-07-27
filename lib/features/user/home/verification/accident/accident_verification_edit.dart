import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../accident/picker/accident_pick_cause.dart';
import '../../../accident/picker/accident_pick_severity.dart';
import '../../alert/required_field_alert.dart';

class AccidentVerificationEditScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> laporan;

  const AccidentVerificationEditScreen({
    super.key,
    required this.lang,
    required this.laporan,
  });

  @override
  State<AccidentVerificationEditScreen> createState() =>
      _AccidentVerificationEditScreenState();
}

class _AccidentVerificationEditScreenState
    extends State<AccidentVerificationEditScreen> {
  final _client = Supabase.instance.client;

  late TextEditingController _judulCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _tindakanCtrl;
  late TextEditingController _deptCtrl;
  late String _selectedSeverity;
  late String _selectedCause;
  bool _isSaving = false;

  static const Color _kRed = Color(0xFFDC2626);

  String get _lang => widget.lang;

  @override
  void initState() {
    super.initState();
    final l = widget.laporan;
    _judulCtrl = TextEditingController(text: l['judul'] ?? '');
    _descCtrl = TextEditingController(text: l['deskripsi'] ?? '');
    _tindakanCtrl = TextEditingController(text: l['tindakan_diambil'] ?? '');
    _deptCtrl = TextEditingController(text: l['departemen_terdampak'] ?? '');
    _selectedSeverity = l['tingkat_keparahan'] ?? 'Ringan';
    _selectedCause = l['penyebab'] ?? 'Lainnya';
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _tindakanCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Map<String, String> get _t {
    switch (_lang) {
      case 'EN':
        return {
          'title': 'Edit Accident Report',
          'label_title': 'Title',
          'hint_title': 'Example: Slipped in warehouse',
          'label_desc': 'Incident Description',
          'hint_desc': 'Describe the incident...',
          'label_severity': 'Severity Level',
          'label_cause': 'Cause',
          'label_dept': 'Affected Department',
          'hint_dept': 'e.g. Marketing',
          'label_action': 'Action Taken',
          'hint_action': 'e.g. Taken to hospital',
          'cancel': 'Cancel',
          'save': 'Save',
          'success_title': 'Saved!',
          'success_msg': 'Report updated successfully.',
          'close': 'Close',
        };
      case 'ZH':
        return {
          'title': '编辑事故报告',
          'label_title': '标题',
          'hint_title': '例如：仓库滑倒',
          'label_desc': '事故描述',
          'hint_desc': '详细描述事故经过...',
          'label_severity': '严重程度',
          'label_cause': '原因',
          'label_dept': '受影响部门',
          'hint_dept': '例如：市场部',
          'label_action': '采取的措施',
          'hint_action': '例如：送往医院',
          'cancel': '取消',
          'save': '保存',
          'success_title': '已保存！',
          'success_msg': '报告更新成功。',
          'close': '关闭',
        };
      default:
        return {
          'title': 'Edit Accident Report',
          'label_title': 'Judul',
          'hint_title': 'Contoh: Tergelincir di gudang',
          'label_desc': 'Deskripsi Kejadian',
          'hint_desc': 'Ceritakan kejadian secara rinci...',
          'label_severity': 'Tingkat Keparahan',
          'label_cause': 'Penyebab',
          'label_dept': 'Departemen Terdampak',
          'hint_dept': 'Contoh: Marketing',
          'label_action': 'Tindakan yang Diambil',
          'hint_action': 'Contoh: Dibawa ke rumah sakit',
          'cancel': 'Batal',
          'save': 'Simpan',
          'success_title': 'Tersimpan!',
          'success_msg': 'Laporan berhasil diperbarui.',
          'close': 'Mengerti',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kRed, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t['title']!,
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kRed),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                ctrl: _judulCtrl,
                icon: Icons.edit_note_rounded,
                label: t['label_title']!,
                hint: t['hint_title']!,
              ),
              const SizedBox(height: 16),
              _buildField(
                ctrl: _descCtrl,
                icon: Icons.description_outlined,
                label: t['label_desc']!,
                hint: t['hint_desc']!,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildFieldLabel(t['label_severity']!,
                  icon: Icons.health_and_safety_outlined),
              _buildPickField(
                icon: AccidentSeverityData.iconOf(_selectedSeverity),
                color: AccidentSeverityData.colorOf(_selectedSeverity),
                label: AccidentSeverityData.labelOf(_selectedSeverity, _lang),
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.5),
                    builder: (_) => AccidentPickSeverityScreen(
                      lang: _lang,
                      selectedSeverity: _selectedSeverity,
                    ),
                  );
                  if (result != null) setState(() => _selectedSeverity = result);
                },
              ),
              const SizedBox(height: 16),
              _buildFieldLabel(t['label_cause']!,
                  icon: Icons.warning_amber_rounded),
              _buildPickField(
                icon: AccidentCauseData.iconOf(_selectedCause),
                color: AccidentCauseData.colorOf(_selectedCause),
                label: AccidentCauseData.labelOf(_selectedCause, _lang),
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.5),
                    builder: (_) => AccidentPickCauseScreen(
                      lang: _lang,
                      selectedCause: _selectedCause,
                    ),
                  );
                  if (result != null) setState(() => _selectedCause = result);
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                ctrl: _deptCtrl,
                icon: Icons.business_outlined,
                label: t['label_dept']!,
                hint: t['hint_dept']!,
              ),
              const SizedBox(height: 16),
              _buildField(
                ctrl: _tindakanCtrl,
                icon: Icons.medical_services_outlined,
                label: t['label_action']!,
                hint: t['hint_action']!,
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(t['cancel']!,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(t['save']!,
                              style:
                                  GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kRed),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13, color: _kRed)),
          const Text(' *',
              style: TextStyle(color: _kRed, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, icon: icon),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(color: const Color(0xFFCBD5E1), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kRed, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPickField({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final missing = <MissingFieldItem>[];
    if (_judulCtrl.text.trim().isEmpty) {
      missing.add(
          MissingFieldItem(icon: Icons.edit_note_rounded, label: _t['label_title']!));
    }
    if (_descCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(
          icon: Icons.description_outlined, label: _t['label_desc']!));
    }
    if (_deptCtrl.text.trim().isEmpty) {
      missing.add(
          MissingFieldItem(icon: Icons.business_outlined, label: _t['label_dept']!));
    }
    if (_tindakanCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(
          icon: Icons.medical_services_outlined, label: _t['label_action']!));
    }

    if (missing.isNotEmpty) {
      await RequiredFieldAlert.show(context, lang: _lang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _client.from('accident_report').update({
        'judul': _judulCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'tingkat_keparahan': _selectedSeverity,
        'penyebab': _selectedCause,
        'departemen_terdampak': _deptCtrl.text.trim(),
        'tindakan_diambil': _tindakanCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id_laporan', widget.laporan['id_laporan'].toString());

      if (!mounted) return;

      final updated = Map<String, dynamic>.from(widget.laporan)
        ..['judul'] = _judulCtrl.text.trim()
        ..['deskripsi'] = _descCtrl.text.trim()
        ..['tingkat_keparahan'] = _selectedSeverity
        ..['penyebab'] = _selectedCause
        ..['departemen_terdampak'] = _deptCtrl.text.trim()
        ..['tindakan_diambil'] = _tindakanCtrl.text.trim();

      await _showSuccessPopup();
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      debugPrint('AccidentVerificationEdit save error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showSuccessPopup() {
    final t = _t;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        const color = Color(0xFF16A34A);
        const bgLight = Color(0xFFF0FDF4);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: bgLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: color, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(t['success_title']!,
                      style: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 6),
                  Text(t['success_msg']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600, height: 1.5)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(t['close']!,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
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
}

// ── Fullscreen image viewer (dipakai juga oleh accident_verification_screen.dart) ──
class AccidentFullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const AccidentFullscreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 8,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
                ),
              ),
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
                    decoration:
                        const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
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