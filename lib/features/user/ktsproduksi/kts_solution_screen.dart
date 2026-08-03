import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/jabatan_helper.dart';
import '../home/alert/required_field_alert.dart';
import '../home/popup/location_permission_popup.dart';
import 'camera/kts_solution_camera_screen.dart';
import 'picker/kts_pick_factor.dart';
import 'picker/kts_pick_section.dart';

class KtsSolutionScreen extends StatefulWidget {
  final String ktsId;
  final String lang;
  final Map<String, dynamic>? penyelesaian;
  final bool isResolved;
  final bool isPic;
  final VoidCallback onSaved;

  const KtsSolutionScreen({
    super.key,
    required this.ktsId,
    required this.lang,
    required this.penyelesaian,
    required this.isResolved,
    required this.isPic,
    required this.onSaved,
  });

  @override
  State<KtsSolutionScreen> createState() => _KtsSolutionScreenState();
}

class _KtsSolutionScreenState extends State<KtsSolutionScreen> {
  bool _isSaving = false;
  final _tindakanCtrl = TextEditingController();
  final _biayaCtrl = TextEditingController();
  final _penyebabCtrl = TextEditingController();
  XFile? _resImageFile;
  Map<String, dynamic>? _selectedSubKategori;
  String? _selectedBagian;
  String? _selectedSectionId;

  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'solution_title': 'Solusi',
      'solution_done': 'KTS Sudah Selesai',
      'upload_photo': 'Foto Solusi',
      'tindakan': 'Tindakan',
      'tindakan_hint': 'Jelaskan tindakan...',
      'biaya': 'Biaya',
      'biaya_hint': 'Contoh: 50000',
      'save_solution': 'Simpan Solusi',
      'success_solution': 'Solusi KTS berhasil disimpan! +10 poin',
      'fail_solution': 'Gagal menyimpan solusi',
      'resolved_by': 'Diselesaikan oleh',
      'resolved_at': 'Selesai pada',
      'cost': 'Biaya',
      'ambil_foto': 'Tambah Foto Solusi',
      'ganti': 'Ganti',
      'bagian': 'Bagian',
      'pick_bagian': 'Pilih Bagian',
      'cause': 'Penyebab',
      'cause_hint': 'Jelaskan penyebab...',
      'cause_factor': 'Faktor Penyebab',
    },
    'EN': {
      'solution_title': 'Solution',
      'solution_done': 'KTS Finished',
      'upload_photo': 'Solution Photo',
      'tindakan': 'Action Taken',
      'tindakan_hint': 'Explain action...',
      'biaya': 'Cost',
      'biaya_hint': 'Example: 50000',
      'save_solution': 'Save Solution',
      'success_solution': 'KTS Solution saved! +10 points',
      'fail_solution': 'Failed to save solution',
      'resolved_by': 'Resolved by',
      'resolved_at': 'Completed on',
      'cost': 'Cost',
      'ambil_foto': 'Add Solution Photo',
      'ganti': 'Retake',
      'bagian': 'Section',
      'pick_bagian': 'Select Section',
      'cause': 'Cause',
      'cause_hint': 'Describe the cause...',
      'cause_factor': 'Cause Factor',
    },
    'ZH': {
      'solution_title': '解决方案',
      'solution_done': '已完成',
      'upload_photo': '解决方案照片',
      'tindakan': '行动',
      'tindakan_hint': '说明行动...',
      'biaya': '费用',
      'biaya_hint': '例如：50000',
      'save_solution': '保存方案',
      'success_solution': '解决方案已保存！+10积分',
      'fail_solution': '保存失败',
      'resolved_by': '解决者',
      'resolved_at': '完成时间',
      'cost': '费用',
      'ambil_foto': '添加解决方案照片',
      'ganti': '重拍',
      'bagian': '部门',
      'pick_bagian': '选择部门',
      'cause': '原因',
      'cause_hint': '说明原因...',
      'cause_factor': '原因因素',
    },
  };

  String _t(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    final p = widget.penyelesaian;
    if (p != null) {
      if (p['penyebab'] != null) _penyebabCtrl.text = p['penyebab'];
      if (p['bagian'] != null) _selectedBagian = p['bagian'];
      if (p['faktor_penyebab_kts'] != null) {
        _selectedSubKategori = Map<String, dynamic>.from(p['faktor_penyebab_kts']);
      }
    }
    KtsSolutionCameraWarmupService.instance.warmUp();
  }

  @override
  void dispose() {
    _tindakanCtrl.dispose();
    _biayaCtrl.dispose();
    _penyebabCtrl.dispose();
    KtsSolutionCameraWarmupService.instance.release();
    super.dispose();
  }

  Future<void> _pickResImage() async {
    final img = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(builder: (_) => KtsSolutionCameraScreen(lang: widget.lang)),
    );
    if (img != null && mounted) setState(() => _resImageFile = img);
    KtsSolutionCameraWarmupService.instance.warmUp();
  }

  Future<void> _showSectionPicker() async {
    final result = await showKtsPickSectionDialog(context, lang: widget.lang);
    if (result != null) {
      final name = widget.lang == 'EN'
          ? (result['nama_section_en']?.toString() ?? result['nama_section_id']?.toString())
          : widget.lang == 'ZH'
              ? (result['nama_section_zh']?.toString() ?? result['nama_section_id']?.toString())
              : result['nama_section_id']?.toString();
      setState(() {
        _selectedBagian = name;
        _selectedSectionId = result['id_section']?.toString();
      });
    }
  }

  Future<void> _showFactorPicker() async {
    final result = await showKtsPickFactorDialog(context, lang: widget.lang);
    if (result != null) {
      setState(() => _selectedSubKategori = result);
    }
  }

  Future<void> _saveSolution() async {
    final locResult = await LocationPermissionPopup.requestWithPopup(context, lang: widget.lang);
    if (!locResult.isAtAtmi) {
      if (!mounted) return;
      final msg = widget.lang == 'EN'
          ? 'Solution can only be submitted within PT ATMI Solo area.'
          : widget.lang == 'ZH'
              ? '解决方案只能在PT ATMI Solo区域内提交。'
              : 'Solusi hanya dapat diajukan di area PT ATMI Solo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.location_off_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ]),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final List<MissingFieldItem> missing = [];
    if (_resImageFile == null) {
      missing.add(MissingFieldItem(icon: Icons.photo_camera_rounded, label: _t('upload_photo')));
    }
    if (_selectedBagian == null || _selectedBagian!.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.grid_view_rounded, label: _t('bagian')));
    }
    if (_penyebabCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.help_outline_rounded, label: _t('cause')));
    }
    if (_selectedSubKategori == null) {
      missing.add(MissingFieldItem(icon: Icons.label_outline_rounded, label: _t('cause_factor')));
    }
    if (_tindakanCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.build_circle_outlined, label: _t('tindakan')));
    }
    if (_biayaCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.attach_money_rounded, label: _t('biaya')));
    }
    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final bytes = await _resImageFile!.readAsBytes();
      final fileName = '${user.id}/kts_res_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('temuan_images').uploadBinary(
          fileName, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);

      final biayaValue = _biayaCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_biayaCtrl.text.trim());

      // Ambil poin penyelesaian KTS dari konfigurasi_poin (bukan hardcode 10)
      final konfigKtsResolve = await supabase
          .from('konfigurasi_poin')
          .select('poin, deskripsi_template, deskripsi_template_en, deskripsi_template_zh')
          .eq('kode', 'KTS_RESOLVE')
          .maybeSingle();
      final int poinKtsResolve = (konfigKtsResolve?['poin'] as num?)?.toInt() ?? 25;

      final insertRes = await supabase
          .from('penyelesaian')
          .insert({
            'gambar_penyelesaian': imageUrl,
            'catatan_penyelesaian': _tindakanCtrl.text.trim(),
            'additional_cost': biayaValue,
            'tanggal_selesai': DateTime.now().toIso8601String(),
            'id_user': user.id,
            'poin_penyelesaian': poinKtsResolve,
            'penyebab': _penyebabCtrl.text.trim().isEmpty
                ? (_selectedSubKategori != null ? _selectedSubKategori!['nama_subkategoritemuan'] : null)
                : _penyebabCtrl.text.trim(),
            'bagian': _selectedBagian,
            'id_section': _selectedSectionId,
            'id_subkategoritemuan_penyebab': _selectedSubKategori?['id_subkategoritemuan'],
          })
          .select('id_penyelesaian')
          .single();

      final String newPenyelesaianId = insertRes['id_penyelesaian'].toString();

      await supabase.from('temuan').update({
        'status_temuan': 'Selesai',
        'id_penyelesaian': newPenyelesaianId,
      }).eq('id_temuan', widget.ktsId);

      // Catat log_poin (3 bahasa) & tambah poin User — menggantikan trigger DB lama
      String judulKtsRes = 'Penyelesaian KTS';
      try {
        final temuanRow = await supabase
            .from('temuan')
            .select('judul_temuan')
            .eq('id_temuan', widget.ktsId)
            .maybeSingle();
        judulKtsRes = temuanRow?['judul_temuan']?.toString() ?? judulKtsRes;
      } catch (_) {}

      String isiTemplateKtsRes(String? tmpl, String fallback) => (tmpl ?? fallback)
          .replaceAll('{judul}', judulKtsRes)
          .replaceAll('{poin}', poinKtsResolve.toString());

      await supabase.from('log_poin').insert({
        'id_user': user.id,
        'poin': poinKtsResolve,
        'deskripsi': isiTemplateKtsRes(konfigKtsResolve?['deskripsi_template'],
            'Penyelesaian KTS "{judul}" berhasil dan mendapatkan {poin} poin'),
        'deskripsi_en': isiTemplateKtsRes(konfigKtsResolve?['deskripsi_template_en'],
            'Resolution of KTS "{judul}" completed and earned {poin} poin'),
        'deskripsi_zh': isiTemplateKtsRes(konfigKtsResolve?['deskripsi_template_zh'],
            'KTS "{judul}"问题解决成功，获得{poin}积分'),
        'tipe_aktivitas': 'KTS_RESOLVE',
      });

      final userRowKtsRes = await supabase.from('User').select('poin').eq('id_user', user.id).maybeSingle();
      final currentPoinKtsRes = (userRowKtsRes?['poin'] as num?)?.toInt() ?? 0;
      await supabase.from('User').update({'poin': currentPoinKtsRes + poinKtsResolve}).eq('id_user', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_t('success_solution')),
            backgroundColor: Colors.green));
        setState(() => _isSaving = false);
        widget.onSaved();
      }
    } catch (e) {
      debugPrint('Solution save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${_t('fail_solution')}: $e'),
            backgroundColor: Colors.redAccent));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.penyelesaian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          widget.isResolved ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.wrench_fill,
          _t('solution_title'),
        ),
        const SizedBox(height: 10),
        if (p != null)
          _buildSolutionResult(p)
        else if (widget.isPic)
          _buildSolutionForm()
        else
          _buildNoSolutionEmptyState(),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title, {Color color = const Color(0xFF16A34A)}) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
    ]);
  }

  Widget _requiredLabel(IconData icon, String label, {double iconSize = 14, double fontSize = 14}) {
    return Row(children: [
      Icon(icon, size: iconSize, color: const Color(0xFF16A34A)),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: fontSize, color: const Color(0xFF1E293B))),
      const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _resultLabel(IconData icon, String label, {Color color = const Color(0xFF12B76A)}) {
    return Row(children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 7),
      Text(label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF12B76A))),
    ]);
  }

  Widget _resultValueBox(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(value,
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), height: 1.5)),
    );
  }

  String _jabatanLabel(Map<String, dynamic> user) {
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final jabatanNama =
        (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
    return JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
  }

  Widget _buildJabatanBadge(Map<String, dynamic> user) {
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final label = _jabatanLabel(user);
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildSolutionResult(Map<String, dynamic> p) {
    final solver = p['solver'] as Map<String, dynamic>?;
    final biaya = p['additional_cost'] as num?;
    final biayaStr = biaya != null && biaya > 0
        ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(biaya)
        : '-';
    final String? penyebab = p['penyebab']?.toString();
    final String? bagian = p['bagian']?.toString();

    // FIX: cause factor sekarang diambil dari relasi faktor_penyebab_kts
    // (sesuai yang dipilih user lewat picker di form), bukan dari field 'penyebab'.
    final Map<String, dynamic>? faktorPenyebab =
        p['faktor_penyebab_kts'] as Map<String, dynamic>?;
    final String? faktorNama = faktorPenyebab?['nama_subkategoritemuan']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['gambar_penyelesaian'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(p['gambar_penyelesaian'], width: double.infinity, height: 200, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    Text(_t('solution_done'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF16A34A))),
                  ]),
                ),
                const SizedBox(height: 18),

                if (bagian != null && bagian.isNotEmpty) ...[
                  _resultLabel(CupertinoIcons.square_grid_2x2_fill, _t('bagian')),
                  const SizedBox(height: 8),
                  _resultValueBox(bagian),
                  const SizedBox(height: 16),
                ],

                if (penyebab != null && penyebab.isNotEmpty) ...[
                  _resultLabel(CupertinoIcons.question_circle_fill, _t('cause')),
                  const SizedBox(height: 8),
                  _resultValueBox(penyebab),
                  const SizedBox(height: 16),
                ],

                if (faktorNama != null && faktorNama.isNotEmpty) ...[
                  _resultLabel(CupertinoIcons.tag_fill, _t('cause_factor')),
                  const SizedBox(height: 8),
                  _resultValueBox(faktorNama),
                  const SizedBox(height: 16),
                ],

                _resultLabel(CupertinoIcons.hammer_fill, _t('tindakan')),
                const SizedBox(height: 8),
                _resultValueBox(p['catatan_penyelesaian']?.toString() ?? '-'),

                if (biaya != null && biaya > 0) ...[
                  const SizedBox(height: 16),
                  _resultLabel(CupertinoIcons.money_dollar_circle_fill, _t('cost'), color: const Color(0xFFEA580C)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(biayaStr,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFEA580C))),
                  ),
                ],
                if (solver != null) ...[
                  const SizedBox(height: 16),
                  _resultLabel(CupertinoIcons.person_fill, _t('resolved_by')),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        solver['gambar_user'] != null
                            ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(solver['gambar_user']))
                            : Container(
                                width: 40, height: 40,
                                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                                child: const Icon(CupertinoIcons.person_fill, size: 19, color: Color(0xFF12B76A)),
                              ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(solver['nama'] ?? '-',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
                            if (_jabatanLabel(solver).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _buildJabatanBadge(solver),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (p['tanggal_selesai'] != null) ...[
                  const SizedBox(height: 16),
                  _resultLabel(CupertinoIcons.clock_fill, _t('resolved_at')),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    DateTime? dt;
                    try { dt = DateTime.parse(p['tanggal_selesai'].toString()).toLocal(); } catch (_) {}
                    final dateStr = dt != null ? DateFormat('dd MMM yyyy').format(dt) : '-';
                    final timeStr = dt != null ? DateFormat('HH:mm').format(dt) : '-';
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(children: [
                        const Icon(CupertinoIcons.calendar, size: 15, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Text(dateStr,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF0F172A))),
                        const SizedBox(width: 10),
                        Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
                        const SizedBox(width: 10),
                        const Icon(CupertinoIcons.clock, size: 13, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Text(timeStr,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF0F172A))),
                      ]),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSolutionEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF1D4ED8).withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFBFDBFE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.hourglass, size: 40, color: Color(0xFF1D4ED8)),
          ),
          const SizedBox(height: 18),
          Text(
            widget.lang == 'EN' ? 'No Solution Yet' : widget.lang == 'ZH' ? '暂无解决方案' : 'Belum Ada Solusi',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.lang == 'EN'
                ? 'Waiting for the person in charge to submit a solution for this report.'
                : widget.lang == 'ZH'
                    ? '正在等待负责人为此报告提交解决方案。'
                    : 'Menunggu penanggung jawab mengunggah solusi untuk laporan ini.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _requiredLabel(CupertinoIcons.camera_fill, _t('upload_photo'), iconSize: 15),
          const SizedBox(height: 8),
          _resImageFile == null
              ? GestureDetector(
                  onTap: _pickResImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                        child: const Icon(CupertinoIcons.camera_fill, color: Color(0xFF16A34A), size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(_t('ambil_foto'),
                          style: GoogleFonts.poppins(color: const Color(0xFF16A34A), fontWeight: FontWeight.w600, fontSize: 14)),
                    ]),
                  ),
                )
              : Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: kIsWeb
                        ? Image.network(_resImageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Image.file(File(_resImageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 12, bottom: 12,
                    child: GestureDetector(
                      onTap: _pickResImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(CupertinoIcons.camera_rotate, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(_t('ganti'), style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ),
                  ),
                ]),
          const SizedBox(height: 16),

          _requiredLabel(CupertinoIcons.square_grid_2x2_fill, _t('bagian'), fontSize: 13),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showSectionPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedBagian != null ? const Color(0xFF16A34A) : const Color(0xFFBBF7D0),
                  width: _selectedBagian != null ? 1.5 : 1,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.square_grid_2x2_fill, size: 18,
                      color: _selectedBagian != null ? const Color(0xFF16A34A) : const Color(0xFFBBF7D0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedBagian ?? _t('pick_bagian'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: _selectedBagian != null ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedBagian != null ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_right, size: 15,
                      color: _selectedBagian != null ? const Color(0xFF16A34A) : const Color(0xFFBBF7D0)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _requiredLabel(CupertinoIcons.question_circle_fill, _t('cause')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _penyebabCtrl,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: _t('cause_hint'),
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF0FDF4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBBF7D0), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          _requiredLabel(CupertinoIcons.tag_fill, _t('cause_factor'), fontSize: 13),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showFactorPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedSubKategori != null ? const Color(0xFF16A34A) : const Color(0xFFBBF7D0),
                  width: _selectedSubKategori != null ? 1.5 : 1,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.tag_fill, size: 18,
                      color: _selectedSubKategori != null ? const Color(0xFF16A34A) : const Color(0xFFBBF7D0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedSubKategori?['nama_subkategoritemuan']?.toString() ??
                          (widget.lang == 'ZH' ? '选择原因因素' : widget.lang == 'EN' ? 'Select cause factor' : 'Pilih faktor penyebab'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: _selectedSubKategori != null ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedSubKategori != null ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_right, size: 15,
                      color: _selectedSubKategori != null ? const Color(0xFF16A34A) : const Color(0xFFBBF7D0)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _requiredLabel(CupertinoIcons.hammer_fill, _t('tindakan')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tindakanCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: _t('tindakan_hint'),
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF0FDF4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBBF7D0), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          _requiredLabel(CupertinoIcons.money_dollar_circle_fill, _t('biaya')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _biayaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: _t('biaya_hint'),
              prefixText: 'Rp ',
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF0FDF4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBBF7D0), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: _isSaving ? null : const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                color: _isSaving ? const Color(0xFFE2E8F0) : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isSaving ? null : [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSolution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(_t('save_solution'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}