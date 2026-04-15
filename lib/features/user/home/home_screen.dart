import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/account/account_screen.dart';
import '../accident/accident_report_list_screen.dart';
import '../explore/explore_screen.dart';
import '../analytics/analytics_screen.dart';
import '../finding/finding_detail_screen.dart';
import '../../shared/notifications/notification_screen.dart';
import '../../shared/code/qr_scanner_screen.dart';
import '../leaderboard/ranking_screen.dart';
import '../finding/camera_finding_screen.dart';
import 'location_screen.dart';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final String? initialUserName;
  final int? initialUserPoin;
  final String? initialUserImage;
  final String? initialUserRole;

  const HomeScreen({
    super.key,
    this.initialUserName,
    this.initialUserPoin,
    this.initialUserImage,
    this.initialUserRole,
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

  // Data User
  String _userName = "...";
  String _userRole = "...";
  int _userPoin = 0;
  String? _userImage;
  int? _userUnitId;
  int? _userLokasiId;

  int _notificationCount = 0;
  DateTime? _lastDialogTime;

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
      'latest_activity': 'Latest:',
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

  final t = _getPointDialogTexts();
  final bool isPositive = points > 0;

  // --- Konfigurasi visual berdasarkan positif/negatif ---
  final Color primaryColor = isPositive
      ? const Color(0xFF16A34A)   // Hijau untuk tambah poin
      : const Color(0xFFDC2626);  // Merah untuk kurang poin

  final Color bgGradientStart = isPositive
      ? const Color(0xFFD1FAE5)   // Hijau muda
      : const Color(0xFFFFE4E6);  // Merah muda

  final Color bgGradientEnd = isPositive
      ? const Color(0xFFECFDF5)
      : const Color(0xFFFFF1F2);

  final IconData mainIcon = isPositive
      ? Icons.trending_up_rounded
      : Icons.trending_down_rounded;

  final String pointsLabel = isPositive
      ? '+$points'
      : '$points'; // sudah mengandung minus dari DB

  final String title = isPositive
      ? t['gained_title']!
      : t['lost_title']!;

  // --- Ikon per tipe aktivitas ---
  IconData tipeIcon;
  switch (tipe) {
    case 'login_pertama':
      tipeIcon = Icons.celebration_rounded;
      break;
    case 'login_harian':
      tipeIcon = Icons.today_rounded;
      break;
    case 'login_pertama_hari_ini':
      tipeIcon = Icons.emoji_events_rounded;
      break;
    case 'penalti':
      tipeIcon = Icons.warning_amber_rounded;
      break;
    default:
      tipeIcon = isPositive
          ? Icons.star_rounded
          : Icons.remove_circle_outline_rounded;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (dialogContext) {
      // Tutup otomatis setelah 4 detik
      Future.delayed(const Duration(milliseconds: 4000), () {
        if (dialogContext.mounted &&
            Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });

      return GestureDetector(
        onTap: () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        },
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bgGradientStart, bgGradientEnd],
                ),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Ikon Utama dengan Ring ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.12),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        Icon(tipeIcon, color: primaryColor, size: 48),
                        // Badge tren (panah naik/turun) di pojok
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              mainIcon,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Judul ---
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- Angka Poin Besar ---
                    Text(
                      '$pointsLabel ${t['total_label']}',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Garis Pemisah ---
                    Container(
                      height: 1,
                      color: primaryColor.withOpacity(0.15),
                    ),
                    const SizedBox(height: 12),

                    // --- Deskripsi ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E3A8A),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Progress Bar Auto Close ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 4000),
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- Teks Petunjuk ---
                    Text(
                      t['tap_close']!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  @override
  void initState() {
    super.initState();
    if (widget.initialUserName != null) {
      _userName = widget.initialUserName!;
      _userPoin = widget.initialUserPoin ?? 0;
      _userImage = widget.initialUserImage;
      _userRole = widget.initialUserRole ?? 'Staff';
      _isUserDataLoading = false;
    }
    _checkVerificationStatus().then((_) {
      if (mounted) {
        _loadLanguage();
        _handleLoginAndFetchData();
      }
    });
  }

  Future<void> _handleLoginAndFetchData() async {
    if (_pointChannel != null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _setupPointListener();

    await Future.delayed(const Duration(milliseconds: 2500));

    try {
      await Supabase.instance.client
          .rpc('handle_daily_login', params: {'p_user_id': user.id});
    } catch (e) {
      debugPrint("Error handling daily login points: $e");
    }

    _fetchUserData();
    _fetchNotificationCount();
    _loadInitialVisitorStatus();
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
          callback: (payload) {
            if (!mounted) return;

            final newLog = payload.newRecord;
            final int points = (newLog['poin'] as num).toInt();
            final String description = (newLog['deskripsi'] ?? '').toString();
            final String tipe = (newLog['tipe_aktivitas'] ?? '').toString();

            if (points == 0) return;

            final now = DateTime.now();

            if (_lastDialogTime != null &&
                now.difference(_lastDialogTime!).inMilliseconds < 3800) {
              Future.delayed(const Duration(milliseconds: 3900), () {
                if (!mounted) return;
                _showPointNotificationDialog(points, description, tipe);
              });
            } else {
              // Gunakan addPostFrameCallback agar context dijamin sudah siap
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _showPointNotificationDialog(points, description, tipe);
              });
            }

            _lastDialogTime = now;
            _fetchUserData();
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
    // Hentikan listener saat halaman ditutup untuk menghindari memory leak
    if (_pointChannel != null) {
      Supabase.instance.client.removeChannel(_pointChannel!);
    }
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('User')
          .select('is_verificator')
          .eq('id_user', userId)
          .single();

      final isVerifier = data['is_verificator'] as bool?;

      if (isVerifier == true && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Akses Ditolak'),
            content: const Text('Akun verifikator tidak dapat mengakses halaman ini. Anda akan diarahkan keluar.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      debugPrint("Error checking verifier status: $e");
    }
  }

  Widget _buildShimmerPlaceholder({double width = double.infinity, double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildLoadingSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  _buildShimmerPlaceholder(height: 16), // Placeholder Judul baris 1
                  const SizedBox(height: 6),
                  _buildShimmerPlaceholder(height: 16, width: 120), // Placeholder Judul baris 2
                  const SizedBox(height: 12),
                  _buildShimmerPlaceholder(height: 12, width: 150), // Placeholder Lokasi
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerPlaceholder(height: 12, width: 80), // Placeholder Tanggal
                      _buildShimmerPlaceholder(height: 28, width: 90), // Placeholder Status
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFindingsLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3, // Jumlah kartu skeleton yang ditampilkan
        itemBuilder: (_, __) => _buildLoadingSkeletonCard(),
      ),
    );
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

      _showCustomDialog(
        title: isVisitor ? getTxt('visitor_on') : getTxt('visitor_off'),
        imagePath: isVisitor 
            ? 'assets/images/visitor_on.png'   
            : 'assets/images/visitor_off.png',
      );

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

  Color _getFireColor(int points) {
    if (points >= 1000) return const Color(0xFFEF4444); // Merah (Legendary)
    if (points >= 500) return const Color(0xFFF97316); // Oranye (Epic)
    if (points >= 100) return const Color(0xFF22C55E); // Hijau (Rare)
    if (points > 0) return const Color(0xFF3B82F6);    // Biru (Common)
    return Colors.grey.shade400;                     
  }

  // 2. Fungsi untuk menampilkan dialog log aktivitas
  void _showActivityLogDialog(BuildContext context) {
    final List<Map<String, dynamic>> dummyActivities = [
      {'icon': Icons.add_task_rounded, 'title': 'Menambahkan temuan baru', 'time': 'Baru saja', 'points': '+15'},
      {'icon': Icons.comment_rounded, 'title': 'Memberi komentar pada temuan', 'time': '5 menit lalu', 'points': '+2'},
      {'icon': Icons.check_circle_rounded, 'title': 'Menyelesaikan sebuah temuan', 'time': '1 jam lalu', 'points': '+25'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(getTxt('activity_log'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(dummyActivities.length, (index) {
                  final activity = dummyActivities[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(activity['icon'], color: const Color(0xFF0075FF), size: 24),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(activity['title'], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                              const SizedBox(height: 2),
                              Text(activity['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(activity['points'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(getTxt('close')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchUserData() async {
    if (!_isUserDataLoading) {
      
    } else {
       setState(() { _isUserDataLoading = true; });
    }
    
    try {
      final userAuth = Supabase.instance.client.auth.currentUser;
      if (userAuth == null) return;

      final userRow = await Supabase.instance.client
          .from('User')
          .select('nama, email, poin, gambar_user, id_jabatan, id_unit, id_lokasi, id_subunit, id_area, jabatan(nama_jabatan)')
          .eq('id_user', userAuth.id)
          .maybeSingle();

      final String? metaName = userAuth.userMetadata?['full_name'] ?? userAuth.userMetadata?['name'];
      final String? metaImage = userAuth.userMetadata?['avatar_url'] ?? userAuth.userMetadata?['picture'];

      if (userRow == null) {
        if (!mounted) return;
        setState(() {
          _userName = metaName ?? 'User';
          _userPoin = 0;
          _userImage = metaImage;
          _userRole = 'Staff';
          _userLocationName = 'Tidak Terdefinisi';
        });
        return;
      }
      
      String locationName = 'Tidak Terdefinisi';
      final idArea = userRow['id_area'];
      final idSubunit = userRow['id_subunit'];
      final idUnit = userRow['id_unit'];
      final idLokasi = userRow['id_lokasi'];

      if (idArea != null) {
        final data = await Supabase.instance.client.from('area').select('nama_area').eq('id_area', idArea).maybeSingle();
        locationName = data?['nama_area'] ?? locationName;
      } else if (idSubunit != null) {
        final data = await Supabase.instance.client.from('subunit').select('nama_subunit').eq('id_subunit', idSubunit).maybeSingle();
        locationName = data?['nama_subunit'] ?? locationName;
      } else if (idUnit != null) {
        final data = await Supabase.instance.client.from('unit').select('nama_unit').eq('id_unit', idUnit).maybeSingle();
        locationName = data?['nama_unit'] ?? locationName;
      } else if (idLokasi != null) {
        final data = await Supabase.instance.client.from('lokasi').select('nama_lokasi').eq('id_lokasi', idLokasi).maybeSingle();
        locationName = data?['nama_lokasi'] ?? locationName;
      }

      String roleName = 'Staff';
      if (userRow['jabatan'] != null && userRow['jabatan']['nama_jabatan'] != null) {
        roleName = userRow['jabatan']['nama_jabatan'];
      }

      String? dbImage = userRow['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      if (!mounted) return;
      setState(() {
        _userName = userRow['nama'] ?? metaName ?? 'User';
        _userPoin = userRow['poin'] ?? 0;
        _userImage = dbImage ?? metaImage;
        _userRole = roleName;
        _userJabatanId = userRow['id_jabatan']; // Simpan id jabatan
        _userUnitId = userRow['id_unit'];
        _userLokasiId = userRow['id_lokasi'];
        _userLocationName = locationName; // Simpan nama lokasi yang sudah jadi
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if(mounted) {
        setState(() {
          _userLocationName = 'Gagal memuat';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUserDataLoading = false;
        });
      }
    }
  }

  Widget _buildInfoCardSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    // Data dummy untuk log aktivitas
    final List<Map<String, dynamic>> dummyActivities = [
      {'icon': Icons.add_task_rounded, 'title': 'Menambahkan temuan baru', 'time': 'Baru saja', 'points': '+15'},
      {'icon': Icons.comment_rounded, 'title': 'Memberi komentar pada temuan', 'time': '5 menit lalu', 'points': '+2'},
      {'icon': Icons.check_circle_rounded, 'title': 'Menyelesaikan sebuah temuan', 'time': '1 jam lalu', 'points': '+25'},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Log Aktivitas",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Column(
              children: List.generate(dummyActivities.length, (index) {
                final activity = dummyActivities[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    children: [
                      Icon(activity['icon'], color: const Color(0xFF0075FF), size: 24),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'],
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity['time'],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        activity['points'],
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
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
                        'assets/images/logo.png',
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
                                MaterialPageRoute(
                                  builder: (_) => AccountScreen(
                                    lang: _lang,
                                    initialUserName: _userName,
                                    initialUserImage: _userImage,
                                    initialUserRole: _userRole,
                                    initialIsVisitor: _isVisitorMode,
                                    initialUserJabatanId: _userJabatanId,
                                    initialUserLocation: _userLocationName,
                                  ),
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
                                      ? NetworkImage(_userImage!)
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
                    isScrollControlled: true, // Agar bisa full screen jika data banyak
                    backgroundColor: Colors.transparent,
                    builder: (context) => LocationBottomSheet(
                      lang: _lang,
                      isProMode: _isProMode,
                      isVisitorMode: _isVisitorMode,
                      userUnitId: _userUnitId,
                      userLokasiId: _userLokasiId,
                      userRole: _userRole,
                    ),
                  ).then((isSuccess) {
                    // Logika ini tetap berguna untuk me-refresh data setelah temuan berhasil disimpan
                    // dan semua layar (form, kamera, lokasi) sudah di-pop.
                    if (isSuccess == true) {
                      _handleLoginAndFetchData();
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

  // Desain Konten Beranda Asli
  Widget _buildHomeContent() {
    // Dictionary Bahasa khusus untuk area konten beranda
    final Map<String, Map<String, String>> homeTexts = {
      'EN': {
        'inspeksi': 'Inspection',
        'pro_mode': 'Professional Mode',
        'visitor_mode': 'Visitor Mode',
        'laporan_cepat': 'Quick Report',
        'telusur': 'Browse & Manage',
        'lokasi': 'Location',
        'laporan': 'Accident Report',
        'hint': 'Click the + button to add a new finding.',
        'no_findings_title': 'No Recent Findings',
        'no_findings_subtitle': 'Recent findings you create or are involved in will appear here.',
        'recent_findings': 'Recent Findings', // TAMBAHKAN KEMBALI KUNCI INI
      },
      'ID': {
        'inspeksi': 'Inspeksi',
        'pro_mode': 'Mode Profesional',
        'visitor_mode': 'Mode Pengunjung',
        'laporan_cepat': 'Laporan Cepat',
        'telusur': 'Telusur & Atur',
        'lokasi': 'Lokasi',
        'laporan': 'Laporan Kecelakaan',
        'hint': 'Klik tombol + untuk memasukkan temuan baru.',
        'no_findings_title': 'Belum Ada Temuan',
        'no_findings_subtitle': 'Temuan terbaru yang Anda buat atau terlibat di dalamnya akan muncul di sini.',
        'recent_findings': 'Temuan Terbaru', // TAMBAHKAN KEMBALI KUNCI INI
      },
      'ZH': {
        'inspeksi': '检查',
        'pro_mode': '专业模式',
        'visitor_mode': '访客模式',
        'laporan_cepat': '快速报告',
        'telusur': '浏览与管理',
        'lokasi': '地点',
        'laporan': '事故报告',
        'hint': '点击 + 按钮添加新发现。',
        'no_findings_title': '暂无最新发现',
        'no_findings_subtitle': '您创建或参与的最新发现将显示在此处。',
        'recent_findings': '最新发现', // TAMBAHKAN KEMBALI KUNCI INI
      },
    };

    String getHomeTxt(String key) => homeTexts[_lang]?[key] ?? key;
    
    // Data dummy untuk log aktivitas terbaru
    final Map<String, dynamic> latestActivity = {
      'title': 'Menambahkan temuan baru',
      'points': '+15'
    };

    final pointProgress = _getPointProgress(_userPoin);
    final fireColor = _getFireColor(_userPoin);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
        // INFO CARD BARU YANG SUDAH DISESUAIKAN
        // ==========================================
        if (_isUserDataLoading)
          _buildInfoCardSkeleton()
        else
          Container(
            margin: const EdgeInsets.only(bottom: 25),
            padding: const EdgeInsets.all(20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB8F0FF), // Biru cerah kiri atas
                  Color(0xFFE8FAFF), // Biru muda tengah
                  Color(0xFFFFFBD6), // Kuning muda tengah-kanan
                  Color(0xFFB6F5C8), // Hijau cerah kanan bawah
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // --- Konten Utama Info Card ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BAGIAN ATAS: NAMA & JABATAN vs LOG TERBARU
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kiri: Foto, Nama, Jabatan
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF00C9E4),
                              backgroundImage: _userImage != null ? NetworkImage(_userImage!) : null,
                              child: _userImage == null ? const Icon(Icons.person, color: Colors.white, size: 24) : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                                ),
                                Text(
                                  _userRole,
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Kanan: Log Aktivitas Terbaru
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              getTxt('latest_activity'),
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${latestActivity['title']} (${latestActivity['points']})",
                              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // BAGIAN TENGAH: INDIKATOR POIN PROGRESIF
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double fireIconSize = 28.0;
                        final double circlePadding = 6.0;
                        final double totalSize = fireIconSize + (circlePadding * 2);
                        final double halfTotal = totalSize / 2;

                        final double rawLeft = constraints.maxWidth * pointProgress;
                        final double clampedLeft = rawLeft.clamp(0.0, constraints.maxWidth - totalSize);

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Garis Background
                            Container(
                              margin: EdgeInsets.only(top: halfTotal),
                              width: double.infinity,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                    width: rawLeft.clamp(0.0, constraints.maxWidth),
                                    decoration: BoxDecoration(
                                      color: fireColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Ikon Api dengan Lingkaran
                            Positioned(
                              left: clampedLeft,
                              top: 0,
                              child: Column(
                                children: [
                                  Container(
                                    width: totalSize,
                                    height: totalSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: fireColor.withOpacity(0.15),
                                      border: Border.all(color: fireColor.withOpacity(0.4), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: fireColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.local_fire_department_rounded,
                                        color: fireColor,
                                        size: fireIconSize,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "$_userPoin P",
                                    style: GoogleFonts.poppins(color: fireColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // BAGIAN BAWAH: TOMBOL VIEW MORE
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: () => _showActivityLogDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(getTxt('view_more'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ==========================================
          // 1. BAGIAN INSPEKSI (MODE PROFESIONAL)
          // ==========================================
          if (_userRole == 'Eksekutif') ...[
            Text(
              getHomeTxt('inspeksi'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_ind_outlined,
                        color: Color(0xFF1E3A8A),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        getHomeTxt('pro_mode'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isProMode,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.orange.shade300,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (value) {
                      setState(() {
                        _isProMode = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],

          // ==========================================
          // 2. BAGIAN MODE VISITOR (UNTUK SEMUA USER)
          // ==========================================
          Text(
            getHomeTxt('laporan_cepat'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F9), // Warna berbeda (biru muda)
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyan.shade200, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined, // Ikon berbeda
                      color: Color(0xFF1E3A8A),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      getHomeTxt('visitor_mode'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isVisitorMode,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.cyan.shade300,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  onChanged: (value) {
                    _updateVisitorStatus(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // ==========================================
          // 3. BAGIAN TELUSUR & ATUR
          // ==========================================
          Text(
            getHomeTxt('telusur'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),

          // Tombol Lokasi
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 2,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.lightBlue,
                  size: 24,
                ),
              ),
              title: Text(
                getHomeTxt('lokasi'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black38,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocationScreen(
                      lang: _lang,
                      isProMode: _isProMode,
                      userRole: _userRole,
                      userUnitId: _userUnitId,
                      userLokasiId: _userLokasiId,
                    ),
                  ),
                );
              },
            ),
          ),

          // Tombol Laporan Kecelakaan
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 2,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
              title: Text(
                getHomeTxt('laporan'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black38,
              ),
              // 2. MODIFIKASI BAGIAN onTap INI
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccidentReportListScreen(lang: _lang),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              getHomeTxt('recent_findings'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),

          FutureBuilder<List<Map<String, dynamic>>>(
            // Query diubah untuk mengambil semua data yang dibutuhkan oleh _buildFindingCard
            future: Supabase.instance.client
                .from('temuan')
                .select('''
                  id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan,
                  poin_temuan, target_waktu_selesai,
                  id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab,
                  lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
                  is_pro, is_visitor, is_eksekutif
                ''')
                .order('created_at', ascending: false)
                .limit(4), // Batasi menjadi 3 untuk awal
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildRecentFindingsLoader();
              }

              // Jika tidak ada data atau error, tampilkan ilustrasi
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/team_illustration.png',
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.search_off, size: 100, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          getHomeTxt('no_findings_title'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getHomeTxt('no_findings_subtitle'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                         const SizedBox(height: 20),
                         Text(
                          getHomeTxt('hint'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Jika ada data, tampilkan ListView dari kartu temuan
              final findings = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll internal
                itemCount: findings.length,
                itemBuilder: (context, index) {
                  return _buildFindingCard(findings[index]); // Gunakan widget baru
                },
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Notifikasi Mode Visitor
  void _showCustomDialog({required String title, required String imagePath}) {
    showDialog(
      context: context,
      barrierDismissible: true, // Boleh ditutup dengan klik di luar dialog
      builder: (BuildContext context) {
        // Hilangkan dialog secara otomatis setelah beberapa detik
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
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
                Image.asset(
                  imagePath,
                  height: 100,
                  width: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      imagePath.contains('success') ? Icons.check_circle_outline : Icons.error_outline,
                      size: 80,
                      color: imagePath.contains('success') ? Colors.green : Colors.red,
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatLocation(Map<String, dynamic> item) {
    if (item['area'] != null && item['area']['nama_area'] != null) {
      return item['area']['nama_area'].toString();
    }
    if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) {
      return item['subunit']['nama_subunit'].toString();
    }
    if (item['unit'] != null && item['unit']['nama_unit'] != null) {
      return item['unit']['nama_unit'].toString();
    }
    if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) {
      return item['lokasi']['nama_lokasi'].toString();
    }
    return '-';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildFindingCard(Map<String, dynamic> data) {
    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final title = (data['judul_temuan'] ?? '-').toString();
    final lokasi = _formatLocation(data);
    final tanggal = _formatDate(data['created_at']);
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final status = (data['status_temuan'] ?? '').toString();

    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;

    final s = status.toLowerCase();
    final isFinished = ['selesai', 'done', 'completed', 'closed'].any((e) => s.contains(e));
    
    final String statusText = isFinished ? 'Selesai' : 'Belum Selesai';

    late Color statusColor;
    late Color statusBg;
    late IconData statusIcon;

    if (isFinished) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFF0FDF4);
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
      statusIcon = Icons.pending_actions_rounded;
    }

    List<Widget> badges = [];
    List<String> inspectionTypes = [];

    if (isPro) inspectionTypes.add('pro');
    if (isVisitor) inspectionTypes.add('visitor');
    if (isEksekutif) inspectionTypes.add('eksekutif');

    if (inspectionTypes.contains('pro')) {
      badges.add(_buildInspectionBadge('PROFESIONAL', const Color.fromARGB(255, 255, 244, 45), Colors.black));
    }
    if (inspectionTypes.contains('visitor')) {
      badges.add(_buildInspectionBadge('VISITOR', const Color(0xFF3B82F6), Colors.white));
    }
    if (inspectionTypes.contains('eksekutif')) {
      badges.add(_buildInspectionBadge('EKSEKUTIF', const Color(0xFFEF4444), Colors.white));
    }

    inspectionTypes.sort();
    String combinationKey = inspectionTypes.join('+');

    final Color borderColor;
    switch (combinationKey) {
      case 'eksekutif+pro+visitor': borderColor = const Color(0xFF9333EA); break;
      case 'pro+visitor': borderColor = const Color(0xFF16A34A); break;
      case 'eksekutif+pro': borderColor = const Color(0xFFEA580C); break;
      case 'eksekutif+visitor': borderColor = const Color(0xFF2563EB); break;
      case 'pro': borderColor = const Color(0xFFF59E0B); break;
      case 'visitor': borderColor = const Color(0xFF3B82F6); break;
      case 'eksekutif': borderColor = const Color(0xFFEF4444); break;
      default: borderColor = const Color(0xFFF1F5F9);
    }
    
    Widget? timeIndicator;
    // Time indicator logic tidak diperlukan untuk home, jadi kita biarkan null

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => FindingDetailScreen(initialData: data, lang: _lang),
        )).then((_) => _handleLoginAndFetchData()); // Refresh data saat kembali
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: borderColor == const Color(0xFFF1F5F9) ? 1.0 : 1.5),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.15), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: Container(
                        color: const Color(0xFFF8FAFC),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey))
                            : const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFFF6B3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('$poin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                  const SizedBox(width: 3),
                                  const Text('Poin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (badges.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Wrap(spacing: 6, runSpacing: 4, children: badges)),
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Expanded(child: Text(lokasi, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(tanggal, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 13, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(statusText, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (timeIndicator != null) timeIndicator,
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
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
  final int? userUnitId;
  final int? userLokasiId;
  final String userRole;

  const LocationBottomSheet({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.isVisitorMode,
    required this.userRole,
    this.userUnitId,
    this.userLokasiId,
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

  Future<void> _fetchData({int? parentId, String? parentName}) async {
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
        'id': item[_getIdColumn(_currentLevel)], 
        'name': item[_getNameColumn(_currentLevel)], 
      });
      _currentLevel++;
      _searchQuery = ""; 
    });

    // Panggil ulang fetch data untuk level selanjutnya
    _fetchData(
      parentId: item[_getIdColumn(_currentLevel - 1)],
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

                      final int itemId = item[idCol] as int;
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
                                      // --- MODIFIKASI DIMULAI DI SINI ---
                                      int? idL, idU, idS, idA;
                                      String locationName = itemName;

                                      // Logika untuk mendapatkan ID hierarki
                                      if (_currentLevel == 0) { idL = itemId; }
                                      else if (_currentLevel == 1) { idL = _navigationHistory[0]['id']; idU = itemId; }
                                      else if (_currentLevel == 2) { idL = _navigationHistory[0]['id']; idU = _navigationHistory[1]['id']; idS = itemId; }
                                      else if (_currentLevel == 3) { idL = _navigationHistory[0]['id']; idU = _navigationHistory[1]['id']; idS = _navigationHistory[2]['id']; idA = itemId; }

                                      // Gabungkan nama untuk ditampilkan di kamera (opsional, tapi bagus)
                                      if (_navigationHistory.isNotEmpty) {
                                          final path = _navigationHistory.map((e) => e['name']).join(' / ');
                                          locationName = '$path / $itemName';
                                      }

                                      // Pop Bottom Sheet terlebih dahulu
                                      Navigator.pop(context); 

                                      // Navigasi ke CameraFindingScreen dengan membawa semua data yang diperlukan
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
                                          ),
                                        ),
                                      ).then((isSuccess) {
                                          // Jika temuan berhasil disimpan dari flow selanjutnya,
                                          // kita teruskan sinyal 'true' ke atas (ke HomeScreen).
                                          if (isSuccess == true) {
                                            // Coba pop lagi untuk menutup bottom sheet (jika belum tertutup)
                                            // dan kirim sinyal sukses ke home
                                            if (Navigator.canPop(context)) {
                                                Navigator.pop(context, true);
                                            }
                                          }
                                      });
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