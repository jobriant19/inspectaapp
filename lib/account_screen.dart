import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class AccountScreen extends StatefulWidget {
  final String lang;
  const AccountScreen({super.key, required this.lang});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late String _currentLang;
  bool _isLoading = false;

  // Data User
  String _userName = "Loading...";
  String? _userImage;
  String _userJabatan = "Loading...";
  String _userLokasiSpesifik = "Tidak terdefinisi";
  bool _isVisitor = false;
  int? _userJabatanId;

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
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userAuth = Supabase.instance.client.auth.currentUser;
    if (userAuth == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final String? metaImage = userAuth.userMetadata?['avatar_url'] ?? userAuth.userMetadata?['picture'];
      final userRow = await Supabase.instance.client
          .from('User')
          .select('nama, gambar_user, id_jabatan, is_visitor, is_verificator, id_lokasi, id_unit, id_subunit, id_area')
          .eq('id_user', userAuth.id)
          .maybeSingle();

      if (userRow == null || !mounted) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final isVisitor = userRow['is_visitor'] ?? false;
      final isVerificator = userRow['is_verificator'] ?? false;
      final idJabatan = userRow['id_jabatan'];
      final idLokasi = userRow['id_lokasi'];
      final idUnit = userRow['id_unit'];
      final idSubunit = userRow['id_subunit'];
      final idArea = userRow['id_area'];

      // --- OPTIMISASI: Siapkan semua query yang mungkin diperlukan ---
      List<Future<PostgrestResponse>> futures = [];

      // Query 0: Jabatan (hanya jika bukan visitor dan punya id_jabatan)
      if (!isVisitor && !isVerificator && idJabatan != null) {
        futures.add(
          Supabase.instance.client
              .from('jabatan')
              .select('nama_jabatan')
              .eq('id_jabatan', idJabatan)
              .maybeSingle()
              .then((value) => PostgrestResponse(data: value, count: 0)), // Bungkus untuk tipe data
        );
      } else {
        futures.add(Future.value(PostgrestResponse(data: null, count: 0))); // Future kosong
      }

      // Query 1: Lokasi spesifik (pilih satu query berdasarkan prioritas)
      if (idArea != null) {
        futures.add(Supabase.instance.client.from('area').select('nama_area').eq('id_area', idArea).maybeSingle().then((value) => PostgrestResponse(data: value, count: 0)));
      } else if (idSubunit != null) {
        futures.add(Supabase.instance.client.from('subunit').select('nama_subunit').eq('id_subunit', idSubunit).maybeSingle().then((value) => PostgrestResponse(data: value, count: 0)));
      } else if (idUnit != null) {
        futures.add(Supabase.instance.client.from('unit').select('nama_unit').eq('id_unit', idUnit).maybeSingle().then((value) => PostgrestResponse(data: value, count: 0)));
      } else if (idLokasi != null) {
        futures.add(Supabase.instance.client.from('lokasi').select('nama_lokasi').eq('id_lokasi', idLokasi).maybeSingle().then((value) => PostgrestResponse(data: value, count: 0)));
      } else {
        futures.add(Future.value(PostgrestResponse(data: null, count: 0))); // Future kosong
      }

      final results = await Future.wait(futures);

      String jabatanName;
      if(isVerificator) {
        jabatanName = getTxt('verifier_role');
      } else if (isVisitor) {
        jabatanName = getTxt('visitor');
      } else {
        final jabatanRow = results[0].data;
        jabatanName = jabatanRow?['nama_jabatan'] ?? 'Staff';
      }

      String lokasiSpesifik = "Tidak Terdefinisi";
      final lokasiRow = results[1].data;
      if (lokasiRow != null) {
        // Ambil nilai dari map, tidak peduli apa key-nya
        lokasiSpesifik = lokasiRow.values.first ?? "Tidak Terdefinisi";
      }

      String? dbImage = userRow['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      if (mounted) {
        setState(() {
          _userName = userRow['nama'] ?? 'User';
          _userImage = dbImage ?? metaImage;
          _userJabatan = jabatanName;
          _userLokasiSpesifik = lokasiSpesifik;
          _isVisitor = isVisitor;
          _userJabatanId = idJabatan;
        });
      }


    } catch (e) {
      debugPrint("Error fetching user data for account: $e");
    } finally {
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
                      color: isSelected ? const Color(0xFF00C9E4).withOpacity(0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected ? Border.all(color: const Color(0xFF00C9E4), width: 2) : null,
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
        title: Text(getTxt('title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // --- KARTU PROFIL UTAMA ---
                  _buildProfileCard(),
                  const SizedBox(height: 30),

                  // --- MENU PENGATURAN ---
                  _buildMenuTile(Icons.translate, getTxt('change_lang'), onTap: _showLanguagePicker, trailing: Text(getTxt('current_lang'), style: const TextStyle(color: Colors.grey))),
                  _buildMenuTile(Icons.info_outline, getTxt('about'), onTap: () {}),
                  _buildMenuTile(Icons.help_outline, getTxt('help'), onTap: () {}),
                  _buildMenuTile(Icons.shield_outlined, getTxt('privacy'), onTap: () {}),
                  _buildMenuTile(Icons.campaign_outlined, getTxt('news'), onTap: () {}),

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
            Icon(icon, color: const Color(0xFF1E3A8A)),
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
  // 1. JIKA USER ADALAH VISITOR
  if (_isVisitor) {
    return _buildVisitorCard(); // Kita pisahkan ke helper di bawah agar rapi
  }

  // 2. JIKA USER ADALAH KARYAWAN (Eksekutif, Manajer, Kassie, Staff)
  List<Color> gradientColors;

  switch (_userJabatanId) {
    case 1: // Eksekutif (Pink Mewah ke Merah Tua)
      gradientColors = [const Color(0xFFFA527B), const Color(0xFF6A041D)];
      break;
    case 2: // Manajer
      gradientColors = [const Color(0xFF00C9E4), const Color(0xFF1E3A8A)];
      break;
    case 3: // Kassie (Hijau Eksklusif)
      gradientColors = [const Color(0xFF26D0CE), const Color(0xFF1A2980)];
      break;
    default: // Staff (Ungu Elegan)
      gradientColors = [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)];
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(lang: _currentLang)))
          .then((_) => _fetchUserData());
    },
    child: Container(
      height: 140, // Tinggi konsisten
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
            // --- CORAK DESAIN ABSTRAK 1 (Top Right) ---
            Positioned(
              right: -50,
              top: -40,
              child: CircleAvatar(
                radius: 90,
                backgroundColor: Colors.white.withOpacity(0.06),
              ),
            ),
            // --- CORAK DESAIN ABSTRAK 2 (Bottom Right) ---
            Positioned(
              right: 20,
              bottom: -70,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white.withOpacity(0.04),
              ),
            ),
            // --- CORAK DESAIN ABSTRAK 3 (Left Edge) ---
            Positioned(
              left: -30,
              bottom: -20,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.black.withOpacity(0.05),
              ),
            ),
            
            // --- KONTEN UTAMA KARTU ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    backgroundImage: _userImage != null ? NetworkImage(_userImage!) : null,
                    child: _userImage == null ? const Icon(Icons.person, color: Color(0xFF1E3A8A), size: 35) : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                        const SizedBox(height: 8),

                        // --- BADGE UNTUK JABATAN ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _userJabatan,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // ----------------------------

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
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(lang: _currentLang)))
          .then((_) => _fetchUserData());
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
            child: _userImage == null ? const Icon(Icons.person_outline, color: Color(0xFF1E3A8A), size: 35) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
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