import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/jabatan_helper.dart';
import '../../shared/account/account_screen.dart';
import '../explore/explore_screen.dart';
import '../analytics/analytics_screen.dart';
import '../../shared/notifications/notification_screen.dart';
import '../../shared/code/qr_scanner_screen.dart';
import '../leaderboard/ranking_screen.dart';
import '../finding/camera_finding_screen.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_news_popup.dart';
import 'user_info_card.dart';
import 'activity_log_dialog.dart';
import 'home_content.dart';

// Supabase shorthand
final _sb = Supabase.instance.client;

class HomeScreen extends StatefulWidget {
  final String? initialUserName;
  final int? initialUserPoin;
  final String? initialUserImage;
  final String? initialUserRole;
  final String? initialUserLocation;
  final Map<String, dynamic>? initialLatestLog;
  final int? initialUserJabatanId;
  final bool? initialIsVerificator;
  final int? initialNotifCount;
  final int? initialMonthlyPoin;

  const HomeScreen({
    super.key,
    this.initialUserName,
    this.initialUserPoin,
    this.initialUserImage,
    this.initialUserRole,
    this.initialUserLocation,
    this.initialLatestLog,
    this.initialUserJabatanId,
    this.initialIsVerificator,
    this.initialNotifCount,
    this.initialMonthlyPoin,
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
  int? _userJabatanId;
  bool _isLoadingVisitorStatus = true;
  bool _isUserDataLoading = true;
  RealtimeChannel? _pointChannel;
  bool _isCheckingLocation = false;
  bool _isAtAtmi = false;

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
  bool _isLatestLogLoading = true;
  bool _isExecutiveVerificator = false;
  bool _hasShownLoginDialog = false;

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

  // ── Penalty dialog teks ──
  static const Map<String, Map<String, String>> _penaltyTexts = {
    'EN': {'title': 'Points Deducted!', 'sub': 'You missed some login days.', 'ok': 'Got It'},
    'ID': {'title': 'Poin Dikurangi!', 'sub': 'Kamu melewatkan beberapa hari login.', 'ok': 'Mengerti'},
    'ZH': {'title': '积分已扣除！', 'sub': '您错过了一些登录天数。', 'ok': '明白'},
  };

  // ── Visitor mode teks ──
  static const Map<String, Map<String, String>> _visitorTexts = {
    'EN': {
      'on_title': 'Visitor Mode Active', 'off_title': 'Visitor Mode Off',
      'on_sub': 'Your findings will be tagged as visitor reports.',
      'off_sub': 'Back to regular mode.',
    },
    'ID': {
      'on_title': 'Mode Pengunjung Aktif', 'off_title': 'Mode Pengunjung Nonaktif',
      'on_sub': 'Temuan Anda akan ditandai sebagai laporan pengunjung.',
      'off_sub': 'Kembali ke mode reguler.',
    },
    'ZH': {
      'on_title': '访客模式已激活', 'off_title': '访客模式已停用',
      'on_sub': '您的发现将被标记为访客报告。', 'off_sub': '返回常规模式。',
    },
  };

  // ── Pro mode teks ──
  static const Map<String, Map<String, String>> _proModeTexts = {
    'EN': {
      'on_title': 'Professional Mode Active', 'off_title': 'Professional Mode Off',
      'on_sub': 'You can now access all locations without restrictions.',
      'off_sub': 'Back to regular mode.',
    },
    'ID': {
      'on_title': 'Mode Profesional Aktif', 'off_title': 'Mode Profesional Nonaktif',
      'on_sub': 'Anda sekarang dapat mengakses semua lokasi tanpa batasan.',
      'off_sub': 'Kembali ke mode reguler.',
    },
    'ZH': {
      'on_title': '专业模式已激活', 'off_title': '专业模式已停用',
      'on_sub': '您现在可以不受限制地访问所有地点。', 'off_sub': '返回常规模式。',
    },
  };

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

    _checkVerificationStatus().then((_) async {
      if (!mounted) return;
      await Future.wait([_loadLanguage(), _checkExecutiveVerificatorStatus()]);
      if (mounted) _handleLoginAndFetchData();
    });
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
  }

  @override
  void dispose() {
    if (_pointChannel != null) _sb.removeChannel(_pointChannel!);
    WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    super.dispose();
  }

  Future<void> _checkLocationAccess() async {
    setState(() => _isCheckingLocation = false); 

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
      _showPenaltyDialog(notif.points, notif.description);
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

    await Future.delayed(const Duration(milliseconds: 800));
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

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      // ── Kasus: login pertama kali seumur hidup ──
      if (status == 'first_ever_login') {
        await _showLoginPointDialogAndWait(dailyBonus, message);
        _fetchUserData(silent: true);
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
        await _showPenaltyDialogAndWait(-penalty, penaltyMsg);
        if (!mounted) return;
        _fetchUserData(silent: true);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // ── Tampilkan bonus pertama hari ini (PRIORITAS, sebelum harian) ──
      if (isFirstToday && firstTodayBonus > 0) {
        if (!mounted) return;
        await _showLoginPointDialogAndWait(
          firstTodayBonus,
          _getLoginConfig('login_pertama_hari_ini', firstTodayBonus),
        );
        if (!mounted) return;
        _fetchUserData(silent: true);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // ── Tampilkan bonus login harian ──
      if (dailyBonus > 0) {
        if (!mounted) return;
        await _showLoginPointDialogAndWait(
          dailyBonus,
          _getLoginConfig('login_harian', dailyBonus),
        );
        if (!mounted) return;
        _fetchUserData(silent: true);
      }

      // ── Tampilkan news popup setelah semua dialog selesai ──
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) await HomeNewsPopup.showIfNeeded(context, lang: _lang);
    } catch (e) {
      debugPrint('Error handling daily login points: $e');
    }
  }

  Future<void> _showLoginPointDialogAndWait(int points, String description) async {
    if (!mounted) return;
    final completer = Completer<void>();

    // Update poin otomatis di background tanpa menunggu user klik
    _fetchUserData(silent: true);

    showDialog(
      context: context,
      barrierDismissible: true, // klik luar = tutup
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _LoginPointDialog(
        points: points,
        description: description,
        lang: _lang,
        userId: _sb.auth.currentUser?.id ?? '',
        userLokasiId: _userLokasiId,
        onClaimed: () {
          Navigator.of(ctx).pop();
          _fetchUserData(silent: true);
          if (!completer.isCompleted) completer.complete();
        },
        onClaimedAndShared: (receiverUser) async {
          Navigator.of(ctx).pop();
          await _handleSharePoints(receiverUser);
          _fetchUserData(silent: true);
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    // Jika dialog ditutup dari luar (barrier), complete otomatis
    await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 10)),
    ]);
    if (!completer.isCompleted) completer.complete();
  }

  // ── Ekstrak logika share poin ke helper ──
  Future<void> _handleSharePoints(Map<String, dynamic> receiverUser) async {
    try {
      await _sb.rpc('share_login_points', params: {
        'p_sharer_id': _sb.auth.currentUser?.id,
        'p_receiver_id': receiverUser['id_user'],
        'p_share_amount': 5,
      });
      if (!mounted) return;

      int sharedAmt = 5, bonusAmt = 1;
      try {
        final cfg = await _sb
            .from('konfigurasi_poin')
            .select('kode, poin')
            .inFilter('kode', ['berbagi_poin', 'bonus_berbagi'])
            .eq('is_aktif', true);
        for (final row in cfg) {
          if (row['kode'] == 'berbagi_poin') sharedAmt = (row['poin'] as num).toInt().abs();
          else if (row['kode'] == 'bonus_berbagi') bonusAmt = (row['poin'] as num).toInt().abs();
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _lang == 'ID'
                    ? '${receiverUser['nama']} mendapat +$sharedAmt poin! Bonus +$bonusAmt poin untukmu.'
                    : '${receiverUser['nama']} gets +$sharedAmt points! Bonus +$bonusAmt points for you.',
              ),
            ),
          ]),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      debugPrint('Error sharing points: $e');
    }
  }

  Future<void> _showPenaltyDialogAndWait(int points, String description) async {
    if (!mounted) return;
    final completer = Completer<void>();

    // Poin langsung diupdate di background tanpa perlu tunggu user klik
    _fetchUserData(silent: true);

    final t = _penaltyTexts[_lang] ?? _penaltyTexts['ID']!;
    showDialog(
      context: context,
      barrierDismissible: true, // klik luar = tutup otomatis
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _PenaltyDialog(
        absPoints: points.abs(),
        description: description,
        title: t['title']!,
        okLabel: t['ok']!,
        onDismiss: () {
          Navigator.of(ctx).pop();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    ).then((_) {
      // Dipanggil ketika dialog ditutup dengan cara apapun (klik luar / tombol)
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
  }

  void _showPenaltyDialog(int points, String description) {
    final t = _penaltyTexts[_lang] ?? _penaltyTexts['ID']!;

    // Update poin otomatis tanpa perlu klik tombol
    _fetchUserData(silent: true);

    showDialog(
      context: context,
      barrierDismissible: true, // klik luar = tutup
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _PenaltyDialog(
        absPoints: points.abs(),
        description: description,
        title: t['title']!,
        okLabel: t['ok']!,
        onDismiss: () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        },
      ),
    );
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
          .from('User').select('is_visitor').eq('id_user', userId).single();
      if (mounted) {
        setState(() {
          _isVisitorMode = data['is_visitor'] ?? false;
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
      _showVisitorStatusDialog(isVisitor);
    } catch (e) {
      debugPrint('Error updating visitor status: $e');
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

      // Fetch user row dan log secara paralel
      final results = await Future.wait([
        _sb.from('User')
            .select('nama, email, poin, gambar_user, id_jabatan, id_unit, id_lokasi, id_subunit, id_area, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)')
            .eq('id_user', userAuth.id)
            .maybeSingle(),
        _sb.from('log_poin')
            .select('poin, deskripsi, tipe_aktivitas, created_at')
            .eq('id_user', userAuth.id)
            .order('created_at', ascending: false)
            .limit(1),
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
      final locationName = await _resolveLocationName(userRow);

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
        _userLocationName = locationName;
        if (latestLog != null) _latestLogPoin = latestLog;
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
  Future<String> _resolveLocationName(Map<String, dynamic> userRow) async {
    final idArea = userRow['id_area'];
    final idSubunit = userRow['id_subunit'];
    final idUnit = userRow['id_unit'];
    final idLokasi = userRow['id_lokasi'];

    try {
      if (idArea != null) {
        final d = await _sb.from('area').select('nama_area').eq('id_area', idArea).maybeSingle();
        return d?['nama_area'] ?? '...';
      } else if (idSubunit != null) {
        final d = await _sb.from('subunit').select('nama_subunit').eq('id_subunit', idSubunit).maybeSingle();
        return d?['nama_subunit'] ?? '...';
      } else if (idUnit != null) {
        final d = await _sb.from('unit').select('nama_unit').eq('id_unit', idUnit).maybeSingle();
        return d?['nama_unit'] ?? '...';
      } else if (idLokasi != null) {
        final d = await _sb.from('lokasi').select('nama_lokasi').eq('id_lokasi', idLokasi).maybeSingle();
        return d?['nama_lokasi'] ?? '...';
      }
    } catch (_) {}
    return '...';
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

  // ── Dialog mode status (Visitor / Pro) — widget tunggal ──
  void _showModeStatusDialog({
    required bool isActive,
    required Map<String, String> t,
    required Color primary,
    required String assetPath,
    required IconData fallbackIcon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 3), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.1),
                      border: Border.all(color: primary.withOpacity(0.3), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: primary, size: 42),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isActive ? t['on_title']! : t['off_title']!,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isActive ? t['on_sub']! : t['off_sub']!,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 3000),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v, minHeight: 4,
                        backgroundColor: primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(primary.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVisitorStatusDialog(bool isVisitor) {
    final t = _visitorTexts[_lang] ?? _visitorTexts['ID']!;
    final Color primary = isVisitor ? const Color(0xFF0891B2) : Colors.grey.shade500;
    _showModeStatusDialog(
      isActive: isVisitor,
      t: t,
      primary: primary,
      assetPath: isVisitor ? 'assets/images/visitor_on.png' : 'assets/images/visitor_off.png',
      fallbackIcon: isVisitor ? Icons.visibility_rounded : Icons.visibility_off_rounded,
    );
  }

  void _showProModeStatusDialog(bool isProMode) {
    final t = _proModeTexts[_lang] ?? _proModeTexts['ID']!;
    final Color primary = isProMode ? const Color(0xFF16A34A) : Colors.grey.shade500;
    _showModeStatusDialog(
      isActive: isProMode,
      t: t,
      primary: primary,
      assetPath: 'assets/images/modepro.png',
      fallbackIcon: isProMode ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined,
    );
  }

  /// Tampilkan dialog ketika user mencoba aksi yang butuh lokasi ATMI
  /// [actionKey]: 'new_finding' | 'resolution'
  void _showLocationBlockedDialog({required String actionKey}) {
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded,
                    color: Colors.orange, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                t['title']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 10),
              Text(
                t[actionKey] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9E4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(t['ok']!,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
      extendBody: true, // agar konten tidak terpotong navbar bawaan HP
      body: Stack(
        children: [
          _buildBgBlob(top: -100, left: -50, size: 350, opacity: 0.25),
          _buildBgBlob(bottom: 50, right: -100, size: 400, opacity: 0.20),
          SafeArea(
            // bottom: false agar konten bisa extend ke bawah
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

  // ── Background blob helper ──
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
            const Color(0xFF00C9E4).withOpacity(opacity),
            Colors.transparent,
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 8, 15, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C9E4).withOpacity(0.15),
            blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image(
            image: const AssetImage('assets/images/logo1.png'),
            height: 38,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9E4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, color: Color(0xFF00C9E4), size: 26),
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
        // Reset badge segera saat tombol diklik
        if (mounted) {
          setState(() => _notificationCount = 0);
        }

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
        // Tidak memanggil _fetchNotificationCount() di sini
        // agar badge tetap 0 setelah kembali dari NotificationScreen
        // Badge akan muncul kembali hanya saat ada assigned findings baru
        // yang masuk via realtime listener di _setupPointListener
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF00C9E4).withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00C9E4).withOpacity(0.2)),
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
            colors: [Color(0xFF00C9E4), Color(0xFF4ADE80)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9E4).withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFF00C9E4),
            backgroundImage: _userImage != null ? CachedNetworkImageProvider(_userImage!) : null,
            child: _userImage == null ? const Icon(Icons.person, color: Colors.white, size: 18) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    // Gunakan padding bottom sistem secara penuh agar selalu aman di semua HP
    final double safeBottom = bottomPadding > 0 ? bottomPadding : 8;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom, left: 20, right: 20),
        child: SizedBox(
          height: 65,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // ── Bar navigasi ──
              Container(
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C9E4).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0),
                    _buildNavItem(Icons.explore_outlined, Icons.explore, 1),
                    const SizedBox(width: 56), // ruang tombol +
                    _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 2),
                    _buildNavItem(Icons.emoji_events_outlined, Icons.emoji_events, 3),
                  ],
                ),
              ),
              // ── Tombol + di tengah, naik sedikit ──
              Positioned(
                top: 4,
                child: GestureDetector(
                  onTap: _openLocationSheet,
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9E4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C9E4).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLocationSheet() async {
    // ── Cek lokasi fresh sebelum buat temuan baru ──
    final result =
        await LocationService.instance.checkUserAtAtmi(forceRefresh: true);

    if (!mounted) return;
    setState(() => _isAtAtmi = result.isAtAtmi);

    if (!result.isAtAtmi) {
      _showLocationBlockedDialog(actionKey: 'new_finding');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50, height: 65,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isActive ? 10 : 0),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF00C9E4).withOpacity(0.15) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? filledIcon : outlineIcon,
              size: 28,
              color: isActive ? const Color(0xFF00C9E4) : Colors.grey.shade400,
            ),
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
      onProModeChanged: (val) {
        setState(() => _isProMode = val);
        _showProModeStatusDialog(val);
      },
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
      buildInfoCard: () => UserInfoCard(
        userName: _userName,
        userRole: _userRole,
        userImage: _userImage,
        userPoin: _userPoin,
        userLocationName: _userLocationName,
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
// DIALOG: LOGIN POINT
// ============================================================
class _LoginPointDialog extends StatefulWidget {
  final int points;
  final String description;
  final String lang;
  final String userId;
  final String? userLokasiId;
  final VoidCallback onClaimed;
  final Function(Map<String, dynamic>) onClaimedAndShared;

  const _LoginPointDialog({
    required this.points,
    required this.description,
    required this.lang,
    required this.userId,
    required this.onClaimed,
    required this.onClaimedAndShared,
    this.userLokasiId,
  });

  @override
  State<_LoginPointDialog> createState() => _LoginPointDialogState();
}

class _LoginPointDialogState extends State<_LoginPointDialog>
    with SingleTickerProviderStateMixin {
  bool _showUserPicker = false;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Poin Login Diterima!', 'claim': 'Ambil Poin', 'share': 'Ambil & Bagikan',
      'share_title': 'Pilih teman untuk berbagi 5 poin',
      'share_info': 'Kamu akan berbagi 5 poin dan mendapat bonus +1 poin!',
      'search': 'Cari teman...',
    },
    'EN': {
      'title': 'Login Points Received!', 'claim': 'Claim Points', 'share': 'Claim & Share',
      'share_title': 'Pick a friend to share 5 points',
      'share_info': 'You share 5 points and earn +1 bonus point!',
      'search': 'Search friend...',
    },
    'ZH': {
      'title': '登录积分已获得！', 'claim': '领取积分', 'share': '领取并分享',
      'share_title': '选择朋友分享5积分',
      'share_info': '您分享5积分并获得+1奖励积分！',
      'search': '搜索朋友...',
    },
  };

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (_users.isNotEmpty) return;
    setState(() => _isLoadingUsers = true);
    try {
      var query = _sb
          .from('User')
          .select('id_user, nama, jabatan(nama_jabatan)')
          .neq('id_user', widget.userId);
      if (widget.userLokasiId != null) query = query.eq('id_lokasi', widget.userLokasiId!);
      final data = await query.order('nama').limit(50);
      if (mounted) setState(() { _users = List<Map<String, dynamic>>.from(data); _isLoadingUsers = false; });
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<int> _getShareAmount() async {
    try {
      final data = await _sb
          .from('konfigurasi_poin')
          .select('poin')
          .eq('kode', 'berbagi_poin')
          .eq('is_aktif', true)
          .maybeSingle();
      return (data?['poin'] as num?)?.toInt().abs() ?? 5;
    } catch (_) { return 5; }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withOpacity(0.3),
                blurRadius: 40, spreadRadius: 5, offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _showUserPicker ? _buildUserPickerView() : _buildMainView(),
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00C9E4).withOpacity(0.4), blurRadius: 20, spreadRadius: 3),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 20),
          Text(t['title']!, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFB8F0FF), Color(0xFFE0F7FF)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('+${widget.points} Points',
                style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0891B2))),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Text(widget.description, textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, height: 1.5)),
          ),
          const SizedBox(height: 24),
          _ActionButton(
            onTap: widget.onClaimed,
            color: const Color(0xFF00C9E4),
            icon: Icons.local_fire_department_rounded,
            label: t['claim']!,
            isOutlined: false,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onTap: () async { await _loadUsers(); setState(() => _showUserPicker = true); },
            color: const Color(0xFF00C9E4),
            icon: Icons.local_fire_department_rounded,
            label: t['share']!,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUserPickerView() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(_users);

    return StatefulBuilder(
      builder: (context, setInner) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showUserPicker = false),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t['share_title']!,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E3A8A))),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00C9E4).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00C9E4).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Color(0xFF00C9E4), size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(t['share_info']!, style: const TextStyle(fontSize: 11, color: Color(0xFF0891B2)))),
            ]),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchCtrl,
              onChanged: (q) {
                setInner(() {
                  filtered = _users
                      .where((u) => u['nama'].toString().toLowerCase().contains(q.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                hintText: t['search']!,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A), size: 20),
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)))
                : filtered.isEmpty
                    ? const Center(child: Text('Tidak ada teman', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final u = filtered[i];
                          return GestureDetector(
                            onTap: () => widget.onClaimedAndShared(u),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF00C9E4).withOpacity(0.12),
                                    child: Text(u['nama'][0].toUpperCase(),
                                        style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u['nama'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        if (u['jabatan'] != null)
                                          Text(u['jabatan']['nama_jabatan'] ?? '',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  FutureBuilder<int>(
                                    future: _getShareAmount(),
                                    builder: (_, snap) {
                                      final amt = snap.data ?? 5;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Dapat', style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontWeight: FontWeight.w500)),
                                            Text('+$amt poin', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Reusable action button ──
class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String label;
  final bool isOutlined;

  const _ActionButton({
    required this.onTap, required this.color, required this.icon,
    required this.label, required this.isOutlined,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: isOutlined ? color : Colors.white),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );

    return SizedBox(
      width: double.infinity, height: 52,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                foregroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: child,
            ),
    );
  }
}

// ============================================================
// DIALOG: PENALTY
// ============================================================
class _PenaltyDialog extends StatefulWidget {
  final int absPoints;
  final String description;
  final String title;
  final String okLabel;
  final VoidCallback onDismiss;

  const _PenaltyDialog({
    required this.absPoints, required this.description,
    required this.title, required this.okLabel, required this.onDismiss,
  });

  @override
  State<_PenaltyDialog> createState() => _PenaltyDialogState();
}

class _PenaltyDialogState extends State<_PenaltyDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim, _fadeAnim, _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const Color red = Color(0xFFDC2626);
    const Color redLight = Color(0xFFFEF2F2);
    const Color redMid = Color(0xFFFFE4E6);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Transform.scale(scale: _scaleAnim.value, child: child),
        ),
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: red.withOpacity(0.18), width: 1.5),
              boxShadow: [
                BoxShadow(color: red.withOpacity(0.18), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: const BoxDecoration(
                    color: redMid,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(children: [
                    _PulsingRing(
                      color: red,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: red.withOpacity(0.12), shape: BoxShape.circle,
                          border: Border.all(color: red.withOpacity(0.35), width: 2),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: red, size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.title,
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: red)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(50)),
                      child: Text('-${widget.absPoints} Poin',
                          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: redLight, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: red.withOpacity(0.12)),
                      ),
                      child: Text(widget.description, textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500,
                              color: const Color(0xFF7F1D1D), height: 1.6)),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 6000),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v, minHeight: 3,
                          backgroundColor: red.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(red.withOpacity(0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red, foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(widget.okLabel,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                border: Border.all(color: primary.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(color: primary.withOpacity(0.2), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(children: [
                      _PulsingRing(
                        color: primary,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12), shape: BoxShape.circle,
                            border: Border.all(color: primary.withOpacity(0.3), width: 2),
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
                          color: primary.withOpacity(0.06), borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primary.withOpacity(0.12)),
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
                            backgroundColor: primary.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(primary.withOpacity(0.45)),
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
                color: widget.color.withOpacity(0.08 * (2.0 - _anim.value)),
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

// ============================================================
// LOCATION BOTTOM SHEET
// ============================================================
class LocationBottomSheet extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;
  final String? userUnitId;
  final String? userLokasiId;
  final String userRole;
  final VoidCallback? onFindingSaved;

  const LocationBottomSheet({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.isVisitorMode,
    required this.userRole,
    this.userUnitId,
    this.userLokasiId,
    this.onFindingSaved,
  });

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  int _currentLevel = 0;
  bool _isLoading = true;
  List<dynamic> _currentData = [];
  List<dynamic> _filteredData = [];
  String _searchQuery = '';
  List<Map<String, dynamic>> _navHistory = [];

  // ── Global search state ──
  bool _isSearchMode = false;
  bool _isSearchLoading = false;
  List<_SearchResult> _searchResults = [];

  // ── Data highlight: lokasi spesifik user & PIC ──
  List<_HighlightItem> _highlightItems = [];
  bool _isHighlightLoading = true;

  // ── User specific data ──
  String? _userSpecificId;   // ID lokasi paling spesifik milik user
  String? _userSpecificType; // 'area' | 'subunit' | 'unit' | 'lokasi'
  Set<String> _userPicIds = {}; // ID lokasi/unit/subunit/area yang user jadi PIC

  bool get _hasFullAccess => widget.isProMode || widget.userRole == 'Eksekutif';

  static const List<String> _tables = ['lokasi', 'unit', 'subunit', 'area'];
  String _getIdCol(int l) => 'id_${_tables[l]}';
  String _getNameCol(int l) => 'nama_${_tables[l]}';
  String _getChildKey(int l) => l < 3 ? _tables[l + 1] : '';

  @override
  void initState() {
    super.initState();
    _loadUserSpecificData();
  }

  // ── Load data spesifik user (lokasi milik user & PIC) ──
  Future<void> _loadUserSpecificData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) { _fetchData(); return; }

      final userData = await _sb
          .from('User')
          .select('id_area, id_subunit, id_unit, id_lokasi')
          .eq('id_user', userId)
          .maybeSingle();

      if (userData != null) {
        if (userData['id_area'] != null) {
          _userSpecificId   = userData['id_area'].toString();
          _userSpecificType = 'area';
        } else if (userData['id_subunit'] != null) {
          _userSpecificId   = userData['id_subunit'].toString();
          _userSpecificType = 'subunit';
        } else if (userData['id_unit'] != null) {
          _userSpecificId   = userData['id_unit'].toString();
          _userSpecificType = 'unit';
        } else if (userData['id_lokasi'] != null) {
          _userSpecificId   = userData['id_lokasi'].toString();
          _userSpecificType = 'lokasi';
        }
      }

      // Ambil PIC ids paralel
      final picResults = await Future.wait([
        _sb.from('lokasi').select('id_lokasi').eq('id_pic', userId),
        _sb.from('unit').select('id_unit').eq('id_pic', userId),
        _sb.from('subunit').select('id_subunit').eq('id_pic', userId),
        _sb.from('area').select('id_area').eq('id_pic', userId),
      ]);

      final Set<String> picIds = {};
      for (final r in picResults[0] as List) picIds.add(r['id_lokasi'].toString());
      for (final r in picResults[1] as List) picIds.add(r['id_unit'].toString());
      for (final r in picResults[2] as List) picIds.add(r['id_subunit'].toString());
      for (final r in picResults[3] as List) picIds.add(r['id_area'].toString());

      if (mounted) setState(() => _userPicIds = picIds);

      // Fetch data spesifik user (area/subunit/unit/lokasi) dan data PIC
      await _fetchUserHighlightData(userId);
    } catch (e) {
      debugPrint('Error loading user specific data: $e');
    }
    _fetchData();
  }

  Future<void> _fetchUserHighlightData(String userId) async {
    try {
      final items = <_HighlightItem>[];

      // ── 1. Lokasi paling spesifik milik user ──
      if (_userSpecificType != null && _userSpecificId != null) {
        final type = _userSpecificType!;
        final id   = _userSpecificId!;
        final row  = await _sb.from(type)
            .select('id_$type, nama_$type, is_star')
            .eq('id_$type', id)
            .maybeSingle();
        if (row != null) {
          items.add(_HighlightItem(
            id: id, name: row['nama_$type']?.toString() ?? '',
            type: type, badge: _ItemBadge.myLocation, raw: row,
          ));
        }
      }

      // ── 2. Lokasi yang user jadi PIC (exclude jika sudah masuk #1) ──
      if (_userPicIds.isNotEmpty) {
        final futures = await Future.wait([
          _sb.from('lokasi').select('id_lokasi, nama_lokasi, is_star')
              .inFilter('id_lokasi', _userPicIds.toList()).limit(5),
          _sb.from('unit').select('id_unit, nama_unit, is_star')
              .inFilter('id_unit', _userPicIds.toList()).limit(5),
          _sb.from('subunit').select('id_subunit, nama_subunit, is_star')
              .inFilter('id_subunit', _userPicIds.toList()).limit(5),
          _sb.from('area').select('id_area, nama_area, is_star')
              .inFilter('id_area', _userPicIds.toList()).limit(5),
        ]);

        final types = ['lokasi', 'unit', 'subunit', 'area'];
        for (int i = 0; i < futures.length; i++) {
          for (final r in futures[i] as List) {
            final id = r['id_${types[i]}']?.toString() ?? '';
            // Jangan duplikat dengan lokasi spesifik user
            if (id == _userSpecificId) continue;
            items.add(_HighlightItem(
              id: id, name: r['nama_${types[i]}']?.toString() ?? '',
              type: types[i], badge: _ItemBadge.pic, raw: r,
            ));
          }
        }
      }

      if (mounted) setState(() { _highlightItems = items; _isHighlightLoading = false; });
    } catch (e) {
      debugPrint('Error fetch highlight: $e');
      if (mounted) setState(() => _isHighlightLoading = false);
    }
  }

  // ── Helper: pesan empty state spesifik berdasarkan level ──
  String _getEmptyMessage() {
    if (_isSearchMode) return _bs('kosong');
    // Tidak dalam search mode: tampilkan pesan sesuai level yang sedang dibuka
    const levelKeys = ['lokasi_empty', 'unit_empty', 'subunit_empty', 'area_empty'];
    return _bs(levelKeys[_currentLevel]);
  }

  Future<void> _fetchData({String? parentId}) async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> data = [];
      final level = _currentLevel;

      if (level == 0) {
        data = await _sb.from('lokasi').select('id_lokasi, nama_lokasi, unit(id_unit), is_star, id_pic');
      } else if (level == 1) {
        if (_hasFullAccess) {
          data = await _sb.from('unit').select('id_unit, nama_unit, subunit(id_subunit), is_star, id_pic').eq('id_lokasi', parentId!);
        } else if (widget.userUnitId != null) {
          data = await _sb.from('unit').select('id_unit, nama_unit, subunit(id_subunit), is_star, id_pic')
              .eq('id_lokasi', parentId!).eq('id_unit', widget.userUnitId!);
        }
      } else if (level == 2) {
        data = await _sb.from('subunit').select('id_subunit, nama_subunit, area(id_area), is_star, id_pic').eq('id_unit', parentId!);
      } else if (level == 3) {
        data = await _sb.from('area').select('id_area, nama_area, is_star, id_pic').eq('id_subunit', parentId!);
      }

      if (mounted) {
        setState(() {
          _currentData = data;
          _filteredData = List.from(data);
          _sortData();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performGlobalSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _isSearchMode = false; _searchResults = []; });
      return;
    }
    setState(() { _isSearchMode = true; _isSearchLoading = true; _searchResults = []; });

    try {
      final List<_SearchResult> results = [];

      if (_hasFullAccess) {
        // ── Mode profesional / eksekutif: cari semua ──
        final futures = await Future.wait([
          _sb.from('lokasi').select('id_lokasi, nama_lokasi, is_star, id_pic')
              .ilike('nama_lokasi', '%$query%').limit(10),
          _sb.from('unit').select('id_unit, nama_unit, is_star, id_pic, id_lokasi, lokasi(nama_lokasi)')
              .ilike('nama_unit', '%$query%').limit(10),
          _sb.from('subunit').select('id_subunit, nama_subunit, is_star, id_pic, id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi)')
              .ilike('nama_subunit', '%$query%').limit(10),
          _sb.from('area').select('id_area, nama_area, is_star, id_pic, id_subunit, id_unit, id_lokasi, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi)')
              .ilike('nama_area', '%$query%').limit(10),
        ]);
        _mapSearchFutures(futures, results);
      } else {
        // ── Mode normal: hanya cari dalam hierarki lokasi user ──
        // Tentukan scope berdasarkan data paling spesifik user
        if (_userSpecificType == 'area' && _userSpecificId != null) {
          final rows = await _sb.from('area')
              .select('id_area, nama_area, is_star, id_pic, id_subunit, id_unit, id_lokasi, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi)')
              .eq('id_area', _userSpecificId!)
              .ilike('nama_area', '%$query%').limit(10);
          for (final r in rows as List) {
            results.add(_makeResult(r, 'area', 3));
          }
        } else if (_userSpecificType == 'subunit' && _userSpecificId != null) {
          final futures = await Future.wait([
            _sb.from('subunit').select('id_subunit, nama_subunit, is_star, id_pic, id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi)')
                .eq('id_subunit', _userSpecificId!).ilike('nama_subunit', '%$query%').limit(10),
            _sb.from('area').select('id_area, nama_area, is_star, id_pic, id_subunit, id_unit, id_lokasi, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi)')
                .eq('id_subunit', _userSpecificId!).ilike('nama_area', '%$query%').limit(10),
          ]);
          for (final r in futures[0] as List) results.add(_makeResult(r, 'subunit', 2));
          for (final r in futures[1] as List) results.add(_makeResult(r, 'area', 3));
        } else if (_userSpecificType == 'unit' && _userSpecificId != null) {
          final futures = await Future.wait([
            _sb.from('unit').select('id_unit, nama_unit, is_star, id_pic, id_lokasi, lokasi(nama_lokasi)')
                .eq('id_unit', _userSpecificId!).ilike('nama_unit', '%$query%').limit(10),
            _sb.from('subunit').select('id_subunit, nama_subunit, is_star, id_pic, id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi)')
                .eq('id_unit', _userSpecificId!).ilike('nama_subunit', '%$query%').limit(10),
            _sb.from('area').select('id_area, nama_area, is_star, id_pic, id_subunit, id_unit, id_lokasi, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi)')
                .eq('id_unit', _userSpecificId!).ilike('nama_area', '%$query%').limit(10),
          ]);
          for (final r in futures[0] as List) results.add(_makeResult(r, 'unit', 1));
          for (final r in futures[1] as List) results.add(_makeResult(r, 'subunit', 2));
          for (final r in futures[2] as List) results.add(_makeResult(r, 'area', 3));
        } else if (_userSpecificType == 'lokasi' && _userSpecificId != null) {
          final futures = await Future.wait([
            _sb.from('lokasi').select('id_lokasi, nama_lokasi, is_star, id_pic')
                .eq('id_lokasi', _userSpecificId!).ilike('nama_lokasi', '%$query%').limit(10),
            _sb.from('unit').select('id_unit, nama_unit, is_star, id_pic, id_lokasi, lokasi(nama_lokasi)')
                .eq('id_lokasi', _userSpecificId!).ilike('nama_unit', '%$query%').limit(10),
            _sb.from('subunit').select('id_subunit, nama_subunit, is_star, id_pic, id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi)')
                .eq('id_lokasi', _userSpecificId!).ilike('nama_subunit', '%$query%').limit(10),
            _sb.from('area').select('id_area, nama_area, is_star, id_pic, id_subunit, id_unit, id_lokasi, subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi)')
                .eq('id_lokasi', _userSpecificId!).ilike('nama_area', '%$query%').limit(10),
          ]);
          for (final r in futures[0] as List) results.add(_makeResult(r, 'lokasi', 0));
          for (final r in futures[1] as List) results.add(_makeResult(r, 'unit', 1));
          for (final r in futures[2] as List) results.add(_makeResult(r, 'subunit', 2));
          for (final r in futures[3] as List) results.add(_makeResult(r, 'area', 3));
        }
      }

      results.sort((a, b) {
        if (a.isUserSpecific != b.isUserSpecific) return a.isUserSpecific ? -1 : 1;
        if (a.isPic != b.isPic) return a.isPic ? -1 : 1;
        if (a.isStar != b.isStar) return a.isStar ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (mounted) setState(() { _searchResults = results; _isSearchLoading = false; });
    } catch (e) {
      debugPrint('Error global search: $e');
      if (mounted) setState(() => _isSearchLoading = false);
    }
  }

  // ── Helper: buat _SearchResult dari raw row ──
  _SearchResult _makeResult(Map<String, dynamic> r, String type, int level) {
    final idKey   = 'id_$type';
    final nameKey = 'nama_$type';
    final id      = r[idKey]?.toString() ?? '';

    String? breadcrumb;
    if (type == 'unit')    breadcrumb = r['lokasi']?['nama_lokasi']?.toString();
    if (type == 'subunit') {
      final parts = [r['lokasi']?['nama_lokasi'], r['unit']?['nama_unit']]
          .whereType<String>().join(' › ');
      breadcrumb = parts.isNotEmpty ? parts : null;
    }
    if (type == 'area') {
      final parts = [r['lokasi']?['nama_lokasi'], r['unit']?['nama_unit'], r['subunit']?['nama_subunit']]
          .whereType<String>().join(' › ');
      breadcrumb = parts.isNotEmpty ? parts : null;
    }

    return _SearchResult(
      id: id, name: r[nameKey]?.toString() ?? '', type: type, level: level,
      isStar: (r['is_star'] ?? 0) == 1,
      isPic: _userPicIds.contains(id),
      isUserSpecific: _userSpecificId == id,
      breadcrumb: breadcrumb, raw: r,
    );
  }

  // ── Helper: map futures hasil search all-access ke results ──
  void _mapSearchFutures(List<dynamic> futures, List<_SearchResult> results) {
    for (final r in futures[0] as List) results.add(_makeResult(r, 'lokasi', 0));
    for (final r in futures[1] as List) results.add(_makeResult(r, 'unit', 1));
    for (final r in futures[2] as List) results.add(_makeResult(r, 'subunit', 2));
    for (final r in futures[3] as List) results.add(_makeResult(r, 'area', 3));
  }

  void _onItemTapped(Map<String, dynamic> item) {
    if (_currentLevel == 3) { Navigator.pop(context, item); return; }
    _navHistory.add({
      'level': _currentLevel,
      'id': item[_getIdCol(_currentLevel)]?.toString(),
      'name': item[_getNameCol(_currentLevel)],
    });
    setState(() { _currentLevel++; _searchQuery = ''; });
    _fetchData(parentId: _navHistory.last['id']);
  }

  void _goBack() {
    if (_navHistory.isEmpty) return;
    _navHistory.removeLast();
    setState(() { _currentLevel--; _searchQuery = ''; });
    _fetchData(parentId: _navHistory.isEmpty ? null : _navHistory.last['id']);
  }

  void _onSearch(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      setState(() { _isSearchMode = false; _searchResults = []; _filteredData = List.from(_currentData); _sortData(); });
      return;
    }
    _performGlobalSearch(query);
  }

  void _sortData() {
    final nameCol = _getNameCol(_currentLevel);
    _filteredData.sort((a, b) {
      final idA = a[_getIdCol(_currentLevel)]?.toString() ?? '';
      final idB = b[_getIdCol(_currentLevel)]?.toString() ?? '';
      final isSpecA = _userSpecificId == idA ? 1 : 0;
      final isSpecB = _userSpecificId == idB ? 1 : 0;
      if (isSpecA != isSpecB) return isSpecB - isSpecA;
      final isPicA = _userPicIds.contains(idA) ? 1 : 0;
      final isPicB = _userPicIds.contains(idB) ? 1 : 0;
      if (isPicA != isPicB) return isPicB - isPicA;
      final starA = a['is_star'] ?? 0;
      final starB = b['is_star'] ?? 0;
      if (starA != starB) return starB - starA;
      return a[nameCol].toString().toLowerCase().compareTo(b[nameCol].toString().toLowerCase());
    });
  }

  // ── Badge untuk item: apakah ini lokasi spesifik user atau PIC ──
  _ItemBadge _getItemBadge(String itemId) {
    if (_userSpecificId == itemId) return _ItemBadge.myLocation;
    if (_userPicIds.contains(itemId)) return _ItemBadge.pic;
    return _ItemBadge.none;
  }

  static const Map<String, Map<String, String>> _bsTxt = {
    'EN': {
      'pilih_lokasi': 'Choose Finding Location',
      'cari': 'Search location, unit, subunit, area...',
      'semua': 'All Locations',
      'unit_saya': 'My Unit',
      'kosong': 'Location not found',
      'sub': 'Sub-locations',
      'my_location': 'My Location',
      'pic': 'My Responsibility',
      'search_result': 'Search Results',
      'lokasi_empty'  : 'Location not found',
      'unit_empty'    : 'Unit not found',
      'subunit_empty' : 'Subunit not found',
      'area_empty'    : 'Area not found',
      'my_location_label' : 'My Location',
      'pic_label'         : 'My Responsibility',
      'highlight_title'   : 'Your Locations',
    },
    'ID': {
      'pilih_lokasi': 'Pilih Lokasi Temuan',
      'cari': 'Cari lokasi, unit, subunit, area...',
      'semua': 'Semua Lokasi',
      'unit_saya': 'Unit Saya',
      'kosong': 'Lokasi tidak ditemukan',
      'sub': 'Sub-lokasi',
      'my_location': 'Lokasi Saya',
      'pic': 'Tanggung Jawab Saya',
      'search_result': 'Hasil Pencarian',
      'lokasi_empty'  : 'Lokasi tidak ditemukan',
      'unit_empty'    : 'Unit tidak ditemukan',
      'subunit_empty' : 'Subunit tidak ditemukan',
      'area_empty'    : 'Area tidak ditemukan',
      'my_location_label' : 'Lokasi Saya',
      'pic_label'         : 'Tanggung Jawab Saya',
      'highlight_title'   : 'Lokasi Anda',

    },
    'ZH': {
      'pilih_lokasi': '选择发现位置',
      'cari': '搜索位置、单位、子单位、区域...',
      'semua': '所有位置',
      'unit_saya': '我的单位',
      'kosong': '未找到位置',
      'sub': '子位置',
      'my_location': '我的位置',
      'pic': '我的责任',
      'search_result': '搜索结果',
      'lokasi_empty'  : '未找到位置',
      'unit_empty'    : '未找到单位',
      'subunit_empty' : '未找到子单位',
      'area_empty'    : '未找到区域',
      'my_location_label' : '我的位置',
      'pic_label'         : '我的责任',
      'highlight_title'   : '您的位置',
    },
  };

  String _bs(String key) => _bsTxt[widget.lang]?[key] ?? _bsTxt['ID']![key]!;

  @override
  Widget build(BuildContext context) {
    final String parentName = _navHistory.isEmpty
        ? (!_hasFullAccess ? _bs('unit_saya') : _bs('semua'))
        : _navHistory.last['name'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(_bs('pilih_lokasi'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          ),
          const Divider(height: 1, color: Colors.black12),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: _onSearch,
                            decoration: InputDecoration(
                              hintText: _bs('cari'), border: InputBorder.none, isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_isSearchMode)
                          GestureDetector(
                            onTap: () {
                              setState(() { _isSearchMode = false; _searchResults = []; _searchQuery = ''; });
                            },
                            child: const Icon(Icons.close, color: Colors.grey, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QRScannerScreen(
                      lang: widget.lang, isProMode: widget.isProMode, isVisitorMode: widget.isVisitorMode,
                    )),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FC), borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),

          // ── Mode search global ──
          if (_isSearchMode)
            Expanded(child: _buildSearchResults())
          else ...[
            // ── Highlight: lokasi spesifik & PIC ──
            _buildHighlightSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                children: [
                  if (_navHistory.isNotEmpty)
                    GestureDetector(
                      onTap: _goBack,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  Text(parentName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(child: _buildLocationList()),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightSection() {
    // Sembunyikan jika sedang search atau tidak ada data
    if (_isSearchMode || (_highlightItems.isEmpty && !_isHighlightLoading)) {
      return const SizedBox.shrink();
    }

    const levelColors = [Color(0xFF0891B2), Color(0xFF7C3AED), Color(0xFF059669), Color(0xFFD97706)];
    const levelIcons  = [
      Icons.location_city_rounded, Icons.domain_rounded,
      Icons.grid_view_rounded,     Icons.place_rounded,
    ];
    const typeIndex   = {'lokasi': 0, 'unit': 1, 'subunit': 2, 'area': 3};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
          child: Row(children: [
            const Icon(Icons.person_pin_circle_rounded, size: 14, color: Color(0xFF0891B2)),
            const SizedBox(width: 6),
            Text(_bs('highlight_title'),
                style: const TextStyle(fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A), fontSize: 13)),
          ]),
        ),
        if (_isHighlightLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C9E4)),
            )),
          )
        else
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _highlightItems.length,
              itemBuilder: (_, i) {
                final item = _highlightItems[i];
                final idx  = typeIndex[item.type] ?? 0;
                final clr  = levelColors[idx];
                final ico  = levelIcons[idx];
                final isMyLoc = item.badge == _ItemBadge.myLocation;

                return GestureDetector(
                  onTap: () => _openCameraFromHighlight(item),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMyLoc
                          ? const Color(0xFF00C9E4).withOpacity(0.07)
                          : const Color(0xFF16A34A).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMyLoc
                            ? const Color(0xFF00C9E4).withOpacity(0.4)
                            : const Color(0xFF16A34A).withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: clr.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(ico, color: clr, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E3A8A)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isMyLoc
                                      ? const Color(0xFF00C9E4).withOpacity(0.12)
                                      : const Color(0xFF16A34A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isMyLoc ? _bs('my_location_label') : _bs('pic_label'),
                                  style: TextStyle(
                                      fontSize: 8, fontWeight: FontWeight.bold,
                                      color: isMyLoc
                                          ? const Color(0xFF0891B2)
                                          : const Color(0xFF16A34A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _openCameraFromHighlight(item),
                          child: const Icon(Icons.camera_alt,
                              color: Color(0xFF00C9E4), size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const Divider(height: 16, color: Colors.black12, indent: 15, endIndent: 15),
      ],
    );
  }

  void _openCameraFromHighlight(_HighlightItem item) {
    String? idL, idU, idS, idA;
    final raw = item.raw;
    switch (item.type) {
      case 'lokasi':  idL = item.id; break;
      case 'unit':    idL = raw['id_lokasi']?.toString(); idU = item.id; break;
      case 'subunit': idL = raw['id_lokasi']?.toString(); idU = raw['id_unit']?.toString(); idS = item.id; break;
      case 'area':    idL = raw['id_lokasi']?.toString(); idU = raw['id_unit']?.toString();
                      idS = raw['id_subunit']?.toString(); idA = item.id; break;
    }
    final onSaved = widget.onFindingSaved;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CameraFindingScreen(
        lang: widget.lang, isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        selectedLocationName: item.name,
        selectedLocationId: idL, selectedUnitId: idU,
        selectedSubunitId: idS, selectedAreaId: idA,
        onFindingSaved: onSaved,
      ),
    ));
  }

  // ── Daftar lokasi normal (non-search) ──
  Widget _buildLocationList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)));
    if (_filteredData.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final item = _filteredData[index];
        final idCol = _getIdCol(_currentLevel);
        final nameCol = _getNameCol(_currentLevel);
        final childKey = _getChildKey(_currentLevel);
        final String itemId = item[idCol]?.toString() ?? '';
        final String itemName = item[nameCol].toString();
        final int subCount = _currentLevel < 3
            ? ((item[childKey] as List<dynamic>?)?.length ?? 0)
            : 0;
        final badge = _getItemBadge(itemId);

        return _buildLocationItem(
          item: item, itemId: itemId, itemName: itemName,
          subCount: subCount, badge: badge,
          onTap: () => _onItemTapped(item),
          onCamera: () => _openCamera(item, itemId, itemName),
        );
      },
    );
  }

  // ── Hasil pencarian global ──
  Widget _buildSearchResults() {
    if (_isSearchLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)));
    if (_searchResults.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Text(
            '${_bs('search_result')} (${_searchResults.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            physics: const BouncingScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildSearchResultItem(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(_SearchResult result) {
    final badge = result.isUserSpecific
        ? _ItemBadge.myLocation
        : result.isPic
            ? _ItemBadge.pic
            : _ItemBadge.none;

    // Icon per level
    final IconData levelIcon = [
      Icons.location_city_rounded,
      Icons.domain_rounded,
      Icons.grid_view_rounded,
      Icons.place_rounded,
    ][result.level];

    final Color levelColor = [
      const Color(0xFF0891B2),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFD97706),
    ][result.level];

    return GestureDetector(
      onTap: () => _openCameraFromSearch(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge == _ItemBadge.myLocation
                ? const Color(0xFF00C9E4).withOpacity(0.5)
                : badge == _ItemBadge.pic
                    ? const Color(0xFF16A34A).withOpacity(0.4)
                    : Colors.blue.withOpacity(0.1),
            width: badge != _ItemBadge.none ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(levelIcon, color: levelColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(result.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                      ),
                      if (badge != _ItemBadge.none) ...[
                        const SizedBox(width: 6),
                        _buildBadgeChip(badge),
                      ],
                    ],
                  ),
                  if (result.breadcrumb != null) ...[
                    const SizedBox(height: 2),
                    Text(result.breadcrumb!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(result.type.toUpperCase(),
                        style: TextStyle(fontSize: 9, color: levelColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _openCameraFromSearch(result),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C9E4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF00C9E4), size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required Map<String, dynamic> item,
    required String itemId,
    required String itemName,
    required int subCount,
    required _ItemBadge badge,
    required VoidCallback onTap,
    required VoidCallback onCamera,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: badge == _ItemBadge.myLocation
                ? const Color(0xFF00C9E4).withOpacity(0.5)
                : badge == _ItemBadge.pic
                    ? const Color(0xFF16A34A).withOpacity(0.4)
                    : Colors.blue.withOpacity(0.1),
            width: badge != _ItemBadge.none ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.domain, color: Colors.lightBlue, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(itemName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                      ),
                      if (badge != _ItemBadge.none) ...[
                        const SizedBox(width: 6),
                        _buildBadgeChip(badge),
                      ],
                    ],
                  ),
                  if (_currentLevel < 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        const Icon(Icons.account_tree_outlined, size: 14, color: Colors.black54),
                        const SizedBox(width: 5),
                        Text('$subCount ${_bs('sub')}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ]),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final idCol = _getIdCol(_currentLevel);
                    final int newStar = (item['is_star'] ?? 0) == 1 ? 0 : 1;
                    setState(() { item['is_star'] = newStar; _sortData(); });
                    await _sb.from(_tables[_currentLevel])
                        .update({'is_star': newStar}).eq(idCol, itemId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      (item['is_star'] ?? 0) == 1 ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber, size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCamera,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9E4).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: Color(0xFF00C9E4), size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Badge chip ──
  Widget _buildBadgeChip(_ItemBadge badge) {
    if (badge == _ItemBadge.myLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF00C9E4).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00C9E4).withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_pin_circle_rounded, size: 10, color: Color(0xFF0891B2)),
            const SizedBox(width: 3),
            Text(_bs('my_location'),
                style: const TextStyle(fontSize: 9, color: Color(0xFF0891B2), fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 10, color: Color(0xFF16A34A)),
            const SizedBox(width: 3),
            Text(_bs('pic'),
                style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }

  // ── Empty state dengan ilustrasi ──
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/team_illustration.png', height: 140,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.location_off_rounded, size: 80, color: Colors.grey)),
            const SizedBox(height: 16),
            Text(_getEmptyMessage(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Buka kamera dari hasil search ──
  void _openCameraFromSearch(_SearchResult result) {
    String? idL, idU, idS, idA;
    final raw = result.raw;

    switch (result.type) {
      case 'lokasi':
        idL = result.id;
        break;
      case 'unit':
        idL = raw['id_lokasi']?.toString();
        idU = result.id;
        break;
      case 'subunit':
        idL = raw['id_lokasi']?.toString();
        idU = raw['id_unit']?.toString();
        idS = result.id;
        break;
      case 'area':
        idL = raw['id_lokasi']?.toString();
        idU = raw['id_unit']?.toString();
        idS = raw['id_subunit']?.toString();
        idA = result.id;
        break;
    }

    final onSaved = widget.onFindingSaved;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraFindingScreen(
          lang: widget.lang,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
          selectedLocationName: result.name,
          selectedLocationId: idL,
          selectedUnitId: idU,
          selectedSubunitId: idS,
          selectedAreaId: idA,
          onFindingSaved: onSaved,
        ),
      ),
    );
  }

  void _openCamera(Map<String, dynamic> item, String itemId, String itemName) {
    String? idL, idU, idS, idA;
    final level = _currentLevel;
    if (level == 0) idL = itemId;
    else if (level == 1) { idL = _navHistory[0]['id']; idU = itemId; }
    else if (level == 2) { idL = _navHistory[0]['id']; idU = _navHistory[1]['id']; idS = itemId; }
    else if (level == 3) { idL = _navHistory[0]['id']; idU = _navHistory[1]['id']; idS = _navHistory[2]['id']; idA = itemId; }

    final onSaved = widget.onFindingSaved;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraFindingScreen(
          lang: widget.lang,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
          selectedLocationName: itemName,
          selectedLocationId: idL,
          selectedUnitId: idU,
          selectedSubunitId: idS,
          selectedAreaId: idA,
          onFindingSaved: onSaved,
        ),
      ),
    );
  }
}

class _HighlightItem {
  final String id;
  final String name;
  final String type; // 'lokasi'|'unit'|'subunit'|'area'
  final _ItemBadge badge;
  final Map<String, dynamic> raw;
  const _HighlightItem({
    required this.id, required this.name,
    required this.type, required this.badge, required this.raw,
  });
}

// ── Helper: search result model ──
class _SearchResult {
  final String id;
  final String name;
  final String type;    // 'lokasi' | 'unit' | 'subunit' | 'area'
  final int level;      // 0-3
  final bool isStar;
  final bool isPic;
  final bool isUserSpecific;
  final String? breadcrumb;
  final Map<String, dynamic> raw;

  const _SearchResult({
    required this.id, required this.name, required this.type,
    required this.level, required this.isStar, required this.isPic,
    required this.isUserSpecific, required this.breadcrumb, required this.raw,
  });
}

// ── Helper: badge type ──
enum _ItemBadge { none, myLocation, pic }