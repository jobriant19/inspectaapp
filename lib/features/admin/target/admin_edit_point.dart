import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/translation_service.dart'; // TODO: cek ulang path ini sesuai lokasi file kamu

class AdminEditPointDialog extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? item; // null = tambah baru
  final VoidCallback onSaved;

  const AdminEditPointDialog({
    super.key,
    required this.lang,
    this.item,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String lang,
    Map<String, dynamic>? item,
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

  late final TextEditingController _kodeCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _poinCtrl;
  late final TextEditingController _deskCtrl;
  late final TextEditingController _ketCtrl;
  bool _isAktif = true;
  bool _isBonus = true;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _kodeCtrl = TextEditingController(text: item?['kode'] ?? '');
    _namaCtrl = TextEditingController(text: _localizedField(item, 'nama'));
    _deskCtrl = TextEditingController(text: _localizedField(item, 'deskripsi_template'));
    _ketCtrl = TextEditingController(text: item?['keterangan'] ?? '');
    final rawPoin = (item?['poin'] as int?) ?? 0;
    _isBonus = rawPoin >= 0;
    _poinCtrl = TextEditingController(text: rawPoin.abs().toString());
    _isAktif = item?['is_aktif'] as bool? ?? true;
  }

  String _localizedField(Map<String, dynamic>? item, String base) {
    if (item == null) return '';
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
        'title_add': 'Tambah Konfigurasi Poin',
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
        'saving': 'Menyimpan & menerjemahkan...',
        'required': 'Wajib diisi',
        'poin_invalid': 'Poin harus berupa angka > 0',
      },
      'EN': {
        'title_add': 'Add Point Configuration',
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
        'saving': 'Saving & translating...',
        'required': 'Required',
        'poin_invalid': 'Points must be a number > 0',
      },
      'ZH': {
        'title_add': '添加积分配置',
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
        'saving': '保存并翻译中...',
        'required': '必填',
        'poin_invalid': '积分必须是大于0的数字',
      },
    };
    return txt[widget.lang]?[key] ?? txt['ID']![key] ?? key;
  }

  Widget _fieldLabel(IconData icon, String label, {bool required = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _blue),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: _blue)),
        if (required) ...[
          const SizedBox(width: 3),
          Text('*',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _red)),
        ],
      ],
    );
  }

  Widget _textField(
    TextEditingController ctrl, {
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
          fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: Colors.black26, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: enabled ? const Color(0xFFF8FAFC) : Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _blue, width: 1.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }

  // Tampilan khusus untuk kode — dibedakan seperti "code chip"
  Widget _kodeField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.code_rounded, size: 16, color: Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _kodeCtrl,
              enabled: !_isEdit,
              style: GoogleFonts.robotoMono(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE2E8F0)),
              decoration: InputDecoration(
                hintText: 'contoh_kode_unik',
                hintStyle: GoogleFonts.robotoMono(
                    fontSize: 12.5, color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? _t('required') : null,
            ),
          ),
        ],
      ),
    );
  }

  // Toggle Bonus (hijau) / Penalti (merah)
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
                color: _isBonus ? _green.withValues(alpha:0.12) : Colors.grey.shade50,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(
                    color: _isBonus ? _green : Colors.grey.shade300,
                    width: _isBonus ? 1.4 : 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_rounded,
                      size: 16, color: _isBonus ? _green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(_t('bonus'),
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _isBonus ? _green : Colors.grey.shade600)),
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
                color: !_isBonus ? _red.withValues(alpha:0.12) : Colors.grey.shade50,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(
                    color: !_isBonus ? _red : Colors.grey.shade300,
                    width: !_isBonus ? 1.4 : 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_circle_rounded,
                      size: 16, color: !_isBonus ? _red : Colors.grey),
                  const SizedBox(width: 6),
                  Text(_t('penalti'),
                      style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: !_isBonus ? _red : Colors.grey.shade600)),
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
    setState(() => _isSaving = true);

    final namaSource = _namaCtrl.text.trim();
    final deskSource = _deskCtrl.text.trim();

    Map<String, String> namaAll = {'id': namaSource, 'en': namaSource, 'zh': namaSource};
    Map<String, String> deskAll = {'id': deskSource, 'en': deskSource, 'zh': deskSource};

    try {
      if (namaSource.isNotEmpty) {
        namaAll = await TranslationHelper.instance
            .translateDescriptionAllLangs(namaSource, widget.lang);
      }
      if (deskSource.isNotEmpty) {
        deskAll = await TranslationHelper.instance
            .translateDescriptionAllLangs(deskSource, widget.lang);
      }
    } catch (e) {
      debugPrint('Error translating konfigurasi poin: $e');
    }

    final magnitude = int.tryParse(_poinCtrl.text.trim()) ?? 0;
    final finalPoin = _isBonus ? magnitude : -magnitude;

    final payload = {
      'kode': _kodeCtrl.text.trim(),
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
      if (_isEdit) {
        await Supabase.instance.client
            .from('konfigurasi_poin')
            .update(payload)
            .eq('id', widget.item!['id']);
      } else {
        await Supabase.instance.client.from('konfigurasi_poin').insert(payload);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      debugPrint('Error saving konfigurasi poin: $e');
      if (mounted) setState(() => _isSaving = false);
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
        child: AbsorbPointer(
          absorbing: _isSaving,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER + TOMBOL CLOSE
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_isEdit ? Icons.edit_rounded : Icons.add_rounded, color: _blue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEdit ? _t('title_edit') : _t('title_add'),
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
                        _fieldLabel(Icons.code_rounded, _t('kode'), required: true),
                        const SizedBox(height: 6),
                        _kodeField(),
                        const SizedBox(height: 16),

                        _fieldLabel(Icons.label_rounded, _t('nama'), required: true),
                        const SizedBox(height: 6),
                        _textField(
                          _namaCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? _t('required') : null,
                        ),
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
                        _textField(
                          _deskCtrl,
                          maxLines: 3,
                          validator: (v) => (v == null || v.trim().isEmpty) ? _t('required') : null,
                        ),
                        const SizedBox(height: 16),

                        _fieldLabel(Icons.sticky_note_2_rounded, _t('keterangan')),
                        const SizedBox(height: 6),
                        _textField(_ketCtrl, maxLines: 2),
                        const SizedBox(height: 16),

                        _fieldLabel(Icons.toggle_on_rounded, _t('aktif')),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isAktif ? _t('bonus') == _t('bonus') ? '' : '' : '', // spacer no-op
                              ),
                              Switch(
                                value: _isAktif,
                                activeColor: _green,
                                activeTrackColor: _green.withValues(alpha:0.3),
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
                    BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 6, offset: const Offset(0, -2)),
                  ],
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: _blue),
                          ),
                          const SizedBox(width: 10),
                          Text(_t('saving'), style: GoogleFonts.poppins(fontSize: 13, color: _blue, fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Row(
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
                                shadowColor: _blue.withValues(alpha:0.3),
                              ),
                              child: Text(_t('save'),
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}