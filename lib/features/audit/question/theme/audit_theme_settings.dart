import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';
import '../../../user/home/alert/required_field_alert.dart';
import 'audit_theme_detail.dart';

class _C {
  static const primary   = Color(0xFF1D72F3);
  static const primaryLt = Color(0xFFE3EFFE);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class AuditThemeSettingsScreen extends StatefulWidget {
  final String lang;
  final String idJenisAudit;
  final VoidCallback onChanged;

  const AuditThemeSettingsScreen({
    super.key,
    required this.lang,
    required this.idJenisAudit,
    required this.onChanged,
  });

  @override
  State<AuditThemeSettingsScreen> createState() =>
      _AuditThemeSettingsScreenState();
}

class _AuditThemeSettingsScreenState extends State<AuditThemeSettingsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _temas = [];
  String _jenisAuditLabel = '-';
  bool _loading = true;
  int _temaPage = 1;
  static const int _temasPerPage = 10;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _temaLabel(Map<String, dynamic> t) {
    if (widget.lang == 'EN') return t['nama_tema_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return t['nama_tema_zh']?.toString() ?? '-';
    return t['nama_tema_id']?.toString() ?? '-';
  }

  List<Map<String, dynamic>> get _filteredTemas {
    if (_search.trim().isEmpty) return _temas;
    final q = _search.trim().toLowerCase();
    return _temas.where((t) {
      return (t['nama_tema_id'] ?? '').toString().toLowerCase().contains(q) ||
          (t['nama_tema_en'] ?? '').toString().toLowerCase().contains(q) ||
          (t['nama_tema_zh'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _supabase
            .from('audit_tema')
            .select()
            .eq('id_jenis_audit', widget.idJenisAudit)
            .order('urutan', ascending: true),
        _supabase
            .from('jenis_audit')
            .select()
            .eq('id_jenis_audit', widget.idJenisAudit)
            .maybeSingle(),
      ]);
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(results[0] as List);
        list.sort((a, b) => ((a['urutan'] as num?) ?? 0)
            .compareTo((b['urutan'] as num?) ?? 0));

        final jenisRow = results[1] as Map<String, dynamic>?;
        String label = _jenisAuditLabel;
        if (jenisRow != null) {
          label = widget.lang == 'EN'
              ? (jenisRow['nama_en']?.toString() ?? '-')
              : widget.lang == 'ZH'
                  ? (jenisRow['nama_zh']?.toString() ?? '-')
                  : (jenisRow['nama_id']?.toString() ?? '-');
        }

        setState(() {
          _temas = list;
          _jenisAuditLabel = label;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch theme settings data: $e');
      if (mounted) setState(() => _loading = false);
    }
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
      barrierLabel: 'success_tema',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        final color =
            isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final bgLight =
            isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
        final icon =
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
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
                      border: Border.all(
                          color: color.withValues(alpha: 0.25), width: 2),
                    ),
                    child: Icon(icon, color: color, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _t(titleEn, titleId, titleZh),
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(msgEn, msgId, msgZh),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _t('Close', 'Tutup', '关闭'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white),
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
    final ctrl = TextEditingController(
        text: existing != null
            ? existing['nama_tema_id']?.toString() ?? ''
            : '');
    final isEdit = existing != null;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _C.primaryLt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_outlined,
                        color: _C.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit
                          ? _t('Edit Theme', 'Edit Tema', '编辑主题')
                          : _t('Add Theme', 'Tambah Tema', '添加主题'),
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.textMain),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.close,
                          size: 16, color: Colors.grey.shade500),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  _t(
                    'Name will be auto-translated to ID / EN / ZH.',
                    'Nama akan diterjemahkan otomatis ke ID / EN / ZH.',
                    '名称将自动翻译为 ID / EN / ZH。',
                  ),
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _C.textSub),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  const Icon(Icons.edit_note_rounded,
                      size: 14, color: _C.primary),
                  const SizedBox(width: 6),
                  Text(
                    _t('Theme Name (Indonesian)', 'Nama Tema (Indonesia)',
                        '主题名称（印尼语）'),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.primary),
                  ),
                  Text(' *',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.red)),
                ]),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: _t('e.g. Target Achievement',
                        'cth. Target Pencapaian', '例如：目标达成'),
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: _C.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _C.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  style:
                      GoogleFonts.poppins(fontSize: 14, color: _C.textMain),
                ),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _C.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        _t('Cancel', 'Batal', '取消'),
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _C.textSub),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final text = ctrl.text.trim();

                        if (text.isEmpty) {
                          RequiredFieldAlert.show(
                            context,
                            lang: widget.lang,
                            missingFields: [
                              MissingFieldItem(
                                icon: Icons.edit_note_rounded,
                                label: _t('Theme Name', 'Nama Tema', '主题名称'),
                              ),
                            ],
                          );
                          return;
                        }

                        final isDup = _temas.any((tm) =>
                            (tm['nama_tema_id']?.toString().trim().toLowerCase() ?? '') ==
                                text.toLowerCase() &&
                            (!isEdit || tm['id_tema'] != existing['id_tema']));
                        if (isDup) {
                          Navigator.pop(ctx);
                          _showSuccessPopup(
                            isSuccess: false,
                            titleEn: 'Duplicate Theme',
                            titleId: 'Tema Duplikat',
                            titleZh: '主题重复',
                            msgEn:
                                'This theme name already exists in this audit type.',
                            msgId: 'Nama tema ini sudah ada pada jenis audit ini.',
                            msgZh: '该审计类型中已存在此主题名称。',
                          );
                          return;
                        }

                        Navigator.pop(ctx);

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => _TranslatingThemeDialog(
                                color: _C.primary, lang: widget.lang),
                          );
                        }

                        Map<String, String> t;
                        try {
                          t = await TranslationHelper.instance
                              .translateDescriptionAllLangs(text, 'ID');
                        } catch (e) {
                          debugPrint('Error translating tema: $e');
                          t = {'id': text, 'en': text, 'zh': text};
                        }

                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        try {
                          if (isEdit) {
                            await _supabase.from('audit_tema').update({
                              'nama_tema_id': t['id'],
                              'nama_tema_en': t['en'],
                              'nama_tema_zh': t['zh'],
                            }).eq('id_tema', existing['id_tema']);
                          } else {
                            await _supabase.from('audit_tema').insert({
                              'id_jenis_audit': widget.idJenisAudit,
                              'nama_tema_id': t['id'],
                              'nama_tema_en': t['en'],
                              'nama_tema_zh': t['zh'],
                              'urutan': _temas.length + 1,
                            });
                          }
                          await _fetchAll();
                          widget.onChanged();
                          _showSuccessPopup(
                            isSuccess: true,
                            titleEn: isEdit ? 'Theme Updated!' : 'Theme Added!',
                            titleId:
                                isEdit ? 'Tema Diperbarui!' : 'Tema Ditambahkan!',
                            titleZh: isEdit ? '主题已更新！' : '主题已添加！',
                            msgEn: isEdit
                                ? 'Theme has been updated successfully.'
                                : 'New theme has been saved successfully.',
                            msgId: isEdit
                                ? 'Tema berhasil diperbarui.'
                                : 'Tema baru berhasil disimpan.',
                            msgZh: isEdit ? '主题已成功更新。' : '新主题已成功保存。',
                          );
                        } catch (e) {
                          debugPrint('Error save tema: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        _t('Save', 'Simpan', '保存'),
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DELETE CONFIRM
  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
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
                      border: Border.all(
                          color: _C.red.withValues(alpha: 0.25), width: 2),
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: _C.red, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('Delete Theme?', 'Hapus Tema?', '删除主题？'),
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textMain),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      'All questions under this theme will also be deleted.',
                      'Semua pertanyaan di bawah tema ini juga akan terhapus.',
                      '该主题下的所有问题也将被删除。',
                    ),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _C.textSub, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: Colors.white, size: 16),
                      label: Text(
                        _t('Delete', 'Hapus', '删除'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _t('Cancel', 'Batal', '取消'),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _C.textSub),
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
      await _supabase
          .from('audit_question')
          .delete()
          .eq('id_tema', item['id_tema']);
      await _supabase
          .from('audit_tema')
          .delete()
          .eq('id_tema', item['id_tema']);
      await _fetchAll();
      widget.onChanged();
      _showSuccessPopup(
        isSuccess: true,
        titleEn: 'Deleted!',
        titleId: 'Dihapus!',
        titleZh: '已删除！',
        msgEn: 'Theme and its questions have been deleted.',
        msgId: 'Tema dan pertanyaannya berhasil dihapus.',
        msgZh: '主题及其问题已成功删除。',
      );
    } catch (e) {
      debugPrint('Delete tema error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _C.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Theme Settings', 'Pengaturan Tema', '主题设置'),
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.primary),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _t('Add Theme', 'Tambah Tema', '添加主题'),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        Text(
                          _t('Tap to add a new theme',
                              'Ketuk untuk menambah tema baru',
                              '点击以添加新主题'),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.82)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 13),
                ]),
              ),
            ),
          ),

          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.divider),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {
                  _search = v;
                  _temaPage = 1;
                }),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                decoration: InputDecoration(
                  isDense: true,
                  hintText:
                      _t('Search theme...', 'Cari tema...', '搜索主题...'),
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.black38, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() {
                              _search = '';
                              _temaPage = 1;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _C.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: _C.red),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          // COUNT BADGE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _C.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.list_alt_rounded,
                        size: 13, color: _C.primary),
                    const SizedBox(width: 5),
                    Text(
                      '${_filteredTemas.length} ${_t('themes', 'tema', '个主题')}',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: _loading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade50,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, __) => Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  )
                : _buildThemeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 140,
              errorBuilder: (_, __, ___) => Icon(
                Icons.folder_open_outlined,
                size: 80,
                color: _C.primary.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _C.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeList() {
    final filtered = _filteredTemas;

    if (_temas.isEmpty) {
      return _buildEmptyState(
        title: _t('No themes yet.', 'Belum ada tema.', '暂无主题。'),
        subtitle: _t(
          'Tap "Add Theme" above to get started.',
          'Ketuk "Tambah Tema" di atas untuk memulai.',
          '点击上方"添加主题"开始使用。',
        ),
      );
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(
        title: _t('No themes found.', 'Tema tidak ditemukan.', '未找到主题。'),
        subtitle: _t(
          'Try a different keyword.',
          'Coba kata kunci lain.',
          '请尝试其他关键词。',
        ),
      );
    }

    final int totalPages = (filtered.length / _temasPerPage).ceil();
    int page = _temaPage;
    if (page > totalPages) page = totalPages;
    if (page < 1) page = 1;

    final int start = (page - 1) * _temasPerPage;
    final int end = (start + _temasPerPage).clamp(0, filtered.length);
    final List<Map<String, dynamic>> pagedTemas = filtered.sublist(start, end);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAll,
            color: _C.primary,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              itemCount: pagedTemas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = pagedTemas[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuditThemeDetailScreen(
                        lang: widget.lang,
                        item: item,
                        jenisAuditLabel: _jenisAuditLabel,
                        onEdit: (it) => _showFormDialog(existing: it),
                        onDelete: (it) => _confirmDelete(it),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _C.primaryLt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${item['urutan'] ?? start + i + 1}',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _C.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _temaLabel(item),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black),
                        ),
                      ),
                      // EDIT
                      GestureDetector(
                        onTap: () => _showFormDialog(existing: item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _C.primary.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: _C.primary, size: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // DELETE
                      GestureDetector(
                        onTap: () => _confirmDelete(item),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _C.red.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: _C.red, size: 15),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _ThemeBottomIndicator(
              currentPage: page,
              totalPages: totalPages,
              color: _C.primary,
              onPageChanged: (p) => setState(() => _temaPage = p),
            ),
          ),
      ],
    );
  }
}

class _TranslatingThemeDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _TranslatingThemeDialog({required this.color, required this.lang});

  @override
  State<_TranslatingThemeDialog> createState() =>
      _TranslatingThemeDialogState();
}

class _TranslatingThemeDialogState extends State<_TranslatingThemeDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.lang) {
      case 'EN':
        return 'Translating...';
      case 'ZH':
        return '翻译中...';
      default:
        return 'Menerjemahkan...';
    }
  }

  String get _subtitle {
    switch (widget.lang) {
      case 'EN':
        return 'Converting to Indonesian, English & Mandarin';
      case 'ZH':
        return '正在转换为印尼语、英语和中文';
      default:
        return 'Mengubah ke Bahasa Indonesia, Inggris & Mandarin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.90 + (_controller.value * 0.12);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.translate_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 150,
                height: 6,
                child: LinearProgressIndicator(
                  backgroundColor: widget.color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeBottomIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _ThemeBottomIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.color,
    required this.onPageChanged,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _arrow(Icons.arrow_back_ios_new_rounded, canPrev, () {
            if (canPrev) onPageChanged(currentPage - 1);
          }),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (final p in pageNumbers) ...[
                  Expanded(child: _pageButton(p)),
                  if (p != pageNumbers.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _arrow(Icons.arrow_forward_ios_rounded, canNext, () {
            if (canNext) onPageChanged(currentPage + 1);
          }),
        ],
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page != currentPage) onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              isActive ? null : Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}