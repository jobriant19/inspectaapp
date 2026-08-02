import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/jabatan_helper.dart';
import '../account/account_screen.dart';
import '../explore/explore_screen.dart';
import '../analytics/analytics_screen.dart';
import '../../shared/notifications/notification_screen.dart';
import '../leaderboard/ranking/ranking_screen.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'popup/home_news_popup.dart';
import 'card/user_info_card.dart';
import 'activity_log_dialog.dart';
import 'home_content.dart';
import 'location/location_bottom_screen.dart';
import 'popup/home_mode_popup.dart';
import 'popup/home_point_popup.dart';
import 'popup/location_permission_popup.dart';

// Supabase shorthand
final _sb = Supabase.instance.client;

class HomeScreen extends StatefulWidget {
  final String? initialUserName;
  final int? initialUserPoin;
  final String? initialUserImage;
  final String? initialUserRole;
  final String? initialUserLocation;
  final String? initialUserLocationLevel;
  final Map<String, dynamic>? initialLatestLog;
  final int? initialUserJabatanId;
  final bool? initialIsVerificator;
  final int? initialNotifCount;
  final int? initialMonthlyPoin;
  final bool? initialIsProMode;
  final bool? initialIsVisitorMode;
  final bool? initialIsPreventiveMaintenanceVisible;
  final List<Map<String, dynamic>>? initialPendingAudits;

  const HomeScreen({
    super.key,
    this.initialUserName,
    this.initialUserPoin,
    this.initialUserImage,
    this.initialUserRole,
    this.initialUserLocation,
    this.initialUserLocationLevel,
    this.initialLatestLog,
    this.initialUserJabatanId,
    this.initialIsVerificator,
    this.initialNotifCount,
    this.initialMonthlyPoin,
    this.initialIsProMode,
    this.initialIsVisitorMode,
    this.initialIsPreventiveMaintenanceVisible,
    this.initialPendingAudits,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _lang = 'EN';
  bool _isProMode = false;
  bool _isVisitorMode = false;
  String _userLocationName = '...';
  String? _userLocationLevel;
  String? _appLogoUrl;
  int? _userJabatanId;
  // ignore: unused_field
  bool _isLoadingVisitorStatus = true;
  bool _isUserDataLoading = true;
  RealtimeChannel? _pointChannel;
  // ignore: unused_field
  bool _isCheckingLocation = false;
  bool _isAtAtmi = false;
  bool _isPreventiveMaintenanceVisible = true;
  List<Map<String, dynamic>>? _initialPendingAudits;

  // User data
  String _userName = '...';
  String _userRole = '...';
  int _userPoin = 0;
  String? _userImage;
  String? _userUnitId;
  String? _userLokasiId;

  int _notificationCount = 0;
  int? _initialMonthlyPoin;
  Map<String, dynamic>? _latestLogPoin;
  List<Map<String, dynamic>> _monthlyActivityLogs = [];
  bool _isLatestLogLoading = true;
  bool _isExecutiveVerificator = false;
  bool _hasShownLoginDialog = false;
bool _isOpeningNotif = false; // guard: cegah notif screen kebuka dobel

  // Point animation
  bool _isAnimatingPoin = false;
  int _displayedPoin = 0;

  _PendingPointNotif? _pendingPointNotif;
  final GlobalKey<HomeContentState> _homeContentKey = GlobalKey<HomeContentState>();
  int _findingsRefreshTrigger = 0;
  int _lastRefreshTrigger = 0;
  _AppLifecycleObserver? _lifecycleObserver;

  // ── Tipe login/verif yang skip dialog notif ──
  static const Set<String> _loginTipes = {
    'login_pertama', 'login_harian', 'login_pertama_hari_ini', 'penalti',
  };
  static const Set<String> _verifTipes = {
    'verifikasi_partisipasi', 'verifikasi_benar', 'verifikasi_salah',
  };

  // ── Nav text (flat map untuk lookup O(1)) ──
  static const Map<String, Map<String, String>> _navText = {
    'EN': {
      'home': 'Home', 'explore': 'Explore', 'analytics': 'Analytics',
      'ranking': 'Ranking', 'visitor_on': 'Visitor Mode Activated',
      'visitor_off': 'Visitor Mode Deactivated', 'update_failed': 'Update Failed',
      'recent_findings': 'Recent Findings', 'view_more': 'View More',
      'activity_log': 'Activity Log', 'points': 'Points', 'close': 'Close',
      'latest_activity': 'Location:',
    },
    'ID': {
      'home': 'Beranda', 'explore': 'Telusuri', 'analytics': 'Analitik',
      'ranking': 'Peringkat', 'visitor_on': 'Mode Pengunjung Diaktifkan',
      'visitor_off': 'Mode Pengunjung Dinonaktifkan', 'update_failed': 'Gagal Memperbarui',
      'recent_findings': 'Temuan Terbaru', 'view_more': 'Lihat Detail',
      'activity_log': 'Log Aktivitas', 'points': 'Poin', 'close': 'Tutup',
      'latest_activity': 'Terbaru:',
    },
    'ZH': {
      'home': '主页', 'explore': '探索', 'analytics': '分析', 'ranking': '排名',
      'visitor_on': '访客模式已激活', 'visitor_off': '访客模式已停用',
      'update_failed': '更新失败', 'recent_findings': '最新发现',
      'view_more': '查看更多', 'activity_log': '活动日志', 'points': '积分',
      'close': '关闭', 'latest_activity': '最新活动:',
    },
  };

  String getTxt(String key) => _navText[_lang]?[key] ?? key;

  // ── Helper config teks ──
  String _getLoginConfig(String tipe, int poin) {
    final isEN = _lang == 'EN';
    final isZH = _lang == 'ZH';
    switch (tipe) {
      case 'login_pertama_hari_ini':
        return isEN ? 'Congratulations! You are the first to login today: +$poin points'
            : isZH ? '恭喜！您今天第一个登录：+$poin积分'
            : 'Selamat! Anda orang pertama yang login hari ini: +$poin poin';
      case 'login_harian':
        return isEN ? 'Daily login bonus: +$poin points'
            : isZH ? '每日登录奖励：+$poin积分'
            : 'Bonus login harian: +$poin poin';
      default:
        return 'Poin: +$poin';
    }
  }

  bool get _isVerifRole =>
      _userRole.toLowerCase().contains('verif') || _userRole == '验证者';

  @override
  void initState() {
    super.initState();

    _lifecycleObserver = _AppLifecycleObserver(onResume: () {
      if (!mounted) return;
      final prevPoin = _userPoin;
      _fetchUserData(silent: true).then((_) {
        if (mounted && _userPoin != prevPoin) _animatePoinUpdate(_userPoin);
      });
    });
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    _applyInitialData();
    _fetchAppLogo();

    _checkVerificationStatus().then((_) async {
      if (!mounted) return;
      await Future.wait([
        _loadLanguage(),
        if (widget.initialIsVerificator == null) _checkExecutiveVerificatorStatus(),
      ]);
      if (mounted) _handleLoginAndFetchData();
    });
  }

  Future<void> _fetchAppLogo() async {
    try {
      final res = await _sb
          .from('app_info')
          .select('logo_url')
          .order('id')
          .limit(1)
          .maybeSingle();
      final url = res?['logo_url'] as String?;
      if (mounted && url != null && url.isNotEmpty) {
        setState(() => _appLogoUrl = url);
        precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
      }
    } catch (e) {
      debugPrint('Error fetching app logo: $e');
    }
  }

  // ── Pisahkan logika initState agar lebih bersih ──
  void _applyInitialData() {
    if (widget.initialUserName == null) return;

    _userName = widget.initialUserName!;
    _userPoin = widget.initialUserPoin ?? 0;
    _displayedPoin = _userPoin;
    _userImage = widget.initialUserImage;
    _isUserDataLoading = false;

    if (widget.initialUserImage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          precacheImage(CachedNetworkImageProvider(widget.initialUserImage!), context);
        }
      });
    }

    final bool initIsVerif = widget.initialIsVerificator == true;
    final bool isActualVerificator = initIsVerif &&
        (widget.initialUserRole?.toLowerCase().contains('verif') == true ||
            widget.initialUserRole == null);

    _userRole = isActualVerificator
        ? JabatanHelper.getDisplayRole(
            isVerificatorFlag: true,
            idJabatan: widget.initialUserJabatanId,
            jabatanFromDb: widget.initialUserRole,
            lang: _lang,
          )
        : widget.initialUserRole ?? 'Staff';

    if (widget.initialUserLocation != null) _userLocationName = widget.initialUserLocation!;
    if (widget.initialUserLocationLevel != null) _userLocationLevel = widget.initialUserLocationLevel;
    if (widget.initialLatestLog != null) {
      _latestLogPoin = widget.initialLatestLog;
      _isLatestLogLoading = false;
    } else {
      _isLatestLogLoading = false;
    }
    if (widget.initialUserJabatanId != null) _userJabatanId = widget.initialUserJabatanId;
    if (widget.initialIsVerificator != null) _isExecutiveVerificator = widget.initialIsVerificator!;
    if (widget.initialNotifCount != null) _notificationCount = widget.initialNotifCount!;
    if (widget.initialMonthlyPoin != null) _initialMonthlyPoin = widget.initialMonthlyPoin!;

    if (widget.initialIsProMode != null) _isProMode = widget.initialIsProMode!;
    if (widget.initialIsVisitorMode != null) _isVisitorMode = widget.initialIsVisitorMode!;
    if (widget.initialIsProMode != null || widget.initialIsVisitorMode != null) {
      _isLoadingVisitorStatus = false;
    }
    if (widget.initialIsPreventiveMaintenanceVisible != null) {
      _isPreventiveMaintenanceVisible = widget.initialIsPreventiveMaintenanceVisible!;
    }
    if (widget.initialPendingAudits != null) _initialPendingAudits = widget.initialPendingAudits;
  }

  @override
  void dispose() {
    if (_pointChannel != null) _sb.removeChannel(_pointChannel!);
    WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    super.dispose();
  }

  Future<void> _checkLocationAccess() async {
    setState(() => _isCheckingLocation = false);

    final currentPermission = await Geolocator.checkPermission();
    final bool alreadyDecided = currentPermission == LocationPermission.always ||
        currentPermission == LocationPermission.whileInUse;

    if (!alreadyDecided) {
      if (mounted) setState(() => _isAtAtmi = false);
      debugPrint('📍 Location not yet decided — skip silent check, popup will show on user action.');
      return;
    }

    final result = await LocationService.instance.checkUserAtAtmi();
    if (!mounted) return;
    setState(() => _isAtAtmi = result.isAtAtmi);
    debugPrint('📍 Background location check: isAtAtmi=$_isAtAtmi');
  }

  // ── Point animation ──
  void _animatePoinUpdate(int newPoin) {
    if (_isAnimatingPoin) {
      setState(() { _displayedPoin = newPoin; _isAnimatingPoin = false; });
      return;
    }
    if (_displayedPoin == newPoin) {
      setState(() => _displayedPoin = newPoin);
      return;
    }
    _isAnimatingPoin = true;
    final int start = _displayedPoin;
    final int diff = newPoin - start;
    final int steps = diff.abs().clamp(1, 30);
    final double step = diff / steps;
    int current = 0;

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 40));
      current++;
      if (mounted) {
        setState(() {
          _displayedPoin = (start + step * current).round();
          if (current >= steps) { _displayedPoin = newPoin; _isAnimatingPoin = false; }
        });
      }
      return current < steps && mounted && _isAnimatingPoin;
    });
  }

  // ── Point listener (realtime) ──
  void _setupPointListener() {
    final user = _sb.auth.currentUser;
    if (user == null) return;

    _pointChannel = _sb
        .channel('log_poin_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'log_poin',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_user',
            value: user.id,
          ),
          callback: (payload) async {
            if (!mounted) return;
            final newLog = payload.newRecord;
            final int points = (newLog['poin'] as num).toInt();
            final String description = newLog['deskripsi']?.toString() ?? '';
            final String tipe = newLog['tipe_aktivitas']?.toString() ?? '';

            if (points == 0) return;

            _fetchUserData(silent: true);

            if (_loginTipes.contains(tipe)) {
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) _fetchUserData(silent: true);
              return;
            }

            if (_verifTipes.contains(tipe)) {
              await Future.delayed(const Duration(milliseconds: 800));
              if (!mounted) return;
              setState(() {
                _initialMonthlyPoin = null;
                _latestLogPoin = {
                  'poin': points,
                  'deskripsi': description,
                  'tipe_aktivitas': tipe,
                };
              });
              await _fetchUserData(silent: true);
              return;
            }

            // ── terima_poin_berbagi ──
            if (tipe == 'terima_poin_berbagi') {
              await Future.delayed(const Duration(milliseconds: 800));
              if (!mounted) return;

              final notifTitle = _lang == 'EN'
                  ? '🎁 You received shared points!'
                  : _lang == 'ZH'
                      ? '🎁 您收到了分享积分！'
                      : '🎁 Kamu menerima poin berbagi!';

              NotificationService.instance.showNotification(
                title: notifTitle,
                body: description,
              );

              _sendFcmToCurrentUser(
                title: notifTitle,
                body: description,
                route: 'activity',
              );

              setState(() {
                _initialMonthlyPoin = null;
                _latestLogPoin = {
                  'poin': points,
                  'deskripsi': description,
                  'tipe_aktivitas': tipe,
                };
              });
              await _fetchUserData(silent: true);
              return;
            }

            if (tipe == 'bonus_berbagi') {
              await Future.delayed(const Duration(milliseconds: 800));
              if (!mounted) return;

              final notifTitle = _lang == 'EN'
                  ? '🔥 Sharing Bonus Received!'
                  : _lang == 'ZH'
                      ? '🔥 分享奖励已获得！'
                      : '🔥 Bonus Berbagi Diterima!';

              NotificationService.instance.showNotification(
                title: notifTitle,
                body: description,
              );

              _sendFcmToCurrentUser(
                title: notifTitle,
                body: description,
                route: 'activity',
              );

              setState(() {
                _initialMonthlyPoin = null;
                _latestLogPoin = {
                  'poin': points,
                  'deskripsi': description,
                  'tipe_aktivitas': tipe,
                };
              });
              await _fetchUserData(silent: true);
              return;
            }

            _pendingPointNotif = _PendingPointNotif(
              points: points,
              description: description,
              tipe: tipe,
            );
            await Future.delayed(const Duration(milliseconds: 1500));
            if (!mounted) return;
            await _fetchUserData(silent: true);
            if (mounted) _tryShowPendingNotif();
          },
        )
        .subscribe();
  }

  /// Ambil fcm_token user login saat ini lalu kirim FCM push notif
  Future<void> _sendFcmToCurrentUser({
    required String title,
    required String body,
    String? route,
  }) async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return;
      final userData = await _sb
          .from('User')
          .select('fcm_token')
          .eq('id_user', userId)
          .maybeSingle();
      final fcmToken = userData?['fcm_token']?.toString();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await NotificationService.sendFcmToToken(
          fcmToken: fcmToken,
          title: title,
          body: body,
          route: route,
        );
        debugPrint('✅ FCM sent to current user');
      } else {
        debugPrint('⚠️ Current user has no FCM token');
      }
    } catch (e) {
      debugPrint('❌ _sendFcmToCurrentUser error: $e');
    }
  }

  void _tryShowPendingNotif() async {
    if (_pendingPointNotif == null || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _pendingPointNotif == null) return;

    final notif = _pendingPointNotif!;
    _pendingPointNotif = null;

    NotificationService.instance.showNotification(
      title: notif.points > 0 ? '🎉 Poin Diterima!' : '⚠️ Poin Dikurangi',
      body: notif.description,
    );

    if (notif.points < 0) {
      showPenaltyDialog(context, points: notif.points, description: notif.description, lang: _lang);
    } else {
      _showPointNotificationDialog(notif.points, notif.description, notif.tipe);
    }
  }

  void _showPointNotificationDialog(int points, String description, String tipe) {
    if (points == 0) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => _PointNotifDialog(
        points: points, description: description, tipe: tipe, lang: _lang,
        onDismiss: () { if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(); },
      ),
    );
  }

  // ── Fetch data paralel untuk mengurangi latency ──
  Future<void> _handleLoginAndFetchData() async {
    final user = _sb.auth.currentUser;
    if (user == null) return;

    if (!kIsWeb) {
      NotificationService.instance.saveFcmTokenAfterLogin();
    }

    // Load Preventive Maintenance visibility
    try {
      final row = await _sb
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', 'preventive_maintenance_visible')
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isPreventiveMaintenanceVisible =
              row?['setting_value'] as bool? ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading preventive_maintenance_visible: $e');
      if (mounted) {
        setState(() => _isPreventiveMaintenanceVisible = true);
      }
    }

    // Cek lokasi di background (tidak blokir masuk home)
    await _checkLocationAccess();

    if (_pointChannel == null) _setupPointListener();

    // Jalankan semua fetch paralel
    await Future.wait([
      _fetchUserData(),
      _fetchNotificationCount(),
      _loadInitialVisitorStatus(),
    ]);

    // Guard: jika sudah pernah diproses di sesi ini, skip
    if (_hasShownLoginDialog) return;
    _hasShownLoginDialog = true;

    // ── Jika tidak di lokasi ATMI: skip semua login poin & penalti ──
    if (!_isAtAtmi) {
      debugPrint('📍 Not at ATMI — skipping login points/penalty.');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) await HomeNewsPopup.showIfNeeded(context, lang: _lang);
      return;
    }

    if (!mounted) return;

    try {
      final dynamic raw = await _sb.rpc(
        'handle_daily_login', params: {'p_user_id': user.id},
      );

      if (!mounted || raw == null) return;

      final result = raw is List
          ? (raw.isNotEmpty
              ? Map<String, dynamic>.from(raw.first)
              : <String, dynamic>{})
          : Map<String, dynamic>.from(raw);

      final String status = result['status']?.toString() ?? '';

      if (status == 'already_logged_in_today' || status.isEmpty) {
        _fetchUserData(silent: true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) await HomeNewsPopup.showIfNeeded(context, lang: _lang);
        return;
      }

      final int dailyBonus =
          (result['daily_bonus'] as num?)?.toInt() ?? 0;
      final int penalty = (result['penalty'] as num?)?.toInt() ?? 0;
      final int firstTodayBonus =
          (result['first_today_bonus'] as num?)?.toInt() ?? 0;
      final bool isFirstToday =
          result['is_first_today'] as bool? ?? false;
      final String message = result['message']?.toString() ?? '';

      if (!mounted) return;

      // ── Kasus: login pertama kali seumur hidup ──
      if (status == 'first_ever_login') {
        _fetchUserData(silent: true);
        await showLoginPointDialog(
          context,
          points: dailyBonus,
          description: message,
          lang: _lang,
          userId: user.id,
          userLokasiId: _userLokasiId,
          onClaimed: () => _fetchUserData(silent: true),
          onClaimedAndShared: (receiverUser) async {
            await handleSharePoints(context, receiverUser: receiverUser, lang: _lang);
            _fetchUserData(silent: true);
          },
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) await HomeNewsPopup.showIfNeeded(context, lang: _lang);
        return;
      }

      // ── Tampilkan penalti dulu jika ada ──
      if (penalty > 0) {
        final int daysAbsent =
            (result['days_absent'] as num?)?.toInt() ?? 0;
        final String penaltyMsg = _lang == 'EN'
            ? 'Penalty for not logging in $daysAbsent days: -$penalty points'
            : _lang == 'ZH'
                ? '未登录$daysAbsent天的罚分：-$penalty积分'
                : 'Penalti tidak login $daysAbsent hari: -$penalty poin';
        _fetchUserData(silent: true);
        await showPenaltyDialog(
          context,
          points: -penalty,
          description: penaltyMsg,
          lang: _lang,
          waitForDismiss: true,
        );
        if (!mounted) return;
        _fetchUserData(silent: true);
      }

      // ── Tampilkan bonus pertama hari ini (PRIORITAS, sebelum harian) ──
      if (isFirstToday && firstTodayBonus > 0) {
        if (!mounted) return;
        _fetchUserData(silent: true);
        await showLoginPointDialog(
          context,
          points: firstTodayBonus,
          description: _getLoginConfig('login_pertama_hari_ini', firstTodayBonus),
          lang: _lang,
          userId: user.id,
          userLokasiId: _userLokasiId,
          onClaimed: () => _fetchUserData(silent: true),
          onClaimedAndShared: (receiverUser) async {
            await handleSharePoints(context, receiverUser: receiverUser, lang: _lang);
            _fetchUserData(silent: true);
          },
        );
        if (!mounted) return;
      }

      // ── Tampilkan bonus login harian ──
      if (dailyBonus > 0) {
        if (!mounted) return;
        _fetchUserData(silent: true);
        await showLoginPointDialog(
          context,
          points: dailyBonus,
          description: _getLoginConfig('login_harian', dailyBonus),
          lang: _lang,
          userId: user.id,
          userLokasiId: _userLokasiId,
          onClaimed: () => _fetchUserData(silent: true),
          onClaimedAndShared: (receiverUser) async {
            await handleSharePoints(context, receiverUser: receiverUser, lang: _lang);
            _fetchUserData(silent: true);
          },
        );
      }

      // ── Tampilkan news popup setelah semua dialog selesai ──
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) await HomeNewsPopup.showIfNeeded(context, lang: _lang);
    } catch (e) {
      debugPrint('Error handling daily login points: $e');
    }
  }

  // ── No-op: kept for consistency, logic moved to _checkExecutiveVerificatorStatus ──
  Future<void> _checkVerificationStatus() async {}

  Future<void> _checkExecutiveVerificatorStatus() async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _sb
          .from('User')
          .select('id_jabatan, is_verificator')
          .eq('id_user', userId)
          .single();
      final bool isVerif = data['is_verificator'] as bool? ?? false;
      final int? idJabatan = data['id_jabatan'] as int?;
      if (mounted) {
        setState(() {
          _isExecutiveVerificator = isVerif || idJabatan == 1 || idJabatan == 2 || idJabatan == 5;
        });
      }
    } catch (e) {
      debugPrint('Error checking exec verificator: $e');
    }
  }

  Future<void> _fetchNotificationCount({bool silent = false}) async {
    if (silent && _notificationCount == 0 && _hasShownLoginDialog) return;

    if (!mounted) return;
    final user = _sb.auth.currentUser;
    if (user == null) return;
    try {
      final count = await _sb
          .from('temuan')
          .count(CountOption.exact)
          .eq('id_penanggung_jawab', user.id)
          .neq('status_temuan', 'Selesai');
      if (mounted) setState(() => _notificationCount = count);
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  Future<Map<String, dynamic>> _prefetchNotificationData() async {
    final user = _sb.auth.currentUser;
    if (user == null) return {'findings': [], 'logs': []};

    final results = await Future.wait([
      _sb
          .from('temuan')
          .select(
            'id_temuan, judul_temuan, gambar_temuan, created_at, '
            'status_temuan, poin_temuan, target_waktu_selesai, '
            'jenis_temuan, id_lokasi, id_unit, id_subunit, id_area, '
            'id_penanggung_jawab, is_pro, is_visitor, is_eksekutif, '
            'lokasi(nama_lokasi), unit(nama_unit), '
            'subunit(nama_subunit), area(nama_area)',
          )
          .eq('id_penanggung_jawab', user.id)
          .order('created_at', ascending: false),
      _sb
          .from('log_poin')
          .select('poin, deskripsi, tipe_aktivitas, created_at')
          .eq('id_user', user.id)
          .gte('created_at',
              DateTime(DateTime.now().year, DateTime.now().month, 1)
                  .toIso8601String())
          .lte('created_at',
              DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59)
                  .toIso8601String())
          .order('created_at', ascending: false),
    ]);

    return {
      'findings': List<Map<String, dynamic>>.from(results[0] as List),
      'logs': List<Map<String, dynamic>>.from(results[1] as List),
    };
  }

  Future<void> _loadInitialVisitorStatus() async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _sb
          .from('User')
          .select('is_visitor, is_pro_mode')
          .eq('id_user', userId)
          .single();
      if (mounted) {
        setState(() {
          _isVisitorMode = data['is_visitor'] ?? false;
          _isProMode = data['is_pro_mode'] ?? false;
          _isLoadingVisitorStatus = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading visitor status: $e');
      if (mounted) setState(() => _isLoadingVisitorStatus = false);
    }
  }

  Future<void> _updateVisitorStatus(bool isVisitor) async {
    setState(() => _isVisitorMode = isVisitor);
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return;
      await _sb.from('User').update({'is_visitor': isVisitor}).eq('id_user', userId);
      showVisitorStatusDialog(context, isVisitor, _lang);
    } catch (e) {
      debugPrint('Error updating visitor status: $e');
      _showCustomDialog(title: getTxt('update_failed'), imagePath: 'assets/images/failed.png');
    }
  }

  Future<void> _updateProModeStatus(bool isPro) async {
    setState(() => _isProMode = isPro);
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) return;
      await _sb.from('User').update({'is_pro_mode': isPro}).eq('id_user', userId);
      showProModeStatusDialog(context, isPro, _lang);
    } catch (e) {
      debugPrint('Error updating pro mode status: $e');
      _showCustomDialog(title: getTxt('update_failed'), imagePath: 'assets/images/failed.png');
    }
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _lang = prefs.getString('lang') ?? 'EN');
  }

  // ── Fetch user data: paralel query untuk lokasi ──
  Future<void> _fetchUserData({bool silent = false}) async {
    if (!silent && widget.initialUserName == null && mounted) {
      setState(() { _isUserDataLoading = true; _isLatestLogLoading = true; _latestLogPoin = null; });
    }
    try {
      final userAuth = _sb.auth.currentUser;
      if (userAuth == null) return;

      // Fetch user row dan seluruh log_poin bulan ini secara paralel
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final startOfNextMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

      final results = await Future.wait([
        _sb.from('User')
            .select('nama, email, poin, gambar_user, id_jabatan, id_unit, id_lokasi, id_subunit, id_area, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)')
            .eq('id_user', userAuth.id)
            .maybeSingle(),
        _sb.from('log_poin')
            .select('poin, deskripsi, tipe_aktivitas, created_at')
            .eq('id_user', userAuth.id)
            .gte('created_at', startOfMonth)
            .lt('created_at', startOfNextMonth)
            .order('created_at', ascending: false),
      ]);

      final userRow = results[0] as Map<String, dynamic>?;
      final logRows = results[1] as List<dynamic>;

      final String? metaName = userAuth.userMetadata?['full_name'] ?? userAuth.userMetadata?['name'];
      final String? metaImage = userAuth.userMetadata?['avatar_url'] ?? userAuth.userMetadata?['picture'];

      if (userRow == null) {
        if (!mounted) return;
        setState(() {
          _userName = metaName ?? 'User';
          _userPoin = 0; _displayedPoin = 0;
          _userImage = metaImage; _userRole = 'Staff';
          _userLocationName = '...'; _isUserDataLoading = false;
        });
        return;
      }

      // Resolusi lokasi — cari dari level paling spesifik
      final locationData = await _resolveLocationName(userRow);

      final bool isVerifFromDb = userRow['is_verificator'] as bool? ?? false;
      final int? jabatanId = userRow['id_jabatan'] as int?;

      final String roleName = isVerifFromDb
          ? JabatanHelper.getDisplayRole(
              isVerificatorFlag: true,
              idJabatan: jabatanId,
              jabatanFromDb: userRow['jabatan']?['nama_jabatan'],
              lang: _lang,
            )
          : (userRow['jabatan']?['nama_jabatan'] ?? 'Staff');

      String? dbImage = userRow['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      final Map<String, dynamic>? latestLog =
          logRows.isNotEmpty ? logRows.first as Map<String, dynamic> : null;
      final List<Map<String, dynamic>> monthlyLogs =
          List<Map<String, dynamic>>.from(logRows);

      if (!mounted) return;
      final int newPoin = (userRow['poin'] as num?)?.toInt() ?? 0;
      final bool shouldAnimate = newPoin != _displayedPoin && !_isAnimatingPoin;

      setState(() {
        _userName = userRow['nama'] ?? metaName ?? 'User';
        _userPoin = newPoin;
        _userImage = dbImage ?? metaImage;
        _userRole = roleName;
        _isExecutiveVerificator = isVerifFromDb || jabatanId == 1 || jabatanId == 2 || jabatanId == 5;
        _userJabatanId = jabatanId;
        _userUnitId = userRow['id_unit']?.toString();
        _userLokasiId = userRow['id_lokasi']?.toString();
        _userLocationName = locationData['name']!;
        _userLocationLevel = locationData['level'];
        if (latestLog != null) _latestLogPoin = latestLog;
        _monthlyActivityLogs = monthlyLogs;
        _isLatestLogLoading = false;
        _isUserDataLoading = false;
        if (!shouldAnimate) _displayedPoin = newPoin;
      });

      if (shouldAnimate) _animatePoinUpdate(newPoin);
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _userLocationName = 'Gagal memuat';
          _isUserDataLoading = false;
          _isLatestLogLoading = false;
        });
      }
    }
  }

  // ── Resolusi lokasi (helper terpisah) ──
  Future<Map<String, String>> _resolveLocationName(Map<String, dynamic> userRow) async {
    final idArea = userRow['id_area'];
    final idSubunit = userRow['id_subunit'];
    final idUnit = userRow['id_unit'];
    final idLokasi = userRow['id_lokasi'];

    try {
      if (idArea != null) {
        final d = await _sb.from('area').select('nama_area').eq('id_area', idArea).maybeSingle();
        return {'name': d?['nama_area'] ?? '...', 'level': 'area'};
      } else if (idSubunit != null) {
        final d = await _sb.from('subunit').select('nama_subunit').eq('id_subunit', idSubunit).maybeSingle();
        return {'name': d?['nama_subunit'] ?? '...', 'level': 'subunit'};
      } else if (idUnit != null) {
        final d = await _sb.from('unit').select('nama_unit').eq('id_unit', idUnit).maybeSingle();
        return {'name': d?['nama_unit'] ?? '...', 'level': 'unit'};
      } else if (idLokasi != null) {
        final d = await _sb.from('lokasi').select('nama_lokasi').eq('id_lokasi', idLokasi).maybeSingle();
        return {'name': d?['nama_lokasi'] ?? '...', 'level': 'lokasi'};
      }
    } catch (_) {}
    return {'name': '...', 'level': 'lokasi'};
  }

  void _showActivityLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ActivityLogDialog(
        lang: _lang,
        userName: _userName,
        userRole: _userRole,
        userImage: _userImage,
        userPoin: _userPoin,
        userJabatanId: _userJabatanId,
        isVerificator: _isVerifRole,
        initialLogs: _monthlyActivityLogs,
      ),
    );
  }

  // ── Callback setelah temuan tersimpan ──
  Future<void> _onFindingSaved() async {
    if (!mounted) return;
    setState(() {
      _currentIndex = 0;
      _isUserDataLoading = true;
      _isLatestLogLoading = true;
      _latestLogPoin = null;
    });
    await Future.wait([_fetchUserData(silent: false), _fetchNotificationCount(silent: true)]);
    if (!mounted) return;
    _homeContentKey.currentState?.refreshFindings();
    _animatePoinUpdate(_userPoin);
    _tryShowPendingNotif();
  }

  /// Tampilkan dialog ketika user mencoba aksi yang butuh lokasi ATMI
  /// [actionKey]: 'new_finding' | 'resolution'
  void _showLocationBlockedDialog({required String actionKey}) {
    const Color primaryColor = Color(0xFF1D72F3);

    final Map<String, Map<String, String>> texts = {
      'EN': {
        'title': 'You must be at PT ATMI Solo',
        'new_finding':
            'Creating a new finding is only allowed within the PT ATMI Solo area.',
        'resolution':
            'Submitting a resolution is only allowed within the PT ATMI Solo area.',
        'ok': 'Understood',
      },
      'ID': {
        'title': 'Harus Berada di PT ATMI Solo',
        'new_finding':
            'Membuat temuan baru hanya dapat dilakukan di dalam area PT ATMI Solo.',
        'resolution':
            'Membuat penyelesaian hanya dapat dilakukan di dalam area PT ATMI Solo.',
        'ok': 'Mengerti',
      },
      'ZH': {
        'title': '您必须在PT ATMI Solo区域内',
        'new_finding': '只能在PT ATMI Solo区域内创建新发现。',
        'resolution': '只能在PT ATMI Solo区域内提交解决方案。',
        'ok': '明白',
      },
    };

    final t = texts[_lang] ?? texts['ID']!;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: primaryColor),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF64B5F6), primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_off_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t['title']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t[actionKey] ?? '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          t['ok']!,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
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
  }

  void _showCustomDialog({required String title, required String imagePath}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(imagePath, height: 100, width: 100,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error_outline, size: 80, color: Colors.red)),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {

    final pages = [
      _buildHomeContent(),
      ExploreScreen(lang: _lang),
      AnalyticsScreen(lang: _lang),
      RankingScreen(lang: _lang),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBody: false, // agar konten tidak terpotong navbar bawaan HP
      body: Stack(
        children: [
          _buildBgBlob(top: -100, left: -50, size: 350, opacity: 0.25),
          _buildBgBlob(bottom: 50, right: -100, size: 400, opacity: 0.20),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 5),
                Expanded(child: pages[_currentIndex]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBgBlob({
    double? top, double? bottom, double? left, double? right,
    required double size, required double opacity,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            const Color(0xFF00C9E4).withValues(alpha:opacity),
            Colors.transparent,
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D72F3).withValues(alpha:0.15),
            blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          (_appLogoUrl != null && _appLogoUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: _appLogoUrl!,
                  height: 38,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Image(
                    image: AssetImage('assets/images/logo1.png'),
                    height: 38,
                    gaplessPlayback: true,
                  ),
                  errorWidget: (_, __, ___) => const Image(
                    image: AssetImage('assets/images/logo1.png'),
                    height: 38,
                    gaplessPlayback: true,
                  ),
                )
              : Image(
                  image: const AssetImage('assets/images/logo1.png'),
                  height: 38,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D72F3).withValues(alpha:0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield, color: Color(0xFF1D72F3), size: 26),
                  ),
                ),
          Row(
            children: [
              _buildNotifButton(),
              const SizedBox(width: 10),
              _buildProfileButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotifButton() {
    return GestureDetector(
      onTap: () async {
        if (_isOpeningNotif) return;
        _isOpeningNotif = true;

        if (mounted) {
          setState(() => _notificationCount = 0);
        }

        try {
          final prefetched = await _prefetchNotificationData();
          if (!mounted) return;

          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => NotificationScreen(
                lang: _lang,
                initialFindings: prefetched['findings'],
                initialActivityLogs: prefetched['logs'],
              ),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        } finally {
          _isOpeningNotif = false;
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF1D72F3).withValues(alpha:0.08),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha:0.2)),
            ),
            child: const Icon(Icons.mail_outlined, color: Color(0xFF1E3A8A), size: 22),
          ),
          if (_notificationCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    _notificationCount > 9 ? '9+' : _notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => AccountScreen(
              lang: _lang,
              initialUserName: _userName,
              initialUserImage: _userImage,
              initialUserRole: _userRole,
              initialIsVisitor: _isVisitorMode,
              initialUserJabatanId: _userJabatanId,
              initialUserLocation: _userLocationName,
              initialUserLocationLevel: _userLocationLevel,
              initialIsVerificator: _isVerifRole,
            ),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) {
          _loadLanguage();
          _handleLoginAndFetchData();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF1D72F3), Color(0xFF4ADE80)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D72F3).withValues(alpha:0.3),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF1D72F3),
            backgroundImage: _userImage != null ? CachedNetworkImageProvider(_userImage!) : null,
            child: _userImage == null ? const Icon(Icons.person, color: Colors.white, size: 18) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final mq = MediaQuery.of(context);
    final double rawInset = mq.viewPadding.bottom > mq.padding.bottom
        ? mq.viewPadding.bottom
        : mq.padding.bottom;
    final double bottomInset = rawInset > 0 ? rawInset : 12;

    const double barContentHeight = 65;
    final double totalHeight = barContentHeight + bottomInset;

    return Container(
      height: totalHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D72F3).withValues(alpha:0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: barContentHeight,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0, getTxt('home')),
                _buildNavItem(Icons.explore_outlined, Icons.explore, 1, getTxt('explore')),
                const SizedBox(width: 56), // ruang tombol +
                _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 2, getTxt('analytics')),
                _buildNavItem(Icons.emoji_events_outlined, Icons.emoji_events, 3, getTxt('ranking')),
              ],
            ),
          ),
          // ── Tombol + tetap center terhadap baris ikon (bukan terhadap total tinggi) ──
          Positioned(
            top: 0,
            child: SizedBox(
              height: barContentHeight,
              child: Center(
                child: GestureDetector(
                  onTap: _openLocationSheet,
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D72F3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D72F3).withValues(alpha:0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLocationSheet() async {
    // Cegah double bottom sheet jika sudah ada yang terbuka
    if (!mounted) return;

    // Cek lokasi fresh sebelum buat temuan baru
    final result = await LocationPermissionPopup.requestWithPopup(context, lang: _lang);

    if (!mounted) return;
    setState(() => _isAtAtmi = result.isAtAtmi);

    if (!result.isAtAtmi) {
      _showLocationBlockedDialog(actionKey: 'new_finding');
      return;
    }

    // Tutup bottom sheet yang mungkin sudah terbuka sebelumnya
    Navigator.of(context).popUntil((route) => route.isFirst || route is! ModalBottomSheetRoute);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => LocationBottomSheet(
        lang: _lang,
        isProMode: _isProMode,
        isVisitorMode: _isVisitorMode,
        userUnitId: _userUnitId,
        userLokasiId: _userLokasiId,
        userRole: _userRole,
        onFindingSaved: _onFindingSaved,
      ),
    ).then((isSuccess) {
      if (isSuccess == true) _onFindingSaved();
    });
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index, String label) {
  final bool isActive = _currentIndex == index;
  const Color activeColor = Color(0xFF1D72F3);
  return GestureDetector(
    onTap: () => setState(() => _currentIndex = index),
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 64,
      height: 65,
      child: Transform.translate(
        offset: const Offset(0, 6), // geser visual ke bawah, tidak memakan ruang layout
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(isActive ? 7 : 0),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? filledIcon : outlineIcon,
                size: 24,
                color: isActive ? activeColor : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHomeContent() {
    return HomeContent(
      key: _homeContentKey,
      lang: _lang,
      isProMode: _isProMode,
      isVisitorMode: _isVisitorMode,
      isUserDataLoading: _isUserDataLoading,
      isAtAtmi: _isAtAtmi,
      userName: _userName,
      userRole: _userRole,
      userLocationName: _userLocationName,
      userPoin: _userPoin,
      displayedPoin: _displayedPoin,
      userImage: _userImage,
      userUnitId: _userUnitId,
      userLokasiId: _userLokasiId,
      latestLogPoin: _latestLogPoin,
      isLatestLogLoading: _isLatestLogLoading,
      onRefresh: () async {
        final int prev = _userPoin;
        setState(() => _initialMonthlyPoin = null);
        await _fetchUserData(silent: true);
        if (mounted && _userPoin != prev) _animatePoinUpdate(_userPoin);
        _tryShowPendingNotif();
      },
      onRequestRefresh: () => setState(() => _currentIndex = 1),
      onViewActivityLog: () => _showActivityLogDialog(context),
      onProModeChanged: _updateProModeStatus,
      onVisitorModeChanged: _updateVisitorStatus,
      isExecVerificator: _isExecutiveVerificator,
      userJabatanId: _userJabatanId,
      onVerifPointEarned: (int earned) {
        final int newPoin = _userPoin + earned;
        setState(() => _userPoin = newPoin);
        _animatePoinUpdate(newPoin);
      },
      shouldRefreshFindings: _findingsRefreshTrigger != _lastRefreshTrigger,
      onRefreshDone: () => setState(() => _lastRefreshTrigger = _findingsRefreshTrigger),
      isPreventiveMaintenanceVisible: _isPreventiveMaintenanceVisible && (_userJabatanId == 1 || _userJabatanId == 3),
      initialPendingAudits: _initialPendingAudits,
      buildInfoCard: () => UserInfoCard(
        userName: _userName,
        userRole: _userRole,
        userImage: _userImage,
        userPoin: _userPoin,
        userLocationName: _userLocationName,
        userLocationLevel: _userLocationLevel,
        latestLogPoin: _latestLogPoin,
        isLatestLogLoading: _isLatestLogLoading,
        lang: _lang,
        isVerificator: _isVerifRole,
        userJabatanId: _userJabatanId,
        initialMonthlyPoin: _initialMonthlyPoin,
        onViewMoreTap: () => _showActivityLogDialog(context),
      ),
    );
  }
}

// ── Helper: pending notif ──
class _PendingPointNotif {
  final int points;
  final String description;
  final String tipe;
  const _PendingPointNotif({required this.points, required this.description, required this.tipe});
}

// ── Helper: lifecycle observer ──
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  _AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

// ============================================================
// DIALOG: POINT NOTIF (realtime)
// ============================================================
class _PointNotifDialog extends StatefulWidget {
  final int points;
  final String description;
  final String tipe;
  final String lang;
  final VoidCallback onDismiss;

  const _PointNotifDialog({
    required this.points, required this.description, required this.tipe,
    required this.lang, required this.onDismiss,
  });

  @override
  State<_PointNotifDialog> createState() => _PointNotifDialogState();
}

class _PointNotifDialogState extends State<_PointNotifDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim, _fadeAnim, _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 50, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 4500), () { if (mounted) widget.onDismiss(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  bool get _isPositive => widget.points > 0;

  Color get _primary {
    if (!_isPositive) return const Color(0xFFDC2626);
    switch (widget.tipe) {
      case 'login_pertama': return const Color(0xFFEC4899);
      case 'login_pertama_hari_ini': return const Color(0xFFF59E0B);
      default: return const Color(0xFF16A34A);
    }
  }

  IconData get _icon {
    switch (widget.tipe) {
      case 'login_pertama': return Icons.celebration_rounded;
      case 'login_harian': return Icons.today_rounded;
      case 'login_pertama_hari_ini': return Icons.emoji_events_rounded;
      default: return _isPositive ? Icons.local_fire_department_rounded : Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = _primary;
    final String pointLabel = _isPositive ? '+${widget.points}' : '${widget.points}';

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Transform.scale(scale: _scaleAnim.value, child: child),
        ),
      ),
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: primary.withValues(alpha:0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(color: primary.withValues(alpha:0.2), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha:0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(children: [
                      _PulsingRing(
                        color: primary,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha:0.12), shape: BoxShape.circle,
                            border: Border.all(color: primary.withValues(alpha:0.3), width: 2),
                          ),
                          child: Icon(_icon, color: primary, size: 36),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(50)),
                        child: Text('$pointLabel Poin',
                            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                    child: Column(children: [
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha:0.06), borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primary.withValues(alpha:0.12)),
                        ),
                        child: Text(widget.description, textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E3A8A), height: 1.6)),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 0.0),
                          duration: const Duration(milliseconds: 4500),
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v, minHeight: 3,
                            backgroundColor: primary.withValues(alpha:0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(primary.withValues(alpha:0.45)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.lang == 'EN' ? 'Tap anywhere to close'
                            : widget.lang == 'ZH' ? '点击任意处关闭'
                            : 'Ketuk di mana saja untuk menutup',
                        style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade400),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pulsing ring ──
class _PulsingRing extends StatefulWidget {
  final Color color;
  final Widget child;
  const _PulsingRing({required this.color, required this.child});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _anim.value,
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha:0.08 * (2.0 - _anim.value)),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}