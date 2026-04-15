import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/account/account_screen.dart';
import '../verification/verification_detail_screen.dart';
import '../verification/verification_history_screen.dart';

class VerificatorHomeScreen extends StatefulWidget {
  const VerificatorHomeScreen({super.key});

  @override
  State<VerificatorHomeScreen> createState() => _VerificatorHomeScreenState();
}

class _VerificatorHomeScreenState extends State<VerificatorHomeScreen> {
  int _currentIndex = 0;

  // Data User
  String _userName = "...";
  String _userRole = "...";
  int _userPoin = 0;
  String? _userImage;
  String _userLocationName = "...";
  int? _userJabatanId;
  bool _isVisitor = false;

  int _notificationCount = 0;

  String _lang = 'EN';

  // Kamus Terjemahan untuk Verificator Screen
  final Map<String, Map<String, String>> _text = {
    'EN': {
      'title': 'Verification Center',
      'subtitle': 'Press the button below to start verifying incoming finding reports.',
      'role': 'Verifier',
      'start_verify': 'Start Verification',
    },
    'ID': {
      'title': 'Pusat Verifikasi',
      'subtitle': 'Tekan tombol di bawah untuk mulai memverifikasi laporan temuan yang masuk.',
      'role': 'Verifier',
      'start_verify': 'Mulai Verifikasi',
    },
    'ZH': {
      'title': '验证中心',
      'subtitle': '按下面的按钮开始验证收到的发现报告。',
      'role': '验证者',
      'start_verify': '开始验证',
    },
  };

  String getTxt(String key) => _text[_lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _fetchInitialData();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _lang = prefs.getString('lang') ?? 'EN';
      });
    }
  }

  void _fetchInitialData() {
    _fetchUserData();
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    if (!mounted) return;
    try {
      // Query ini disesuaikan untuk verifikator: menghitung temuan yang menunggu verifikasi
      final count = await Supabase.instance.client
          .from('temuan')
          .count(CountOption.exact)
          .eq('status_temuan', 'Menunggu Verifikasi');

      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    } catch (e) {
      debugPrint("Error fetching verifier notification count: $e");
    }
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    try {
      final userAuth = Supabase.instance.client.auth.currentUser;
      if (userAuth == null) return;
      
      final userRow = await Supabase.instance.client
          .from('User')
          .select('nama, poin, gambar_user, id_jabatan, is_visitor, id_lokasi, id_unit, id_subunit, id_area, jabatan(nama_jabatan)')
          .eq('id_user', userAuth.id)
          .maybeSingle();

      final String? metaImage = userAuth.userMetadata?['avatar_url'] ?? userAuth.userMetadata?['picture'];
      
      if (userRow == null) {
        setState(() {
          _userName = userAuth.userMetadata?['full_name'] ?? 'Verifier';
          _userImage = metaImage;
          _userLocationName = "Tidak Terdefinisi";
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
      
      String roleName = 'Verifier';
      if (userRow['jabatan'] != null && userRow['jabatan']['nama_jabatan'] != null) {
        roleName = userRow['jabatan']['nama_jabatan'];
      }

      setState(() {
        _userName = userRow['nama'] ?? 'Verifier';
        _userPoin = userRow['poin'] ?? 0;
        _userImage = userRow['gambar_user'] ?? metaImage;
        _userRole = roleName;
        _userJabatanId = userRow['id_jabatan'];
        _userLocationName = locationName;
        _isVisitor = userRow['is_visitor'] ?? false;
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // --- BAGIAN 1: HEADER (LOGO, NOTIF, FOTO) ---
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', height: 40),
                  Row(
                    children: [
                      // Tombol Notifikasi
                      GestureDetector(
                        onTap: () {
                          // TODO: Buat halaman notifikasi untuk Verifikator jika perlu
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
                            if (_notificationCount > 0)
                              Positioned(
                                top: -4, right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                  child: Center(
                                    child: Text(
                                      _notificationCount.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Foto Profil
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccountScreen(
                                lang: _lang,
                                initialUserName: _userName,
                                initialUserImage: _userImage,
                                initialUserRole: getTxt('role'),
                                initialUserLocation: _userLocationName,
                                initialIsVisitor: _isVisitor,
                                initialUserJabatanId: _userJabatanId,
                              ),
                            ),
                          ).then((_) {
                            _loadLanguage();
                            _fetchInitialData();
                          });
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF00C9E4),
                          backgroundImage: _userImage != null ? NetworkImage(_userImage!) : null,
                          child: _userImage == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // ==========================================
            // --- BAGIAN 2: INFO CARD PENGGUNA ---
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9E4), Color(0xFF0075FF)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0075FF).withOpacity(0.4),
                      blurRadius: 15, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // MODIFIKASI: Gunakan terjemahan untuk role
                          Text(getTxt('role'),
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // --- BAGIAN 3: KONTEN UTAMA VERIFIKATOR ---
            // ==========================================
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 100, color: Color(0xFF00A0B8)),
                  const SizedBox(height: 20),
                  // MODIFIKASI: Gunakan terjemahan untuk judul
                  Text(getTxt('title'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    // MODIFIKASI: Gunakan terjemahan untuk subjudul
                    child: Text(
                      getTxt('subtitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 80), // Jarak ke bawah untuk nav bar
                ],
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      // ==========================================
      // --- BAGIAN 4: BOTTOM NAVIGATION BAR BARU ---
      // ==========================================
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Kotak Latar Belakang Putih
            Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C9E4).withOpacity(0.15),
                    blurRadius: 20, offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_outlined, Icons.home_rounded, 0),
                  const SizedBox(width: 50), // Ruang untuk tombol tengah
                  _buildNavItem(Icons.person_outline, Icons.person, 1),
                ],
              ),
            ),

            // 2. Tombol "Mulai Verifikasi" di Tengah
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VerificationDetailScreen(lang: _lang)),
                  );
                },
                child: Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9E4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C9E4).withOpacity(0.4),
                        blurRadius: 15, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VerificationHistoryScreen(lang: _lang)),
          ).then((_) {
            _loadLanguage();
            _fetchInitialData();
          });
        } else {
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        height: 65,
        child: Center(
          child: Icon(
            isActive ? filledIcon : outlineIcon,
            size: 28,
            color: isActive ? const Color(0xFF00C9E4) : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}