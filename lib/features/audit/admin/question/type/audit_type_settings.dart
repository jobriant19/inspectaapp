import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/services/translation_service.dart';
import '../../../../user/home/alert/required_field_alert.dart';
import 'audit_type_detail.dart';

class _C {
  static const primary   = Color(0xFF6366F1);
  static const primaryLt = Color(0xFFEDE9FE);
  static const red       = Color(0xFFEF4444);
  static const blue      = Color(0xFF2563EB);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

class AuditTypeSettingsScreen extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> initialList;
  final VoidCallback onChanged;

  const AuditTypeSettingsScreen({
    super.key,
    required this.lang,
    required this.initialList,
    required this.onChanged,
  });

  @override
  State<AuditTypeSettingsScreen> createState() =>
      _AuditTypeSettingsScreenState();
}

class _AuditTypeSettingsScreenState extends State<AuditTypeSettingsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _list = [];
  String _search = '';
  bool _loading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  String _label(Map<String, dynamic> j) {
    if (widget.lang == 'EN') return j['nama_en']?.toString() ?? '-';
    if (widget.lang == 'ZH') return j['nama_zh']?.toString() ?? '-';
    return j['nama_id']?.toString() ?? '-';
  }

  @override
  void initState() {
    super.initState();
    _list = List.from(widget.initialList);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final rows = await _supabase
          .from('jenis_audit')
          .select()
          .order('urutan');
      if (mounted) {
        setState(() {
          _list = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Reload jenis_audit error: $e');
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
      barrierLabel: 'success',
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _showFormDialog({Map<String, dynamic>? existing}) async {
    final ctrl = TextEditingController(
        text: existing != null ? existing['nama_id']?.toString() ?? '' : '');
    final isEdit = existing != null;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _C.primaryLt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fact_check_outlined,
                        color: _C.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit
                          ? _t('Edit Audit Type', 'Edit Jenis Audit', '编辑审计类型')
                          : _t('Add Audit Type', 'Tambah Jenis Audit', '添加审计类型'),
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _C.primary),
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
                    _t('Audit Type Name (Indonesian)',
                        'Nama Jenis Audit (Indonesia)', '审计类型名称（印尼语）'),
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
                    hintText:
                        _t('e.g. Performance', 'cth. Performa', '例如：绩效'),
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
                                label: _t('Audit Type Name',
                                    'Nama Jenis Audit', '审计类型名称'),
                              ),
                            ],
                          );
                          return;
                        }

                        final isDup = _list.any((j) =>
                            (j['nama_id']?.toString().trim().toLowerCase() ?? '') ==
                                text.toLowerCase() &&
                            (!isEdit ||
                                j['id_jenis_audit'] !=
                                    existing['id_jenis_audit']));
                        if (isDup) {
                          Navigator.pop(ctx);
                          _showSuccessPopup(
                            isSuccess: false,
                            titleEn: 'Duplicate Name',
                            titleId: 'Nama Duplikat',
                            titleZh: '名称重复',
                            msgEn: 'This audit type name already exists.',
                            msgId: 'Nama jenis audit ini sudah ada.',
                            msgZh: '该审计类型名称已存在。',
                          );
                          return;
                        }

                        Navigator.pop(ctx);

                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => _TranslatingTypeDialog(
                                color: _C.primary, lang: widget.lang),
                          );
                        }

                        Map<String, String> t;
                        try {
                          t = await TranslationHelper.instance
                              .translateDescriptionAllLangs(text, 'ID');
                        } catch (e) {
                          debugPrint('Error translating jenis_audit: $e');
                          t = {'id': text, 'en': text, 'zh': text};
                        }

                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        try {
                          if (isEdit) {
                            await _supabase.from('jenis_audit').update({
                              'nama_id': t['id'],
                              'nama_en': t['en'],
                              'nama_zh': t['zh'],
                            }).eq('id_jenis_audit',
                                    existing['id_jenis_audit']);
                          } else {
                            final kodeRaw =
                                text.toLowerCase().replaceAll(' ', '_');
                            final kode = kodeRaw.length > 18
                                ? kodeRaw.substring(0, 18)
                                : kodeRaw;
                            await _supabase.from('jenis_audit').insert({
                              'kode': kode,
                              'nama_id': t['id'],
                              'nama_en': t['en'],
                              'nama_zh': t['zh'],
                              'urutan': _list.length + 1,
                            });
                          }
                          await _reload();
                          widget.onChanged();
                          _showSuccessPopup(
                            isSuccess: true,
                            titleEn: isEdit ? 'Updated!' : 'Saved!',
                            titleId: isEdit ? 'Diperbarui!' : 'Tersimpan!',
                            titleZh: isEdit ? '已更新！' : '已保存！',
                            msgEn: isEdit
                                ? 'Audit type has been updated successfully.'
                                : 'Audit type has been added successfully.',
                            msgId: isEdit
                                ? 'Jenis audit berhasil diperbarui.'
                                : 'Jenis audit berhasil ditambahkan.',
                            msgZh:
                                isEdit ? '审计类型已成功更新。' : '审计类型已成功添加。',
                          );
                        } catch (e) {
                          debugPrint('Error save jenis_audit: $e');
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
                    _t('Delete Audit Type?', 'Hapus Jenis Audit?',
                        '删除审计类型？'),
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textMain),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      'All themes and questions under this type will also be deleted.',
                      'Semua tema dan pertanyaan di bawah jenis ini juga akan terhapus.',
                      '该类型下的所有主题和问题也将被删除。',
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
          .from('jenis_audit')
          .delete()
          .eq('id_jenis_audit', item['id_jenis_audit']);
      await _reload();
      widget.onChanged();
      _showSuccessPopup(
        isSuccess: true,
        titleEn: 'Deleted!',
        titleId: 'Dihapus!',
        titleZh: '已删除！',
        msgEn: 'Audit type has been deleted successfully.',
        msgId: 'Jenis audit berhasil dihapus.',
        msgZh: '审计类型已成功删除。',
      );
    } catch (e) {
      debugPrint('Delete jenis_audit error: $e');
    }
  }

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> result;
    if (_search.trim().isEmpty) {
      result = List.from(_list);
    } else {
      final q = _search.toLowerCase();
      result = _list.where((j) {
        return (j['nama_id'] ?? '').toString().toLowerCase().contains(q) ||
            (j['nama_en'] ?? '').toString().toLowerCase().contains(q) ||
            (j['nama_zh'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }
    result.sort((a, b) => ((a['urutan'] as num?) ?? 0)
        .compareTo((b['urutan'] as num?) ?? 0));
    return result;
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
          _t('Audit Type Settings', 'Pengaturan Jenis Audit', '审计类型设置'),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: () => _showFormDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.primary,
                      _C.primary.withValues(alpha: 0.78)
                    ],
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
                          _t('Add Audit Type', 'Tambah Jenis Audit',
                              '添加审计类型'),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        Text(
                          _t('Tap to add a new audit type',
                              'Ketuk untuk menambah jenis audit baru',
                              '点击以添加新审计类型'),
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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.divider),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                textAlignVertical: TextAlignVertical.center,
                style:
                    GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _t('Search audit type...', 'Cari jenis audit...',
                      '搜索审计类型...'),
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.black38, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                          child: Container(
                            margin: const EdgeInsets.all(9),
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
                    const Icon(Icons.fact_check_outlined,
                        size: 13, color: _C.primary),
                    const SizedBox(width: 5),
                    Text(
                      '${_filtered.length} ${_t('types', 'jenis audit', '个审计类型')}',
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
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _C.primary, strokeWidth: 2))
                : _filtered.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/team_illustration.png',
                                height: 140,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.fact_check_outlined,
                                  size: 80,
                                  color: _C.primary.withValues(alpha: 0.35),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _search.isNotEmpty
                                    ? _t('No matching audit types',
                                        'Jenis Audit Tidak Ditemukan', '未找到匹配的审计类型')
                                    : _t('No audit types found.',
                                        'Belum ada jenis audit.', '暂无审计类型。'),
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _C.primary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _search.isNotEmpty
                                    ? _t(
                                        'Try adjusting your search keyword.',
                                        'Coba ubah kata kunci pencarian.',
                                        '请尝试更改搜索关键词。',
                                      )
                                    : _t(
                                        'Tap "Add Audit Type" above to get started.',
                                        'Ketuk "Tambah Jenis Audit" di atas untuk memulai.',
                                        '点击上方"添加审计类型"开始使用。',
                                      ),
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: _C.textSub),
                                textAlign: TextAlign.center,
                              ),
                              if (_search.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() => _search = '');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _C.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                          color: _C.primary.withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh_rounded,
                                            size: 15, color: _C.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          _t('Clear search', 'Hapus pencarian',
                                              '清除搜索'),
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _C.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        color: _C.primary,
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = _filtered[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AuditTypeDetailScreen(
                                    lang: widget.lang,
                                    item: item,
                                    onEdit: (it) =>
                                        _showFormDialog(existing: it),
                                    onDelete: (it) => _confirmDelete(it),
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                    14, 12, 10, 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _C.divider),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
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
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${item['urutan'] ?? i + 1}',
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
                                      _label(item),
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _showFormDialog(existing: item),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _C.blue
                                            .withValues(alpha: 0.09),
                                        borderRadius:
                                            BorderRadius.circular(9),
                                      ),
                                      child: const Icon(Icons.edit_outlined,
                                          color: _C.blue, size: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            _C.red.withValues(alpha: 0.09),
                                        borderRadius:
                                            BorderRadius.circular(9),
                                      ),
                                      child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: _C.red,
                                          size: 15),
                                    ),
                                  ),
                                ]),
                              ),
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

class _TranslatingTypeDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _TranslatingTypeDialog({required this.color, required this.lang});

  @override
  State<_TranslatingTypeDialog> createState() =>
      _TranslatingTypeDialogState();
}

class _TranslatingTypeDialogState extends State<_TranslatingTypeDialog>
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