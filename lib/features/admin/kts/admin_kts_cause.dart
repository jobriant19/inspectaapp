import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class _C {
  static const primary      = Color(0xFFF59E0B);
  static const primaryDark  = Color(0xFFD97706);
  static const primaryLight = Color(0xFFFEF3C7);
  static const surface      = Color(0xFFFFFBEB);
  static const textPrimary  = Color(0xFF78350F);
  static const textSec      = Color(0xFF92400E);
  static const textMuted    = Color(0xFFD97706);
  static const divider      = Color(0xFFFDE68A);
  static const blue         = Color(0xFF1D4ED8);
  static const blueLight    = Color(0xFFEFF6FF);
  static const orange       = Color(0xFFF59E0B);
  static const green        = Color(0xFF059669);
  static const greenLight   = Color(0xFFD1FAE5);
}

const List<String> kKtsBagianList = [
  'Laser', 'Mesin', 'Spot', 'Las', 'Ftw', 'Cat',
  'Assy', 'Ekspedisi & Packing', 'Purchasing', 'Engineering', 'PPIC',
];

enum _FilterType { bagian, faktor, biaya }

class _BagianStat {
  final String bagian;
  final int jumlah;
  final double totalBiaya;
  const _BagianStat({
    required this.bagian,
    required this.jumlah,
    required this.totalBiaya,
  });
}

class _FaktorStat {
  final String id;
  final String namaFaktor;
  final int jumlah;
  final double totalBiaya;
  const _FaktorStat({
    required this.id,
    required this.namaFaktor,
    required this.jumlah,
    required this.totalBiaya,
  });
}

class _ChartRow {
  final String label;
  final double value;
  const _ChartRow({required this.label, required this.value});
}

class AdminKtsCauseTab extends StatefulWidget {
  final String lang;

  const AdminKtsCauseTab({super.key, required this.lang});

  @override
  State<AdminKtsCauseTab> createState() => _AdminKtsCauseTabState();
}

class _AdminKtsCauseTabState extends State<AdminKtsCauseTab> {
  final _db = Supabase.instance.client;

  String _t(String k) => _i18n[widget.lang]?[k] ?? _i18n['ID']![k] ?? k;

  static const _i18n = {
    'ID': {
      'bagian_penyebab': 'Bagian Penyebab',
      'faktor_penyebab': 'Faktor Penyebab',
      'biaya_kts'      : 'Biaya KTS',
      'pilih_filter'   : 'Pilih Tampilan',
      'pilih_bagian'   : 'Pilih Bagian',
      'pilih_faktor'   : 'Pilih Faktor',
      'semua_bagian'   : 'Semua Bagian',
      'semua_faktor'   : 'Semua Faktor',
      'pilih_bulan'    : 'Pilih Bulan',
      'terapkan'       : 'Terapkan',
      'bulanan'        : 'Bulanan',
      'harian'         : 'Harian',
      'jumlah_kts'     : 'Jumlah KTS',
      'total_biaya'    : 'Total Biaya (Rp)',
      'persen'         : '%',
      'jumlah'         : 'Jumlah',
      'tidak_ada'      : 'Tidak ada data untuk periode ini',
      'grafik'         : 'Grafik',
      'rekap'          : 'Rekap',
      'total'          : 'Total',
      'total_nominal'  : 'Total Nominal KTS',
      'juta_rp'        : 'Juta Rupiah',
      'bagian_label'   : 'Bagian',
      'faktor_label'   : 'Penyebab',
    },
    'EN': {
      'bagian_penyebab': 'Cause Section',
      'faktor_penyebab': 'Cause Factor',
      'biaya_kts'      : 'KTS Cost',
      'pilih_filter'   : 'Select View',
      'pilih_bagian'   : 'Select Section',
      'pilih_faktor'   : 'Select Factor',
      'semua_bagian'   : 'All Sections',
      'semua_faktor'   : 'All Factors',
      'pilih_bulan'    : 'Select Month',
      'terapkan'       : 'Apply',
      'bulanan'        : 'Monthly',
      'harian'         : 'Daily',
      'jumlah_kts'     : 'KTS Count',
      'total_biaya'    : 'Total Cost (Rp)',
      'persen'         : '%',
      'jumlah'         : 'Count',
      'tidak_ada'      : 'No data for this period',
      'grafik'         : 'Chart',
      'rekap'          : 'Summary',
      'total'          : 'Total',
      'total_nominal'  : 'Total KTS Nominal',
      'juta_rp'        : 'Million IDR',
      'bagian_label'   : 'Section',
      'faktor_label'   : 'Cause',
    },
    'ZH': {
      'bagian_penyebab': '原因部门',
      'faktor_penyebab': '原因因素',
      'biaya_kts'      : 'KTS费用',
      'pilih_filter'   : '选择视图',
      'pilih_bagian'   : '选择部门',
      'pilih_faktor'   : '选择因素',
      'semua_bagian'   : '所有部门',
      'semua_faktor'   : '所有因素',
      'pilih_bulan'    : '选择月份',
      'terapkan'       : '应用',
      'bulanan'        : '按月',
      'harian'         : '按日',
      'jumlah_kts'     : 'KTS数量',
      'total_biaya'    : '总费用 (Rp)',
      'persen'         : '%',
      'jumlah'         : '数量',
      'tidak_ada'      : '此期间无数据',
      'grafik'         : '图表',
      'rekap'          : '汇总',
      'total'          : '总计',
      'total_nominal'  : 'KTS总金额',
      'juta_rp'        : '百万卢比',
      'bagian_label'   : '部门',
      'faktor_label'   : '原因',
    },
  };

  // TIME FILTER STATE
  int _monthIdx = DateTime.now().month - 1;
  String _mode  = 'monthly';
  DateTime? _selDate;
  late List<String> _months;

  // TYPE FILTER STATE
  _FilterType? _activeFilter = _FilterType.bagian;
  String? _subBagian;
  String? _subFaktorId;

  // CHART STATE
  bool _chartExpanded = false;

  // COST SUBFILTER
  String _biayaSubFilter = 'faktor';

  // DATA
  bool _loading = false;
  List<_BagianStat> _bagianStats = [];
  List<_FaktorStat> _faktorStats = [];
  // ignore: unused_field
  double _totalBiaya = 0;
  // ignore: unused_field
  int _totalKts = 0;
  List<Map<String, dynamic>> _faktorMaster = [];

  @override
  void initState() {
    super.initState();
    _initMonths();
    _loadFaktorMaster().then((_) => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initMonths();
  }

  void _initMonths() {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN'
            ? 'en_US'
            : 'zh_CN';
    _months = List.generate(
      12,
      (i) => DateFormat.MMM(locale).format(DateTime(2000, i + 1)),
    );
  }

  Future<void> _loadFaktorMaster() async {
    try {
      final katRes = await _db
          .from('kategoritemuan')
          .select('id_kategoritemuan')
          .eq('nama_kategoritemuan', 'KTS Produksi')
          .maybeSingle();
      if (katRes == null) return;
      final katId = katRes['id_kategoritemuan'].toString();

      final res = await _db
          .from('subkategoritemuan')
          .select('id_subkategoritemuan, nama_subkategoritemuan')
          .eq('id_kategoritemuan', katId)
          .order('nama_subkategoritemuan');

      if (mounted) {
        setState(() => _faktorMaster = List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      debugPrint('loadFaktorMaster error: $e');
    }
  }

  (DateTime, DateTime) _dateRange() {
    if (_mode == 'daily' && _selDate != null) {
      final d = _selDate!;
      return (
        DateTime(d.year, d.month, d.day),
        DateTime(d.year, d.month, d.day, 23, 59, 59),
      );
    }
    final y = DateTime.now().year;
    final m = _monthIdx + 1;
    return (DateTime(y, m, 1), DateTime(y, m + 1, 0, 23, 59, 59));
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final (start, end) = _dateRange();
      final res = await _db.from('temuan').select('''
            id_temuan,
            penyelesaian!temuan_id_penyelesaian_fkey(
              id_penyelesaian,
              bagian,
              id_subkategoritemuan_penyebab,
              additional_cost,
              subkategori_penyebab:id_subkategoritemuan_penyebab(
                id_subkategoritemuan,
                nama_subkategoritemuan
              )
            )
          ''')
          .eq('jenis_temuan', 'KTS Production')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .not('id_penyelesaian', 'is', null);

      final rows = List<Map<String, dynamic>>.from(res);
      final filtered = rows.where((r) {
        final p = r['penyelesaian'] as Map<String, dynamic>?;
        if (p == null) return false;
        if (_subBagian != null && p['bagian'] != _subBagian) return false;
        if (_subFaktorId != null &&
            p['id_subkategoritemuan_penyebab']?.toString() != _subFaktorId) {
          return false;
        }
        return true;
      }).toList();

      final Map<String, ({int n, double biaya})> bagMap = {
        for (final b in kKtsBagianList) b: (n: 0, biaya: 0.0),
      };

      final Map<String, ({String nama, int n, double biaya})> faktMap = {
        for (final f in _faktorMaster)
          f['id_subkategoritemuan'].toString(): (
            nama: f['nama_subkategoritemuan'] as String,
            n: 0,
            biaya: 0.0,
          ),
      };

      for (final row in filtered) {
        final p      = row['penyelesaian'] as Map<String, dynamic>;
        final bagian = (p['bagian'] as String?)?.trim() ?? '';
        final biaya  = (p['additional_cost'] as num?)?.toDouble() ?? 0.0;
        final subkat = p['subkategori_penyebab'] as Map<String, dynamic>?;
        final faktorNama = subkat?['nama_subkategoritemuan'] as String? ?? '';
        final faktorId   = p['id_subkategoritemuan_penyebab']?.toString() ?? '';

        if (bagian.isNotEmpty && kKtsBagianList.contains(bagian)) {
          final cur = bagMap[bagian]!;
          bagMap[bagian] = (n: cur.n + 1, biaya: cur.biaya + biaya);
        }

        if (faktorId.isNotEmpty) {
          final cur = faktMap[faktorId];
          if (cur != null) {
            faktMap[faktorId] =
                (nama: cur.nama, n: cur.n + 1, biaya: cur.biaya + biaya);
          } else if (faktorNama.isNotEmpty) {
            faktMap[faktorId] = (nama: faktorNama, n: 1, biaya: biaya);
          }
        }
      }

      final bagianStats = bagMap.entries
          .map((e) => _BagianStat(
                bagian: e.key,
                jumlah: e.value.n,
                totalBiaya: e.value.biaya,
              ))
          .toList()
        ..sort((a, b) => b.jumlah.compareTo(a.jumlah));

      final faktorStats = faktMap.entries
          .map((e) => _FaktorStat(
                id: e.key,
                namaFaktor: e.value.nama,
                jumlah: e.value.n,
                totalBiaya: e.value.biaya,
              ))
          .toList()
        ..sort((a, b) => b.jumlah.compareTo(a.jumlah));

      final totalBiaya = filtered.fold(0.0, (s, r) {
        final p = r['penyelesaian'] as Map<String, dynamic>;
        return s + ((p['additional_cost'] as num?)?.toDouble() ?? 0.0);
      });

      if (mounted) {
        setState(() {
          _bagianStats = bagianStats;
          _faktorStats = faktorStats;
          _totalBiaya  = totalBiaya;
          _totalKts    = filtered.length;
          _loading     = false;
        });
      }
    } catch (e) {
      debugPrint('loadData penyebab error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMonthPicker() async {
    String tmpMode   = _mode;
    int tmpMonthIdx  = _monthIdx;
    DateTime tmpDate = _selDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
              maxWidth: 340,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.primaryLight, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_month_rounded,
                        color: _C.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _t('pilih_bulan'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _C.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: _C.textSec),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                ),

                // TOGGLE BULANAN / HARIAN
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.primaryLight),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: ['monthly', 'daily'].map((m) {
                        final sel = tmpMode == m;
                        final lbl = m == 'monthly'
                            ? _t('bulanan')
                            : _t('harian');
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => ss(() => tmpMode = m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 36,
                              decoration: BoxDecoration(
                                color: sel
                                    ? _C.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  lbl,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white
                                        : _C.textSec,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // PILIH BULAN / PILIH TANGGAL
                if (tmpMode == 'monthly')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: 12,
                      itemBuilder: (_, i) {
                        final sel = i == tmpMonthIdx;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _mode      = 'monthly';
                              _monthIdx  = i;
                              _selDate   = null;
                            });
                            _loadData();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: sel ? _C.primary : _C.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel ? _C.primary : _C.divider,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _months[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: sel
                                      ? Colors.white
                                      : _C.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _buildDailyCalendar(
                      tmpDate,
                      (d) => ss(() => tmpDate = d),
                      onConfirm: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _mode      = 'daily';
                          _selDate   = tmpDate;
                          _monthIdx  = tmpDate.month - 1;
                        });
                        _loadData();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCalendar(
    DateTime sel,
    ValueChanged<DateTime> onChange, {
    required VoidCallback onConfirm,
  }) {
    final now    = DateTime.now();
    final days   = DateUtils.getDaysInMonth(now.year, now.month);
    final first  = DateTime(now.year, now.month, 1).weekday % 7;
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN'
            ? 'en_US'
            : 'zh_CN';
    final hdr  = DateFormat('MMMM yyyy', locale)
        .format(DateTime(now.year, now.month));
    final lbls = widget.lang == 'ZH'
        ? ['日', '一', '二', '三', '四', '五', '六']
        : widget.lang == 'ID'
            ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
            : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return StatefulBuilder(
      builder: (_, si) => Column(
        children: [
          Text(
            hdr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: lbls
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _C.textSec,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: first + days,
            itemBuilder: (_, i) {
              if (i < first) return const SizedBox();
              final day      = i - first + 1;
              final date     = DateTime(now.year, now.month, day);
              final isSel    = sel.year == date.year &&
                  sel.month == date.month &&
                  sel.day == date.day;
              final isToday  = now.day == day;
              final isFuture = date.isAfter(now);
              return GestureDetector(
                onTap: isFuture ? null : () => si(() => onChange(date)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSel
                        ? _C.primary
                        : isToday
                            ? _C.primaryLight
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSel
                        ? Border.all(color: _C.primary, width: 1.2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSel
                            ? Colors.white
                            : isFuture
                                ? _C.textMuted
                                : _C.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                _t('terapkan'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterTypePicker() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.primaryLight, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: BoxDecoration(
                  color: _C.primaryLight,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Icon(Icons.filter_list_rounded,
                      color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('pilih_filter'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _C.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: _C.textSec),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              _buildTypeOption(ctx, _FilterType.bagian,
                  Icons.grid_view_rounded, _t('bagian_penyebab'), _C.blue),
              _buildTypeOption(ctx, _FilterType.faktor, Icons.tag_rounded,
                  _t('faktor_penyebab'), _C.green),
              _buildTypeOption(ctx, _FilterType.biaya,
                  Icons.monetization_on_rounded, _t('biaya_kts'), _C.orange),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(
    BuildContext ctx,
    _FilterType type,
    IconData icon,
    String label,
    Color color,
  ) {
    final isSel = _activeFilter == type;
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        setState(() {
          if (_activeFilter == type) {
            _activeFilter = null;
            _subBagian    = null;
            _subFaktorId  = null;
          } else {
            _activeFilter = type;
            _subBagian    = null;
            _subFaktorId  = null;
          }
        });
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha:0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? color : const Color(0xFFE2E8F0),
            width: isSel ? 1.8 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSel ? color : color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18, color: isSel ? Colors.white : color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSel ? color : const Color(0xFF1E293B),
              ),
            ),
          ),
          if (isSel)
            Icon(Icons.check_circle_rounded, color: color, size: 20),
        ]),
      ),
    );
  }

  void _showBagianPicker() async {
    final items = [null, ...kKtsBagianList];
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.blueLight, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: BoxDecoration(
                  color: _C.blueLight,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(children: [
                  const Icon(Icons.grid_view_rounded,
                      color: _C.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('pilih_bagian'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _C.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: _C.blue),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ),
              Flexible(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.only(bottom: 12, top: 4),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final lbl  = item ?? _t('semua_bagian');
                    final sel  = item == _subBagian;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _subBagian = item);
                        _loadData();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? _C.blueLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? _C.blue
                                : const Color(0xFFE2E8F0),
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: sel ? _C.blue : _C.blueLight,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                lbl.isNotEmpty
                                    ? lbl[0].toUpperCase()
                                    : '#',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: sel
                                      ? Colors.white
                                      : _C.blue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lbl,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: sel
                                    ? _C.blue
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (sel)
                            const Icon(Icons.check_circle_rounded,
                                color: _C.blue, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaktorPicker() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.greenLight, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                decoration: BoxDecoration(
                  color: _C.greenLight,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(children: [
                  const Icon(Icons.tag_rounded,
                      color: _C.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('pilih_faktor'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _C.green,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: _C.green),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                  ),
                ]),
              ),
              Flexible(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.only(bottom: 12, top: 4),
                  itemCount: _faktorMaster.length + 1,
                  itemBuilder: (_, i) {
                    final isAll = i == 0;
                    final id    = isAll
                        ? null
                        : _faktorMaster[i - 1]
                                ['id_subkategoritemuan']
                            ?.toString();
                    final lbl = isAll
                        ? _t('semua_faktor')
                        : (_faktorMaster[i - 1]
                                ['nama_subkategoritemuan'] as String? ??
                            '-');
                    final sel = id == _subFaktorId;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _subFaktorId = id);
                        _loadData();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              sel ? _C.greenLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? _C.green
                                : const Color(0xFFE2E8F0),
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color:
                                  sel ? _C.green : _C.greenLight,
                              borderRadius:
                                  BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Icon(Icons.tag_rounded,
                                  size: 16,
                                  color: sel
                                      ? Colors.white
                                      : _C.green),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lbl,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: sel
                                    ? _C.green
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (sel)
                            const Icon(Icons.check_circle_rounded,
                                color: _C.green, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN'
            ? 'en_US'
            : 'zh_CN';
    final periodLabel = _mode == 'daily' && _selDate != null
        ? DateFormat('d MMM yyyy', locale).format(_selDate!)
        : _months[_monthIdx];

    String filterLabel;
    Color filterColor;
    VoidCallback? subAction;

    if (_activeFilter == _FilterType.bagian) {
      filterLabel = _subBagian ?? _t('bagian_penyebab');
      filterColor = _C.blue;
      subAction   = _showBagianPicker;
    } else if (_activeFilter == _FilterType.faktor) {
      filterLabel = _subFaktorId == null
          ? _t('faktor_penyebab')
          : (_faktorMaster.firstWhere(
              (f) =>
                  f['id_subkategoritemuan']?.toString() ==
                  _subFaktorId,
              orElse: () =>
                  {'nama_subkategoritemuan': _t('faktor_penyebab')},
            )['nama_subkategoritemuan'] as String);
      filterColor = _C.green;
      subAction   = _showFaktorPicker;
    } else if (_activeFilter == _FilterType.biaya) {
      filterLabel = _t('biaya_kts');
      filterColor = _C.orange;
      subAction   = null;
    } else {
      filterLabel = _t('pilih_filter');
      filterColor = _C.primary;
      subAction   = null;
    }

    final bool showBiayaSub = _activeFilter == _FilterType.biaya;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
        // TOMBOL PERIODE
        _filterBtn(
          label: periodLabel,
          active: true,
          color: _C.primary,
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: _showMonthPicker,
        ),
        const SizedBox(width: 6),

        // TOMBOL PILIH TAMPILAN
        Expanded(
          flex: showBiayaSub ? 2 : 3,
          child: GestureDetector(
            onTap: _showFilterTypePicker,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _activeFilter != null
                    ? filterColor.withValues(alpha:0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _activeFilter != null
                      ? filterColor
                      : _C.primaryLight,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withValues(alpha:0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(children: [
                if (_activeFilter != null) ...[
                  Icon(
                    _activeFilter == _FilterType.bagian
                        ? Icons.grid_view_rounded
                        : _activeFilter == _FilterType.faktor
                            ? Icons.tag_rounded
                            : Icons.monetization_on_rounded,
                    size: 13,
                    color: filterColor,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    filterLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _activeFilter != null
                          ? filterColor
                          : _C.primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: _activeFilter != null
                      ? filterColor
                      : _C.primary,
                ),
              ]),
            ),
          ),
        ),

        // SUB FILTER BAGIAN / FAKTOR
        if (subAction != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: subAction,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: (_activeFilter == _FilterType.bagian
                        ? _subBagian != null
                        : _subFaktorId != null)
                    ? filterColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: filterColor, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 13,
                    color: (_activeFilter == _FilterType.bagian
                            ? _subBagian != null
                            : _subFaktorId != null)
                        ? Colors.white
                        : filterColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _activeFilter == _FilterType.bagian
                        ? (_subBagian ?? _t('semua_bagian'))
                        : (_subFaktorId == null
                            ? _t('semua_faktor')
                            : (_faktorMaster.firstWhere(
                                (f) =>
                                    f['id_subkategoritemuan']
                                        ?.toString() ==
                                    _subFaktorId,
                                orElse: () =>
                                    {'nama_subkategoritemuan': '?'},
                              )['nama_subkategoritemuan'] as String)),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: (_activeFilter == _FilterType.bagian
                              ? _subBagian != null
                              : _subFaktorId != null)
                          ? Colors.white
                          : filterColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // SUB FILTER BIAYA
        if (showBiayaSub) ...[
          const SizedBox(width: 6),
          Expanded(flex: 2, child: _buildBiayaSubFilter()),
        ],
      ]),
    );
  }

  Widget _buildBiayaSubFilter() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.orange, width: 1.5),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_biayaSubFilter != 'faktor') {
                setState(() => _biayaSubFilter = 'faktor');
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _biayaSubFilter == 'faktor'
                    ? _C.orange
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  widget.lang == 'ZH'
                      ? '因素'
                      : widget.lang == 'EN'
                          ? 'Factor'
                          : 'Faktor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _biayaSubFilter == 'faktor'
                        ? Colors.white
                        : _C.orange,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_biayaSubFilter != 'bagian') {
                setState(() => _biayaSubFilter = 'bagian');
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _biayaSubFilter == 'bagian'
                    ? _C.orange
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  widget.lang == 'ZH'
                      ? '部门'
                      : widget.lang == 'EN'
                          ? 'Section'
                          : 'Bagian',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _biayaSubFilter == 'bagian'
                        ? Colors.white
                        : _C.orange,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _filterBtn({
    required String label,
    required VoidCallback onTap,
    bool active = false,
    required Color color,
    IconData icon = Icons.keyboard_arrow_down_rounded,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : _C.primaryLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha:0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon,
                color: active ? Colors.white : color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildChartToggle() {
    final locale = widget.lang == 'ID'
        ? 'id_ID'
        : widget.lang == 'EN'
            ? 'en_US'
            : 'zh_CN';
    final lbl = _mode == 'daily' && _selDate != null
        ? DateFormat('d MMM yyyy', locale).format(_selDate!)
        : DateFormat('MMMM yyyy', locale)
            .format(DateTime(DateTime.now().year, _monthIdx + 1));

    return GestureDetector(
      onTap: () =>
          setState(() => _chartExpanded = !_chartExpanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _C.primary.withValues(alpha:0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha:0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Icon(Icons.bar_chart_rounded, size: 16, color: _C.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_t('grafik')} $lbl',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.primaryDark,
              ),
            ),
          ),
          AnimatedRotation(
            turns: _chartExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: _C.primary,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildChart() {
    if (_loading) return _shimmerBox(180);

    if (_activeFilter == _FilterType.biaya) {
      final sourceStats =
          _biayaSubFilter == 'faktor' ? _faktorStats : _bagianStats;
      final rows = sourceStats.map((s) {
        final biayaJuta = s is _FaktorStat
            ? s.totalBiaya / 1e6
            : (s as _BagianStat).totalBiaya / 1e6;
        final label = s is _FaktorStat
            ? s.namaFaktor
            : (s as _BagianStat).bagian;
        return _ChartRow(label: label, value: biayaJuta);
      }).toList();
      final totalBiayaChart = sourceStats.fold(0.0, (sum, s) {
        final b = s is _FaktorStat
            ? s.totalBiaya
            : (s as _BagianStat).totalBiaya;
        return sum + b;
      });
      return _buildBiayaBarChart(
          rows: rows, totalBiaya: totalBiayaChart);
    } else if (_activeFilter == _FilterType.faktor) {
      final total =
          _faktorStats.fold(0, (sum, s) => sum + s.jumlah);
      return _buildHorizontalBarChart(
        title: _t('faktor_penyebab'),
        rows: _faktorStats
            .map((s) =>
                _ChartRow(label: s.namaFaktor, value: s.jumlah.toDouble()))
            .toList(),
        color: _C.green,
        total: total,
      );
    } else {
      final total =
          _bagianStats.fold(0, (sum, s) => sum + s.jumlah);
      return _buildHorizontalBarChart(
        title: _t('bagian_penyebab'),
        rows: _bagianStats
            .map((s) =>
                _ChartRow(label: s.bagian, value: s.jumlah.toDouble()))
            .toList(),
        color: _C.blue,
        total: total,
      );
    }
  }

  Widget _buildHorizontalBarChart({
    required String title,
    required List<_ChartRow> rows,
    required Color color,
    required int total,
  }) {
    final nonZero = rows.where((r) => r.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final zero   = rows.where((r) => r.value == 0).toList();
    final sorted = [...nonZero, ...zero];

    if (sorted.isEmpty || sorted.every((r) => r.value == 0)) {
      return _emptyBox();
    }

    final maxVal = sorted
        .map((r) => r.value)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primaryLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha:0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          ...sorted.map((row) {
            final frac   = maxVal > 0
                ? (row.value / maxVal).clamp(0.0, 1.0)
                : 0.0;
            final isZero = row.value == 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isZero
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: isZero
                      ? Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha:0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : LayoutBuilder(builder: (ctx, constraints) {
                          final barWidth =
                              constraints.maxWidth * frac;
                          final labelStr =
                              '${row.value.toInt()}';
                          return Stack(children: [
                            Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha:0.1),
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 22,
                              width: barWidth.clamp(
                                  0.0, constraints.maxWidth),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(
                              height: 22,
                              width: constraints.maxWidth,
                              child: Center(
                                child: Text(
                                  labelStr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ]);
                        }),
                ),
              ]),
            );
          }),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(children: [
            const SizedBox(width: 108),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_t('total')} KTS ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBiayaBarChart({
    required List<_ChartRow> rows,
    required double totalBiaya,
  }) {
    final nonZero = rows.where((r) => r.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final zero   = rows.where((r) => r.value == 0).toList();
    final sorted = [...nonZero, ...zero];

    if (sorted.isEmpty || sorted.every((r) => r.value == 0)) {
      return _emptyBox();
    }

    final maxVal = sorted
        .map((r) => r.value)
        .fold(0.0, (a, b) => a > b ? a : b);
    final totalLabel = NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(totalBiaya);

    double niceMax(double v) {
      if (v <= 0) return 1.0;
      final steps = [0.5, 1.0, 2.0, 2.5, 5.0, 10.0, 20.0, 50.0];
      for (final step in steps) {
        final candidate = (v / step).ceil() * step;
        if (candidate / step <= 10) return candidate;
      }
      return (v * 1.2).ceilToDouble();
    }

    final axisMax   = niceMax(maxVal * 1.05);
    const int ticks = 8;
    final List<double> axisVals = List.generate(
      ticks + 1,
      (i) => (axisMax / ticks) * i,
    );

    String fmtAxis(double v) {
      if (v == v.truncateToDouble()) return '${v.toInt()},00';
      return v.toStringAsFixed(2).replaceAll('.', ',');
    }

    String fmtRp(double v) => NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(v);

    void showBarDetail(BuildContext ctx, String label, double valueJuta) {
      final nominalRp = valueJuta * 1e6;
      showDialog(
        context: ctx,
        builder: (dialogCtx) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.primaryLight, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _C.orange,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                          Icons.monetization_on_rounded,
                          size: 16,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('biaya_kts'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _C.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: _C.textSec),
                      onPressed: () => Navigator.pop(dialogCtx),
                      padding: EdgeInsets.zero,
                    ),
                  ]),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _C.orange.withValues(alpha:0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _C.orange.withValues(alpha:0.3)),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _C.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _detailRow(
                        icon: Icons.bar_chart_rounded,
                        color: _C.orange,
                        label: widget.lang == 'ZH'
                            ? '百万卢比'
                            : widget.lang == 'EN'
                                ? 'Million IDR'
                                : 'Juta Rupiah',
                        value:
                            '${valueJuta.toStringAsFixed(2).replaceAll('.', ',')} Jt',
                      ),
                      const SizedBox(height: 8),
                      _detailRow(
                        icon: Icons.account_balance_wallet_rounded,
                        color: _C.green,
                        label: widget.lang == 'ZH'
                            ? '总费用'
                            : widget.lang == 'EN'
                                ? 'Total Cost'
                                : 'Total Nominal',
                        value: fmtRp(nominalRp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    const double labelW  = 100.0;
    const double barH    = 22.0;
    const double barVPad = 3.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primaryLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha:0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Center(
                child: Text(
                  _t('biaya_kts'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _C.orange,
                  ),
                ),
              ),
            ),
            Text(
              widget.lang == 'ZH'
                  ? '百万卢比'
                  : widget.lang == 'EN'
                      ? 'Million IDR'
                      : 'Juta Rupiah',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ]),
          const SizedBox(height: 8),

          LayoutBuilder(builder: (ctx, constraints) {
            const double rightPad = 48.0;
            final double barAreaW =
                constraints.maxWidth - labelW - 6 - rightPad;
            final List<double> tX = axisVals
                .map((v) => (v / axisMax) * barAreaW)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LABEL X AXIS
                SizedBox(
                  height: 14,
                  child: Row(children: [
                    SizedBox(width: labelW + 6),
                    SizedBox(
                      width: barAreaW,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: List.generate(axisVals.length, (i) {
                          double leftPos = tX[i];
                          if (i == axisVals.length - 1) {
                            leftPos -= 28;
                          }
                          return Positioned(
                            left: leftPos,
                            top: 0,
                            width: 36,
                            height: 14,
                            child: Text(
                              fmtAxis(axisVals[i]),
                              textAlign: i == 0
                                  ? TextAlign.left
                                  : i == axisVals.length - 1
                                      ? TextAlign.right
                                      : TextAlign.center,
                              style: const TextStyle(
                                fontSize: 8.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 2),

                // GARIS ATAS
                Row(children: [
                  SizedBox(width: labelW + 6),
                  Container(
                      width: barAreaW,
                      height: 1,
                      color: const Color(0xFFE2E8F0)),
                  SizedBox(width: rightPad),
                ]),
                const SizedBox(height: 4),

                // BARIS DATA
                ...sorted.map((row) {
                  final frac     = axisMax > 0
                      ? (row.value / axisMax).clamp(0.0, 1.0)
                      : 0.0;
                  final isZero   = row.value == 0;
                  final barWidth =
                      (barAreaW * frac).clamp(0.0, barAreaW);
                  final valStr   = row.value > 0
                      ? row.value
                          .toStringAsFixed(2)
                          .replaceAll('.', ',')
                      : '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: GestureDetector(
                      onTap: isZero
                          ? null
                          : () => showBarDetail(
                              ctx, row.label, row.value),
                      child: SizedBox(
                        height: barH,
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: labelW,
                              child: Text(
                                row.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isZero
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _BiayaBarPainter(
                                        tX: tX,
                                        barWidth: barWidth,
                                        barH: barH,
                                        barVPad: barVPad,
                                        isZero: isZero,
                                        barColor: _C.orange,
                                      ),
                                    ),
                                  ),
                                  if (!isZero)
                                    Positioned(
                                      left: barWidth + 4,
                                      top: 0,
                                      bottom: 0,
                                      child: Align(
                                        alignment:
                                            Alignment.centerLeft,
                                        child: Text(
                                          valStr,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 4),
                // GARIS BAWAH
                Row(children: [
                  SizedBox(width: labelW + 6),
                  Container(
                      width: barAreaW,
                      height: 1,
                      color: const Color(0xFFE2E8F0)),
                  SizedBox(width: rightPad),
                ]),
              ],
            );
          }),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                widget.lang == 'ZH'
                    ? '总费用 '
                    : widget.lang == 'EN'
                        ? 'Total Cost '
                        : 'Total Biaya ',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  totalLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableBagian() {
    final stats    = _bagianStats;
    final total    = stats.fold(0, (s, e) => s + e.jumlah);
    final totBiaya = stats.fold(0.0, (s, e) => s + e.totalBiaya);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.blue.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        _tableHeader(
          [
            _t('bagian_label'),
            _t('jumlah_kts'),
            _t('persen'),
            _t('total_nominal'),
          ],
          [3, 2, 1, 3],
          _C.blueLight,
          _C.blue,
        ),
        ...stats.asMap().entries.map((e) {
          final i   = e.key;
          final s   = e.value;
          final pct = total > 0
              ? (s.jumlah / total * 100).toStringAsFixed(0)
              : '0';
          return Column(children: [
            if (i > 0)
              const Divider(
                  height: 1, color: Color(0xFFE0E7FF)),
            _tableRow(
              [
                s.bagian,
                '${s.jumlah}',
                '$pct%',
                _formatRp(s.totalBiaya),
              ],
              [3, 2, 1, 3],
              numCols: {1, 2, 3},
              highlightCol: 1,
              highlightColor: s.jumlah > 0
                  ? _C.blue
                  : const Color(0xFFCBD5E1),
              mutedRow: s.jumlah == 0,
            ),
          ]);
        }),
        _tableFooter(
          [
            widget.lang == 'ZH'
                ? '合计'
                : widget.lang == 'EN'
                    ? 'Total'
                    : 'Jumlah',
            '$total',
            '100%',
            _formatRp(totBiaya),
          ],
          [3, 2, 1, 3],
          _C.blueLight,
          _C.blue,
        ),
      ]),
    );
  }

  Widget _buildTableFaktor() {
    final stats = _faktorStats;
    if (stats.isEmpty) return _emptyBox();
    final total    = stats.fold(0, (s, e) => s + e.jumlah);
    final totBiaya = stats.fold(0.0, (s, e) => s + e.totalBiaya);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.greenLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.green.withValues(alpha:0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        _tableHeader(
          [
            _t('faktor_label'),
            _t('jumlah_kts'),
            _t('persen'),
            _t('total_nominal'),
          ],
          [3, 2, 1, 3],
          _C.greenLight,
          _C.green,
        ),
        ...stats.asMap().entries.map((e) {
          final i   = e.key;
          final s   = e.value;
          final pct = total > 0
              ? (s.jumlah / total * 100).toStringAsFixed(0)
              : '0';
          return Column(children: [
            if (i > 0)
              const Divider(
                  height: 1, color: Color(0xFFD1FAE5)),
            _tableRow(
              [
                s.namaFaktor,
                '${s.jumlah}',
                '$pct%',
                _formatRp(s.totalBiaya),
              ],
              [3, 2, 1, 3],
              numCols: {1, 2, 3},
              highlightCol: 1,
              highlightColor: s.jumlah > 0
                  ? _C.green
                  : const Color(0xFFCBD5E1),
              mutedRow: s.jumlah == 0,
            ),
          ]);
        }),
        _tableFooter(
          [
            widget.lang == 'ZH'
                ? '合计'
                : widget.lang == 'EN'
                    ? 'Total'
                    : 'Jumlah',
            '$total',
            '100%',
            _formatRp(totBiaya),
          ],
          [3, 2, 1, 3],
          _C.greenLight,
          _C.green,
        ),
      ]),
    );
  }

  Widget _tableHeader(
    List<String> cols,
    List<int> flexes,
    Color bg,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: List.generate(
          cols.length,
          (i) => Expanded(
            flex: flexes[i],
            child: Text(
              cols[i],
              textAlign: i == 0
                  ? TextAlign.left
                  : i == cols.length - 1
                      ? TextAlign.right
                      : TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableRow(
    List<String> vals,
    List<int> flexes, {
    required Set<int> numCols,
    int? highlightCol,
    Color? highlightColor,
    bool mutedRow = false,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: List.generate(vals.length, (i) {
          final isNum = numCols.contains(i);
          final isHl  = i == highlightCol;
          final color = mutedRow
              ? const Color(0xFFCBD5E1)
              : isHl
                  ? (highlightColor ?? _C.textPrimary)
                  : const Color(0xFF334155);
          return Expanded(
            flex: flexes[i],
            child: Text(
              vals[i],
              textAlign: i == 0
                  ? TextAlign.left
                  : i == vals.length - 1
                      ? TextAlign.right
                      : TextAlign.center,
              style: TextStyle(
                fontSize: isNum ? 13 : 12,
                fontWeight:
                    isHl ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tableFooter(
    List<String> vals,
    List<int> flexes,
    Color bg,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg.withValues(alpha:0.6),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12)),
      ),
      child: Row(
        children: List.generate(
          vals.length,
          (i) => Expanded(
            flex: flexes[i],
            child: Text(
              vals[i],
              textAlign: i == 0
                  ? TextAlign.left
                  : i == vals.length - 1
                      ? TextAlign.right
                      : TextAlign.center,
              style: TextStyle(
                fontSize: i == 1 ? 15 : 12,
                fontWeight: FontWeight.w900,
                color: i == 0 ? _C.textPrimary : color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ]),
    );
  }

  String _formatRp(double v) {
    if (v == 0) return 'Rp0';
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(v);
  }

  Widget _emptyBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primaryLight, width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 40, color: _C.primaryLight),
            const SizedBox(height: 8),
            Text(
              _t('tidak_ada'),
              style: const TextStyle(
                  color: _C.textSec, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF64748B)),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    ]);
  }

  Widget _shimmerBox(double h) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildFilterBar(),
      _buildChartToggle(),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _C.primary,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _chartExpanded
                    ? _buildChart()
                    : const SizedBox.shrink(),
              ),
              if (_loading)
                _buildShimmerList()
              else if (_activeFilter == _FilterType.faktor) ...[
                _sectionTitle(
                    _t('faktor_penyebab'), _C.green, Icons.tag_rounded),
                _buildTableFaktor(),
              ] else if (_activeFilter == _FilterType.biaya) ...[
                if (_biayaSubFilter == 'bagian') ...[
                  _sectionTitle(
                      _t('bagian_penyebab'), _C.blue, Icons.grid_view_rounded),
                  _buildTableBagian(),
                ] else ...[
                  _sectionTitle(
                      _t('faktor_penyebab'), _C.green, Icons.tag_rounded),
                  _buildTableFaktor(),
                ],
              ] else ...[
                _sectionTitle(
                    _t('bagian_penyebab'), _C.blue, Icons.grid_view_rounded),
                _buildTableBagian(),
              ],
            ],
          ),
        ),
      ),
    ]);
  }
}

class _BiayaBarPainter extends CustomPainter {
  final List<double> tX;
  final double barWidth;
  final double barH;
  final double barVPad;
  final bool isZero;
  final Color barColor;

  const _BiayaBarPainter({
    required this.tX,
    required this.barWidth,
    required this.barH,
    required this.barVPad,
    required this.isZero,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (int i = 1; i < tX.length; i++) {
      canvas.drawLine(
        Offset(tX[i], 0),
        Offset(tX[i], size.height),
        tickPaint,
      );
    }
    if (!isZero && barWidth > 0) {
      final barPaint = Paint()..color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barVPad, barWidth, size.height - barVPad * 2),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BiayaBarPainter old) =>
      old.barWidth != barWidth || old.isZero != isZero;
}