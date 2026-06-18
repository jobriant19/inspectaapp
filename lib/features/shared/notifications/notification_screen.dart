import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../audit/audit_evidence_camera_screen.dart';
import '../../user/finding/finding_detail_screen.dart';
import '../../user/home/finding_card.dart';

class NotificationScreen extends StatefulWidget {
  final String lang;
  final List<dynamic>? initialFindings;
  final List<dynamic>? initialActivityLogs;

  const NotificationScreen({
    super.key,
    required this.lang,
    this.initialFindings,
    this.initialActivityLogs,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'title': 'Notifications',
      'tab_findings': 'Findings',
      'tab_activity': 'Activity',
      'tab_audit': 'Audit',
      'empty_findings': 'No assigned findings',
      'empty_findings_sub': 'Findings assigned to you will appear here.',
      'empty_activity': 'No activity yet',
      'empty_activity_sub': 'Your point history will appear here.',
      'empty_audit': 'No audit notifications',
      'empty_audit_sub': 'Audit results for your locations will appear here.',
    },
    'ID': {
      'title': 'Notifikasi',
      'tab_findings': 'Temuan',
      'tab_activity': 'Aktivitas',
      'tab_audit': 'Audit',
      'empty_findings': 'Tidak ada temuan ditugaskan',
      'empty_findings_sub': 'Temuan yang ditugaskan ke Anda akan muncul di sini.',
      'empty_activity': 'Belum ada aktivitas',
      'empty_activity_sub': 'Riwayat poin Anda akan muncul di sini.',
      'empty_audit': 'Belum ada notif audit',
      'empty_audit_sub': 'Hasil audit untuk lokasi Anda akan muncul di sini.',
    },
    'ZH': {
      'title': '通知',
      'tab_findings': '发现',
      'tab_activity': '活动',
      'tab_audit': '审计',
      'empty_findings': '没有分配的发现',
      'empty_findings_sub': '分配给您的发现将显示在此处。',
      'empty_activity': '暂无活动',
      'empty_activity_sub': '您的积分历史将显示在此处。',
      'empty_audit': '暂无审计通知',
      'empty_audit_sub': '您管理位置的审计结果将显示在此处。',
    },
  };

  RealtimeChannel? _findingsChannel;
  RealtimeChannel? _logsChannel;

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    Future<String?> getFcmToken() async {
      try {
        final data = await Supabase.instance.client
            .from('User')
            .select('fcm_token')
            .eq('id_user', userId)
            .maybeSingle();
        final token = data?['fcm_token']?.toString();
        return (token != null && token.trim().isNotEmpty) ? token.trim() : null;
      } catch (_) { return null; }
    }

    _findingsChannel = Supabase.instance.client
        .channel('notif_findings_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'temuan',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_penanggung_jawab',
            value: userId,
          ),
          callback: (payload) async {
            if (!mounted) return;
            final newRow = payload.newRecord;
            final judul = newRow['judul_temuan']?.toString() ?? 'Temuan baru';
            final notifTitle = widget.lang == 'EN'
                ? '📋 New Finding Assigned'
                : widget.lang == 'ZH' ? '📋 新发现已分配' : '📋 Temuan Baru Ditugaskan';
            await PushNotificationService.instance.showLocalNotification(
                title: notifTitle, body: judul, payload: 'findings');
            final fcmToken = await getFcmToken();
            if (fcmToken != null) {
              await NotificationService.sendFcmToToken(
                  fcmToken: fcmToken, title: notifTitle, body: judul, route: 'findings');
            }
          },
        )
        .subscribe();

    _logsChannel = Supabase.instance.client
        .channel('notif_logs_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'log_poin',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_user',
            value: userId,
          ),
          callback: (payload) async {
            if (!mounted) return;
            final newRow = payload.newRecord;
            final tipe = newRow['tipe_aktivitas']?.toString() ?? '';
            final poin = (newRow['poin'] as num?)?.toInt() ?? 0;
            final deskripsi = newRow['deskripsi']?.toString() ?? '';
            if (tipe != 'terima_poin_berbagi' && tipe != 'bonus_berbagi') return;

            String notifTitle;
            String notifBody;
            if (tipe == 'terima_poin_berbagi') {
              notifTitle = widget.lang == 'EN' ? '🎁 You received shared points!'
                  : widget.lang == 'ZH' ? '🎁 您收到了分享积分！' : '🎁 Kamu menerima poin berbagi!';
              notifBody = '+$poin ${widget.lang == 'EN' ? 'points' : 'poin'}: $deskripsi';
            } else {
              notifTitle = widget.lang == 'EN' ? '🔥 Sharing Bonus Received!'
                  : widget.lang == 'ZH' ? '🔥 分享奖励已获得！' : '🔥 Bonus Berbagi Diterima!';
              notifBody = '+$poin ${widget.lang == 'EN' ? 'points' : 'poin'}: $deskripsi';
            }
            await PushNotificationService.instance.showLocalNotification(
                title: notifTitle, body: notifBody, payload: 'activity');
            final fcmToken = await getFcmToken();
            if (fcmToken != null) {
              await NotificationService.sendFcmToToken(
                  fcmToken: fcmToken, title: notifTitle, body: notifBody, route: 'activity');
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_findingsChannel != null) Supabase.instance.client.removeChannel(_findingsChannel!);
    if (_logsChannel != null) Supabase.instance.client.removeChannel(_logsChannel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        body: Column(
          children: [
            // ── HEADER ──
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  size: 18, color: Color(0xFF1D72F3)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _t('title'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1D72F3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── 3 Tab dalam satu baris rapi ──
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        tabAlignment: TabAlignment.fill,
                        indicator: BoxDecoration(
                          color: const Color(0xFF0EA5E9),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF0EA5E9),
                        labelStyle: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w500),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.assignment_ind_outlined, size: 13),
                                const SizedBox(width: 4),
                                Flexible(child: Text(_t('tab_findings'),
                                    overflow: TextOverflow.ellipsis, maxLines: 1)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history_rounded, size: 13),
                                const SizedBox(width: 4),
                                Flexible(child: Text(_t('tab_activity'),
                                    overflow: TextOverflow.ellipsis, maxLines: 1)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fact_check_outlined, size: 13),
                                const SizedBox(width: 4),
                                Flexible(child: Text(_t('tab_audit'),
                                    overflow: TextOverflow.ellipsis, maxLines: 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── KONTEN ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AssignedFindingsTab(
                    lang: widget.lang,
                    initialData: widget.initialFindings != null
                        ? List<Map<String, dynamic>>.from(widget.initialFindings!)
                        : null,
                    t: _t,
                  ),
                  _ActivityLogTab(
                    lang: widget.lang,
                    initialLogs: widget.initialActivityLogs != null
                        ? List<Map<String, dynamic>>.from(widget.initialActivityLogs!)
                        : null,
                    t: _t,
                  ),
                  _AuditNotifRedirectTab(lang: widget.lang, t: _t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TAB AUDIT NOTIF
// ══════════════════════════════════════════════
class _AuditNotifTab extends StatefulWidget {
  final String lang;
  final String Function(String) t;

  const _AuditNotifTab({required this.lang, required this.t});

  @override
  State<_AuditNotifTab> createState() => _AuditNotifTabState();
}

class _AuditNotifTabState extends State<_AuditNotifTab>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  // Apakah user ini adalah PIC dari lokasi/unit/subunit/area
  // Jika ya → tampilkan hasil audit dari area yang dia PIC-i
  // Jika tidak → tampilkan audit yang dia lakukan (sebagai auditor)
  bool _isPic = false;
  String? _userId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _userId = _supabase.auth.currentUser?.id;
    _fetchAuditNotifs();
  }

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  Future<void> _fetchAuditNotifs() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      // Fetch semua level dimana user ini adalah PIC
      final results = await Future.wait([
        _supabase.from('lokasi').select('id_lokasi').eq('id_pic', _userId!),
        _supabase.from('unit').select('id_unit').eq('id_pic', _userId!),
        _supabase.from('subunit').select('id_subunit').eq('id_pic', _userId!),
        _supabase.from('area').select('id_area').eq('id_pic', _userId!),
      ]);

      final List<Map<String, dynamic>> picRefs = [];
      for (final row in results[0] as List) picRefs.add({'level': 'lokasi', 'id': row['id_lokasi'].toString()});
      for (final row in results[1] as List) picRefs.add({'level': 'unit', 'id': row['id_unit'].toString()});
      for (final row in results[2] as List) picRefs.add({'level': 'subunit', 'id': row['id_subunit'].toString()});
      for (final row in results[3] as List) picRefs.add({'level': 'area', 'id': row['id_area'].toString()});

      _isPic = picRefs.isNotEmpty;

      List<Map<String, dynamic>> auditItems = [];

      if (_isPic) {
        // Fetch audit_result untuk setiap ref yang PIC-i user ini
        for (final ref in picRefs) {
          final rows = await _supabase
              .from('audit_result')
              .select(
                'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
                'catatan_audit, selfie_url, created_at, '
                'Auditor:User!fk_audit_result_auditor(nama, gambar_user)',
              )
              .eq('level_type', ref['level']!)
              .eq('id_ref', ref['id']!)
              .order('created_at', ascending: false)
              .limit(20);

          for (final row in rows as List) {
            final r = Map<String, dynamic>.from(row as Map);
            r['_is_pic_view'] = true; // saya sebagai PIC melihat hasil audit
            r['_level'] = ref['level'];
            auditItems.add(r);
          }
        }
      } else {
        // Fetch audit_result yang user ini lakukan sebagai auditor
        final rows = await _supabase
            .from('audit_result')
            .select(
              'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
              'catatan_audit, selfie_url, created_at',
            )
            .eq('id_auditor', _userId!)
            .order('created_at', ascending: false)
            .limit(50);
        for (final row in rows as List) {
          final r = Map<String, dynamic>.from(row as Map);
          r['_is_pic_view'] = false;
          auditItems.add(r);
        }
      }

      // Sort by created_at desc
      auditItems.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      // Fetch nama lokasi per id_ref
      for (final item in auditItems) {
        final levelType = item['level_type']?.toString() ?? item['_level']?.toString() ?? '';
        final idRef = item['id_ref']?.toString() ?? '';
        if (levelType.isEmpty || idRef.isEmpty) continue;
        try {
          final nameCol = 'nama_$levelType';
          final idCol = 'id_$levelType';
          final nameRow = await _supabase
              .from(levelType)
              .select('$nameCol, id_pic')
              .eq(idCol, idRef)
              .maybeSingle();
          item['_location_name'] = nameRow?[nameCol]?.toString() ?? '-';
        } catch (_) {
          item['_location_name'] = '-';
        }
      }

      // Fetch jawaban No untuk setiap result (untuk tampilkan reply thread)
      for (final item in auditItems) {
        final idResult = item['id_result']?.toString() ?? '';
        if (idResult.isEmpty) continue;
        try {
          final answers = await _supabase
              .from('audit_answer')
              .select(
                'id_answer, jawaban, catatan, gambar_jawaban, '
                'Question:audit_question(pertanyaan, pertanyaan_en, pertanyaan_zh), '
                'Replies:audit_answer_reply(id_reply, catatan_reply, gambar_reply, is_confirmed, created_at, '
                'PIC:User!fk_reply_pic(nama, gambar_user))',
              )
              .eq('id_result', idResult)
              .eq('jawaban', false);
          item['_no_answers'] = List<Map<String, dynamic>>.from(answers);
        } catch (_) {
          item['_no_answers'] = [];
        }
      }

      if (mounted) {
        setState(() {
          _items = auditItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch audit notifs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _scoreColor(double? score) {
    if (score == null) return const Color(0xFF64748B);
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays < 1) return _t('Today', 'Hari ini', '今天');
    if (diff.inDays < 7) return '${diff.inDays} ${_t('days ago', 'hari lalu', '天前')}';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _questionText(Map<String, dynamic> q) {
    final qData = q['Question'] as Map<String, dynamic>?;
    if (qData == null) return '-';
    if (widget.lang == 'EN') return qData['pertanyaan_en']?.toString() ?? qData['pertanyaan']?.toString() ?? '-';
    if (widget.lang == 'ZH') return qData['pertanyaan_zh']?.toString() ?? qData['pertanyaan']?.toString() ?? '-';
    return qData['pertanyaan']?.toString() ?? '-';
  }

  Future<void> _showReplyDialog(Map<String, dynamic> answer, String idResult) async {
    final noteCtrl = TextEditingController();
    String? photoUrl;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t('Reply to Finding', 'Balas Temuan', '回复发现'),
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 6),
                Text(
                  _questionText(answer),
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Upload foto bukti perbaikan
                GestureDetector(
                  onTap: () async {
                    // Gunakan AuditEvidenceCameraScreen atau image picker sesuai kebutuhan
                    // Di sini menggunakan placeholder — sambungkan ke camera screen Anda
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35)),
                    ),
                    child: photoUrl == null
                        ? Column(children: [
                            const Icon(Icons.add_a_photo_rounded,
                                color: Color(0xFF6366F1), size: 22),
                            const SizedBox(height: 4),
                            Text(_t('Upload Evidence Photo', 'Upload Foto Bukti Perbaikan', '上传修复证据照片'),
                                style: GoogleFonts.poppins(fontSize: 12,
                                    fontWeight: FontWeight.w600, color: const Color(0xFF6366F1))),
                          ])
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(photoUrl, height: 120, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _t('Describe the corrective action taken…',
                        'Jelaskan tindakan perbaikan yang dilakukan…', '描述已采取的纠正措施…'),
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : () async {
                      if (noteCtrl.text.trim().isEmpty) return;
                      setSt(() => submitting = true);
                      try {
                        await _supabase.from('audit_answer_reply').insert({
                          'id_answer': answer['id_answer'],
                          'id_pic': _userId,
                          'catatan_reply': noteCtrl.text.trim(),
                          'gambar_reply': photoUrl,
                          'is_confirmed': false,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchAuditNotifs();
                      } catch (e) {
                        setSt(() => submitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: const Color(0xFFEF4444),
                          ));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: submitting
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_t('Send Reply', 'Kirim Balasan', '发送回复'),
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

  Future<void> _confirmReply(String idReply) async {
    try {
      await _supabase
          .from('audit_answer_reply')
          .update({'is_confirmed': true})
          .eq('id_reply', idReply);
      _fetchAuditNotifs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 120,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.08),
              ),
              child: Icon(Icons.fact_check_outlined,
                  size: 36, color: const Color(0xFF6366F1).withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(widget.t('empty_audit'),
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A))),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(widget.t('empty_audit_sub'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAuditNotifs,
      color: const Color(0xFF6366F1),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildAuditCard(_items[index]),
      ),
    );
  }

  Widget _buildAuditCard(Map<String, dynamic> item) {
    final score = double.tryParse(item['nilai_audit']?.toString() ?? '');
    final scoreColor = _scoreColor(score);
    final isPicView = item['_is_pic_view'] == true;
    final locationName = item['_location_name']?.toString() ?? '-';
    final levelType = item['level_type']?.toString() ?? '';
    final date = _formatDate(item['tanggal_audit']);
    final auditorData = item['Auditor'] as Map<String, dynamic>?;
    final auditorName = auditorData?['nama']?.toString() ?? '-';
    final noAnswers = (item['_no_answers'] as List<Map<String, dynamic>>?) ?? [];
    final idResult = item['id_result']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      score != null ? '${score.toStringAsFixed(0)}%' : '-',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w800, color: scoreColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            levelType.toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700,
                                color: const Color(0xFF6366F1)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            locationName,
                            style: GoogleFonts.poppins(fontSize: 13,
                                fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                        isPicView
                            ? '${_t('Audited by', 'Diaudit oleh', '审计员')}: $auditorName'
                            : '${_t('You audited', 'Anda mengaudit', '您审计了')}: $locationName',
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        date,
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Jawaban No + Thread Reply ──
          if (noAnswers.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFEF4444)),
                const SizedBox(width: 5),
                Text(
                  '${noAnswers.length} ${_t('finding(s) need action', 'temuan perlu tindakan', '个发现需要处理')}',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444)),
                ),
              ]),
            ),
            ...noAnswers.map((ans) => _buildAnswerThread(ans, isPicView, idResult)),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAnswerThread(Map<String, dynamic> ans, bool isPicView, String idResult) {
    final replies = (ans['Replies'] as List?)
        ?.map((r) => Map<String, dynamic>.from(r as Map))
        .toList() ?? [];
    final hasReply = replies.isNotEmpty;
    final latestReply = hasReply ? replies.last : null;
    final isConfirmed = latestReply?['is_confirmed'] == true;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pertanyaan
          Text(
            _questionText(ans),
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                color: const Color(0xFF1E3A8A)),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
          // Catatan auditor
          if ((ans['catatan']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ans['catatan'].toString(),
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ],
          // Foto bukti auditor
          if ((ans['gambar_jawaban']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ans['gambar_jawaban'].toString(),
                height: 100, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],

          // ── Replies dari PIC ──
          if (hasReply) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...replies.map((reply) {
              final picData = reply['PIC'] as Map<String, dynamic>?;
              final picName = picData?['nama']?.toString() ?? '-';
              final confirmed = reply['is_confirmed'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: confirmed
                      ? const Color(0xFF10B981).withOpacity(0.07)
                      : const Color(0xFF6366F1).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: confirmed
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFF6366F1).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        confirmed ? Icons.verified_rounded : Icons.reply_rounded,
                        size: 13,
                        color: confirmed ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '$picName ${confirmed ? '✓ ${_t('Confirmed', 'Dikonfirmasi', '已确认')}' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: confirmed ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ]),
                    if ((reply['catatan_reply']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reply['catatan_reply'].toString(),
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF1E3A8A)),
                      ),
                    ],
                    if ((reply['gambar_reply']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          reply['gambar_reply'].toString(),
                          height: 80, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    // Tombol konfirmasi (hanya untuk auditor yang melihat, reply belum confirmed)
                    if (!isPicView && !confirmed) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmReply(reply['id_reply'].toString()),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                          label: Text(_t('Confirm Fixed', 'Konfirmasi Sudah Diperbaiki', '确认已修复'),
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],

          // ── Tombol Reply (hanya untuk PIC, jika belum ada reply atau belum confirmed) ──
          if (isPicView && (!hasReply || (latestReply != null && !isConfirmed))) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showReplyDialog(ans, idResult),
                icon: const Icon(Icons.reply_rounded, size: 14),
                label: Text(
                  hasReply
                      ? _t('Update Reply', 'Perbarui Balasan', '更新回复')
                      : _t('Reply', 'Balas', '回复'),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TAB AUDIT — inline, as auditor + as PIC, warna biru
// ══════════════════════════════════════════════
class _AuditNotifRedirectTab extends StatefulWidget {
  final String lang;
  final String Function(String) t;

  const _AuditNotifRedirectTab({required this.lang, required this.t});

  @override
  State<_AuditNotifRedirectTab> createState() => _AuditNotifRedirectTabState();
}

class _AuditNotifRedirectTabState extends State<_AuditNotifRedirectTab>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  DateTime _filterFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _filterTo = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  static const _blue = Color(0xFF1D4ED8);
  static const _blueLt = Color(0xFFEFF6FF);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  Future<void> _fetch() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      // ── 1. Fetch sebagai AUDITOR ──────────────────────────────────────
      final auditorRows = await _supabase
          .from('audit_result')
          .select(
            'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
            'nilai_final, is_finalized, catatan_audit, created_at',
          )
          .eq('id_auditor', userId)
          .gte('created_at', _filterFrom.toIso8601String())
          .lte('created_at', _filterTo.toIso8601String())
          .order('created_at', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> items = [];
      for (final row in auditorRows as List) {
        final r = Map<String, dynamic>.from(row as Map);
        r['_role'] = 'auditor';
        items.add(r);
      }

      // ── 2. Fetch sebagai PIC ──────────────────────────────────────────
      final picLevels = await Future.wait([
        _supabase.from('lokasi').select('id_lokasi').eq('id_pic', userId),
        _supabase.from('unit').select('id_unit').eq('id_pic', userId),
        _supabase.from('subunit').select('id_subunit').eq('id_pic', userId),
        _supabase.from('area').select('id_area').eq('id_pic', userId),
      ]);

      final List<Map<String, String>> picRefs = [];
      for (final r in picLevels[0] as List) picRefs.add({'level': 'lokasi', 'id': r['id_lokasi'].toString()});
      for (final r in picLevels[1] as List) picRefs.add({'level': 'unit', 'id': r['id_unit'].toString()});
      for (final r in picLevels[2] as List) picRefs.add({'level': 'subunit', 'id': r['id_subunit'].toString()});
      for (final r in picLevels[3] as List) picRefs.add({'level': 'area', 'id': r['id_area'].toString()});

      for (final ref in picRefs) {
        final picRows = await _supabase
            .from('audit_result')
            .select(
              'id_result, level_type, id_ref, tanggal_audit, nilai_audit, '
              'nilai_final, is_finalized, catatan_audit, created_at, '
              'Auditor:User!fk_audit_result_auditor(nama)',
            )
            .eq('level_type', ref['level']!)
            .eq('id_ref', ref['id']!)
            .gte('created_at', _filterFrom.toIso8601String())
            .lte('created_at', _filterTo.toIso8601String())
            .order('created_at', ascending: false)
            .limit(30);

        for (final row in picRows as List) {
          final r = Map<String, dynamic>.from(row as Map);
          r['_role'] = 'pic';
          r['_level'] = ref['level'];
          // Hindari duplikat jika user adalah auditor sekaligus PIC lokasi sendiri
          final alreadyExists = items.any((i) => i['id_result'] == r['id_result']);
          if (!alreadyExists) items.add(r);
        }
      }

      // Sort by created_at desc
      items.sort((a, b) {
        final at = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final bt = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return bt.compareTo(at);
      });

      // ── 3. Enrich setiap item ─────────────────────────────────────────
      for (final item in items) {
        final levelType = item['level_type']?.toString() ?? item['_level']?.toString() ?? '';
        final idRef = item['id_ref']?.toString() ?? '';
        final idResult = item['id_result']?.toString() ?? '';
        final role = item['_role']?.toString() ?? 'auditor';

        // Nama lokasi
        if (levelType.isNotEmpty && idRef.isNotEmpty) {
          try {
            final nameCol = 'nama_$levelType';
            final idCol = 'id_$levelType';
            final nameRow = await _supabase
                .from(levelType)
                .select(nameCol)
                .eq(idCol, idRef)
                .maybeSingle();
            item['_location_name'] = nameRow?[nameCol]?.toString() ?? '-';
          } catch (_) {
            item['_location_name'] = '-';
          }
        } else {
          item['_location_name'] = '-';
        }

        final locName = item['_location_name']?.toString() ?? '';

        // Poin dari log_poin (hanya untuk auditor)
        if (role == 'auditor') {
          try {
            final createdAt = item['created_at']?.toString() ?? '';
            final auditDt = DateTime.tryParse(createdAt);

            final logs = await _supabase
                .from('log_poin')
                .select('poin, deskripsi, tipe_aktivitas, created_at')
                .eq('id_user', userId)
                .eq('tipe_aktivitas', 'audit_submit')
                .order('created_at', ascending: false)
                .limit(200);

            // ── PERUBAHAN: tambahkan batas atas window waktu (±15 menit dari
            // created_at audit ini). AUDIT_SUBMIT diberikan serentak saat
            // submit, jadi window ketat ini mencegah poin dari audit LAIN
            // di lokasi yang sama (sebelumnya tidak terbatas karena hanya
            // pakai gte) ikut tertampil berulang pada kartu yang berbeda ──
            final filtered = (logs as List).where((l) {
              final desc = l['deskripsi']?.toString() ?? '';
              if (!desc.contains(locName)) return false;
              if (auditDt == null) return true;
              final logDt = DateTime.tryParse(l['created_at']?.toString() ?? '');
              if (logDt == null) return true;
              final diffMinutes = logDt.difference(auditDt).inMinutes.abs();
              return diffMinutes <= 15;
            }).toList();

            item['_poin_logs'] = List<Map<String, dynamic>>.from(filtered);
          } catch (_) {
            item['_poin_logs'] = <Map<String, dynamic>>[];
          }
        } else {
          // Poin bonus yang diterima PIC dari log_poin
          // Include audit_bonus_tema, audit_bonus_full, audit_bonus_pic
          try {
            final createdAt = item['created_at']?.toString() ?? '';
            final auditDt = DateTime.tryParse(createdAt);

            final logs = await _supabase
                .from('log_poin')
                .select('poin, deskripsi, tipe_aktivitas, created_at')
                .eq('id_user', userId)
                .inFilter('tipe_aktivitas', [
                  'audit_bonus_tema',
                  'audit_bonus_full',
                  'audit_bonus_pic',
                ])
                .order('created_at', ascending: false)
                .limit(200);

            // ── PERUBAHAN: pisahkan window waktu pencocokan per jenis bonus,
            // agar bonus tema/full milik audit LAIN di lokasi sama (tanggal
            // berdekatan) tidak ikut tampil di kartu audit ini.
            // - audit_bonus_tema & audit_bonus_full: diberikan SAAT submit,
            //   jadi cocokkan dengan window sangat ketat (±5 menit).
            // - audit_bonus_pic: diberikan setelah PIC memperbaiki & auditor
            //   konfirmasi, bisa beberapa hari setelah audit, jadi cocokkan
            //   dengan window 0–30 hari SETELAH audit. ──
            final filtered = (logs as List).where((l) {
              final desc = l['deskripsi']?.toString() ?? '';
              if (!desc.contains(locName)) return false;
              if (auditDt == null) return true;

              final logDt = DateTime.tryParse(l['created_at']?.toString() ?? '');
              if (logDt == null) return true;

              final tipe = l['tipe_aktivitas']?.toString() ?? '';
              if (tipe == 'audit_bonus_tema' || tipe == 'audit_bonus_full') {
                final diffMinutes = logDt.difference(auditDt).inMinutes.abs();
                // ── PERUBAHAN: window dilebarkan dari 5 ke 15 menit untuk
                // toleransi keterlambatan jaringan saat proses submit ──
                return diffMinutes <= 15;
              }
              // audit_bonus_pic
              final diffDays = logDt.difference(auditDt).inDays;
              return diffDays >= 0 && diffDays <= 30;
            }).toList();

            item['_poin_logs'] = List<Map<String, dynamic>>.from(filtered);
          } catch (_) {
            item['_poin_logs'] = <Map<String, dynamic>>[];
          }
        }

        // Jawaban + tema + replies untuk detail (auditor dan PIC)
        try {
          final answers = await _supabase
              .from('audit_answer')
              .select(
                'id_answer, jawaban, catatan, gambar_jawaban, '
                'Question:audit_question('
                  'pertanyaan, pertanyaan_en, pertanyaan_zh, '
                  'Tema:audit_tema(nama_tema_id, nama_tema_en, nama_tema_zh)'
                '), '
                'Replies:audit_answer_reply('
                  'id_reply, id_pic, catatan_reply, gambar_reply, '
                  'is_confirmed, confirmed_at, created_at, '
                  'PIC:User!fk_reply_pic(nama, gambar_user)'
                ')',
              )
              .eq('id_result', idResult);
          item['_answers'] = List<Map<String, dynamic>>.from(answers as List);
        } catch (_) {
          item['_answers'] = <Map<String, dynamic>>[];
        }
      }

      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
        _applyFilter(_searchQuery);
      }
    } catch (e) {
      debugPrint('_AuditNotifRedirectTab fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String query) {
    setState(() {
      _searchQuery = query;
      final q = query.toLowerCase().trim();
      if (q.isEmpty) {
        _filtered = List.from(_allItems);
      } else {
        _filtered = _allItems.where((item) {
          final loc = (item['_location_name'] ?? '').toString().toLowerCase();
          final level = (item['level_type'] ?? '').toString().toLowerCase();
          final score = (item['nilai_audit'] ?? '').toString();
          return loc.contains(q) || level.contains(q) || score.contains(q);
        }).toList();
      }
    });
  }

  String _formatDate(dynamic v) {
    if (v == null) return '-';
    final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
    if (dt == null) return '-';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return _t('Hari ini', 'Today', '今天');
    if (diff.inDays < 7) return '${diff.inDays} ${_t('hari lalu', 'days ago', '天前')}';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _monthLabel(DateTime dt) {
    final months = {
      'EN': ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
      'ID': ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'],
      'ZH': ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
    };
    final m = months[widget.lang] ?? months['ID']!;
    return '${m[dt.month - 1]} ${dt.year}';
  }

  Color _scoreColor(double? s) {
    if (s == null) return const Color(0xFF64748B);
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Future<void> _showPeriodPicker() async {
    DateTime tempFrom = _filterFrom;
    DateTime tempTo = DateTime(_filterTo.year, _filterTo.month, _filterTo.day);
    final now = DateTime.now();
    final years = List.generate(3, (i) => now.year - 1 + i);
    final monthNames = {
      'EN': ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
      'ID': ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'],
      'ZH': ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
    }[widget.lang] ?? ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];

    Widget buildPicker(DateTime current, ValueChanged<DateTime> onChange, StateSetter setSt) {
      return Row(children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _blueLt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: current.month - 1,
                icon: Icon(Icons.keyboard_arrow_down, size: 18, color: _blue),
                style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600),
                dropdownColor: Colors.white,
                items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(monthNames[i]))),
                onChanged: (v) {
                  if (v != null) setSt(() => onChange(DateTime(current.year, v + 1)));
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
              color: _blueLt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: current.year,
                icon: Icon(Icons.keyboard_arrow_down, size: 18, color: _blue),
                style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600),
                dropdownColor: Colors.white,
                items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) {
                  if (v != null) setSt(() => onChange(DateTime(v, current.month)));
                },
              ),
            ),
          ),
        ),
      ]);
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
              border: Border.all(color: _blue.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.date_range_rounded, color: _blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t('Pilih Periode', 'Select Period', '选择期间'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _blue),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
                ]),
                const SizedBox(height: 16),
                Text(_t('Dari', 'From', '从'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                buildPicker(tempFrom, (d) => tempFrom = d, setSt),
                const SizedBox(height: 14),
                Text(_t('Sampai', 'To', '到'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                buildPicker(tempTo, (d) => tempTo = d, setSt),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterFrom = DateTime(tempFrom.year, tempFrom.month, 1);
                        _filterTo = DateTime(tempTo.year, tempTo.month + 1, 0, 23, 59, 59);
                      });
                      Navigator.pop(ctx);
                      _fetch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_t('Terapkan', 'Apply', '应用')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final periodLabel = '${_monthLabel(_filterFrom)} – ${_monthLabel(DateTime(_filterTo.year, _filterTo.month))}';

    return Column(
      children: [
        // ── Filter bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withOpacity(0.25)),
                ),
                child: Row(children: [
                  Icon(Icons.search, color: _blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _applyFilter,
                      style: GoogleFonts.poppins(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: _t('Cari lokasi audit…', 'Search audit location…', '搜索审计位置…'),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () { _searchCtrl.clear(); _applyFilter(''); },
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showPeriodPicker,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(periodLabel,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),

        // ── Content ──
        Expanded(
          child: _isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade100,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (_, __) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 110,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                )
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _blue.withOpacity(0.08),
                            ),
                            child: Icon(Icons.fact_check_outlined, size: 36, color: _blue.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 16),
                          Text(widget.t('empty_audit'),
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E3A8A))),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(widget.t('empty_audit_sub'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: _blue,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final score = double.tryParse(item['nilai_audit']?.toString() ?? '');
    final scoreFinal = double.tryParse(item['nilai_final']?.toString() ?? '');
    final isFinalized = item['is_finalized'] == true;
    final displayScore = isFinalized ? scoreFinal : score;
    final scoreColor = _scoreColor(displayScore);
    final locationName = item['_location_name']?.toString() ?? '-';
    final levelType = item['level_type']?.toString() ?? '';
    final date = _formatDate(item['tanggal_audit']);
    final answers = (item['_answers'] as List<Map<String, dynamic>>?) ?? [];
    final role = item['_role']?.toString() ?? 'auditor';
    final isPic = role == 'pic';
    final auditorData = item['Auditor'] as Map<String, dynamic>?;
    final auditorName = auditorData?['nama']?.toString() ?? '';
    final idResult = item['id_result']?.toString() ?? '';
    final userId = _supabase.auth.currentUser?.id ?? '';

    final noAnswers = answers.where((a) => a['jawaban'] == false).toList();
    final allNoConfirmed = noAnswers.isNotEmpty &&
        noAnswers.every((a) {
          final replies = (a['Replies'] as List?) ?? [];
          return replies.any((r) => r['is_confirmed'] == true);
        });

    final effectiveScore =
        (noAnswers.isNotEmpty && allNoConfirmed) ? 100.0 : displayScore;
    final effectiveScoreColor =
        _scoreColor(noAnswers.isNotEmpty && allNoConfirmed ? 100.0 : displayScore);
    final showScore = noAnswers.isEmpty || allNoConfirmed;

    final rawPoinLogs = (item['_poin_logs'] as List<Map<String, dynamic>>?) ?? [];
    // ── PERUBAHAN: filter tambahan berdasarkan struktur data —
    // audit TANPA jawaban No (100% murni) hanya mungkin mendapat
    // audit_bonus_tema / audit_bonus_full saat submit, TIDAK PERNAH
    // audit_bonus_pic. Audit yang ADA jawaban No (termasuk yang sudah
    // Final via konfirmasi) sudah pasti TIDAK pernah mendapat
    // audit_bonus_tema / audit_bonus_full (lihat guard hasAnyNo di
    // _grantBonusPoin), hanya mungkin audit_bonus_pic setelah semua No
    // dikonfirmasi. Filter ini mencegah bonus milik audit LAIN di lokasi
    // yang sama ikut tertampil pada kartu yang salah ──
    final poinLogs = role != 'pic'
        ? rawPoinLogs
        : rawPoinLogs.where((l) {
            final tipe = l['tipe_aktivitas']?.toString() ?? '';
            if (noAnswers.isEmpty) {
              return tipe == 'audit_bonus_tema' || tipe == 'audit_bonus_full';
            }
            return tipe == 'audit_bonus_pic';
          }).toList();
    final showPoinLogs = role == 'auditor' ? true : (noAnswers.isEmpty || allNoConfirmed);

    int totalPoin = 0;
    if (showPoinLogs) {
      for (final l in poinLogs) {
        totalPoin += ((l['poin'] as num?)?.toInt() ?? 0);
      }
    }

    final expanded = ValueNotifier<bool>(false);

    return ValueListenableBuilder<bool>(
      valueListenable: expanded,
      builder: (_, isExpanded, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: showScore
                ? scoreColor.withOpacity(0.25)
                : const Color(0xFFF59E0B).withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──
            GestureDetector(
              onTap: () => expanded.value = !isExpanded,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: showScore
                          ? effectiveScoreColor.withOpacity(0.12)
                          : const Color(0xFFF59E0B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: showScore
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  effectiveScore != null
                                      ? '${effectiveScore.toStringAsFixed(0)}%'
                                      : '-',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: effectiveScoreColor),
                                ),
                                if (isFinalized || allNoConfirmed)
                                  Text(_t('Final', 'Final', '最终'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          color: effectiveScoreColor)),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.pending_actions_rounded,
                                    size: 20, color: Color(0xFFF59E0B)),
                                Text(
                                  _t('Proses', 'WIP', '进行中'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF59E0B)),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPic
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : _blue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPic ? _t('PIC', 'PIC', 'PIC') : _t('Auditor', 'Auditor', '审计员'),
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isPic ? const Color(0xFF10B981) : _blue),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(levelType.toUpperCase(),
                                style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _blue)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(locationName,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E3A8A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(date,
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: Colors.grey.shade400)),
                          if (isPic && auditorName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '· ${_t('oleh', 'by', '由')} $auditorName',
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: Colors.grey.shade500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          // Badge poin hanya jika showPoinLogs dan ada poin
                          if (totalPoin != 0 && showPoinLogs) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: totalPoin > 0
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : const Color(0xFFEF4444).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                totalPoin > 0 ? '+$totalPoin poin' : '$totalPoin poin',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: totalPoin > 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                          if (!showScore) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFF59E0B).withOpacity(0.4)),
                              ),
                              child: Text(
                                _t('Perlu Perbaikan', 'Needs Fix', '需要修复'),
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF59E0B)),
                              ),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _blue,
                    size: 22,
                  ),
                ]),
              ),
            ),

            // ── Detail expand ──
            if (isExpanded) ...[
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Poin log — hanya tampil jika showPoinLogs
              if (poinLogs.isNotEmpty && showPoinLogs)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      const Color(0xFF10B981).withOpacity(0.08),
                      _blue.withOpacity(0.05),
                    ]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: Color(0xFF10B981), size: 15),
                        const SizedBox(width: 6),
                        Text(
                          isPic
                              ? _t('Bonus Poin PIC', 'PIC Bonus Points', 'PIC奖励积分')
                              : _t('Poin Diperoleh', 'Points Earned', '获得积分'),
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      ...poinLogs.map((log) {
                        final p = (log['poin'] as num?)?.toInt() ?? 0;
                        final isPos = p >= 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPos
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : const Color(0xFFEF4444).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(isPos ? '+$p' : '$p',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isPos
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(log['deskripsi']?.toString() ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF1E3A8A)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        );
                      }),
                    ],
                  ),
                ),

              // Pertanyaan No + thread reply
              if (noAnswers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      '${noAnswers.length} ${_t('pertanyaan perlu perbaikan', 'questions need fix', '个问题需要修复')}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444)),
                    ),
                  ]),
                ),
                ...noAnswers.map((ans) =>
                    _buildAnswerThreadFull(ans, idResult, isPic, userId)),
              ],

              // Ringkasan jawaban semua
              if (answers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(children: [
                    Icon(Icons.list_alt_rounded, size: 14, color: _blue),
                    const SizedBox(width: 6),
                    Text(
                      _t('Ringkasan Jawaban', 'Answer Summary', '回答摘要'),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _blue),
                    ),
                  ]),
                ),
                _buildAnswerSummary(answers),
              ],

              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  /// Thread reply untuk pertanyaan No:
  /// - PIC: foto (wajib) + notes (wajib) → submit reply
  /// - Auditor: notes (wajib) → konfirmasi Yes langsung
  /// - Tombol Edit + Delete hanya pada reply card
  /// - Konfirmasi Yes HANYA dari sisi auditor (tidak perlu reply dulu)
  Widget _buildAnswerThreadFull(
      Map<String, dynamic> ans,
      String idResult,
      bool isPic,
      String userId) {
    final q = ans['Question'] as Map<String, dynamic>?;
    final replies = (ans['Replies'] as List?)
            ?.map((r) => Map<String, dynamic>.from(r as Map))
            .toList() ??
        [];
    final gambar = ans['gambar_jawaban']?.toString() ?? '';
    final catatan = ans['catatan']?.toString() ?? '';
    final idAnswer = ans['id_answer']?.toString() ?? '';

    // Cek apakah reply PIC sudah dikonfirmasi oleh auditor
    final picReplies = replies.where((r) => r['is_confirmed'] != true).toList();
    final confirmedReplies = replies.where((r) => r['is_confirmed'] == true).toList();
    final isFullyConfirmed = confirmedReplies.isNotEmpty;

    String questionText;
    if (widget.lang == 'EN') {
      questionText = q?['pertanyaan_en']?.toString() ??
          q?['pertanyaan']?.toString() ?? '-';
    } else if (widget.lang == 'ZH') {
      questionText = q?['pertanyaan_zh']?.toString() ??
          q?['pertanyaan']?.toString() ?? '-';
    } else {
      questionText = q?['pertanyaan']?.toString() ?? '-';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFullyConfirmed
            ? const Color(0xFF10B981).withOpacity(0.05)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullyConfirmed
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pertanyaan ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: isFullyConfirmed
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFullyConfirmed ? Icons.check_rounded : Icons.close_rounded,
                  size: 12,
                  color: isFullyConfirmed
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(questionText,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A))),
              ),
            ],
          ),

          // Evidence auditor (gambar temuan)
          if (gambar.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(gambar,
                  height: 120, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
          if (catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            // ── PERUBAHAN: tambah label "Notes" agar lebih jelas ──
            Text(
              _t('Catatan', 'Notes', '备注'),
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(catatan,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF64748B))),
            ),
          ],

          // ── Daftar Replies ──
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            ...replies.map((reply) {
              final confirmed = reply['is_confirmed'] == true;
              final picData = reply['PIC'] as Map<String, dynamic>?;
              final picName = picData?['nama']?.toString() ?? '-';
              final replyGambar = reply['gambar_reply']?.toString() ?? '';
              final replyCatatan = reply['catatan_reply']?.toString() ?? '';
              final idReply = reply['id_reply']?.toString() ?? '';
              // ── PERUBAHAN: cek apakah reply ini benar-benar dikirim oleh
              // User yang sedang login, bukan sekadar role PIC/Auditor ──
              final replyOwnerId = reply['id_pic']?.toString();
              final isOwnReply = replyOwnerId != null && replyOwnerId == userId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: confirmed
                      ? const Color(0xFF10B981).withOpacity(0.07)
                      : const Color(0xFF6366F1).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: confirmed
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFF6366F1).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header reply + Edit/Delete (hanya jika belum confirmed dan milik PIC)
                    Row(children: [
                      Icon(
                        confirmed ? Icons.verified_rounded : Icons.reply_rounded,
                        size: 13,
                        color: confirmed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          confirmed
                              ? '$picName ✓ ${_t('Dikonfirmasi', 'Confirmed', '已确认')}'
                              : picName,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: confirmed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6366F1)),
                        ),
                      ),
                      // Edit & Delete hanya untuk PIC pada reply yang belum confirmed
                      if (isPic && !confirmed && isOwnReply) ...[
                        GestureDetector(
                          onTap: () => _showEditReplySheet(
                              idReply, idAnswer, idResult, userId, reply),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.edit_rounded,
                                size: 13, color: _blue),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _deleteReply(idReply),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 13, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ]),

                    if (replyCatatan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(replyCatatan,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF1E3A8A))),
                    ],
                    if (replyGambar.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(replyGambar,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()),
                      ),
                    ],

                    // ── PERUBAHAN: tombol Konfirmasi + Balas — HANYA untuk
                    // Auditor, HANYA pada reply milik PIC (bukan reply
                    // auditor sendiri), belum confirmed. Tombol "Balas"
                    // memungkinkan auditor memberi feedback ke PIC kalau
                    // perbaikan dirasa belum cukup, tanpa harus langsung
                    // konfirmasi yes ──
                    if (!isPic && !confirmed && !isOwnReply) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _confirmReply(idReply, idAnswer, idResult),
                            icon: const Icon(Icons.check_circle_rounded, size: 14),
                            label: Text(
                              _t('Konfirmasi', 'Confirm', '确认'),
                              style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAuditorReplySheet(
                                idReply, idAnswer, idResult, userId),
                            icon: const Icon(Icons.reply_rounded, size: 14),
                            label: Text(
                              _t('Balas', 'Reply', '回复'),
                              style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _blue,
                              side: BorderSide(color: _blue),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              );
            }),
          ],

          // ── Tombol Reply — hanya untuk PIC jika belum fully confirmed ──
          if (isPic && !isFullyConfirmed) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showReplyBottomSheet(ans, idResult, true, userId),
                icon: const Icon(Icons.reply_rounded, size: 14),
                label: Text(
                  replies.isEmpty
                      ? _t('Balas Temuan', 'Reply Finding', '回复发现')
                      : _t('Tambah Balasan', 'Add Reply', '添加回复'),
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],

          // ── Info untuk Auditor: menunggu reply PIC ──
          if (!isPic && replies.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _t(
                      'Menunggu balasan PIC…',
                      'Waiting for PIC reply…',
                      '等待PIC回复…',
                    ),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFFF59E0B)),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  /// Bottom sheet reply untuk PIC:
  /// - Foto WAJIB (ada indikator *)
  /// - Notes WAJIB (ada indikator *)
  Future<void> _showReplyBottomSheet(
      Map<String, dynamic> ans,
      String idResult,
      bool isPic,
      String userId) async {
    final noteCtrl = TextEditingController();
    String? photoUrl;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.reply_rounded,
                        color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Balas Temuan', 'Reply Finding', '回复发现'),
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A)),
                        ),
                        Text(
                          _t(
                            'Sertakan bukti foto dan penjelasan tindakan perbaikan.',
                            'Include photo evidence and corrective action description.',
                            '请附上照片证据和纠正措施说明。',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── Foto Bukti WAJIB ──
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A)),
                    children: const [
                      TextSpan(text: 'Foto Bukti Perbaikan'),
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final url = await Navigator.push<String>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => AuditEvidenceCameraScreen(
                          lang: widget.lang,
                          questionText: '',
                        ),
                      ),
                    );
                    if (url != null) setSt(() => photoUrl = url);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: photoUrl == null
                            ? const Color(0xFFEF4444).withOpacity(0.4)
                            : const Color(0xFF6366F1).withOpacity(0.5),
                      ),
                    ),
                    child: photoUrl == null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(children: [
                              const Icon(Icons.add_a_photo_rounded,
                                  color: Color(0xFF6366F1), size: 22),
                              const SizedBox(height: 4),
                              Text(
                                _t('Ambil / Upload Foto *',
                                    'Take / Upload Photo *', '拍照/上传照片 *'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6366F1)),
                              ),
                              Text(
                                _t('Wajib diisi', 'Required', '必填'),
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: const Color(0xFFEF4444)),
                              ),
                            ]),
                          )
                        : Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(photoUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setSt(() => photoUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Notes WAJIB ──
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A)),
                    children: const [
                      TextSpan(text: 'Keterangan Tindakan Perbaikan'),
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _t(
                      'Jelaskan tindakan perbaikan yang telah dilakukan…',
                      'Describe corrective action taken…',
                      '描述已采取的纠正措施…',
                    ),
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            // Validasi: foto wajib
                            if (photoUrl == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Upload foto bukti perbaikan terlebih dahulu.',
                                    'Please upload fix evidence photo.',
                                    '请先上传修复证据照片。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            // Validasi: notes wajib
                            if (noteCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Keterangan tindakan perbaikan wajib diisi.',
                                    'Corrective action description is required.',
                                    '请填写纠正措施说明。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            setSt(() => submitting = true);
                            try {
                              await _supabase.from('audit_answer_reply').insert({
                                'id_answer': ans['id_answer'],
                                'id_pic': userId,
                                'catatan_reply': noteCtrl.text.trim(),
                                'gambar_reply': photoUrl,
                                'is_confirmed': false,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetch();
                            } catch (e) {
                              setSt(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _t('Kirim Balasan', 'Send Reply', '发送回复'),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Edit reply yang sudah ada (hanya PIC, belum confirmed)
  Future<void> _showEditReplySheet(
      String idReply,
      String idAnswer,
      String idResult,
      String userId,
      Map<String, dynamic> existingReply) async {
    final noteCtrl = TextEditingController(
        text: existingReply['catatan_reply']?.toString() ?? '');
    String? photoUrl = existingReply['gambar_reply']?.toString();
    if (photoUrl != null && photoUrl.isEmpty) photoUrl = null;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_rounded, color: _blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _t('Edit Balasan', 'Edit Reply', '编辑回复'),
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A)),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Foto WAJIB
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A)),
                    children: const [
                      TextSpan(text: 'Foto Bukti Perbaikan'),
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final url = await Navigator.push<String>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => AuditEvidenceCameraScreen(
                          lang: widget.lang,
                          questionText: '',
                        ),
                      ),
                    );
                    if (url != null) setSt(() => photoUrl = url);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: photoUrl == null
                            ? const Color(0xFFEF4444).withOpacity(0.4)
                            : const Color(0xFF6366F1).withOpacity(0.5),
                      ),
                    ),
                    child: photoUrl == null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(children: [
                              const Icon(Icons.add_a_photo_rounded,
                                  color: Color(0xFF6366F1), size: 22),
                              const SizedBox(height: 4),
                              Text(
                                _t('Ambil / Upload Foto *',
                                    'Take / Upload Photo *', '拍照/上传照片 *'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6366F1)),
                              ),
                            ]),
                          )
                        : Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(photoUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setSt(() => photoUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes WAJIB
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A)),
                    children: const [
                      TextSpan(text: 'Keterangan Tindakan Perbaikan'),
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _t(
                      'Jelaskan tindakan perbaikan…',
                      'Describe corrective action…',
                      '描述纠正措施…',
                    ),
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (photoUrl == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Upload foto bukti perbaikan terlebih dahulu.',
                                    'Please upload fix evidence photo.',
                                    '请先上传修复证据照片。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            if (noteCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Keterangan tindakan perbaikan wajib diisi.',
                                    'Corrective action description is required.',
                                    '请填写纠正措施说明。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            setSt(() => submitting = true);
                            try {
                              await _supabase
                                  .from('audit_answer_reply')
                                  .update({
                                'catatan_reply': noteCtrl.text.trim(),
                                'gambar_reply': photoUrl,
                              }).eq('id_reply', idReply);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetch();
                            } catch (e) {
                              setSt(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _t('Simpan Perubahan', 'Save Changes', '保存更改'),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hapus reply (hanya PIC, belum confirmed)
  Future<void> _deleteReply(String idReply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t('Hapus Balasan', 'Delete Reply', '删除回复'),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A)),
        ),
        content: Text(
          _t('Balasan ini akan dihapus. Lanjutkan?',
              'This reply will be deleted. Continue?', '此回复将被删除。是否继续？'),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Batal', 'Cancel', '取消'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_t('Hapus', 'Delete', '删除'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _supabase
          .from('audit_answer_reply')
          .delete()
          .eq('id_reply', idReply);
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  /// Bottom sheet untuk auditor MEMBALAS balasan PIC tanpa mengonfirmasi.
  /// Dipakai saat perbaikan PIC dirasa belum cukup — auditor menambahkan
  /// catatan (opsional foto) ke thread, PIC akan melihatnya dan bisa
  /// membalas lagi. Reply ini TIDAK menandai is_confirmed: true.
  Future<void> _showAuditorReplySheet(
      String idReply,
      String idAnswer,
      String idResult,
      String userId) async {
    final noteCtrl = TextEditingController();
    String? photoUrl;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.reply_rounded, color: _blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Balas Perbaikan', 'Reply to Fix', '回复修复'),
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A)),
                        ),
                        Text(
                          _t(
                            'Jelaskan jika perbaikan belum sesuai — PIC akan menerima balasan ini dan bisa memperbaiki lagi.',
                            'Explain if the fix is not sufficient yet — PIC will receive this and can fix it again.',
                            '说明修复是否仍不充分——PIC将收到此回复并可以再次修复。',
                          ),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Upload foto (opsional)
                GestureDetector(
                  onTap: () async {
                    final url = await Navigator.push<String>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => AuditEvidenceCameraScreen(
                          lang: widget.lang,
                          questionText: '',
                        ),
                      ),
                    );
                    if (url != null) setSt(() => photoUrl = url);
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _blue.withOpacity(0.3)),
                    ),
                    child: photoUrl == null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(children: [
                              Icon(Icons.add_a_photo_rounded, color: _blue, size: 22),
                              const SizedBox(height: 4),
                              Text(
                                _t('Upload Foto (opsional)',
                                    'Upload Photo (optional)', '上传照片（可选）'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _blue),
                              ),
                            ]),
                          )
                        : Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(photoUrl!,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setSt(() => photoUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Catatan (wajib)
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _t(
                      'Jelaskan kekurangan perbaikan ini (wajib)…',
                      'Describe what is still lacking (required)…',
                      '说明此修复仍存在的问题（必填）…',
                    ),
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _blue, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (noteCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text(_t(
                                    'Catatan wajib diisi.',
                                    'Note is required.',
                                    '备注为必填项。')),
                                backgroundColor: const Color(0xFFEF4444),
                              ));
                              return;
                            }
                            setSt(() => submitting = true);
                            try {
                              // ── Hanya menambahkan balasan auditor ke thread,
                              // TIDAK mengonfirmasi reply PIC — tujuannya
                              // memberi feedback bahwa perbaikan belum cukup,
                              // bukan menyetujuinya ──
                              await _supabase.from('audit_answer_reply').insert({
                                'id_answer': idAnswer,
                                'id_pic': userId,
                                'catatan_reply': noteCtrl.text.trim(),
                                'gambar_reply': photoUrl,
                                'is_confirmed': false,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              _fetch();
                            } catch (e) {
                              setSt(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                    icon: submitting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      submitting ? '' : _t('Kirim Balasan', 'Send Reply', '发送回复'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Konfirmasi reply PIC oleh Auditor.
/// Memberikan AUDIT_BONUS_PIC ke PIC jika semua No sudah confirmed.
/// TIDAK memberikan bonus tema / bonus full.
Future<void> _confirmReply(
    String idReply, String idAnswer, String idResult) async {
  try {
    // Update reply → is_confirmed: true
    await _supabase
        .from('audit_answer_reply')
        .update({
          'is_confirmed': true,
          'confirmed_at': DateTime.now().toIso8601String(),
        })
        .eq('id_reply', idReply);

    // Cek apakah result sudah finalized
    final resultRow = await _supabase
        .from('audit_result')
        .select('is_finalized, level_type, id_ref, id_auditor')
        .eq('id_result', idResult)
        .maybeSingle();

    if (resultRow == null || resultRow['is_finalized'] == true) {
      _fetch();
      return;
    }

    // Ambil semua jawaban No dan cek apakah semua sudah confirmed
    final allAnswers = await _supabase
        .from('audit_answer')
        .select('id_answer, jawaban, Replies:audit_answer_reply(is_confirmed)')
        .eq('id_result', idResult);

    final noAnswers = (allAnswers as List)
        .where((a) => a['jawaban'] == false)
        .toList();

    final allNoConfirmed = noAnswers.isNotEmpty &&
        noAnswers.every((a) {
          final replies = (a['Replies'] as List?) ?? [];
          return replies.any((r) => r['is_confirmed'] == true);
        });

    if (!allNoConfirmed) {
      // Belum semua No confirmed — jangan finalize dulu
      _fetch();
      return;
    }

    // Semua No sudah confirmed → beri AUDIT_BONUS_PIC ke PIC
    final levelType = resultRow['level_type'].toString();
    final idRef = resultRow['id_ref'].toString();
    final nameCol = 'nama_$levelType';
    final idCol = 'id_$levelType';

    final locRow = await _supabase
        .from(levelType)
        .select('id_pic, $nameCol')
        .eq(idCol, idRef)
        .maybeSingle();

    final picId = locRow?['id_pic']?.toString();
    final lokasiName = locRow?[nameCol]?.toString() ?? '-';

    if (picId != null) {
      final cfgRow = await _supabase
          .from('konfigurasi_poin')
          .select('poin, deskripsi_template')
          .eq('kode', 'AUDIT_BONUS_PIC')
          .eq('is_aktif', true)
          .maybeSingle();

      if (cfgRow != null) {
        final deskripsi = (cfgRow['deskripsi_template'] as String)
            .replaceAll('{lokasi}', lokasiName);

        await _supabase.from('log_poin').insert({
          'id_user': picId,
          'poin': cfgRow['poin'] as int,
          'deskripsi': deskripsi,
          'tipe_aktivitas': 'audit_bonus_pic',
        });
      }
    }

    // Tandai result sebagai finalized
    await _supabase
        .from('audit_result')
        .update({'is_finalized': true})
        .eq('id_result', idResult);

    _fetch();
  } catch (e) {
    debugPrint('_confirmReply error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    }
  }
}

  /// Ringkasan jawaban semua (yes dan no) dalam format compact
  Widget _buildAnswerSummary(List<Map<String, dynamic>> answers) {
    final Map<String, List<Map<String, dynamic>>> byTema = {};
    for (final ans in answers) {
      final q = ans['Question'] as Map<String, dynamic>?;
      final tema = q?['Tema'] as Map<String, dynamic>?;
      String temaKey;
      if (widget.lang == 'EN') {
        temaKey = tema?['nama_tema_en']?.toString() ?? _t('Lainnya', 'Other', '其他');
      } else if (widget.lang == 'ZH') {
        temaKey = tema?['nama_tema_zh']?.toString() ?? _t('Lainnya', 'Other', '其他');
      } else {
        temaKey = tema?['nama_tema_id']?.toString() ?? _t('Lainnya', 'Other', '其他');
      }
      byTema.putIfAbsent(temaKey, () => []).add(ans);
    }

    return Column(
      children: byTema.entries.map((entry) {
        final temaName = entry.key;
        final temaAnswers = entry.value;
        final yes = temaAnswers.where((a) => a['jawaban'] == true).length;
        final total = temaAnswers.length;
        final is100 = yes == total;
        Color temaColor = is100 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          decoration: BoxDecoration(
            color: is100
                ? const Color(0xFF10B981).withOpacity(0.04)
                : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: temaColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  Icon(
                      is100 ? Icons.check_circle_rounded : Icons.topic_outlined,
                      size: 13, color: temaColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(temaName,
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700, color: temaColor)),
                  ),
                  Text('$yes/$total',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w700, color: temaColor)),
                ]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════
// TAB 1 & 2 — tidak berubah dari kode asli
// ══════════════════════════════════════════════
class _AssignedFindingsTab extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialData;
  final String Function(String) t;

  const _AssignedFindingsTab({required this.lang, required this.t, this.initialData});

  @override
  State<_AssignedFindingsTab> createState() => _AssignedFindingsTabState();
}

class _AssignedFindingsTabState extends State<_AssignedFindingsTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _items = widget.initialData!;
    } else {
      _fetchFindings();
    }
  }

  Future<void> _fetchFindings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('temuan')
          .select(
            'id_temuan, judul_temuan, gambar_temuan, created_at, '
            'status_temuan, poin_temuan, target_waktu_selesai, '
            'jenis_temuan, id_lokasi, id_unit, id_subunit, id_area, '
            'id_penanggung_jawab, is_pro, is_visitor, is_eksekutif, '
            'lokasi(nama_lokasi), unit(nama_unit), '
            'subunit(nama_subunit), area(nama_area)',
          )
          .eq('id_penanggung_jawab', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching findings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return _buildShimmer();
    if (_items.isEmpty) {
      return _buildEmpty(
        widget.t('empty_findings'),
        widget.t('empty_findings_sub'),
        Icons.assignment_ind_outlined,
      );
    }

    final pendingCount = _items.where((e) {
      final s = (e['status_temuan'] ?? '').toString().toLowerCase();
      return !['selesai', 'done', 'completed', 'closed'].any((x) => s.contains(x));
    }).length;

    return Column(
      children: [
        if (pendingCount > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFFDC2626).withOpacity(0.08),
                const Color(0xFFEF4444).withOpacity(0.05),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.pending_actions_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.lang == 'ID'
                      ? '$pendingCount temuan masih menunggu penyelesaian Anda'
                      : '$pendingCount findings are waiting for your action',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626)),
                ),
              ),
            ]),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return FindingCard(
                data: item,
                lang: widget.lang,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FindingDetailScreen(initialData: item, lang: widget.lang),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C9E4).withOpacity(0.08),
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF00C9E4).withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TAB 2: Activity Log
// ══════════════════════════════════════════════
class _ActivityLogTab extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialLogs;
  final String Function(String) t;

  const _ActivityLogTab({
    required this.lang,
    required this.t,
    this.initialLogs,
  });

  @override
  State<_ActivityLogTab> createState() => _ActivityLogTabState();
}

class _ActivityLogTabState extends State<_ActivityLogTab>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  DateTime _filterFrom =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _filterTo = DateTime(
      DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  int _totalPoin = 0;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLogs != null) {
      _allLogs = widget.initialLogs!;
      _computeTotal(_allLogs);
      _filteredLogs = List.from(_allLogs);
    } else {
      _fetchLogs();
    }
  }

  void _computeTotal(List<Map<String, dynamic>> logs) {
    int total = 0;
    for (final l in logs) {
      total += ((l['poin'] as num?)?.toInt() ?? 0);
    }
    _totalPoin = total;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final List<dynamic> logs = await Supabase.instance.client
          .from('log_poin')
          .select('poin, deskripsi, tipe_aktivitas, created_at')
          .eq('id_user', userId)
          .gte('created_at', _filterFrom.toIso8601String())
          .lte('created_at', _filterTo.toIso8601String())
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(logs);
      if (mounted) {
        setState(() {
          _allLogs = list;
          _computeTotal(list);
          _isLoading = false;
        });
        _applySearch(_searchQuery);
      }
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredLogs = List.from(_allLogs);
      } else {
        final q = query.toLowerCase();
        _filteredLogs = _allLogs.where((l) {
          final desc = (l['deskripsi'] ?? '').toString().toLowerCase();
          final tipe = (l['tipe_aktivitas'] ?? '').toString().toLowerCase();
          return desc.contains(q) || tipe.contains(q);
        }).toList();
      }
    });
  }

  Color _getTipeColor(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':
        return const Color(0xFFEC4899);
      case 'login_harian':
        return const Color(0xFF3B82F6);
      case 'login_pertama_hari_ini':
        return const Color(0xFFF59E0B);
      case 'penalti':
        return const Color(0xFFEF4444);
      default:
        return isPositive
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
    }
  }

  IconData _getTipeIcon(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':
        return Icons.celebration_rounded;
      case 'login_harian':
        return Icons.today_rounded;
      case 'login_pertama_hari_ini':
        return Icons.emoji_events_rounded;
      case 'penalti':
        return Icons.warning_amber_rounded;
      default:
        return isPositive
            ? Icons.star_rounded
            : Icons.remove_circle_outline_rounded;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt =
        value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return widget.lang == 'ZH'
          ? '刚刚'
          : widget.lang == 'EN'
              ? 'Just now'
              : 'Baru saja';
    }
    if (diff.inHours < 1) {
      return widget.lang == 'ZH'
          ? '${diff.inMinutes}分钟前'
          : widget.lang == 'EN'
              ? '${diff.inMinutes} min ago'
              : '${diff.inMinutes} menit lalu';
    }
    if (diff.inDays < 1) {
      return widget.lang == 'ZH'
          ? '${diff.inHours}小时前'
          : widget.lang == 'EN'
              ? '${diff.inHours} hr ago'
              : '${diff.inHours} jam lalu';
    }
    if (diff.inDays < 7) {
      return widget.lang == 'ZH'
          ? '${diff.inDays}天前'
          : widget.lang == 'EN'
              ? '${diff.inDays} days ago'
              : '${diff.inDays} hari lalu';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _monthLabel(DateTime dt) {
    final months = {
      'EN': ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
      'ID': ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'],
      'ZH': ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
    };
    final m = months[widget.lang] ?? months['ID']!;
    return '${m[dt.month - 1]} ${dt.year}';
  }

  void _showPeriodPicker() async {
    DateTime tempFrom = _filterFrom;
    DateTime tempTo =
        DateTime(_filterTo.year, _filterTo.month, _filterTo.day);

    final now = DateTime.now();
    final years = List.generate(3, (i) => now.year - 1 + i);
    final monthNames = {
          'EN': ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
          'ID': ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'],
          'ZH': ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'],
        }[widget.lang] ??
        ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];

    Widget buildMonthYearPicker(DateTime current,
        ValueChanged<DateTime> onChange, StateSetter setSt) {
      return Row(children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: current.month - 1,
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: Color(0xFF0284C7)),
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0C4A6E),
                    fontWeight: FontWeight.w600),
                dropdownColor: Colors.white,
                items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                        value: i, child: Text(monthNames[i]))),
                onChanged: (v) {
                  if (v != null)
                    setSt(() => onChange(DateTime(current.year, v + 1)));
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
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: current.year,
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: Color(0xFF0284C7)),
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0C4A6E),
                    fontWeight: FontWeight.w600),
                dropdownColor: Colors.white,
                items: years
                    .map((y) =>
                        DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) {
                  if (v != null)
                    setSt(() => onChange(DateTime(v, current.month)));
                },
              ),
            ),
          ),
        ),
      ]);
    }

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
                  color: const Color(0xFFE0F2FE), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.date_range_rounded,
                      color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    widget.lang == 'EN'
                        ? 'Select Period'
                        : widget.lang == 'ZH'
                            ? '选择期间'
                            : 'Pilih Periode',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0C4A6E)),
                  )),
                  IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero),
                ]),
                const SizedBox(height: 16),
                Text(
                  widget.lang == 'EN'
                      ? 'From'
                      : widget.lang == 'ZH'
                          ? '从'
                          : 'Dari',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                buildMonthYearPicker(
                    tempFrom, (d) => tempFrom = d, setSt),
                const SizedBox(height: 14),
                Text(
                  widget.lang == 'EN'
                      ? 'To'
                      : widget.lang == 'ZH'
                          ? '到'
                          : 'Sampai',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                buildMonthYearPicker(
                    tempTo, (d) => tempTo = d, setSt),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterFrom = DateTime(
                            tempFrom.year, tempFrom.month, 1);
                        _filterTo = DateTime(tempTo.year,
                            tempTo.month + 1, 0, 23, 59, 59);
                      });
                      Navigator.pop(ctx);
                      _fetchLogs();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.lang == 'EN'
                        ? 'Apply'
                        : widget.lang == 'ZH'
                            ? '应用'
                            : 'Terapkan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getFireColor(int points) {
    if (points >= 1000) return const Color(0xFFEF4444);
    if (points >= 500) return const Color(0xFFF97316);
    if (points >= 100) return const Color(0xFF22C55E);
    if (points > 0) return const Color(0xFF3B82F6);
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final fireColor = _getFireColor(_totalPoin);
    final periodLabel =
        '${_monthLabel(_filterFrom)} – ${_monthLabel(DateTime(_filterTo.year, _filterTo.month))}';

    return Column(children: [
      // ── Summary Card ──
      Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(children: [
          Icon(Icons.local_fire_department_rounded,
              color: fireColor, size: 32),
          const SizedBox(width: 12),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lang == 'EN'
                      ? 'Total Points'
                      : widget.lang == 'ZH'
                          ? '总积分'
                          : 'Total Poin',
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                ),
                Text(
                  _isLoading
                      ? '...'
                      : '$_totalPoin ${widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin'}',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
              ]),
          const Spacer(),
          Text(
            _isLoading ? '...' : '${_filteredLogs.length} log',
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
          ),
        ]),
      ),

      // ── Filter Bar ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(children: [
                const Icon(Icons.search,
                    color: Color(0xFF0EA5E9), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _applySearch,
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: widget.lang == 'EN'
                          ? 'Search activity...'
                          : widget.lang == 'ZH'
                              ? '搜索活动...'
                              : 'Cari aktivitas...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      _applySearch('');
                    },
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.grey),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showPeriodPicker,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      periodLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ]),
            ),
          ),
        ]),
      ),

      // ── Log List ──
      Expanded(
        child: _isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade100,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (_, __) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 70,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )
            : _filteredLogs.isEmpty
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00C9E4).withOpacity(0.08),
                        ),
                        child: Icon(Icons.history_rounded,
                            size: 36,
                            color: const Color(0xFF00C9E4).withOpacity(0.5)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.t('empty_activity'),
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E3A8A)),
                      ),
                    ],
                  ))
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: _filteredLogs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildActivityLogCard(_filteredLogs[index]),
                  ),
      ),
    ]);
  }

  Widget _buildActivityLogCard(Map<String, dynamic> log) {
    final int poin = (log['poin'] as num).toInt();
    final bool isPositive = poin >= 0;
    final String tipe = (log['tipe_aktivitas'] ?? '').toString();
    final String desc = (log['deskripsi'] ?? '').toString();
    final String tanggal = _formatDate(log['created_at']);
    final Color color = _getTipeColor(tipe, isPositive);
    final IconData icon = _getTipeIcon(tipe, isPositive);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.4),
              ),
              const SizedBox(height: 3),
              Text(tanggal,
                  style: GoogleFonts.poppins(
                      fontSize: 10.5, color: Colors.grey.shade400)),
            ])),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(
            isPositive ? '+$poin' : '$poin',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color),
          ),
        ),
      ]),
    );
  }
}