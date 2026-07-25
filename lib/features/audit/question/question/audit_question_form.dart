import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';
import '../../../user/home/alert/required_field_alert.dart';
import '../theme/audit_theme_settings.dart';

class _C {
  static const primary   = Color(0xFF6366F1);
  static const primaryLt = Color(0xFFEDE9FE);
  static const red       = Color(0xFFEF4444);
  static const textMain  = Color(0xFF1E3A8A);
  static const textSub   = Color(0xFF64748B);
  static const divider   = Color(0xFFE2E8F0);
  static const surface   = Color(0xFFF8FAFC);
}

String _t(String lang, String en, String id, String zh) {
  if (lang == 'EN') return en;
  if (lang == 'ZH') return zh;
  return id;
}

String _temaLabel(String lang, Map<String, dynamic> t) {
  if (lang == 'EN') return t['nama_tema_en']?.toString() ?? '-';
  if (lang == 'ZH') return t['nama_tema_zh']?.toString() ?? '-';
  return t['nama_tema_id']?.toString() ?? '-';
}

String _questionText(String lang, Map<String, dynamic> q) {
  if (lang == 'EN') {
    return q['pertanyaan_en']?.toString() ?? q['pertanyaan']?.toString() ?? '';
  }
  if (lang == 'ZH') {
    return q['pertanyaan_zh']?.toString() ?? q['pertanyaan']?.toString() ?? '';
  }
  return q['pertanyaan']?.toString() ?? '';
}

int _nextUrutanForTema(
  List<Map<String, dynamic>> questions,
  String? temaId,
) {
  final filtered =
      questions.where((q) => q['id_tema']?.toString() == temaId).toList();
  if (filtered.isEmpty) return 1;
  final maxUrutan = filtered.fold<int>(0, (prevMax, q) {
    final u = (q['urutan'] as num?)?.toInt() ?? 0;
    return u > prevMax ? u : prevMax;
  });
  return maxUrutan + 1;
}

void _showResultPopup(
  BuildContext context, {
  required String lang,
  required bool isSuccess,
  required String titleEn,
  required String titleId,
  required String titleZh,
  required String msgEn,
  required String msgId,
  required String msgZh,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'success_q',
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
                  _t(lang, titleEn, titleId, titleZh),
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  _t(lang, msgEn, msgId, msgZh),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _t(lang, 'Close', 'Tutup', '关闭'),
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

Future<void> showAuditQuestionForm(
  BuildContext context, {
  required String lang,
  required String idJenisAudit,
  required List<Map<String, dynamic>> temas,
  required List<Map<String, dynamic>> questions,
  Map<String, dynamic>? existing,
  String? defaultTemaId,
  required VoidCallback onSaved,
  required VoidCallback onThemeChanged,
}) async {
  final supabase = Supabase.instance.client;

  final idCtrl = TextEditingController(
      text: existing == null ? '' : _questionText(lang, existing));
  final activeCtrl = ValueNotifier<bool>(
      existing == null ? true : (existing['is_active'] as bool? ?? true));
  final urutanCtrl = TextEditingController(
      text: existing == null
          ? '${_nextUrutanForTema(questions, defaultTemaId)}'
          : '${existing['urutan']}');
  final selectedTemaIdNotifier = ValueNotifier<String?>(
      existing?['id_tema']?.toString() ?? defaultTemaId);

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER + CLOSE BUTTON (X)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 4),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _C.primaryLt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        color: _C.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existing == null
                              ? _t(lang, 'Add Question', 'Tambah Pertanyaan',
                                  '添加问题')
                              : _t(lang, 'Edit Question', 'Edit Pertanyaan',
                                  '编辑问题'),
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.primary),
                        ),
                        Text(
                          _t(
                            lang,
                            'Auto-translated to EN & ZH',
                            'Otomatis diterjemahkan ke EN & ZH',
                            '自动翻译为英文和中文',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _C.textSub),
                        ),
                      ],
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
              ),
              const Divider(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LABEL THEME
                      Row(children: [
                        const Icon(Icons.topic_rounded,
                            size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Text(_t(lang, 'Theme', 'Tema', '主题'),
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.primary)),
                        Text(' *',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.red)),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(
                          child: ValueListenableBuilder<String?>(
                            valueListenable: selectedTemaIdNotifier,
                            builder: (_, temaId, __) {
                              final selected = temas.firstWhere(
                                (t) => t['id_tema'].toString() == temaId,
                                orElse: () => <String, dynamic>{},
                              );
                              final label = selected.isNotEmpty
                                  ? _temaLabel(lang, selected)
                                  : null;
                              return GestureDetector(
                                onTap: () async {
                                  final result = await showDialog<String>(
                                    context: ctx,
                                    builder: (_) => _ThemePickerDialog(
                                      lang: lang,
                                      temas: temas,
                                      selectedTemaId: temaId,
                                    ),
                                  );
                                  if (result != null) {
                                    selectedTemaIdNotifier.value = result;
                                    if (existing == null) {
                                      urutanCtrl.text =
                                          '${_nextUrutanForTema(questions, result)}';
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _C.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _C.divider),
                                  ),
                                  child: Row(children: [
                                    Expanded(
                                      child: Text(
                                        label ??
                                            _t(lang, 'Select theme',
                                                'Pilih tema', '选择主题'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: label != null
                                              ? _C.textMain
                                              : Colors.black38,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.expand_more_rounded,
                                        size: 18, color: Colors.black38),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AuditThemeSettingsScreen(
                                  lang: lang,
                                  idJenisAudit: idJenisAudit,
                                  onChanged: onThemeChanged,
                                ),
                              ),
                            );
                            setSheet(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _C.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _C.primary.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: _C.primary, size: 18),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // LABEL QUESTION
                      Row(children: [
                        const Icon(Icons.edit_note_rounded,
                            size: 14, color: _C.primary),
                        const SizedBox(width: 6),
                        Text(
                          _t(lang, 'Question (Indonesian)',
                              'Pertanyaan (Indonesia)', '问题（印尼语）'),
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
                      Container(
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.divider),
                        ),
                        child: TextField(
                          controller: idCtrl,
                          maxLines: 3,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _C.textMain),
                          decoration: InputDecoration(
                            hintText: _t(
                              lang,
                              'Enter question in Indonesian...',
                              'Masukkan pertanyaan dalam Bahasa Indonesia...',
                              '请用印尼语输入问题...',
                            ),
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ORDER & ACTIVE
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.sort_rounded,
                                    size: 14, color: _C.primary),
                                const SizedBox(width: 6),
                                Text(_t(lang, 'Order', 'Urutan', '顺序'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _C.primary)),
                              ]),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: _C.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _C.divider),
                                ),
                                child: TextField(
                                  controller: urutanCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _C.textMain),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(_t(lang, 'Active', 'Aktif', '活跃'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _C.primary)),
                            ]),
                            const SizedBox(height: 6),
                            ValueListenableBuilder<bool>(
                              valueListenable: activeCtrl,
                              builder: (_, v, __) => Switch(
                                value: v,
                                onChanged: (val) => activeCtrl.value = val,
                                activeColor: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 22),

                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final text = idCtrl.text.trim();
                            final selectedTemaId = selectedTemaIdNotifier.value;

                            final missing = <MissingFieldItem>[];
                            if (selectedTemaId == null) {
                              missing.add(MissingFieldItem(
                                icon: Icons.topic_rounded,
                                label: _t(lang, 'Theme', 'Tema', '主题'),
                              ));
                            }
                            if (text.isEmpty) {
                              missing.add(MissingFieldItem(
                                icon: Icons.edit_note_rounded,
                                label: _t(lang, 'Question', 'Pertanyaan', '问题'),
                              ));
                            }
                            if (missing.isNotEmpty) {
                              RequiredFieldAlert.show(context,
                                  lang: lang, missingFields: missing);
                              return;
                            }

                            final isDup = questions.any((q) =>
                                q['id_tema']?.toString() == selectedTemaId &&
                                (q['pertanyaan']
                                            ?.toString()
                                            .trim()
                                            .toLowerCase() ??
                                        '') ==
                                    text.toLowerCase() &&
                                (existing == null ||
                                    q['id_question'] != existing['id_question']));
                            if (isDup) {
                              Navigator.pop(ctx);
                              _showResultPopup(
                                context,
                                lang: lang,
                                isSuccess: false,
                                titleEn: 'Duplicate Question',
                                titleId: 'Pertanyaan Duplikat',
                                titleZh: '问题重复',
                                msgEn: 'This question already exists in this theme.',
                                msgId: 'Pertanyaan ini sudah ada pada tema ini.',
                                msgZh: '该主题中已存在此问题。',
                              );
                              return;
                            }

                            Navigator.pop(ctx);

                            if (context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => _TranslatingQuestionDialog(
                                    color: _C.primary, lang: lang),
                              );
                            }

                            Map<String, String> t;
                            try {
                              t = await TranslationHelper.instance
                                  .translateDescriptionAllLangs(text, 'ID');
                            } catch (e) {
                              debugPrint('Error translating question: $e');
                              t = {'id': text, 'en': text, 'zh': text};
                            }

                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }

                            try {
                              final urutan =
                                  int.tryParse(urutanCtrl.text.trim()) ??
                                      _nextUrutanForTema(
                                          questions, selectedTemaId);

                              final payload = {
                                'id_jenis_audit': idJenisAudit,
                                'id_tema': selectedTemaId,
                                'pertanyaan': t['id'],
                                'pertanyaan_en': t['en'],
                                'pertanyaan_zh': t['zh'],
                                'urutan': urutan,
                                'is_active': activeCtrl.value,
                              };
                              final isAdd = existing == null;
                              if (isAdd) {
                                await supabase
                                    .from('audit_question')
                                    .insert(payload);
                              } else {
                                await supabase
                                    .from('audit_question')
                                    .update(payload)
                                    .eq('id_question', existing['id_question']);
                              }

                              onSaved();
                              _showResultPopup(
                                context,
                                lang: lang,
                                isSuccess: true,
                                titleEn:
                                    isAdd ? 'Question Added!' : 'Question Updated!',
                                titleId: isAdd
                                    ? 'Pertanyaan Ditambahkan!'
                                    : 'Pertanyaan Diperbarui!',
                                titleZh: isAdd ? '问题已添加！' : '问题已更新！',
                                msgEn: isAdd
                                    ? 'New question has been saved successfully.'
                                    : 'Question has been updated successfully.',
                                msgId: isAdd
                                    ? 'Pertanyaan baru berhasil disimpan.'
                                    : 'Pertanyaan berhasil diperbarui.',
                                msgZh: isAdd ? '新问题已成功保存。' : '问题已成功更新。',
                              );
                            } catch (e) {
                              debugPrint('Error save question: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _t(lang, 'Save', 'Simpan', '保存'),
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ThemePickerDialog extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> temas;
  final String? selectedTemaId;

  const _ThemePickerDialog({
    required this.lang,
    required this.temas,
    required this.selectedTemaId,
  });

  @override
  State<_ThemePickerDialog> createState() => _ThemePickerDialogState();
}

class _ThemePickerDialogState extends State<_ThemePickerDialog> {
  static const Color _blue = Color(0xFF1D72F3);
  static const int _perPage = 5;
  static const double _listAreaHeight = 268;

  String _search = '';
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.temas.where((t) {
      final label = _temaLabel(widget.lang, t).toLowerCase();
      return label.contains(_search.toLowerCase());
    }).toList();

    final totalPages =
        filtered.isEmpty ? 1 : (filtered.length / _perPage).ceil();
    if (_page > totalPages) _page = totalPages;
    if (_page < 1) _page = 1;
    final startIdx = (_page - 1) * _perPage;
    final endIdx = (startIdx + _perPage).clamp(0, filtered.length);
    final pageItems =
        filtered.isEmpty ? <Map<String, dynamic>>[] : filtered.sublist(startIdx, endIdx);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.topic_rounded, color: _blue, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _t(widget.lang, 'Select Theme', 'Pilih Tema', '选择主题'),
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w700, color: _blue),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 18),

            // SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() {
                    _search = v;
                    _page = 1;
                  }),
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _blue),
                  decoration: InputDecoration(
                    hintText:
                        _t(widget.lang, 'Search theme...', 'Cari tema...', '搜索主题...'),
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
                    prefixIcon: const Icon(Icons.search, size: 18, color: _blue),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // LIST 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: _listAreaHeight,
                child: pageItems.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/team_illustration.png',
                            height: 100,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.category_outlined, size: 56, color: Colors.grey.shade300),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _t(widget.lang, 'No theme found', 'Tema tidak ditemukan', '未找到主题'),
                            style: GoogleFonts.poppins(
                                fontSize: 12.5, color: Colors.black45, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: pageItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t = pageItems[i];
                          final id = t['id_tema'].toString();
                          final isSelected = id == widget.selectedTemaId;
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? _blue.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? _blue : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _temaLabel(widget.lang, t),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? _blue : const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded, color: _blue, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // BOTTOM INDICATOR
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: _ThemePagerIndicator(
                  currentPage: _page,
                  totalPages: totalPages,
                  color: _blue,
                  onPageChanged: (p) => setState(() => _page = p),
                ),
              )
            else
              const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _ThemePagerIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _ThemePagerIndicator({
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
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.25)),
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

class _TranslatingQuestionDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _TranslatingQuestionDialog({required this.color, required this.lang});

  @override
  State<_TranslatingQuestionDialog> createState() =>
      _TranslatingQuestionDialogState();
}

class _TranslatingQuestionDialogState extends State<_TranslatingQuestionDialog>
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