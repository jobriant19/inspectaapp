import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

const _kGreen = Color(0xFF059669);

enum _T { monthly, daily, offDay }

extension _TE on _T {
  String get db => ['monthly', 'daily_specific', 'off_day'][index];

  static _T from(String s) => s == 'daily_specific'
      ? _T.daily
      : s == 'off_day'
          ? _T.offDay
          : _T.monthly;
}

class AdminTarget5rScreen extends StatefulWidget {
  final String lang;
  const AdminTarget5rScreen({super.key, required this.lang});

  @override
  State<AdminTarget5rScreen> createState() => _State();
}

class _State extends State<AdminTarget5rScreen> {
  List<Map<String, dynamic>> _all = [], _view = [];
  bool _loading = true;
  _T? _fType;
  bool? _fAktif;
  String _q = '';

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
          .order('tahun', ascending: false)
          .order('bulan', ascending: false)
          .order('specific_date', ascending: false);
      if (!mounted) return;
      _all = List<Map<String, dynamic>>.from(d);
      _filter();
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(_t('err'), err: true);
    }
  }

  void _filter() {
    var l = List<Map<String, dynamic>>.from(_all);
    if (_fType != null) l = l.where((r) => r['type'] == _fType!.db).toList();
    if (_fAktif != null) {
      l = l.where((r) => (r['is_aktif'] as bool? ?? true) == _fAktif).toList();
    }
    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      l = l
          .where((r) => [
                r['off_day_label'],
                r['keterangan'],
                r['specific_date'],
                '${r['bulan']}',
                '${r['tahun']}',
              ].any((v) => (v ?? '').toString().toLowerCase().contains(q)))
          .toList();
    }
    _view = l;
  }

  Future<void> _save({
    required bool isEdit,
    int? id,
    required _T type,
    int? bulan,
    int? tahun,
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
        'is_aktif'                : aktif,
        'keterangan'              : ket?.isEmpty == true ? null : ket,
        'updated_at'              : DateTime.now().toIso8601String(),
      };

      if (type == _T.monthly) {
        payload['bulan']                    = bulan;
        payload['tahun']                    = tahun;
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
      } else if (type == _T.daily) {
        payload['bulan']                    = null;
        payload['tahun']                    = null;
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
        payload['bulan']                    = null;
        payload['tahun']                    = null;
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
        _snack(_t('ok_edit'));
      } else {
        await Supabase.instance.client
            .from('target_5r_findings')
            .insert(payload);
        _snack(_t('ok_add'));
      }
      _fetch();
    } catch (e) {
      debugPrint('Save target error: $e');
      _snack(_t('err'), err: true);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_t('del_q'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(_t('del_d'), style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_t('cancel'),
                  style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text(_t('delete'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client
          .from('target_5r_findings')
          .delete()
          .eq('id', id);
      _snack(_t('ok_del'));
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

  @override
  Widget build(BuildContext ctx) => Scaffold(
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: _view.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _card(_view[i]),
                      )),
      ),
    ]),
  );

  // FILTER BAR
  Widget _filterBar() => Container(
    color: Colors.white,
    child: Column(children: [
      // ADD TARGET BUTTON
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: GestureDetector(
          onTap: () => _showForm(),
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

      // SEARCH BAR + ACTIVE FILTER
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(children: [
          // SEARCH BAR
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (v) => setState(() { _q = v; _filter(); }),
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: _t('search'),
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: _kGreen, size: 18),
                filled: true,
                fillColor: const Color(0xFFF0FDF4),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: _kGreen.withValues(alpha:0.3))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: _kGreen.withValues(alpha:0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: _kGreen, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ACTIVE FILTER
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                color: _fAktif == null
                    ? Colors.grey.shade100
                    : _fAktif == true
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _fAktif == null
                      ? Colors.grey.shade300
                      : _fAktif == true
                          ? _kGreen.withValues(alpha:0.5)
                          : Colors.red.shade200,
                  width: 1.2,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<bool?>(
                  value: _fAktif,
                  isDense: true,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _fAktif == null
                        ? Colors.grey.shade500
                        : _fAktif == true
                            ? _kGreen
                            : Colors.red.shade400,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  style: GoogleFonts.poppins(fontSize: 12),
                  items: [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text(
                        widget.lang == 'ID'
                            ? 'Semua'
                            : widget.lang == 'ZH'
                                ? '全部'
                                : 'All',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text(
                        _t('active'),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _kGreen,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text(
                        _t('inactive'),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() { _fAktif = v; _filter(); }),
                ),
              ),
            ),
          ),
        ]),
      ),

      // TYPE FILTER CHIP
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
            _fType == _T.monthly,
            Icons.calendar_month_rounded,
            _kGreen,
            () => setState(() { _fType = _T.monthly; _filter(); }),
          )),
          const SizedBox(width: 6),
          // DAILY
          Expanded(child: _typeChip(
            _t('daily'),
            _fType == _T.daily,
            Icons.event_rounded,
            const Color(0xFF2563EB),
            () => setState(() { _fType = _T.daily; _filter(); }),
          )),
          const SizedBox(width: 6),
          // OFF DAY
          Expanded(child: _typeChip(
            _t('offDay'),
            _fType == _T.offDay,
            Icons.beach_access_rounded,
            const Color(0xFFD97706),
            () => setState(() { _fType = _T.offDay; _filter(); }),
          )),
        ]),
      ),

      // OFF DAY FILTER ACTIVE INFO BANNER
      if (_fType == _T.offDay)
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
        padding: const EdgeInsets.symmetric(vertical: 7),
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
            if (icon != null)
              Icon(icon, size: 13, color: sel ? Colors.white : color),
            if (icon != null) const SizedBox(height: 2),
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
    final type = _TE.from(item['type'] as String? ?? 'monthly');
    final aktif = item['is_aktif'] as bool? ?? true;
    final (Color tc, IconData ti, String tl) = switch (type) {
      _T.monthly => (_kGreen, Icons.calendar_month_rounded, _t('monthly')),
      _T.daily => (
          const Color(0xFF2563EB),
          Icons.event_rounded,
          _t('daily')
        ),
      _T.offDay => (
          const Color(0xFFD97706),
          Icons.beach_access_rounded,
          _t('offDay')
        ),
    };
    final subtitle = type == _T.monthly
        ? '${DateFormat('MMMM', _locale).format(DateTime(item['tahun'] as int? ?? 2024, item['bulan'] as int? ?? 1))} ${item['tahun']}'
        : (item['specific_date'] ?? '-').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: aktif ? tc.withValues(alpha:0.3) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: aktif
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
            // Header row
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A))),
              ])),
              _statusBadge(aktif),
            ]),

            // OFF DAY: LABEL + INFO
            if (type == _T.offDay) ...[
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
            if (type != _T.offDay) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _badge(Icons.people_rounded,
                    item['target_anggota'] as int? ?? 0, tc),
                _badge(Icons.search_rounded,
                    item['target_inspeksi'] as int? ?? 0, tc),
                _badge(Icons.check_circle_rounded,
                    item['target_anggota_selesai'] as int? ?? 0, _kGreen),
                _badge(Icons.check_circle_outline_rounded,
                    item['target_inspeksi_selesai'] as int? ?? 0, _kGreen),
                _badge(Icons.location_city_rounded,
                    item['target_lokasi'] as int? ?? 0, tc),
                _badge(Icons.apartment_rounded,
                    item['target_unit'] as int? ?? 0, tc),
                _badge(Icons.domain_rounded,
                    item['target_subunit'] as int? ?? 0, tc),
                _badge(Icons.place_rounded,
                    item['target_area'] as int? ?? 0, tc),
              ]),
              if (type == _T.daily) ...[
                const SizedBox(height: 4),
                Text(_t('override'),
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF2563EB),
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
              _iconBtn(Icons.edit_rounded, const Color(0xFF2563EB),
                  () => _showForm(item: item)),
              const SizedBox(width: 8),
              _iconBtn(Icons.delete_outline_rounded, Colors.red,
                  () => _delete(item['id'] as int)),
            ]),
          ])),
    );
  }

  Widget _statusBadge(bool aktif) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: aktif
              ? const Color(0xFF22C55E).withValues(alpha:0.12)
              : Colors.grey.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: aktif
                  ? const Color(0xFF22C55E).withValues(alpha:0.5)
                  : Colors.grey.withValues(alpha:0.3)),
        ),
        child: Text(
          aktif
              ? (widget.lang == 'EN'
                  ? 'Active'
                  : widget.lang == 'ZH'
                      ? '启用'
                      : 'Aktif')
              : (widget.lang == 'EN'
                  ? 'Inactive'
                  : widget.lang == 'ZH'
                      ? '禁用'
                      : 'Nonaktif'),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: aktif ? const Color(0xFF16A34A) : Colors.grey),
        ),
      );

  Widget _badge(IconData icon, int val, Color c) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: c.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withValues(alpha:0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text('$val',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w700, color: c)),
        ]),
      );

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

  // FORM
  void _showForm({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    _T selType = isEdit
        ? _TE.from(item['type'] as String? ?? 'monthly')
        : _T.monthly;
    int selBulan = item?['bulan'] as int? ?? DateTime.now().month;
    int selTahun = item?['tahun'] as int? ?? DateTime.now().year;
    DateTime selDate = item?['specific_date'] != null
        ? (DateTime.tryParse(item!['specific_date'] as String) ??
            DateTime.now())
        : DateTime.now();
    bool aktif = item?['is_aktif'] as bool? ?? true;

    final cA = TextEditingController(
        text: '${item?['target_anggota'] ?? 2}');
    final cI = TextEditingController(
        text: '${item?['target_inspeksi'] ?? 2}');
    final cL = TextEditingController(
        text: '${item?['target_lokasi'] ?? 5}');
    final cU = TextEditingController(
        text: '${item?['target_unit'] ?? 5}');
    final cS = TextEditingController(
        text: '${item?['target_subunit'] ?? 5}');
    final cAr = TextEditingController(
        text: '${item?['target_area'] ?? 5}');
    final cASelesai = TextEditingController(
        text: '${item?['target_anggota_selesai'] ?? 2}');
    final cISelesai = TextEditingController(
        text: '${item?['target_inspeksi_selesai'] ?? 2}');
    final cLbl = TextEditingController(
        text: item?['off_day_label'] as String? ?? '');
    final cKet = TextEditingController(
        text: item?['keterangan'] as String? ?? '');
    final fk = GlobalKey<FormState>();
    final tahunList =
        List.generate(6, (i) => DateTime.now().year - 1 + i);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setM) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Container(
                  constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(ctx).size.height * 0.92),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24))),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Form(
                        key: fk,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                                child: Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius:
                                            BorderRadius.circular(
                                                2)))),
                            const SizedBox(height: 14),
                            // ── TITLE
                            Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color:
                                          _kGreen.withValues(alpha:0.1),
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  child: Icon(
                                      isEdit
                                          ? Icons.edit_rounded
                                          : Icons.add_rounded,
                                      color: _kGreen,
                                      size: 20)),
                              const SizedBox(width: 10),
                              Text(
                                  isEdit ? _t('edit') : _t('add'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen)),
                            ]),
                            const SizedBox(height: 18),

                            // TYPE SELECTOR
                            Text(_t('type'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _kGreen)),
                            const SizedBox(height: 8),
                            _buildTypeSelector(
                                selType, setM, (t) {
                              selType = t;
                              if (t == _T.monthly) {
                                selBulan = DateTime.now().month;
                                selTahun = DateTime.now().year;
                              } else {
                                selDate = DateTime.now();
                              }
                            }),
                            const SizedBox(height: 18),

                            // MONTHLY: MONTH + YEAR
                            if (selType == _T.monthly) ...[
                              Row(children: [
                                Expanded(
                                    child: _styledDropdownMonth(
                                        selBulan,
                                        (v) => setM(
                                            () => selBulan = v!))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _styledDropdownYear(
                                        selTahun,
                                        tahunList,
                                        (v) => setM(
                                            () => selTahun = v!))),
                              ]),
                              const SizedBox(height: 16),
                              _sectionLabel(
                                  Icons.track_changes_rounded,
                                  widget.lang == 'ID'
                                      ? 'Target Bulanan'
                                      : 'Monthly Targets'),
                              const SizedBox(height: 10),
                              _targetGrid(cA, cI, cL, cU, cS, cAr,
                                cASelesai: cASelesai, cISelesai: cISelesai),
                            ],

                            // DAILY / OFF DAY: DATE PICKER
                            if (selType != _T.monthly) ...[
                              _styledDatePicker(selDate, ctx,
                                  (p) => setM(() => selDate = p)),
                              const SizedBox(height: 16),
                              if (selType == _T.offDay) ...[
                                _sectionLabel(
                                    Icons.beach_access_rounded,
                                    _t('label')),
                                const SizedBox(height: 8),
                                _formFieldStyled(cLbl, _t('label'),
                                    required: false),
                                const SizedBox(height: 12),
                                // INFO: OFFDAY NO TARGET
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFFFFF7ED),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFFBBF24)
                                            .withValues(alpha:0.5)),
                                  ),
                                  child: Row(children: [
                                    const Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: Color(0xFFD97706)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(
                                            _t('holiday_info'),
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: const Color(
                                                    0xFFD97706)))),
                                  ]),
                                ),
                              ],
                              if (selType == _T.daily) ...[
                                _sectionLabel(
                                    Icons.track_changes_rounded,
                                    widget.lang == 'ID'
                                        ? 'Target Harian'
                                        : 'Daily Targets'),
                                const SizedBox(height: 10),
                                _targetGrid(cA, cI, cL, cU, cS, cAr,
                                  cASelesai: cASelesai, cISelesai: cISelesai),
                              ],
                            ],

                            const SizedBox(height: 14),
                            _formFieldStyled(
                                cKet, _t('ket'),
                                required: false,
                                maxLines: 2),
                            const SizedBox(height: 12),

                            // ACTIVE TOGGLE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.toggle_on_rounded,
                                          color: aktif
                                              ? _kGreen
                                              : Colors.grey,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text(_t('aktif'),
                                          style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: aktif
                                                  ? _kGreen
                                                  : Colors.grey
                                                      .shade600)),
                                    ]),
                                    Switch(
                                        value: aktif,
                                        activeColor:
                                            const Color(0xFF22C55E),
                                        activeTrackColor:
                                            const Color(0xFFBBF7D0),
                                        inactiveThumbColor:
                                            Colors.grey.shade400,
                                        inactiveTrackColor:
                                            Colors.grey.shade200,
                                        onChanged: (v) =>
                                            setM(() => aktif = v)),
                                  ]),
                            ),
                            const SizedBox(height: 20),

                            // SAVE BUTTON
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                      Icons.save_rounded,
                                      size: 18,
                                      color: Colors.white),
                                  label: Text(_t('save'),
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  onPressed: () async {
                                    if (!fk.currentState!
                                        .validate()) { return; }
                                    Navigator.pop(ctx);
                                    await _save(
                                      isEdit: isEdit,
                                      id: item?['id'] as int?,
                                      type: selType,
                                      bulan: selType == _T.monthly
                                          ? selBulan
                                          : null,
                                      tahun: selType == _T.monthly
                                          ? selTahun
                                          : null,
                                      date: selType != _T.monthly
                                          ? selDate
                                          : null,
                                      a: int.tryParse(cA.text) ?? 0,
                                      i: int.tryParse(cI.text) ?? 0,
                                      l: int.tryParse(cL.text) ?? 0,
                                      u: int.tryParse(cU.text) ?? 0,
                                      s: int.tryParse(cS.text) ?? 0,
                                      ar: int.tryParse(cAr.text) ??
                                          0,
                                      aSelesai: int.tryParse(cASelesai.text) ?? 0,
                                      iSelesai: int.tryParse(cISelesai.text) ?? 0,
                                      label: cLbl.text.trim().isEmpty
                                          ? null
                                          : cLbl.text.trim(),
                                      ket: cKet.text.trim().isEmpty
                                          ? null
                                          : cKet.text.trim(),
                                      aktif: aktif,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    elevation: 3,
                                    shadowColor:
                                        _kGreen.withValues(alpha:0.4),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                )),
                          ],
                        )),
                  ),
                ),
              )),
    );
  }

  // FORM HELPERS
  Widget _buildTypeSelector(
      _T current, StateSetter setM, void Function(_T) onChange) {
    final types = [
      (
        _T.monthly,
        _t('monthly'),
        Icons.calendar_month_rounded,
        _kGreen
      ),
      (
        _T.daily,
        _t('daily'),
        Icons.event_rounded,
        const Color(0xFF2563EB)
      ),
      (
        _T.offDay,
        _t('offDay'),
        Icons.beach_access_rounded,
        const Color(0xFFD97706)
      ),
    ];
    return Row(
      children: types.map((t) {
        final sel = current == t.$1;
        return Expanded(
            child: Padding(
          padding: EdgeInsets.only(right: t.$1 != _T.offDay ? 8 : 0),
          child: GestureDetector(
            onTap: () => setM(() => onChange(t.$1)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? t.$4 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? t.$4 : Colors.grey.shade200,
                    width: sel ? 1.5 : 1),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: t.$4.withValues(alpha:0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$3,
                        size: 18,
                        color: sel ? Colors.white : t.$4),
                    const SizedBox(height: 4),
                    Text(t.$2,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? Colors.white
                                : Colors.grey.shade600),
                        textAlign: TextAlign.center),
                  ]),
            ),
          ),
        ));
      }).toList(),
    );
  }

  Widget _sectionLabel(IconData icon, String label) => Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: _kGreen.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: _kGreen),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kGreen)),
      ]);

  Widget _styledDropdownMonth(int value, ValueChanged<int?> onChanged) {
    return _StyledDropdown<int>(
      value: value,
      icon: Icons.calendar_today_rounded,
      label: _t('month'),
      color: _kGreen,
      items: List.generate(12, (i) {
        final name =
            DateFormat('MMMM', _locale).format(DateTime(2000, i + 1));
        return DropdownMenuItem(
          value: i + 1,
          child: Text(name, style: GoogleFonts.poppins(fontSize: 13)),
        );
      }),
      onChanged: onChanged,
    );
  }

  Widget _styledDropdownYear(
      int value, List<int> years, ValueChanged<int?> onChanged) {
    return _StyledDropdown<int>(
      value: value,
      icon: Icons.date_range_rounded,
      label: _t('year'),
      color: _kGreen,
      items: years
          .map((y) => DropdownMenuItem(
              value: y,
              child: Text('$y',
                  style: GoogleFonts.poppins(fontSize: 13))))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _styledDatePicker(
      DateTime date, BuildContext ctx, ValueChanged<DateTime> onPick) {
    return GestureDetector(
      onTap: () async {
        final p = await showDatePicker(
            context: ctx,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: _kGreen,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ));
        if (p != null) onPick(p);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kGreen.withValues(alpha:0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: _kGreen.withValues(alpha:0.08),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _kGreen.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.calendar_today_rounded,
                size: 16, color: _kGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(_t('date'),
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.black45)),
              Text(
                  DateFormat('d MMMM yyyy', _locale).format(date),
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A))),
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.edit_calendar_rounded,
                  size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                  widget.lang == 'EN'
                      ? 'Change'
                      : widget.lang == 'ZH'
                          ? '更改'
                          : 'Ubah',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _formFieldStyled(TextEditingController ctrl, String label,
      {bool required = true, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _kGreen, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return _t('req');
        }
        return null;
      },
    );
  }

  Widget _targetGrid(
    TextEditingController cA,
    TextEditingController cI,
    TextEditingController cL,
    TextEditingController cU,
    TextEditingController cS,
    TextEditingController cAr, {
    TextEditingController? cASelesai,
    TextEditingController? cISelesai,
  }) {
    final pairs = [
      (cA, _t('a'), Icons.people_rounded, _kGreen),
      if (cASelesai != null)
        (cASelesai, widget.lang == 'ID' ? 'Target Anggota Selesai'
            : widget.lang == 'ZH' ? '成员完成目标' : 'Member Completion Target',
        Icons.check_circle_rounded, _kGreen),
      (cI, _t('i'), Icons.search_rounded, _kGreen),
      if (cISelesai != null)
        (cISelesai, widget.lang == 'ID' ? 'Target Inspeksi Selesai'
            : widget.lang == 'ZH' ? '检查完成目标' : 'Inspection Completion Target',
        Icons.check_circle_outline_rounded, _kGreen),
      (cL, _t('l'), Icons.location_city_rounded, const Color(0xFF2563EB)),
      (cU, _t('u'), Icons.apartment_rounded, const Color(0xFF2563EB)),
      (cS, _t('s'), Icons.domain_rounded, const Color(0xFF7C3AED)),
      (cAr, _t('ar'), Icons.place_rounded, const Color(0xFF7C3AED)),
    ];
    final w = (MediaQuery.of(context).size.width - 60) / 2;
    return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: pairs.map((p) {
          return SizedBox(
            width: w,
            child: TextFormField(
              controller: p.$1,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: p.$2,
                labelStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
                prefixIcon: Icon(p.$3, size: 16, color: p.$4),
                filled: true,
                fillColor: p.$4.withValues(alpha:0.04),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: p.$4.withValues(alpha:0.3))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: p.$4.withValues(alpha:0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: p.$4, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                return (n == null || n < 0) ? _t('num') : null;
              },
            ),
          );
        }).toList());
  }

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
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha:0.08),
                    shape: BoxShape.circle),
                child: Icon(Icons.track_changes_rounded,
                    size: 48, color: _kGreen.withValues(alpha:0.5))),
            const SizedBox(height: 12),
            Text(_t('empty'),
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black38,
                    fontWeight: FontWeight.w500)),
          ]));
}

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final IconData icon;
  final String label;
  final Color color;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _StyledDropdown({
    super.key,
    required this.value,
    required this.icon,
    required this.label,
    required this.color,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha:0.07),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500)),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                isDense: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: color),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF0C4A6E),
                    fontWeight: FontWeight.w600),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}