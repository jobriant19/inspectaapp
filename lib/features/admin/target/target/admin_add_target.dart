import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'admin_target_5r_screen.dart';
import 'admin_target_pick_date.dart';
import '../../../user/home/alert/required_field_alert.dart';

const _kGreen = Color(0xFF059669);
const _kBlue = Color(0xFF1D72F3);
const _kSky = Color(0xFF0EA5E9);
const _kPurple = Color(0xFF7C3AED);
const _kPink = Color(0xFFDB2777);
const _kAmber = Color(0xFFD97706);
const _kTeal = Color(0xFF0D9488);

// ── Callback typedefs — menghubungkan ke logic milik admin_target_5r_screen.dart ──
typedef DuplicateFinder = Map<String, dynamic>? Function({
  required TargetType type,
  DateTime? date,
  int? excludeId,
});

typedef DuplicateWarningShower = Future<void> Function(
    BuildContext ctx, Map<String, dynamic> existing);

typedef ConfirmDialogShower = Future<bool?> Function(
  BuildContext ctx, {
  required bool isEdit,
  required TargetType type,
  DateTime? monthlyEffectiveDate,
  DateTime? dateValue,
  String? offDayLabel,
  int a,
  int i,
  int l,
  int u,
  int s,
  int ar,
  int aSelesai,
  int iSelesai,
});

typedef TargetSaver = Future<void> Function({
  required bool isEdit,
  int? id,
  required TargetType type,
  DateTime? effectiveDate,
  DateTime? date,
  int a,
  int i,
  int l,
  int u,
  int s,
  int ar,
  int aSelesai,
  int iSelesai,
  String? label,
  String? ket,
  required bool aktif,
});

class AdminAddTargetDialog extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? item;
  final DuplicateFinder findDuplicate;
  final DuplicateWarningShower showDuplicateWarning;
  final ConfirmDialogShower confirmDialog;
  final TargetSaver onSave;

  const AdminAddTargetDialog({
    super.key,
    required this.lang,
    this.item,
    required this.findDuplicate,
    required this.showDuplicateWarning,
    required this.confirmDialog,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String lang,
    Map<String, dynamic>? item,
    required DuplicateFinder findDuplicate,
    required DuplicateWarningShower showDuplicateWarning,
    required ConfirmDialogShower confirmDialog,
    required TargetSaver onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AdminAddTargetDialog(
        lang: lang,
        item: item,
        findDuplicate: findDuplicate,
        showDuplicateWarning: showDuplicateWarning,
        confirmDialog: confirmDialog,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AdminAddTargetDialog> createState() => _AdminAddTargetDialogState();
}

class _AdminAddTargetDialogState extends State<AdminAddTargetDialog> {
  bool get _isEdit => widget.item != null;

  late TargetType _selType;
  late DateTime _monthlyEffectiveDate;
  late DateTime _selDate;

  late final TextEditingController _cA;
  late final TextEditingController _cI;
  late final TextEditingController _cL;
  late final TextEditingController _cU;
  late final TextEditingController _cS;
  late final TextEditingController _cAr;
  late final TextEditingController _cASelesai;
  late final TextEditingController _cISelesai;
  late final TextEditingController _cLbl;
  late final TextEditingController _cKet;
  final _formKey = GlobalKey<FormState>();

  String get _locale =>
      widget.lang == 'ID' ? 'id_ID' : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';

  static const _txt = <String, Map<String, String>>{
    'ID': {
      'add': 'Tambah Target',
      'edit': 'Edit Target',
      'type': 'Tipe',
      'monthly': 'Bulanan',
      'daily': 'Harian Spesifik',
      'offDay': 'Hari Libur',
      'date': 'Tanggal',
      'label': 'Label Hari Libur',
      'a': 'Target Anggota',
      'i': 'Target Inspeksi',
      'l': 'Skor Lokasi',
      'u': 'Skor Unit',
      's': 'Skor Subunit',
      'ar': 'Skor Area',
      'a_selesai': 'Target Anggota Selesai',
      'i_selesai': 'Target Inspeksi Selesai',
      'l_name': 'Lokasi',
      'u_name': 'Unit',
      's_name': 'Subunit',
      'ar_name': 'Area',
      'ket': 'Keterangan (opsional)',
      'ket_hint': 'Tulis catatan tambahan di sini...',
      'save': 'Simpan',
      'cancel': 'Batal',
      'req': 'Wajib diisi',
      'num': 'Harus angka ≥ 0',
      'holiday_info': 'Pada tanggal ini seluruh target progres dan audit otomatis dinonaktifkan, sehingga tidak ada penghitungan pencapaian.',
      'no_target_title': 'Tidak Ada Target',
      'override': 'Override target bulanan pada tanggal ini',
      'progress_section': 'Target Progres',
      'audit_section': 'Skor Target Audit',
      'audit_section_sub': 'Lokasi, Unit, Subunit & Area',
      'change': 'Ubah',
      'eff_from': 'Mulai Berlaku',
      'eff_note_edit': 'Tanggal berlaku tidak dapat diubah, hanya nilai target.',
      'eff_note_new': 'Target ini otomatis aktif tanggal 1 bulan depan dan menggantikan target bulanan sebelumnya.',
    },
    'EN': {
      'add': 'Add Target',
      'edit': 'Edit Target',
      'type': 'Type',
      'monthly': 'Monthly',
      'daily': 'Specific Daily',
      'offDay': 'Holiday',
      'date': 'Date',
      'label': 'Holiday Label',
      'a': 'Member Target',
      'i': 'Inspection Target',
      'l': 'Location Score',
      'u': 'Unit Score',
      's': 'Sub-unit Score',
      'ar': 'Area Score',
      'a_selesai': 'Member Completion Target',
      'i_selesai': 'Inspection Completion Target',
      'l_name': 'Location',
      'u_name': 'Unit',
      's_name': 'Sub-unit',
      'ar_name': 'Area',
      'ket': 'Note (optional)',
      'ket_hint': 'Write additional notes here...',
      'save': 'Save',
      'cancel': 'Cancel',
      'req': 'Required',
      'num': 'Must be a number ≥ 0',
      'holiday_info': 'On this date, all progress and audit targets are automatically disabled, so no achievement is calculated.',
      'no_target_title': 'No Target',
      'override': 'Overrides monthly target on this date',
      'progress_section': 'Progress Target',
      'audit_section': 'Audit Target Score',
      'audit_section_sub': 'Location, Unit, Sub-unit & Area',
      'change': 'Change',
      'eff_from': 'Effective From',
      'eff_note_edit': 'Effective date cannot be changed, only the target values.',
      'eff_note_new': 'This target activates automatically on the 1st of next month, replacing the previous monthly target.',
    },
    'ZH': {
      'add': '添加目标',
      'edit': '编辑目标',
      'type': '类型',
      'monthly': '月度',
      'daily': '特定日期',
      'offDay': '节假日',
      'date': '日期',
      'label': '节假日标签',
      'a': '成员目标',
      'i': '检查目标',
      'l': '位置分数',
      'u': '单元分数',
      's': '子单元分数',
      'ar': '区域分数',
      'a_selesai': '成员完成目标',
      'i_selesai': '检查完成目标',
      'l_name': '位置',
      'u_name': '单元',
      's_name': '子单元',
      'ar_name': '区域',
      'ket': '备注（可选）',
      'ket_hint': '在此输入备注...',
      'save': '保存',
      'cancel': '取消',
      'req': '必填',
      'num': '必须是 ≥ 0 的数字',
      'holiday_info': '此日期的所有进度和审核目标将自动停用，因此不计算达成率。',
      'no_target_title': '无目标',
      'override': '覆盖此日期的月度目标',
      'progress_section': '进度目标',
      'audit_section': '审核目标分数',
      'audit_section_sub': '位置、单元、子单元和区域',
      'change': '更改',
      'eff_from': '生效日期',
      'eff_note_edit': '生效日期无法更改，只能修改目标值。',
      'eff_note_new': '此目标将于下月1日自动生效，并取代之前的每月目标。',
    },
  };

  String _t(String k) => _txt[widget.lang]?[k] ?? _txt['ID']![k] ?? k;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _selType = _isEdit
        ? TargetTypeX.from(item!['type'] as String? ?? 'monthly')
        : TargetType.monthly;
    _monthlyEffectiveDate = (_isEdit &&
            item!['effective_date'] != null &&
            DateTime.tryParse(item['effective_date'] as String) != null)
        ? DateTime.tryParse(item['effective_date'] as String)!
        : DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
    _selDate = item?['specific_date'] != null
        ? (DateTime.tryParse(item!['specific_date'] as String) ?? DateTime.now())
        : DateTime.now();

    _cA = TextEditingController(text: _isEdit ? '${item?['target_anggota'] ?? 2}' : '');
    _cI = TextEditingController(text: _isEdit ? '${item?['target_inspeksi'] ?? 2}' : '');
    _cL = TextEditingController(text: _isEdit ? '${item?['target_lokasi'] ?? 5}' : '');
    _cU = TextEditingController(text: _isEdit ? '${item?['target_unit'] ?? 5}' : '');
    _cS = TextEditingController(text: _isEdit ? '${item?['target_subunit'] ?? 5}' : '');
    _cAr = TextEditingController(text: _isEdit ? '${item?['target_area'] ?? 5}' : '');
    _cASelesai = TextEditingController(text: _isEdit ? '${item?['target_anggota_selesai'] ?? 2}' : '');
    _cISelesai = TextEditingController(text: _isEdit ? '${item?['target_inspeksi_selesai'] ?? 2}' : '');
    _cLbl = TextEditingController(text: item?['off_day_label'] as String? ?? '');
    _cKet = TextEditingController(text: item?['keterangan'] as String? ?? '');
  }

  @override
  void dispose() {
    _cA.dispose();
    _cI.dispose();
    _cL.dispose();
    _cU.dispose();
    _cS.dispose();
    _cAr.dispose();
    _cASelesai.dispose();
    _cISelesai.dispose();
    _cLbl.dispose();
    _cKet.dispose();
    super.dispose();
  }

  // ── LABEL DENGAN ICON (w700) ────────────────────────────────────────────
  Widget _fieldLabel(IconData icon, String label, Color color, {bool required = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
                ),
                if (required)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── FIELD TANPA ICON (isi Poppins hitam w600) ───────────────────────────
  Widget _plainField(
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
    Color accent = _kBlue,
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
        fillColor: accent.withValues(alpha: 0.045),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent.withValues(alpha: 0.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent.withValues(alpha: 0.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 1.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }

  String? _numValidator(String? v) {
    final n = int.tryParse((v ?? '').trim());
    return (n == null || n < 0) ? _t('num') : null;
  }

  Widget _targetTile({
    required IconData icon,
    required String label,
    required Color color,
    required TextEditingController ctrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(icon, label, color, required: true),
        const SizedBox(height: 6),
        _plainField(ctrl, keyboardType: TextInputType.number, hint: '0', accent: color, validator: _numValidator),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.7))),
            ],
          ),
        ),
      ],
    );
  }

  // ── PROGRESS TARGET — SUSUN VERTIKAL, WARNA TARGET vs COMPLETION DIBEDAKAN ──
  Widget _progressSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.trending_up_rounded, _t('progress_section'),
              widget.lang == 'ID' ? 'Anggota & Inspeksi' : widget.lang == 'ZH' ? '成员与检查' : 'Members & Inspections', _kTeal),
          const SizedBox(height: 14),
          _targetTile(icon: Icons.people_rounded, label: _t('a'), color: _kBlue, ctrl: _cA),
          const SizedBox(height: 14),
          _targetTile(icon: Icons.check_circle_rounded, label: _t('a_selesai'), color: _kGreen, ctrl: _cASelesai),
          const SizedBox(height: 14),
          _targetTile(icon: Icons.search_rounded, label: _t('i'), color: _kPurple, ctrl: _cI),
          const SizedBox(height: 14),
          _targetTile(icon: Icons.check_circle_rounded, label: _t('i_selesai'), color: _kGreen, ctrl: _cISelesai),
        ],
      ),
    );
  }

  // ── AUDIT TARGET — setiap kategori punya 1 nilai (kolom database tetap sama) ──
  Widget _auditCategoryBlock({
    required IconData icon,
    required String scoreLabel,
    required String categoryName,
    required Color color,
    required TextEditingController ctrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(icon, categoryName, color, required: true),
          const SizedBox(height: 8),
          _plainField(ctrl, keyboardType: TextInputType.number, hint: '0', accent: color, validator: _numValidator),
        ],
      ),
    );
  }

  Widget _tileGrid(List<Widget> tiles) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 14,
          children: tiles.map((t) => SizedBox(width: w, child: t)).toList(),
        );
      },
    );
  }

  Widget _auditSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.fact_check_rounded, _t('audit_section'), _t('audit_section_sub'), _kBlue),
          const SizedBox(height: 12),
          _tileGrid([
            _auditCategoryBlock(icon: Icons.location_city_rounded, scoreLabel: _t('l'), categoryName: _t('l_name'), color: _kBlue, ctrl: _cL),
            _auditCategoryBlock(icon: Icons.apartment_rounded, scoreLabel: _t('u'), categoryName: _t('u_name'), color: _kSky, ctrl: _cU),
            _auditCategoryBlock(icon: Icons.domain_rounded, scoreLabel: _t('s'), categoryName: _t('s_name'), color: _kPurple, ctrl: _cS),
            _auditCategoryBlock(icon: Icons.place_rounded, scoreLabel: _t('ar'), categoryName: _t('ar_name'), color: _kPink, ctrl: _cAr),
          ]),
        ],
      ),
    );
  }

  Widget _typeSelector() {
    final types = [
      (TargetType.monthly, _t('monthly'), Icons.calendar_month_rounded, _kGreen),
      (TargetType.daily, _t('daily'), Icons.event_rounded, _kBlue),
      (TargetType.offDay, _t('offDay'), Icons.beach_access_rounded, _kAmber),
    ];
    return Row(
      children: types.map((t) {
        final sel = _selType == t.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: t.$1 != TargetType.offDay ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() {
                _selType = t.$1;
                if (t.$1 != TargetType.monthly) _selDate = DateTime.now();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? t.$4 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? t.$4 : Colors.grey.shade200, width: sel ? 1.5 : 1),
                  boxShadow: sel ? [BoxShadow(color: t.$4.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3, size: 18, color: sel ? Colors.white : t.$4),
                    const SizedBox(height: 4),
                    Text(t.$2,
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.grey.shade600),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── BADGE TIPE — TAMPIL DI HEADER SAAT EDIT (TIPE TIDAK BISA DIUBAH) ─────
  Widget _typeBadge() {
    late final IconData icon;
    late final Color color;
    late final String label;
    switch (_selType) {
      case TargetType.monthly:
        icon = Icons.calendar_month_rounded;
        color = _kGreen;
        label = _t('monthly');
        break;
      case TargetType.daily:
        icon = Icons.event_rounded;
        color = _kBlue;
        label = _t('daily');
        break;
      case TargetType.offDay:
        icon = Icons.beach_access_rounded;
        color = _kAmber;
        label = _t('offDay');
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _datePickerTile() {
    return GestureDetector(
      onTap: () async {
        final p = await showAdminTargetDatePicker(context: context, lang: widget.lang, initialDate: _selDate);
        if (p != null) setState(() => _selDate = p);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBlue.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [BoxShadow(color: _kBlue.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.calendar_today_rounded, size: 16, color: _kBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('date'), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black45)),
                  Text(DateFormat('d MMMM yyyy', _locale).format(_selDate),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_calendar_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(_t('change'), style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EFFECTIVE FROM — LEBIH JELAS, WARNA BIRU 0xFF1D72F3 ──────────────────
  Widget _effectiveFromBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBlue.withValues(alpha: 0.10), _kBlue.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBlue.withValues(alpha: 0.35), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _kBlue.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('eff_from').toUpperCase(),
                        style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: _kBlue, letterSpacing: 0.6)),
                    const SizedBox(height: 4),
                    Text(DateFormat('d MMMM yyyy', _locale).format(_monthlyEffectiveDate),
                        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBlue.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 13, color: _kBlue.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isEdit ? _t('eff_note_edit') : _t('eff_note_new'),
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── INFO "TIDAK ADA TARGET PADA HARI LIBUR" — DIPERBAGUS ─────────────────
  Widget _holidayInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kAmber.withValues(alpha: 0.10), _kAmber.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAmber.withValues(alpha: 0.35), width: 1.3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kAmber,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _kAmber.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.beach_access_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('no_target_title'),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF92400E))),
                const SizedBox(height: 4),
                Text(_t('holiday_info'),
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFB45309), height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── VALIDASI WAJIB ISI VIA RequiredFieldAlert ─────────────────────────────
  List<MissingFieldItem> _collectMissingFields() {
    final missing = <MissingFieldItem>[];

    if (_selType == TargetType.offDay) {
      if (_cLbl.text.trim().isEmpty) {
        missing.add(MissingFieldItem(icon: Icons.beach_access_rounded, label: _t('label')));
      }
      return missing;
    }

    void check(TextEditingController c, IconData icon, String label) {
      if (c.text.trim().isEmpty) missing.add(MissingFieldItem(icon: icon, label: label));
    }

    check(_cA, Icons.people_rounded, _t('a'));
    check(_cASelesai, Icons.check_circle_rounded, _t('a_selesai'));
    check(_cI, Icons.search_rounded, _t('i'));
    check(_cISelesai, Icons.check_circle_outline_rounded, _t('i_selesai'));
    check(_cL, Icons.location_city_rounded, _t('l'));
    check(_cU, Icons.apartment_rounded, _t('u'));
    check(_cS, Icons.domain_rounded, _t('s'));
    check(_cAr, Icons.place_rounded, _t('ar'));

    return missing;
  }

  Future<void> _onSavePressed() async {
    final missing = _collectMissingFields();
    if (missing.isNotEmpty) {
      await RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final dup = widget.findDuplicate(
      type: _selType,
      date: _selType == TargetType.monthly ? _monthlyEffectiveDate : _selDate,
      excludeId: _isEdit ? widget.item!['id'] as int? : null,
    );
    if (dup != null) {
      await widget.showDuplicateWarning(context, dup);
      return;
    }

    final confirmed = await widget.confirmDialog(
      context,
      isEdit: _isEdit,
      type: _selType,
      monthlyEffectiveDate: _monthlyEffectiveDate,
      dateValue: _selType != TargetType.monthly ? _selDate : null,
      offDayLabel: _cLbl.text.trim(),
      a: int.tryParse(_cA.text) ?? 0,
      i: int.tryParse(_cI.text) ?? 0,
      l: int.tryParse(_cL.text) ?? 0,
      u: int.tryParse(_cU.text) ?? 0,
      s: int.tryParse(_cS.text) ?? 0,
      ar: int.tryParse(_cAr.text) ?? 0,
      aSelesai: int.tryParse(_cASelesai.text) ?? 0,
      iSelesai: int.tryParse(_cISelesai.text) ?? 0,
    );
    if (confirmed != true) return;

    if (mounted) Navigator.pop(context);

    await widget.onSave(
      isEdit: _isEdit,
      id: widget.item?['id'] as int?,
      type: _selType,
      effectiveDate: _selType == TargetType.monthly ? _monthlyEffectiveDate : null,
      date: _selType != TargetType.monthly ? _selDate : null,
      a: int.tryParse(_cA.text) ?? 0,
      i: int.tryParse(_cI.text) ?? 0,
      l: int.tryParse(_cL.text) ?? 0,
      u: int.tryParse(_cU.text) ?? 0,
      s: int.tryParse(_cS.text) ?? 0,
      ar: int.tryParse(_cAr.text) ?? 0,
      aSelesai: int.tryParse(_cASelesai.text) ?? 0,
      iSelesai: int.tryParse(_cISelesai.text) ?? 0,
      label: _cLbl.text.trim().isEmpty ? null : _cLbl.text.trim(),
      ket: _cKet.text.trim().isEmpty ? null : _cKet.text.trim(),
      aktif: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER + CLOSE
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_isEdit ? Icons.edit_rounded : Icons.add_rounded, color: _kGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(_isEdit ? _t('edit') : _t('add'),
                      style: GoogleFonts.poppins(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 16)),
                  if (_isEdit)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 4),
                          child: _typeBadge(),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
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
                      if (!_isEdit) ...[
                        _fieldLabel(Icons.category_rounded, _t('type'), _kGreen),
                        const SizedBox(height: 8),
                        _typeSelector(),
                        const SizedBox(height: 18),
                      ],

                      // MONTHLY
                      if (_selType == TargetType.monthly) ...[
                        _effectiveFromBanner(),
                        const SizedBox(height: 16),
                        _progressSection(),
                        const SizedBox(height: 14),
                        _auditSection(),
                      ],

                      // DAILY / OFF DAY
                      if (_selType != TargetType.monthly) ...[
                        _datePickerTile(),
                        const SizedBox(height: 16),
                        if (_selType == TargetType.offDay) ...[
                          _fieldLabel(Icons.beach_access_rounded, _t('label'), _kAmber, required: true),
                          const SizedBox(height: 6),
                          _plainField(
                            _cLbl,
                            accent: _kAmber,
                            validator: (v) => (v == null || v.trim().isEmpty) ? _t('req') : null,
                          ),
                          const SizedBox(height: 12),
                          _holidayInfoBanner(),
                        ],
                        if (_selType == TargetType.daily) ...[
                          _progressSection(),
                          const SizedBox(height: 14),
                          _auditSection(),
                          const SizedBox(height: 6),
                          Text(_t('override'),
                              style: GoogleFonts.poppins(fontSize: 10, color: _kBlue, fontStyle: FontStyle.italic)),
                        ],
                      ],

                      const SizedBox(height: 16),
                      _fieldLabel(Icons.sticky_note_2_rounded, _t('ket'), _kGreen),
                      const SizedBox(height: 6),
                      _plainField(_cKet, maxLines: 2, accent: _kGreen, hint: _t('ket_hint')),
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, -2))],
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
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                      label: Text(_t('save'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                      onPressed: _onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: _kGreen.withValues(alpha: 0.3),
                      ),
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