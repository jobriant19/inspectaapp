import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String lang;
  const ProfileScreen({super.key, required this.lang});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedJabatan;
  String? _imageUrl; // Menyimpan URL gambar dari database
  File? _imageFile; // Menyimpan gambar yang baru dipilih dari galeri
  bool _isLoading = false;

  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'Profile',
      'name': 'Name',
      'email': 'Email Address',
      'phone': 'Phone',
      'role': 'Job Title',
      'save': 'Save Changes',
      'logout': 'Logout',
      'success': 'Profile Updated',
      'change_photo': 'Change Photo',
      'remove_photo': 'Remove Photo',
    },
    'ID': {
      'title': 'Profil',
      'name': 'Nama',
      'email': 'Alamat Email',
      'phone': 'Telepon',
      'role': 'Jabatan',
      'save': 'Simpan Perubahan',
      'logout': 'Keluar',
      'success': 'Profil Diperbarui',
      'change_photo': 'Ubah Foto',
      'remove_photo': 'Hapus Foto',
    },
    'ZH': {
      'title': '个人资料',
      'name': '姓名',
      'email': '电子邮件地址',
      'phone': '电话',
      'role': '职位',
      'save': '保存更改',
      'logout': '登出',
      'success': '个人资料已更新',
      'change_photo': '更改照片',
      'remove_photo': '删除照片',
    },
  };

  String getTxt(String key) => _txt[widget.lang]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userAuth = Supabase.instance.client.auth.currentUser;
    if (userAuth == null) return;

    try {
      // 1) Ambil user tanpa join
      final userRow = await Supabase.instance.client
          .from('User')
          .select('nama, email, phone, gambar_user, id_jabatan')
          .eq('id_user', userAuth.id)
          .maybeSingle();

      if (userRow == null) {
        if (!mounted) return;
        setState(() {
          _nameController.text = userAuth.userMetadata?['full_name'] ?? '';
          _emailController.text = userAuth.email ?? '';
          _phoneController.text = '';
          _imageUrl = userAuth.userMetadata?['avatar_url'];
          _selectedJabatan = 'Staff';
        });
        return;
      }

      // 2) Ambil nama jabatan dari tabel jabatan
      String roleName = 'Staff';
      final int? idJabatan = userRow['id_jabatan'];

      if (idJabatan != null) {
        final jabatanRow = await Supabase.instance.client
            .from('jabatan') // PENTING: gunakan nama tabel asli
            .select('nama_jabatan')
            .eq('id_jabatan', idJabatan)
            .maybeSingle();

        roleName = jabatanRow?['nama_jabatan'] ?? 'Staff';
      }

      if (!mounted) return;
      setState(() {
        _nameController.text =
            userRow['nama'] ?? userAuth.userMetadata?['full_name'] ?? '';
        _emailController.text = userRow['email'] ?? userAuth.email ?? '';
        _phoneController.text = userRow['phone'] ?? '';
        _imageUrl =
            userRow['gambar_user'] ?? userAuth.userMetadata?['avatar_url'];
        _selectedJabatan = roleName;
      });
    } catch (e) {
      debugPrint("Error load profile: $e");
    }
  }

  // Fungsi Pilih Gambar dari Galeri
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // Fungsi Hapus Gambar
  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageUrl = null;
    });
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final userAuth = Supabase.instance.client.auth.currentUser;
      int idJabatan = 4;
      if (_selectedJabatan == 'Eksekutif') idJabatan = 1;
      if (_selectedJabatan == 'Manager') idJabatan = 2;
      if (_selectedJabatan == 'Kasie') idJabatan = 3;

      String? finalImageUrl = _imageUrl;

      // Jika user memilih foto baru, upload ke Storage Supabase
      if (_imageFile != null) {
        final fileExt = _imageFile!.path.split('.').last;
        final fileName =
            '${userAuth!.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await Supabase.instance.client.storage
            .from('avatars')
            .upload(fileName, _imageFile!);
        finalImageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(fileName);
      }

      // Update Database
      await Supabase.instance.client
          .from('User')
          .update({
            'nama': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'id_jabatan': idJabatan,
            'gambar_user': finalImageUrl,
          })
          .eq('id_user', userAuth!.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTxt('success')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Agar background menyatu dengan AppBar
      appBar: AppBar(
        title: Text(
          getTxt('title'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // Background gradient yang estetik agar efek Glassmorphism terlihat menonjol
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFF5F7FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // GLASSMORPHISM CARD
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // BAGIAN FOTO PROFIL
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundColor: const Color(
                                  0xFF00C9E4,
                                ).withOpacity(0.2),
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!) as ImageProvider
                                    : (_imageUrl != null
                                          ? NetworkImage(_imageUrl!)
                                          : null),
                                child: (_imageFile == null && _imageUrl == null)
                                    ? const Icon(
                                        Icons.person,
                                        size: 55,
                                        color: Color(0xFF00C9E4),
                                      )
                                    : null,
                              ),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00C9E4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_imageFile != null || _imageUrl != null)
                            TextButton(
                              onPressed: _removeImage,
                              child: Text(
                                getTxt('remove_photo'),
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 25),

                          // FORM INPUT (Dengan gaya minimalis)
                          _buildTextField(
                            _nameController,
                            getTxt('name'),
                            Icons.person_outline,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            _emailController,
                            getTxt('email'),
                            Icons.email_outlined,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            _phoneController,
                            getTxt('phone'),
                            Icons.phone_outlined,
                          ),
                          const SizedBox(height: 15),

                          // DROPDOWN JABATAN
                          DropdownButtonFormField<String>(
                            value: _selectedJabatan,
                            decoration: InputDecoration(
                              labelText: getTxt('role'),
                              prefixIcon: const Icon(
                                Icons.work_outline,
                                color: Colors.black54,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: ['Eksekutif', 'Manager', 'Kasie', 'Staff']
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedJabatan = val),
                          ),
                          const SizedBox(height: 35),

                          // TOMBOL SIMPAN
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9E4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                shadowColor: const Color(
                                  0xFF00C9E4,
                                ).withOpacity(0.5),
                              ),
                              onPressed: _isLoading ? null : _updateProfile,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      getTxt('save'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // TOMBOL LOGOUT
                TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: Text(
                    getTxt('logout'),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted)
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk TextField yang seragam dan estetik
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
