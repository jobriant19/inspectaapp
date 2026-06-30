import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _currentUserId = _db.auth.currentUser?.id;
    _loadUserJabatan();
    _loadAll();
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

      dynamic kasieQuery = _db.from('User').select('id_user, nama, bagian_kasie').eq('id_jabatan', 3);
      if (_filterBagian != null) kasieQuery = kasieQuery.eq('bagian_kasie', _filterBagian!);
      final kasieRes  = List<Map<String, dynamic>>.from(await kasieQuery);
      if (kasieRes.isEmpty) { setState(() { _tableRows = []; _loadingTable = false; }); return; }

      final start = months.first;
      final end   = DateTime(months.last.year, months.last.month + 1, 0);

      // PERIODE SEKARANG BERBASIS bulan_pm (BUKAN created_at)
      final pmRes = List<Map<String, dynamic>>.from(
        await _db.from('preventif_maintenance')
            .select('id_user, bagian, bulan_pm, alasan_terlambat, is_late')
            .gte('bulan_pm', DateFormat('yyyy-MM-dd').format(start))
            .lte('bulan_pm', DateFormat('yyyy-MM-dd').format(end)),
      );

      // MAPPING: BAGIAN -> INDEX BULAN -> STATUS / ALASAN (is_late LANGSUNG DARI DB)
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

      var rows = kasieRes.map((k) {
        final kasieId   = k['id_user']?.toString() ?? '';
        final kasieNama = k['nama']?.toString() ?? '-';
        final bagian    = (k['bagian_kasie'] as String?)?.trim() ?? '';
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _PC.primaryLight, width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            decoration: const BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              const Icon(Icons.date_range_rounded, color: _PC.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.lang == 'EN' ? 'Select Period' : widget.lang == 'ZH' ? '选择期间' : 'Pilih Periode',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _PC.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18, color: _PC.textSec), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
          ),
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
                  Expanded(child: Text(r.label(widget.lang), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? _PC.primaryDark : const Color(0xFF1E293B)))),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _range == _PmRange.custom ? _PC.primaryDark : const Color(0xFF1E293B)))),
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
      Widget monthYearPicker(String title, DateTime value, ValueChanged<DateTime> onChanged) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: _PC.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _PC.textSec)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: DropdownButton<int>(
                isExpanded: true, value: value.month, underline: const SizedBox.shrink(),
                items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m,
                  child: Text(DateFormat('MMMM').format(DateTime(2024, m, 1)), style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (m) { if (m != null) onChanged(DateTime(value.year, m, 1)); },
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButton<int>(
                isExpanded: true, value: value.year, underline: const SizedBox.shrink(),
                items: List.generate(6, (i) => now.year - 4 + i).map((y) => DropdownMenuItem(value: y,
                  child: Text('$y', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (y) { if (y != null) onChanged(DateTime(y, value.month, 1)); },
              )),
            ]),
          ]),
        );
      }

      final monthsDiff = (tempEnd.year - tempStart.year) * 12 + (tempEnd.month - tempStart.month);
      final isValid = monthsDiff >= 0 && monthsDiff < 12;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.edit_calendar_rounded, color: _PC.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.lang == 'EN' ? 'Custom Period' : widget.lang == 'ZH' ? '自定义期间' : 'Periode Kustom',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _PC.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _PC.textSec), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            const SizedBox(height: 8),
            monthYearPicker(widget.lang == 'EN' ? 'Start' : widget.lang == 'ZH' ? '开始' : 'Mulai', tempStart, (d) => setLocal(() => tempStart = d)),
            monthYearPicker(widget.lang == 'EN' ? 'End' : widget.lang == 'ZH' ? '结束' : 'Selesai', tempEnd, (d) => setLocal(() => tempEnd = d)),
            if (!isValid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.lang == 'EN' ? 'Range must be between 0–12 months' : widget.lang == 'ZH' ? '范围必须在0-12个月之间' : 'Rentang maksimal 12 bulan',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: isValid ? () {
                  Navigator.pop(ctx);
                  setState(() { _range = _PmRange.custom; _customStart = tempStart; _customEnd = tempEnd; });
                  _loadTableData();
                } : null,
                style: ElevatedButton.styleFrom(backgroundColor: _PC.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(widget.lang == 'EN' ? 'Apply' : widget.lang == 'ZH' ? '应用' : 'Terapkan'),
              )),
            ),
          ]),
        ),
      );
    }));
  }

  void _showBagianPicker() async {
    final items = [null, ...kPmBagianList];
    await showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _PC.primaryLight, width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            decoration: const BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              const Icon(Icons.grid_view_rounded, color: _PC.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(_t('pilih_bagian'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _PC.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18, color: _PC.textSec), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
          ),
          Flexible(child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i]; final lbl = item ?? _t('semua_bagian'); final sel = item == _filterBagian;
              return InkWell(onTap: () { Navigator.pop(ctx); setState(() => _filterBagian = item); _loadTableData(); },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: sel ? _PC.primaryLight : Colors.white, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? _PC.primary : const Color(0xFFE2E8F0), width: sel ? 1.5 : 1)),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: sel ? _PC.primary : _PC.primaryLight, borderRadius: BorderRadius.circular(9)),
                      child: Center(child: Text(lbl.isNotEmpty ? lbl[0].toUpperCase() : '#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: sel ? Colors.white : _PC.primaryDark)))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(lbl, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? _PC.primaryDark : const Color(0xFF1E293B)))),
                    if (sel) const Icon(Icons.check_circle_rounded, color: _PC.primary, size: 18),
                  ]),
                ));
            },
          )),
        ]),
      ),
    ));
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
                    Text(kasieNama, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                    Text(bagian, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
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
          Expanded(child: Text('${_t('grafik')} ${_t('title')} – $rangeLabel',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _PC.primaryDark))),
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
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isZero ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
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
      rangeLabel = '${DateFormat('MMM yy').format(_customStart!)}–${DateFormat('MMM yy').format(_customEnd!)}';
    }
    return Column(children: [
      Row(children: [
        Expanded(child: _filterBtn(label: rangeLabel, active: true, icon: Icons.date_range_rounded, onTap: _showRangePicker)),
        const SizedBox(width: 8),
        Expanded(child: _filterBtn(label: _filterBagian ?? _t('semua_bagian'), active: _filterBagian != null, icon: Icons.grid_view_rounded, onTap: _showBagianPicker)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _filterBtn(
          label: _lateFilter.label(widget.lang),
          active: _lateFilter != _PmLateFilter.all,
          icon: Icons.flag_circle_rounded,
          onTap: _showLateFilterPicker)),
      ]),
    ]);
  }

  void _showLateFilterPicker() async {
    await showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _PC.primaryLight, width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            decoration: const BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              const Icon(Icons.flag_circle_rounded, color: _PC.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.lang == 'EN' ? 'Report Status' : widget.lang == 'ZH' ? '报告状态' : 'Status Laporan',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _PC.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18, color: _PC.textSec), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
          ),
          const SizedBox(height: 8),
          ..._PmLateFilter.values.map((f) {
            final sel = _lateFilter == f;
            Color dot;
            switch (f) {
              case _PmLateFilter.late:        dot = const Color(0xFFEF4444); break;
              case _PmLateFilter.onTime:      dot = _PC.barColor; break;
              case _PmLateFilter.notReported: dot = const Color(0xFFCBD5E1); break;
              case _PmLateFilter.all:         dot = _PC.primary; break;
            }
            return GestureDetector(onTap: () { Navigator.pop(ctx); setState(() => _lateFilter = f); _loadTableData(); },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? _PC.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _PC.primary : const Color(0xFFE2E8F0), width: sel ? 1.8 : 1)),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f.label(widget.lang), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? _PC.primaryDark : const Color(0xFF1E293B)))),
                  if (sel) const Icon(Icons.check_circle_rounded, color: _PC.primary, size: 20),
                ]),
              ));
          }),
          const SizedBox(height: 12),
        ]),
      ),
    ));
  }

  Widget _filterBtn({required String label, required VoidCallback onTap, bool active = false, IconData icon = Icons.keyboard_arrow_down_rounded}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? _PC.primary : Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _PC.primary : _PC.primaryLight, width: 1.5),
          boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.12), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? Colors.white : _PC.primary),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : _PC.primary), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: active ? Colors.white : _PC.primary),
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
                Expanded(flex: 5, child: Align(alignment: Alignment.centerLeft, child: Text(_t('bagian'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _PC.textSec)))),
                Expanded(flex: 6, child: Align(alignment: Alignment.centerLeft, child: Text(_t('kasie'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _PC.textSec)))),
              ])),
            ...rows.asMap().entries.map((e) {
              final idx = e.key; final row = e.value;
              return Container(
                height: rowH,
                decoration: BoxDecoration(border: idx > 0 ? const Border(top: BorderSide(color: _PC.divider)) : null),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  Expanded(flex: 5, child: Text(row.bagian.isEmpty ? '-' : row.bagian,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: row.total > 0 ? _PC.textPrimary : const Color(0xFFCBD5E1)), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 6, child: GestureDetector(
                    onTap: _currentUserJabatan == 1 ? () => _showKasieDetail(row.kasieId, row.kasieNama, row.bagian) : null,
                    child: Text(row.kasieNama,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
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
      ]),
      const SizedBox(height: 10),
      ..._myRecords.map((r) {
        final dateStr = r['created_at'] != null
            ? DateFormat('dd MMM yyyy', locale).format(DateTime.parse(r['created_at']).toLocal()) : '-';
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _PC.border, width: 1.4),
            boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.07), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(r['bagian'] ?? '-', style: GoogleFonts.inter(fontSize: 11, color: _PC.primary, fontWeight: FontWeight.w700))),
                  if ((r['deskripsi_pm'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(r['deskripsi_pm'], style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ])),
              ]),
            ),
            Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                const Spacer(),
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
              Text('${_t('title')} – ${_t('kasie')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _PC.barColor)),
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