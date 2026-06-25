import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/gemini_recurring_service.dart';
import '../../finding/finding_detail_screen.dart';
import '../../home/kts_finding_card.dart';

class _AppColors {
  static const primary = Color(0xFF0EA5E9);
  static const primaryLight = Color(0xFFE0F2FE);
  static const surface = Color(0xFFF0F9FF);
  static const textPrimary = Color(0xFF0C4A6E);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFBDBDBD);
  static const divider = Color(0xFFE0F2FE);
}

class RecurringTopic5R {
  final String topic;
  final String locationArea;
  final int total;
  final String? imageUrl;
  final List<Map<String, dynamic>> findings;

  const RecurringTopic5R({
    required this.topic,
    required this.locationArea,
    required this.total,
    this.imageUrl,
    required this.findings,
  });
}

class FiveRRecurringTab extends StatefulWidget {
  final String lang;
  final String Function(String) getTxt;
  final Widget Function({
    required String label,
    required VoidCallback onTap,
    IconData icon,
    bool isActive,
  }) buildFilterBtn;

  const FiveRRecurringTab({
    super.key,
    required this.lang,
    required this.getTxt,
    required this.buildFilterBtn,
  });

  @override
  State<FiveRRecurringTab> createState() => FiveRRecurringTabState();
}

class FiveRRecurringTabState extends State<FiveRRecurringTab> {
  final _supabase = Supabase.instance.client;

  DateTime _recurringFrom =
      DateTime(DateTime.now().year - 1, DateTime.now().month);
  DateTime _recurringTo = DateTime.now();
  String? _recurringUserId;
  String _recurringUserName = '';

  Future<List<RecurringTopic5R>>? _recurringFuture;

  @override
  void initState() {
    super.initState();
    _recurringFuture = _fetchRecurringData();
  }

  void refresh() {
    setState(() {
      _recurringFuture = _fetchRecurringData();
    });
  }

  Future<List<RecurringTopic5R>> _fetchRecurringData() async {
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
          .neq('jenis_temuan', 'KTS Production')
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
        isKts: false,
        fromDate: _recurringFrom,
        toDate: _recurringTo,
        filterUserId: _recurringUserId,
      );

      return groups
          .map((g) => RecurringTopic5R(
                topic: g.topic,
                locationArea: g.locationArea,
                total: g.total,
                imageUrl: g.imageUrl,
                findings: g.findings,
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching Recurring: $e');
      return [];
    }
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
      // FILTER BAR
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Expanded(
              child: widget.buildFilterBtn(
            label: periodLabel,
            onTap: _showPeriodPicker,
            icon: Icons.calendar_month_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: widget.buildFilterBtn(
            label: _recurringUserName.isEmpty
                ? widget.getTxt('semua_grup')
                : _recurringUserName,
            onTap: _showUserPicker,
          )),
        ]),
      ),

      // SECTION LABEL
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.getTxt('topik'),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.textPrimary)),
        ),
      ),
      const Divider(height: 1, color: _AppColors.divider),

      // LIST
      Expanded(
          child: FutureBuilder<List<RecurringTopic5R>>(
        future: _recurringFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildRecurringShimmer();
          }
          final topics = snapshot.data ?? [];
          if (topics.isEmpty) {
            final name = _recurringUserName.isEmpty ? '' : _recurringUserName;
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        color: _AppColors.primaryLight,
                        shape: BoxShape.circle),
                    child: Icon(Icons.search_off_rounded,
                        size: 36,
                        color: _AppColors.primary.withOpacity(0.5))),
                const SizedBox(height: 16),
                Text(
                    name.isEmpty
                        ? widget.getTxt('tidak_ada_data_anggota')
                        : '$name ${widget.getTxt('belum_memiliki_temuan')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        color: _AppColors.textSecondary,
                        height: 1.5)),
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

  // TOPIC CARD
  Widget _buildRecurringTopicCard(RecurringTopic5R topic) {
    return GestureDetector(
      onTap: () => _showRecurringDetail(topic),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _AppColors.primaryLight, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: _AppColors.primary.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80,
              height: 80,
              color: _AppColors.primaryLight,
              child: topic.imageUrl != null && topic.imageUrl!.isNotEmpty
                  ? Image.network(topic.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: _AppColors.textMuted))
                  : const Icon(Icons.image_outlined,
                      color: _AppColors.textMuted, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Builder(builder: (context) {
              final isKts = topic.findings.isNotEmpty &&
                  (topic.findings.first['jenis_temuan'] ?? '') ==
                      'KTS Production';
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.topic,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(
                        isKts
                            ? Icons.tag_rounded
                            : Icons.location_on_rounded,
                        size: 13,
                        color: isKts
                            ? const Color(0xFFD97706)
                            : _AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                          child: Text(
                        isKts
                            ? '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}'
                            : topic.locationArea,
                        style: TextStyle(
                            fontSize: 12,
                            color: isKts
                                ? const Color(0xFFD97706)
                                : _AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ]);
            }),
          )),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _AppColors.primary.withOpacity(0.3))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.getTxt('total'),
                  style: const TextStyle(
                      fontSize: 9, color: _AppColors.textSecondary)),
              Text('${topic.total}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _AppColors.primary)),
            ]),
          ),
        ]),
      ),
    );
  }

  // DETAIL BOTTOM SHEET
  void _showRecurringDetail(RecurringTopic5R topic) {
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(
                    child: Builder(builder: (context) {
                  final isKts = topic.findings.isNotEmpty &&
                      (topic.findings.first['jenis_temuan'] ?? '') ==
                          'KTS Production';
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(topic.topic,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(
                              isKts
                                  ? Icons.tag_rounded
                                  : Icons.location_on_rounded,
                              size: 13,
                              color: isKts
                                  ? const Color(0xFFD97706)
                                  : _AppColors.primary),
                          const SizedBox(width: 3),
                          Flexible(
                              child: Text(
                            isKts
                                ? '${widget.lang == 'ID' ? 'No. Order' : widget.lang == 'ZH' ? '订单号' : 'Order No.'}: ${topic.locationArea}'
                                : '${widget.getTxt('di_sekitar')} ${topic.locationArea}',
                            style: TextStyle(
                                fontSize: 12,
                                color: isKts
                                    ? const Color(0xFFD97706)
                                    : _AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ]),
                      ]);
                })),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                      '${widget.getTxt('total')}: ${topic.total}',
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
                      '${widget.getTxt('daftar_temuan')} (${topic.total})',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.textPrimary))),
            ),
            Expanded(
                child: ListView.separated(
              controller: scrollCtrl,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: topic.findings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _buildRecurringFindingCard(topic.findings[i]),
            )),
          ]),
        ),
      ),
    );
  }

  // FINDING CARD
  Widget _buildRecurringFindingCard(Map<String, dynamic> data) {
    final isKts = (data['jenis_temuan'] ?? '') == 'KTS Production';

    if (isKts) {
      return KtsFindingCard(
        data: data,
        lang: widget.lang,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => FindingDetailScreen(
                    initialData: data, lang: widget.lang))),
      );
    }

    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final title = (data['judul_temuan'] ?? '-').toString();
    final status = (data['status_temuan'] ?? '').toString();
    final s = status.toLowerCase();
    final isFinished =
        ['selesai', 'done', 'completed', 'closed'].any((e) => s.contains(e));
    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final isKtsCard = (data['jenis_temuan'] ?? '') == 'KTS Production';

    final tanggal = () {
      final v = data['created_at'];
      if (v == null) return '-';
      final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
      if (dt == null) return '-';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }();

    String location = '';
    if (data['area'] != null) location = data['area']['nama_area'] ?? '';
    else if (data['subunit'] != null) location = data['subunit']['nama_subunit'] ?? '';
    else if (data['unit'] != null) location = data['unit']['nama_unit'] ?? '';
    else if (data['lokasi'] != null) location = data['lokasi']['nama_lokasi'] ?? '';

    final statusColor =
        isFinished ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg =
        isFinished ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusIcon = isFinished
        ? Icons.check_circle_rounded
        : Icons.pending_actions_rounded;
    final statusText = isFinished
        ? (widget.lang == 'ID'
            ? 'Selesai'
            : widget.lang == 'ZH'
                ? '已完成'
                : 'Finished')
        : (widget.lang == 'ID'
            ? 'Belum Selesai'
            : widget.lang == 'ZH'
                ? '未完成'
                : 'Unfinished');

    final List<Widget> badges = [];
    if (isPro)
      badges.add(_buildBadge('PROFESIONAL',
          const Color.fromARGB(255, 255, 244, 45), Colors.black));
    if (isVisitor)
      badges.add(
          _buildBadge('VISITOR', const Color(0xFF3B82F6), Colors.white));
    if (isEksekutif)
      badges.add(
          _buildBadge('EKSEKUTIF', const Color(0xFFEF4444), Colors.white));

    final Color borderColor =
        isKtsCard ? const Color(0xFFFDE68A) : const Color(0xFF38BDF8);

    Widget? timeIndicator;
    if (isFinished) {
      final penyelesaianData = data['penyelesaian'] as Map<String, dynamic>?;
      String completionDateText = '-';
      if (penyelesaianData != null) {
        final v = penyelesaianData['tanggal_selesai'];
        if (v != null) {
          final dt = DateTime.tryParse(v.toString());
          if (dt != null)
            completionDateText =
                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        }
      }
      timeIndicator = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: statusBg,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18))),
        child: Row(children: [
          Icon(Icons.event_available_rounded, size: 13, color: statusColor),
          const SizedBox(width: 5),
          Text(
              '${widget.lang == 'ID' ? 'Selesai pada' : widget.lang == 'ZH' ? '完成于' : 'Completed on'} $completionDateText',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor)),
        ]),
      );
    } else {
      final deadline =
          DateTime.tryParse(data['target_waktu_selesai']?.toString() ?? '');
      if (deadline != null) {
        final now = DateTime.now();
        final difference = deadline.difference(now);
        Color timeColor;
        String timeText;
        IconData timeIcon;
        if (difference.isNegative) {
          timeColor = Colors.red.shade700;
          timeIcon = Icons.warning_amber_rounded;
          final abs = difference.abs();
          if (abs.inDays > 0) {
            timeText = widget.lang == 'ID'
                ? '${abs.inDays} hari terlewat'
                : widget.lang == 'ZH'
                    ? '已超过 ${abs.inDays} 天'
                    : '${abs.inDays} days overdue';
          } else if (abs.inHours > 0) {
            timeText = widget.lang == 'ID'
                ? '${abs.inHours} jam terlewat'
                : widget.lang == 'ZH'
                    ? '已超过 ${abs.inHours} 小时'
                    : '${abs.inHours} hours overdue';
          } else {
            timeText = widget.lang == 'ID'
                ? '${abs.inMinutes} menit terlewat'
                : widget.lang == 'ZH'
                    ? '已超过 ${abs.inMinutes} 分钟'
                    : '${abs.inMinutes} minutes overdue';
          }
        } else {
          final sisaHari = difference.inDays;
          if (sisaHari == 0) {
            timeColor = Colors.orange.shade800;
            timeIcon = Icons.today_rounded;
            timeText = widget.lang == 'ID'
                ? 'Deadline hari ini'
                : widget.lang == 'ZH'
                    ? '今天截止'
                    : 'Due today';
          } else {
            timeColor = Colors.green.shade800;
            timeIcon = Icons.timer_outlined;
            timeText = widget.lang == 'ID'
                ? '$sisaHari hari tersisa'
                : widget.lang == 'ZH'
                    ? '还剩 $sisaHari 天'
                    : '$sisaHari days remaining';
          }
        }
        timeIndicator = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: timeColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18))),
          child: Row(children: [
            Icon(timeIcon, size: 13, color: timeColor),
            const SizedBox(width: 5),
            Text(timeText,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: timeColor)),
          ]),
        );
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  FindingDetailScreen(initialData: data, lang: widget.lang))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: borderColor.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.12),
                            width: 1.5)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11.5),
                      child: Container(
                        color: const Color(0xFFF8FAFC),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.grey))
                            : const Icon(Icons.image_outlined,
                                color: Colors.grey, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Text(title,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.3,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 6),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8)
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFF38BDF8),
                                          width: 1.1)),
                                  child: const Text('5R',
                                      style: TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9))),
                              if (poin > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFFF6B3D)
                                          ]),
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons
                                                .local_fire_department_rounded,
                                            size: 10,
                                            color: Colors.white),
                                        const SizedBox(width: 2),
                                        Text('$poin',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 10)),
                                      ]),
                                ),
                              ],
                            ]),
                        const SizedBox(height: 5),
                        if (badges.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Wrap(
                                  spacing: 4,
                                  runSpacing: 3,
                                  children: badges)),
                        Row(children: [
                          const Icon(Icons.place_rounded,
                              size: 12, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(location,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF475569)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text(tanggal,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(16)),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      size: 11, color: statusColor),
                                  const SizedBox(width: 3),
                                  Text(statusText,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor)),
                                ]),
                          ),
                        ]),
                      ])),
                ]),
          ),
          if (timeIndicator != null) timeIndicator,
        ]),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(text,
          style: TextStyle(
              color: textColor,
              fontSize: 8,
              fontWeight: FontWeight.w900)),
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
          height: 80,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(14))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmerBox(height: 14, width: double.infinity),
                const SizedBox(height: 6),
                _shimmerBox(height: 12, width: 120),
              ],
            )),
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerBox({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
    );
  }

  // FILTER DIALOG
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _AppColors.primaryLight, width: 1.5)),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.date_range_rounded,
                              color: _AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(widget.getTxt('pilih_periode'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: _AppColors.textPrimary))),
                          IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => Navigator.pop(ctx),
                              padding: EdgeInsets.zero),
                        ]),
                        const SizedBox(height: 16),
                        Text(widget.getTxt('dari'),
                            style: const TextStyle(
                                fontSize: 12,
                                color: _AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _buildYearMonthPicker(tempFrom, locale,
                            (d) => setSt(() => tempFrom = d)),
                        const SizedBox(height: 14),
                        Text(widget.getTxt('sampai'),
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
                                _recurringFuture = _fetchRecurringData();
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12))),
                            child: Text(widget.getTxt('terapkan')),
                          ),
                        ),
                      ]),
                ),
              )),
    );
  }

  Widget _buildYearMonthPicker(
      DateTime current, String locale, ValueChanged<DateTime> onChange) {
    final months = List.generate(
        12,
        (i) =>
            DateFormat.MMM(locale).format(DateTime(2000, i + 1)));
    final years =
        List.generate(5, (i) => DateTime.now().year - 2 + i);
    return Row(children: [
      Expanded(
        flex: 3,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AppColors.primaryLight)),
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
                  (i) => DropdownMenuItem(
                      value: i, child: Text(months[i]))),
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
              border: Border.all(color: _AppColors.primaryLight)),
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
                  .map((y) => DropdownMenuItem(
                      value: y, child: Text('$y')))
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

  void _showUserPicker() async {
    try {
      final response = await _supabase
          .from('User')
          .select(
              'id_user, nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .order('nama');
      final users = List<Map<String, dynamic>>.from(response);
      final allItem = {
        'id_user': null,
        'nama': widget.getTxt('pilih_penemu'),
        'gambar_user': null,
        'jabatan': null
      };
      final items = [allItem, ...users];
      if (!mounted) return;

      final ctrl = TextEditingController();
      List<Map<String, dynamic>> filtered = List.from(items);

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height * 0.7),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _AppColors.primaryLight, width: 1.5)),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.fromLTRB(16, 14, 8, 12),
                      decoration: const BoxDecoration(
                          color: _AppColors.primaryLight,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20))),
                      child: Row(children: [
                        const Icon(Icons.person_search_rounded,
                            color: _AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                widget.getTxt('pilih_penemu'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _AppColors.textPrimary))),
                        IconButton(
                            icon: const Icon(Icons.close,
                                size: 18,
                                color: _AppColors.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero),
                      ]),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: StatefulBuilder(
                        builder: (_, setInner) => TextField(
                          controller: ctrl,
                          onChanged: (q) {
                            setInner(() {
                              filtered = items
                                  .where((e) => (e['nama'] as String)
                                      .toLowerCase()
                                      .contains(q.toLowerCase()))
                                  .toList();
                            });
                            setSt(() {});
                          },
                          decoration: InputDecoration(
                            hintText: widget.getTxt('cari'),
                            hintStyle: const TextStyle(
                                fontSize: 13,
                                color: _AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search,
                                color: _AppColors.primary, size: 18),
                            filled: true,
                            fillColor: _AppColors.surface,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: _AppColors.divider)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: _AppColors.divider)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: _AppColors.primary,
                                    width: 1.5)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 14, bottom: 4),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              '${filtered.length} ${widget.lang == 'ID' ? 'penemu' : widget.lang == 'ZH' ? '发现者' : 'finders'}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _AppColors.textSecondary))),
                    ),
                    Flexible(
                        child: StatefulBuilder(
                      builder: (_, __) => ListView.builder(
                        padding:
                            const EdgeInsets.only(bottom: 12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final name = item['nama'] as String;
                          final id = item['id_user']?.toString();
                          final avatarUrl =
                              item['gambar_user'] as String?;
                          final role = (item['jabatan']
                                  as Map<String, dynamic>?)?[
                              'nama_jabatan'] as String?;
                          final isSelected = id ==
                                  _recurringUserId ||
                              (id == null && _recurringUserId == null);
                          final isAll = id == null;

                          return InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _recurringUserId = id;
                                _recurringUserName = isAll
                                    ? (widget.lang == 'ID'
                                        ? 'Semua Penemu'
                                        : widget.lang == 'ZH'
                                            ? '所有发现者'
                                            : 'All Finders')
                                    : name;
                                _recurringFuture =
                                    _fetchRecurringData();
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                  color: isSelected
                                      ? _AppColors.primaryLight
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected
                                          ? _AppColors.primary
                                          : _AppColors.divider,
                                      width: isSelected ? 1.5 : 1)),
                              child: Row(children: [
                                if (isAll)
                                  Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          color: isSelected
                                              ? _AppColors.primary
                                              : _AppColors.surface,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: _AppColors
                                                  .primaryLight)),
                                      child: Icon(
                                          Icons.group_rounded,
                                          color: isSelected
                                              ? Colors.white
                                              : _AppColors.primary,
                                          size: 20))
                                else if (avatarUrl != null &&
                                    avatarUrl.isNotEmpty)
                                  CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          NetworkImage(avatarUrl),
                                      onBackgroundImageError:
                                          (_, __) {},
                                      backgroundColor:
                                          _AppColors.primaryLight)
                                else
                                  CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected
                                          ? _AppColors.primary
                                          : _AppColors.primaryLight,
                                      child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 15,
                                              color: isSelected
                                                  ? Colors.white
                                                  : _AppColors
                                                      .primary))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          isAll
                                              ? (widget.lang == 'ID'
                                                  ? 'Semua Penemu'
                                                  : widget.lang ==
                                                          'ZH'
                                                      ? '所有发现者'
                                                      : 'All Finders')
                                              : name,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? _AppColors.primary
                                                  : _AppColors
                                                      .textPrimary)),
                                      if (role != null &&
                                          role.isNotEmpty)
                                        Text(role,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: _AppColors
                                                    .textSecondary)),
                                    ])),
                                if (isSelected)
                                  const Icon(
                                      Icons.check_circle_rounded,
                                      color: _AppColors.primary,
                                      size: 18),
                              ]),
                            ),
                          );
                        },
                      ),
                    )),
                  ]),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
  }
}