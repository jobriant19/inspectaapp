import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../user/finding/finding_detail_screen.dart';
import '../../user/home/finding_card.dart';

class NotificationScreen extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialFindings;
  final List<Map<String, dynamic>>? initialActivityLogs;

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
                    initialData: widget.initialFindings,
                    t: _t,
                  ),
                  _ActivityLogTab(
                    lang: widget.lang,
                    initialLogs: widget.initialActivityLogs,
                    t: _t,
                  ),
                  _AuditNotifTab(lang: widget.lang, t: _t),
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