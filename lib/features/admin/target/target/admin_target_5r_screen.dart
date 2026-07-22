import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'admin_add_target.dart';

const _kGreen = Color(0xFF059669);
const _kBlue = Color(0xFF1D72F3);
const _kSky = Color(0xFF0EA5E9);
const _kPurple = Color(0xFF7C3AED);
const _kPink = Color(0xFFDB2777);

enum TargetType { monthly, daily, offDay }

extension TargetTypeX on TargetType {
  String get db => ['monthly', 'daily_specific', 'off_day'][index];

  static TargetType from(String s) => s == 'daily_specific'
      ? TargetType.daily
      : s == 'off_day'
          ? TargetType.offDay
          : TargetType.monthly;
}

enum _TargetStatus { active, inactive, upcoming, superseded }

class AdminTarget5rScreen extends StatefulWidget {
  final String lang;
  const AdminTarget5rScreen({super.key, required this.lang});

  @override
  State<AdminTarget5rScreen> createState() => _State();
}

class _State extends State<AdminTarget5rScreen> {
  List<Map<String, dynamic>> _all = [], _view = [];
  bool _loading = true;
  TargetType? _fType;
  _TargetStatus? _fStatus;
  String _q = '';
  int? _activeMonthlyId;
  int _currentPage = 1;
  static const int _perPage = 10;

  static const _txt = <String, Map<String, String>>{
    'ID': {
      'title': 'Target Temuan 5R',
      'add': 'Tambah Target',
      'edit': 'Edit Target',
      'type': 'Tipe',
      'monthly': 'Bulanan',
      'daily': 'Harian Spesifik',
      'offDay': 'Hari Libur',
      'month': 'Bulan',
      'year': 'Tahun',
      'date': 'Tanggal',
      'label': 'Label Hari Libur',
      'a': 'Target Anggota',
      'i': 'Target Inspeksi',
      'a_selesai': 'Anggota Selesai',
      'i_selesai': 'Inspeksi Selesai',
      'l': 'Target Lokasi',
      'u': 'Target Unit',
      's': 'Target Subunit',
      'ar': 'Target Area',
      'ket': 'Keterangan (opsional)',
      'aktif': 'Aktif',
      'save': 'Simpan',
      'cancel': 'Batal',
      'delete': 'Hapus',
      'del_q': 'Hapus target ini?',
      'del_d': 'Tindakan ini tidak dapat dibatalkan.',
      'req': 'Wajib diisi',
      'num': 'Harus angka ≥ 0',
      'empty': 'Belum ada data target.',
      'alltype': 'Semua Tipe',
      'active': 'Aktif',
      'inactive': 'Nonaktif',
      'ok_add': 'Target berhasil ditambahkan.',
      'ok_edit': 'Target berhasil diperbarui.',
      'ok_del': 'Target berhasil dihapus.',
      'err': 'Terjadi kesalahan.',
      'search': 'Cari...',
      'override': 'Override target bulanan pada tanggal ini',
      'holiday_info': 'Tidak ada target pada hari libur ini',
      'weekend_note': 'Sabtu & Minggu otomatis tidak ada target',
    },
    'EN': {
      'title': '5R Finding Target',
      'add': 'Add Target',
      'edit': 'Edit Target',
      'type': 'Type',
      'monthly': 'Monthly',
      'daily': 'Specific Daily',
      'offDay': 'Holiday',
      'month': 'Month',
      'year': 'Year',
      'date': 'Date',
      'label': 'Holiday Label',
      'a': 'Member Target',
      'i': 'Inspection Target',
      'a_selesai': 'Member Completion',
      'i_selesai': 'Inspection Completion',
      'l': 'Location Target',
      'u': 'Unit Target',
      's': 'Sub-unit Target',
      'ar': 'Area Target',
      'ket': 'Note (optional)',
      'aktif': 'Active',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'del_q': 'Delete this target?',
      'del_d': 'This action cannot be undone.',
      'req': 'Required',
      'num': 'Must be a number ≥ 0',
      'empty': 'No target data yet.',
      'alltype': 'All Types',
      'active': 'Active',
      'inactive': 'Inactive',
      'ok_add': 'Target added.',
      'ok_edit': 'Target updated.',
      'ok_del': 'Target deleted.',
      'err': 'An error occurred.',
      'search': 'Search...',
      'override': 'Overrides monthly target on this date',
      'holiday_info': 'No target on this holiday',
      'weekend_note': 'Sat & Sun automatically have no target',
    },
    'ZH': {
      'title': '5R 发现目标',
      'add': '添加目标',
      'edit': '编辑目标',
      'type': '类型',
      'monthly': '月度',
      'daily': '特定日期',
      'offDay': '节假日',
      'month': '月份',
      'year': '年份',
      'date': '日期',
      'label': '节假日标签',
      'a': '成员目标',
      'i': '检查目标',
      'a_selesai': '成员完成',
      'i_selesai': '检查完成',
      'l': '位置目标',
      'u': '单元目标',
      's': '子单元目标',
      'ar': '区域目标',
      'ket': '备注（可选）',
      'aktif': '启用',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'del_q': '删除此目标？',
      'del_d': '此操作无法撤销。',
      'req': '必填',
      'num': '必须是 ≥ 0 的数字',
      'empty': '暂无目标数据。',
      'alltype': '所有类型',
      'active': '启用',
      'inactive': '禁用',
      'ok_add': '目标添加成功。',
      'ok_edit': '目标更新成功。',
      'ok_del': '目标删除成功。',
      'err': '发生错误。',
      'search': '搜索...',
      'override': '覆盖此日期的月度目标',
      'holiday_info': '节假日无目标',
      'weekend_note': '周六周日自动无目标',
    },
  };

  String _t(String k) => _txt[widget.lang]?[k] ?? _txt['ID']![k] ?? k;

  String get _locale =>
      widget.lang == 'ID' ? 'id_ID' : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final d = await Supabase.instance.client
          .from('target_5r_findings')
          .select()
          .order('type')
          .order('effective_date', ascending: false)
          .order('specific_date', ascending: false);
      if (!mounted) return;
      _all = List<Map<String, dynamic>>.from(d);
      _computeActiveMonthly();
      _filter();
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(_t('err'), err: true);
    }
  }

  void _computeActiveMonthly() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    int? activeId;
    DateTime? bestDate;
    for (final r in _all) {
      if (r['type'] != 'monthly') continue;
      final eff = DateTime.tryParse(r['effective_date']?.toString() ?? '');
      if (eff == null) continue;
      if (eff.isAfter(todayOnly)) continue;
      if (bestDate == null || eff.isAfter(bestDate)) {
        bestDate = eff;
        activeId = r['id'] as int?;
      }
    }
    _activeMonthlyId = activeId;
  }

  _TargetStatus _statusOf(Map<String, dynamic> item) {
    final type = TargetTypeX.from(item['type'] as String? ?? 'monthly');
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (type == TargetType.monthly) {
      if (item['id'] == _activeMonthlyId) return _TargetStatus.active;
      final eff = DateTime.tryParse(item['effective_date']?.toString() ?? '');
      if (eff != null && eff.isAfter(todayOnly)) return _TargetStatus.upcoming;
      return _TargetStatus.superseded;
    }

    final specific = DateTime.tryParse(item['specific_date']?.toString() ?? '');
    final aktifFlag = item['is_aktif'] as bool? ?? true;
    if (specific != null && specific.isBefore(todayOnly)) {
      return _TargetStatus.inactive;
    }
    if (!aktifFlag) return _TargetStatus.inactive;
    if (specific != null && specific.isAfter(todayOnly)) {
      return _TargetStatus.upcoming;
    }
    return _TargetStatus.active;
  }

  String _statusLabel(_TargetStatus st) {
    switch (st) {
      case _TargetStatus.active:
        return widget.lang == 'EN' ? 'Active' : widget.lang == 'ZH' ? '启用' : 'Aktif';
      case _TargetStatus.inactive:
        return widget.lang == 'EN' ? 'Inactive' : widget.lang == 'ZH' ? '禁用' : 'Nonaktif';
      case _TargetStatus.upcoming:
        return widget.lang == 'EN' ? 'Upcoming' : widget.lang == 'ZH' ? '即将生效' : 'Akan Datang';
      case _TargetStatus.superseded:
        return widget.lang == 'EN' ? 'Superseded' : widget.lang == 'ZH' ? '已被取代' : 'Sudah Digantikan';
    }
  }

  (Color, Color, Color) _statusColors(_TargetStatus st) {
    switch (st) {
      case _TargetStatus.active:
        return (const Color(0xFF22C55E).withValues(alpha: 0.12), const Color(0xFF22C55E).withValues(alpha: 0.5), const Color(0xFF16A34A));
      case _TargetStatus.upcoming:
        return (_kBlue.withValues(alpha: 0.12), _kBlue.withValues(alpha: 0.5), _kBlue);
      case _TargetStatus.superseded:
        return (Colors.grey.withValues(alpha: 0.1), Colors.grey.withValues(alpha: 0.3), Colors.grey.shade600);
      case _TargetStatus.inactive:
        return (Colors.red.withValues(alpha: 0.08), Colors.red.withValues(alpha: 0.3), Colors.red.shade400);
    }
  }

  IconData _statusIcon(_TargetStatus st) {
    switch (st) {
      case _TargetStatus.active:
        return Icons.check_circle_rounded;
      case _TargetStatus.inactive:
        return Icons.pause_circle_rounded;
      case _TargetStatus.upcoming:
        return Icons.schedule_rounded;
      case _TargetStatus.superseded:
        return Icons.history_rounded;
    }
  }

  String _searchableText(Map<String, dynamic> r) {
    final type = TargetTypeX.from(r['type'] as String? ?? 'monthly');
    final typeLabel = type == TargetType.monthly
        ? _t('monthly')
        : type == TargetType.daily
            ? _t('daily')
            : _t('offDay');

    String dateText = '';
    if (type == TargetType.monthly) {
      final eff = DateTime.tryParse(r['effective_date']?.toString() ?? '');
      dateText = eff != null ? DateFormat('MMMM yyyy', _locale).format(eff) : '';
    } else {
      final d = DateTime.tryParse(r['specific_date']?.toString() ?? '');
      dateText = d != null ? DateFormat('d MMMM yyyy', _locale).format(d) : '';
    }

    final statusText = _statusLabel(_statusOf(r));

    final parts = <dynamic>[
      typeLabel,
      dateText,
      statusText,
      r['off_day_label'],
      r['keterangan'],
      r['target_anggota'],
      r['target_inspeksi'],
      r['target_anggota_selesai'],
      r['target_inspeksi_selesai'],
      r['target_lokasi'],
      r['target_unit'],
      r['target_subunit'],
      r['target_area'],
    ];
    return parts.map((e) => (e ?? '').toString().toLowerCase()).join(' ');
  }

  Map<String, dynamic>? _findDuplicate({
    required TargetType type,
    DateTime? date,
    int? excludeId,
  }) {
    if (date == null) return null;
    final dateStr = date.toIso8601String().split('T').first;
    for (final r in _all) {
      if (excludeId != null && r['id'] == excludeId) continue;
      if (r['type'] != type.db) continue;
      final compareField = type == TargetType.monthly ? r['effective_date'] : r['specific_date'];
      if ((compareField?.toString()) == dateStr) return r;
    }
    return null;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dCtx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(dCtx, rootNavigator: true).canPop()) {
            Navigator.of(dCtx, rootNavigator: true).pop();
          }
        });
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: _kGreen, size: 40),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDuplicateWarningDialog(
      BuildContext ctx, Map<String, dynamic> existing) {
    final dupType = TargetTypeX.from(existing['type'] as String? ?? 'daily_specific');
    final rawDateStr = dupType == TargetType.monthly
        ? (existing['effective_date'] ?? '-').toString()
        : (existing['specific_date'] ?? '-').toString();
    final parsedDate = DateTime.tryParse(rawDateStr);
    final dateStr = parsedDate != null
        ? (dupType == TargetType.monthly
            ? DateFormat('MMMM yyyy', _locale).format(parsedDate)
            : DateFormat('d MMMM yyyy', _locale).format(parsedDate))
        : rawDateStr;

    final label = dupType == TargetType.offDay
        ? existing['off_day_label'] as String?
        : null;
    final typeLabel = dupType == TargetType.offDay
        ? _t('offDay')
        : dupType == TargetType.monthly
            ? _t('monthly')
            : _t('daily');

    final String messageText = dupType == TargetType.monthly
        ? (widget.lang == 'ID'
            ? 'Sudah ada target $typeLabel pada bulan ini. Silakan edit target yang sudah ada.'
            : widget.lang == 'ZH'
                ? '本月已存在$typeLabel目标。请编辑现有目标。'
                : 'A $typeLabel target already exists for this month. Please edit the existing target.')
        : (widget.lang == 'ID'
            ? 'Sudah ada target $typeLabel pada tanggal ini. Silakan edit target yang sudah ada, atau pilih tanggal lain.'
            : widget.lang == 'ZH'
                ? '此日期已存在$typeLabel目标。请编辑现有目标，或选择其他日期。'
                : 'A $typeLabel target already exists on this date. Please edit the existing target or choose a different date.');

    return showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.lang == 'ID'
                  ? 'Target Sudah Ada'
                  : widget.lang == 'ZH'
                      ? '目标已存在'
                      : 'Target Already Exists',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              messageText,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha:0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.event_rounded, size: 14, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (label != null && label.isNotEmpty)
                        ? '$dateStr • $label'
                        : dateStr,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.red),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              widget.lang == 'ID'
                  ? 'Mengerti'
                  : widget.lang == 'ZH'
                      ? '知道了'
                      : 'Got It',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _filter() {
    var l = List<Map<String, dynamic>>.from(_all);
    if (_fType != null) l = l.where((r) => r['type'] == _fType!.db).toList();
    if (_fStatus != null) {
      l = l.where((r) => _statusOf(r) == _fStatus).toList();
    }
    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      l = l.where((r) => _searchableText(r).contains(q)).toList();
    }
    _view = l;
    _currentPage = 1;
  }

  Future<void> _save({
    required bool isEdit,
    int? id,
    required TargetType type,
    DateTime? effectiveDate,
    DateTime? date,
    int a = 0,
    int i = 0,
    int l = 0,
    int u = 0,
    int s = 0,
    int ar = 0,
    int aSelesai = 0,
    int iSelesai = 0,
    String? label,
    String? ket,
    required bool aktif,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'type'                    : type.db,
        'is_aktif'                : type == TargetType.monthly ? true : aktif,
        'keterangan'              : ket?.isEmpty == true ? null : ket,
        'updated_at'              : DateTime.now().toIso8601String(),
      };

      if (type == TargetType.monthly) {
        payload['effective_date']           = effectiveDate?.toIso8601String().split('T').first;
        payload['specific_date']            = null;
        payload['off_day_label']            = null;
        payload['target_anggota']           = a;
        payload['target_inspeksi']          = i;
        payload['target_lokasi']            = l;
        payload['target_unit']              = u;
        payload['target_subunit']           = s;
        payload['target_area']              = ar;
        payload['target_anggota_selesai']   = aSelesai;
        payload['target_inspeksi_selesai']  = iSelesai;
      } else if (type == TargetType.daily) {
        payload['effective_date']           = null;
        payload['specific_date']            = date?.toIso8601String().split('T').first;
        payload['off_day_label']            = null;
        payload['target_anggota']           = a;
        payload['target_inspeksi']          = i;
        payload['target_lokasi']            = l;
        payload['target_unit']              = u;
        payload['target_subunit']           = s;
        payload['target_area']              = ar;
        payload['target_anggota_selesai']   = aSelesai;
        payload['target_inspeksi_selesai']  = iSelesai;
      } else {
        payload['effective_date']           = null;
        payload['specific_date']            = date?.toIso8601String().split('T').first;
        payload['off_day_label']            = label;
        payload['target_anggota']           = 0;
        payload['target_inspeksi']          = 0;
        payload['target_lokasi']            = 0;
        payload['target_unit']              = 0;
        payload['target_subunit']           = 0;
        payload['target_area']              = 0;
        payload['target_anggota_selesai']   = 0;
        payload['target_inspeksi_selesai']  = 0;
      }

      if (isEdit && id != null) {
        await Supabase.instance.client
            .from('target_5r_findings')
            .update(payload)
            .eq('id', id);
        _showSuccessDialog(_t('ok_edit'));
      } else if (type == TargetType.monthly) {
        await Supabase.instance.client
            .from('target_5r_findings')
            .upsert(payload, onConflict: 'type,effective_date');
        _showSuccessDialog(_t('ok_add'));
      } else {
        await Supabase.instance.client
            .from('target_5r_findings')
            .insert(payload);
        _showSuccessDialog(_t('ok_add'));
      }
      _fetch();
    } catch (e) {
      debugPrint('Save target error: $e');
      _snack(_t('err'), err: true);
    }
  }

  // CONFIRM TARGET POP-UP
  Future<bool?> _confirmAddDialog(
    BuildContext ctx, {
    required bool isEdit, 
    required TargetType type,
    DateTime? monthlyEffectiveDate,
    DateTime? dateValue,
    String? offDayLabel,
    int a = 0,
    int i = 0,
    int l = 0,
    int u = 0,
    int s = 0,
    int ar = 0,
    int aSelesai = 0,
    int iSelesai = 0,
  }) {
    final (String typeLabel, IconData typeIcon, Color typeColor) = switch (type) {
      TargetType.monthly => (_t('monthly'), Icons.calendar_month_rounded, _kGreen),
      TargetType.daily => (_t('daily'), Icons.event_rounded, _kBlue),
      TargetType.offDay => (_t('offDay'), Icons.beach_access_rounded, const Color(0xFFD97706)),
    };

    String detail;
    if (type == TargetType.monthly) {
      final effStr = DateFormat('d MMMM yyyy', _locale).format(monthlyEffectiveDate!);
      detail = widget.lang == 'ID'
          ? 'Akan otomatis aktif pada $effStr dan menggantikan target bulanan yang sedang berjalan.'
          : widget.lang == 'ZH'
              ? '将于 $effStr 自动生效，并取代当前的每月目标。'
              : 'Will automatically activate on $effStr, replacing the current monthly target.';
    } else if (type == TargetType.daily) {
      detail = DateFormat('d MMMM yyyy', _locale).format(dateValue ?? DateTime.now());
    } else {
      final lbl = (offDayLabel ?? '').isEmpty ? '-' : offDayLabel!;
      detail =
          '${DateFormat('d MMMM yyyy', _locale).format(dateValue ?? DateTime.now())} • $lbl';
    }
    final List<(IconData, String, int, Color)> targetRows = type == TargetType.offDay
        ? []
        : [
            (Icons.people_rounded, _t('a'), a, _kGreen),
            (Icons.check_circle_rounded, widget.lang == 'ID'
                ? 'Target Anggota Selesai'
                : widget.lang == 'ZH' ? '成员完成目标' : 'Member Completion Target', aSelesai, _kGreen),
            (Icons.search_rounded, _t('i'), i, _kGreen),
            (Icons.check_circle_outline_rounded, widget.lang == 'ID'
                ? 'Target Inspeksi Selesai'
                : widget.lang == 'ZH' ? '检查完成目标' : 'Inspection Completion Target', iSelesai, _kGreen),
            (Icons.location_city_rounded, _t('l'), l, _kBlue),
            (Icons.apartment_rounded, _t('u'), u, _kBlue),
            (Icons.domain_rounded, _t('s'), s, const Color(0xFF7C3AED)),
            (Icons.place_rounded, _t('ar'), ar, const Color(0xFF7C3AED)),
          ];
    final String dialogTitle = isEdit
        ? (widget.lang == 'ID'
            ? 'Konfirmasi Perubahan'
            : widget.lang == 'ZH'
                ? '确认修改'
                : 'Confirm Changes')
        : (widget.lang == 'ID'
            ? 'Konfirmasi Penambahan'
            : widget.lang == 'ZH'
                ? '确认添加'
                : 'Confirm Addition');

    final String questionText = isEdit
        ? (widget.lang == 'ID'
            ? 'Simpan perubahan pada target $typeLabel berikut?'
            : widget.lang == 'ZH'
                ? '确定要保存此 $typeLabel 目标的更改吗？'
                : 'Save the following changes to this $typeLabel target?')
        : (widget.lang == 'ID'
            ? 'Tambahkan target $typeLabel berikut?'
            : widget.lang == 'ZH'
                ? '确定要添加此 $typeLabel 目标吗？'
                : 'Add the following $typeLabel target?');

    final String confirmBtnText = isEdit
        ? (widget.lang == 'ID'
            ? 'Ya, Simpan'
            : widget.lang == 'ZH'
                ? '是，保存'
                : 'Yes, Save')
        : (widget.lang == 'ID'
            ? 'Ya, Tambahkan'
            : widget.lang == 'ZH'
                ? '是，添加'
                : 'Yes, Add');

    return showDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: typeColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(isEdit ? Icons.edit_rounded : typeIcon, color: typeColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dialogTitle,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                questionText,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: typeColor.withValues(alpha:0.25)),
                ),
                child: Text(detail,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: typeColor)),
              ),

              if (targetRows.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.lang == 'ID'
                      ? 'Detail Target'
                      : widget.lang == 'ZH'
                          ? '目标详情'
                          : 'Target Details',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      for (int idx = 0; idx < targetRows.length; idx++) ...[
                        if (idx > 0)
                          Divider(height: 1, color: Colors.grey.shade100),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Icon(targetRows[idx].$1, size: 14, color: targetRows[idx].$4),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(targetRows[idx].$2,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.black87)),
                            ),
                            Text('${targetRows[idx].$3}',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: targetRows[idx].$4)),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              if (type == TargetType.offDay && (offDayLabel ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: typeColor.withValues(alpha:0.25)),
                  ),
                  child: Row(children: [
                    Icon(Icons.label_rounded, size: 14, color: typeColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(offDayLabel!,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: typeColor)),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              confirmBtnText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEBEB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFFEF4444),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.lang == 'EN' ? 'Delete?' : widget.lang == 'ZH' ? '删除？' : 'Hapus?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('del_d'),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 18),
                      label: Text(
                        _t('delete'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _t('cancel'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (ok != true) return;
    try {
      await Supabase.instance.client
          .from('target_5r_findings')
          .delete()
          .eq('id', id);
      _showSuccessDialog(_t('ok_del'));
      _fetch();
    } catch (_) {
      _snack(_t('err'), err: true);
    }
  }

  void _snack(String msg, {bool err = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: err ? Colors.red : _kGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));

  void _openAddTargetDialog({Map<String, dynamic>? item}) {
    AdminAddTargetDialog.show(
      context,
      lang: widget.lang,
      item: item,
      findDuplicate: _findDuplicate,
      showDuplicateWarning: _showDuplicateWarningDialog,
      confirmDialog: _confirmAddDialog,
      onSave: _save,
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final totalPages = _view.isEmpty ? 1 : (_view.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > _view.length ? _view.length : startIdx + _perPage;
    final pageData = _view.isEmpty ? <Map<String, dynamic>>[] : _view.sublist(startIdx, endIdx);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        _filterBar(),
        Expanded(
          child: _loading
              ? _shimmer()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: _kGreen,
                  child: _view.isEmpty
                      ? _empty()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: pageData.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _card(pageData[i]),
                        )),
        ),
        if (!_loading && totalPages > 1) _pageIndicator(safePage, totalPages),
      ]),
    );
  }

  // BOTTOM PAGE INDICATOR
  Widget _pageIndicator(int currentPage, int totalPages) {
    const int maxVisible = 5;
    List<int> visible() {
      if (totalPages <= maxVisible) return List.generate(totalPages, (i) => i + 1);
      int start = currentPage - 2;
      int end = currentPage + 2;
      if (start < 1) {
        start = 1;
        end = maxVisible;
      } else if (end > totalPages) {
        end = totalPages;
        start = totalPages - (maxVisible - 1);
      }
      return List.generate(end - start + 1, (i) => start + i);
    }

    final pageNumbers = visible();
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomSpacing = bottomInset > 0 ? bottomInset + 10 : 16;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(15, 8, 15, bottomSpacing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: _kGreen.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            _pageArrow(
              icon: Icons.arrow_back_ios_new_rounded,
              enabled: canPrev,
              onTap: () {
                if (canPrev) setState(() => _currentPage = currentPage - 1);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  for (final p in pageNumbers) ...[
                    Expanded(child: _pageNum(p, currentPage)),
                    if (p != pageNumbers.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _pageArrow(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: canNext,
              onTap: () {
                if (canNext) setState(() => _currentPage = currentPage + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageNum(int page, int currentPage) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page != currentPage) setState(() => _currentPage = page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _kGreen : _kGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: _kGreen.withValues(alpha: 0.25)),
        ),
        child: Text('$page',
            style: GoogleFonts.poppins(color: isActive ? Colors.white : _kGreen, fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }

  Widget _pageArrow({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? _kGreen.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? _kGreen : Colors.grey.shade400),
      ),
    );
  }

  // FILTER BAR
  Widget _filterBar() => Container(
    color: Colors.white,
    child: Column(children: [
      // ADD TARGET BUTTON
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: GestureDetector(
          onTap: () => _openAddTargetDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGreen, Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _kGreen.withValues(alpha:0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t('add'),
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    Text(
                      widget.lang == 'ID'
                          ? 'Tambah target bulanan, harian, atau hari libur'
                          : widget.lang == 'ZH'
                              ? '添加月度、每日或节假日目标'
                              : 'Add monthly, daily, or holiday target',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha:0.85)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 14),
            ]),
          ),
        ),
      ),

      // SEARCH BAR + STATUS FILTER
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          // SEARCH BAR
          Expanded(
            flex: 3,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() { _q = v; _filter(); }),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(fontSize: 13, color: _kBlue, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: _t('search'),
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // STATUS FILTER 
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _showStatusFilterDialog,
              child: Builder(builder: (_) {
                final Color fg = _fStatus == null ? Colors.grey.shade600 : _statusColors(_fStatus!).$3;
                final Color bg = _fStatus == null ? const Color(0xFFF1F5F9) : _statusColors(_fStatus!).$1;
                final Color bd = _fStatus == null ? Colors.black.withValues(alpha: 0.08) : _statusColors(_fStatus!).$2;
                final IconData ic = _fStatus == null ? Icons.apps_rounded : _statusIcon(_fStatus!);
                final String label = _fStatus == null
                    ? (widget.lang == 'ID' ? 'Semua' : widget.lang == 'ZH' ? '全部' : 'All')
                    : _statusLabel(_fStatus!);
                return Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bd),
                  ),
                  child: Row(children: [
                    Icon(ic, size: 16, color: fg),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(label,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey.shade400),
                  ]),
                );
              }),
            ),
          ),
        ]),
      ),

      // TYPE FILTER CHIP (TAB BAR)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          // ALL
          Expanded(child: _typeChip(
            _t('alltype'),
            _fType == null,
            null,
            null,
            () => setState(() { _fType = null; _filter(); }),
          )),
          const SizedBox(width: 6),
          // MONTHLY
          Expanded(child: _typeChip(
            _t('monthly'),
            _fType == TargetType.monthly,
            Icons.calendar_month_rounded,
            _kGreen,
            () => setState(() { _fType = TargetType.monthly; _filter(); }),
          )),
          const SizedBox(width: 6),
          // DAILY
          Expanded(child: _typeChip(
            _t('daily'),
            _fType == TargetType.daily,
            Icons.event_rounded,
            _kBlue,
            () => setState(() { _fType = TargetType.daily; _filter(); }),
          )),
          const SizedBox(width: 6),
          // OFF DAY
          Expanded(child: _typeChip(
            _t('offDay'),
            _fType == TargetType.offDay,
            Icons.beach_access_rounded,
            const Color(0xFFD97706),
            () => setState(() { _fType = TargetType.offDay; _filter(); }),
          )),
        ]),
      ),

      // OFF DAY FILTER ACTIVE INFO BANNER
      if (_fType == TargetType.offDay)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFBBF24).withValues(alpha:0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t('holiday_info'),
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFD97706),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
        ),

      Container(height: 1, color: Colors.black.withValues(alpha:0.06)),
    ]),
  );

  Future<void> _showStatusFilterDialog() {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.lang == 'ID' ? 'Filter Status' : widget.lang == 'ZH' ? '筛选状态' : 'Filter Status',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              _statusOptionTile(
                dCtx,
                icon: Icons.apps_rounded,
                color: Colors.grey.shade600,
                label: widget.lang == 'ID' ? 'Semua' : widget.lang == 'ZH' ? '全部' : 'All',
                value: null,
              ),
              const SizedBox(height: 10),
              _statusOptionTile(
                dCtx,
                icon: _statusIcon(_TargetStatus.active),
                color: _statusColors(_TargetStatus.active).$3,
                label: _statusLabel(_TargetStatus.active),
                value: _TargetStatus.active,
              ),
              const SizedBox(height: 10),
              _statusOptionTile(
                dCtx,
                icon: _statusIcon(_TargetStatus.upcoming),
                color: _statusColors(_TargetStatus.upcoming).$3,
                label: _statusLabel(_TargetStatus.upcoming),
                value: _TargetStatus.upcoming,
              ),
              const SizedBox(height: 10),
              _statusOptionTile(
                dCtx,
                icon: _statusIcon(_TargetStatus.inactive),
                color: _statusColors(_TargetStatus.inactive).$3,
                label: _statusLabel(_TargetStatus.inactive),
                value: _TargetStatus.inactive,
              ),
              const SizedBox(height: 10),
              _statusOptionTile(
                dCtx,
                icon: _statusIcon(_TargetStatus.superseded),
                color: _statusColors(_TargetStatus.superseded).$3,
                label: _statusLabel(_TargetStatus.superseded),
                value: _TargetStatus.superseded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusOptionTile(
    BuildContext dCtx, {
    required IconData icon,
    required Color color,
    required String label,
    required _TargetStatus? value,
  }) {
    final bool selected = _fStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() { _fStatus = value; _filter(); });
        Navigator.pop(dCtx);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color.withValues(alpha: 0.5) : Colors.grey.shade200,
              width: selected ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: selected ? color : Colors.black87)),
            ),
            if (selected) Icon(Icons.check_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  // CHIP FILTER TYPE
  Widget _typeChip(
    String label,
    bool sel,
    IconData? icon,
    Color? activeColor,
    VoidCallback onTap,
  ) {
    final color = activeColor ?? Colors.grey.shade600;
    final selBg = activeColor ?? Colors.grey.shade500;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? selBg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? selBg : Colors.grey.shade300,
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel
              ? [BoxShadow(
                  color: selBg.withValues(alpha:0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2))]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.apps_rounded, size: 13, color: sel ? Colors.white : color),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // TARGET CARD
  Widget _card(Map<String, dynamic> item) {
    final type = TargetTypeX.from(item['type'] as String? ?? 'monthly');
    final bool displayActive = _statusOf(item) == _TargetStatus.active;
    final (Color tc, IconData ti, String tl) = switch (type) {
      TargetType.monthly => (_kGreen, Icons.calendar_month_rounded, _t('monthly')),
      TargetType.daily => (
          _kBlue,
          Icons.event_rounded,
          _t('daily')
        ),
      TargetType.offDay => (
          const Color(0xFFD97706),
          Icons.beach_access_rounded,
          _t('offDay')
        ),
    };
    final monthlyEff = type == TargetType.monthly
        ? DateTime.tryParse(item['effective_date']?.toString() ?? '')
        : null;
    final specificDate = type != TargetType.monthly
        ? DateTime.tryParse(item['specific_date']?.toString() ?? '')
        : null;
    final subtitle = type == TargetType.monthly
        ? (monthlyEff != null
            ? DateFormat('MMMM yyyy', _locale).format(monthlyEff)
            : '-')
        : (specificDate != null
            ? DateFormat('d MMMM yyyy', _locale).format(specificDate)
            : (item['specific_date'] ?? '-').toString());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: displayActive ? tc.withValues(alpha:0.3) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: displayActive
                  ? tc.withValues(alpha:0.08)
                  : Colors.black.withValues(alpha:0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // HEADER ROW
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: tc.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(ti, color: tc, size: 16)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(tl,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: tc,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _kBlue)),
              ])),
              _statusBadgeGeneric(item),
            ]),

            // MONTHLY: SCHEDULE INFO
            if (type == TargetType.monthly && item['id'] != _activeMonthlyId) ...[
              const SizedBox(height: 6),
              Text(
                (monthlyEff != null && monthlyEff.isAfter(DateTime.now()))
                    ? (widget.lang == 'ID'
                        ? 'Akan menggantikan target aktif mulai tanggal di atas'
                        : widget.lang == 'ZH'
                            ? '将于上方日期起替代当前生效的目标'
                            : 'Will replace the active target starting the date above')
                    : (widget.lang == 'ID'
                        ? 'Target ini sudah digantikan oleh target bulanan yang lebih baru'
                        : widget.lang == 'ZH'
                            ? '此目标已被更新的每月目标取代'
                            : 'This target has been superseded by a newer monthly target'),
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                    fontStyle: FontStyle.italic),
              ),
            ],

            // OFF DAY: LABEL + INFO
            if (type == TargetType.offDay) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha:0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.beach_access_rounded,
                      size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      if ((item['off_day_label'] as String?)
                              ?.isNotEmpty ==
                          true)
                        Text(
                          item['off_day_label'] as String,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706)),
                        ),
                      Text(
                        _t('holiday_info'),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFFD97706)
                                .withValues(alpha:0.8),
                            fontStyle: FontStyle.italic),
                      ),
                    ]),
                  ),
                ]),
              ),
            ],

            // NON-HOLIDAY: TARGET GRID
            if (type != TargetType.offDay) ...[
              const SizedBox(height: 12),
              _targetGrid([
                _targetStatChip(Icons.people_rounded, _t('a'), item['target_anggota'] as int? ?? 0, _kBlue),
                _targetStatChip(Icons.check_circle_rounded, _t('a_selesai'), item['target_anggota_selesai'] as int? ?? 0, _kGreen),
                _targetStatChip(Icons.search_rounded, _t('i'), item['target_inspeksi'] as int? ?? 0, _kPurple),
                _targetStatChip(Icons.check_circle_rounded, _t('i_selesai'), item['target_inspeksi_selesai'] as int? ?? 0, _kGreen),
                _targetStatChip(Icons.location_city_rounded, _t('l'), item['target_lokasi'] as int? ?? 0, _kBlue),
                _targetStatChip(Icons.apartment_rounded, _t('u'), item['target_unit'] as int? ?? 0, _kSky),
                _targetStatChip(Icons.domain_rounded, _t('s'), item['target_subunit'] as int? ?? 0, _kPurple),
                _targetStatChip(Icons.place_rounded, _t('ar'), item['target_area'] as int? ?? 0, _kPink),
              ]),
              if (type == TargetType.daily) ...[
                const SizedBox(height: 6),
                Text(_t('override'),
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _kBlue,
                        fontStyle: FontStyle.italic)),
              ],
            ],

            if ((item['keterangan'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(item['keterangan'] as String,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black38,
                      fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            // ACTIONS
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _iconBtn(Icons.edit_rounded, _kBlue,
                  () => _openAddTargetDialog(item: item)),
              const SizedBox(width: 8),
              _iconBtn(Icons.delete_outline_rounded, Colors.red,
                  () => _delete(item['id'] as int)),
            ]),
          ])),
    );
  }

  Widget _statusBadgeGeneric(Map<String, dynamic> item) {
    final st = _statusOf(item);
    final (bg, border, fg) = _statusColors(st);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(st), size: 10, color: fg),
          const SizedBox(width: 3),
          Text(_statusLabel(st), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  Widget _targetGrid(List<Widget> chips) {
    return LayoutBuilder(builder: (ctx, constraints) {
      const spacing = 8.0;
      final w = (constraints.maxWidth - spacing * 3) / 4;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: chips.map((c) => SizedBox(width: w, child: c)).toList(),
      );
    });
  }

  Widget _targetStatChip(IconData icon, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 4),
          Text('$value',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color c, VoidCallback onTap) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: c.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.withValues(alpha:0.3))),
            child: Icon(icon, size: 16, color: c),
          ));

  Widget _shimmer() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(
              height: 110,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14))),
        ),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/team_illustration.png',
                height: 160,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: Icon(Icons.track_changes_rounded, size: 48, color: _kGreen.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(height: 16),
              Text(_t('empty'),
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _kGreen),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                widget.lang == 'ID'
                    ? 'Coba ubah kata kunci atau filter pencarian kamu.'
                    : widget.lang == 'ZH'
                        ? '请尝试更改搜索关键词或筛选条件。'
                        : 'Try changing your search keyword or filter.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}