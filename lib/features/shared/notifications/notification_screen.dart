import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/push_notification_service.dart';
import 'assigned_findings_tab.dart';
import 'activity_log_tab.dart';
import 'audit_notif_tab.dart';

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
            // HEADER
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
                    // 3 TAB 
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

            // CONTENT
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AssignedFindingsTab(
                    lang: widget.lang,
                    initialData: widget.initialFindings != null
                        ? List<Map<String, dynamic>>.from(widget.initialFindings!)
                        : null,
                    t: _t,
                  ),
                  ActivityLogTab(
                    lang: widget.lang,
                    initialLogs: widget.initialActivityLogs != null
                        ? List<Map<String, dynamic>>.from(widget.initialActivityLogs!)
                        : null,
                    t: _t,
                  ),
                  AuditNotifTab(lang: widget.lang, t: _t),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}