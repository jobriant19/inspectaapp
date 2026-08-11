import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../analytics/kts production/kts_section_location_picker.dart';
import 'preventif_add_report.dart';
import 'preventif_edit_report.dart';

const List<String> kPmBagianList = [
  'Laser', 'Mesin', 'Spot', 'Las', 'Ftw', 'Cat',
  'Assy', 'Ekspedisi & Packing', 'Purchasing', 'Engineering', 'PPIC',
];

class _PC {
  static const primary      = Color(0xFF1D4ED8);
  static const primaryDark  = Color(0xFF1E3A8A);
  static const primaryLight = Color(0xFFEFF6FF);
  static const border       = Color(0xFFBFDBFE);
  static const bg           = Color(0xFFF0F4FF);
  static const barColor     = Color(0xFF3B82F6);
  static const divider      = Color(0xFFDBEAFE);
  static const textPrimary  = Color(0xFF1E3A8A);
  static const textSec      = Color(0xFF3730A3);
}

enum _PmRange { thisMonth, threeMonths, sixMonths, oneYear, custom }

extension _PmRangeExt on _PmRange {
  String label(String lang) {
    switch (this) {
      case _PmRange.thisMonth:    return lang == 'EN' ? 'This Month'  : lang == 'ZH' ? '本月'  : 'Bulan Ini';
      case _PmRange.threeMonths:  return lang == 'EN' ? '3 Months'    : lang == 'ZH' ? '3个月' : '3 Bulan';
      case _PmRange.sixMonths:    return lang == 'EN' ? '6 Months'    : lang == 'ZH' ? '6个月' : '6 Bulan';
      case _PmRange.oneYear:      return lang == 'EN' ? '1 Year'      : lang == 'ZH' ? '1年'   : '1 Tahun';
      case _PmRange.custom:       return lang == 'EN' ? 'Custom'      : lang == 'ZH' ? '自定义' : 'Kustom';
    }
  }
  int get monthCount {
    switch (this) {
      case _PmRange.thisMonth:   return 1;
      case _PmRange.threeMonths: return 3;
      case _PmRange.sixMonths:   return 6;
      case _PmRange.oneYear:     return 12;
      case _PmRange.custom:      return 12; // di-override dinamis oleh _customStart/_customEnd
    }
  }
}

enum _PmStatus { none, onTime, late }
enum _PmLateFilter { all, onTime, late, notReported }

extension _PmLateFilterExt on _PmLateFilter {
  String label(String lang) {
    switch (this) {
      case _PmLateFilter.all:         return lang == 'EN' ? 'All Status'   : lang == 'ZH' ? '全部状态' : 'Semua Status';
      case _PmLateFilter.onTime:      return lang == 'EN' ? 'On Time'      : lang == 'ZH' ? '准时'    : 'Tepat Waktu';
      case _PmLateFilter.late:        return lang == 'EN' ? 'Late'         : lang == 'ZH' ? '迟到'    : 'Terlambat';
      case _PmLateFilter.notReported: return lang == 'EN' ? 'Not Reported' : lang == 'ZH' ? '未报告'  : 'Tidak Lapor';
    }
  }

  IconData get icon {
    switch (this) {
      case _PmLateFilter.late:        return Icons.priority_high_rounded;
      case _PmLateFilter.onTime:      return Icons.check_circle_rounded;
      case _PmLateFilter.notReported: return Icons.help_outline_rounded;
      case _PmLateFilter.all:         return Icons.list_alt_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _PmLateFilter.late:        return const Color(0xFFEF4444);
      case _PmLateFilter.onTime:      return _PC.barColor;
      case _PmLateFilter.notReported: return const Color(0xFF94A3B8);
      case _PmLateFilter.all:         return _PC.primary;
    }
  }
}

class _PmKasieRow {
  final String kasieId;
  final String kasieNama;
  final String bagian;
  final Map<int, _PmStatus> bulanan;
  final Map<int, String?> alasan;
  final int total;
  final int lateCount;
  const _PmKasieRow({
    required this.kasieId,
    required this.kasieNama,
    required this.bagian,
    required this.bulanan,
    required this.alasan,
    required this.total,
    required this.lateCount,
  });
}

class PreventifMaintenanceScreen extends StatefulWidget {
  final String lang;
  const PreventifMaintenanceScreen({super.key, required this.lang});

  @override
  State<PreventifMaintenanceScreen> createState() => _PreventifMaintenanceScreenState();
}

class _PreventifMaintenanceScreenState extends State<PreventifMaintenanceScreen> {
  final _db = Supabase.instance.client;
  String? _currentUserId;
  int? _currentUserJabatan;

  // CHART & FILTER STATE
  bool _chartExpanded  = false;
  _PmRange _range      = _PmRange.threeMonths;
  String? _filterBagian;
  _PmLateFilter _lateFilter = _PmLateFilter.all;
  DateTime? _customStart; 
  DateTime? _customEnd;

  // DATA STATE
  bool _loadingTable    = false;
  bool _loadingRecords  = false;
  List<_PmKasieRow> _tableRows  = [];
  // ignore: unused_field
  List<String>      _bulanLabels = [];
  List<Map<String, dynamic>> _myRecords = [];
  Map<String, String> _sectionDisplayMap = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = _db.auth.currentUser?.id;
    _loadUserJabatan();
    _loadSectionDisplayMap();
    _loadAll();
  }

  Future<void> _loadSectionDisplayMap() async {
    try {
      final res = await _db
          .from('section')
          .select('nama_section_id, nama_section_en, nama_section_zh');
      final rows = List<Map<String, dynamic>>.from(res);
      final map = <String, String>{};
      for (final r in rows) {
        final idName = (r['nama_section_id'] as String?)?.trim();
        if (idName == null || idName.isEmpty) continue;
        String display = idName;
        if (widget.lang == 'EN') {
          final en = (r['nama_section_en'] as String?)?.trim();
          if (en != null && en.isNotEmpty) display = en;
        } else if (widget.lang == 'ZH') {
          final zh = (r['nama_section_zh'] as String?)?.trim();
          if (zh != null && zh.isNotEmpty) display = zh;
        }
        map[idName.toLowerCase()] = display;
      }
      if (mounted) setState(() => _sectionDisplayMap = map);
    } catch (e) {
      debugPrint('PM loadSectionDisplayMap error: $e');
    }
  }

  String _displaySectionName(String raw) {
    if (raw.isEmpty) return raw;
    return _sectionDisplayMap[raw.trim().toLowerCase()] ?? raw;
  }

  Future<void> _loadUserJabatan() async {
    if (_currentUserId == null) return;
    try {
      final res = await _db
          .from('User')
          .select('id_jabatan')
          .eq('id_user', _currentUserId!)
          .single();
      if (mounted) {
        setState(() => _currentUserJabatan = res['id_jabatan'] as int?);
      }
    } catch (e) {
      debugPrint('PM loadUserJabatan error: $e');
    }
  }

  String _t(String k) => _i18n[widget.lang]?[k] ?? _i18n['ID']![k] ?? k;
  static const _i18n = {
    'ID': {
      'title'       : 'Preventif Maintenance',
      'add'         : 'Buat Laporan PM',
      'add_sub'     : 'Catat kegiatan preventif maintenance',
      'empty_title' : 'Belum Ada Laporan PM',
      'empty_sub'   : 'Buat laporan PM pertama Anda.',
      'delete'      : 'Hapus',
      'cancel'      : 'Batal',
      'delete_confirm': 'Hapus laporan PM ini?',
      'deleted'     : 'Laporan PM dihapus',
      'edit'        : 'Edit',
      'bagian'      : 'Bagian',
      'semua_bagian': 'Semua Bagian',
      'pilih_bagian': 'Pilih Bagian',
      'grafik'      : 'Grafik',
      'tidak_ada'   : 'Tidak ada data untuk periode ini',
      'kasie'       : 'Kasie',
      'total'       : 'Total',
      'my_records'  : 'Laporan Saya',
    },
    'EN': {
      'title'       : 'Preventive Maintenance',
      'add'         : 'Create PM Report',
      'add_sub'     : 'Record preventive maintenance activity',
      'empty_title' : 'No PM Reports Yet',
      'empty_sub'   : 'Create your first PM report.',
      'delete'      : 'Delete',
      'cancel'      : 'Cancel',
      'delete_confirm': 'Delete this PM report?',
      'deleted'     : 'PM report deleted',
      'edit'        : 'Edit',
      'bagian'      : 'Section',
      'semua_bagian': 'All Sections',
      'pilih_bagian': 'Select Section',
      'grafik'      : 'Chart',
      'tidak_ada'   : 'No data for this period',
      'kasie'       : 'Kasie',
      'total'       : 'Total',
      'my_records'  : 'My Reports',
    },
    'ZH': {
      'title'       : '预防性维护',
      'add'         : '创建PM报告',
      'add_sub'     : '记录预防性维护活动',
      'empty_title' : '暂无PM报告',
      'empty_sub'   : '创建您的第一份PM报告。',
      'delete'      : '删除',
      'cancel'      : '取消',
      'delete_confirm': '删除此PM报告？',
      'deleted'     : 'PM报告已删除',
      'edit'        : '编辑',
      'bagian'      : '部门',
      'semua_bagian': '所有部门',
      'pilih_bagian': '选择部门',
      'grafik'      : '图表',
      'tidak_ada'   : '此期间无数据',
      'kasie'       : '科长',
      'total'       : '总计',
      'my_records'  : '我的报告',
    },
  };

  Future<void> _loadAll() async {
    await Future.wait([_loadTableData(), _loadMyRecords()]);
  }

  List<DateTime> _getMonths() {
    if (_range == _PmRange.custom && _customStart != null && _customEnd != null) {
      final List<DateTime> months = [];
      DateTime cursor = DateTime(_customStart!.year, _customStart!.month, 1);
      final last = DateTime(_customEnd!.year, _customEnd!.month, 1);
      while (!cursor.isAfter(last) && months.length < 12) {
        months.add(cursor);
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      return months;
    }
    final now   = DateTime.now();
    final count = _range.monthCount;
    return List.generate(count, (i) {
      final offset = count - 1 - i;
      return DateTime(now.year, now.month - offset, 1);
    });
  }

  Future<void> _loadTableData() async {
    setState(() => _loadingTable = true);
    try {
      final months = _getMonths();
      final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
      _bulanLabels = months.map((m) => DateFormat('MMM yy', locale).format(m)).toList();

      dynamic sectionQuery = _db.from('section')
          .select('id_section, nama_section_id, id_pic, pic:id_pic(id_user, nama)')
          .not('id_pic', 'is', null);
      if (_filterBagian != null) sectionQuery = sectionQuery.eq('nama_section_id', _filterBagian!);
      final sectionRes = List<Map<String, dynamic>>.from(await sectionQuery);
      if (sectionRes.isEmpty) { setState(() { _tableRows = []; _loadingTable = false; }); return; }

      final start = months.first;
      final end   = DateTime(months.last.year, months.last.month + 1, 0);

      // PERIOD NOW BASED ON bulan_pm (NOT created_at)
      final pmRes = List<Map<String, dynamic>>.from(
        await _db.from('preventif_maintenance')
            .select('id_user, bagian, bulan_pm, alasan_terlambat, is_late')
            .gte('bulan_pm', DateFormat('yyyy-MM-dd').format(start))
            .lte('bulan_pm', DateFormat('yyyy-MM-dd').format(end)),
      );

      // MAPPING: SECTION -> MONTH INDEX -> STATUS / REASON (is_late FROM DB)
      final Map<String, Map<int, _PmStatus>> bagianMonthStatus = {};
      final Map<String, Map<int, String?>>  bagianMonthAlasan  = {};
      for (final row in pmRes) {
        final bagian = (row['bagian'] as String?)?.trim() ?? '';
        if (bagian.isEmpty) continue;
        final bln = DateTime.tryParse(row['bulan_pm']?.toString() ?? '');
        if (bln == null) continue;
        final isLate = row['is_late'] == true;
        for (int i = 0; i < months.length; i++) {
          final m = months[i];
          if (bln.year == m.year && bln.month == m.month) {
            final statusMap = bagianMonthStatus.putIfAbsent(bagian, () => {});
            final alasanMap = bagianMonthAlasan.putIfAbsent(bagian, () => {});
            statusMap[i] = isLate ? _PmStatus.late : _PmStatus.onTime;
            if (isLate) alasanMap[i] = row['alasan_terlambat']?.toString();
            break;
          }
        }
      }

      var rows = sectionRes.map((sec) {
        final pic       = sec['pic'] as Map<String, dynamic>?;
        final kasieId   = pic?['id_user']?.toString() ?? '';
        final kasieNama = pic?['nama']?.toString() ?? '-';
        final bagian    = (sec['nama_section_id'] as String?)?.trim() ?? '';
        final statusMap = bagianMonthStatus[bagian] ?? {};
        final alasanMap = bagianMonthAlasan[bagian] ?? {};
        final bulanan   = <int, _PmStatus>{ for (int i = 0; i < months.length; i++) i: statusMap[i] ?? _PmStatus.none };
        final alasan    = <int, String?>{ for (int i = 0; i < months.length; i++) i: alasanMap[i] };
        final total     = bulanan.values.where((s) => s != _PmStatus.none).length;
        final lateCount = bulanan.values.where((s) => s == _PmStatus.late).length;
        return _PmKasieRow(kasieId: kasieId, kasieNama: kasieNama, bagian: bagian, bulanan: bulanan, alasan: alasan, total: total, lateCount: lateCount);
      }).toList();

      // FILTER STATUS LAPORAN (BERLAKU UNTUK CHART & TABLE)
      if (_lateFilter == _PmLateFilter.late) {
        rows = rows.where((r) => r.lateCount > 0).toList();
      } else if (_lateFilter == _PmLateFilter.onTime) {
        rows = rows.where((r) => r.bulanan.values.any((s) => s == _PmStatus.onTime)).toList();
      } else if (_lateFilter == _PmLateFilter.notReported) {
        rows = rows.where((r) => r.bulanan.values.any((s) => s == _PmStatus.none)).toList();
      }

      rows.sort((a, b) => b.total.compareTo(a.total));

      setState(() { _tableRows = rows; _loadingTable = false; });
    } catch (e) {
      debugPrint('PM loadTableData error: $e');
      if (mounted) setState(() => _loadingTable = false);
    }
  }

  Future<void> _openFile(String? url, String? fileName) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.lang == 'EN'
              ? 'Cannot open file'
              : widget.lang == 'ZH'
                  ? '无法打开文件'
                  : 'Tidak dapat membuka file'),
          backgroundColor: CupertinoColors.destructiveRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _loadMyRecords() async {
    if (_currentUserId == null) return;
    setState(() => _loadingRecords = true);
    try {
      final res = await _db.from('preventif_maintenance')
          .select('*')
          .eq('id_user', _currentUserId!)
          .order('created_at', ascending: false);
      if (mounted) setState(() { _myRecords = List<Map<String, dynamic>>.from(res); _loadingRecords = false; });
    } catch (e) {
      debugPrint('PM loadMyRecords error: $e');
      if (mounted) setState(() => _loadingRecords = false);
    }
  }

  Future<void> _deleteRecord(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0, backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.12), blurRadius: 24, offset: const Offset(0, 8))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFFFF1F2), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.trash_fill, color: Color(0xFFEF4444), size: 32)),
            const SizedBox(height: 16),
            Text(_t('delete_confirm'), style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(widget.lang == 'EN' ? 'This action cannot be undone.' : widget.lang == 'ZH' ? '此操作无法撤销。' : 'Tindakan ini tidak dapat dibatalkan.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(onTap: () => Navigator.pop(context, false),
                child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(_t('cancel'), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF475569))))))),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(onTap: () => Navigator.pop(context, true),
                child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]), borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: Center(child: Text(_t('delete'), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)))))),
            ]),
          ]),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await _db.from('preventif_maintenance').delete().eq('id_pm', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('deleted')), backgroundColor: CupertinoColors.activeGreen));
        _loadAll();
      }
    } catch (e) { debugPrint('PM delete error: $e'); }
  }

  void _showRangePicker() async {
    await showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _PC.primary.withValues(alpha: 0.2), width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _PC.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.date_range_rounded, color: _PC.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.lang == 'EN' ? 'Select Period' : widget.lang == 'ZH' ? '选择期间' : 'Pilih Periode',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: _PC.primary))),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          ..._PmRange.values.where((r) => r != _PmRange.custom).map((r) {
            final sel = _range == r;
            return GestureDetector(onTap: () { Navigator.pop(ctx); setState(() => _range = r); _loadTableData(); },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? _PC.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _PC.primary : const Color(0xFFE2E8F0), width: sel ? 1.8 : 1)),
                child: Row(children: [
                  Expanded(child: Text(r.label(widget.lang), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? _PC.primaryDark : const Color(0xFF1E293B)))),
                  if (sel) const Icon(Icons.check_circle_rounded, color: _PC.primary, size: 20),
                ]),
              ));
          }),
          GestureDetector(
            onTap: () { Navigator.pop(ctx); _showCustomRangePicker(); },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _range == _PmRange.custom ? _PC.primaryLight : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _range == _PmRange.custom ? _PC.primary : const Color(0xFFE2E8F0), width: _range == _PmRange.custom ? 1.8 : 1)),
              child: Row(children: [
                const Icon(Icons.edit_calendar_rounded, size: 16, color: _PC.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _range == _PmRange.custom && _customStart != null && _customEnd != null
                      ? '${DateFormat('MMM yyyy').format(_customStart!)} – ${DateFormat('MMM yyyy').format(_customEnd!)}'
                      : (widget.lang == 'EN' ? 'Custom (Start – End)' : widget.lang == 'ZH' ? '自定义（开始-结束）' : 'Kustom (Mulai – Selesai)'),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _range == _PmRange.custom ? _PC.primaryDark : const Color(0xFF1E293B)))),
                if (_range == _PmRange.custom) const Icon(Icons.check_circle_rounded, color: _PC.primary, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    ));
  }

  void _showCustomRangePicker() async {
    final now = DateTime.now();
    DateTime tempStart = _customStart ?? DateTime(now.year, now.month, 1);
    DateTime tempEnd   = _customEnd   ?? DateTime(now.year, now.month, 1);

    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
      Widget monthYearField({
        required String label,
        required IconData labelIcon,
        required DateTime value,
        required ValueChanged<int> onMonthChanged,
        required ValueChanged<int> onYearChanged,
      }) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(labelIcon, size: 13, color: _PC.primary),
              const SizedBox(width: 5),
              Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _PC.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _PC.primary.withValues(alpha: 0.35)),
              ),
              child: Row(children: [
                Icon(Icons.event_rounded, size: 17, color: _PC.primary),
                const SizedBox(width: 10),
                Expanded(child: DropdownButton<int>(
                  isExpanded: true, value: value.month, underline: const SizedBox.shrink(),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0C3A8C)),
                  items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m,
                    child: Text(DateFormat('MMMM').format(DateTime(2024, m, 1)), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (m) { if (m != null) onMonthChanged(m); },
                )),
                const SizedBox(width: 8),
                Expanded(child: DropdownButton<int>(
                  isExpanded: true, value: value.year, underline: const SizedBox.shrink(),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0C3A8C)),
                  items: List.generate(6, (i) => now.year - 4 + i).map((y) => DropdownMenuItem(value: y,
                    child: Text('$y', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (y) { if (y != null) onYearChanged(y); },
                )),
              ]),
            ),
          ],
        );
      }

      final monthsDiff = (tempEnd.year - tempStart.year) * 12 + (tempEnd.month - tempStart.month);
      final isValid = monthsDiff >= 0 && monthsDiff < 12;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _PC.primary.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _PC.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_calendar_rounded, color: _PC.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.lang == 'EN' ? 'Custom Period' : widget.lang == 'ZH' ? '自定义期间' : 'Periode Kustom',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: _PC.textPrimary),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                  ),
                ),
              ]),
              const SizedBox(height: 18),

              monthYearField(
                label: widget.lang == 'EN' ? 'Start' : widget.lang == 'ZH' ? '开始' : 'Mulai',
                labelIcon: Icons.play_circle_outline_rounded,
                value: tempStart,
                onMonthChanged: (m) => setLocal(() => tempStart = DateTime(tempStart.year, m, 1)),
                onYearChanged: (y) => setLocal(() => tempStart = DateTime(y, tempStart.month, 1)),
              ),
              const SizedBox(height: 16),
              monthYearField(
                label: widget.lang == 'EN' ? 'End' : widget.lang == 'ZH' ? '结束' : 'Selesai',
                labelIcon: Icons.flag_circle_rounded,
                value: tempEnd,
                onMonthChanged: (m) => setLocal(() => tempEnd = DateTime(tempEnd.year, m, 1)),
                onYearChanged: (y) => setLocal(() => tempEnd = DateTime(y, tempEnd.month, 1)),
              ),
              if (!isValid)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.lang == 'EN' ? 'Range must be between 0–12 months' : widget.lang == 'ZH' ? '范围必须在0-12个月之间' : 'Rentang maksimal 12 bulan',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isValid ? () {
                    Navigator.pop(ctx);
                    setState(() { _range = _PmRange.custom; _customStart = tempStart; _customEnd = tempEnd; });
                    _loadTableData();
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: _PC.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(widget.lang == 'EN' ? 'Apply' : widget.lang == 'ZH' ? '应用' : 'Terapkan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }));
  }

  void _showBagianPicker() async {
    final result = await showKtsSectionLocationPicker(
      context,
      lang: widget.lang,
      accentColor: _PC.primary,
    );
    if (result == null) return;
    setState(() => _filterBagian = result.isAllSections ? null : result.sectionName);
    _loadTableData();
  }

  void _showKasieDetail(String kasieId, String kasieNama, String bagian) async {
    final months = _getMonths();
    final start  = months.first;
    final end    = DateTime(months.last.year, months.last.month + 1, 0, 23, 59, 59);
    try {
      final res = await _db.from('preventif_maintenance')
          .select('*, pelapor:id_user(nama, gambar_user)')
          .eq('bagian', bagian)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);
      final records = List<Map<String, dynamic>>.from(res);
      if (!mounted) return;
      final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
      await showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.92,
          builder: (__, sc) => Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(children: [
              Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.engineering_rounded, color: _PC.primary, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(kasieNama, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    Text(bagian, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(20)),
                    child: Text('${records.length} laporan', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _PC.primary))),
                ]),
              ),
              const Divider(height: 1),
              Expanded(child: records.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.engineering_outlined, size: 48, color: _PC.primaryLight),
                    const SizedBox(height: 8),
                    Text(_t('tidak_ada'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ]))
                : ListView.separated(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final r = records[i];
                      final dateStr = r['created_at'] != null
                          ? DateFormat('dd MMM yyyy, HH:mm', locale).format(DateTime.parse(r['created_at']).toLocal())
                          : '-';
                      final pelapor = r['pelapor'] as Map<String, dynamic>?;
                      return Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _PC.border, width: 1.2),
                          boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (r['file_pm'] != null && r['file_name_pm'] != null)
                            GestureDetector(
                              onTap: () => _openFile(r['file_pm'], r['file_name_pm']),
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _PC.border, width: 1.2)),
                                child: Row(children: [
                                  Icon(CupertinoIcons.doc_fill, size: 16, color: _PC.primary),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(
                                    r['file_name_pm'] ?? '-',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                                      color: _PC.primary, decoration: TextDecoration.underline),
                                    overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 6),
                                  const Icon(CupertinoIcons.arrow_up_right_square, size: 14, color: _PC.primary),
                                ]),
                              )),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(r['judul_pm'] ?? '-', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(8)),
                                  child: Text(r['bagian'] ?? '-', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _PC.primary))),
                              ]),
                              if ((r['deskripsi_pm'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(r['deskripsi_pm'], style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.5)),
                              ],
                              const SizedBox(height: 10),
                              Row(children: [
                                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                                if (pelapor != null) ...[
                                  const SizedBox(width: 10),
                                  const Icon(Icons.person_outline, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(pelapor['nama'] ?? '-', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                                ],
                              ]),
                            ]),
                          ),
                        ]),
                      );
                    },
                  )),
            ]),
          ),
        ),
      );
    } catch (e) { debugPrint('PM kasie detail error: $e'); }
  }

  String _deadlineInfoText() {
    final now = DateTime.now();
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final bulanNow = DateFormat('MMMM yyyy', locale).format(now);
    if (widget.lang == 'EN') {
      return 'PM report deadline for $bulanNow is the 10th. After that, it will be marked as late.';
    } else if (widget.lang == 'ZH') {
      return '$bulanNow 的PM报告截止日期是10日，之后将自动标记为迟到。';
    }
    return 'Batas pelaporan PM bulan $bulanNow adalah tanggal 10. Lewat dari tanggal itu otomatis tercatat terlambat.';
  }

  Widget _buildDeadlineInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_rounded, size: 18, color: Color(0xFFD97706)),
        const SizedBox(width: 10),
        Expanded(child: Text(_deadlineInfoText(),
          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF92400E), height: 1.4))),
      ]),
    );
  }

  Widget _buildAddButton() {
    if (_currentUserJabatan != 3) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => PmFormScreen(lang: widget.lang)));
        if (result == true) _loadAll();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha:0.4), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.25), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 30)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('add'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text(_t('add_sub'), style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha:0.85))),
          ])),
          const Icon(CupertinoIcons.chevron_right, color: Colors.white, size: 18),
        ]),
      ),
    );
  }

  Widget _buildChartToggle() {
    final months = _getMonths();
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    String rangeLabel;
    if (months.length == 1) {
      rangeLabel = DateFormat('MMMM yyyy', locale).format(months.first);
    } else {
      rangeLabel = '${DateFormat('MMM', locale).format(months.first)} – ${DateFormat('MMM yyyy', locale).format(months.last)}';
    }
    return GestureDetector(
      onTap: () => setState(() => _chartExpanded = !_chartExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _PC.primary.withValues(alpha:0.45), width: 1.2),
          boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.07), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          const Icon(Icons.bar_chart_rounded, size: 16, color: _PC.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('${_t('grafik')} ${_t('title')} ($rangeLabel)',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _PC.primaryDark))),
          AnimatedRotation(turns: _chartExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _PC.primary)),
        ]),
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
  ]);

  Widget _buildChart() {
    if (_loadingTable) {
      return Shimmer.fromColors(baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
        child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))));
    }
    final filtered = _tableRows; // SUDAH DIFILTER (bagian + status) DI _loadTableData
    if (filtered.isEmpty) return _emptyBox();

    final xMax = _getMonths().length;
    final xTicks = List.generate(xMax + 1, (i) => i);
    const double labelW = 72.0;
    const double barH   = 22.0;
    const double rowVPad = 4.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.primaryLight, width: 1.2),
        boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.07), blurRadius: 10, offset: const Offset(0, 3))]),
      child: LayoutBuilder(builder: (_, constraints) {
        final barAreaW = constraints.maxWidth - labelW - 8;
        final List<double> tickX = xTicks.map((v) => xMax > 0 ? (v / xMax) * barAreaW : 0.0).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: labelW + 8),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _legendDot(_PC.barColor, widget.lang == 'EN' ? 'On time' : widget.lang == 'ZH' ? '准时' : 'Tepat waktu'),
              const SizedBox(width: 10),
              _legendDot(const Color(0xFFEF4444), widget.lang == 'EN' ? 'Late' : widget.lang == 'ZH' ? '迟到' : 'Terlambat'),
            ])),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            SizedBox(width: labelW + 8),
            SizedBox(width: barAreaW, height: 16,
              child: Stack(clipBehavior: Clip.none, children: List.generate(xTicks.length, (i) {
                double left = tickX[i];
                if (i == xTicks.length - 1) left -= 8;
                return Positioned(left: left, top: 0, child: Text('${xTicks[i]}',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  textAlign: i == 0 ? TextAlign.left : i == xTicks.length - 1 ? TextAlign.right : TextAlign.center));
              }))),
          ]),
          Row(children: [SizedBox(width: labelW + 8), Container(width: barAreaW, height: 1, color: const Color(0xFFE2E8F0))]),
          const SizedBox(height: 4),
          ...filtered.map((row) {
            final onTimeCount = row.total - row.lateCount;
            final onTimeFrac  = xMax > 0 ? onTimeCount / xMax : 0.0;
            final lateFrac    = xMax > 0 ? row.lateCount / xMax : 0.0;
            final onTimeWidth = (barAreaW * onTimeFrac).clamp(0.0, barAreaW);
            final lateWidth   = (barAreaW * lateFrac).clamp(0.0, barAreaW);
            final isZero      = row.total == 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: rowVPad),
              child: SizedBox(height: barH, child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(width: labelW, child: Text(row.kasieNama,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: isZero ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
                const SizedBox(width: 8),
                Expanded(child: CustomPaint(
                  painter: _PmBarPainter(tickX: tickX, onTimeWidth: onTimeWidth, lateWidth: lateWidth, barH: barH, barVPad: rowVPad * 0.5, isZero: isZero),
                  child: const SizedBox.expand())),
              ])),
            );
          }),
          const SizedBox(height: 4),
          Row(children: [SizedBox(width: labelW + 8), Container(width: barAreaW, height: 1, color: const Color(0xFFE2E8F0))]),
        ]);
      }),
    );
  }

  Widget _buildFilterBar() {
    String rangeLabel = _range.label(widget.lang);
    if (_range == _PmRange.custom && _customStart != null && _customEnd != null) {
      rangeLabel = '${DateFormat('MMM yy').format(_customStart!)} – ${DateFormat('MMM yy').format(_customEnd!)}';
    }
    return Column(children: [
      Row(children: [
        Expanded(child: _buildRangeFilterButton(rangeLabel)),
        const SizedBox(width: 8),
        Expanded(child: _filterBtn(
          label: _filterBagian != null ? _displaySectionName(_filterBagian!) : _t('semua_bagian'),
          active: _filterBagian != null,
          icon: Icons.grid_view_rounded,
          onTap: _showBagianPicker,
          onReset: _filterBagian != null
              ? () { setState(() => _filterBagian = null); _loadTableData(); }
              : null,
          activeColor: const Color(0xFF1D72F3),
        )),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _filterBtn(
          label: _lateFilter.label(widget.lang),
          active: _lateFilter != _PmLateFilter.all,
          icon: _lateFilter.icon,
          onTap: _showLateFilterPicker,
          onReset: _lateFilter != _PmLateFilter.all
              ? () { setState(() => _lateFilter = _PmLateFilter.all); _loadTableData(); }
              : null,
          activeColor: _lateFilter.color,
        )),
      ]),
    ]);
  }

  // Tombol filter periode: putih dengan teks/ikon biru selalu.
  // Default (3 Bulan) → panah bawah. Selain default → tombol reset X merah.
  Widget _buildRangeFilterButton(String rangeLabel) {
    final isActive = _range != _PmRange.threeMonths;
    return GestureDetector(
      onTap: _showRangePicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _PC.primary, width: 1.5),
          boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.date_range_rounded, size: 15, color: _PC.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(rangeLabel,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _PC.primary)),
                ),
              ],
            ),
          ),
          if (isActive)
            GestureDetector(
              onTap: () {
                setState(() => _range = _PmRange.threeMonths);
                _loadTableData();
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
              ),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, color: _PC.primary, size: 18),
        ]),
      ),
    );
  }

  void _showLateFilterPicker() async {
    await showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _PC.primary.withValues(alpha: 0.2), width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _PC.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.flag_circle_rounded, color: _PC.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.lang == 'EN' ? 'Report Status' : widget.lang == 'ZH' ? '报告状态' : 'Status Laporan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: _PC.primary))),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          ..._PmLateFilter.values.map((f) {
            final sel = _lateFilter == f;
            final icon = f.icon;
            final color = f.color;
            return GestureDetector(onTap: () { Navigator.pop(ctx); setState(() => _lateFilter = f); _loadTableData(); },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? color.withValues(alpha: 0.10) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? color : const Color(0xFFE2E8F0), width: sel ? 1.8 : 1)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(f.label(widget.lang), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? color : const Color(0xFF1E293B)))),
                  if (sel) Icon(Icons.check_circle_rounded, color: color, size: 20),
                ]),
              ));
          }),
          const SizedBox(height: 12),
        ]),
      ),
    ));
  }

  Widget _filterBtn({
    required String label,
    required VoidCallback onTap,
    bool active = false,
    IconData icon = Icons.keyboard_arrow_down_rounded,
    VoidCallback? onReset,
    Color activeColor = _PC.primary,
  }) {
    final color = active ? activeColor : _PC.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? activeColor : _PC.primaryLight, width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha:0.12), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          if (active && onReset != null)
            GestureDetector(
              onTap: onReset,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
              ),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
        ]),
      ),
    );
  }

  void _showLateReason(_PmKasieRow row, int monthIdx, DateTime month) async {
    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final reason = row.alasan[monthIdx];
    await showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.priority_high_rounded, color: Color(0xFFEF4444), size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '${row.kasieNama} • ${DateFormat('MMMM yyyy', locale).format(month)}',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
          ]),
          const SizedBox(height: 6),
          Text(widget.lang == 'EN' ? 'Reported late' : widget.lang == 'ZH' ? '逾期报告' : 'Laporan terlambat',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12)),
            child: Text(
              (reason == null || reason.isEmpty)
                  ? (widget.lang == 'EN' ? 'No reason provided' : widget.lang == 'ZH' ? '未提供原因' : 'Tidak ada alasan')
                  : reason,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.lang == 'EN' ? 'Close' : widget.lang == 'ZH' ? '关闭' : 'Tutup'))),
        ]),
      ),
    ));
  }

  Widget _buildTable() {
    if (_loadingTable) {
      return Shimmer.fromColors(baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
        child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))));
    }
    final rows = _tableRows; // SUDAH DIFILTER (bagian + status) DI _loadTableData
    if (rows.isEmpty) return _emptyBox();

    final months = _getMonths();
    final locale  = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final bulanLabels3 = months.map((m) => DateFormat('MMM', locale).format(m)).toList();
    final int grandTotal = rows.fold(0, (s, r) => s + r.total);

    const double leftW   = 150.0;
    const double monthW  = 46.0;
    const double totalW  = 56.0;
    const double rowH    = 40.0;

    Color statusColor(_PmStatus s) {
      switch (s) {
        case _PmStatus.late:    return const Color(0xFFEF4444);
        case _PmStatus.onTime:  return _PC.barColor;
        case _PmStatus.none:    return const Color(0xFFCBD5E1);
      }
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.primaryLight, width: 1.5),
        boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 3))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // KOLOM KIRI TETAP (BAGIAN + KASIE) — SELALU TERLIHAT
          SizedBox(width: leftW, child: Column(children: [
            Container(height: rowH, color: _PC.primaryLight, padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Expanded(flex: 5, child: Align(alignment: Alignment.centerLeft, child: Text(_t('bagian'), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _PC.textSec)))),
                Expanded(flex: 6, child: Align(alignment: Alignment.centerLeft, child: Text(_t('kasie'), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _PC.textSec)))),
              ])),
            ...rows.asMap().entries.map((e) {
              final idx = e.key; final row = e.value;
              return Container(
                height: rowH,
                decoration: BoxDecoration(border: idx > 0 ? const Border(top: BorderSide(color: _PC.divider)) : null),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  Expanded(flex: 5, child: Text(row.bagian.isEmpty ? '-' : _displaySectionName(row.bagian),
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: row.total > 0 ? _PC.textPrimary : const Color(0xFFCBD5E1)), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 6, child: GestureDetector(
                    onTap: _currentUserJabatan == 1 ? () => _showKasieDetail(row.kasieId, row.kasieNama, row.bagian) : null,
                    child: Text(row.kasieNama,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700,
                        color: row.total > 0 ? (_currentUserJabatan == 1 ? _PC.primary : _PC.textPrimary) : const Color(0xFFCBD5E1),
                        decoration: row.total > 0 && _currentUserJabatan == 1 ? TextDecoration.underline : TextDecoration.none),
                      overflow: TextOverflow.ellipsis))),
                ]),
              );
            }),
            Container(height: rowH, decoration: const BoxDecoration(color: Color(0xFFEFF6FF), border: Border(top: BorderSide(color: _PC.divider, width: 1.5))),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(alignment: Alignment.centerLeft, child: Text(widget.lang == 'EN' ? 'Total' : widget.lang == 'ZH' ? '合计' : 'Total',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _PC.textPrimary)))),
          ])),
          Container(width: 1, color: _PC.divider),
          // KOLOM KANAN: FILL JIKA RUANG TERSISA MASIH LEBAR, SCROLL JIKA SEMPIT
          Expanded(child: LayoutBuilder(builder: (_, rightConstraints) {
            final availW = rightConstraints.maxWidth;
            final neededW = monthW * months.length + totalW;
            final effMonthW = neededW < availW && months.isNotEmpty
                ? (availW - totalW) / months.length
                : monthW;
            final totalContentW = neededW < availW ? availW : neededW;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: neededW < availW ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
              child: SizedBox(width: totalContentW, child: Column(children: [
              Container(height: rowH, color: _PC.primaryLight,
                child: Row(children: [
                  ...bulanLabels3.map((lbl) => SizedBox(width: effMonthW, child: Center(child: Text(lbl, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _PC.textSec))))),
                  SizedBox(width: totalW, child: Center(child: Text(_t('total'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _PC.primaryDark)))),
                ])),
              ...rows.asMap().entries.map((e) {
                final idx = e.key; final row = e.value;
                return Container(
                  height: rowH,
                  decoration: BoxDecoration(border: idx > 0 ? const Border(top: BorderSide(color: _PC.divider)) : null),
                  child: Row(children: [
                    ...List.generate(months.length, (mi) {
                      final status = row.bulanan[mi] ?? _PmStatus.none;
                      final isLate = status == _PmStatus.late;
                      return SizedBox(width: effMonthW, child: Center(child: GestureDetector(
                        onTap: isLate ? () => _showLateReason(row, mi, months[mi]) : null,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: status != _PmStatus.none ? statusColor(status).withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: isLate ? Border.all(color: const Color(0xFFEF4444), width: 1.2) : null),
                          child: Center(child: status == _PmStatus.none
                            ? const Text('?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1)))
                            : Icon(isLate ? Icons.priority_high_rounded : Icons.check_rounded, size: 15, color: statusColor(status))),
                        ))));
                    }),
                    SizedBox(width: totalW, child: Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: row.total > 0 ? _PC.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                      child: Text('${row.total}', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: row.total > 0 ? Colors.white : const Color(0xFFCBD5E1)))))),
                  ]),
                );
              }),
              Container(height: rowH, decoration: const BoxDecoration(color: Color(0xFFEFF6FF), border: Border(top: BorderSide(color: _PC.divider, width: 1.5))),
                child: Row(children: [
                  ...List.generate(months.length, (mi) {
                    final colLate   = rows.fold(0, (s, r) => s + ((r.bulanan[mi] ?? _PmStatus.none) == _PmStatus.late ? 1 : 0));
                    final colOnTime = rows.fold(0, (s, r) => s + ((r.bulanan[mi] ?? _PmStatus.none) == _PmStatus.onTime ? 1 : 0));
                    final colTotal  = colLate + colOnTime;
                    return SizedBox(width: effMonthW, child: Center(child: Text('$colTotal',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colLate > 0 ? const Color(0xFFEF4444) : _PC.primaryDark))));
                  }),
                  SizedBox(width: totalW, child: Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: _PC.primary, borderRadius: BorderRadius.circular(8)),
                    child: Text('$grandTotal', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white))))),
                ])),
            ])),
            );
          })),
        ]),
      ),
    );
  }

  Widget _buildMyRecords() {
    if (_loadingRecords) {
      return Shimmer.fromColors(baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
        child: Column(children: List.generate(2, (_) => Container(margin: const EdgeInsets.only(bottom: 12), height: 120,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))))));
    }
    if (_myRecords.isEmpty) return const SizedBox.shrink();

    final locale = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _PC.barColor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.list_alt_rounded, size: 14, color: _PC.barColor)),
        const SizedBox(width: 8),
        Text(_t('my_records'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _PC.barColor)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _PC.barColor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(20)),
          child: Text('${_myRecords.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _PC.barColor)),
        ),
      ]),
      const SizedBox(height: 10),
      ..._myRecords.map((r) {
        final dateStr = r['created_at'] != null
            ? DateFormat('dd MMM yyyy', locale).format(DateTime.parse(r['created_at']).toLocal()) : '-';
        final isLate = r['is_late'] == true;
        final bulanParsed = DateTime.tryParse(r['bulan_pm']?.toString() ?? '');
        final bulanStr = bulanParsed != null ? DateFormat('MMMM yyyy', locale).format(bulanParsed) : '-';
        final statusColor = isLate ? const Color(0xFFEF4444) : _PC.barColor;
        final statusLabel = isLate
            ? (widget.lang == 'EN' ? 'Late' : widget.lang == 'ZH' ? '迟到' : 'Terlambat')
            : (widget.lang == 'EN' ? 'On Time' : widget.lang == 'ZH' ? '准时' : 'Tepat Waktu');
        final statusIcon = isLate ? Icons.priority_high_rounded : Icons.check_circle_rounded;
        final alasan = r['alasan_terlambat']?.toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _PC.border, width: 1.4),
            boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.07), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // STRIP STATUS + BULAN PENGAJUAN (INFO PALING PENTING DITARUH PALING ATAS)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.2), width: 1)),
              ),
              child: Row(children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(statusLabel, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800, color: statusColor)),
                const Spacer(),
                Icon(Icons.calendar_month_rounded, size: 13, color: statusColor.withValues(alpha: 0.85)),
                const SizedBox(width: 4),
                Text(bulanStr, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
              ]),
            ),

            if (r['file_pm'] != null && r['file_name_pm'] != null)
              GestureDetector(
                onTap: () => _openFile(r['file_pm'], r['file_name_pm']),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _PC.border, width: 1.2)),
                  child: Row(children: [
                    Icon(CupertinoIcons.doc_fill, size: 16, color: _PC.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      r['file_name_pm'] ?? '-',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                        color: _PC.primary, decoration: TextDecoration.underline),
                      overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    const Icon(CupertinoIcons.arrow_up_right_square, size: 14, color: _PC.primary),
                  ]),
                )),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['judul_pm'] ?? '-', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.grid_view_rounded, size: 11, color: _PC.primary),
                      const SizedBox(width: 4),
                      Text(
                        (r['bagian'] == null || (r['bagian'] as String).isEmpty) ? '-' : _displaySectionName(r['bagian']),
                        style: GoogleFonts.inter(fontSize: 11, color: _PC.primary, fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                  if ((r['deskripsi_pm'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(r['deskripsi_pm'], style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                  if (isLate && alasan != null && alasan.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.info_rounded, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(alasan, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF991B1B), height: 1.4))),
                      ]),
                    ),
                  ],
                ])),
              ]),
            ),
            Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(child: Text(
                  widget.lang == 'EN' ? 'Submitted $dateStr' : widget.lang == 'ZH' ? '提交于 $dateStr' : 'Dilaporkan $dateStr',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis)),
                // EDIT BUTTON
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PmEditScreen(lang: widget.lang, existingData: r)));
                    if (result == true) _loadAll();
                  },
                  child: Container(width: 32, height: 32, decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: _PC.primary.withValues(alpha:0.25), width: 1)),
                    child: const Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 15, color: _PC.primary)),
                ),
                const SizedBox(width: 8),
                // DELETE BUTTON
                GestureDetector(
                  onTap: () => _deleteRecord(r['id_pm'].toString()),
                  child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha:0.25), width: 1)),
                    child: const Icon(CupertinoIcons.trash, size: 15, color: Color(0xFFEF4444))),
                ),
              ]),
            ),
          ]),
        );
      }),
    ]);
  }

  Widget _emptyBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _PC.primaryLight, width: 1.5)),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bar_chart_outlined, size: 40, color: Colors.blue.shade100),
        const SizedBox(height: 8),
        Text(_t('tidak_ada'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PC.bg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(CupertinoIcons.back, color: _PC.primary), onPressed: () => Navigator.pop(context)),
        title: Text(_t('title'), style: GoogleFonts.inter(color: _PC.primary, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [IconButton(onPressed: _loadAll, icon: const Icon(CupertinoIcons.refresh, color: _PC.primary))],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: _PC.border, height: 1)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: _PC.primary, backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // INFO DEADLINE
            _buildDeadlineInfo(),

            // ADD BUTTON
            _buildAddButton(),
            const SizedBox(height: 20),

            // CHART TOGGLE
            _buildChartToggle(),
            const SizedBox(height: 8),

            // COLLAPSIBLE CHART
            AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
              child: _chartExpanded ? Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildChart()) : const SizedBox.shrink()),

            // FILTER BAR
            _buildFilterBar(),
            const SizedBox(height: 14),

            // KASIE TABLE
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _PC.barColor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.engineering_outlined, size: 14, color: _PC.barColor)),
              const SizedBox(width: 8),
              Text('${_t('title')} – ${_t('kasie')}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _PC.barColor)),
            ]),
            const SizedBox(height: 8),
            _buildTable(),
            const SizedBox(height: 24),

            // RECORD USER CARD
            _buildMyRecords(),
          ]),
        ),
      ),
    );
  }
}

class _PmBarPainter extends CustomPainter {
  final List<double> tickX;
  final double onTimeWidth;
  final double lateWidth;
  final double barH;
  final double barVPad;
  final bool isZero;
  const _PmBarPainter({required this.tickX, required this.onTimeWidth, required this.lateWidth, required this.barH, required this.barVPad, required this.isZero});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
    for (int i = 1; i < tickX.length; i++) { canvas.drawLine(Offset(tickX[i], 0), Offset(tickX[i], size.height), gridPaint); }
    if (!isZero) {
      if (onTimeWidth > 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, barVPad, onTimeWidth, size.height - barVPad * 2), const Radius.circular(4)),
          Paint()..color = _PC.barColor);
      }
      if (lateWidth > 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(onTimeWidth, barVPad, lateWidth, size.height - barVPad * 2), const Radius.circular(4)),
          Paint()..color = const Color(0xFFEF4444));
      }
    }
  }

  @override
  bool shouldRepaint(_PmBarPainter old) => old.onTimeWidth != onTimeWidth || old.lateWidth != lateWidth || old.isZero != isZero;
}