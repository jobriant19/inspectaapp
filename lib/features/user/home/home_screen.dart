import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/jabatan_helper.dart';
import '../../shared/account/account_screen.dart';
import '../explore/explore_screen.dart';
import '../analytics/analytics_screen.dart';
import '../../shared/notifications/notification_screen.dart';
import '../../shared/code/qr_scanner_screen.dart';
import '../leaderboard/ranking_screen.dart';
import '../finding/camera_finding_screen.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_info_card.dart';
import 'activity_log_dialog.dart';
import 'home_content.dart';

class HomeScreen extends StatefulWidget {
  final String? initialUserName;
  final int? initialUserPoin;
  final String? initialUserImage;
  final String? initialUserRole;
  final String? initialUserLocation;
  final Map<String, dynamic>? initialLatestLog;
  final int? initialUserJabatanId;       // ← TAMBAH INI
  final bool? initialIsVerificator;

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
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _lang = 'EN';
  bool _isProMode = false;
  bool _isVisitorMode = false;
  String _userLocationName = "...";
  int? _userJabatanId;
  bool _isLoadingVisitorStatus = true;
  bool _isUserDataLoading = true;
  RealtimeChannel? _pointChannel;
  int _findingsRefreshTrigger = 0;

  // Data User
  String _userName = "...";
  String _userRole = "...";
  int _userPoin = 0;
  String? _userImage;
  String? _userUnitId;
  String? _userLokasiId;

  int _notificationCount = 0;
  DateTime? _lastDialogTime;
  
  Map<String, dynamic>? _latestLogPoin;
  bool _isLatestLogLoading = true;
  bool _isExecutiveVerificator = false;
  String _activeTab = 'my';
  bool _hasShownLoginDialog = false;
  int _previousPoin = 0;
  bool _isAnimatingPoin = false;
  int _displayedPoin = 0;
  final RouteObserver<ModalRoute<void>> _routeObserver = RouteObserver<ModalRoute<void>>();
  _PendingPointNotif? _pendingPointNotif;
  final GlobalKey<HomeContentState> _homeContentKey = GlobalKey<HomeContentState>();
  VoidCallback? _triggerFindingsRefresh;
  bool _shouldRefreshFindings = false;
  int _lastRefreshTrigger = 0;
  _AppLifecycleObserver? _lifecycleObserver;

  // Dictionary Translate untuk Navigation Bar
  final Map<String, Map<String, String>> _navText = {
    'EN': {
      'home': 'Home',
      'explore': 'Explore',
      'analytics': 'Analytics',
      'ranking': 'Ranking',
      'visitor_on': 'Visitor Mode Activated',
      'visitor_off': 'Visitor Mode Deactivated',
      'update_failed': 'Update Failed',
      'recent_findings': 'Recent Findings',
      'view_more': 'View More',
      'activity_log': 'Activity Log',
      'points': 'Points',
      'close': 'Close',
      'latest_activity': 'Location:',
    },
    'ID': {
      'home': 'Beranda',
      'explore': 'Telusuri',
      'analytics': 'Analitik',
      'ranking': 'Peringkat',
      'visitor_on': 'Mode Pengunjung Diaktifkan',
      'visitor_off': 'Mode Pengunjung Dinonaktifkan',
      'update_failed': 'Gagal Memperbarui',
      'recent_findings': 'Temuan Terbaru',
      'view_more': 'Lihat Detail',
      'activity_log': 'Log Aktivitas',
      'points': 'Poin',
      'close': 'Tutup',
      'latest_activity': 'Terbaru:',
    },
    'ZH': {
      'home': '主页', 
      'explore': '探索', 
      'analytics': '分析', 
      'ranking': '排名',
      'visitor_on': '访客模式已激活',
      'visitor_off': '访客模式已停用',
      'update_failed': '更新失败',
      'recent_findings': '最新发现',
      'view_more': '查看更多',
      'activity_log': '活动日志',
      'points': '积分',
      'close': '关闭',
      'latest_activity': '最新活动:',
    },
  };

  Map<String, String> _getPointDialogTexts() {
    final Map<String, Map<String, String>> texts = {
      'EN': {
        'gained_title': 'Points Received!',
        'lost_title': 'Points Deducted!',
        'auto_close': 'Closing automatically...',
        'total_label': 'Total Points',
        'tap_close': 'Tap anywhere to close',
      },
      'ID': {
        'gained_title': 'Poin Diterima!',
        'lost_title': 'Poin Dikurangi!',
        'auto_close': 'Menutup otomatis...',
        'total_label': 'Total Poin',
        'tap_close': 'Ketuk di mana saja untuk menutup',
      },
      'ZH': {
        'gained_title': '获得积分！',
        'lost_title': '积分已扣除！',
        'auto_close': '自动关闭中...',
        'total_label': '总积分',
        'tap_close': '点击任意处关闭',
      },
    };
    return texts[_lang] ?? texts['ID']!;
  }

  void _showPointNotificationDialog(int points, String description, String tipe) {
    if (points == 0) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) => _PointNotifDialog(
        points: points,
        description: description,
        tipe: tipe,
        lang: _lang,
        onDismiss: () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
  }

  void _tryShowPendingNotif() async {
    if (_pendingPointNotif == null) return;
    if (!mounted) return;

    // Pastikan kita benar-benar di HomeScreen (tidak ada screen lain di atas)
    // Tunggu sampai navigation selesai
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _pendingPointNotif == null) return;

    final notif = _pendingPointNotif!;
    _pendingPointNotif = null;
    _lastDialogTime = DateTime.now();

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

  // ── Animasi poin naik pada info card ──
  void _animatePoinUpdate(int newPoin) {
    if (_isAnimatingPoin) {
      // Jika sedang animasi, langsung set target baru dan stop
      setState(() {
        _displayedPoin = newPoin;
        _isAnimatingPoin = false;
      });
      return;
    }

    final int startPoin = _displayedPoin;

    // Tidak perlu animasi jika nilai sama
    if (startPoin == newPoin) {
      setState(() => _displayedPoin = newPoin);
      return;
    }

    _isAnimatingPoin = true;
    final int diff = newPoin - startPoin;
    final int steps = diff.abs().clamp(1, 30);
    final double stepValue = diff / steps;
    int currentStep = 0;

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 40));
      currentStep++;
      if (mounted) {
        setState(() {
          _displayedPoin = (startPoin + (stepValue * currentStep)).round();
          if (currentStep >= steps) {
            _displayedPoin = newPoin;
            _isAnimatingPoin = false;
          }
        });
      }
      return currentStep < steps && mounted && _isAnimatingPoin;
    });
  }

  // Helper: buat deskripsi dari konfigurasi (fallback jika belum load)
  String _getConfig(String tipe, int poin) {
    switch (tipe) {
      case 'login_pertama_hari_ini':
        return _lang == 'EN'
            ? 'Congratulations! You are the first to login today: +$poin points'
            : _lang == 'ZH'
                ? '恭喜！您今天第一个登录：+$poin积分'
                : 'Selamat! Anda orang pertama yang login hari ini: +$poin poin';
      case 'login_harian':
        return _lang == 'EN'
            ? 'Daily login bonus: +$poin points'
            : _lang == 'ZH'
                ? '每日登录奖励：+$poin积分'
                : 'Bonus login harian: +$poin poin';
      default:
        return 'Poin: +$poin';
    }
  }

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _AppLifecycleObserver(onResume: () {
      if (mounted) {
        final int poinSebelum = _userPoin;
        _fetchUserData(silent: true).then((_) {
          if (mounted && _userPoin != poinSebelum) {
            _animatePoinUpdate(_userPoin);
          }
        });
      }
    });
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
    if (widget.initialUserName != null) {
      _userName = widget.initialUserName!;
      _userPoin = widget.initialUserPoin ?? 0;
      _displayedPoin = widget.initialUserPoin ?? 0;
      _userImage = widget.initialUserImage;
      final bool initIsVerif = widget.initialIsVerificator == true;
      if (initIsVerif) {
        _userRole = JabatanHelper.getDisplayRole(
          isVerificatorFlag: true,
          idJabatan: widget.initialUserJabatanId,
          jabatanFromDb: widget.initialUserRole,
          lang: _lang,
        );
      } else {
        _userRole = widget.initialUserRole ?? 'Staff';
      }
      _isUserDataLoading = false;
      if (widget.initialUserLocation != null) {
        _userLocationName = widget.initialUserLocation!;
      }
      if (widget.initialLatestLog != null) {
        _latestLogPoin = widget.initialLatestLog;
        _isLatestLogLoading = false;
      } else {
        _isLatestLogLoading = false;
      }
      // ← Set langsung dari data yang dikirim login/splash
      if (widget.initialUserJabatanId != null) {
        _userJabatanId = widget.initialUserJabatanId;
      }
      if (widget.initialIsVerificator != null) {
        _isExecutiveVerificator = widget.initialIsVerificator == true;
      }
    }

    _checkVerificationStatus().then((_) async {
      if (!mounted) return;
      await _loadLanguage();
      await _checkExecutiveVerificatorStatus();
      if (mounted) {
        _handleLoginAndFetchData();
      }
    });
  }

  Future<void> _handleLoginAndFetchData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_pointChannel == null) {
      _setupPointListener();
    }

    // Fetch data & notif count
    _fetchUserData();
    _fetchNotificationCount();
    _loadInitialVisitorStatus();

    // ✅ Dialog hanya ditampilkan SEKALI per sesi app
    if (!_hasShownLoginDialog) {
      _hasShownLoginDialog = true;

      // Tunggu UI dan bahasa siap
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      try {
        final dynamic raw = await Supabase.instance.client
            .rpc('handle_daily_login', params: {'p_user_id': user.id});

        if (!mounted || raw == null) return;

        final Map<String, dynamic> result = raw is List
            ? (raw.isNotEmpty ? Map<String, dynamic>.from(raw.first) : {})
            : Map<String, dynamic>.from(raw);

        final String status = result['status']?.toString() ?? '';

        // ✅ Jika sudah login hari ini, skip dialog tapi tetap refresh data
        if (status == 'already_logged_in_today' || status.isEmpty) {
          _fetchUserData(silent: true);
          return;
        }

        final int dailyBonus = (result['daily_bonus'] as num?)?.toInt() ?? 0;
        final int penalty = (result['penalty'] as num?)?.toInt() ?? 0;
        final int firstTodayBonus = (result['first_today_bonus'] as num?)?.toInt() ?? 0;
        final bool isFirstToday = result['is_first_today'] as bool? ?? false;
        final String message = result['message']?.toString() ?? '';

        // Tunggu sebentar agar home screen fully rendered
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        // Login pertama seumur hidup
        if (status == 'first_ever_login') {
          await _showLoginPointDialogAndWait(dailyBonus, message);
          _fetchUserData(silent: true);
          return;
        }

        // ✅ Tampilkan dialog berurutan: penalti → bonus pertama hari ini → bonus harian
        if (penalty > 0) {
          final int daysAbsent = (result['days_absent'] as num?)?.toInt() ?? 0;
          await _showPenaltyDialogAndWait(
            -penalty,
            _lang == 'EN'
                ? 'Penalty for not logging in $daysAbsent days: -$penalty points'
                : _lang == 'ZH'
                    ? '未登录$daysAbsent天的罚分：-$penalty积分'
                    : 'Penalti tidak login $daysAbsent hari: -$penalty poin',
          );
          if (!mounted) return;
          // Refresh poin setelah penalti ditampilkan
          _fetchUserData(silent: true);
        }

        if (isFirstToday && firstTodayBonus > 0) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          await _showLoginPointDialogAndWait(
            firstTodayBonus,
            _getConfig('login_pertama_hari_ini', firstTodayBonus),
          );
          if (!mounted) return;
          _fetchUserData(silent: true);
        }

        if (dailyBonus > 0) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          await _showLoginPointDialogAndWait(
            dailyBonus,
            _getConfig('login_harian', dailyBonus),
          );
          if (!mounted) return;
          // ✅ Refresh data setelah semua dialog selesai → animasi poin update
          _fetchUserData(silent: true);
        }

      } catch (e) {
        debugPrint("Error handling daily login points: $e");
      }
    }
  }

  /// Menampilkan dialog login poin dan MENUNGGU sampai user klik tombol
  Future<void> _showLoginPointDialogAndWait(int points, String description) async {
    if (!mounted) return;
    final completer = Completer<void>();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => _LoginPointDialog(
        points: points,
        description: description,
        lang: _lang,
        userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        userLokasiId: _userLokasiId,
        onClaimed: () {
          Navigator.of(dialogContext).pop();
          _fetchUserData(silent: true);
          if (!completer.isCompleted) completer.complete();
        },
        onClaimedAndShared: (receiverUser) async {
          Navigator.of(dialogContext).pop();
          try {
            await Supabase.instance.client.rpc('share_login_points', params: {
              'p_sharer_id': Supabase.instance.client.auth.currentUser?.id,
              'p_receiver_id': receiverUser['id_user'],
              'p_share_amount': 5,
            });
            if (mounted) {
              int sharedAmt = 5;
              int bonusAmt = 1;
              try {
                final cfg = await Supabase.instance.client
                    .from('konfigurasi_poin')
                    .select('kode, poin')
                    .inFilter('kode', ['berbagi_poin', 'bonus_berbagi'])
                    .eq('is_aktif', true);
                for (final row in cfg) {
                  if (row['kode'] == 'berbagi_poin') {
                    sharedAmt = (row['poin'] as num).toInt().abs();
                  } else if (row['kode'] == 'bonus_berbagi') {
                    bonusAmt = (row['poin'] as num).toInt().abs();
                  }
                }
              } catch (_) {}
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 16),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          } catch (e) {
            debugPrint('Error sharing points: $e');
          }
          _fetchUserData(silent: true);
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
  }

  /// Menampilkan dialog penalti dan MENUNGGU sampai user klik tombol OK
  Future<void> _showPenaltyDialogAndWait(int points, String description) async {
    if (!mounted) return;
    final completer = Completer<void>();
    final Map<String, Map<String, String>> texts = {
      'EN': {'title': 'Points Deducted!', 'sub': 'You missed some login days.', 'ok': 'Got It'},
      'ID': {'title': 'Poin Dikurangi!', 'sub': 'Kamu melewatkan beberapa hari login.', 'ok': 'Mengerti'},
      'ZH': {'title': '积分已扣除！', 'sub': '您错过了一些登录天数。', 'ok': '明白'},
    };
    final t = texts[_lang] ?? texts['ID']!;
    final int absPoints = points.abs();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _PenaltyDialog(
        absPoints: absPoints,
        description: description,
        title: t['title']!,
        okLabel: t['ok']!,
        onDismiss: () {
          Navigator.of(ctx).pop();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
  }

  // === TAMBAHAN BARU: Fungsi untuk mendengarkan poin baru ===
  void _setupPointListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _pointChannel = Supabase.instance.client
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
            final String description = (newLog['deskripsi'] ?? '').toString();
            final String tipe = (newLog['tipe_aktivitas'] ?? '').toString();

            if (points == 0) return;

            // ── UPDATE POIN & LOG LANGSUNG dari realtime payload ──
            if (mounted) {
              setState(() {
                
              });
              // Tidak perlu notifier tambahan — cukup setState saja
            }

            // Tipe login — skip dialog
            const Set<String> loginTipes = {
              'login_pertama',
              'login_harian',
              'login_pertama_hari_ini',
              'penalti',
            };

            // Tipe verifikasi — skip dialog
            const Set<String> verifTipes = {
              'verifikasi_partisipasi',
              'verifikasi_benar',
              'verifikasi_salah',
            };

            if (loginTipes.contains(tipe)) {
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) _fetchUserData(silent: true);
              return;
            }

            if (verifTipes.contains(tipe)) {
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) _fetchUserData(silent: true);
              return;
            }

            // ── Untuk tipe lainnya: simpan pending notif ──
            _pendingPointNotif = _PendingPointNotif(
              points: points,
              description: description,
              tipe: tipe,
            );

            // Tunggu 1.5 detik agar navigation pop selesai dulu
            await Future.delayed(const Duration(milliseconds: 1500));
            if (!mounted) return;

            // Refresh data user (poin, log) dari DB
            await _fetchUserData(silent: true);

            // Tampilkan dialog notif
            if (mounted) _tryShowPendingNotif();
          },
        )
        .subscribe();
  }

  // === TAMBAHAN BARU: Dialog pop-up untuk notifikasi poin ===
  // void _showPointGainedDialog(int points, String description) {
  //   if (points == 0) return;

  //   final bool isPositive = points > 0;
  //   final Color glowColor = isPositive ? Colors.green : Colors.red;
  //   final Color textColor =
  //       isPositive ? Colors.green.shade700 : Colors.red.shade700;
  //   final IconData icon =
  //       isPositive ? Icons.star_rounded : Icons.remove_circle_rounded;
  //   final Color iconColor = isPositive ? Colors.amber : Colors.red.shade400;
  //   final String pointsLabel = isPositive ? '+$points POIN' : '$points POIN';

  //   showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (dialogContext) {
  //       // Tutup otomatis setelah 3.5 detik
  //       Future.delayed(const Duration(milliseconds: 3500), () {
  //         if (Navigator.of(dialogContext).canPop()) {
  //           Navigator.of(dialogContext).pop();
  //         }
  //       });

  //       return Center(
  //         child: Material(
  //           color: Colors.transparent,
  //           child: Container(
  //             margin: const EdgeInsets.symmetric(horizontal: 40),
  //             padding:
  //                 const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(28),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: glowColor.withOpacity(0.25),
  //                   blurRadius: 30,
  //                   spreadRadius: 8,
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(
  //                   padding: const EdgeInsets.all(16),
  //                   decoration: BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     color: glowColor.withOpacity(0.1),
  //                     border: Border.all(
  //                       color: glowColor.withOpacity(0.3),
  //                       width: 2,
  //                     ),
  //                   ),
  //                   child: Icon(icon, color: iconColor, size: 60),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 Text(
  //                   pointsLabel,
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 32,
  //                     fontWeight: FontWeight.w900,
  //                     color: textColor,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   description,
  //                   textAlign: TextAlign.center,
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 13,
  //                     fontWeight: FontWeight.w500,
  //                     color: const Color(0xFF1E3A8A),
  //                     height: 1.5,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 ClipRRect(
  //                   borderRadius: BorderRadius.circular(10),
  //                   child: LinearProgressIndicator(
  //                     value: null,
  //                     minHeight: 4,
  //                     backgroundColor: glowColor.withOpacity(0.1),
  //                     valueColor: AlwaysStoppedAnimation<Color>(glowColor),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   'Menutup otomatis...',
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 11,
  //                     color: Colors.grey.shade400,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  void dispose() {
    if (_pointChannel != null) {
      Supabase.instance.client.removeChannel(_pointChannel!);
    }
    WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    // is_verificator true sekarang tetap di HomeScreen dengan role Verificator
    // Tidak perlu redirect atau sign out
  }

  Future<void> _checkExecutiveVerificatorStatus() async {
    try{
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
        .from('User')
        .select('id_jabatan, is_verificator')
        .eq('id_user', userId)
        .single();

      final bool isVerif = data['is_verificator'] as bool? ?? false;

      if (mounted) {
        setState(() {
           _isExecutiveVerificator = isVerif; 
        });
      }
    } catch (e) {
      debugPrint('Error checking exec verificator: $e');
    }
  }

  Future<void> _fetchNotificationCount() async {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final count = await Supabase.instance.client
          .from('temuan')
          .count(CountOption.exact)
          .eq('id_penanggung_jawab', user.id)
          .neq('status_temuan', 'Selesai');
      
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notification count: $e");
    }
  }

  // Mode Visitor (is_visitor)
  Future<void> _loadInitialVisitorStatus() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('User')
          .select('is_visitor')
          .eq('id_user', userId)
          .single();
      
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
    setState(() {
      _isVisitorMode = isVisitor;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('User')
          .update({'is_visitor': isVisitor})
          .eq('id_user', userId);

      _showVisitorStatusDialog(isVisitor);

    } catch (e) {
      debugPrint('Error updating visitor status: $e');
      _showCustomDialog(
        title: getTxt('update_failed'),
        imagePath: 'assets/images/failed.png', 
      );
    }
  }

  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('lang') ?? 'EN';
    });
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

 Future<void> _fetchUserData({bool silent = false}) async {
    if (!silent && widget.initialUserName == null) {
      if (mounted) {
        setState(() {
          _isUserDataLoading = true;
          _isLatestLogLoading = true;
          _latestLogPoin = null;
        });
      }
    }
    // Selalu lakukan silent refresh tanpa mengubah _isUserDataLoading
    // kecuali memang pertama kali load

    try {
      final userAuth = Supabase.instance.client.auth.currentUser;
      if (userAuth == null) return;

      final userRow = await Supabase.instance.client
          .from('User')
          .select('nama, email, poin, gambar_user, id_jabatan, id_unit, id_lokasi, id_subunit, id_area, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .eq('id_user', userAuth.id)
          .maybeSingle();

      final String? metaName = userAuth.userMetadata?['full_name'] ?? userAuth.userMetadata?['name'];
      final String? metaImage = userAuth.userMetadata?['avatar_url'] ?? userAuth.userMetadata?['picture'];

      if (userRow == null) {
        if (!mounted) return;
        setState(() {
          _userName = metaName ?? 'User';
          _userPoin = 0;
          _displayedPoin = 0;
          _userImage = metaImage;
          _userRole = 'Staff';
          _userLocationName = '...';
          _isUserDataLoading = false;
        });
        return;
      }

      // Resolusi lokasi
      String locationName = '...';
      final idArea    = userRow['id_area'];
      final idSubunit = userRow['id_subunit'];
      final idUnit    = userRow['id_unit'];
      final idLokasi  = userRow['id_lokasi'];

      if (idArea != null) {
        final data = await Supabase.instance.client
            .from('area').select('nama_area').eq('id_area', idArea).maybeSingle();
        locationName = data?['nama_area'] ?? locationName;
      } else if (idSubunit != null) {
        final data = await Supabase.instance.client
            .from('subunit').select('nama_subunit').eq('id_subunit', idSubunit).maybeSingle();
        locationName = data?['nama_subunit'] ?? locationName;
      } else if (idUnit != null) {
        final data = await Supabase.instance.client
            .from('unit').select('nama_unit').eq('id_unit', idUnit).maybeSingle();
        locationName = data?['nama_unit'] ?? locationName;
      } else if (idLokasi != null) {
        final data = await Supabase.instance.client
            .from('lokasi').select('nama_lokasi').eq('id_lokasi', idLokasi).maybeSingle();
        locationName = data?['nama_lokasi'] ?? locationName;
      }

      final bool isVerifFromDb = userRow['is_verificator'] as bool? ?? false;

      String roleName;
      if (isVerifFromDb) {
        roleName = JabatanHelper.getDisplayRole(
          isVerificatorFlag: true,
          idJabatan: userRow['id_jabatan'] as int?,
          jabatanFromDb: userRow['jabatan']?['nama_jabatan'],
          lang: _lang,
        );
      } else if (userRow['jabatan'] != null && userRow['jabatan']['nama_jabatan'] != null) {
        roleName = userRow['jabatan']['nama_jabatan'];
      } else {
        roleName = 'Staff';
      }

      String? dbImage = userRow['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      Map<String, dynamic>? latestLog;
      try {
        final logs = await Supabase.instance.client
            .from('log_poin')
            .select('poin, deskripsi, tipe_aktivitas, created_at')
            .eq('id_user', userAuth.id)
            .order('created_at', ascending: false)
            .limit(1);
        if (logs.isNotEmpty) latestLog = logs.first;
      } catch (_) {}

      if (!mounted) return;

      final int newPoin = (userRow['poin'] as num?)?.toInt() ?? 0;
      final bool shouldAnimate = newPoin != _displayedPoin && !_isAnimatingPoin;

      setState(() {
        _userName          = userRow['nama'] ?? metaName ?? 'User';
        _userPoin          = newPoin;
        _userImage         = dbImage ?? metaImage;
        _userRole          = roleName;
        _isExecutiveVerificator = isVerifFromDb;
        _userJabatanId     = userRow['id_jabatan'] as int?;
        _userUnitId        = userRow['id_unit']?.toString();
        _userLokasiId      = userRow['id_lokasi']?.toString();
        _userLocationName  = locationName;
        // Hanya update latestLog jika tidak sedang ada animasi aktif
        // agar log tidak berubah di tengah animasi poin
        if (latestLog != null) _latestLogPoin = latestLog;
        _isLatestLogLoading = false;
        _isUserDataLoading  = false;
        // Jika tidak perlu animasi, langsung set displayed
        if (!shouldAnimate) {
          _displayedPoin = newPoin;
        }
      });

      if (shouldAnimate) {
        _animatePoinUpdate(newPoin);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          _userLocationName   = 'Gagal memuat';
          _isUserDataLoading  = false;
          _isLatestLogLoading = false;
        });
      }
    }
  }

  String getTxt(String key) => _navText[_lang]![key] ?? key;

  @override
  Widget build(BuildContext context) {
    // List Layar yang akan ditampilkan
    final List<Widget> pages = [
      _buildHomeContent(), // 0: Beranda
      ExploreScreen(lang: _lang), // 1: Telusuri
      AnalyticsScreen(lang: _lang), // 2: Analitik
      RankingScreen(lang: _lang), // 3: Peringkat
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // --- 1. EFEK BACKGROUND BERCAK BIRU CERAH (BLOB GRADIENT) ---
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9E4).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9E4).withOpacity(0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // --- 2. KONTEN UTAMA APLIKASI ---
          SafeArea(
            child: Column(
              children: [
                // ==========================================
                // --- BAGIAN 1: HEADER (LOGO, NOTIF, FOTO) ---
                // ==========================================
                Container(
                  margin: const EdgeInsets.fromLTRB(15, 8, 15, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C9E4).withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // KIRI: Logo
                      Image.asset(
                        'assets/images/logo1.png',
                        height: 38,
                        errorBuilder: (c, e, s) => Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C9E4).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield,
                            color: Color(0xFF00C9E4),
                            size: 26,
                          ),
                        ),
                      ),

                      // KANAN: Notifikasi & Foto Profil
                      Row(
                        children: [
                          // Tombol Notifikasi
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => NotificationScreen(lang: _lang)),
                              ).then((_) => _fetchNotificationCount());
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C9E4).withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF00C9E4).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.mail_outlined,
                                    color: Color(0xFF1E3A8A),
                                    size: 22,
                                  ),
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
                          ),
                          const SizedBox(width: 10),

                          // Foto Profil dengan Ring Gradient
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, animation, __) => AccountScreen(
                                    lang: _lang,
                                    initialUserName: _userName,
                                    initialUserImage: _userImage,
                                    initialUserRole: _userRole,
                                    initialIsVisitor: _isVisitorMode,
                                    initialUserJabatanId: _userJabatanId,
                                    initialUserLocation: _userLocationName,
                                    initialIsVerificator: _isExecutiveVerificator,
                                  ),
                                  transitionsBuilder: (_, animation, __, child) {
                                    final slide = Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    ));
                                    return SlideTransition(position: slide, child: child);
                                  },
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
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C9E4).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: const Color(0xFF00C9E4),
                                  backgroundImage: _userImage != null
                                      ? CachedNetworkImageProvider(_userImage!)
                                      : null,
                                  child: _userImage == null
                                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // --- KONTEN HALAMAN BERUBAH SESUAI TAB ---
                Expanded(child: pages[_currentIndex]),
              ],
            ),
          ),
        ],
      ),

      extendBody: true,

      // --- BOTTOM NAVIGATION BAR (CUSTOM PREMIUM FLOATING + FAB) ---
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Kotak Latar Belakang Putih Melayang
            Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF00C9E4,
                    ).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0),
                  _buildNavItem(Icons.explore_outlined, Icons.explore, 1),
                  const SizedBox(
                    width: 50,
                  ), // Jarak ruang kosong di tengah untuk tombol +
                  _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 2),
                  _buildNavItem(
                    Icons.emoji_events_outlined,
                    Icons.emoji_events,
                    3,
                  ),
                ],
              ),
            ),

            // 2. Tombol + Melayang di Tengah
            Positioned(
              top: 0, 
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => LocationBottomSheet(
                      lang: _lang,
                      isProMode: _isProMode,
                      isVisitorMode: _isVisitorMode,
                      userUnitId: _userUnitId?.toString(),
                      userLokasiId: _userLokasiId?.toString(),
                      userRole: _userRole,
                      onFindingSaved: () async {
                        // Callback ini dipanggil langsung dari CameraFindingScreen
                        // setelah temuan berhasil disimpan
                        if (!mounted) return;
                        setState(() => _currentIndex = 0);
                        setState(() {
                          _isUserDataLoading = true;
                          _isLatestLogLoading = true;
                          _latestLogPoin = null;
                        });
                        await Future.wait([
                          _fetchUserData(silent: false),
                          _fetchNotificationCount(),
                        ]);
                        if (!mounted) return;
                        _homeContentKey.currentState?.refreshFindings();
                        _animatePoinUpdate(_userPoin);
                        _tryShowPendingNotif();
                      },
                    ),
                  ).then((isSuccess) async {
                    if (isSuccess == true) {
                      if (!mounted) return;
                      setState(() => _currentIndex = 0);
                      setState(() {
                        _isUserDataLoading = true;
                        _isLatestLogLoading = true;
                        _latestLogPoin = null;
                      });
                      await Future.wait([
                        _fetchUserData(silent: false),
                        _fetchNotificationCount(),
                      ]);
                      if (!mounted) return;
                      _homeContentKey.currentState?.refreshFindings();
                      _animatePoinUpdate(_userPoin);
                      _tryShowPendingNotif();
                    }
                  });
                },
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF00C9E4,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C9E4).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER Untuk Ikon Navigasi Bawah Kustom ---
  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        height: 65,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isActive ? 10 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF00C9E4).withOpacity(0.15)
                  : Colors.transparent,
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

  // Fungsi helper baru untuk menghitung progres poin
  double _getPointProgress(int points) {
    const maxPointsForFullBar = 2000; // Anggap 2000 poin adalah 100%
    final progress = points / maxPointsForFullBar;
    return progress.clamp(0.0, 1.0); // Pastikan nilai antara 0 dan 1
  }

  static const Map<String, Map<String, String>> _homeTxtMini = {
    'EN': {
      'no_findings_title': 'No Recent Findings',
      'no_findings_subtitle':
          'Recent findings you create or are involved in will appear here.',
    },
    'ID': {
      'no_findings_title': 'Belum Ada Temuan',
      'no_findings_subtitle':
          'Temuan terbaru yang Anda buat atau terlibat di dalamnya akan muncul di sini.',
    },
    'ZH': {
      'no_findings_title': '暂无最新发现',
      'no_findings_subtitle': '您创建或参与的最新发现将显示在此处。',
    },
  };

  String getHomeTxt(String key) => _homeTxtMini[_lang]?[key] ?? key;

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
      userUnitId: _userUnitId?.toString(),
      userLokasiId: _userLokasiId?.toString(),
      latestLogPoin: _latestLogPoin,
      isLatestLogLoading: _isLatestLogLoading,
      onRefresh: () async {
        final int poinSebelum = _userPoin;
        await _fetchUserData(silent: true);
        if (mounted && _userPoin != poinSebelum) {
          _animatePoinUpdate(_userPoin);
        }
        _tryShowPendingNotif();
      },
      onRequestRefresh: () {
        setState(() => _currentIndex = 1);
      },
      onViewActivityLog: () => _showActivityLogDialog(context),
      onProModeChanged: (val) {
        setState(() => _isProMode = val);
        _showProModeStatusDialog(val);
      },
      onVisitorModeChanged: _updateVisitorStatus,
      isExecVerificator: _isExecutiveVerificator,
      userJabatanId: _userJabatanId,
      onVerifPointEarned: (int earnedPoints) {
        final int newPoin = _userPoin + earnedPoints;
        setState(() => _userPoin = newPoin);
        _animatePoinUpdate(newPoin);
      },
      shouldRefreshFindings: _findingsRefreshTrigger != _lastRefreshTrigger,
      onRefreshDone: () {
        setState(() => _lastRefreshTrigger = _findingsRefreshTrigger);
      },
      buildInfoCard: () => UserInfoCard(
        userName: _userName,
        userRole: _userRole,
        userImage: _userImage,
        userPoin: _userPoin,
        userLocationName: _userLocationName,
        latestLogPoin: _latestLogPoin,
        isLatestLogLoading: _isLatestLogLoading,
        lang: _lang,
        isVerificator: _isExecutiveVerificator,
        userJabatanId: _userJabatanId,
        onViewMoreTap: () => _showActivityLogDialog(context),
      ),
    );
  }

  // Notifikasi Mode Visitor
  void _showVisitorStatusDialog(bool isVisitor) {
    final Map<String, Map<String, String>> texts = {
      'EN': {
        'on_title': 'Visitor Mode Active',
        'off_title': 'Visitor Mode Off',
        'on_sub': 'Your findings will be tagged as visitor reports.',
        'off_sub': 'Back to regular mode.',
      },
      'ID': {
        'on_title': 'Mode Pengunjung Aktif',
        'off_title': 'Mode Pengunjung Nonaktif',
        'on_sub': 'Temuan Anda akan ditandai sebagai laporan pengunjung.',
        'off_sub': 'Kembali ke mode reguler.',
      },
      'ZH': {
        'on_title': '访客模式已激活',
        'off_title': '访客模式已停用',
        'on_sub': '您的发现将被标记为访客报告。',
        'off_sub': '返回常规模式。',
      },
    };
    final t = texts[_lang] ?? texts['ID']!;

    final Color primary = isVisitor ? const Color(0xFF0891B2) : Colors.grey.shade500;
    final IconData icon = isVisitor ? Icons.visibility_rounded : Icons.visibility_off_rounded;

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
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ilustrasi (gunakan asset jika ada, fallback ke icon)
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.1),
                      border: Border.all(color: primary.withOpacity(0.3), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        isVisitor ? 'assets/images/visitor_on.png' : 'assets/images/visitor_off.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(icon, color: primary, size: 42),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVisitor ? t['on_title']! : t['off_title']!,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isVisitor ? t['on_sub']! : t['off_sub']!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade500),
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

  // ── Notifikasi mode professional ──
  void _showProModeStatusDialog(bool isProMode) {
    final Map<String, Map<String, String>> texts = {
      'EN': {
        'on_title': 'Professional Mode Active',
        'off_title': 'Professional Mode Off',
        'on_sub': 'You can now access all locations without restrictions.',
        'off_sub': 'Back to regular mode.',
      },
      'ID': {
        'on_title': 'Mode Profesional Aktif',
        'off_title': 'Mode Profesional Nonaktif',
        'on_sub': 'Anda sekarang dapat mengakses semua lokasi tanpa batasan.',
        'off_sub': 'Kembali ke mode reguler.',
      },
      'ZH': {
        'on_title': '专业模式已激活',
        'off_title': '专业模式已停用',
        'on_sub': '您现在可以不受限制地访问所有地点。',
        'off_sub': '返回常规模式。',
      },
    };
    final t = texts[_lang] ?? texts['ID']!;

    final Color primary = isProMode
        ? const Color(0xFF16A34A)
        : Colors.grey.shade500;
    final IconData icon = isProMode
        ? Icons.workspace_premium_rounded
        : Icons.workspace_premium_outlined;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 3), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
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
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.1),
                      border: Border.all(
                          color: primary.withOpacity(0.3), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        isProMode
                            ? 'assets/images/modepro.png'
                            : 'assets/images/modepro.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(icon, color: primary, size: 42),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isProMode ? t['on_title']! : t['off_title']!,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isProMode ? t['on_sub']! : t['off_sub']!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 3000),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            primary.withOpacity(0.6)),
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

  // ── Dialog khusus penalti pengurangan poin ──
  void _showPenaltyDialog(int points, String description) {
    final Map<String, Map<String, String>> texts = {
      'EN': {'title': 'Points Deducted!', 'ok': 'Got It'},
      'ID': {'title': 'Poin Dikurangi!', 'ok': 'Mengerti'},
      'ZH': {'title': '积分已扣除！', 'ok': '明白'},
    };
    final t = texts[_lang] ?? texts['ID']!;
    final int absPoints = points.abs();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _PenaltyDialog(
        absPoints: absPoints,
        description: description,
        title: t['title']!,
        okLabel: t['ok']!,
        onDismiss: () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  // ── Notif gagal update (tetap ada sebagai fallback) ──
  void _showCustomDialog({required String title, required String imagePath}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        });
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(imagePath, height: 100, width: 100,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error_outline, size: 80, color: Colors.red)),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A))),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Helper class untuk menyimpan notif yang pending ──
class _PendingPointNotif {
  final int points;
  final String description;
  final String tipe;

  const _PendingPointNotif({
    required this.points,
    required this.description,
    required this.tipe,
  });
}

// ============================================================
// DIALOG: NOTIFIKASI POIN LOGIN
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

  Map<String, String> get t => _dialogTxt[widget.lang] ?? _dialogTxt['ID']!;

  static const Map<String, Map<String, String>> _dialogTxt = {
    'ID': {
      'title': 'Poin Login Diterima!',
      'claim': 'Ambil Poin',
      'share': 'Ambil & Bagikan',
      'share_title': 'Pilih teman untuk berbagi 5 poin',
      'share_info': 'Kamu akan berbagi 5 poin dan mendapat bonus +1 poin!',
      'search': 'Cari teman...',
    },
    'EN': {
      'title': 'Login Points Received!',
      'claim': 'Claim Points',
      'share': 'Claim & Share',
      'share_title': 'Pick a friend to share 5 points',
      'share_info': 'You share 5 points and earn +1 bonus point!',
      'search': 'Search friend...',
    },
    'ZH': {
      'title': '登录积分已获得！',
      'claim': '领取积分',
      'share': '领取并分享',
      'share_title': '选择朋友分享5积分',
      'share_info': '您分享5积分并获得+1奖励积分！',
      'search': '搜索朋友...',
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
      var query = Supabase.instance.client
          .from('User')
          .select('id_user, nama, jabatan(nama_jabatan)')
          .neq('id_user', widget.userId);
      
      if (widget.userLokasiId != null) {
        query = query.eq('id_lokasi', widget.userLokasiId!);
      }

      final data = await query.order('nama').limit(50);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  // Ambil jumlah poin berbagi dari konfigurasi database
  Future<int> _getShareAmount() async {
    try {
      final data = await Supabase.instance.client
          .from('konfigurasi_poin')
          .select('poin')
          .eq('kode', 'berbagi_poin')
          .eq('is_aktif', true)
          .maybeSingle();
      return (data?['poin'] as num?)?.toInt().abs() ?? 5;
    } catch (_) {
      return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 10),
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
          // Ikon berdenyut
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C9E4).withOpacity(0.4),
                    blurRadius: 20, spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 20),
          Text(t['title']!,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          // Poin besar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8F0FF), Color(0xFFE0F7FF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${widget.points} Points',
              style: GoogleFonts.poppins(
                  fontSize: 32, fontWeight: FontWeight.w900,
                  color: const Color(0xFF0891B2)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(widget.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade600, height: 1.5)),
          ),
          const SizedBox(height: 24),
          // ── Tombol Ambil Poin ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.onClaimed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9E4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 22, color: Colors.white),
                const SizedBox(width: 8),
                Text(t['claim']!,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          // ── Tombol Bagikan ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                await _loadUsers();
                setState(() => _showUserPicker = true);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFF00C9E4), width: 1.5),
                foregroundColor: const Color(0xFF00C9E4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 22, color: Color(0xFF00C9E4)),
                const SizedBox(width: 8),
                Text(t['share']!,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPickerView() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(_users);

    return StatefulBuilder(
      builder: (context, setInner) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showUserPicker = false),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t['share_title']!,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 14,
                            color: const Color(0xFF1E3A8A))),
                  ),
                ],
              ),
            ),
            // Info banner
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
                Expanded(child: Text(t['share_info']!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0891B2)))),
              ]),
            ),
            const SizedBox(height: 10),
            // Search
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Daftar user
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
                                      child: Text(
                                        u['nama'][0].toUpperCase(),
                                        style: const TextStyle(
                                            color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u['nama'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600, fontSize: 13)),
                                          if (u['jabatan'] != null)
                                            Text(u['jabatan']['nama_jabatan'] ?? '',
                                                style: TextStyle(
                                                    fontSize: 11, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                    ),
                                    // Tampilkan poin yang akan DITERIMA penerima (+5P)
                                    FutureBuilder<int>(
                                      future: _getShareAmount(),
                                      builder: (_, snap) {
                                        final amt = snap.data ?? 5;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Dapat',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '+$amt poin',
                                                style: const TextStyle(
                                                  color: Color(0xFF16A34A),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
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
        );
      },
    );
  }
}

// ============================================================
// DIALOG: PENALTI POIN — dipakai oleh await & non-await
// ============================================================
class _PenaltyDialog extends StatefulWidget {
  final int absPoints;
  final String description;
  final String title;
  final String okLabel;
  final VoidCallback onDismiss;

  const _PenaltyDialog({
    required this.absPoints,
    required this.description,
    required this.title,
    required this.okLabel,
    required this.onDismiss,
  });

  @override
  State<_PenaltyDialog> createState() => _PenaltyDialogState();
}

class _PenaltyDialogState extends State<_PenaltyDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color red = Color(0xFFDC2626);
    const Color redLight = Color(0xFFFEF2F2);
    const Color redMid   = Color(0xFFFFE4E6);

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
                BoxShadow(
                    color: red.withOpacity(0.18),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header merah ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: redMid,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32)),
                  ),
                  child: Column(children: [
                    // Ikon dengan ring animasi
                    _PulsingRing(
                      color: red,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: red.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: red.withOpacity(0.35), width: 2),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: red, size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: red),
                    ),
                    const SizedBox(height: 6),
                    // Badge poin
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: red,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '-${widget.absPoints} Poin',
                        style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ),
                  ]),
                ),

                // ── Body ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: redLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: red.withOpacity(0.12), width: 1),
                      ),
                      child: Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7F1D1D),
                            height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar auto-close
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 6000),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 3,
                          backgroundColor: red.withOpacity(0.08),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(red.withOpacity(0.4)),
                        ),
                        child: null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tombol
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          widget.okLabel,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
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
// DIALOG: NOTIFIKASI POIN (realtime listener — non-login)
// ============================================================
class _PointNotifDialog extends StatefulWidget {
  final int points;
  final String description;
  final String tipe;
  final String lang;
  final VoidCallback onDismiss;

  const _PointNotifDialog({
    required this.points,
    required this.description,
    required this.tipe,
    required this.lang,
    required this.onDismiss,
  });

  @override
  State<_PointNotifDialog> createState() => _PointNotifDialogState();
}

class _PointNotifDialogState extends State<_PointNotifDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 50, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();

    // Auto dismiss
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _primary {
    if (!_isPositive) return const Color(0xFFDC2626);
    switch (widget.tipe) {
      case 'login_pertama': return const Color(0xFFEC4899);
      case 'login_pertama_hari_ini': return const Color(0xFFF59E0B);
      default: return const Color(0xFF16A34A);
    }
  }

  bool get _isPositive => widget.points > 0;

  IconData get _icon {
    switch (widget.tipe) {
      case 'login_pertama': return Icons.celebration_rounded;
      case 'login_harian': return Icons.today_rounded;
      case 'login_pertama_hari_ini': return Icons.emoji_events_rounded;
      default:
        return _isPositive
            ? Icons.local_fire_department_rounded
            : Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = _primary;
    final Color bgColor = primary.withOpacity(0.06);
    final String pointLabel =
        _isPositive ? '+${widget.points}' : '${widget.points}';

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
                border: Border.all(
                    color: primary.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: primary.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 4,
                      offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header berwarna ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32)),
                    ),
                    child: Column(children: [
                      _PulsingRing(
                        color: primary,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: primary.withOpacity(0.3), width: 2),
                          ),
                          child: Icon(_icon, color: primary, size: 36),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Badge poin besar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '$pointLabel Poin',
                          style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                      ),
                    ]),
                  ),

                  // ── Body ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                    child: Column(children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: primary.withOpacity(0.12), width: 1),
                        ),
                        child: Text(
                          widget.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E3A8A),
                              height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 0.0),
                          duration: const Duration(milliseconds: 4500),
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 3,
                            backgroundColor: primary.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                primary.withOpacity(0.45)),
                          ),
                          child: null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.lang == 'EN'
                            ? 'Tap anywhere to close'
                            : widget.lang == 'ZH'
                                ? '点击任意处关闭'
                                : 'Ketuk di mana saja untuk menutup',
                        style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: Colors.grey.shade400),
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

// ============================================================
// HELPER: Pulsing ring animation untuk ikon dialog
// ============================================================
class _PulsingRing extends StatefulWidget {
  final Color color;
  final Widget child;
  const _PulsingRing({required this.color, required this.child});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 1.18).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          // Ring luar berdenyut
          Transform.scale(
            scale: _anim.value,
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(
                    0.08 * (2.0 - _anim.value)),
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

// ============================================================================
// WIDGET BOTTOM SHEET: PILIH LOKASI (Lokasi -> Unit -> Subunit -> Area)
// ============================================================================
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
  int _currentLevel = 0; // 0: Lokasi, 1: Unit, 2: Subunit, 3: Area
  bool _isLoading = true;
  List<dynamic> _currentData = [];
  List<dynamic> _filteredData = [];
  String _searchQuery = "";

  List<Map<String, dynamic>> _navigationHistory = [];

  bool get _hasFullAccess => widget.isProMode || widget.userRole == 'Eksekutif';

  // --- HELPER METHODS UNTUK MENGAMBIL NAMA KOLOM SECARA DINAMIS ---
  String _getTableName(int level) => ['lokasi', 'unit', 'subunit', 'area'][level];
  String _getIdColumn(int level) => 'id_${_getTableName(level)}';
  String _getNameColumn(int level) => 'nama_${_getTableName(level)}';
  String _getChildColumn(int level) => level < 3 ? ['unit', 'subunit', 'area'][level] : '';

  @override
  void initState() {
    super.initState();
    _currentLevel = 0;
    _fetchData();
  }

  Future<void> _fetchData({String? parentId, String? parentName}) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];

      if (_currentLevel == 0) {
        data = await supabase.from('lokasi').select('id_lokasi, nama_lokasi, unit(id_unit), is_star');
      } else if (_currentLevel == 1) {
        if (_hasFullAccess) {
          data = await supabase.from('unit').select('id_unit, nama_unit, subunit(id_subunit), is_star').eq('id_lokasi', parentId!);
        } else {
          if (widget.userUnitId != null) {
            data = await supabase.from('unit').select('id_unit, nama_unit, subunit(id_subunit), is_star').eq('id_lokasi', parentId!).eq('id_unit', widget.userUnitId!);
          } else { data = []; }
        }
      } else if (_currentLevel == 2) {
        data = await supabase.from('subunit').select('id_subunit, nama_subunit, area(id_area), is_star').eq('id_unit', parentId!);
      } else if (_currentLevel == 3) {
        data = await supabase.from('area').select('id_area, nama_area, is_star').eq('id_subunit', parentId!);
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
      debugPrint("Error fetching locations: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(Map<String, dynamic> item) {
    if (_currentLevel == 3) {
      Navigator.pop(context, item);
      return;
    }

    setState(() {
      _navigationHistory.add({
        'level': _currentLevel,
        'id': item[_getIdColumn(_currentLevel)]?.toString(),
        'name': item[_getNameColumn(_currentLevel)], 
      });
      _currentLevel++;
      _searchQuery = ""; 
    });

    // Panggil ulang fetch data untuk level selanjutnya
    _fetchData(
      parentId: item[_getIdColumn(_currentLevel - 1)]?.toString(),
      parentName: item[_getNameColumn(_currentLevel - 1)],
    );
  }

  void _goBack() {
    if (_navigationHistory.isEmpty) return;

    setState(() {
      _navigationHistory.removeLast();
      _currentLevel--;
      _searchQuery = "";
    });

    if (_navigationHistory.isEmpty) {
      _currentLevel = 0;
      _fetchData(); 
    } else {
      final prev = _navigationHistory.last;
      _fetchData(parentId: prev['id'], parentName: prev['name']);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredData = _currentData.where((item) {
        String name = item[_getNameColumn(_currentLevel)].toString().toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
      _sortData();
    });
  }

  void _sortData() {
    _filteredData.sort((a, b) {
      int isStarA = a['is_star'] ?? 0;
      int isStarB = b['is_star'] ?? 0;

      if (isStarA == 1 && isStarB == 0) return -1;
      if (isStarA == 0 && isStarB == 1) return 1;
      
      final nameCol = _getNameColumn(_currentLevel);
      final nameA = a[nameCol].toString().toLowerCase();
      final nameB = b[nameCol].toString().toLowerCase();
      return nameA.compareTo(nameB);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, String>> bottomSheetTexts = {
      'EN': {
        'pilih_lokasi': 'Choose Finding Location',
        'cari': 'Search location',
        'semua': 'All Locations',
        'unit_saya': 'My Unit',
        'kosong': 'Data not found.',
        'sub': 'Sub-locations',
      },
      'ID': {
        'pilih_lokasi': 'Pilih Lokasi Temuan',
        'cari': 'Cari lokasi',
        'semua': 'Semua Lokasi',
        'unit_saya': 'Unit Saya',
        'kosong': 'Data tidak ditemukan.',
        'sub': 'Sub-lokasi',
      },
    };

    String getBsTxt(String key) => bottomSheetTexts[widget.lang]?[key] ?? key;

    String currentParentName = _navigationHistory.isEmpty
        ? (!_hasFullAccess ? getBsTxt('unit_saya') : getBsTxt('semua'))
        : _navigationHistory.last['name'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(
              getBsTxt('pilih_lokasi'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                              hintText: getBsTxt('cari'),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => QRScannerScreen(
                      lang: widget.lang,
                      isProMode: widget.isProMode,
                      isVisitorMode: widget.isVisitorMode,
                    )));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Row(
              children: [
                if (_navigationHistory.isNotEmpty)
                  GestureDetector(
                    onTap: _goBack,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                Text(
                  currentParentName.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)))
                : _filteredData.isEmpty
                ? Center(child: Text(getBsTxt('kosong'), style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final item = _filteredData[index];
                      
                      // AMBIL DATA DENGAN NAMA KOLOM (AMAN DARI ERROR)
                      final String idCol = _getIdColumn(_currentLevel);
                      final String nameCol = _getNameColumn(_currentLevel);
                      final String childCol = _getChildColumn(_currentLevel);

                      final String itemId = item[idCol]?.toString() ?? '';
                      final String itemName = item[nameCol].toString();

                      int subCount = 0;
                      if (_currentLevel < 3) {
                        final listSub = item[childCol] as List<dynamic>?;
                        subCount = listSub?.length ?? 0;
                      }

                      return GestureDetector(
                        onTap: () => _onItemTapped(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FAFE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.1)),
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
                                    Text(
                                      itemName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                                    ),
                                    if (_currentLevel < 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.account_tree_outlined, size: 14, color: Colors.black54),
                                            const SizedBox(width: 5),
                                            Text(
                                              "$subCount ${getBsTxt('sub')}",
                                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // AREA TOMBOL AKSI (BINTANG & KAMERA)
                              Row(
                                children: [
                                  // TOMBOL BINTANG
                                  GestureDetector(
                                    onTap: () async {
                                      int currentStar = item['is_star'] ?? 0;
                                      int newStar = currentStar == 1 ? 0 : 1;

                                      String tableName = _getTableName(_currentLevel);

                                      setState(() {
                                        item['is_star'] = newStar;
                                        _sortData();
                                      });

                                      await Supabase.instance.client
                                          .from(tableName)
                                          .update({'is_star': newStar})
                                          .eq(idCol, itemId);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        (item['is_star'] ?? 0) == 1
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // TOMBOL KAMERA
                                  GestureDetector(
                                    onTap: () {
  String? idL, idU, idS, idA;
  String locationName = itemName;

  if (_currentLevel == 0) { idL = itemId; }
  else if (_currentLevel == 1) { 
    idL = _navigationHistory[0]['id']?.toString(); 
    idU = itemId; 
  }
  else if (_currentLevel == 2) { 
    idL = _navigationHistory[0]['id']?.toString(); 
    idU = _navigationHistory[1]['id']?.toString(); 
    idS = itemId; 
  }
  else if (_currentLevel == 3) { 
    idL = _navigationHistory[0]['id']?.toString(); 
    idU = _navigationHistory[1]['id']?.toString(); 
    idS = _navigationHistory[2]['id']?.toString(); 
    idA = itemId; 
  }

  if (_navigationHistory.isNotEmpty) {
    final path = _navigationHistory.map((e) => e['name']).join(' / ');
    locationName = '$path / $itemName';
  }

  // Simpan callback sebelum pop (context masih valid)
  final onSaved = widget.onFindingSaved;
  
  // Tutup BottomSheet
  Navigator.pop(context);

  // Push CameraFindingScreen menggunakan navigatorKey atau
  // cukup panggil onFindingSaved sebagai callback langsung
  // dari CameraFindingScreen lewat parameter
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CameraFindingScreen(
        lang: widget.lang,
        isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        selectedLocationName: locationName,
        selectedLocationId: idL,
        selectedUnitId: idU,
        selectedSubunitId: idS,
        selectedAreaId: idA,
        onFindingSaved: onSaved, // TERUSKAN CALLBACK
      ),
    ),
  );
},
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Helper: lifecycle observer untuk refresh poin saat app kembali ke foreground ──
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  _AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}