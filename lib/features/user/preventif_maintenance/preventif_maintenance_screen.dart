import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

enum _PmRange { thisMonth, threeMonths, sixMonths }

extension _PmRangeExt on _PmRange {
  String label(String lang) {
    switch (this) {
      case _PmRange.thisMonth:    return lang == 'EN' ? 'This Month'  : lang == 'ZH' ? '本月'  : 'Bulan Ini';
      case _PmRange.threeMonths:  return lang == 'EN' ? '3 Months'    : lang == 'ZH' ? '3个月' : '3 Bulan';
      case _PmRange.sixMonths:    return lang == 'EN' ? '6 Months'    : lang == 'ZH' ? '6个月' : '6 Bulan';
    }
  }
  int get monthCount {
    switch (this) {
      case _PmRange.thisMonth:   return 1;
      case _PmRange.threeMonths: return 3;
      case _PmRange.sixMonths:   return 6;
    }
  }
}

class _PmKasieRow {
  final String kasieId;
  final String kasieNama;
  final String bagian;
  final Map<int, int> bulanan;
  final int total;
  const _PmKasieRow({
    required this.kasieId,
    required this.kasieNama,
    required this.bagian,
    required this.bulanan,
    required this.total,
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

  // ── State chart & filter ──
  bool _chartExpanded  = false;
  _PmRange _range      = _PmRange.threeMonths;
  String? _filterBagian;

  // ── State data ──
  bool _loadingTable    = false;
  bool _loadingRecords  = false;
  List<_PmKasieRow> _tableRows  = [];
  List<String>      _bulanLabels = [];
  List<Map<String, dynamic>> _myRecords = []; // semua record milik user

  @override
  void initState() {
    super.initState();
    _currentUserId = _db.auth.currentUser?.id;
    _loadAll();
  }

  // ── i18n ──
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

  // ────────────────────────────────────────────────────────────
  // FETCH
  // ────────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    await Future.wait([_loadTableData(), _loadMyRecords()]);
  }

  List<DateTime> _getMonths() {
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

      // Ambil semua kasie (id_jabatan = 3)
      dynamic kasieQuery = _db.from('User').select('id_user, nama, bagian_kasie').eq('id_jabatan', 3);
      if (_filterBagian != null) kasieQuery = kasieQuery.eq('bagian_kasie', _filterBagian!);
      final kasieRes  = List<Map<String, dynamic>>.from(await kasieQuery);
      if (kasieRes.isEmpty) { setState(() { _tableRows = []; _loadingTable = false; }); return; }

      final start = months.first;
      final end   = DateTime(months.last.year, months.last.month + 1, 0, 23, 59, 59);

      // Ambil semua PM dalam range
      final pmRes = List<Map<String, dynamic>>.from(
        await _db.from('preventif_maintenance')
            .select('id_user, bagian, created_at')
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String()),
      );

      // Buat mapping: bagian → set bulan index yang ada PM
      final Map<String, Set<int>> bagianMonthSet = {};
      for (final row in pmRes) {
        final bagian    = (row['bagian'] as String?)?.trim() ?? '';
        if (bagian.isEmpty) continue;
        final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
        if (createdAt == null) continue;
        for (int i = 0; i < months.length; i++) {
          final m = months[i];
          if (createdAt.year == m.year && createdAt.month == m.month) {
            bagianMonthSet.putIfAbsent(bagian, () => {}).add(i);
            break;
          }
        }
      }

      final rows = kasieRes.map((k) {
        final kasieId   = k['id_user']?.toString() ?? '';
        final kasieNama = k['nama']?.toString() ?? '-';
        final bagian    = (k['bagian_kasie'] as String?)?.trim() ?? '';
        final monthSet  = bagianMonthSet[bagian] ?? {};
        final bulanan   = <int, int>{for (int i = 0; i < months.length; i++) i: monthSet.contains(i) ? 1 : 0};
        return _PmKasieRow(kasieId: kasieId, kasieNama: kasieNama, bagian: bagian, bulanan: bulanan, total: monthSet.length);
      }).toList()
        ..sort((a, b) => b.total.compareTo(a.total));

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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))]),
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
                    boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
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

  // ────────────────────────────────────────────────────────────
  // PICKERS
  // ────────────────────────────────────────────────────────────
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
          ..._PmRange.values.map((r) {
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
          const SizedBox(height: 12),
        ]),
      ),
    ));
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

  // ────────────────────────────────────────────────────────────
  // SHOW DETAIL POPUP (klik nama kasie di tabel)
  // ────────────────────────────────────────────────────────────
  void _showKasieDetail(String kasieId, String kasieNama, String bagian) async {
    // Ambil semua record PM dari bagian tersebut
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
                          boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]),
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

  // ────────────────────────────────────────────────────────────
  // WIDGETS
  // ────────────────────────────────────────────────────────────

  Widget _buildAddButton() {
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
          boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 30)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_t('add'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text(_t('add_sub'), style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85))),
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
          border: Border.all(color: _PC.primary.withOpacity(0.45), width: 1.2),
          boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))]),
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

  Widget _buildChart() {
    if (_loadingTable) {
      return Shimmer.fromColors(baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
        child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))));
    }
    final filtered = _filterBagian != null ? _tableRows.where((r) => r.bagian == _filterBagian).toList() : _tableRows;
    if (filtered.isEmpty) return _emptyBox();

    final xMax = _range.monthCount;
    final xTicks = List.generate(xMax + 1, (i) => i);
    const double labelW = 72.0;
    const double barH   = 22.0;
    const double rowVPad = 4.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.primaryLight, width: 1.2),
        boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))]),
      child: LayoutBuilder(builder: (_, constraints) {
        final barAreaW = constraints.maxWidth - labelW - 8;
        final List<double> tickX = xTicks.map((v) => xMax > 0 ? (v / xMax) * barAreaW : 0.0).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            final frac     = xMax > 0 ? row.total / xMax : 0.0;
            final barWidth = (barAreaW * frac).clamp(0.0, barAreaW);
            final isZero   = row.total == 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: rowVPad),
              child: SizedBox(height: barH, child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(width: labelW, child: Text(row.kasieNama,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isZero ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
                const SizedBox(width: 8),
                Expanded(child: CustomPaint(
                  painter: _PmBarPainter(tickX: tickX, barWidth: barWidth, barH: barH, barVPad: rowVPad * 0.5, isZero: isZero),
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
    return Row(children: [
      _filterBtn(label: _range.label(widget.lang), active: true, icon: Icons.date_range_rounded, onTap: _showRangePicker),
      const SizedBox(width: 8),
      Expanded(child: _filterBtn(label: _filterBagian ?? _t('semua_bagian'), active: _filterBagian != null, icon: Icons.grid_view_rounded, onTap: _showBagianPicker)),
    ]);
  }

  Widget _filterBtn({required String label, required VoidCallback onTap, bool active = false, IconData icon = Icons.keyboard_arrow_down_rounded}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? _PC.primary : Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _PC.primary : _PC.primaryLight, width: 1.5),
          boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))]),
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

  Widget _buildTable() {
    if (_loadingTable) {
      return Shimmer.fromColors(baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
        child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))));
    }
    final rows = _filterBagian != null ? _tableRows.where((r) => r.bagian == _filterBagian).toList() : _tableRows;
    if (rows.isEmpty) return _emptyBox();

    final months = _getMonths();
    final locale  = widget.lang == 'ID' ? 'id_ID' : widget.lang == 'EN' ? 'en_US' : 'zh_CN';
    final bulanLabels3 = months.map((m) => DateFormat('MMM', locale).format(m)).toList();
    final List<int> colTotals = List.generate(_bulanLabels.length, (i) => rows.fold(0, (s, r) => s + (r.bulanan[i] ?? 0)));
    final int grandTotal = rows.fold(0, (s, r) => s + r.total);

    const int flexSection = 3;
    const int flexKasie   = 4;
    const int flexMonth   = 2;
    const int flexTotal   = 2;

    Widget hCell(String text, {int flex = 2, TextAlign align = TextAlign.left, Color? color}) =>
      Expanded(flex: flex, child: Text(text, textAlign: align,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color ?? _PC.textSec), overflow: TextOverflow.ellipsis));

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.primaryLight, width: 1.5),
        boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(children: [
        // HEADER
        Container(
          decoration: const BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            hCell(_t('bagian'), flex: flexSection),
            hCell(_t('kasie'),  flex: flexKasie),
            ...bulanLabels3.map((lbl) => hCell(lbl, flex: flexMonth, align: TextAlign.center)),
            hCell(_t('total'), flex: flexTotal, align: TextAlign.center, color: _PC.primaryDark),
          ]),
        ),
        // ROWS
        ...rows.asMap().entries.map((e) {
          final idx = e.key; final row = e.value;
          return Container(
            decoration: BoxDecoration(border: idx > 0 ? const Border(top: BorderSide(color: _PC.divider)) : null),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              // BAGIAN
              Expanded(flex: flexSection, child: Text(row.bagian.isEmpty ? '-' : row.bagian,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: row.total > 0 ? _PC.textPrimary : const Color(0xFFCBD5E1)), overflow: TextOverflow.ellipsis)),
              // KASIE — klik → popup
              Expanded(flex: flexKasie, child: GestureDetector(
                onTap: () => _showKasieDetail(row.kasieId, row.kasieNama, row.bagian),
                child: Text(row.kasieNama,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: row.total > 0 ? _PC.primary : const Color(0xFFCBD5E1),
                    decoration: row.total > 0 ? TextDecoration.underline : TextDecoration.none),
                  overflow: TextOverflow.ellipsis),
              )),
              // PER BULAN
              ...List.generate(_bulanLabels.length, (mi) {
                final val = row.bulanan[mi] ?? 0;
                final isNull = val == 0;
                return Expanded(flex: flexMonth, child: Center(child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(color: !isNull ? _PC.barColor.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text(isNull ? '?' : '$val',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: !isNull ? _PC.barColor : const Color(0xFFCBD5E1)))))));
              }),
              // TOTAL
              Expanded(flex: flexTotal, child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: row.total > 0 ? _PC.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Text('${row.total}', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: row.total > 0 ? Colors.white : const Color(0xFFCBD5E1)))))),
            ]),
          );
        }),
        // FOOTER
        Container(
          decoration: const BoxDecoration(color: Color(0xFFEFF6FF), borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border(top: BorderSide(color: _PC.divider, width: 1.5))),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Expanded(flex: flexSection + flexKasie, child: Text(widget.lang == 'EN' ? 'Total' : widget.lang == 'ZH' ? '合计' : 'Total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _PC.textPrimary))),
            ...List.generate(_bulanLabels.length, (mi) => Expanded(flex: flexMonth, child: Center(child: Text('${colTotals[mi]}', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _PC.primaryDark))))),
            Expanded(flex: flexTotal, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: _PC.primary, borderRadius: BorderRadius.circular(8)),
              child: Text('$grandTotal', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white))))),
          ]),
        ),
      ]),
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
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _PC.barColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
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
            boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))]),
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
                // TOMBOL EDIT
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PmFormScreen(lang: widget.lang, existingData: r)));
                    if (result == true) _loadAll();
                  },
                  child: Container(width: 32, height: 32, decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: _PC.primary.withOpacity(0.25), width: 1)),
                    child: const Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 15, color: _PC.primary)),
                ),
                const SizedBox(width: 8),
                // TOMBOL DELETE
                GestureDetector(
                  onTap: () => _deleteRecord(r['id_pm'].toString()),
                  child: Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25), width: 1)),
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

  // ────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────
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
            // 1. TOMBOL ADD
            _buildAddButton(),
            const SizedBox(height: 20),

            // 2. CHART TOGGLE
            _buildChartToggle(),
            const SizedBox(height: 8),

            // 3. CHART (collapsible)
            AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
              child: _chartExpanded ? Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildChart()) : const SizedBox.shrink()),

            // 4. FILTER BAR
            _buildFilterBar(),
            const SizedBox(height: 14),

            // 5. TABEL KASIE
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _PC.barColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.engineering_outlined, size: 14, color: _PC.barColor)),
              const SizedBox(width: 8),
              Text('${_t('title')} – ${_t('kasie')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _PC.barColor)),
            ]),
            const SizedBox(height: 8),
            _buildTable(),
            const SizedBox(height: 24),

            // 6. CARD MILIK USER
            _buildMyRecords(),
          ]),
        ),
      ),
    );
  }
}

// ============================================================
// FORM SCREEN (CREATE & EDIT) — FILE UPLOAD VERSION
// ============================================================
class PmFormScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? existingData;
  const PmFormScreen({super.key, required this.lang, this.existingData});

  @override
  State<PmFormScreen> createState() => _PmFormScreenState();
}

class _PmFormScreenState extends State<PmFormScreen> {
  bool get _isEdit => widget.existingData != null;
  bool _isSaving   = false;

  final _judulCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String? _selectedBagian;

  // ── File state (ganti dari XFile/image ke PlatformFile) ──
  PlatformFile? _pickedFile;          // file baru yang dipilih
  String? _existingFileUrl;           // URL file lama (edit mode)
  String? _existingFileName;          // nama file lama (edit mode)

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const _txt = {
    'ID': {
      'create_title' : 'Buat Laporan PM',
      'edit_title'   : 'Edit Laporan PM',
      'judul'        : 'Judul PM',
      'judul_hint'   : 'Contoh: Perawatan mesin laser',
      'bagian'       : 'Bagian',
      'pick_bagian'  : 'Pilih Bagian',
      'file'         : 'File Lampiran (Opsional)',
      'add_file'     : 'Tambah File',
      'file_hint'    : 'PDF, Word, Excel, dan lainnya',
      'change_file'  : 'Ganti File',
      'remove_file'  : 'Hapus File',
      'desc'         : 'Deskripsi (Opsional)',
      'desc_hint'    : 'Jelaskan kegiatan PM...',
      'submit'       : 'Simpan Laporan',
      'update'       : 'Perbarui Laporan',
      'err_judul'    : 'Judul wajib diisi!',
      'err_bagian'   : 'Bagian wajib dipilih!',
      'success'      : 'Laporan PM berhasil disimpan!',
      'success_edit' : 'Laporan PM berhasil diperbarui!',
      'fail'         : 'Gagal menyimpan laporan',
      'saving'       : 'Menyimpan...',
      'cancel'       : 'Batal',
    },
    'EN': {
      'create_title' : 'Create PM Report',
      'edit_title'   : 'Edit PM Report',
      'judul'        : 'PM Title',
      'judul_hint'   : 'Example: Laser machine maintenance',
      'bagian'       : 'Section',
      'pick_bagian'  : 'Select Section',
      'file'         : 'Attachment File (Optional)',
      'add_file'     : 'Add File',
      'file_hint'    : 'PDF, Word, Excel, and others',
      'change_file'  : 'Change File',
      'remove_file'  : 'Remove File',
      'desc'         : 'Description (Optional)',
      'desc_hint'    : 'Describe PM activity...',
      'submit'       : 'Save Report',
      'update'       : 'Update Report',
      'err_judul'    : 'Title is required!',
      'err_bagian'   : 'Section is required!',
      'success'      : 'PM report saved!',
      'success_edit' : 'PM report updated!',
      'fail'         : 'Failed to save',
      'saving'       : 'Saving...',
      'cancel'       : 'Cancel',
    },
    'ZH': {
      'create_title' : '创建PM报告',
      'edit_title'   : '编辑PM报告',
      'judul'        : '标题',
      'judul_hint'   : '例如：激光机器维护',
      'bagian'       : '部门',
      'pick_bagian'  : '选择部门',
      'file'         : '附件文件（可选）',
      'add_file'     : '添加文件',
      'file_hint'    : 'PDF、Word、Excel等',
      'change_file'  : '更换文件',
      'remove_file'  : '删除文件',
      'desc'         : '描述（可选）',
      'desc_hint'    : '描述PM活动...',
      'submit'       : '保存报告',
      'update'       : '更新报告',
      'err_judul'    : '标题为必填项！',
      'err_bagian'   : '部门为必填项！',
      'success'      : 'PM报告已保存！',
      'success_edit' : 'PM报告已更新！',
      'fail'         : '保存失败',
      'saving'       : '保存中...',
      'cancel'       : '取消',
    },
  };

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.existingData!;
      _judulCtrl.text   = d['judul_pm'] ?? '';
      _descCtrl.text    = d['deskripsi_pm'] ?? '';
      _selectedBagian   = d['bagian'];
      _existingFileUrl  = d['file_pm'];
      _existingFileName = d['file_name_pm'];
    }
  }

  @override
  void dispose() { _judulCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: CupertinoColors.destructiveRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));

  // ── Helper: ikon berdasar ekstensi file ──
  IconData _fileIcon(String? name) {
    final ext = (name ?? '').split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':  return CupertinoIcons.doc_richtext;
      case 'doc':
      case 'docx': return CupertinoIcons.doc_text_fill;
      case 'xls':
      case 'xlsx': return CupertinoIcons.table;
      case 'ppt':
      case 'pptx': return CupertinoIcons.play_rectangle_fill;
      case 'zip':
      case 'rar':  return CupertinoIcons.archivebox_fill;
      case 'jpg':
      case 'jpeg':
      case 'png':  return CupertinoIcons.photo_fill;
      default:     return CupertinoIcons.doc_fill;
    }
  }

  Color _fileColor(String? name) {
    final ext = (name ?? '').split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':  return const Color(0xFFEF4444);
      case 'doc':
      case 'docx': return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx': return const Color(0xFF16A34A);
      case 'ppt':
      case 'pptx': return const Color(0xFFEA580C);
      default:     return _PC.primary;
    }
  }

  // ── Pilih file menggunakan file_picker ──
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,   // wajib untuk web & upload bytes
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  // ── Upload file ke Supabase Storage bucket pm_files ──
  Future<String?> _uploadFile(PlatformFile file, String userId) async {
    final sb        = Supabase.instance.client;
    final bytes     = file.bytes;
    if (bytes == null) return null;

    final ext      = file.extension ?? 'bin';
    final fileName = '$userId/pm_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await sb.storage.from('pm_files').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(upsert: false),
    );
    return sb.storage.from('pm_files').getPublicUrl(fileName);
  }

  Future<void> _submit() async {
    if (_judulCtrl.text.trim().isEmpty) return _showError(t['err_judul']!);
    if (_selectedBagian == null)        return _showError(t['err_bagian']!);
    setState(() => _isSaving = true);

    try {
      final sb   = Supabase.instance.client;
      final user = sb.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Upload file baru jika ada
      String? fileUrl  = _existingFileUrl;
      String? fileName = _existingFileName;

      if (_pickedFile != null) {
        fileUrl  = await _uploadFile(_pickedFile!, user.id);
        fileName = _pickedFile!.name;
      }

      final data = {
        'judul_pm'     : _judulCtrl.text.trim(),
        'bagian'       : _selectedBagian,
        'deskripsi_pm' : _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'file_pm'      : fileUrl,
        'file_name_pm' : fileName,
        'tanggal_pm'   : DateTime.now().toIso8601String().split('T').first,
      };

      if (_isEdit) {
        await sb.from('preventif_maintenance').update(data)
            .eq('id_pm', widget.existingData!['id_pm']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t['success_edit']!), backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
        }
      } else {
        await sb.from('preventif_maintenance').insert({...data, 'id_user': user.id});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t['success']!), backgroundColor: CupertinoColors.activeGreen));
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('PM submit error: $e');
      if (mounted) { _showError('${t['fail']!}: $e'); setState(() => _isSaving = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PC.bg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(CupertinoIcons.back, color: _PC.primary), onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? t['edit_title']! : t['create_title']!,
          style: GoogleFonts.inter(color: _PC.primary, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: _PC.border, height: 1)),
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── JUDUL ──
            _sectionCard(children: [
              _label(t['judul']!, required: true),
              _textField(_judulCtrl, t['judul_hint']!, CupertinoIcons.text_cursor),
            ]),
            const SizedBox(height: 16),

            // ── BAGIAN ──
            _sectionCard(children: [
              _label(t['bagian']!, required: true),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedBagian != null ? _PC.primary : _PC.border, width: _selectedBagian != null ? 1.5 : 1)),
                child: DropdownButtonHideUnderline(child: ButtonTheme(alignedDropdown: true, child: DropdownButton<String>(
                  isExpanded: true, value: _selectedBagian, dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14), menuMaxHeight: 300,
                  hint: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Row(children: [
                    const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFFBFDBFE)), const SizedBox(width: 10),
                    Text(t['pick_bagian']!, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFCBD5E1)))])),
                  icon: Padding(padding: const EdgeInsets.only(right: 4),
                    child: Icon(CupertinoIcons.chevron_down, size: 15,
                      color: _selectedBagian != null ? _PC.primary : const Color(0xFFBFDBFE))),
                  selectedItemBuilder: (context) => kPmBagianList.map((b) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(children: [
                      const Icon(Icons.grid_view_rounded, size: 16, color: _PC.primary), const SizedBox(width: 10),
                      Text(b, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))]))).toList(),
                  items: kPmBagianList.map((b) {
                    final isSel = _selectedBagian == b;
                    return DropdownMenuItem<String>(value: b, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: isSel ? _PC.primaryLight : Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Container(width: 32, height: 32, decoration: BoxDecoration(color: isSel ? _PC.primary : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.grid_view_rounded, size: 14, color: isSel ? Colors.white : const Color(0xFF94A3B8))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(b, style: GoogleFonts.inter(fontSize: 14,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? _PC.primary : const Color(0xFF1E293B)))),
                        if (isSel) const Icon(CupertinoIcons.checkmark_circle_fill, size: 18, color: _PC.primary),
                      ])));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBagian = val),
                ))),
              ),
            ]),
            const SizedBox(height: 16),

            // ── FILE LAMPIRAN ──
            _sectionCard(children: [
              _label(t['file']!, required: false),
              _fileWidget(),
            ]),
            const SizedBox(height: 16),

            // ── DESKRIPSI ──
            _sectionCard(children: [
              _label(t['desc']!, required: false),
              _textField(_descCtrl, t['desc_hint']!, CupertinoIcons.doc_text, maxLines: 4),
            ]),
            const SizedBox(height: 24),

            // ── SUBMIT ──
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0, minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(_isEdit ? t['update']! : t['submit']!,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),

        // ── SAVING OVERLAY ──
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CupertinoActivityIndicator(radius: 12, color: _PC.primary),
                const SizedBox(height: 12),
                Text(t['saving']!, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              ])))),
      ]),
    );
  }

  // ── Widget pemilih & preview file ──
  Widget _fileWidget() {
    // Tentukan nama tampilan: file baru diprioritaskan, fallback ke file lama
    final displayName = _pickedFile?.name ?? _existingFileName;
    final hasFile     = displayName != null;

    if (!hasFile) {
      // ── Belum ada file: tampilkan tombol pilih ──
      return GestureDetector(
        onTap: _pickFile,
        child: Container(
          height: 100, width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _PC.border, width: 1.5)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: _PC.primaryLight, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.doc_chart_fill, color: _PC.primary, size: 26)),
            const SizedBox(height: 10),
            Text(t['add_file']!, style: GoogleFonts.inter(color: _PC.primary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(t['file_hint']!, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11)),
          ]),
        ),
      );
    }

    // ── Sudah ada file: tampilkan preview + tombol ganti/hapus ──
    final fileColor = _fileColor(displayName);
    final fileIcon  = _fileIcon(displayName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.border, width: 1.5)),
      child: Row(children: [
        // Ikon file
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: fileColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(fileIcon, color: fileColor, size: 24)),
        const SizedBox(width: 12),
        // Nama file
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(displayName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (_pickedFile?.size != null) ...[
            const SizedBox(height: 2),
            Text(_formatBytes(_pickedFile!.size), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
          ],
        ])),
        const SizedBox(width: 8),
        // Tombol ganti
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: _PC.primary.withOpacity(0.25))),
            child: Text(t['change_file']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _PC.primary)))),
        const SizedBox(width: 6),
        // Tombol hapus
        GestureDetector(
          onTap: () => setState(() { _pickedFile = null; _existingFileUrl = null; _existingFileName = null; }),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25))),
            child: const Icon(CupertinoIcons.trash, size: 14, color: Color(0xFFEF4444)))),
      ]),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024)       return '$bytes B';
    if (bytes < 1048576)    return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Widget _sectionCard({required List<Widget> children}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _PC.border, width: 1),
      boxShadow: [BoxShadow(color: _PC.primary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _label(String label, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Row(children: [
      Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF475569))),
      if (required) const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontWeight: FontWeight.bold)),
    ]));

  Widget _textField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) => TextFormField(
    controller: ctrl, maxLines: maxLines,
    style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
    decoration: InputDecoration(
      hintText: hint, hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
      prefixIcon: maxLines == 1 ? Icon(icon, color: _PC.primary, size: 20) : null,
      filled: true, fillColor: const Color(0xFFF8FAFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _PC.border, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _PC.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)));
}

// ============================================================
// CUSTOM PAINTER — HORIZONTAL BAR BIRU
// ============================================================
class _PmBarPainter extends CustomPainter {
  final List<double> tickX;
  final double barWidth;
  final double barH;
  final double barVPad;
  final bool isZero;
  const _PmBarPainter({required this.tickX, required this.barWidth, required this.barH, required this.barVPad, required this.isZero});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
    for (int i = 1; i < tickX.length; i++) canvas.drawLine(Offset(tickX[i], 0), Offset(tickX[i], size.height), gridPaint);
    if (!isZero && barWidth > 0) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, barVPad, barWidth, size.height - barVPad * 2), const Radius.circular(4)),
        Paint()..color = _PC.barColor);
    }
  }

  @override
  bool shouldRepaint(_PmBarPainter old) => old.barWidth != barWidth || old.isZero != isZero;
}