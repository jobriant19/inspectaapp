import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/ai_recurring_service.dart';
import '../../../../core/utils/jabatan_helper.dart';
import '../../../admin/target/target/admin_target_pick_date.dart';
import '../../accident/accident_detail_screen.dart';
import '../../accident/picker/accident_pick_cause.dart';
import '../../accident/picker/accident_pick_severity.dart';

class _C {
  static const primary       = Color(0xFF1D72F3);
  static const textPrimary   = Color(0xFF0C4A6E);
  static const textMuted     = Color(0xFFBDBDBD);
  static const divider       = Color(0xFFE0F2FE);
  static const red           = Color(0xFFEF4444);
  static const amber         = Color(0xFFF59E0B);
  static const green         = Color(0xFF10B981);
  static const surface       = Color(0xFFFEF2F2);
  static const primaryLight  = Color(0xFFFEE2E2);
}

class AccidentRecurringTab extends StatefulWidget {
  final String lang;
  final Widget Function({
    required String    label,
    required VoidCallback onTap,
    IconData           icon,
    bool               isActive,
  }) buildFilterBtn;

  const AccidentRecurringTab({
    super.key,
    required this.lang,
    required this.buildFilterBtn,
  });

  @override
  State<AccidentRecurringTab> createState() => AccidentRecurringTabState();
}

class AccidentRecurringTabState extends State<AccidentRecurringTab> {
  final _supabase = Supabase.instance.client;

  // FILTER STATE
  DateTime _recurringFrom   = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo     = DateTime.now();
  String?  _recurringUserId;
  String   _recurringUserName = '';

  Future<List<Map<String, dynamic>>>? _recurringFuture;
  int _topicsCurrentPage = 1;
  static const int _topicsPerPage = 7;

  static const List<Color> _levelColors = [
    Color(0xFF10B981), Color(0xFF6366F1), Color(0xFFFBBF24), Color(0xFFF472B6),
  ];
  Color _colorForLocLevel(String lvl) => _levelColors[['Lokasi', 'Unit', 'Subunit', 'Area'].indexOf(lvl).clamp(0, 3)];
  IconData _iconForLocLevel(String lvl) {
    switch (lvl) {
      case 'Unit': return Icons.business_rounded;
      case 'Subunit': return Icons.layers_rounded;
      case 'Area': return Icons.place_rounded;
      default: return Icons.location_city_rounded;
    }
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  String _levelLabel(String backendLevel) {
    switch (backendLevel) {
      case 'Unit':
        return _t('Unit', 'Unit', '单元');
      case 'Subunit':
        return _t('Subunit', 'Sub-unit', '子单元');
      case 'Area':
        return _t('Area', 'Area', '区域');
      default:
        return _t('Lokasi', 'Location', '位置');
    }
  }

  Color _severityColorByTotal(int total) {
    if (total >= 6) return _C.red;
    if (total >= 3) return _C.amber;
    return _C.green;
  }

  String _severityLabelByTotal(int total) {
    if (total >= 6) return _t('Sering Terjadi', 'Frequent', '频繁发生');
    if (total >= 3) return _t('Cukup Sering', 'Recurring', '较常见');
    return _t('Jarang', 'Occasional', '较少');
  }

  bool get _isPeriodDefault {
    final now = DateTime.now();
    final defaultFrom = DateTime(now.year - 1, now.month);
    return _recurringFrom.year == defaultFrom.year &&
        _recurringFrom.month == defaultFrom.month &&
        _recurringTo.year == now.year &&
        _recurringTo.month == now.month;
  }

  void _resetPeriod() {
    setState(() {
      _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
      _recurringTo = DateTime.now();
      _topicsCurrentPage = 1;
      _recurringFuture = _fetchRecurring();
    });
  }

  void _resetFinder() {
    setState(() {
      _recurringUserId = null;
      _recurringUserName = '';
      _topicsCurrentPage = 1;
      _recurringFuture = _fetchRecurring();
    });
  }

  Widget _buildPeriodFilterButton(String periodLabel) {
    final isActive = !_isPeriodDefault;
    return GestureDetector(
      onTap: _showPeriodPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.primary, width: 1.5),
          boxShadow: [BoxShadow(color: _C.primary.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15, color: _C.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(periodLabel,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.primary)),
                ),
              ],
            ),
          ),
          if (isActive)
            GestureDetector(
              onTap: _resetPeriod,
              child: Container(
                padding: const EdgeInsets.all(3),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: _C.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.red.withValues(alpha: 0.45)),
                ),
                child: Icon(Icons.close_rounded, size: 12, color: _C.red),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildFinderFilterButton() {
    final isActive = _recurringUserId != null;
    final label = _recurringUserName.isEmpty
        ? _t('Semua Penemu', 'All Finders', '所有发现者')
        : _recurringUserName;
    return GestureDetector(
      onTap: _showUserPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.primary, width: 1.5),
          boxShadow: [BoxShadow(color: _C.primary.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(Icons.person_search_rounded, size: 15, color: _C.primary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _C.primary)),
          ),
          if (isActive)
            GestureDetector(
              onTap: _resetFinder,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _C.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.red.withValues(alpha: 0.45)),
                ),
                child: Icon(Icons.close_rounded, size: 12, color: _C.red),
              ),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, color: _C.primary, size: 18),
        ]),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _recurringFuture = _fetchRecurring();
  }

  Future<List<Map<String, dynamic>>> _fetchRecurring() async {
    try {
      var q = _supabase.from('accident_report').select('''
        id_laporan, judul, deskripsi, foto_bukti, created_at, status,
        tanggal_kejadian, waktu_kejadian, tingkat_keparahan, penyebab,
        departemen_terdampak, tindakan_diambil,
        id_lokasi, id_unit, id_subunit, id_area, id_pelapor,
        nama_pihak_terdampak, nama_saksi,
        lokasi:id_lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
        pelapor:accident_report_id_pelapor_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
        pihak_terdampak:accident_report_id_pihak_terdampak_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
        supervisor_user:accident_report_id_supervisor_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
        saksi_user:accident_report_id_saksi_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan))
      ''')
          .gte('created_at', _recurringFrom.toIso8601String())
          .lte('created_at', DateTime(
              _recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59)
              .toIso8601String());
      if (_recurringUserId != null) q = q.eq('id_pelapor', _recurringUserId!);
      final List<dynamic> res = await q.order('created_at', ascending: false);
      final reports = List<Map<String, dynamic>>.from(res);
      if (reports.isEmpty) return [];

      final groups = await GeminiRecurringService.instance.analyzeAccidents(
        reports,
        fromDate:     _recurringFrom,
        toDate:       _recurringTo,
        filterUserId: _recurringUserId,
      );
      return groups.map((g) => {
        'topic':           g.topic,
        'locationArea':    g.locationArea,
        'total':           g.total,
        'imageUrl':        g.imageUrl,
        'reports':         g.reports,
        'severityPattern': g.severityPattern,
        'similarityScore': g.similarityScore,
        'aiReason':        g.reason,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final locale    = widget.lang == 'ID' ? 'id_ID'
        : widget.lang == 'ZH' ? 'zh_CN' : 'en_US';
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel   = DateFormat('MMM yyyy', locale).format(_recurringTo);

    return Column(children: [
      // FILTER ROW (TETAP - style putih/merah sudah benar dari parent)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: _buildPeriodFilterButton('$fromLabel - $toLabel')),
          const SizedBox(width: 10),
          Expanded(child: _buildFinderFilterButton()),
        ]),
      ),
      // SECTION LABEL (gaya sama seperti 5R)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.primary.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: _C.primary, shape: BoxShape.circle),
              child: const Icon(Icons.autorenew_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Kecelakaan Berulang', 'Recurring Accidents', '重复事故'),
                    style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _C.primary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _t(
                      'Laporan kecelakaan dengan pola atau lokasi serupa dikelompokkan otomatis',
                      'Accident reports with similar patterns or locations are grouped automatically',
                      '相似模式或位置的事故报告会自动分组',
                    ),
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _C.primary,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
      // LIST
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recurringFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }
          final groups = snap.data ?? [];
          if (groups.isEmpty) return _buildEmptyState();

          final totalTopicPages = (groups.length / _topicsPerPage).ceil().clamp(1, 999999);
          final safeTopicPage = _topicsCurrentPage.clamp(1, totalTopicPages);
          final tStart = (safeTopicPage - 1) * _topicsPerPage;
          final tEnd = (tStart + _topicsPerPage) > groups.length ? groups.length : tStart + _topicsPerPage;
          final pagedGroups = groups.sublist(tStart, tEnd);

          return Column(children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                itemCount: pagedGroups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) => _AccidentRecurringCard(
                  group: pagedGroups[i], lang: widget.lang,
                  onTap: () => _showRecurringDetail(context, pagedGroups[i]),
                ),
              ),
            ),
            if (totalTopicPages > 1)
              Padding(
                padding: EdgeInsets.fromLTRB(0, 4, 0, MediaQuery.of(context).viewPadding.bottom + 10),
                child: _AccidentPagePickerIndicator(
                  currentPage: safeTopicPage, totalPages: totalTopicPages, color: _C.red,
                  onPageChanged: (p) => setState(() => _topicsCurrentPage = p),
                ),
              )
            else
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 10),
          ]);
        },
      )),
    ]);
  }

  // ─── EMPTY STATE (ilustrasi + teks sesuai bahasa, gaya lebih menarik) ─────
  Widget _buildEmptyState() {
    final name = _recurringUserName.isEmpty ? '' : _recurringUserName;
    final message = name.isEmpty
        ? _t('Belum ada laporan kecelakaan yang berulang.',
            'No recurring accident reports yet.', '暂无重复的事故报告。')
        : '$name ${_t('belum memiliki laporan kecelakaan berulang', 'does not have recurring accident reports yet', '还没有重复的事故报告')}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _C.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _C.primaryLight, width: 1.5),
              ),
              child: Image.asset(
                'assets/images/team_illustration.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                      color: _C.surface, shape: BoxShape.circle),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 44, color: _C.red.withValues(alpha: 0.6)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _C.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.red.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.autorenew_rounded, size: 13, color: _C.red),
                const SizedBox(width: 5),
                Text(_t('Kecelakaan Berulang', 'Recurring Accidents', '重复事故'),
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _C.red)),
              ]),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: _C.textPrimary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // RECURRING DETAIL BOTTOM SHEET
  void _showRecurringDetail(BuildContext context, Map<String, dynamic> group) {
    final total = group['total'] as int? ?? 0;
    final severityColor = _severityColorByTotal(total);
    final severityLabel = _severityLabelByTotal(total);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AccidentTopicDetailScreen(
          group: group, lang: widget.lang, severityColor: severityColor, severityLabel: severityLabel,
        ),
      ),
    );
  }

  // PERIOD PICKER (gaya sama persis seperti 5R Recurring)
  void _showPeriodPicker() async {
    DateTime tempFrom = _recurringFrom;
    DateTime tempTo   = _recurringTo;

    Widget dateField({
      required String label,
      required IconData labelIcon,
      required DateTime value,
      required VoidCallback onTap,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(labelIcon, size: 13, color: _C.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 48,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _C.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.primary.withValues(alpha: 0.35)),
              ),
              child: Row(children: [
                Icon(Icons.event_rounded, size: 17, color: _C.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEE, d MMM yyyy').format(value),
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0C3A8C)),
                  ),
                ),
                Icon(Icons.keyboard_arrow_right_rounded, size: 18, color: _C.primary),
              ]),
            ),
          ),
        ],
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.date_range_rounded, color: _C.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _t('Pilih Periode', 'Select Period', '选择期间'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0C3A8C)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),

                dateField(
                  label: _t('Dari', 'From', '从'),
                  labelIcon: Icons.play_circle_outline_rounded,
                  value: tempFrom,
                  onTap: () async {
                    final picked = await showAdminTargetDatePicker(
                      context: ctx,
                      lang: widget.lang,
                      initialDate: tempFrom,
                    );
                    if (picked != null) {
                      setSt(() {
                        tempFrom = picked;
                        if (tempTo.isBefore(tempFrom)) tempTo = tempFrom;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                dateField(
                  label: _t('Sampai', 'To', '到'),
                  labelIcon: Icons.flag_circle_rounded,
                  value: tempTo,
                  onTap: () async {
                    final picked = await showAdminTargetDatePicker(
                      context: ctx,
                      lang: widget.lang,
                      initialDate: tempTo,
                    );
                    if (picked != null) {
                      setSt(() {
                        tempTo = picked;
                        if (tempFrom.isAfter(tempTo)) tempFrom = tempTo;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _recurringFrom   = tempFrom;
                        _recurringTo     = tempTo;
                        _recurringFuture = _fetchRecurring();
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_t('Terapkan', 'Apply', '应用'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Badge jabatan (sama seperti 5R/KTS) ──────────────────────────────────
  Widget _buildJabatanBadge({
    required int? idJabatan,
    required String? jabatanNama,
    required bool? isVerificator,
  }) {
    final label = JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
    if (label.isEmpty) return const SizedBox.shrink();
    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ─── Popup pemilih lokasi (Lokasi/Unit/Subunit/Area) untuk filter finder ──
  Future<Map<String, String?>?> _pickLocationFilter(
      BuildContext parentContext, String initialLevel, String? initialId) async {
    String tempLevel = initialLevel;
    String? tempId = initialId;
    List<Map<String, String>> locItems = [];
    bool loading = true;
    bool initialized = false;
    int locCurrentPage = 1;
    const int locPerPage = 5;
    final searchCtrl = TextEditingController();

    Future<void> fetchItems(void Function(void Function()) setSt) async {
      loading = true;
      setSt(() {});
      final levelLower = tempLevel.toLowerCase();
      final idMap = {'lokasi': 'id_lokasi', 'unit': 'id_unit', 'subunit': 'id_subunit', 'area': 'id_area'};
      final nameMap = {'lokasi': 'nama_lokasi', 'unit': 'nama_unit', 'subunit': 'nama_subunit', 'area': 'nama_area'};
      final idCol = idMap[levelLower] ?? 'id_lokasi';
      final nameCol = nameMap[levelLower] ?? 'nama_lokasi';
      try {
        final res = await _supabase.from(levelLower).select('$idCol, $nameCol').order(nameCol);
        locItems = List<Map<String, dynamic>>.from(res)
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'}).toList();
      } catch (e) { locItems = []; }
      loading = false;
      locCurrentPage = 1;
      setSt(() {});
    }

    IconData levelIcon(String label) => _iconForLocLevel(label);

    return showDialog<Map<String, String?>>(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (!initialized) { initialized = true; fetchItems(setSt); }
          final q = searchCtrl.text.trim().toLowerCase();
          final filteredLoc = q.isEmpty ? locItems : locItems.where((e) => e['name']!.toLowerCase().contains(q)).toList();
          final currentColor = _colorForLocLevel(tempLevel);

          final totalLocPages = filteredLoc.isEmpty ? 1 : (filteredLoc.length / locPerPage).ceil();
          final safeLocPage = locCurrentPage.clamp(1, totalLocPages);
          final locStart = (safeLocPage - 1) * locPerPage;
          final locEnd = (locStart + locPerPage) > filteredLoc.length ? filteredLoc.length : locStart + locPerPage;
          final pagedLoc = filteredLoc.isEmpty ? <Map<String, String>>[] : filteredLoc.sublist(locStart, locEnd);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 340,
              height: MediaQuery.of(parentContext).size.height * 0.78,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.primary.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.tune_rounded, color: _C.primary, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_t('Pilih Lokasi', 'Select Location', '选择位置'), style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: _C.primary))),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18)),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(children: List.generate(4, (index) {
                    final lvl = ['Lokasi', 'Unit', 'Subunit', 'Area'][index];
                    final isSel = lvl == tempLevel;
                    final color = _levelColors[index];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () { tempLevel = lvl; tempId = null; searchCtrl.clear(); locCurrentPage = 1; fetchItems(setSt); },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(color: isSel ? color : Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: isSel ? color : const Color(0xFFE2E8F0))),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(levelIcon(lvl), size: 14, color: isSel ? Colors.white : color),
                            const SizedBox(height: 2),
                            Text(_levelLabel(lvl), overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSel ? Colors.white : const Color(0xFF475569))),
                          ]),
                        ),
                      ),
                    );
                  })),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: currentColor.withValues(alpha: 0.35), width: 1.3)),
                    child: TextField(
                      controller: searchCtrl,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (_) => setSt(() { locCurrentPage = 1; }),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _t('Cari...', 'Search...', '搜索...'), hintStyle: const TextStyle(fontSize: 12.5, color: _C.textMuted),
                        prefixIcon: Icon(Icons.search_rounded, color: currentColor, size: 18),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? GestureDetector(onTap: () => setSt(() { searchCtrl.clear(); locCurrentPage = 1; }),
                                child: Container(margin: const EdgeInsets.all(9), padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFFEF4444))))
                            : null,
                        border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: _C.divider),
                Expanded(
                  child: loading
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: 6,
                            itemBuilder: (_, __) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                              child: Row(children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(height: 14, width: 150, color: Colors.white),
                                  const SizedBox(height: 6),
                                  Container(height: 10, width: 90, color: Colors.white),
                                ])),
                              ]),
                            ),
                          ),
                        )
                      : Column(children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              children: [
                                InkWell(
                                  onTap: () => Navigator.pop(ctx, {'level': tempLevel, 'id': null, 'name': null}),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: tempId == null ? currentColor.withValues(alpha: 0.10) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: tempId == null ? currentColor : _C.divider, width: tempId == null ? 1.5 : 1)),
                                    child: Row(children: [
                                      Container(width: 44, height: 44, alignment: Alignment.center,
                                          decoration: BoxDecoration(color: currentColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                                          child: Icon(Icons.map_rounded, size: 20, color: currentColor)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('${_t('Semua', 'All', '全部')} (${_levelLabel(tempLevel)})',
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: tempId == null ? FontWeight.w700 : FontWeight.w600, color: tempId == null ? currentColor : _C.textPrimary))),
                                      if (tempId == null) Icon(Icons.check_circle_rounded, color: currentColor, size: 18),
                                    ]),
                                  ),
                                ),
                                if (filteredLoc.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Image.asset('assets/images/team_illustration.png', height: 100, fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Container(width: 76, height: 76, decoration: BoxDecoration(color: currentColor.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, size: 32, color: currentColor.withValues(alpha: 0.4)))),
                                      const SizedBox(height: 10),
                                      Text(_t('Tidak ada data untuk level ini.', 'No data for this level.', '此级别没有数据。'), style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: currentColor), textAlign: TextAlign.center),
                                      if (searchCtrl.text.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () => setSt(() { searchCtrl.clear(); locCurrentPage = 1; }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                            decoration: BoxDecoration(color: currentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: currentColor.withValues(alpha: 0.35))),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.refresh_rounded, size: 14, color: currentColor),
                                              const SizedBox(width: 6),
                                              Text(widget.lang == 'EN' ? 'Clear search' : widget.lang == 'ZH' ? '清除搜索' : 'Hapus pencarian', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: currentColor)),
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ]),
                                  )
                                else
                                  ...pagedLoc.map((item) {
                                    final isSel = item['id'] == tempId;
                                    return InkWell(
                                      onTap: () => Navigator.pop(ctx, {'level': tempLevel, 'id': item['id'], 'name': item['name']}),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: isSel ? currentColor.withValues(alpha: 0.10) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isSel ? currentColor : _C.divider, width: isSel ? 1.5 : 1)),
                                        child: Row(children: [
                                          Container(width: 44, height: 44, alignment: Alignment.center,
                                              decoration: BoxDecoration(color: currentColor.withValues(alpha: isSel ? 0.20 : 0.14), borderRadius: BorderRadius.circular(12)),
                                              child: Icon(levelIcon(tempLevel), size: 20, color: currentColor)),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(item['name']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isSel ? currentColor : _C.textPrimary), overflow: TextOverflow.ellipsis)),
                                          if (isSel) Icon(Icons.check_circle_rounded, color: currentColor, size: 18),
                                        ]),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          if (totalLocPages > 1 && filteredLoc.isNotEmpty)
                            _AccidentPagePickerIndicator(currentPage: safeLocPage, totalPages: totalLocPages, color: currentColor, onPageChanged: (p) => setSt(() => locCurrentPage = p)),
                        ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ─── Popup Select Finder (dengan filter lokasi + badge jabatan) ───────────
  void _showUserPicker() async {
    String currentLocLevel = 'Lokasi';
    String? currentLocId;
    String? currentLocName;
    List<Map<String, dynamic>> items = [];
    List<Map<String, dynamic>> filtered = [];
    bool loadingUsers = true;
    bool initialized = false;
    int currentPage = 1;
    const int perPage = 7;
    final ctrl = TextEditingController();

    Future<void> loadUsers(void Function(void Function()) setSt) async {
      loadingUsers = true;
      setSt(() {});
      try {
        var userQuery = _supabase.from('User').select(
            'id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)');
        if (currentLocId != null) {
          const idMap = {'Lokasi': 'id_lokasi', 'Unit': 'id_unit', 'Subunit': 'id_subunit', 'Area': 'id_area'};
          final idCol = idMap[currentLocLevel] ?? 'id_lokasi';
          userQuery = userQuery.eq(idCol, currentLocId!);
        }
        final res = await userQuery.order('nama');
        final users = List<Map<String, dynamic>>.from(res);
        final allItem = {
          'id_user': null, 'nama': _t('Semua Penemu', 'All Finders', '所有发现者'),
          'gambar_user': null, 'jabatan': null, 'id_jabatan': null, 'is_verificator': null,
        };
        items = [allItem, ...users];
      } catch (e) { items = []; }
      final q = ctrl.text.trim().toLowerCase();
      filtered = q.isEmpty ? List.from(items) : items.where((e) => (e['nama'] as String).toLowerCase().contains(q)).toList();
      currentPage = 1;
      loadingUsers = false;
      setSt(() {});
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (!initialized) { initialized = true; loadUsers(setSt); }

          final totalPages = filtered.isEmpty ? 1 : (filtered.length / perPage).ceil();
          final safePage = currentPage.clamp(1, totalPages);
          final startIdx = (safePage - 1) * perPage;
          final endIdx = (startIdx + perPage) > filtered.length ? filtered.length : startIdx + perPage;
          final pageItems = filtered.isEmpty ? <Map<String, dynamic>>[] : filtered.sublist(startIdx, endIdx);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 340,
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.primary.withValues(alpha: 0.25), width: 1.5)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_search_rounded, color: _C.primary, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_t('Pilih Penemu', 'Select Finder', '选择发现者'), style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: _C.primary))),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.primary.withValues(alpha: 0.35), width: 1.3)),
                        child: TextField(
                          controller: ctrl,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (q) {
                            filtered = q.trim().isEmpty ? List.from(items) : items.where((e) => (e['nama'] as String).toLowerCase().contains(q.toLowerCase())).toList();
                            currentPage = 1;
                            setSt(() {});
                          },
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: _t('Cari...', 'Search...', '搜索...'), hintStyle: const TextStyle(fontSize: 12.5, color: _C.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: _C.primary, size: 19),
                            suffixIcon: ctrl.text.isNotEmpty
                                ? GestureDetector(onTap: () { ctrl.clear(); filtered = List.from(items); currentPage = 1; setSt(() {}); },
                                    child: Container(margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444))))
                                : null,
                            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await _pickLocationFilter(ctx, currentLocLevel, currentLocId);
                        if (result != null) {
                          currentLocLevel = result['level'] ?? currentLocLevel;
                          currentLocId = result['id'];
                          currentLocName = result['name'];
                          await loadUsers(setSt);
                        }
                      },
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: currentLocId != null ? _C.primary : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: currentLocId != null ? _C.primary : _C.primary.withValues(alpha: 0.35), width: 1.3)),
                        child: Icon(Icons.map, color: currentLocId != null ? Colors.white : _C.primary, size: 20),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.primary.withValues(alpha: 0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.groups_rounded, size: 13, color: _C.primary),
                        const SizedBox(width: 5),
                        Text('${filtered.length} ${widget.lang == 'ID' ? 'Penemu' : widget.lang == 'ZH' ? '发现者' : 'Finders'}', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: _C.primary)),
                      ]),
                    ),
                    const Spacer(),
                    if (currentLocName != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 165),
                        child: Container(
                          padding: const EdgeInsets.only(left: 9, right: 4, top: 3, bottom: 3),
                          decoration: BoxDecoration(color: _colorForLocLevel(currentLocLevel).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: _colorForLocLevel(currentLocLevel).withValues(alpha: 0.4))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_iconForLocLevel(currentLocLevel), size: 11, color: _colorForLocLevel(currentLocLevel)),
                            const SizedBox(width: 4),
                            Flexible(child: Text(currentLocName!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _colorForLocLevel(currentLocLevel)), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () { currentLocId = null; currentLocName = null; loadUsers(setSt); },
                              child: Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 10, color: Color(0xFFEF4444))),
                            ),
                          ]),
                        ),
                      ),
                  ]),
                ),
                const Divider(height: 1, color: _C.divider),
                Expanded(
                  child: loadingUsers
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 6, bottom: 12),
                            itemCount: 6,
                            itemBuilder: (_, __) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
                              child: Row(children: [
                                Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(height: 13, width: 130, color: Colors.white),
                                  const SizedBox(height: 6),
                                  Container(height: 10, width: 75, color: Colors.white),
                                ])),
                              ]),
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Image.asset('assets/images/team_illustration.png', height: 110, fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(width: 84, height: 84, decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.search_off_rounded, size: 36, color: _C.primary))),
                                const SizedBox(height: 12),
                                Text(widget.lang == 'EN' ? 'No users found' : widget.lang == 'ZH' ? '未找到用户' : 'Pengguna tidak ditemukan', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _C.primary), textAlign: TextAlign.center),
                                if (ctrl.text.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () { ctrl.clear(); filtered = List.from(items); currentPage = 1; setSt(() {}); },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                      decoration: BoxDecoration(color: _C.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: _C.primary.withValues(alpha: 0.35))),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.refresh_rounded, size: 14, color: _C.primary),
                                        const SizedBox(width: 6),
                                        Text(widget.lang == 'EN' ? 'Clear search' : widget.lang == 'ZH' ? '清除搜索' : 'Hapus pencarian', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary)),
                                      ]),
                                    ),
                                  ),
                                ],
                              ]),
                            )
                          : Column(children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                                  itemCount: pageItems.length,
                                  itemBuilder: (_, i) {
                                    final item = pageItems[i];
                                    final name = item['nama'] as String;
                                    final id = item['id_user']?.toString();
                                    final avatarUrl = item['gambar_user'] as String?;
                                    final idJabatan = item['id_jabatan'] as int?;
                                    final isVerificator = item['is_verificator'] as bool?;
                                    final jabatanNama = (item['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
                                    final isSelected = id == _recurringUserId || (id == null && _recurringUserId == null);
                                    final isAll = id == null;

                                    return InkWell(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _recurringUserId = id;
                                          _recurringUserName = isAll ? _t('Semua Penemu', 'All Finders', '所有发现者') : name;
                                          _topicsCurrentPage = 1;
                                          _recurringFuture = _fetchRecurring();
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(color: isSelected ? _C.primary.withValues(alpha: 0.10) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? _C.primary : _C.divider, width: isSelected ? 1.5 : 1)),
                                        child: Row(children: [
                                          if (isAll)
                                            Container(width: 40, height: 40, decoration: BoxDecoration(color: isSelected ? _C.primary : const Color(0xFFF0F9FF), shape: BoxShape.circle, border: Border.all(color: _C.divider)), child: Icon(Icons.group_rounded, color: isSelected ? Colors.white : _C.primary, size: 20))
                                          else if (avatarUrl != null && avatarUrl.isNotEmpty)
                                            CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl), onBackgroundImageError: (_, __) {}, backgroundColor: const Color(0xFFE0F2FE))
                                          else
                                            CircleAvatar(radius: 20, backgroundColor: isSelected ? _C.primary : const Color(0xFFE0F2FE), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? Colors.white : _C.primary))),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text(isAll ? _t('Semua Penemu', 'All Finders', '所有发现者') : name,
                                                  style: isAll
                                                      ? TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? _C.primary : _C.textPrimary)
                                                      : GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                                              if (!isAll) ...[
                                                const SizedBox(height: 4),
                                                _buildJabatanBadge(idJabatan: idJabatan, jabatanNama: jabatanNama, isVerificator: isVerificator),
                                              ],
                                            ]),
                                          ),
                                          if (isSelected) const Icon(Icons.check_circle_rounded, color: _C.primary, size: 18),
                                        ]),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (totalPages > 1)
                                _AccidentPagePickerIndicator(currentPage: safePage, totalPages: totalPages, color: _C.primary, onPageChanged: (p) => setSt(() => currentPage = p)),
                            ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─── CARD TOPIK (gaya sama seperti 5R: strip keseringan + total besar) ──────
class _AccidentRecurringCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final String               lang;
  final VoidCallback         onTap;
  const _AccidentRecurringCard({required this.group, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final topic        = group['topic'] as String? ?? '-';
    final locationArea = group['locationArea'] as String? ?? '';
    final total        = group['total'] as int? ?? 0;
    final imageUrl      = group['imageUrl'] as String?;
    Color severityColor; IconData severityIcon; String severity;
    if (total >= 6) {
      severityColor = _C.red;
      severityIcon = Icons.autorenew_rounded;
      severity = lang == 'ID' ? 'Sering Terjadi' : lang == 'ZH' ? '频繁发生' : 'Frequent';
    } else if (total >= 3) {
      severityColor = _C.amber;
      severityIcon = Icons.autorenew_rounded;
      severity = lang == 'ID' ? 'Cukup Sering' : lang == 'ZH' ? '较常见' : 'Recurring';
    } else {
      severityColor = _C.green;
      severityIcon = Icons.autorenew_rounded;
      severity = lang == 'ID' ? 'Jarang' : lang == 'ZH' ? '较少' : 'Occasional';
    }

    final occurrenceLabel = lang == 'ID' ? '$total kejadian' : lang == 'ZH' ? '$total 次' : '$total occurrences';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: severityColor.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [BoxShadow(color: severityColor.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: severityColor.withValues(alpha: 0.10), borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5))),
            child: Row(children: [
              Icon(severityIcon, size: 13, color: severityColor),
              const SizedBox(width: 4),
              Text(severity, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: severityColor)),
              const Spacer(),
              Text(occurrenceLabel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: severityColor)),
            ]),
          ),
          Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15)),
              child: Container(
                width: 78, height: 78, color: severityColor.withValues(alpha: 0.10),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(severityIcon, color: severityColor, size: 30))
                    : Icon(severityIcon, color: severityColor, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(topic, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (locationArea.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.location_on_rounded, size: 12, color: _C.primary),
                        const SizedBox(width: 4),
                        Flexible(child: Text(locationArea, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _C.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                ]),
              ),
            ),
            Padding(padding: const EdgeInsets.only(right: 14), child: Icon(Icons.chevron_right_rounded, color: Colors.black, size: 22)),
          ]),
        ]),
      ),
    );
  }
}

class _AccidentPagePickerIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _AccidentPagePickerIndicator({required this.currentPage, required this.totalPages, required this.color, required this.onPageChanged});

  static const int _maxVisibleButtons = 5;
  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) return List.generate(totalPages, (i) => i + 1);
    int start = currentPage - 2; int end = currentPage + 2;
    if (start < 1) { start = 1; end = _maxVisibleButtons; }
    else if (end > totalPages) { end = totalPages; start = totalPages - (_maxVisibleButtons - 1); }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        GestureDetector(
          onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
          child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: canPrev ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: canPrev ? color : Colors.grey.shade400)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Row(children: [
          for (final p in pageNumbers) ...[
            Expanded(child: GestureDetector(
              onTap: () => p == currentPage ? null : onPageChanged(p),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 34, alignment: Alignment.center,
                  decoration: BoxDecoration(color: p == currentPage ? color : color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: p == currentPage ? null : Border.all(color: color.withValues(alpha: 0.25))),
                  child: Text('$p', style: GoogleFonts.poppins(color: p == currentPage ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13))),
            )),
            if (p != pageNumbers.last) const SizedBox(width: 8),
          ],
        ])),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: canNext ? () => onPageChanged(currentPage + 1) : null,
          child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: canNext ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: canNext ? color : Colors.grey.shade400)),
        ),
      ]),
    );
  }
}

// KARTU DETAIL — GAYA SAMA SEPERTI accident_report_screen.dart (_buildCard), tanpa tombol edit/hapus
class _AccidentDetailCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final VoidCallback onTap;
  const _AccidentDetailCard({required this.data, required this.lang, required this.onTap});

  Map<String, dynamic> _locationBadgeInfo(Map<String, dynamic> r) {
    if (r['area'] != null && r['area']['nama_area'] != null) {
      return {'label': r['area']['nama_area'].toString(), 'icon': Icons.place_rounded, 'color': const Color(0xFFF472B6)};
    }
    if (r['subunit'] != null && r['subunit']['nama_subunit'] != null) {
      return {'label': r['subunit']['nama_subunit'].toString(), 'icon': Icons.layers_rounded, 'color': const Color(0xFFFBBF24)};
    }
    if (r['unit'] != null && r['unit']['nama_unit'] != null) {
      return {'label': r['unit']['nama_unit'].toString(), 'icon': Icons.business_rounded, 'color': const Color(0xFF6366F1)};
    }
    if (r['lokasi'] != null && r['lokasi']['nama_lokasi'] != null) {
      return {'label': r['lokasi']['nama_lokasi'].toString(), 'icon': Icons.location_city_rounded, 'color': const Color(0xFF10B981)};
    }
    return {'label': '-', 'icon': Icons.location_off_rounded, 'color': const Color(0xFF94A3B8)};
  }

  @override
  Widget build(BuildContext context) {
    final severityKey = data['tingkat_keparahan'];
    final severityLabel = AccidentSeverityData.labelOf(severityKey, lang);
    final severityIcon = AccidentSeverityData.iconOf(severityKey);
    final sevColor = AccidentSeverityData.colorOf(severityKey);
    final penyebabKey = data['penyebab'];
    final penyebabLabel = AccidentCauseData.labelOf(penyebabKey, lang);
    final penyebabIcon = AccidentCauseData.iconOf(penyebabKey);
    final penyebabColor = AccidentCauseData.colorOf(penyebabKey);
    final status = (data['status'] ?? 'Menunggu').toString();

    Color statusColor; Color statusBg; IconData statusIcon; String statusText;
    switch (status) {
      case 'Ditinjau':
        statusColor = const Color(0xFF2563EB); statusBg = const Color(0xFFEFF6FF); statusIcon = Icons.visibility_rounded;
        statusText = lang == 'ID' ? 'Ditinjau' : lang == 'ZH' ? '审核中' : 'Under Review'; break;
      case 'Selesai':
        statusColor = const Color(0xFF16A34A); statusBg = const Color(0xFFF0FDF4); statusIcon = Icons.check_circle_rounded;
        statusText = lang == 'ID' ? 'Selesai' : lang == 'ZH' ? '已完成' : 'Completed'; break;
      default:
        statusColor = const Color(0xFFDC2626); statusBg = const Color(0xFFFEF2F2); statusIcon = Icons.pending_actions_rounded;
        statusText = lang == 'ID' ? 'Menunggu' : lang == 'ZH' ? '等待中' : 'Pending';
    }

    final dateStr = data['tanggal_kejadian'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(data['tanggal_kejadian']))
        : '-';
    final loc = _locationBadgeInfo(data);
    final locColor = loc['color'] as Color;
    const double imgSize = 85;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFFF63B3B).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: imgSize, height: imgSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [sevColor.withValues(alpha: 0.15), sevColor.withValues(alpha: 0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.5),
                child: data['foto_bukti'] != null
                    ? Image.network(data['foto_bukti'], width: imgSize, height: imgSize, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.warning_amber_rounded, color: sevColor, size: 30))
                    : Icon(Icons.warning_amber_rounded, color: sevColor, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(data['judul'] ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3, color: const Color(0xFF0F172A)))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9), border: Border.all(color: sevColor, width: 1.2)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(severityIcon, size: 11, color: sevColor),
                      const SizedBox(width: 3),
                      Text(severityLabel, style: GoogleFonts.poppins(color: sevColor, fontWeight: FontWeight.w800, fontSize: 10)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: locColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: locColor.withValues(alpha: 0.4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(loc['icon'] as IconData, size: 12, color: locColor),
                    const SizedBox(width: 4),
                    Flexible(child: Text(loc['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: locColor))),
                  ]),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: penyebabColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(penyebabIcon, size: 10, color: penyebabColor),
                    const SizedBox(width: 4),
                    Text(penyebabLabel, style: GoogleFonts.poppins(fontSize: 11, color: penyebabColor, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1)),
                  child: Row(children: [
                    const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text(dateStr, style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF475569), fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: statusColor.withValues(alpha: 0.35))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusText, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AccidentTopicDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final String lang;
  final Color severityColor;
  final String severityLabel;

  const _AccidentTopicDetailScreen({required this.group, required this.lang, required this.severityColor, required this.severityLabel});

  @override
  State<_AccidentTopicDetailScreen> createState() => _AccidentTopicDetailScreenState();
}

class _AccidentTopicDetailScreenState extends State<_AccidentTopicDetailScreen> {
  int _currentPage = 1;
  static const int _perPage = 7;

  @override
  Widget build(BuildContext context) {
    final topic = widget.group['topic'] as String? ?? '-';
    final total = widget.group['total'] as int? ?? 0;
    final reports = widget.group['reports'] as List<Map<String, dynamic>>;
    final color = widget.severityColor;

    final totalPages = reports.isEmpty ? 1 : (reports.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > reports.length ? reports.length : startIdx + _perPage;
    final pageItems = reports.isEmpty ? <Map<String, dynamic>>[] : reports.sublist(startIdx, endIdx);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
        centerTitle: true,
        title: Text(
          widget.lang == 'ID' ? 'Detail Berulang' : widget.lang == 'ZH' ? '重复详情' : 'Recurring Detail',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black),
        ),
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.3),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.4))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.autorenew_rounded, size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(widget.severityLabel, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ]),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.bar_chart_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('${widget.lang == 'ID' ? 'Total' : widget.lang == 'ZH' ? '总计' : 'Total'}: $total', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Text(topic, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
            if ((widget.group['locationArea'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.primary.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_on_rounded, size: 13, color: _C.primary),
                  const SizedBox(width: 5),
                  Flexible(child: Text(widget.group['locationArea'] as String,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.primary),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: reports.isEmpty
              ? Center(child: Text('-', style: GoogleFonts.poppins(color: const Color(0xFF64748B))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: pageItems.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AccidentDetailCard(
                      data: pageItems[i], lang: widget.lang,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccidentReportDetailScreen(
                            reportId: pageItems[i]['id_laporan'].toString(),
                            lang: widget.lang,
                            initialData: pageItems[i], // data instan, tanpa loading
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        if (totalPages > 1)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewPadding.bottom + 12),
            child: _AccidentPagePickerIndicator(currentPage: safePage, totalPages: totalPages, color: color, onPageChanged: (p) => setState(() => _currentPage = p)),
          )
        else
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 12),
      ]),
    );
  }
}