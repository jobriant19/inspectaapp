import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatefulWidget {
  final String lang;
  final String? initialUserName;
  final String? initialUserImage;
  final String? initialUserRole;
  final String? initialUserLocation;

  const ProfileScreen({
    super.key, 
    required this.lang,
    this.initialUserName,
    this.initialUserImage,
    this.initialUserRole,
    this.initialUserLocation,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _email = '', _jabatan = '', _lokasi = '';
  String? _initialName, _imageUrl;
  XFile? _imageFile; // Variabel ini kunci untuk preview gambar baru
  bool _isSaving = false;
  bool _isScreenLoading = true;
  bool _isEditMode = false;
  bool _hasChanges = false;

  final Map<String, Map<String, String>> _txt = {
    'EN': { 'profile_title': 'My Profile', 'edit_title': 'Edit Profile', 'name': 'Name', 'email': 'Email Address', 'role': 'Job Title', 'location': 'Location', 'save': 'Save Changes', 'success': 'Profile Updated', 'edit': 'Edit', 'verifier': 'Verifier', 'error_update': 'Failed to update profile. Please try again.' },
    'ID': { 'profile_title': 'Profil Saya', 'edit_title': 'Ubah Profil', 'name': 'Nama', 'email': 'Alamat Email', 'role': 'Jabatan', 'location': 'Lokasi', 'save': 'Simpan Perubahan', 'success': 'Profil Diperbarui', 'edit': 'Ubah', 'verifier': 'Verifier', 'error_update': 'Gagal memperbarui profil. Silakan coba lagi.' },
    'ZH': { 'profile_title': '我的资料', 'edit_title': '编辑资料', 'name': '姓名', 'email': '电子邮件', 'role': '职位', 'location': '地点', 'save': '保存更改', 'success': '资料已更新', 'edit': '编辑', 'verifier': '验证者', 'error_update': '无法更新资料，请重试.' },
  };
  String getTxt(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameController.addListener(() {
      if (_isEditMode) {
        setState(() => _hasChanges = _nameController.text != _initialName || _imageFile != null);
      }
    });
  }

  Future<void> _loadProfile() async {
    if (widget.initialUserName != null && widget.initialUserName != "Loading...") {
      setState(() {
        _nameController.text = widget.initialUserName!;
        _initialName = widget.initialUserName!;
        _imageUrl = widget.initialUserImage;
        _jabatan = widget.initialUserRole!;
        _lokasi = widget.initialUserLocation!;
        _email = Supabase.instance.client.auth.currentUser?.email ?? '';
        _isScreenLoading = false;
      });
      return;
    }

    setState(() => _isScreenLoading = true);
    final user = Supabase.instance.client.auth.currentUser!;
    try {
      final row = await Supabase.instance.client
          .from('User')
          .select('nama, email, gambar_user, id_jabatan, is_verificator, id_lokasi, id_unit, id_subunit, id_area')
          .eq('id_user', user.id)
          .maybeSingle();

      if (row == null || !mounted) return;

      String jabatan;
      final isVerificator = row['is_verificator'] ?? false;
      if (isVerificator) {
        jabatan = getTxt('verifier');
      } else if (row['id_jabatan'] != null) {
        final j = await Supabase.instance.client.from('jabatan').select('nama_jabatan').eq('id_jabatan', row['id_jabatan']).maybeSingle();
        jabatan = j?['nama_jabatan'] ?? 'Staff';
      } else {
        jabatan = 'Staff';
      }
      
      String lokasi = "N/A";
      if (row['id_area'] != null) {
        lokasi = (await Supabase.instance.client.from('area').select('nama_area').eq('id_area', row['id_area']).maybeSingle())?['nama_area'] ?? lokasi;
      } else if (row['id_subunit'] != null) {
        lokasi = (await Supabase.instance.client.from('subunit').select('nama_subunit').eq('id_subunit', row['id_subunit']).maybeSingle())?['nama_subunit'] ?? lokasi;
      } else if (row['id_unit'] != null) {
        lokasi = (await Supabase.instance.client.from('unit').select('nama_unit').eq('id_unit', row['id_unit']).maybeSingle())?['nama_unit'] ?? lokasi;
      } else if (row['id_lokasi'] != null) {
        lokasi = (await Supabase.instance.client.from('lokasi').select('nama_lokasi').eq('id_lokasi', row['id_lokasi']).maybeSingle())?['nama_lokasi'] ?? lokasi;
      }
      
      final String? metaImage = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
      String? dbImage = row['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      if(mounted) {
        setState(() {
          _initialName = row['nama'];
          _nameController.text = row['nama'] ?? '';
          _email = row['email'] ?? '';
          _jabatan = jabatan;
          _lokasi = lokasi;
          _imageUrl = dbImage ?? metaImage;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if(mounted) setState(() => _isScreenLoading = false);
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditMode) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked != null) {
      setState(() {
        _imageFile = picked;
        _hasChanges = true;
      });
    }
  }

  // --- BAGIAN UTAMA PERBAIKAN: METHOD UNTUK MENYIMPAN PROFIL ---
  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);

    final user = Supabase.instance.client.auth.currentUser!;
    String? finalImageUrl = _imageUrl;

    try {
      // Upload gambar baru jika ada
      if (_imageFile != null) {
        final ext = _imageFile!.path.split('.').last.toLowerCase();
        final fileName =
            '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
        final filePath = 'avatars/$fileName';
        final bytes = await _imageFile!.readAsBytes();

        await Supabase.instance.client.storage
            .from('temuan_images')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(
                contentType: 'image/$ext',
                upsert: true,
              ),
            );

        finalImageUrl = Supabase.instance.client.storage
            .from('temuan_images')
            .getPublicUrl(filePath);
      }

      // Update tabel User
      await Supabase.instance.client
          .from('User')
          .update({
            'nama': _nameController.text.trim(),
            if (finalImageUrl != null) 'gambar_user': finalImageUrl,
          })
          .eq('id_user', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTxt('success')),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _initialName = _nameController.text.trim();
          _imageUrl = finalImageUrl;
          _imageFile = null;
          _isEditMode = false;
          _hasChanges = false;
        });
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${getTxt('error_update')}\nDetail: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
              setState(() {
                _isEditMode = false;
                _nameController.text = _initialName ?? '';
                _imageFile = null;
                _hasChanges = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(getTxt(_isEditMode ? 'edit_title' : 'profile_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        actions: [
          if (!_isEditMode && !_isScreenLoading)
            TextButton.icon(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF1E3A8A), size: 20),
              label: Text(getTxt('edit'), style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
              onPressed: () => setState(() => _isEditMode = true),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
        ],
      ),
      body: _isScreenLoading
          ? _buildSkeletonBody()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: _imageFile != null ? _imageFile!.readAsBytes() : null,
                          builder: (context, snapshot) {
                            ImageProvider? imageProvider;

                            if (_imageFile != null && snapshot.hasData) {
                              // Preview gambar baru dari file lokal
                              imageProvider = MemoryImage(snapshot.data!);
                            } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
                              // Gambar dari server
                              imageProvider = NetworkImage(_imageUrl!);
                            }

                            return CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? const Icon(Icons.person, size: 60,
                                      color: Color(0xFF00C9E4))
                                  : null,
                            );
                          },
                        ),
                        if (_isEditMode)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C9E4),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildField(_nameController, getTxt('name'), Icons.person_outline, enabled: _isEditMode),
                  _buildInfoField(_email, getTxt('email'), Icons.email_outlined),
                  _buildInfoField(_jabatan, getTxt('role'), Icons.work_outline),
                  _buildInfoField(_lokasi, getTxt('location'), Icons.location_on_outlined),
                  const SizedBox(height: 30),
                  if (_isEditMode)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9E4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        onPressed: _hasChanges && !_isSaving ? _updateProfile : null,
                        child: _isSaving
                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                            : Text(getTxt('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSkeletonBody() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const CircleAvatar(radius: 60, backgroundColor: Colors.white),
            const SizedBox(height: 30),
            _buildSkeletonField(),
            _buildSkeletonField(),
            _buildSkeletonField(),
            _buildSkeletonField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 60,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon, {bool enabled = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [if (enabled) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: c,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildInfoField(String value, String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}