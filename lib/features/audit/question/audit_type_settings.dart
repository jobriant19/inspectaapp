import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const primary   = Color(0xFF6366F1);
  static const primaryLt = Color(0xFFEDE9FE);
  static const red       = Color(0xFFEF4444);
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

  Future<String> _translateText(String text, String langPair) async {
    if (text.trim().isEmpty) return text;
    try {
      final normalized = langPair
          .replaceAll('|zh', '|zh-CN')
          .replaceAll('zh|', 'zh-CN|');
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
            t.toUpperCase().startsWith('PLEASE')) { return text; }
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
    bool isTranslating = false;
    final isEdit = existing != null;

    await showDialog(
      context: context,
      barrierDismissible: false,
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
                          color: _C.textMain),
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
                  style: GoogleFonts.poppins(fontSize: 11, color: _C.textSub),
                ),
                const SizedBox(height: 18),
                Text(
                  _t('Audit Type Name (Indonesian)',
                      'Nama Jenis Audit (Indonesia)', '审计类型名称（印尼语）'),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.textSub),
                ),
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
                      onPressed:
                          isTranslating ? null : () => Navigator.pop(ctx),
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
                      onPressed: isTranslating
                          ? null
                          : () async {
                              final text = ctrl.text.trim();
                              if (text.isEmpty) return;
                              setDlg(() => isTranslating = true);
                              try {
                                final isDup = _list.any((j) =>
                                    (j['nama_id']?.toString().trim().toLowerCase() ?? '') ==
                                        text.toLowerCase() &&
                                    (!isEdit || j['id_jenis_audit'] != existing['id_jenis_audit']));
                                if (isDup) {
                                  setDlg(() => isTranslating = false);
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
                                final t = await _translateAll(text);
                                if (isEdit) {
                                  await _supabase
                                      .from('jenis_audit')
                                      .update({
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
                                if (ctx.mounted) Navigator.pop(ctx);
                                await _reload();
                                widget.onChanged();
                                _showSuccessPopup(
                                  isSuccess: true,
                                  titleEn: isEdit ? 'Updated!' : 'Saved!',
                                  titleId:
                                      isEdit ? 'Diperbarui!' : 'Tersimpan!',
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
                                if (ctx.mounted) {
                                  setDlg(() => isTranslating = false);
                                }
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
                      child: isTranslating
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
    result.sort((a, b) =>
        (a['urutan'] as int? ?? 0).compareTo(b['urutan'] as int? ?? 0));
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
              color: _C.textMain, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Audit Type Settings', 'Pengaturan Jenis Audit', '审计类型设置'),
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.textMain),
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
                onChanged: (v) => setState(() => _search = v),
                style:
                    GoogleFonts.poppins(fontSize: 13, color: _C.textMain),
                decoration: InputDecoration(
                  hintText: _t('Search audit type...', 'Cari jenis audit...',
                      '搜索审计类型...'),
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Colors.black38, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
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
                '${_filtered.length} ${_t('types', 'jenis audit', '个审计类型')}',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.black38),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fact_check_outlined,
                                size: 52, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(
                              _t('No audit types found.',
                                  'Belum ada jenis audit.', '暂无审计类型。'),
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: _C.textSub),
                            ),
                          ],
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
                            return Container(
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
                                    borderRadius: BorderRadius.circular(10),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _label(item),
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _C.textMain),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: ${item['nama_id'] ?? '-'}  •  EN: ${item['nama_en'] ?? '-'}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 10, color: _C.textSub),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _showFormDialog(existing: item),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _C.primary
                                          .withValues(alpha: 0.09),
                                      borderRadius:
                                          BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.edit_outlined,
                                        color: _C.primary, size: 15),
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