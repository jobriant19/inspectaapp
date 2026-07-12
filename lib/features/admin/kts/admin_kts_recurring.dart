import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/ai_recurring_service.dart';
import '../../../../core/utils/jabatan_helper.dart';
import '../../user/finding/detail/finding_detail_screen.dart';
import '../../user/home/card/kts_finding_card.dart';

class _AppColors {
  static const primary = Color(0xFFF59E0B);
  static const primaryLight = Color(0xFFFEF3C7);
  static const surface = Color(0xFFFFFBEB);
  static const textPrimary = Color(0xFF78350F);
  static const textSecondary = Color(0xFF92400E);
  static const textMuted = Color(0xFFD97706);
  static const divider = Color(0xFFFDE68A);
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

class AdminKtsRecurringTab extends StatefulWidget {
  final String lang;

  const AdminKtsRecurringTab({super.key, required this.lang});

  @override
  State<AdminKtsRecurringTab> createState() => _AdminKtsRecurringTabState();
}

class _AdminKtsRecurringTabState extends State<AdminKtsRecurringTab> {
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

  // STATE
  DateTime _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo = DateTime.now();
  String? _recurringUserId;
  String _recurringUserName = '';

  Future<List<KTSRecurringTopic>>? _recurringFuture;

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
            penyelesaian!temuan_id_penyelesaian_fkey(*, User_Solver:User!id_user(nama, gambar_user)),
            User_Creator:User!temuan_id_user_fkey(nama, gambar_user),
            User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user),
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
    setState(() => _recurringFuture = _fetchRecurringData());
  }

  // ─── FILTER BUTTON (default putih, aktif oranye) ──────────────────────────
  Widget _buildFilterButton({
    required String label,
    required VoidCallback onTap,
    IconData icon = Icons.keyboard_arrow_down_rounded,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? _AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _AppColors.primary : _AppColors.primaryLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _AppColors.primary),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 4),
          Icon(icon, color: isActive ? Colors.white : _AppColors.primary, size: 18),
        ]),
      ),
    );
  }

  // FILTER PICKERS
  void _showPeriodPicker() async {
    DateTime tempFrom = _recurringFrom;
    DateTime tempTo = _recurringTo;
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _AppColors.primaryLight, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.date_range_rounded,
                      color: _AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(getTxt('pilih_periode'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                  ),
                ]),
                const SizedBox(height: 16),
                Text(getTxt('dari'),
                    style: const TextStyle(
                        fontSize: 12,
                        color: _AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _buildYearMonthPicker(
                    tempFrom, locale, (d) => setSt(() => tempFrom = d)),
                const SizedBox(height: 14),
                Text(getTxt('sampai'),
                    style: const TextStyle(
                        fontSize: 12,
                        color: _AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _buildYearMonthPicker(
                    tempTo, locale, (d) => setSt(() => tempTo = d)),
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
                      backgroundColor: _AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(getTxt('terapkan')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearMonthPicker(
      DateTime current, String locale, ValueChanged<DateTime> onChange) {
    final months = List.generate(
        12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);
    return Row(children: [
      Expanded(
        flex: 3,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.primaryLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.month - 1,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: _AppColors.primary),
              style: const TextStyle(
                  fontSize: 13,
                  color: _AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
              dropdownColor: Colors.white,
              items: List.generate(
                  12,
                  (i) =>
                      DropdownMenuItem(value: i, child: Text(months[i]))),
              onChanged: (v) {
                if (v != null) onChange(DateTime(current.year, v + 1));
              },
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.primaryLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.year,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: _AppColors.primary),
              style: const TextStyle(
                  fontSize: 13,
                  color: _AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
              dropdownColor: Colors.white,
              items: years
                  .map((y) =>
                      DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChange(DateTime(v, current.month));
              },
            ),
          ),
        ),
      ),
    ]);
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
            .map((e) => {'id': e[idCol]?.toString() ?? '', 'name': e[nameCol]?.toString() ?? '-'})
            .toList();
      } catch (e) {
        locItems = [];
      }
      loading = false;
      setSt(() {});
    }

    IconData levelIcon(String label) {
      switch (label) {
        case 'Unit': return Icons.business_rounded;
        case 'Subunit': return Icons.layers_rounded;
        case 'Area': return Icons.place_rounded;
        default: return Icons.location_city_rounded;
      }
    }

    return showDialog<Map<String, String?>>(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (!initialized) {
            initialized = true;
            fetchItems(setSt);
          }
          final q = searchCtrl.text.trim().toLowerCase();
          final filteredLoc = q.isEmpty
              ? locItems
              : locItems.where((e) => e['name']!.toLowerCase().contains(q)).toList();

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 320,
              height: MediaQuery.of(parentContext).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.primaryLight, width: 1.5),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: const BoxDecoration(
                    color: _AppColors.primaryLight,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.tune_rounded, color: _AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(getTxt('pilih_lokasi'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                    IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AppColors.primaryLight),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(children: ['Lokasi', 'Unit', 'Subunit', 'Area'].map((lvl) {
                      final isSel = lvl == tempLevel;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            tempLevel = lvl;
                            tempId = null;
                            searchCtrl.clear();
                            fetchItems(setSt);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 34,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSel ? _AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                                child: Text(_levelLabel(lvl),
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSel ? Colors.white : _AppColors.textSecondary))),
                          ),
                        ),
                      );
                    }).toList()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _AppColors.primary.withValues(alpha: 0.35), width: 1.3),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setSt(() {}),
                      style: const TextStyle(fontSize: 13, color: _AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: getTxt('cari'),
                        hintStyle: const TextStyle(fontSize: 12.5, color: _AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: _AppColors.primary, size: 18),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: _AppColors.divider),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator(color: _AppColors.primary, strokeWidth: 2))
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(ctx, {'level': tempLevel, 'id': null, 'name': null}),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: tempId == null ? _AppColors.primary.withValues(alpha: 0.10) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: tempId == null ? _AppColors.primary : _AppColors.divider,
                                      width: tempId == null ? 1.5 : 1),
                                ),
                                child: Row(children: [
                                  Icon(Icons.apps_rounded,
                                      size: 18, color: tempId == null ? _AppColors.primary : _AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text('${getTxt('semua_grup_anggota')} (${_levelLabel(tempLevel)})',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: tempId == null ? FontWeight.bold : FontWeight.w500,
                                              color: tempId == null ? _AppColors.primary : _AppColors.textPrimary))),
                                  if (tempId == null)
                                    const Icon(Icons.check_circle_rounded, color: _AppColors.primary, size: 18),
                                ]),
                              ),
                            ),
                            if (filteredLoc.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                    child: Text(getTxt('tidak_ada_data_level'),
                                        style: const TextStyle(fontSize: 12.5, color: _AppColors.textSecondary))),
                              )
                            else
                              ...filteredLoc.map((item) {
                                final isSel = item['id'] == tempId;
                                return InkWell(
                                  onTap: () =>
                                      Navigator.pop(ctx, {'level': tempLevel, 'id': item['id'], 'name': item['name']}),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSel ? _AppColors.primary.withValues(alpha: 0.10) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: isSel ? _AppColors.primary : _AppColors.divider,
                                          width: isSel ? 1.5 : 1),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSel ? _AppColors.primary : _AppColors.surface,
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Icon(levelIcon(tempLevel),
                                            size: 16, color: isSel ? Colors.white : _AppColors.primary),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(item['name']!,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                                  color: isSel ? _AppColors.primary : _AppColors.textPrimary),
                                              overflow: TextOverflow.ellipsis)),
                                      if (isSel)
                                        const Icon(Icons.check_circle_rounded, color: _AppColors.primary, size: 18),
                                    ]),
                                  ),
                                );
                              }),
                          ],
                        ),
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
          'gambar_user': null, 'jabatan': null,
          'id_jabatan': null, 'is_verificator': null,
        };
        items = [allItem, ...users];
      } catch (e) {
        debugPrint('Error fetching users: $e');
        items = [];
      }
      final q = ctrl.text.trim().toLowerCase();
      filtered = q.isEmpty
          ? List.from(items)
          : items.where((e) => (e['nama'] as String).toLowerCase().contains(q)).toList();
      loadingUsers = false;
      setSt(() {});
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          if (!initialized) {
            initialized = true;
            loadUsers(setSt);
          }
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 340,
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.primaryLight, width: 1.5),
              ),
              child: Column(children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: const BoxDecoration(
                    color: _AppColors.primaryLight,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_search_rounded, color: _AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(getTxt('pilih_penemu'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15, color: _AppColors.textPrimary))),
                    IconButton(
                        icon: const Icon(Icons.close, size: 18, color: _AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero),
                  ]),
                ),
                // SEARCH + FILTER LOKASI (BERSEBELAHAN)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _AppColors.primary.withValues(alpha: 0.35), width: 1.3),
                          boxShadow: [
                            BoxShadow(
                                color: _AppColors.primary.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: TextField(
                          controller: ctrl,
                          onChanged: (q) {
                            filtered = q.trim().isEmpty
                                ? List.from(items)
                                : items
                                    .where((e) => (e['nama'] as String).toLowerCase().contains(q.toLowerCase()))
                                    .toList();
                            setSt(() {});
                          },
                          style: const TextStyle(
                              fontSize: 13, color: _AppColors.textPrimary, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: getTxt('cari'),
                            hintStyle: const TextStyle(fontSize: 12.5, color: _AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: _AppColors.primary, size: 19),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: currentLocId != null ? _AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: currentLocId != null
                                  ? _AppColors.primary
                                  : _AppColors.primary.withValues(alpha: 0.35),
                              width: 1.3),
                          boxShadow: [
                            BoxShadow(
                                color: _AppColors.primary.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Icon(Icons.map,
                            color: currentLocId != null ? Colors.white : _AppColors.primary, size: 20),
                      ),
                    ),
                  ]),
                ),
                // INFO FILTER LOKASI AKTIF + COUNT
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
                  child: Row(children: [
                    Text('${filtered.length} ${widget.lang == 'ID' ? 'penemu' : widget.lang == 'ZH' ? '发现者' : 'finders'}',
                        style: const TextStyle(fontSize: 11, color: _AppColors.textSecondary)),
                    if (currentLocName != null) ...[
                      const Spacer(),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(currentLocName!,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _AppColors.primary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ]),
                ),
                const Divider(height: 1, color: _AppColors.divider),
                // LIST
                Expanded(
                  child: loadingUsers
                      ? const Center(child: CircularProgressIndicator(color: _AppColors.primary, strokeWidth: 2))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final name = item['nama'] as String;
                            final id = item['id_user']?.toString();
                            final avatarUrl = item['gambar_user'] as String?;
                            final idJabatan = item['id_jabatan'] as int?;
                            final isVerificator = item['is_verificator'] as bool?;
                            final jabatanNama =
                                (item['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
                            final isSelected =
                                id == _recurringUserId || (id == null && _recurringUserId == null);
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
                                  color: isSelected ? _AppColors.primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected ? _AppColors.primary : _AppColors.divider,
                                      width: isSelected ? 1.5 : 1),
                                ),
                                child: Row(children: [
                                  if (isAll)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _AppColors.primary : _AppColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _AppColors.primaryLight),
                                      ),
                                      child: Icon(Icons.group_rounded,
                                          color: isSelected ? Colors.white : _AppColors.primary, size: 20),
                                    )
                                  else if (avatarUrl != null && avatarUrl.isNotEmpty)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(avatarUrl),
                                      onBackgroundImageError: (_, __) {},
                                      backgroundColor: _AppColors.primaryLight,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected ? _AppColors.primary : _AppColors.primaryLight,
                                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isSelected ? Colors.white : _AppColors.primary)),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(isAll ? getTxt('semua_penemu') : name,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                color: isSelected ? _AppColors.primary : _AppColors.textPrimary)),
                                        if (!isAll) ...[
                                          const SizedBox(height: 4),
                                          _buildJabatanBadge(
                                              idJabatan: idJabatan,
                                              jabatanNama: jabatanNama,
                                              isVerificator: isVerificator),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: _AppColors.primary, size: 18),
                                ]),
                              ),
                            );
                          },
                        ),
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

  // ─── EMPTY STATE (ilustrasi + teks sesuai bahasa) ─────────────────────────
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
            Image.asset(
              'assets/images/team_illustration.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    color: _AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(Icons.search_off_rounded,
                    size: 44, color: _AppColors.primary.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: _AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CARD TOPIK (gaya sama seperti 5R: strip keseringan + total besar) ────
  Widget _buildTopicCard(KTSRecurringTopic topic) {
    final Color severityColor = topic.total >= 6
        ? const Color(0xFFEF4444)
        : topic.total >= 3
            ? _AppColors.primary
            : const Color(0xFF10B981);
    final String severityLabel = topic.total >= 6
        ? (widget.lang == 'ID' ? 'Sering Terjadi' : widget.lang == 'ZH' ? '频繁发生' : 'Frequent')
        : topic.total >= 3
            ? (widget.lang == 'ID' ? 'Cukup Sering' : widget.lang == 'ZH' ? '较常见' : 'Recurring')
            : (widget.lang == 'ID' ? 'Jarang' : widget.lang == 'ZH' ? '较少' : 'Occasional');
    final String occurrenceLabel = widget.lang == 'ID'
        ? '${topic.total} kejadian'
        : widget.lang == 'ZH'
            ? '${topic.total} 次'
            : '${topic.total} occurrences';

    return GestureDetector(
      onTap: () => _showDetail(topic),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: severityColor.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: severityColor.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // STRIP TINGKAT KESERINGAN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
            ),
            child: Row(children: [
              Icon(Icons.autorenew_rounded, size: 13, color: severityColor),
              const SizedBox(width: 4),
              Text(severityLabel,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: severityColor)),
              const Spacer(),
              Text(occurrenceLabel,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: severityColor)),
            ]),
          ),
          // KONTEN (KHUSUS KTS: menampilkan No. Order)
          Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15)),
              child: Container(
                width: 78,
                height: 78,
                color: _AppColors.primaryLight,
                child: topic.imageUrl != null && topic.imageUrl!.isNotEmpty
                    ? Image.network(topic.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported, color: _AppColors.textMuted))
                    : const Icon(Icons.image_outlined, color: _AppColors.textMuted, size: 30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.topic,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.tag_rounded, size: 13, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${topic.total}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: severityColor)),
                Icon(Icons.chevron_right_rounded, color: _AppColors.textMuted, size: 18),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showDetail(KTSRecurringTopic topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic.topic,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.tag_rounded,
                            size: 13, color: Color(0xFFD97706)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD97706)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${getTxt('total')}: ${topic.total}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _AppColors.primary)),
                ),
              ]),
            ),
            const Divider(height: 1, color: _AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    '${getTxt('daftar_temuan')} (${topic.total})',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _AppColors.textPrimary)),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                itemCount: topic.findings.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _buildFindingCard(topic.findings[i]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFindingCard(Map<String, dynamic> data) {
    return KtsFindingCard(
      data: data,
      lang: widget.lang,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FindingDetailScreen(
            initialData: data,
            lang: widget.lang,
          ),
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
          Expanded(
            child: _buildFilterButton(
              label: periodLabel,
              onTap: _showPeriodPicker,
              icon: Icons.calendar_month_rounded,
              isActive: !_isPeriodDefault,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildFilterButton(
              label: _recurringUserName.isEmpty
                  ? getTxt('semua_penemu')
                  : _recurringUserName,
              onTap: _showUserPicker,
              isActive: _recurringUserId != null,
            ),
          ),
        ]),
      ),

      // SECTION LABEL (gaya sama seperti 5R)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _AppColors.primaryLight),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: _AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.autorenew_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(getTxt('topik'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    widget.lang == 'ID'
                        ? 'Temuan KTS Production dengan pola atau order serupa dikelompokkan otomatis'
                        : widget.lang == 'ZH'
                            ? '相似模式或订单的KTS生产发现会自动分组'
                            : 'KTS Production findings with similar patterns or orders are grouped automatically',
                    style: const TextStyle(
                        fontSize: 11,
                        color: _AppColors.textSecondary,
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
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildTopicCard(topics[i]),
            );
          },
        ),
      ),
    ]);
  }
}