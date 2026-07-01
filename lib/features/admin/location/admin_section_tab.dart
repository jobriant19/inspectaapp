import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/admin_image_picker_widget.dart';

class _C {
  static const primary   = Color(0xFF10B981);
  static const primaryLt = Color(0xFFD1FAE5);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class AdminSectionTab extends StatefulWidget {
  final String lang;
  const AdminSectionTab({super.key, required this.lang});

  @override
  State<AdminSectionTab> createState() => _AdminSectionTabState();
}

class _AdminSectionTabState extends State<AdminSectionTab> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _lokasiList = [];
  List<Map<String, dynamic>> _unitList = [];
  List<Map<String, dynamic>> _subunitList = [];
  List<Map<String, dynamic>> _areaList = [];
  bool _loading = true;
  String _search = '';

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _nameOf(Map<String, dynamic> s) {
    if (widget.lang == 'EN') {
      return s['nama_section_en']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    }
    if (widget.lang == 'ZH') {
      return s['nama_section_zh']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    }
    return s['nama_section_id']?.toString() ?? '-';
  }

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _supabase
            .from('section')
            .select(
                '*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)')
            .order('urutan', ascending: true),
        _supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi'),
        _supabase.from('unit').select('id_unit, nama_unit, id_lokasi').order('nama_unit'),
        _supabase.from('subunit').select('id_subunit, nama_subunit, id_unit').order('nama_subunit'),
        _supabase.from('area').select('id_area, nama_area, id_subunit').order('nama_area'),
      ]);
      if (mounted) {
        setState(() {
          _sections = List<Map<String, dynamic>>.from(results[0] as List);
          _lokasiList = List<Map<String, dynamic>>.from(results[1] as List);
          _unitList = List<Map<String, dynamic>>.from(results[2] as List);
          _subunitList = List<Map<String, dynamic>>.from(results[3] as List);
          _areaList = List<Map<String, dynamic>>.from(results[4] as List);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch section: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.trim().isEmpty) return _sections;
    final q = _search.toLowerCase();
    return _sections.where((s) => _nameOf(s).toLowerCase().contains(q)).toList();
  }

  Future<String> _translateText(String text, String langPair) async {
    if (text.trim().isEmpty) return text;
    try {
      final normalized =
          langPair.replaceAll('|zh', '|zh-CN').replaceAll('zh|', 'zh-CN|');
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=$normalized',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final t = data['responseData']?['translatedText']?.toString() ?? '';
        if (t.isEmpty ||
            t.toUpperCase().startsWith('MYMEMORY WARNING') ||
            t.toUpperCase().startsWith('PLEASE')) {
          return text;
        }
        return t;
      }
      return text;
    } catch (_) {
      return text;
    }
  }

  Future<Map<String, String>> _translateAll(String text) async {
    final results = await Future.wait([
      _translateText(text, 'id|en'),
      _translateText(text, 'id|zh'),
    ]);
    return {'id': text, 'en': results[0], 'zh': results[1]};
  }

  void _showSuccessPopup({
    required bool isSuccess,
    required String titleEn,
    required String titleId,
    required String titleZh,
    required String msgEn,
    required String msgId,
    required String msgZh,
  }) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'success_section',
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
        final color = isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final bgLight = isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
        final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
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
                    child: Icon(icon, color: color, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _t(titleEn, titleId, titleZh),
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w800, color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(msgEn, msgId, msgZh),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600, height: 1.5),
                  ),
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
                      child: Text(
                        _t('Close', 'Tutup', '关闭'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
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

  // ADD / EDIT FORM
  Future<void> _showFormDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final namaCtrl =
        TextEditingController(text: isEdit ? existing['nama_section_id']?.toString() ?? '' : '');
    final descCtrl =
        TextEditingController(text: isEdit ? existing['deskripsi_section']?.toString() ?? '' : '');
    final kategoriCtrl =
        TextEditingController(text: isEdit ? existing['kategori']?.toString() ?? '' : '');
    String? gambarUrl = isEdit ? existing['gambar_section'] as String? : null;

    String? selLokasi = isEdit ? existing['id_lokasi']?.toString() : null;
    String? selUnit = isEdit ? existing['id_unit']?.toString() : null;
    String? selSubunit = isEdit ? existing['id_subunit']?.toString() : null;
    String? selArea = isEdit ? existing['id_area']?.toString() : null;

    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final unitOptions = selLokasi == null
              ? _unitList
              : _unitList.where((u) => u['id_lokasi']?.toString() == selLokasi).toList();
          final subunitOptions = selUnit == null
              ? _subunitList
              : _subunitList.where((s) => s['id_unit']?.toString() == selUnit).toList();
          final areaOptions = selSubunit == null
              ? _areaList
              : _areaList.where((a) => a['id_subunit']?.toString() == selSubunit).toList();

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 20, 16),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration:
                            BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEdit
                              ? _t('Edit Section', 'Edit Section', '编辑部门')
                              : _t('Add Section', 'Tambah Section', '添加部门'),
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700, color: _C.textMain),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                        ),
                      ),
                    ]),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _t('Photo', 'Foto', '图片'),
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub),
                          ),
                          const SizedBox(height: 8),
                          AdminImagePickerWidget(
                            currentImageUrl: gambarUrl,
                            storageBucket: 'lokasi-images',
                            storageFolder: 'section',
                            filePrefix: existing?['id_section']?.toString() ?? 'new-section',
                            height: 120,
                            isCircle: false,
                            accentColor: _C.primary,
                            placeholder:
                                const Icon(Icons.dashboard_customize_rounded, color: _C.primary, size: 28),
                            hint: _t('Tap to select image', 'Tap untuk pilih gambar', '点击选择图片'),
                            subHint: _t('Camera or Gallery', 'Kamera atau Galeri', '相机或图库'),
                            uploadingText: _t('Uploading...', 'Mengunggah...', '上传中...'),
                            changeText: _t('Change Image', 'Ganti Gambar', '更换图片'),
                            sourceTitleText: _t('Select Image Source', 'Pilih Sumber Gambar', '选择图片来源'),
                            cameraText: _t('Camera', 'Kamera', '相机'),
                            galleryText: _t('Gallery', 'Galeri', '图库'),
                            onUploaded: (newUrl) => setDlg(() => gambarUrl = newUrl),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _t('Section Name (Indonesian)', 'Nama Section (Indonesia)', '部门名称（印尼语）'),
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: namaCtrl,
                            decoration: InputDecoration(
                              hintText: _t('e.g. Assembly', 'cth. Assy', '例如：组装'),
                              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: _C.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14, color: _C.textMain),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _t('Name will be auto-translated to EN / ZH.',
                                'Nama akan diterjemahkan otomatis ke EN / ZH.', '名称将自动翻译为英文/中文。'),
                            style: GoogleFonts.poppins(fontSize: 10, color: _C.textSub),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _t('Description', 'Deskripsi', '描述'),
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: _t('Optional', 'Opsional', '可选'),
                              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: _C.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _t('Category', 'Kategori', '类别'),
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: kategoriCtrl,
                            decoration: InputDecoration(
                              hintText: _t('Optional', 'Opsional', '可选'),
                              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: _C.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _C.primary, width: 1.5)),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _t('Location Mapping (optional)', 'Pemetaan Lokasi (opsional)', '位置映射（可选）'),
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700, color: _C.textMain),
                          ),
                          const SizedBox(height: 8),
                          _sectionDropdown(
                            label: _t('Location', 'Lokasi', '位置'),
                            items: _lokasiList,
                            idKey: 'id_lokasi',
                            nameKey: 'nama_lokasi',
                            value: selLokasi,
                            onChanged: (v) => setDlg(() {
                              selLokasi = v;
                              selUnit = null;
                              selSubunit = null;
                              selArea = null;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _sectionDropdown(
                            label: _t('Unit', 'Unit', '单位'),
                            items: unitOptions,
                            idKey: 'id_unit',
                            nameKey: 'nama_unit',
                            value: selUnit,
                            onChanged: (v) => setDlg(() {
                              selUnit = v;
                              selSubunit = null;
                              selArea = null;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _sectionDropdown(
                            label: _t('Sub-Unit', 'Sub-Unit', '子单位'),
                            items: subunitOptions,
                            idKey: 'id_subunit',
                            nameKey: 'nama_subunit',
                            value: selSubunit,
                            onChanged: (v) => setDlg(() {
                              selSubunit = v;
                              selArea = null;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _sectionDropdown(
                            label: _t('Area', 'Area', '区域'),
                            items: areaOptions,
                            idKey: 'id_area',
                            nameKey: 'nama_area',
                            value: selArea,
                            onChanged: (v) => setDlg(() => selArea = v),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, -2)),
                      ],
                    ),
                    child: Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _C.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text(
                            _t('Cancel', 'Batal', '取消'),
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600, color: _C.textSub),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final text = namaCtrl.text.trim();
                                  if (text.isEmpty) return;
                                  setDlg(() => isSaving = true);
                                  try {
                                    final isDup = _sections.any((s) =>
                                        (s['nama_section_id']?.toString().trim().toLowerCase() ?? '') ==
                                            text.toLowerCase() &&
                                        (!isEdit || s['id_section'] != existing['id_section']));
                                    if (isDup) {
                                      setDlg(() => isSaving = false);
                                      _showSuccessPopup(
                                        isSuccess: false,
                                        titleEn: 'Duplicate Section',
                                        titleId: 'Section Duplikat',
                                        titleZh: '部门重复',
                                        msgEn: 'This section name already exists.',
                                        msgId: 'Nama section ini sudah ada.',
                                        msgZh: '该部门名称已存在。',
                                      );
                                      return;
                                    }
                                    final t = await _translateAll(text);
                                    final data = {
                                      'nama_section_id': t['id'],
                                      'nama_section_en': t['en'],
                                      'nama_section_zh': t['zh'],
                                      'deskripsi_section':
                                          descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                      'kategori':
                                          kategoriCtrl.text.trim().isEmpty ? null : kategoriCtrl.text.trim(),
                                      'gambar_section': gambarUrl,
                                      'id_lokasi': selLokasi,
                                      'id_unit': selUnit,
                                      'id_subunit': selSubunit,
                                      'id_area': selArea,
                                    };
                                    if (isEdit) {
                                      await _supabase
                                          .from('section')
                                          .update(data)
                                          .eq('id_section', existing['id_section']);
                                    } else {
                                      await _supabase.from('section').insert({
                                        ...data,
                                        'urutan': _sections.length + 1,
                                      });
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    await _fetchAll();
                                    _showSuccessPopup(
                                      isSuccess: true,
                                      titleEn: isEdit ? 'Section Updated!' : 'Section Added!',
                                      titleId: isEdit ? 'Section Diperbarui!' : 'Section Ditambahkan!',
                                      titleZh: isEdit ? '部门已更新！' : '部门已添加！',
                                      msgEn: isEdit
                                          ? 'Section has been updated successfully.'
                                          : 'New section has been saved successfully.',
                                      msgId: isEdit
                                          ? 'Section berhasil diperbarui.'
                                          : 'Section baru berhasil disimpan.',
                                      msgZh: isEdit ? '部门已成功更新。' : '新部门已成功保存。',
                                    );
                                  } catch (e) {
                                    debugPrint('Error save section: $e');
                                    if (ctx.mounted) setDlg(() => isSaving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _t('Saving...', 'Menyimpan...', '保存中...'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                                  ],
                                )
                              : Text(
                                  _t('Save', 'Simpan', '保存'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionDropdown({
    required String label,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.any((e) => e[idKey]?.toString() == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _C.textSub)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: validValue,
              isExpanded: true,
              dropdownColor: Colors.white,
              hint: Text(_t('None', 'Tidak ada', '无'),
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(_t('None', 'Tidak ada', '无'),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black38)),
                ),
                ...items.map((e) => DropdownMenuItem<String>(
                      value: e[idKey]?.toString(),
                      child: Text(
                        e[nameKey]?.toString() ?? '-',
                        style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // DELETE CONFIRM
  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.red.withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: _C.red, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('Delete Section?', 'Hapus Section?', '删除部门？'),
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _C.textMain),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      'Users linked to this section will keep their data, but the section link will be removed.',
                      'User yang terhubung ke section ini datanya tetap ada, namun tautan section akan dihapus.',
                      '与此部门关联的用户数据将保留，但部门关联将被移除。',
                    ),
                    style: GoogleFonts.poppins(fontSize: 12, color: _C.textSub, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 16),
                      label: Text(
                        _t('Delete', 'Hapus', '删除'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.divider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _t('Cancel', 'Batal', '取消'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13, color: _C.textSub),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!ok) return;
    try {
      await _supabase.from('section').delete().eq('id_section', item['id_section']);
      await _fetchAll();
      _showSuccessPopup(
        isSuccess: true,
        titleEn: 'Deleted!',
        titleId: 'Dihapus!',
        titleZh: '已删除！',
        msgEn: 'Section has been deleted.',
        msgId: 'Section berhasil dihapus.',
        msgZh: '部门已成功删除。',
      );
    } catch (e) {
      debugPrint('Delete section error: $e');
    }
  }

  String _locationBadge(Map<String, dynamic> item) {
    final parts = <String>[];
    if (item['lokasi']?['nama_lokasi'] != null) parts.add(item['lokasi']['nama_lokasi']);
    if (item['unit']?['nama_unit'] != null) parts.add(item['unit']['nama_unit']);
    if (item['subunit']?['nama_subunit'] != null) parts.add(item['subunit']['nama_subunit']);
    if (item['area']?['nama_area'] != null) parts.add(item['area']['nama_area']);
    return parts.isEmpty ? '' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final data = _filtered;
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Section Settings', 'Pengaturan Section', '部门设置'),
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _C.primary),
        ),
      ),
      body: Column(
        children: [
          // ADD BUTTON
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: GestureDetector(
              onTap: () => _showFormDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.primary, _C.primary.withValues(alpha: 0.78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                        color: _C.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _t('Add Section', 'Tambah Section', '添加部门'),
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          _t('Tap to add a new section', 'Ketuk untuk menambah section baru', '点击以添加新部门'),
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.white.withValues(alpha: 0.82)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13),
                ]),
              ),
            ),
          ),

          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.divider),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                decoration: InputDecoration(
                  hintText: _t('Search section...', 'Cari section...', '搜索部门...'),
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // COUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${data.length} ${_t('sections', 'section', '个部门')}',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _C.primary, strokeWidth: 2))
                : data.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.dashboard_customize_outlined, size: 52, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(_t('No sections yet.', 'Belum ada section.', '暂无部门。'),
                                style: GoogleFonts.poppins(fontSize: 13, color: _C.textSub)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchAll,
                        color: _C.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: data.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = data[i];
                            final badge = _locationBadge(item);
                            return Container(
                              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _C.divider),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration:
                                      BoxDecoration(color: _C.primaryLt, borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: Text(
                                      '${item['urutan'] ?? i + 1}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, fontWeight: FontWeight.w800, color: _C.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _nameOf(item),
                                        style: GoogleFonts.poppins(
                                            fontSize: 13, fontWeight: FontWeight.w700, color: _C.textMain),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        badge.isEmpty
                                            ? _t('No location mapped', 'Tidak ada lokasi', '未设置位置')
                                            : badge,
                                        style: GoogleFonts.poppins(fontSize: 10, color: _C.textSub),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showFormDialog(existing: item),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: _C.primary.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(9)),
                                    child: const Icon(Icons.edit_outlined, color: _C.primary, size: 15),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _confirmDelete(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: _C.red.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(9)),
                                    child: const Icon(Icons.delete_outline_rounded, color: _C.red, size: 15),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}