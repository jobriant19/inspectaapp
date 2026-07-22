import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart';

class AdminEditPointDialog extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> item;
  final VoidCallback onSaved;

  const AdminEditPointDialog({
    super.key,
    required this.lang,
    required this.item,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String lang,
    required Map<String, dynamic> item,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AdminEditPointDialog(lang: lang, item: item, onSaved: onSaved),
    );
  }

  @override
  State<AdminEditPointDialog> createState() => _AdminEditPointDialogState();
}

class _AdminEditPointDialogState extends State<AdminEditPointDialog> {
  static const _blue = Color(0xFF1D72F3);
  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);

  late final TextEditingController _namaCtrl;
  late final TextEditingController _poinCtrl;
  late final TextEditingController _deskCtrl;
  late final TextEditingController _ketCtrl;
  bool _isAktif = true;
  bool _isBonus = true;
  final _formKey = GlobalKey<FormState>();

  String get _kode => (widget.item['kode'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _namaCtrl = TextEditingController(text: _localizedField(item, 'nama'));
    _deskCtrl = TextEditingController(text: _localizedField(item, 'deskripsi_template'));
    _ketCtrl = TextEditingController(text: item['keterangan'] ?? '');
    final rawPoin = (item['poin'] as int?) ?? 0;
    _isBonus = rawPoin >= 0;
    _poinCtrl = TextEditingController(text: rawPoin.abs().toString());
    _isAktif = item['is_aktif'] as bool? ?? true;
  }

  String _localizedField(Map<String, dynamic> item, String base) {
    switch (widget.lang) {
      case 'EN':
        return (item['${base}_en'] ?? item[base] ?? '').toString();
      case 'ZH':
        return (item['${base}_zh'] ?? item[base] ?? '').toString();
      default:
        return (item[base] ?? '').toString();
    }
  }

  String _t(String key) {
    const txt = {
      'ID': {
        'title_edit': 'Edit Konfigurasi Poin',
        'kode': 'Kode',
        'nama': 'Nama',
        'poin': 'Jumlah Poin',
        'deskripsi': 'Template Deskripsi',
        'keterangan': 'Keterangan (opsional)',
        'aktif': 'Status Aktif',
        'bonus': 'Bonus (+)',
        'penalti': 'Penalti (-)',
        'save': 'Simpan',
        'cancel': 'Batal',
        'required': 'Wajib diisi',
        'poin_invalid': 'Poin harus berupa angka > 0',
        'translating_title': 'Menerjemahkan...',
        'translating_subtitle': 'Mengubah ke Bahasa Indonesia, Inggris & Mandarin',
      },
      'EN': {
        'title_edit': 'Edit Point Configuration',
        'kode': 'Code',
        'nama': 'Name',
        'poin': 'Point Amount',
        'deskripsi': 'Description Template',
        'keterangan': 'Note (optional)',
        'aktif': 'Active Status',
        'bonus': 'Bonus (+)',
        'penalti': 'Penalty (-)',
        'save': 'Save',
        'cancel': 'Cancel',
        'required': 'Required',
        'poin_invalid': 'Points must be a number > 0',
        'translating_title': 'Translating...',
        'translating_subtitle': 'Converting to Indonesian, English & Mandarin',
      },
      'ZH': {
        'title_edit': '编辑积分配置',
        'kode': '代码',
        'nama': '名称',
        'poin': '积分数值',
        'deskripsi': '描述模板',
        'keterangan': '备注（可选）',
        'aktif': '启用状态',
        'bonus': '奖励 (+)',
        'penalti': '处罚 (-)',
        'save': '保存',
        'cancel': '取消',
        'required': '必填',
        'poin_invalid': '积分必须是大于0的数字',
        'translating_title': '翻译中...',
        'translating_subtitle': '正在转换为印尼语、英语和中文',
      },
    };
    return txt[widget.lang]?[key] ?? txt['ID']![key] ?? key;
  }

  Widget _fieldLabel(IconData icon, String label, {bool required = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _blue),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _blue)),
        if (required) ...[
          const SizedBox(width: 3),
          Text('*', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _red)),
        ],
      ],
    );
  }

  Widget _textField(
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black26, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _kodeField() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.code_rounded, size: 16, color: Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          Text(
            _kode,
            style: GoogleFonts.robotoMono(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
          ),
        ],
      ),
    );
  }

  Widget _bonusPenaltyToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isBonus = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _isBonus ? _green.withValues(alpha: 0.12) : Colors.grey.shade50,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: _isBonus ? _green : Colors.grey.shade300, width: _isBonus ? 1.4 : 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_rounded, size: 16, color: _isBonus ? _green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(_t('bonus'), style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _isBonus ? _green : Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isBonus = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !_isBonus ? _red.withValues(alpha: 0.12) : Colors.grey.shade50,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: !_isBonus ? _red : Colors.grey.shade300, width: !_isBonus ? 1.4 : 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_circle_rounded, size: 16, color: !_isBonus ? _red : Colors.grey),
                  const SizedBox(width: 6),
                  Text(_t('penalti'), style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: !_isBonus ? _red : Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final namaSource = _namaCtrl.text.trim();
    final deskSource = _deskCtrl.text.trim();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _TranslatingDialog(color: _blue, lang: widget.lang),
      );
    }

    Map<String, String> namaAll = {'id': namaSource, 'en': namaSource, 'zh': namaSource};
    Map<String, String> deskAll = {'id': deskSource, 'en': deskSource, 'zh': deskSource};

    try {
      if (namaSource.isNotEmpty) {
        namaAll = await TranslationHelper.instance.translateDescriptionAllLangs(namaSource, widget.lang);
      }
      if (deskSource.isNotEmpty) {
        deskAll = await TranslationHelper.instance.translateDescriptionAllLangs(deskSource, widget.lang);
      }
    } catch (e) {
      debugPrint('Error translating konfigurasi poin: $e');
    }

    final magnitude = int.tryParse(_poinCtrl.text.trim()) ?? 0;
    final finalPoin = _isBonus ? magnitude : -magnitude;

    final payload = {
      'nama': namaAll['id'],
      'nama_en': namaAll['en'],
      'nama_zh': namaAll['zh'],
      'poin': finalPoin,
      'deskripsi_template': deskAll['id'],
      'deskripsi_template_en': deskAll['en'],
      'deskripsi_template_zh': deskAll['zh'],
      'keterangan': _ketCtrl.text.trim().isEmpty ? null : _ketCtrl.text.trim(),
      'is_aktif': _isAktif,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await Supabase.instance.client.from('konfigurasi_poin').update(payload).eq('id', widget.item['id']);

      // CLOSE POPUP TRANSLATING
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      // CLOSE DIALOG EDIT
      if (mounted) Navigator.pop(context);

      widget.onSaved();
    } catch (e) {
      debugPrint('Error saving konfigurasi poin: $e');
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER + CLOSE BUTTON
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_rounded, color: _blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t('title_edit'),
                      style: GoogleFonts.poppins(color: _blue, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
            // BODY
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(Icons.code_rounded, _t('kode')),
                      const SizedBox(height: 6),
                      _kodeField(),
                      const SizedBox(height: 16),

                      _fieldLabel(Icons.label_rounded, _t('nama'), required: true),
                      const SizedBox(height: 6),
                      _textField(_namaCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? _t('required') : null),
                      const SizedBox(height: 16),

                      _fieldLabel(Icons.stars_rounded, _t('poin'), required: true),
                      const SizedBox(height: 6),
                      _bonusPenaltyToggle(),
                      const SizedBox(height: 8),
                      _textField(
                        _poinCtrl,
                        keyboardType: TextInputType.number,
                        hint: '0',
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return _t('poin_invalid');
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _fieldLabel(Icons.notes_rounded, _t('deskripsi'), required: true),
                      const SizedBox(height: 6),
                      _textField(_deskCtrl, maxLines: 3, validator: (v) => (v == null || v.trim().isEmpty) ? _t('required') : null),
                      const SizedBox(height: 16),

                      _fieldLabel(Icons.sticky_note_2_rounded, _t('keterangan')),
                      const SizedBox(height: 6),
                      _textField(_ketCtrl, maxLines: 2),
                      const SizedBox(height: 16),

                      _fieldLabel(Icons.toggle_on_rounded, _t('aktif')),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isAktif ? _t('bonus').replaceAll(RegExp(r'[^A-Za-z ]'), '').trim() : '',
                              style: const TextStyle(fontSize: 0),
                            ),
                            Switch(
                              value: _isAktif,
                              activeThumbColor: _green,
                              activeTrackColor: _green.withValues(alpha: 0.3),
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade200,
                              onChanged: (v) => setState(() => _isAktif = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // FOOTER
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_t('cancel'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: _blue.withValues(alpha: 0.3),
                      ),
                      child: Text(_t('save'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslatingDialog extends StatefulWidget {
  final Color color;
  final String lang;
  const _TranslatingDialog({required this.color, required this.lang});

  @override
  State<_TranslatingDialog> createState() => _TranslatingDialogState();
}

class _TranslatingDialogState extends State<_TranslatingDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
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
                    BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _title,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4),
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