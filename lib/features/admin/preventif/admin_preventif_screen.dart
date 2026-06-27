import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../admin_profile_screen.dart';
import '../home/admin_home_screen.dart';
import '../5R/admin_5r_screen.dart';
import '../kts/admin_kts_screen.dart';
import '../accident/admin_accident_screen.dart';

const List<String> _kBagianList = [
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
      case _PmRange.thisMonth:   return lang == 'EN' ? 'This Month'  : lang == 'ZH' ? '本月'  : 'Bulan Ini';
      case _PmRange.threeMonths: return lang == 'EN' ? '3 Months'    : lang == 'ZH' ? '3个月' : '3 Bulan';
      case _PmRange.sixMonths:   return lang == 'EN' ? '6 Months'    : lang == 'ZH' ? '6个月' : '6 Bulan';
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

class AdminPreventifScreen extends StatefulWidget {
  final String lang;
  final String? adminName;
  final String? adminImage;

  const AdminPreventifScreen({
    super.key,
    required this.lang,
    this.adminName,
    this.adminImage,
  });

  @override
  State<AdminPreventifScreen> createState() => _AdminPreventifScreenState();
}

class _AdminPreventifScreenState extends State<AdminPreventifScreen>
    with TickerProviderStateMixin {
  final _db = Supabase.instance.client;

  late String _lang;
  String _adminName = 'Admin';
  String? _adminImage;
  final int _activeNavIndex = 4;

  // FILTER & CHART
  bool _chartExpanded = false;
  _PmRange _range     = _PmRange.threeMonths;
  String? _filterBagian;

  // DATA
  bool _loadingTable = false;
  List<_PmKasieRow> _tableRows   = [];
  List<String>      _bulanLabels = [];

  static const _i18n = {
    'ID': {
      'title'        : 'Preventif Maintenance',
      'grafik'       : 'Grafik',
      'semua_bagian' : 'Semua Bagian',
      'pilih_bagian' : 'Pilih Bagian',
      'bagian'       : 'Bagian',
      'kasie'        : 'Kasie',
      'total'        : 'Total',
      'tidak_ada'    : 'Tidak ada data untuk periode ini',
      'detail_title' : 'Detail Laporan PM',
      'cant_open'    : 'Tidak dapat membuka file',
      'records'      : 'laporan',
    },
    'EN': {
      'title'        : 'Preventive Maintenance',
      'grafik'       : 'Chart',
      'semua_bagian' : 'All Sections',
      'pilih_bagian' : 'Select Section',
      'bagian'       : 'Section',
      'kasie'        : 'Kasie',
      'total'        : 'Total',
      'tidak_ada'    : 'No data for this period',
      'detail_title' : 'PM Report Detail',
      'cant_open'    : 'Cannot open file',
      'records'      : 'reports',
    },
    'ZH': {
      'title'        : '预防性维护',
      'grafik'       : '图表',
      'semua_bagian' : '所有部门',
      'pilih_bagian' : '选择部门',
      'bagian'       : '部门',
      'kasie'        : '科长',
      'total'        : '总计',
      'tidak_ada'    : '此期间无数据',
      'detail_title' : 'PM报告详情',
      'cant_open'    : '无法打开文件',
      'records'      : '份报告',
    },
  };

  String _t(String k) => _i18n[_lang]?[k] ?? _i18n['ID']![k] ?? k;

  @override
  void initState() {
    super.initState();
    _lang      = widget.lang;
    _adminName = widget.adminName ?? 'Admin';
    _adminImage = widget.adminImage;
    _loadTableData();
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
      final locale = _lang == 'ID' ? 'id_ID' : _lang == 'EN' ? 'en_US' : 'zh_CN';
      _bulanLabels = months.map((m) => DateFormat('MMM yy', locale).format(m)).toList();

      dynamic kasieQuery = _db.from('User')
          .select('id_user, nama, bagian_kasie')
          .eq('id_jabatan', 3);
      if (_filterBagian != null) kasieQuery = kasieQuery.eq('bagian_kasie', _filterBagian!);
      final kasieRes = List<Map<String, dynamic>>.from(await kasieQuery);

      if (kasieRes.isEmpty) {
        if (mounted) setState(() { _tableRows = []; _loadingTable = false; });
        return;
      }

      final start = months.first;
      final end   = DateTime(months.last.year, months.last.month + 1, 0, 23, 59, 59);

      final pmRes = List<Map<String, dynamic>>.from(
        await _db.from('preventif_maintenance')
            .select('bagian, created_at')
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String()),
      );

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
        return _PmKasieRow(
          kasieId: kasieId, kasieNama: kasieNama,
          bagian: bagian, bulanan: bulanan, total: monthSet.length,
        );
      }).toList()..sort((a, b) => b.total.compareTo(a.total));

      if (mounted) setState(() { _tableRows = rows; _loadingTable = false; });
    } catch (e) {
      debugPrint('AdminPreventif loadTable error: $e');
      if (mounted) setState(() => _loadingTable = false);
    }
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('cant_open')),
          backgroundColor: CupertinoColors.destructiveRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // FILE ICON HELPER
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

  // KASIE DETAIL BOTTOM SHEET
  Future<void> _showKasieDetail(String kasieNama, String bagian) async {
    final months = _getMonths();
    final start  = months.first;
    final end    = DateTime(months.last.year, months.last.month + 1, 0, 23, 59, 59);
    final locale = _lang == 'ID' ? 'id_ID' : _lang == 'EN' ? 'en_US' : 'zh_CN';

    try {
      final res = await _db
          .from('preventif_maintenance')
          .select('*, pelapor:id_user(nama, gambar_user)')
          .eq('bagian', bagian)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);

      final records = List<Map<String, dynamic>>.from(res);
      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.70,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (__, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // HANDLE
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),

                // SHEET HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.engineering_rounded, color: _PC.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kasieNama,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                            Text(bagian,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '${records.length} ${_t('records')}',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _PC.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: _PC.divider),

                // RECORDS LIST
                Expanded(
                  child: records.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.engineering_outlined, size: 52, color: _PC.primaryLight),
                            const SizedBox(height: 10),
                            Text(_t('tidak_ada'),
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                          ]),
                        )
                      : ListView.separated(
                          controller: sc,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                          itemCount: records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildRecordCard(records[i], locale),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('AdminPreventif kasieDetail error: $e');
    }
  }

  Widget _buildRecordCard(Map<String, dynamic> r, String locale) {
    final dateStr = r['created_at'] != null
        ? DateFormat('dd MMM yyyy, HH:mm', locale)
            .format(DateTime.parse(r['created_at']).toLocal())
        : '-';
    final pelapor = r['pelapor'] as Map<String, dynamic>?;
    final hasFile = r['file_pm'] != null && r['file_name_pm'] != null;
    final desc    = (r['deskripsi_pm'] ?? '').toString().trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PC.border, width: 1.3),
        boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILE ATTACHMENT
          if (hasFile)
            GestureDetector(
              onTap: () => _openFile(r['file_pm']),
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _PC.border, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _fileColor(r['file_name_pm']).withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_fileIcon(r['file_name_pm']),
                          color: _fileColor(r['file_name_pm']), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r['file_name_pm'] ?? '-',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _PC.primary, decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(CupertinoIcons.arrow_up_right_square, size: 14, color: _PC.primary),
                  ],
                ),
              ),
            ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE + SECTION BADGE
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r['judul_pm'] ?? '-',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        r['bagian'] ?? '-',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _PC.primary),
                      ),
                    ),
                  ],
                ),

                // DESCRIPTION
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(desc,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.5)),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(dateStr,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                    if (pelapor != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pelapor['nama'] ?? '-',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RANGE PICKER
  void _showRangePicker() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _PC.primaryLight, width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: _PC.primaryLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.date_range_rounded, color: _PC.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _lang == 'EN' ? 'Select Period' : _lang == 'ZH' ? '选择期间' : 'Pilih Periode',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _PC.textPrimary),
                )),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _PC.textSec),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            const SizedBox(height: 8),
            ..._PmRange.values.map((r) {
              final sel = _range == r;
              return GestureDetector(
                onTap: () { Navigator.pop(ctx); setState(() => _range = r); _loadTableData(); },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: sel ? _PC.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? _PC.primary : const Color(0xFFE2E8F0), width: sel ? 1.8 : 1),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(r.label(_lang),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: sel ? _PC.primaryDark : const Color(0xFF1E293B)))),
                    if (sel) const Icon(Icons.check_circle_rounded, color: _PC.primary, size: 20),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  void _showBagianPicker() {
    final items = [null, ..._kBagianList];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _PC.primaryLight, width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                color: _PC.primaryLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.grid_view_rounded, color: _PC.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_t('pilih_bagian'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _PC.textPrimary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _PC.textSec),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final lbl  = item ?? _t('semua_bagian');
                  final sel  = item == _filterBagian;
                  return InkWell(
                    onTap: () { Navigator.pop(ctx); setState(() => _filterBagian = item); _loadTableData(); },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? _PC.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? _PC.primary : const Color(0xFFE2E8F0), width: sel ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: sel ? _PC.primary : _PC.primaryLight,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(child: Text(
                            lbl.isNotEmpty ? lbl[0].toUpperCase() : '#',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                color: sel ? Colors.white : _PC.primaryDark),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(lbl,
                          style: TextStyle(fontSize: 13,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              color: sel ? _PC.primaryDark : const Color(0xFF1E293B)))),
                        if (sel) const Icon(Icons.check_circle_rounded, color: _PC.primary, size: 18),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == _activeNavIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(context, _slideRoute(
        AdminHomeScreen(initialUserName: _adminName, initialUserImage: _adminImage),
        fromRight: false));
      return;
    }
    if (index == 1) {
      Navigator.pushReplacement(context, _slideRoute(
        Admin5RScreen(lang: _lang, adminName: _adminName, adminImage: _adminImage),
        fromRight: false));
      return;
    }
    if (index == 2) {
      Navigator.pushReplacement(context, _slideRoute(
        AdminKtsScreen(lang: _lang, adminName: _adminName, adminImage: _adminImage),
        fromRight: false));
      return;
    }
    if (index == 3) {
      Navigator.pushReplacement(context, _slideRoute(
        AdminAccidentScreen(lang: _lang, adminName: _adminName, adminImage: _adminImage),
        fromRight: false));
      return;
    }
  }

  PageRouteBuilder<T> _slideRoute<T>(Widget screen, {bool fromRight = true}) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        final begin  = fromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
        return SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
            child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _PC.bg,
      body: Stack(
        children: [
          // BACKGROUND BLOBS
          Positioned(top: -80, right: -60,
            child: Container(width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_PC.primary.withValues(alpha:0.08), Colors.transparent])))),
          Positioned(bottom: 100, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_PC.barColor.withValues(alpha:0.06), Colors.transparent])))),

          // MAIN COLUMN
          Column(
            children: [
              SafeArea(bottom: false, child: _buildHeader()),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(children: [
                        Container(
                          width: 4, height: 20,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_PC.primary, _PC.barColor],
                              begin: Alignment.topCenter, end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 10),
                        Text(_t('title'),
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _PC.primaryDark)),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // SCROLLABLE BODY
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadTableData,
                        color: _PC.primary, backgroundColor: Colors.white,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 90 + bottomPadding),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                            _buildChartToggle(),
                            const SizedBox(height: 8),

                            AnimatedSize(
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
                              child: _chartExpanded
                                  ? Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildChart())
                                  : const SizedBox.shrink(),
                            ),

                            _buildFilterBar(),
                            const SizedBox(height: 14),

                            // SECTION TABLE LABEL
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _PC.barColor.withValues(alpha:0.12),
                                  borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.engineering_outlined, size: 14, color: _PC.barColor)),
                              const SizedBox(width: 8),
                              Text('${_t('title')} – ${_t('kasie')}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _PC.barColor)),
                            ]),
                            const SizedBox(height: 8),

                            _buildTable(),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // BOTTOM NAV
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNavBar(bottomPadding)),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Image(
          image: const AssetImage('assets/images/logo1.png'), height: 36, gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20)),
        ),
        const SizedBox(width: 10),
        Text('Admin Panel', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 29, 199, 97))),
        const Spacer(),
        _buildLangSwitcher(),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => AdminProfileScreen(lang: _lang, initialUserName: _adminName, initialUserImage: _adminImage),
            transitionsBuilder: (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
              child: child),
            transitionDuration: const Duration(milliseconds: 300))),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 16, backgroundColor: const Color(0xFF6366F1),
                backgroundImage: _adminImage != null ? CachedNetworkImageProvider(_adminImage!) : null,
                child: _adminImage == null ? const Icon(Icons.person, color: Colors.white, size: 16) : null),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildLangSwitcher() {
    final langs = [
      {'code': 'ID', 'flag': '🇮🇩'},
      {'code': 'EN', 'flag': '🇺🇸'},
      {'code': 'ZH', 'flag': '🇨🇳'},
    ];
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context, backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(_lang == 'EN' ? 'Select Language' : _lang == 'ZH' ? '选择语言' : 'Pilih Bahasa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: const Color.fromARGB(255, 29, 199, 97))),
            const SizedBox(height: 16),
            ...langs.map((l) {
              final isSelected = _lang == l['code'];
              final labels = {'ID': 'Bahasa Indonesia', 'EN': 'English', 'ZH': '中文'};
              return GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('lang', l['code']!);
                  if (mounted) setState(() => _lang = l['code']!);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF059669).withValues(alpha: 0.08) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? const Color(0xFF059669) : Colors.grey.shade200, width: isSelected ? 1.5 : 1)),
                  child: Row(children: [
                    Text(l['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(labels[l['code']]!,
                      style: GoogleFonts.poppins(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 15,
                          color: isSelected ? const Color(0xFF059669) : const Color.fromARGB(255, 7, 139, 97)))),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                  ]),
                ),
              );
            }),
          ]),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_lang == 'ID' ? '🇮🇩' : _lang == 'EN' ? '🇺🇸' : '🇨🇳', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(_lang, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF059669)),
        ]),
      ),
    );
  }

  // CHART TOGGLE BUTTON
  Widget _buildChartToggle() {
    final months = _getMonths();
    final locale = _lang == 'ID' ? 'id_ID' : _lang == 'EN' ? 'en_US' : 'zh_CN';
    final rangeLabel = months.length == 1
        ? DateFormat('MMMM yyyy', locale).format(months.first)
        : '${DateFormat('MMM', locale).format(months.first)} – ${DateFormat('MMM yyyy', locale).format(months.last)}';

    return GestureDetector(
      onTap: () => setState(() => _chartExpanded = !_chartExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _PC.primary.withValues(alpha:0.40), width: 1.2),
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

  // CHART
  Widget _buildChart() {
    if (_loadingTable) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
        child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))));
    }
    final filtered = _filterBagian != null
        ? _tableRows.where((r) => r.bagian == _filterBagian).toList()
        : _tableRows;
    if (filtered.isEmpty) return _emptyBox();

    final xMax   = _range.monthCount;
    final xTicks = List.generate(xMax + 1, (i) => i);
    const double labelW  = 72.0;
    const double barH    = 22.0;
    const double rowVPad = 4.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.primaryLight, width: 1.2),
        boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.07), blurRadius: 10, offset: const Offset(0, 3))]),
      child: LayoutBuilder(builder: (_, constraints) {
        final barAreaW = constraints.maxWidth - labelW - 8;
        final tickX = xTicks.map((v) => xMax > 0 ? (v / xMax) * barAreaW : 0.0).toList();
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
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                      color: isZero ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
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

  // FILTER BAR
  Widget _buildFilterBar() {
    return Row(children: [
      _filterBtn(label: _range.label(_lang), active: true, icon: Icons.date_range_rounded, onTap: _showRangePicker),
      const SizedBox(width: 8),
      Expanded(child: _filterBtn(
        label: _filterBagian ?? _t('semua_bagian'),
        active: _filterBagian != null,
        icon: Icons.grid_view_rounded,
        onTap: _showBagianPicker)),
    ]);
  }

  Widget _filterBtn({required String label, required VoidCallback onTap, bool active = false, required IconData icon}) {
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
          Flexible(child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : _PC.primary),
            overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: active ? Colors.white : _PC.primary),
        ]),
      ),
    );
  }

  // TABLE
  Widget _buildTable() {
    if (_loadingTable) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
        child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))));
    }
    final rows = _filterBagian != null
        ? _tableRows.where((r) => r.bagian == _filterBagian).toList()
        : _tableRows;
    if (rows.isEmpty) return _emptyBox();

    final months = _getMonths();
    final locale  = _lang == 'ID' ? 'id_ID' : _lang == 'EN' ? 'en_US' : 'zh_CN';
    final bulanLabels3 = months.map((m) => DateFormat('MMM', locale).format(m)).toList();
    final colTotals = List.generate(_bulanLabels.length,
        (i) => rows.fold(0, (s, r) => s + (r.bulanan[i] ?? 0)));
    final grandTotal = rows.fold(0, (s, r) => s + r.total);

    const int flexSection = 3;
    const int flexKasie   = 4;
    const int flexMonth   = 2;
    const int flexTotal   = 2;

    Widget hCell(String text, {int flex = 2, TextAlign align = TextAlign.left, Color? color}) =>
        Expanded(flex: flex, child: Text(text, textAlign: align,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color ?? _PC.textSec),
          overflow: TextOverflow.ellipsis));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.primaryLight, width: 1.5),
        boxShadow: [BoxShadow(color: _PC.primary.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 3))]),
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
              Expanded(flex: flexSection, child: Text(row.bagian.isEmpty ? '-' : row.bagian,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: row.total > 0 ? _PC.textPrimary : const Color(0xFFCBD5E1)),
                overflow: TextOverflow.ellipsis)),
              // KASIE — TAP → DETAIL
              Expanded(flex: flexKasie, child: GestureDetector(
                onTap: () => _showKasieDetail(row.kasieNama, row.bagian),
                child: Text(row.kasieNama,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: row.total > 0 ? _PC.primary : const Color(0xFFCBD5E1),
                      decoration: row.total > 0 ? TextDecoration.underline : TextDecoration.none),
                  overflow: TextOverflow.ellipsis),
              )),
              ...List.generate(_bulanLabels.length, (mi) {
                final val    = row.bulanan[mi] ?? 0;
                final isNull = val == 0;
                return Expanded(flex: flexMonth, child: Center(child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: !isNull ? _PC.barColor.withValues(alpha:0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text(isNull ? '·' : '$val',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: !isNull ? _PC.barColor : const Color(0xFFCBD5E1)))))));
              }),
              Expanded(flex: flexTotal, child: Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: row.total > 0 ? _PC.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8)),
                child: Text('${row.total}', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                      color: row.total > 0 ? Colors.white : const Color(0xFFCBD5E1)))))),
            ]),
          );
        }),
        // FOOTER
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border(top: BorderSide(color: _PC.divider, width: 1.5))),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Expanded(flex: flexSection + flexKasie, child: Text(
              _lang == 'EN' ? 'Total' : _lang == 'ZH' ? '合计' : 'Total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _PC.textPrimary))),
            ...List.generate(_bulanLabels.length, (mi) => Expanded(flex: flexMonth, child: Center(child: Text('${colTotals[mi]}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _PC.primaryDark))))),
            Expanded(flex: flexTotal, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: _PC.primary, borderRadius: BorderRadius.circular(8)),
              child: Text('$grandTotal', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white))))),
          ]),
        ),
      ]),
    );
  }

  Widget _emptyBox() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.primaryLight, width: 1.5)),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bar_chart_outlined, size: 44, color: _PC.primaryLight),
        const SizedBox(height: 10),
        Text(_t('tidak_ada'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      ])),
    );
  }

  Widget _buildBottomNavBar(double bottomPadding) {
    const activeColor   = Color.fromARGB(255, 29, 199, 97);
    const inactiveColor = Color(0xFF94A3B8);
    final double safeBottom = bottomPadding > 0 ? bottomPadding : 8;

    final items = [
      _NavItem(index: 0, labelID: 'Beranda',   labelEN: 'Home',       labelZH: '首页',
          activeIcon: Icons.home_rounded,                 inactiveIcon: Icons.home_outlined),
      _NavItem(index: 1, labelID: '5R',        labelEN: '5R',         labelZH: '5R',
          activeIcon: Icons.search_rounded,               inactiveIcon: Icons.search_outlined),
      _NavItem(index: 2, labelID: 'KTS',       labelEN: 'KTS',        labelZH: 'KTS',
          activeIcon: Icons.precision_manufacturing_rounded, inactiveIcon: Icons.precision_manufacturing_outlined),
      _NavItem(index: 3, labelID: 'Accident',  labelEN: 'Accident',   labelZH: '事故',
          activeIcon: Icons.warning_rounded,              inactiveIcon: Icons.warning_amber_outlined),
      _NavItem(index: 4, labelID: 'Preventif', labelEN: 'Preventive', labelZH: '预防',
          activeIcon: Icons.build_circle_rounded,         inactiveIcon: Icons.build_circle_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, -4))]),
      child: Padding(
        padding: EdgeInsets.only(top: 8, bottom: safeBottom),
        child: SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items.map((item) {
              final isActive = _activeNavIndex == item.index;
              final label    = _lang == 'EN' ? item.labelEN : _lang == 'ZH' ? item.labelZH : item.labelID;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onNavTap(item.index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200), curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20)),
                      child: Icon(isActive ? item.activeIcon : item.inactiveIcon,
                          size: 24, color: isActive ? activeColor : inactiveColor)),
                    const SizedBox(height: 2),
                    Text(label, style: GoogleFonts.poppins(fontSize: 10,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? activeColor : inactiveColor),
                        overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _PmBarPainter extends CustomPainter {
  final List<double> tickX;
  final double barWidth;
  final double barH;
  final double barVPad;
  final bool isZero;

  const _PmBarPainter({
    required this.tickX, required this.barWidth,
    required this.barH,  required this.barVPad, required this.isZero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
    for (int i = 1; i < tickX.length; i++) {
      canvas.drawLine(Offset(tickX[i], 0), Offset(tickX[i], size.height), gridPaint);
    }
    if (!isZero && barWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barVPad, barWidth, size.height - barVPad * 2),
          const Radius.circular(4)),
        Paint()..color = _PC.barColor);
    }
  }

  @override
  bool shouldRepaint(_PmBarPainter old) => old.barWidth != barWidth || old.isZero != isZero;
}

class _NavItem {
  final int index;
  final String labelID, labelEN, labelZH;
  final IconData activeIcon, inactiveIcon;
  const _NavItem({
    required this.index,
    required this.labelID, required this.labelEN, required this.labelZH,
    required this.activeIcon, required this.inactiveIcon,
  });
}