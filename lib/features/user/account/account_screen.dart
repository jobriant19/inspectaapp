import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/jabatan_helper.dart';
import '../../auth/login_screen.dart';
import 'profile/profile_screen.dart';
import 'about_inspecta_screen.dart';
import 'help_center_screen.dart';
import 'privacy_security_screen.dart';
import 'news_screen.dart';
import 'package:shimmer/shimmer.dart';

class AccountScreen extends StatefulWidget {
  final String lang;
  final String? initialUserName;
  final String? initialUserImage;
  final String? initialUserRole;
  final String? initialUserLocation;
  final String? initialUserLocationLevel;
  final bool? initialIsVisitor;
  final int? initialUserJabatanId;
  final bool? initialIsVerificator;
  
  const AccountScreen({
    super.key, 
    required this.lang,
    this.initialUserName,
    this.initialUserImage,
    this.initialUserRole,
    this.initialUserLocation,
    this.initialUserLocationLevel,
    this.initialIsVisitor,
    this.initialUserJabatanId,
    this.initialIsVerificator,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late String _currentLang;
  bool _isLoading = true;

  // Data User
  String _userName = "Loading...";
  String? _userImage;
  String _userJabatan = "Loading...";
  String _userLokasiSpesifik = "Tidak terdefinisi";
  String? _userLokasiLevel;
  bool _isVisitor = false;
  int? _userJabatanId;
  bool _isVerificatorUser = false;
  String? _cachedAppName;
  String? _cachedAppVersion;
  String? _cachedAppWebsite;

  // Kamus terjemahan
  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'My Account',
      'edit_profile': 'Edit Profile',
      'change_lang': 'Change Language',
      'current_lang': 'English',
      'about': 'About Inspecta',
      'help': 'Help Center',
      'privacy': 'Privacy & Security',
      'news': 'Latest News',
      'news_title': 'Latest News',
      'update_notes': 'Update Notes',
      'maintenance_notices': 'Maintenance Notices',
      'logout': 'Logout',
      'logout_desc': 'End your session on this device',
      'select_lang': 'Select Language',
      'visitor': 'Visitor',
      'verifier_role': 'Verifier',
      'cancel': 'Cancel'
    },
    'ID': {
      'title': 'Akun Saya',
      'edit_profile': 'Ubah Profil',
      'change_lang': 'Ganti Bahasa',
      'current_lang': 'Bahasa Indonesia',
      'about': 'Tentang Inspecta',
      'help': 'Pusat Bantuan',
      'privacy': 'Privasi dan Keamanan',
      'news': 'Kabar Terbaru',
      'news_title': 'Kabar Terbaru',
      'update_notes': 'Catatan Pembaruan',
      'maintenance_notices': 'Pemberitahuan Pemeliharaan',
      'logout': 'Keluar Akun',
      'logout_desc': 'Akhiri sesi Anda di perangkat ini',
      'select_lang': 'Pilih Bahasa',
      'visitor': 'Pengunjung',
      'verifier_role': 'Verifier',
      'cancel': 'Batal'
    },
    'ZH': {
      'title': '我的账户',
      'edit_profile': '编辑个人资料',
      'change_lang': '更改语言',
      'current_lang': '中文',
      'about': '关于 Inspecta',
      'help': '帮助中心',
      'privacy': '隐私与安全',
      'news': '最新消息',
      'news_title': '最新消息',
      'update_notes': '更新记录',
      'maintenance_notices': '维护通知',
      'logout': '登出',
      'logout_desc': '在此设备上结束您的会话',
      'select_lang': '选择语言',
      'visitor': '访客',
      'verifier_role': '验证者',
      'cancel': '取消'
    },
  };

  String getTxt(String key) => _txt[_currentLang]?[key] ?? key;

  static const Map<String, Color> _levelColors = {
    'lokasi': Color(0xFF10B981),
    'unit': Color(0xFF6366F1),
    'subunit': Color(0xFFFBBF24),
    'area': Color(0xFFF472B6),
  };

  static const Map<String, String> _flagMap = {
    'ID': '🇮🇩',
    'EN': '🇺🇸',
    'ZH': '🇨🇳',
  };

  Color get _locationColor =>
      _levelColors[_userLokasiLevel?.toLowerCase()] ?? const Color(0xFFF472B6);

  Color _darken(Color color, [double amount = 0.16]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;

    _userName           = widget.initialUserName ?? '';
    _userImage          = widget.initialUserImage;
    _userLokasiSpesifik = widget.initialUserLocation ?? '...';
    _userLokasiLevel    = widget.initialUserLocationLevel;
    _isVisitor          = widget.initialIsVisitor ?? false;
    _userJabatanId      = widget.initialUserJabatanId;
    _isVerificatorUser  = widget.initialIsVerificator ?? false;

    if (_isVisitor) {
      _userJabatan = getTxt('visitor');
    } else if (_isVerificatorUser) {
      _userJabatan = getTxt('verifier_role');
    } else {
      _userJabatan = widget.initialUserRole ?? '...';
    }

    _isLoading = false;

    _fetchUserDataSilent();
    _prefetchAppInfo();

    // Precache gambar About Inspecta di background
    // sehingga saat layar About dibuka, gambar sudah ada di cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/logo1.PNG'), context)
          .catchError((_) {});
      precacheImage(const AssetImage('assets/images/flutter.png'), context)
          .catchError((_) {});
      precacheImage(const AssetImage('assets/images/supabase.png'), context)
          .catchError((_) {});
    });
  }

  Widget _buildSkeletonProfileCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            // Placeholder Gambar
            const CircleAvatar(radius: 35, backgroundColor: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder Nama
                  Container(height: 20, width: 150, color: Colors.white),
                  const SizedBox(height: 10),
                  // Placeholder Jabatan
                  Container(height: 14, width: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  // Placeholder Lokasi
                  Container(height: 14, width: 120, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchUserDataSilent() async {
    final userAuth = Supabase.instance.client.auth.currentUser;
    if (userAuth == null) return;

    try {
      final userRow = await Supabase.instance.client
          .from('User')
          .select('nama, gambar_user, id_jabatan, is_visitor, is_verificator, id_lokasi, id_unit, id_subunit, id_area, jabatan(nama_jabatan)')
          .eq('id_user', userAuth.id)
          .maybeSingle();

      if (userRow == null || !mounted) return;

      final isVerificator = userRow['is_verificator'] as bool? ?? false;
      final String? metaImage = userAuth.userMetadata?['avatar_url'] ?? userAuth.userMetadata?['picture'];
      final isVisitor = userRow['is_visitor'] as bool? ?? false;
      final idJabatan = userRow['id_jabatan'] as int?;

      // Resolusi lokasi
      final idLokasi  = userRow['id_lokasi'];
      final idUnit    = userRow['id_unit'];
      final idSubunit = userRow['id_subunit'];
      final idArea    = userRow['id_area'];

      String locationName = _userLokasiSpesifik;
      String? locationLevel;
      if (idArea != null) {
        final data = await Supabase.instance.client.from('area').select('nama_area').eq('id_area', idArea).maybeSingle();
        locationName = data?['nama_area'] ?? locationName;
        locationLevel = 'area';
      } else if (idSubunit != null) {
        final data = await Supabase.instance.client.from('subunit').select('nama_subunit').eq('id_subunit', idSubunit).maybeSingle();
        locationName = data?['nama_subunit'] ?? locationName;
        locationLevel = 'subunit';
      } else if (idUnit != null) {
        final data = await Supabase.instance.client.from('unit').select('nama_unit').eq('id_unit', idUnit).maybeSingle();
        locationName = data?['nama_unit'] ?? locationName;
        locationLevel = 'unit';
      } else if (idLokasi != null) {
        final data = await Supabase.instance.client.from('lokasi').select('nama_lokasi').eq('id_lokasi', idLokasi).maybeSingle();
        locationName = data?['nama_lokasi'] ?? locationName;
        locationLevel = 'lokasi';
      }

      // ── Prioritas is_verificator SELALU menang ──
      String jabatanName;
      if (isVisitor) {
        jabatanName = getTxt('visitor');
      } else if (isVerificator) {
        // is_verificator TRUE → paksa "Verificator", abaikan id_jabatan
        jabatanName = getTxt('verifier_role');
      } else {
        jabatanName = userRow['jabatan']?['nama_jabatan'] ?? 'Staff';
      }

      String? dbImage = userRow['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      if (mounted) {
        setState(() {
          _userName            = userRow['nama'] ?? 'User';
          _userImage           = dbImage ?? metaImage;
          _userJabatan         = jabatanName;          // ← sudah benar: Verificator
          _userLokasiSpesifik  = locationName;
          _userLokasiLevel     = locationLevel;
          _isVisitor           = isVisitor;
          _userJabatanId       = idJabatan;
          _isVerificatorUser   = isVerificator;        // ← set di sini, TIDAK early return
          _isLoading           = false;                // ← hilangkan loading
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data for account: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _prefetchAppInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('app_info')
          .select()
          .single();
      if (mounted) {
        setState(() {
          _cachedAppName    = response['app_name'] ?? 'Inspecta';
          _cachedAppVersion = response['version']  ?? '-';
          _cachedAppWebsite = response['website']  ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error prefetching app info: $e');
    }
  }

  Future<void> _showLanguagePicker() async {
    final languages = {
      'ID': {'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
      'EN': {'name': 'English', 'flag': '🇺🇸'},
      'ZH': {'name': '中文', 'flag': '🇨🇳'},
    };

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D72F3).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        getTxt('select_lang'),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: const Color(0xFF1D72F3),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF1D72F3)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  children: languages.entries.map((entry) {
                    final isSelected = _currentLang == entry.key;
                    return GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('lang', entry.key);
                        if (mounted) setState(() => _currentLang = entry.key);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1D72F3).withValues(alpha: 0.08)
                              : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1D72F3)
                                : const Color(0xFFE0E7FF),
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE0E7FF)),
                              ),
                              child: Text(entry.value['flag']!, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.value['name']!,
                                style: GoogleFonts.poppins(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 15,
                                  color: isSelected
                                      ? const Color(0xFF1D72F3)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF1D72F3), size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(getTxt('title'), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Color(0xFF1D72F3))),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha:0.08),
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Warm-up bendera emoji lokal, agar selalu instan muncul di layar ini
          const Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.02,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: OverflowBox(
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: 500,
                    maxHeight: 500,
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      children: [
                        Text('🇺🇸🇮🇩🇨🇳', style: TextStyle(fontSize: 22)),
                        Text('🇺🇸🇮🇩🇨🇳', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // --- KARTU PROFIL UTAMA ---
                  _isLoading ? _buildSkeletonProfileCard() : _buildProfileCard(),
                  const SizedBox(height: 30),

                  // --- MENU PENGATURAN ---
                  _buildMenuTile(
                    Icons.translate,
                    getTxt('change_lang'),
                    onTap: _showLanguagePicker,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _flagMap[_currentLang] ?? '🇺🇸',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          getTxt('current_lang'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D72F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildMenuTile(
                    Icons.info_outline,
                    getTxt('about'),
                    onTap: () {
                      Navigator.push(
                        context,
                        _slideRoute(AboutInspectaScreen(
                          lang: _currentLang,
                          initialAppName:    _cachedAppName,
                          initialAppVersion: _cachedAppVersion,
                          initialAppWebsite: _cachedAppWebsite,
                        )),
                      );
                    },
                  ),
                  _buildMenuTile(
                    Icons.help_outline,
                    getTxt('help'),
                    onTap: () {
                      Navigator.push(
                        context,
                        _slideRoute(HelpCenterScreen(lang: _currentLang)),
                      );
                    },
                  ),
                  _buildMenuTile(
                    Icons.shield_outlined,
                    getTxt('privacy'),
                    onTap: () {
                      Navigator.push(
                        context,
                        _slideRoute(PrivacySecurityScreen(lang: _currentLang)),
                      );
                    },
                  ),
                  _buildMenuTile(
                    Icons.campaign_outlined,
                    getTxt('news'),
                    onTap: () {
                      Navigator.push(
                        context,
                        _slideRoute(NewsScreen(
                          lang: _currentLang,
                          translations: _txt,
                        )),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // --- TOMBOL LOGOUT ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: Text(
                      getTxt('logout'),
                      style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha:0.1),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFEBEB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  getTxt('logout'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  getTxt('logout_desc'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.pop(context, true),
                                    icon: const Icon(Icons.logout_rounded,
                                        color: Colors.white, size: 18),
                                    label: Text(
                                      getTxt('logout'),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      elevation: 0,
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xFFE2E8F0), width: 1.5),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Text(
                                      getTxt('cancel'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (confirmed == true) {
                        await Supabase.instance.client.auth.signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper untuk membuat tile menu yang konsisten
  Widget _buildMenuTile(IconData icon, String title,
    {VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1D72F3)),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            if (trailing != null) trailing,
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Helper navigasi dengan CurvedAnimation EaseOut
  PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  Widget _buildProfileCard() {
    if (_isVisitor) {
      return _buildVisitorCard();
    }

    final Color roleColor = JabatanHelper.getPrimaryColor(
      isVerificatorFlag: _isVerificatorUser,
      idJabatan: _userJabatanId,
    );
    final IconData roleIcon = JabatanHelper.getRoleIcon(
      isVerificatorFlag: _isVerificatorUser,
      idJabatan: _userJabatanId,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => ProfileScreen(
              lang: _currentLang,
              initialUserName: _userName,
              initialUserImage: _userImage,
              initialUserRole: _userJabatan,
              initialUserLocation: _userLokasiSpesifik,
              isVerificator: _isVerificatorUser,
              userJabatanId: _userJabatanId,
            ),
            transitionsBuilder: (_, animation, __, child) {
              final slide = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
              return SlideTransition(position: slide, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => _fetchUserDataSilent());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: JabatanHelper.getCardGradient(
              isVerificatorFlag: _isVerificatorUser,
              idJabatan: _userJabatanId,
            ),
            stops: const [0.0, 0.35, 0.65, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // AVATAR — ukuran dikembalikan seperti semula (radius 35)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF1D72F3),
                backgroundImage:
                    _userImage != null ? NetworkImage(_userImage!) : null,
                child: _userImage == null
                    ? const Icon(Icons.person, color: Colors.white, size: 35)
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // NAMA + BADGE JABATAN + BADGE LOKASI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BARIS 1: NAMA — auto mengecil, selalu 1 baris penuh
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _userName,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // BARIS 2: BADGE JABATAN — warna identik dengan user_info_card.dart
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [roleColor, _darken(roleColor)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75), width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: roleColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, size: 11.5, color: Colors.white),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _userJabatan,
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // BARIS 3: BADGE LOKASI SPESIFIK — disamakan dengan user_info_card.dart
                  Container(
                    constraints: const BoxConstraints(maxWidth: 165),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_locationColor, _darken(_locationColor)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: _locationColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.map, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _userLokasiSpesifik,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.clip,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF0F172A), size: 18),
          ],
        ),
      ),
    );
  }

  // --- HELPER UNTUK KARTU VISITOR ---
  Widget _buildVisitorCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => ProfileScreen(
              lang: _currentLang,
              isVerificator: _isVerificatorUser,
              userJabatanId: _userJabatanId,
            ),
            transitionsBuilder: (_, animation, __, child) {
              final slide = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
              return SlideTransition(position: slide, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ).then((_) => _fetchUserDataSilent());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(   // ← HAPUS color: Colors.white, pindah ke dalam decoration
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _userImage != null ? NetworkImage(_userImage!) : null,
              child: _userImage == null
                  ? const Icon(Icons.person_outline, color: Color(0xFF1D72F3), size: 35)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D72F3),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _userJabatan,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}