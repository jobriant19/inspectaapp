import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String lang;
  const ProfileScreen({super.key, required this.lang});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _email = '', _jabatan = '', _lokasi = '';
  String? _initialName, _imageUrl;
  File? _imageFile;
  bool _isLoading = false, _isEditMode = false, _hasChanges = false;

  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'profile_title': 'My Profile',
      'edit_title': 'Edit Profile',
      'name': 'Name',
      'email': 'Email Address',
      'role': 'Job Title',
      'location': 'Location',
      'save': 'Save Changes',
      'success': 'Profile Updated',
      'edit': 'Edit',
      'verifier': 'Verifier',
    },
    'ID': {
      'profile_title': 'Profil Saya',
      'edit_title': 'Ubah Profil',
      'name': 'Nama',
      'email': 'Alamat Email',
      'role': 'Jabatan',
      'location': 'Lokasi',
      'save': 'Simpan Perubahan',
      'success': 'Profil Diperbarui',
      'edit': 'Ubah',
      'verifier': 'Verifier',
    },
    'ZH': {
      'profile_title': '我的资料',
      'edit_title': '编辑资料',
      'name': '姓名',
      'email': '电子邮件',
      'role': '职位',
      'location': '地点',
      'save': '保存更改',
      'success': '资料已更新',
      'edit': '编辑',
      'verifier': '验证者',
    },
  };
  String getTxt(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameController.addListener(() {
      if (_isEditMode)
        setState(
          () => _hasChanges =
              _nameController.text != _initialName || _imageFile != null,
        );
    });
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final row = await Supabase.instance.client
        .from('User')
        .select(
          'nama, email, gambar_user, id_jabatan, is_verificator, id_lokasi, id_unit, id_subunit, id_area',
        )
        .eq('id_user', user.id)
        .maybeSingle();
    if (row == null) return;

    String jabatan;
    final isVerificator = row['is_verificator'] ?? false;

    if (isVerificator) {
      jabatan = getTxt('verifier');
    } else if (row['id_jabatan'] != null) {
      final j = await Supabase.instance.client
          .from('jabatan')
          .select('nama_jabatan')
          .eq('id_jabatan', row['id_jabatan'])
          .maybeSingle();
      jabatan = j?['nama_jabatan'] ?? 'Staff';
    } else {
      jabatan = 'Staff';
    }
    
    String lokasi = "N/A";
    if (row['id_area'] != null) {
      lokasi =
          (await Supabase.instance.client
              .from('area')
              .select('nama_area')
              .eq('id_area', row['id_area'])
              .maybeSingle())?['nama_area'] ??
          lokasi;
    } else if (row['id_subunit'] != null) {
      lokasi =
          (await Supabase.instance.client
              .from('subunit')
              .select('nama_subunit')
              .eq('id_subunit', row['id_subunit'])
              .maybeSingle())?['nama_subunit'] ??
          lokasi;
    } else if (row['id_unit'] != null) {
      lokasi =
          (await Supabase.instance.client
              .from('unit')
              .select('nama_unit')
              .eq('id_unit', row['id_unit'])
              .maybeSingle())?['nama_unit'] ??
          lokasi;
    } else if (row['id_lokasi'] != null) {
      lokasi =
          (await Supabase.instance.client
              .from('lokasi')
              .select('nama_lokasi')
              .eq('id_lokasi', row['id_lokasi'])
              .maybeSingle())?['nama_lokasi'] ??
          lokasi;
    }

    setState(() {
      _initialName = row['nama'];
      _nameController.text = row['nama'] ?? '';
      _email = row['email'] ?? '';
      _jabatan = jabatan;
      _lokasi = lokasi;
      _imageUrl = row['gambar_user'];
    });
  }

  Future<void> _pickImage() async {
    if (!_isEditMode) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null)
      setState(() {
        _imageFile = File(file.path);
        _hasChanges = true;
      });
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser!;
    String? finalImageUrl = _imageUrl;
    if (_imageFile != null) {
      final name =
          '${user.id}-${DateTime.now().millisecondsSinceEpoch}.${_imageFile!.path.split('.').last}';
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(name, _imageFile!);
      finalImageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(name);
    }
    await Supabase.instance.client
        .from('User')
        .update({'nama': _nameController.text, 'gambar_user': finalImageUrl})
        .eq('id_user', user.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(getTxt('success')), backgroundColor: Colors.green),
    );
    setState(() {
      _isEditMode = false;
      _hasChanges = false;
      _initialName = _nameController.text;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E3A8A)),
          onPressed: () {
            if (_isEditMode) {
              // Jika sedang dalam mode edit, matikan mode edit
              setState(() => _isEditMode = false);
            } else {
              // Jika tidak, kembali ke halaman sebelumnya (AccountScreen)
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          getTxt(_isEditMode ? 'edit_title' : 'profile_title'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        actions: [
          if (!_isEditMode)
            TextButton.icon(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF1E3A8A), size: 20),
              label: Text(
                getTxt('edit'),
                style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
              ),
              onPressed: () => setState(() => _isEditMode = true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_imageUrl != null ? NetworkImage(_imageUrl!) : null)
                              as ImageProvider?,
                    child: (_imageFile == null && _imageUrl == null)
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFF00C9E4),
                          )
                        : null,
                  ),
                  if (_isEditMode)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C9E4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildField(
              _nameController,
              getTxt('name'),
              Icons.person_outline,
              enabled: _isEditMode,
            ),
            _buildInfoField(_email, getTxt('email'), Icons.email_outlined),
            _buildInfoField(_jabatan, getTxt('role'), Icons.work_outline),
            _buildInfoField(
              _lokasi,
              getTxt('location'),
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 30),
            if (_isEditMode)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9E4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _hasChanges && !_isLoading ? _updateProfile : null,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          getTxt('save'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String label,
    IconData icon, {
    bool enabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: c,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String value, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
