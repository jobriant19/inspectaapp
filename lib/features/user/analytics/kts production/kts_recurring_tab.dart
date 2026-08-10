import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/ai_recurring_service.dart';
import '../../../../core/utils/jabatan_helper.dart';
import '../../../admin/target/target/admin_target_pick_date.dart';
import '../../home/card/kts_finding_card.dart';
import '../../ktsproduksi/kts_detail_screen.dart';

class _AppColors {
  static const primary = Color(0xFFF59E0B);
  static const primaryLight = Color(0xFFFEF3C7);
  static const surface = Color(0xFFFFFBEB);
  static const textPrimary = Color(0xFF78350F);
  static const textMuted = Color(0xFFD97706);
  static const divider = Color(0xFFFDE68A);
  static const periodAccent = Color(0xFF1D72F3);
}

class KTSRecurringTopic {
  final String topic;
  final String locationArea;
  final int total;
  final String? imageUrl;
  final List<Map<String, dynamic>> findings;

  const KTSRecurringTopic({
    required this.topic,
    required this.locationArea,
    required this.total,
    this.imageUrl,
    required this.findings,
  });
}

class KtsRecurringTab extends StatefulWidget {
  final String lang;

  const KtsRecurringTab({super.key, required this.lang});

  @override
  State<KtsRecurringTab> createState() => _KtsRecurringTabState();
}

class _KtsRecurringTabState extends State<KtsRecurringTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'temuan_berulang': 'Temuan Berulang',
      'tidak_ada_data': 'Belum ada temuan KTS Production yang berulang.',
      'belum_memiliki_temuan': 'belum\nmemiliki temuan berulang',
      'topik': 'Topik',
      'pilih_periode': 'Pilih Periode',
      'pilih_penemu': 'Pilih Penemu',
      'cari': 'Cari...',
      'dari': 'Dari',
      'sampai': 'Sampai',
      'terapkan': 'Terapkan',
      'total': 'Total',
      'daftar_temuan': 'Daftar Temuan',
      'semua_penemu': 'Semua Penemu',
      'level_lokasi': 'Lokasi',
      'level_unit': 'Unit',
      'level_subunit': 'Subunit',
      'level_area': 'Area',
      'pilih_lokasi': 'Pilih Lokasi',
      'semua_grup_anggota': 'Semua',
      'tidak_ada_data_level': 'Tidak ada data untuk level ini.',
    },
    'EN': {
      'temuan_berulang': 'Recurring Findings',
      'tidak_ada_data': 'No recurring KTS Production findings yet.',
      'belum_memiliki_temuan': 'does not have\nrecurring findings yet',
      'topik': 'Topic',
      'pilih_periode': 'Select Period',
      'pilih_penemu': 'Select Finder',
      'cari': 'Search...',
      'dari': 'From',
      'sampai': 'To',
      'terapkan': 'Apply',
      'total': 'Total',
      'daftar_temuan': 'Finding List',
      'semua_penemu': 'All Finders',
      'level_lokasi': 'Location',
      'level_unit': 'Unit',
      'level_subunit': 'Sub-unit',
      'level_area': 'Area',
      'pilih_lokasi': 'Select Location',
      'semua_grup_anggota': 'All',
      'tidak_ada_data_level': 'No data for this level.',
    },
    'ZH': {
      'temuan_berulang': '重复发现',
      'tidak_ada_data': '暂无重复的KTS生产发现。',
      'belum_memiliki_temuan': '还没有\n重复的发现',
      'topik': '话题',
      'pilih_periode': '选择期间',
      'pilih_penemu': '选择发现者',
      'cari': '搜索...',
      'dari': '从',
      'sampai': '到',
      'terapkan': '应用',
      'total': '总计',
      'daftar_temuan': '发现列表',
      'semua_penemu': '所有发现者',
      'level_lokasi': '位置',
      'level_unit': '单元',
      'level_subunit': '子单元',
      'level_area': '区域',
      'pilih_lokasi': '选择位置',
      'semua_grup_anggota': '全部',
      'tidak_ada_data_level': '此级别没有数据。',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  static const List<Color> _levelColors = [
    Color(0xFF10B981), Color(0xFF6366F1), Color(0xFFFBBF24), Color(0xFFF472B6),
  ];
  Color _colorForLocLevel(String lvl) =>
      _levelColors[['Lokasi', 'Unit', 'Subunit', 'Area'].indexOf(lvl).clamp(0, 3)];
  IconData _iconForLocLevel(String lvl) {
    switch (lvl) {
      case 'Unit': return Icons.business_rounded;
      case 'Subunit': return Icons.layers_rounded;
      case 'Area': return Icons.place_rounded;
      default: return Icons.location_city_rounded;
    }
  }

  Color _severityColor(int total) {
    if (total >= 6) return const Color(0xFFEF4444);
    if (total >= 3) return _AppColors.primary;
    return const Color(0xFF10B981);
  }

  String _severityLabel(int total) {
    if (total >= 6) return widget.lang == 'ID' ? 'Sering Terjadi' : widget.lang == 'ZH' ? '频繁发生' : 'Frequent';
    if (total >= 3) return widget.lang == 'ID' ? 'Cukup Sering' : widget.lang == 'ZH' ? '较常见' : 'Recurring';
    return widget.lang == 'ID' ? 'Jarang' : widget.lang == 'ZH' ? '较少' : 'Occasional';
  }

  // STATE
  DateTime _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo = DateTime.now();
  String? _recurringUserId;
  String _recurringUserName = '';

  Future<List<KTSRecurringTopic>>? _recurringFuture;
  int _topicsCurrentPage = 1;
  static const int _topicsPerPage = 7;

  @override
  void initState() {
    super.initState();
    _recurringFuture = _fetchRecurringData();
  }

  bool get _isPeriodDefault {
    final now = DateTime.now();
    final defaultFrom = DateTime(now.year - 1, now.month);
    return _recurringFrom.year == defaultFrom.year &&
        _recurringFrom.month == defaultFrom.month &&
        _recurringTo.year == now.year &&
        _recurringTo.month == now.month;
  }

  String _levelLabel(String backendLevel) {
    switch (backendLevel) {
      case 'Unit':
        return getTxt('level_unit');
      case 'Subunit':
        return getTxt('level_subunit');
      case 'Area':
        return getTxt('level_area');
      default:
        return getTxt('level_lokasi');
    }
  }

  // DATA FETCHING (TETAP: hanya jenis_temuan = KTS Production)
  Future<List<KTSRecurringTopic>> _fetchRecurringData() async {
    try {
      var query = _supabase
          .from('temuan')
          .select('''
            id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan,
            poin_temuan, target_waktu_selesai, jenis_temuan,
            id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, id_user,
            lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
            kategoritemuan(nama_kategoritemuan),
            is_pro, is_visitor, is_eksekutif, no_order, jumlah_item,
            penyelesaian!temuan_id_penyelesaian_fkey(
              *, User_Solver:User!id_user(nama, gambar_user),
              faktor_penyebab:id_subkategoritemuan_penyebab(id_subkategoritemuan, nama_subkategoritemuan),
              section:id_section(nama_section_id, nama_section_en, nama_section_zh)
            ),
            User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
            User_PIC:User!temuan_id_penanggung_jawab_fkey(id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
            id_penyelesaian, nama_item_manual, deskripsi_temuan,
            item_produksi:id_item(id_item, nama_item, gambar_item, kode_item),
            subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan)
          ''')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', _recurringFrom.toIso8601String())
          .lte(
              'created_at',
              DateTime(_recurringTo.year, _recurringTo.month + 1, 0, 23, 59,
                      59)
                  .toIso8601String());

      if (_recurringUserId != null) {
        query = query.eq('id_user', _recurringUserId!);
      }

      final List<dynamic> response =
          await query.order('created_at', ascending: false);
      final findings = List<Map<String, dynamic>>.from(response);
      if (findings.isEmpty) return [];

      final groups = await GeminiRecurringService.instance.analyzeFindings(
        findings,
        isKts: true,
        fromDate: _recurringFrom,
        toDate: _recurringTo,
        filterUserId: _recurringUserId,
        lang: widget.lang,
      );

      return groups
          .map((g) => KTSRecurringTopic(
                topic: g.topic,
                locationArea: g.locationArea,
                total: g.total,
                imageUrl: g.imageUrl,
                findings: g.findings,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching KTS Recurring: $e');
      return [];
    }
  }

  void _refresh() {
    setState(() {
      _topicsCurrentPage = 1;
      _recurringFuture = _fetchRecurringData();
    });
  }

  // ─── FILTER BUTTON (gaya sama seperti 5R Recurring, warna biru) ───────────
  void _resetPeriod() {
    setState(() {
      _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
      _recurringTo = DateTime.now();
    });
    _refresh();
  }

  void _resetFinder() {
    setState(() {
      _recurringUserId = null;
      _recurringUserName = '';
    });
    _refresh();
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
          border: Border.all(color: _AppColors.periodAccent, width: 1.5),
          boxShadow: [BoxShadow(color: _AppColors.periodAccent.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15, color: _AppColors.periodAccent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(periodLabel,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _AppColors.periodAccent)),
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildFinderFilterButton() {
    final isActive = _recurringUserId != null;
    final label = _recurringUserName.isEmpty ? getTxt('semua_penemu') : _recurringUserName;
    return GestureDetector(
      onTap: _showUserPicker,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _AppColors.periodAccent, width: 1.5),
          boxShadow: [BoxShadow(color: _AppColors.periodAccent.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(Icons.person_search_rounded, size: 15, color: _AppColors.periodAccent),
          const SizedBox(width: 5),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.periodAccent)),
          ),
          if (isActive)
            GestureDetector(
              onTap: _resetFinder,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.45)),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF4444)),
              ),
            )
          else
            Icon(Icons.keyboard_arrow_down_rounded, color: _AppColors.periodAccent, size: 18),
        ]),
      ),
    );
  }

  // FILTER PICKERS (gaya sama persis seperti 5R Recurring)
  void _showPeriodPicker() async {
    DateTime tempFrom = _recurringFrom;
    DateTime tempTo = _recurringTo;

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
            Icon(labelIcon, size: 13, color: _AppColors.periodAccent),
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
                color: _AppColors.periodAccent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _AppColors.periodAccent.withValues(alpha: 0.35)),
              ),
              child: Row(children: [
                Icon(Icons.event_rounded, size: 17, color: _AppColors.periodAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('EEE, d MMM yyyy').format(value),
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0C3A8C)),
                  ),
                ),
                Icon(Icons.keyboard_arrow_right_rounded, size: 18, color: _AppColors.periodAccent),
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
              border: Border.all(color: _AppColors.periodAccent.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _AppColors.periodAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.date_range_rounded, color: _AppColors.periodAccent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      getTxt('pilih_periode'),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0C3A8C)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),

                dateField(
                  label: getTxt('dari'),
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
                  label: getTxt('sampai'),
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
                        _recurringFrom = tempFrom;
                        _recurringTo = tempTo;
                      });
                      Navigator.pop(ctx);
                      _refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AppColors.periodAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(getTxt('terapkan'),
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

  // ─── Badge jabatan (sama seperti 5R) ───────────────────────────────────────
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
                border: Border.all(color: _AppColors.periodAccent.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _AppColors.periodAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.tune_rounded, color: _AppColors.periodAccent, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(getTxt('pilih_lokasi'), style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: _AppColors.periodAccent))),
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
                        hintText: getTxt('cari'), hintStyle: const TextStyle(fontSize: 12.5, color: _AppColors.textMuted),
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
                const Divider(height: 1, color: _AppColors.divider),
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
                                    decoration: BoxDecoration(color: tempId == null ? currentColor.withValues(alpha: 0.10) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: tempId == null ? currentColor : _AppColors.divider, width: tempId == null ? 1.5 : 1)),
                                    child: Row(children: [
                                      Container(width: 44, height: 44, alignment: Alignment.center,
                                          decoration: BoxDecoration(color: currentColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                                          child: Icon(Icons.map_rounded, size: 20, color: currentColor)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('${getTxt('semua_grup_anggota')} (${_levelLabel(tempLevel)})',
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: tempId == null ? FontWeight.w700 : FontWeight.w600, color: tempId == null ? currentColor : _AppColors.textPrimary))),
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
                                      Text(getTxt('tidak_ada_data_level'), style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: currentColor), textAlign: TextAlign.center),
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
                                        decoration: BoxDecoration(color: isSel ? currentColor.withValues(alpha: 0.10) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isSel ? currentColor : _AppColors.divider, width: isSel ? 1.5 : 1)),
                                        child: Row(children: [
                                          Container(width: 44, height: 44, alignment: Alignment.center,
                                              decoration: BoxDecoration(color: currentColor.withValues(alpha: isSel ? 0.20 : 0.14), borderRadius: BorderRadius.circular(12)),
                                              child: Icon(levelIcon(tempLevel), size: 20, color: currentColor)),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(item['name']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isSel ? currentColor : _AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                                          if (isSel) Icon(Icons.check_circle_rounded, color: currentColor, size: 18),
                                        ]),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          if (totalLocPages > 1 && filteredLoc.isNotEmpty)
                            _KtsPagePickerIndicator(currentPage: safeLocPage, totalPages: totalLocPages, color: currentColor, onPageChanged: (p) => setSt(() => locCurrentPage = p)),
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
          'id_user': null, 'nama': getTxt('pilih_penemu'),
          'gambar_user': null, 'jabatan': null, 'id_jabatan': null, 'is_verificator': null,
        };
        items = [allItem, ...users];
      } catch (e) {
        items = [];
      }
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.periodAccent.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _AppColors.periodAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person_search_rounded, color: _AppColors.periodAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(getTxt('pilih_penemu'),
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, color: _AppColors.periodAccent)),
                    ),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _AppColors.periodAccent.withValues(alpha: 0.35), width: 1.3),
                        ),
                        child: TextField(
                          controller: ctrl,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (q) {
                            filtered = q.trim().isEmpty
                                ? List.from(items)
                                : items.where((e) => (e['nama'] as String).toLowerCase().contains(q.toLowerCase())).toList();
                            currentPage = 1;
                            setSt(() {});
                          },
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: getTxt('cari'),
                            hintStyle: const TextStyle(fontSize: 12.5, color: _AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: _AppColors.periodAccent, size: 19),
                            suffixIcon: ctrl.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () { ctrl.clear(); filtered = List.from(items); currentPage = 1; setSt(() {}); },
                                    child: Container(
                                      margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                                    ),
                                  )
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
                        decoration: BoxDecoration(
                          color: currentLocId != null ? _AppColors.periodAccent : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: currentLocId != null ? _AppColors.periodAccent : _AppColors.periodAccent.withValues(alpha: 0.35), width: 1.3),
                        ),
                        child: Icon(Icons.map, color: currentLocId != null ? Colors.white : _AppColors.periodAccent, size: 20),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _AppColors.periodAccent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _AppColors.periodAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.groups_rounded, size: 13, color: _AppColors.periodAccent),
                        const SizedBox(width: 5),
                        Text('${filtered.length} ${widget.lang == 'ID' ? 'Penemu' : widget.lang == 'ZH' ? '发现者' : 'Finders'}',
                            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: _AppColors.periodAccent)),
                      ]),
                    ),
                    const Spacer(),
                    if (currentLocName != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 165),
                        child: Container(
                          padding: const EdgeInsets.only(left: 9, right: 4, top: 3, bottom: 3),
                          decoration: BoxDecoration(
                            color: _colorForLocLevel(currentLocLevel).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _colorForLocLevel(currentLocLevel).withValues(alpha: 0.4)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_iconForLocLevel(currentLocLevel), size: 11, color: _colorForLocLevel(currentLocLevel)),
                            const SizedBox(width: 4),
                            Flexible(child: Text(currentLocName!,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _colorForLocLevel(currentLocLevel)),
                                overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () { currentLocId = null; currentLocName = null; loadUsers(setSt); },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.15), shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, size: 10, color: Color(0xFFEF4444)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                  ]),
                ),
                const Divider(height: 1, color: _AppColors.divider),
                Expanded(
                  child: loadingUsers
                      ? Shimmer.fromColors(
                          baseColor: Colors.grey[200]!, highlightColor: Colors.grey[50]!,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 6, bottom: 12),
                            itemCount: 6,
                            itemBuilder: (_, __) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _AppColors.divider)),
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
                                    errorBuilder: (_, __, ___) => Container(width: 84, height: 84,
                                        decoration: BoxDecoration(color: _AppColors.periodAccent.withValues(alpha: 0.08), shape: BoxShape.circle),
                                        child: const Icon(Icons.search_off_rounded, size: 36, color: _AppColors.periodAccent))),
                                const SizedBox(height: 12),
                                Text(widget.lang == 'EN' ? 'No users found' : widget.lang == 'ZH' ? '未找到用户' : 'Pengguna tidak ditemukan',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.periodAccent), textAlign: TextAlign.center),
                                if (ctrl.text.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () { ctrl.clear(); filtered = List.from(items); currentPage = 1; setSt(() {}); },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                      decoration: BoxDecoration(color: _AppColors.periodAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: _AppColors.periodAccent.withValues(alpha: 0.35))),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.refresh_rounded, size: 14, color: _AppColors.periodAccent),
                                        const SizedBox(width: 6),
                                        Text(widget.lang == 'EN' ? 'Clear search' : widget.lang == 'ZH' ? '清除搜索' : 'Hapus pencarian',
                                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.periodAccent)),
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
                                          _recurringUserName = isAll ? getTxt('semua_penemu') : name;
                                        });
                                        _refresh();
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? _AppColors.periodAccent.withValues(alpha: 0.10) : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isSelected ? _AppColors.periodAccent : _AppColors.divider, width: isSelected ? 1.5 : 1),
                                        ),
                                        child: Row(children: [
                                          if (isAll)
                                            Container(width: 40, height: 40,
                                                decoration: BoxDecoration(color: isSelected ? _AppColors.periodAccent : _AppColors.surface, shape: BoxShape.circle, border: Border.all(color: _AppColors.primaryLight)),
                                                child: Icon(Icons.group_rounded, color: isSelected ? Colors.white : _AppColors.periodAccent, size: 20))
                                          else if (avatarUrl != null && avatarUrl.isNotEmpty)
                                            CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl), onBackgroundImageError: (_, __) {}, backgroundColor: _AppColors.primaryLight)
                                          else
                                            CircleAvatar(radius: 20, backgroundColor: isSelected ? _AppColors.periodAccent : _AppColors.primaryLight,
                                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? Colors.white : _AppColors.periodAccent))),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text(isAll ? getTxt('semua_penemu') : name,
                                                  style: isAll
                                                      ? TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? _AppColors.periodAccent : _AppColors.textPrimary)
                                                      : GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                                              if (!isAll) ...[
                                                const SizedBox(height: 4),
                                                _buildJabatanBadge(idJabatan: idJabatan, jabatanNama: jabatanNama, isVerificator: isVerificator),
                                              ],
                                            ]),
                                          ),
                                          if (isSelected) const Icon(Icons.check_circle_rounded, color: _AppColors.periodAccent, size: 18),
                                        ]),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (totalPages > 1)
                                _KtsPagePickerIndicator(
                                  currentPage: safePage, totalPages: totalPages, color: _AppColors.periodAccent,
                                  onPageChanged: (p) => setSt(() => currentPage = p),
                                ),
                            ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ─── SHIMMER ────────────────────────────────────────────────────────────────
  Widget _buildShimmerBox(
      {double? width, required double height, double borderRadius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildRecurringShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(
              width: 78,
              height: 78,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShimmerBox(
                      height: 14, width: double.infinity),
                  const SizedBox(height: 6),
                  _buildShimmerBox(height: 12, width: 120),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── EMPTY STATE (ilustrasi + teks sesuai bahasa, gaya lebih menarik) ─────
  Widget _buildEmptyState() {
    final name = _recurringUserName.isEmpty ? '' : _recurringUserName;
    final message = name.isEmpty
        ? getTxt('tidak_ada_data')
        : '$name ${getTxt('belum_memiliki_temuan')}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _AppColors.primaryLight, width: 1.5),
              ),
              child: Image.asset(
                'assets/images/team_illustration.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                      color: _AppColors.primaryLight, shape: BoxShape.circle),
                  child: Icon(Icons.search_off_rounded,
                      size: 44, color: _AppColors.primary.withValues(alpha: 0.6)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.autorenew_rounded, size: 13, color: _AppColors.primary),
                const SizedBox(width: 5),
                Text(getTxt('temuan_berulang'),
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _AppColors.primary)),
              ]),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: _AppColors.textPrimary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CARD TOPIK (gaya sama seperti 5R: strip keseringan + total besar) ────
  Widget _buildTopicCard(KTSRecurringTopic topic) {
    final severityColor = _severityColor(topic.total);
    final severityLabel = _severityLabel(topic.total);
    final String occurrenceLabel = widget.lang == 'ID' ? '${topic.total} kejadian' : widget.lang == 'ZH' ? '${topic.total} 次' : '${topic.total} occurrences';

    return GestureDetector(
      onTap: () => _showDetail(topic),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
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
              Icon(Icons.autorenew_rounded, size: 13, color: severityColor),
              const SizedBox(width: 4),
              Text(severityLabel, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: severityColor)),
              const Spacer(),
              Text(occurrenceLabel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: severityColor)),
            ]),
          ),
          Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15)),
              child: Container(
                width: 78, height: 78, color: _AppColors.primaryLight,
                child: topic.imageUrl != null && topic.imageUrl!.isNotEmpty
                    ? Image.network(topic.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: _AppColors.textMuted))
                    : const Icon(Icons.image_outlined, color: _AppColors.textMuted, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(topic.topic, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.apartment_rounded, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Flexible(child: Text('${widget.lang == 'ID' ? 'Section' : widget.lang == 'ZH' ? '部门' : 'Section'}: ${topic.locationArea}',
                          style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)), maxLines: 1, overflow: TextOverflow.ellipsis)),
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

  void _showDetail(KTSRecurringTopic topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _KtsTopicDetailScreen(
          topic: topic, lang: widget.lang,
          severityColor: _severityColor(topic.total),
          severityLabel: _severityLabel(topic.total),
        ),
      ),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final fromLabel =
        DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel = DateFormat('MMM yyyy', locale).format(_recurringTo);
    final periodLabel = '$fromLabel - $toLabel';

    return Column(children: [
      // FILTER ROW
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: _buildPeriodFilterButton(periodLabel)),
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
            color: _AppColors.periodAccent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _AppColors.periodAccent.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: _AppColors.periodAccent, shape: BoxShape.circle),
              child: const Icon(Icons.autorenew_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(getTxt('topik'),
                      style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _AppColors.periodAccent)),
                  const SizedBox(height: 3),
                  Text(
                    widget.lang == 'ID'
                        ? 'Temuan KTS Production dengan section atau pola serupa dikelompokkan otomatis'
                        : widget.lang == 'ZH'
                            ? '相似部门或模式的KTS生产发现会自动分组'
                            : 'KTS Production findings with similar sections or patterns are grouped automatically',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.periodAccent,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),

      Expanded(
        child: FutureBuilder<List<KTSRecurringTopic>>(
          future: _recurringFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildRecurringShimmer();
            }
            final topics = snapshot.data ?? [];
            if (topics.isEmpty) {
              return _buildEmptyState();
            }
            final totalTopicPages = (topics.length / _topicsPerPage).ceil().clamp(1, 999999);
            final safeTopicPage = _topicsCurrentPage.clamp(1, totalTopicPages);
            final tStart = (safeTopicPage - 1) * _topicsPerPage;
            final tEnd = (tStart + _topicsPerPage) > topics.length ? topics.length : tStart + _topicsPerPage;
            final pagedTopics = topics.sublist(tStart, tEnd);

            return Column(children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: pagedTopics.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _buildTopicCard(pagedTopics[i]),
                ),
              ),
              if (totalTopicPages > 1)
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, MediaQuery.of(context).viewPadding.bottom + 10),
                  child: _KtsPagePickerIndicator(
                    currentPage: safeTopicPage, totalPages: totalTopicPages, color: _AppColors.primary,
                    onPageChanged: (p) => setState(() => _topicsCurrentPage = p),
                  ),
                )
              else
                SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 10),
            ]);
          },
        ),
      ),
    ]);
  }
}

class _KtsPagePickerIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _KtsPagePickerIndicator({required this.currentPage, required this.totalPages, required this.color, required this.onPageChanged});

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
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        GestureDetector(
          onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
          child: Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: canPrev ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08), shape: BoxShape.circle),
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
          child: Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: canNext ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: canNext ? color : Colors.grey.shade400)),
        ),
      ]),
    );
  }
}

class _KtsTopicDetailScreen extends StatefulWidget {
  final KTSRecurringTopic topic;
  final String lang;
  final Color severityColor;
  final String severityLabel;

  const _KtsTopicDetailScreen({required this.topic, required this.lang, required this.severityColor, required this.severityLabel});

  @override
  State<_KtsTopicDetailScreen> createState() => _KtsTopicDetailScreenState();
}

class _KtsTopicDetailScreenState extends State<_KtsTopicDetailScreen> {
  int _currentPage = 1;
  static const int _perPage = 7;

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final color = widget.severityColor;

    final totalPages = topic.findings.isEmpty ? 1 : (topic.findings.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > topic.findings.length ? topic.findings.length : startIdx + _perPage;
    final pageItems = topic.findings.isEmpty ? <Map<String, dynamic>>[] : topic.findings.sublist(startIdx, endIdx);

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
                  Text('${widget.lang == 'ID' ? 'Total' : widget.lang == 'ZH' ? '总计' : 'Total'}: ${topic.total}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.apartment_rounded, size: 13, color: Color(0xFFD97706)),
                const SizedBox(width: 5),
                Flexible(child: Text('${widget.lang == 'ID' ? 'Section' : widget.lang == 'ZH' ? '部门' : 'Section'}: ${topic.locationArea}',
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: topic.findings.isEmpty
              ? Center(child: Text('-', style: GoogleFonts.poppins(color: const Color(0xFF92400E))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: pageItems.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: KtsFindingCard(
                      data: pageItems[i],
                      lang: widget.lang,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KtsDetailScreen(
                            ktsId: pageItems[i]['id_temuan'].toString(),
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
            child: _KtsPagePickerIndicator(currentPage: safePage, totalPages: totalPages, color: color, onPageChanged: (p) => setState(() => _currentPage = p)),
          )
        else
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 12),
      ]),
    );
  }
}