// lib/features/analytics/accident_recurring_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

// ─── Warna (sama dengan analytics_screen) ────────────────────────────────────
class _AC {
  static const primary    = Color(0xFF0EA5E9);
  static const textPrimary   = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const divider    = Color(0xFFE0F2FE);
  static const red        = Color(0xFFEF4444);
  static const amber      = Color(0xFFF59E0B);
  static const green      = Color(0xFF10B981);
}

// ─── Widget utama — stateless, semua state dikelola parent ───────────────────
class AccidentRecurringTab extends StatelessWidget {
  final String lang;
  final Future<List<Map<String, dynamic>>>? accidentRecurringFuture;
  final DateTime recurringFrom;
  final DateTime recurringTo;
  final String recurringUserName;
  final VoidCallback onShowPeriodPicker;
  final VoidCallback onShowUserPicker;

  const AccidentRecurringTab({
    super.key,
    required this.lang,
    required this.accidentRecurringFuture,
    required this.recurringFrom,
    required this.recurringTo,
    required this.recurringUserName,
    required this.onShowPeriodPicker,
    required this.onShowUserPicker,
  });

  String _t(String id, String en, String zh) {
    if (lang == 'ID') return id;
    if (lang == 'ZH') return zh;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final locale = lang == 'ID' ? 'id_ID' : lang == 'ZH' ? 'zh_CN' : 'en_US';
    final fromLabel = DateFormat('MMM yyyy', locale).format(recurringFrom);
    final toLabel   = DateFormat('MMM yyyy', locale).format(recurringTo);
    final periodLabel = '$fromLabel - $toLabel';

    return Column(children: [
      // ── Filter row ──────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(child: _FilterBtn(
            label: periodLabel,
            icon: Icons.calendar_month_rounded,
            onTap: onShowPeriodPicker,
          )),
          const SizedBox(width: 10),
          Expanded(child: _FilterBtn(
            label: recurringUserName.isEmpty
                ? _t('Semua Penemu', 'All Finders', '所有发现者')
                : recurringUserName,
            onTap: onShowUserPicker,
          )),
        ]),
      ),

      // ── Title ───────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _t('Laporan Kecelakaan Berulang',
               'Recurring Accident Reports', '重复事故报告'),
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: _AC.textPrimary),
          ),
        ),
      ),
      const Divider(height: 1, color: _AC.divider),

      // ── List ────────────────────────────────────────────────────────────
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: accidentRecurringFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmer();
            }
            final groups = snapshot.data ?? [];
            if (groups.isEmpty) {
              return _buildEmpty(context);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AccidentRecurringCard(
                group: groups[i],
                lang: lang,
                onTap: () => _showDetail(context, groups[i]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFFEF2F2), shape: BoxShape.circle),
          child: Icon(Icons.warning_amber_rounded, size: 36,
              color: _AC.red.withOpacity(0.5)),
        ),
        const SizedBox(height: 16),
        Text(
          _t('Tidak ada laporan kecelakaan berulang.',
             'No recurring accident reports.',
             '没有重复的事故报告。'),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 14, color: _AC.textSecondary, height: 1.5),
        ),
      ],
    ));
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── Detail bottom sheet ────────────────────────────────────────────────────
  void _showDetail(BuildContext context, Map<String, dynamic> group) {
    final topic   = group['topic'] as String;
    final reports = group['reports'] as List<Map<String, dynamic>>;
    final locale  = lang == 'ID' ? 'id_ID' : lang == 'ZH' ? 'zh_CN' : 'en_US';
    final listLabel = lang == 'ID' ? 'Daftar Laporan'
        : lang == 'ZH' ? '报告列表' : 'Report List';
    final totalLabel = lang == 'ID' ? 'Total' : lang == 'ZH' ? '总计' : 'Total';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(child: Text(topic, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold,
                    color: _AC.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('$totalLabel: ${reports.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: _AC.red)),
                ),
              ]),
            ),
            const Divider(height: 1, color: _AC.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('$listLabel (${reports.length})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: _AC.textPrimary)),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _AccidentReportCard(
                    data: reports[i], lang: lang, locale: locale),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Card untuk grup recurring ────────────────────────────────────────────────
class _AccidentRecurringCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final String lang;
  final VoidCallback onTap;

  const _AccidentRecurringCard({
    required this.group,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final topic       = group['topic'] as String? ?? '-';
    final locationArea = group['locationArea'] as String? ?? '';
    final total       = group['total'] as int? ?? 0;
    final imageUrl    = group['imageUrl'] as String?;
    final severity    = group['severityPattern'] as String? ?? topic;

    // Warna berdasarkan severity
    Color color; IconData icon;
    final s = severity.toLowerCase();
    if (s.contains('berat') || s.contains('heavy') || s.contains('重')) {
      color = _AC.red; icon = Icons.dangerous_rounded;
    } else if (s.contains('menengah') || s.contains('medium') || s.contains('中')) {
      color = _AC.amber; icon = Icons.warning_amber_rounded;
    } else {
      color = _AC.green; icon = Icons.info_outline_rounded;
    }

    final totalLabel = lang == 'ID' ? 'Total' : lang == 'ZH' ? '总计' : 'Total';
    final sevLabel   = lang == 'ID' ? 'Pola: $severity'
        : lang == 'ZH' ? '模式: $severity' : 'Pattern: $severity';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Thumbnail
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80, height: 80,
              color: color.withOpacity(0.1),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, color: color, size: 32))
                  : Icon(icon, color: color, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(topic,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.repeat_rounded, size: 12, color: color.withOpacity(0.7)),
                const SizedBox(width: 3),
                Expanded(child: Text(sevLabel,
                    style: TextStyle(fontSize: 11,
                        color: color.withOpacity(0.8)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              if (locationArea.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 12,
                      color: _AC.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(child: Text(locationArea,
                      style: const TextStyle(
                          fontSize: 11, color: _AC.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ]),
          )),
          // Badge total
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(totalLabel,
                  style: TextStyle(
                      fontSize: 9, color: color.withOpacity(0.7))),
              Text('$total',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900,
                      color: color)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Card individual accident report ─────────────────────────────────────────
class _AccidentReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final String locale;

  const _AccidentReportCard({
    required this.data,
    required this.lang,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final judul   = (data['judul']             ?? '-').toString();
    final status  = (data['status']            ?? '').toString();
    final tingkat = (data['tingkat_keparahan'] ?? '').toString();
    final penyebab = (data['penyebab']         ?? '').toString();
    final fotoUrl  = (data['foto_bukti']       ?? '').toString();
    final isSelesai = status == 'Selesai';

    final tanggal = () {
      final v = data['created_at'];
      if (v == null) return '-';
      final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
      if (dt == null) return '-';
      return DateFormat('dd/MM/yyyy', locale).format(dt);
    }();

    String location = '';
    if      (data['area']    != null) location = (data['area']    as Map)['nama_area']    ?? '';
    else if (data['subunit'] != null) location = (data['subunit'] as Map)['nama_subunit'] ?? '';
    else if (data['unit']    != null) location = (data['unit']    as Map)['nama_unit']    ?? '';
    else if (data['lokasi']  != null) location = (data['lokasi']  as Map)['nama_lokasi']  ?? '';

    final statusColor = isSelesai ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg    = isSelesai ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusText  = isSelesai
        ? (lang == 'ID' ? 'Selesai' : lang == 'ZH' ? '已完成' : 'Resolved')
        : status;

    Color sevColor;
    final tl = tingkat.toLowerCase();
    if      (tl.contains('berat')    || tl.contains('heavy'))  sevColor = _AC.red;
    else if (tl.contains('menengah') || tl.contains('medium')) sevColor = _AC.amber;
    else                                                         sevColor = _AC.green;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sevColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(
            color: sevColor.withOpacity(0.1),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Foto
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: sevColor.withOpacity(0.3), width: 1.5)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.5),
                child: fotoUrl.isNotEmpty
                    ? Image.network(fotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported, color: Colors.grey))
                    : Container(
                        color: const Color(0xFFF8FAFC),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Colors.grey, size: 28)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Judul + severity badge
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(judul,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: _AC.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                if (tingkat.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sevColor, width: 1)),
                    child: Text(tingkat, style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: sevColor)),
                  ),
              ]),
              const SizedBox(height: 4),
              // Lokasi
              if (location.isNotEmpty)
                Row(children: [
                  const Icon(Icons.place_rounded, size: 11,
                      color: Color(0xFF94A3B8)),
                  const SizedBox(width: 3),
                  Expanded(child: Text(location,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF475569)),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              const SizedBox(height: 4),
              // Tanggal + status
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 10,
                    color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text(tanggal, style: const TextStyle(
                    fontSize: 10, color: Color(0xFF64748B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(statusText, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: statusColor)),
                ),
              ]),
            ])),
          ]),
        ),
        // Penyebab footer
        if (penyebab.isNotEmpty && penyebab != '-')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: sevColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14))),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 12, color: sevColor),
              const SizedBox(width: 5),
              Expanded(child: Text(penyebab,
                  style: TextStyle(
                      fontSize: 11,
                      color: sevColor.withOpacity(0.9),
                      fontWeight: FontWeight.w500),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
      ]),
    );
  }
}

// ─── Filter button (lokal, tidak bergantung class lain) ───────────────────────
class _FilterBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  const _FilterBtn({
    required this.label,
    required this.onTap,
    this.icon = Icons.keyboard_arrow_down_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF7DD3FC), width: 1.5),
          boxShadow: [BoxShadow(
              color: _AC.primary.withOpacity(0.10),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: _AC.primary),
              overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(icon, color: _AC.primary, size: 18),
        ]),
      ),
    );
  }
}