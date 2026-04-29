import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/jabatan_helper.dart';
import '../../auth/login_screen.dart';
import 'profile_screen.dart';
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
  bool _isVisitor = false;
  int? _userJabatanId;
  bool _isVerificatorUser = false;

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
    },
  };

  String getTxt(String key) => _txt[_currentLang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;

    if (widget.initialUserName != null && widget.initialUserName != '...') {
      _userName = widget.initialUserName!;
      _userImage = widget.initialUserImage;
      _userJabatan = widget.initialUserRole ?? '...';
      _userLokasiSpesifik = widget.initialUserLocation ?? '...';
      _isVisitor = widget.initialIsVisitor ?? false;
      _userJabatanId = widget.initialUserJabatanId;
      _isVerificatorUser  = widget.initialIsVerificator ?? false;

      if (_isVerificatorUser) {
        _userJabatan = getTxt('verifier_role'); 
      } else {
        _userJabatan = widget.initialUserRole ?? '...';
      }

      _isLoading = false;
    }
    _fetchUserDataSilent();
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

  Future<void> _showLanguagePicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final languages = {
          'ID': {'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
          'EN': {'name': 'English', 'flag': '🇺🇸'},
          'ZH': {'name': '中文', 'flag': '🇨🇳'},
        };
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getTxt('select_lang'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 20),
              ...languages.entries.map((entry) {
                bool isSelected = _currentLang == entry.key;
                return GestureDetector(
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString('lang', entry.key);
                    setState(() => _currentLang = entry.key);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1D72F3).withOpacity(0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected ? Border.all(color: const Color(0xFF1D72F3), width: 2) : null,
                    ),
                    child: Row(
                      children: [
                        Text(entry.value['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 15),
                        Expanded(child: Text(entry.value['name']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16))),
                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00C9E4)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
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
        title: Text(getTxt('title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D72F3))),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // --- KARTU PROFIL UTAMA ---
                  _isLoading ? _buildSkeletonProfileCard() : _buildProfileCard(),
                  const SizedBox(height: 30),

                  // --- MENU PENGATURAN ---
                  _buildMenuTile(Icons.translate, getTxt('change_lang'), onTap: _showLanguagePicker, trailing: Text(getTxt('current_lang'), style: const TextStyle(color: Colors.grey))),
                  _buildMenuTile(
                    Icons.info_outline, 
                    getTxt('about'), 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutInspectaScreen(lang: _currentLang),
                        ),
                      );
                    }
                  ),
                  _buildMenuTile(
                    Icons.help_outline, 
                    getTxt('help'), 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HelpCenterScreen(lang: _currentLang),
                        ),
                      );
                    }
                  ),
                  _buildMenuTile(
                    Icons.shield_outlined, 
                    getTxt('privacy'), 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PrivacySecurityScreen(lang: _currentLang)),
                      );
                    },
                  ),
                  _buildMenuTile(Icons.campaign_outlined, getTxt('news'), onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsScreen(
                          lang: _currentLang, 
                          translations: _txt,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 40),

                  // --- TOMBOL LOGOUT ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: Text(
                      getTxt('logout'),
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // Helper untuk membuat tile menu yang konsisten
  Widget _buildMenuTile(IconData icon, String title, {VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1D72F3)),
            const SizedBox(width: 15),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            if (trailing != null) trailing,
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_isVisitor) {
      return _buildVisitorCard();
    }

    final List<Color> gradientColors = JabatanHelper.getGradientColors(
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
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned(
                right: -50, top: -40,
                child: CircleAvatar(radius: 90, backgroundColor: Colors.white.withOpacity(0.06)),
              ),
              Positioned(
                right: 20, bottom: -70,
                child: CircleAvatar(radius: 70, backgroundColor: Colors.white.withOpacity(0.04)),
              ),
              Positioned(
                left: -30, bottom: -20,
                child: CircleAvatar(radius: 50, backgroundColor: Colors.black.withOpacity(0.05)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.8),
                      backgroundImage: _userImage != null ? NetworkImage(_userImage!) : null,
                      child: _userImage == null ? const Icon(Icons.person, color: Color(0xFF1D72F3), size: 35) : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _userJabatan,
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 16),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _userLokasiSpesifik,
                                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ],
          ),
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
            pageBuilder: (_, animation, __) => ProfileScreen(lang: _currentLang, isVerificator: _isVerificatorUser, userJabatanId: _userJabatanId,),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _userImage != null ? NetworkImage(_userImage!) : null,
              child: _userImage == null ? const Icon(Icons.person_outline, color: Color(0xFF1D72F3), size: 35) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D72F3))),
                  const SizedBox(height: 5),
                  Text(_userJabatan, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
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