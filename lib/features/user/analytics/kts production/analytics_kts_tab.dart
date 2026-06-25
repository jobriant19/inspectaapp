import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/gemini_recurring_service.dart';
import '../../finding/finding_detail_screen.dart';
import '../../home/kts_finding_card.dart';
import 'kts_cause_tab.dart';
import 'kts_members_tab.dart';

// ─── Warna & Tema ──────────────────────────────────────────────────────────
class _KTSAppColors {
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

// ─── Main Widget ──────────────────────────────────────────────────────────────
class KTSAnalyticsTab extends StatefulWidget {
  final String lang;
  final String userId;
  final VoidCallback? onTabChanged; // Tambahkan callback
  
  const KTSAnalyticsTab({
    super.key,
    required this.lang,
    required this.userId,
    this.onTabChanged,
  });

  @override
  State<KTSAnalyticsTab> createState() => _KTSAnalyticsTabState();
}

class _KTSAnalyticsTabState extends State<KTSAnalyticsTab>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'anggota': 'Anggota', 'temuan_berulang': 'Temuan Berulang',
      'memuat_data': 'Memuat data...', 'diperbarui_pada': 'Terakhir diperbarui pada',
      'semua_grup_anggota': 'Semua Grup', 'gagal_muat_anggota': 'Gagal memuat data Anggota',
      'tidak_ada_data_anggota': 'Tidak ada data anggota.',
      'tidak_ada_data_level': 'Tidak ada data untuk level',
      'nama': 'Nama', 'temuan': 'Temuan', 'selesai': 'Selesai',
      'target_bulanan': 'Target Bulanan', 'saya': 'Saya', 'rank': 'Rank',
      'topik': 'Topik', 'belum_memiliki_temuan': 'belum\nmemiliki temuan berulang',
      'pilih_bulan': 'Pilih Bulan', 'pilih_grup': 'Pilih Grup',
      'pilih_periode': 'Pilih Periode', 'pilih_penemu': 'Pilih Penemu',
      'cari': 'Cari...', 'dari': 'Dari', 'sampai': 'Sampai',
      'terapkan': 'Terapkan', 'total': 'Total',
      'penemu': 'Penemu', 'periode': 'Periode',
      'daftar_temuan': 'Daftar Temuan', 'di_sekitar': 'Di sekitar',
      'semua_grup': 'Semua Penemu', 'hari_terlewat': 'hari terlewat',
      'jam_terlewat': 'jam terlewat', 'menit_terlewat': 'menit terlewat',
      'deadline_hari_ini': 'Deadline hari ini', 'hari_tersisa': 'hari tersisa',
    },
    'EN': {
      'anggota': 'Members', 'temuan_berulang': 'Recurring Findings',
      'memuat_data': 'Loading data...', 'diperbarui_pada': 'Last updated at',
      'semua_grup_anggota': 'All Groups', 'gagal_muat_anggota': 'Failed to load Member data',
      'tidak_ada_data_anggota': 'No member data available.',
      'tidak_ada_data_level': 'No data for level',
      'nama': 'Name', 'temuan': 'Findings', 'selesai': 'Completed',
      'target_bulanan': 'Monthly Target', 'saya': 'Me', 'rank': 'Rank',
      'topik': 'Topic', 'belum_memiliki_temuan': 'does not have\nrecurring findings yet',
      'pilih_bulan': 'Select Month', 'pilih_grup': 'Select Group',
      'pilih_periode': 'Select Period', 'pilih_penemu': 'Select Finder',
      'cari': 'Search...', 'dari': 'From', 'sampai': 'To',
      'terapkan': 'Apply', 'total': 'Total',
      'penemu': 'Finder', 'periode': 'Period',
      'daftar_temuan': 'Finding List', 'di_sekitar': 'Around',
      'semua_grup': 'All Finders', 'hari_terlewat': 'days overdue',
      'jam_terlewat': 'hours overdue', 'menit_terlewat': 'minutes overdue',
      'deadline_hari_ini': 'Deadline today', 'hari_tersisa': 'days remaining',
    },
    'ZH': {
      'anggota': '成员', 'temuan_berulang': '重复发现',
      'memuat_data': '加载数据...', 'diperbarui_pada': '最后更新于',
      'semua_grup_anggota': '所有组', 'gagal_muat_anggota': '加载成员数据失败',
      'tidak_ada_data_anggota': '没有成员数据。',
      'tidak_ada_data_level': '没有级别的数据',
      'nama': '名称', 'temuan': '发现', 'selesai': '已完成',
      'target_bulanan': '每月目标', 'saya': '我', 'rank': '排名',
      'topik': '话题', 'belum_memiliki_temuan': '还没有\n重复的发现',
      'pilih_bulan': '选择月份', 'pilih_grup': '选择组',
      'pilih_periode': '选择期间', 'pilih_penemu': '选择发现者',
      'cari': '搜索...', 'dari': '从', 'sampai': '到',
      'terapkan': '应用', 'total': '总计',
      'penemu': '发现者', 'periode': '期间',
      'daftar_temuan': '发现列表', 'di_sekitar': '周围',
      'semua_grup': '所有发现者', 'hari_terlewat': '天逾期',
      'jam_terlewat': '小时逾期', 'menit_terlewat': '分钟逾期',
      'deadline_hari_ini': '今天截止', 'hari_tersisa': '天剩余',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  // Recurring findings filter
  DateTime _recurringFrom = DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo = DateTime.now();
  String? _recurringUserId;
  String _recurringUserName = '';

  // ─── State untuk Data ────────────────────────────────────────────────────
  Future<List<KTSRecurringTopic>>? _recurringFuture;

  // ignore: unused_field
  late List<String> _translatedMonths;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initLocaleDependentLists();
    _fetchAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initLocaleDependentLists();
  }

  void _initLocaleDependentLists() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    _translatedMonths = List.generate(12, (i) =>
        DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
  }

  void _fetchAllData() {
    setState(() {
      _recurringFuture = _fetchRecurringData();
    });
  }

  void _fetchRecurring() {
    setState(() {
      _recurringFuture = _fetchRecurringData();
    });
  }

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
          .lte('created_at', DateTime(
              _recurringTo.year, _recurringTo.month + 1, 0, 23, 59, 59)
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

      return groups.map((g) => KTSRecurringTopic(
        topic: g.topic,
        locationArea: g.locationArea,
        total: g.total,
        imageUrl: g.imageUrl,
        findings: g.findings,
      )).toList();
    } catch (e) {
      debugPrint('Error fetching KTS Recurring: $e');
      return [];
    }
  }

  Widget _buildRecurringShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShimmerBox(height: 14, width: double.infinity),
                const SizedBox(height: 6),
                _buildShimmerBox(height: 12, width: 120),
              ],
            )),
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 48, height: 48,
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

  // ─── Shimmer Helpers ──────────────────────────────────────────────────────
  Widget _buildShimmerBox({double? width, required double height, bool isCircle = false, double borderRadius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCircle ? height / 2 : borderRadius),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPeriodPicker() async {
    DateTime tempFrom = _recurringFrom;
    DateTime tempTo = _recurringTo;
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _KTSAppColors.primaryLight, width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.date_range_rounded, color: _KTSAppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(getTxt('pilih_periode'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _KTSAppColors.textPrimary))),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
            ]),
            const SizedBox(height: 16),
            Text(getTxt('dari'), style: const TextStyle(fontSize: 12, color: _KTSAppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempFrom, locale, (d) => setSt(() => tempFrom = d)),
            const SizedBox(height: 14),
            Text(getTxt('sampai'), style: const TextStyle(fontSize: 12, color: _KTSAppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildYearMonthPicker(tempTo, locale, (d) => setSt(() => tempTo = d)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() { _recurringFrom = tempFrom; _recurringTo = tempTo; });
                  Navigator.pop(ctx);
                  _fetchRecurring();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _KTSAppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(getTxt('terapkan')),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  Widget _buildYearMonthPicker(DateTime current, String locale, ValueChanged<DateTime> onChange) {
    final months = List.generate(12, (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);
    return Row(children: [
      Expanded(
        flex: 3,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _KTSAppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _KTSAppColors.primaryLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.month - 1,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _KTSAppColors.primary),
              style: const TextStyle(fontSize: 13, color: _KTSAppColors.textPrimary, fontWeight: FontWeight.w600),
              dropdownColor: Colors.white,
              items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(months[i]))),
              onChanged: (v) { if (v != null) onChange(DateTime(current.year, v + 1)); },
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
            color: _KTSAppColors.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _KTSAppColors.primaryLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.year,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _KTSAppColors.primary),
              style: const TextStyle(fontSize: 13, color: _KTSAppColors.textPrimary, fontWeight: FontWeight.w600),
              dropdownColor: Colors.white,
              items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) { if (v != null) onChange(DateTime(v, current.month)); },
            ),
          ),
        ),
      ),
    ]);
  }

  void _showUserPicker() async {
    try {
      final response = await _supabase
          .from('User')
          .select('id_user, nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .order('nama');
      final users = List<Map<String, dynamic>>.from(response);
      final allItem = {'id_user': null, 'nama': getTxt('pilih_penemu'), 'gambar_user': null, 'jabatan': null};
      final items = [allItem, ...users];
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) {
            final ctrl = TextEditingController();
            List<Map<String, dynamic>> filtered = List.from(items);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _KTSAppColors.primaryLight, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                      decoration: BoxDecoration(
                        color: _KTSAppColors.primaryLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.person_search_rounded, color: _KTSAppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(getTxt('pilih_penemu'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _KTSAppColors.textPrimary))),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: _KTSAppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: StatefulBuilder(
                        builder: (_, setInner) => TextField(
                          controller: ctrl,
                          onChanged: (q) {
                            setInner(() {
                              filtered = items.where((e) =>
                                (e['nama'] as String).toLowerCase().contains(q.toLowerCase())
                              ).toList();
                            });
                            setSt(() {});
                          },
                          decoration: InputDecoration(
                            hintText: getTxt('cari'),
                            hintStyle: const TextStyle(fontSize: 13, color: _KTSAppColors.textMuted),
                            prefixIcon: const Icon(Icons.search, color: _KTSAppColors.primary, size: 18),
                            filled: true, fillColor: _KTSAppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _KTSAppColors.divider)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _KTSAppColors.divider)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _KTSAppColors.primary, width: 1.5)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${filtered.length} ${widget.lang == 'ID' ? 'penemu' : widget.lang == 'ZH' ? '发现者' : 'finders'}',
                          style: const TextStyle(fontSize: 11, color: _KTSAppColors.textSecondary)),
                      ),
                    ),
                    Flexible(
                      child: StatefulBuilder(
                        builder: (_, __) => ListView.builder(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final name = item['nama'] as String;
                            final id = item['id_user']?.toString();
                            final avatarUrl = item['gambar_user'] as String?;
                            final role = (item['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
                            final isSelected = id == _recurringUserId ||
                              (id == null && _recurringUserId == null);
                            final isAll = id == null;

                            return InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _recurringUserId = id;
                                  _recurringUserName = isAll
                                      ? (widget.lang == 'ID' ? 'Semua Penemu' : widget.lang == 'ZH' ? '所有发现者' : 'All Finders')
                                      : name;
                                });
                                _fetchRecurring();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? _KTSAppColors.primaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? _KTSAppColors.primary : _KTSAppColors.divider,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  if (isAll)
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _KTSAppColors.primary : _KTSAppColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _KTSAppColors.primaryLight)),
                                      child: Icon(Icons.group_rounded,
                                        color: isSelected ? Colors.white : _KTSAppColors.primary, size: 20),
                                    )
                                  else if (avatarUrl != null && avatarUrl.isNotEmpty)
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: NetworkImage(avatarUrl),
                                      onBackgroundImageError: (_, __) {},
                                      backgroundColor: _KTSAppColors.primaryLight,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected ? _KTSAppColors.primary : _KTSAppColors.primaryLight,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15,
                                          color: isSelected ? Colors.white : _KTSAppColors.primary,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(isAll
                                          ? (widget.lang == 'ID' ? 'Semua Penemu' : widget.lang == 'ZH' ? '所有发现者' : 'All Finders')
                                          : name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? _KTSAppColors.primary : _KTSAppColors.textPrimary,
                                        )),
                                      if (role != null && role.isNotEmpty)
                                        Text(role, style: const TextStyle(
                                          fontSize: 11, color: _KTSAppColors.textSecondary)),
                                    ],
                                  )),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                      color: _KTSAppColors.primary, size: 18),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }

  // ─── Filter Button Widget ─────────────────────────────────────────────────
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
          color: isActive ? _KTSAppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _KTSAppColors.primary : _KTSAppColors.primaryLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _KTSAppColors.primary.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _KTSAppColors.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, color: isActive ? Colors.white : _KTSAppColors.primary, size: 18),
        ]),
      ),
    );
  }

  // ─── 3 Tab untuk KTS: Members, Cause, dan Recurring Findings ──────────────────────
  Widget _buildKTSTabBar() {
    final tabLabels = [
      getTxt('anggota'),
      widget.lang == 'ID' ? 'Penyebab' : widget.lang == 'ZH' ? '原因' : 'Cause',
      getTxt('temuan_berulang'),
    ];
    final activeColor = _KTSAppColors.primary;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          indicator: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: activeColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: tabLabels.map((t) => Tab(child: Text(t))).toList(),
        ),
      ),
    );
  }

  Widget _buildRecurringTopicCard(KTSRecurringTopic topic) {
    return GestureDetector(
      onTap: () => _showRecurringDetail(topic),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _KTSAppColors.primaryLight, width: 1.5),
          boxShadow: [BoxShadow(color: _KTSAppColors.primary.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80, height: 80,
              color: _KTSAppColors.primaryLight,
              child: topic.imageUrl != null && topic.imageUrl!.isNotEmpty
                  ? Image.network(topic.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: _KTSAppColors.textMuted))
                  : const Icon(Icons.image_outlined, color: _KTSAppColors.textMuted, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(topic.topic,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _KTSAppColors.textPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.tag_rounded, size: 13, color: const Color(0xFFD97706)),
                const SizedBox(width: 3),
                Expanded(child: Text(
                  '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD97706),
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ]),
          )),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _KTSAppColors.primaryLight, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _KTSAppColors.primary.withOpacity(0.3)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(getTxt('total'), style: const TextStyle(fontSize: 9, color: _KTSAppColors.textSecondary)),
              Text('${topic.total}', style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: _KTSAppColors.primary)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showRecurringDetail(KTSRecurringTopic topic) {
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(topic.topic, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _KTSAppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.tag_rounded, size: 13, color: const Color(0xFFD97706)),
                    const SizedBox(width: 3),
                    Flexible(child: Text(
                      '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD97706),
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _KTSAppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('${getTxt('total')}: ${topic.total}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _KTSAppColors.primary)),
                ),
              ]),
            ),
            const Divider(height: 1, color: _KTSAppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('${getTxt('daftar_temuan')} (${topic.total})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _KTSAppColors.textPrimary))),
            ),
            Expanded(child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: topic.findings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final data = topic.findings[i];
                return _buildRecurringFindingCard(data);
              },
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecurringFindingCard(Map<String, dynamic> data) {
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

  // ─── Recurring Tab - TANPA chart ──────────────────────────────────────────
  Widget _buildRecurringTab() {
    final locale = widget.lang == 'ID' ? 'id_ID' : (widget.lang == 'EN' ? 'en_US' : 'zh_CN');
    final fromLabel = DateFormat('MMM yyyy', locale).format(_recurringFrom);
    final toLabel = DateFormat('MMM yyyy', locale).format(_recurringTo);
    final periodLabel = '$fromLabel - $toLabel';

    return Column(children: [
      // Filter row (tanpa chart)
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: _buildFilterButton(
            label: periodLabel,
            onTap: _showPeriodPicker,
            icon: Icons.calendar_month_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton(
            label: _recurringUserName.isEmpty ? getTxt('semua_grup') : _recurringUserName,
            onTap: _showUserPicker,
          )),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Align(alignment: Alignment.centerLeft,
          child: Text(getTxt('topik'), style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: _KTSAppColors.textPrimary))),
      ),
      const Divider(height: 1, color: _KTSAppColors.divider),
      Expanded(child: FutureBuilder<List<KTSRecurringTopic>>(
        future: _recurringFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildRecurringShimmer();
          }
          final topics = snapshot.data ?? [];
          if (topics.isEmpty) {
            final name = _recurringUserName.isEmpty ? '' : _recurringUserName;
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 72, height: 72,
                  decoration: BoxDecoration(color: _KTSAppColors.primaryLight, shape: BoxShape.circle),
                  child: Icon(Icons.search_off_rounded, size: 36, color: _KTSAppColors.primary.withOpacity(0.5))),
                const SizedBox(height: 16),
                Text(
                  name.isEmpty ? getTxt('tidak_ada_data_anggota')
                      : '$name ${getTxt('belum_memiliki_temuan')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _KTSAppColors.textSecondary, height: 1.5)),
              ],
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _buildRecurringTopicCard(topics[i]),
          );
        },
      )),
    ]);
  }

  // ─── build() method ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildKTSTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              KtsMembersTab(lang: widget.lang, userId: widget.userId),
              KtsPenyebabTab(lang: widget.lang),
              _buildRecurringTab(),
            ],
          ),
        ),
      ],
    );
  }
}