import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/login_screen.dart';

// ============================================================
// ADMIN PROFILE SCREEN — CRUD nama & gambar_user
// ============================================================
class AdminProfileScreen extends StatefulWidget {
  final String lang;
  final String? initialUserName;
  final String? initialUserImage;

  const AdminProfileScreen({
    super.key,
    required this.lang,
    this.initialUserName,
    this.initialUserImage,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  String _email = '';
  String _jabatan = 'Admin';
  String? _imageUrl;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _imageExt;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _hasChanges = false;
  String? _initialName;

  // Teks UI
  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'My Profile',
      'edit_title': 'Edit Profile',
      'name': 'Name',
      'email': 'Email Address',
      'role': 'Role',
      'save': 'Save Changes',
      'edit': 'Edit',
      'success': 'Profile Updated!',
      'success_body': 'Your profile has been successfully updated.',
      'error_update': 'Update Failed',
      'error_body': 'Failed to update profile. Please try again.',
      'close': 'Close',
      'saving': 'Saving your profile...',
      'uploading': 'Uploading photo...',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
    },
    'ID': {
      'title': 'Profil Saya',
      'edit_title': 'Ubah Profil',
      'name': 'Nama',
      'email': 'Alamat Email',
      'role': 'Peran',
      'save': 'Simpan Perubahan',
      'edit': 'Ubah',
      'success': 'Profil Diperbarui!',
      'success_body': 'Profil Anda berhasil diperbarui.',
      'error_update': 'Gagal Memperbarui',
      'error_body': 'Gagal memperbarui profil. Silakan coba lagi.',
      'close': 'Tutup',
      'saving': 'Menyimpan profil Anda...',
      'uploading': 'Mengunggah foto...',
      'logout': 'Keluar Akun',
      'logout_confirm': 'Apakah Anda yakin ingin keluar?',
      'cancel': 'Batal',
    },
  };

  String getTxt(String key) => _txt[widget.lang]?[key] ?? _txt['EN']![key]!;

  @override
  void initState() {
    super.initState();

    // Set data awal dari parameter — tidak ada skeleton
    if (widget.initialUserName != null) {
      _nameCtrl.text = widget.initialUserName!;
      _initialName = widget.initialUserName;
      _imageUrl = widget.initialUserImage;
      _email = Supabase.instance.client.auth.currentUser?.email ?? '';
      _isLoading = false;
    }

    _nameCtrl.addListener(() {
      if (_isEditMode) {
        setState(() {
          _hasChanges =
              _nameCtrl.text != _initialName || _imageFile != null;
        });
      }
    });

    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final row = await Supabase.instance.client
          .from('User')
          .select('nama, email, gambar_user, id_jabatan, jabatan(nama_jabatan)')
          .eq('id_user', user.id)
          .maybeSingle();

      if (row == null || !mounted) return;

      String? dbImage = row['gambar_user'];
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      final jabatanName =
          row['jabatan']?['nama_jabatan'] ?? 'Admin';

      setState(() {
        _nameCtrl.text = row['nama'] ?? widget.initialUserName ?? '';
        _initialName = row['nama'] ?? widget.initialUserName ?? '';
        _email = row['email'] ?? user.email ?? '';
        _jabatan = jabatanName;
        _imageUrl = dbImage ??
            user.userMetadata?['avatar_url'] ??
            widget.initialUserImage;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching admin profile: $e');
      if (mounted) setState(() => _isLoading = false);
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
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
        _imageExt = ext.isEmpty ? 'jpg' : ext;
        _hasChanges = true;
      });
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6366F1)),
                  backgroundColor: Color(0xFFEDE9FE),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _imageBytes != null
                    ? getTxt('uploading')
                    : getTxt('saving'),
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog({required bool isSuccess, String? errorDetail}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFFDCFCE7)
                      : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: isSuccess
                      ? const Color(0xFF16A34A)
                      : Colors.red.shade400,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                getTxt(isSuccess ? 'success' : 'error_update'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSuccess
                      ? const Color(0xFF16A34A)
                      : Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isSuccess
                    ? getTxt('success_body')
                    : '${getTxt('error_body')}\n\n${errorDetail ?? ''}',
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess
                        ? const Color(0xFF16A34A)
                        : Colors.red.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(getTxt('close'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    _showLoadingDialog();

    final user = Supabase.instance.client.auth.currentUser!;
    String? finalImageUrl = _imageUrl;

    try {
      if (_imageBytes != null && _imageExt != null) {
        final ext = _imageExt!;
        final fileName =
            '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
        final filePath = 'avatars/$fileName';

        final String contentType;
        if (ext == 'png') {
          contentType = 'image/png';
        } else if (ext == 'gif') {
          contentType = 'image/gif';
        } else if (ext == 'webp') {
          contentType = 'image/webp';
        } else {
          contentType = 'image/jpeg';
        }

        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(
              filePath,
              _imageBytes!,
              fileOptions:
                  FileOptions(contentType: contentType, upsert: true),
            );

        finalImageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(filePath);
      }

      await Supabase.instance.client
          .from('User')
          .update({
            'nama': _nameCtrl.text.trim(),
            if (finalImageUrl != null) 'gambar_user': finalImageUrl,
          })
          .eq('id_user', user.id);

      if (mounted) {
        Navigator.of(context).pop(); // tutup loading
        setState(() {
          _initialName = _nameCtrl.text.trim();
          _imageUrl = finalImageUrl;
          _imageFile = null;
          _imageBytes = null;
          _imageExt = null;
          _isEditMode = false;
          _hasChanges = false;
          _isSaving = false;
        });
        _showResultDialog(isSuccess: true);
      }
    } catch (e) {
      debugPrint('Error updating admin profile: $e');
      if (mounted) {
        Navigator.of(context).pop(); // tutup loading
        setState(() => _isSaving = false);
        _showResultDialog(isSuccess: false, errorDetail: e.toString());
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          getTxt('logout'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          getTxt('logout_confirm'),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(getTxt('cancel'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(getTxt('logout'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEditMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          _isEditMode = false;
          _nameCtrl.text = _initialName ?? '';
          _imageFile = null;
          _imageBytes = null;
          _imageExt = null;
          _hasChanges = false;
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF6366F1)),
            onPressed: () {
              if (_isEditMode) {
                setState(() {
                  _isEditMode = false;
                  _nameCtrl.text = _initialName ?? '';
                  _imageFile = null;
                  _imageBytes = null;
                  _imageExt = null;
                  _hasChanges = false;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            getTxt(_isEditMode ? 'edit_title' : 'title'),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6366F1),
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.08),
          actions: [
            if (!_isEditMode && !_isLoading)
              TextButton.icon(
                icon: const Icon(Icons.edit_rounded,
                    color: Color(0xFF6366F1), size: 18),
                label: Text(getTxt('edit'),
                    style: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _isEditMode = true),
                style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16)),
              ),
          ],
        ),
        body: _isLoading
            ? _buildSkeleton()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Header gradient ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 30, bottom: 36),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.18),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 56,
                                    backgroundColor:
                                        const Color(0xFFEDE9FE),
                                    backgroundImage: _imageBytes != null
                                        ? MemoryImage(_imageBytes!)
                                            as ImageProvider
                                        : (_imageUrl != null &&
                                                _imageUrl!.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                _imageUrl!)
                                            : null),
                                    child: (_imageBytes == null &&
                                            (_imageUrl == null ||
                                                _imageUrl!.isEmpty))
                                        ? const Icon(Icons.person,
                                            size: 56,
                                            color: Color(0xFF6366F1))
                                        : null,
                                  ),
                                ),
                                if (_isEditMode)
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFF6366F1),
                                          width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Color(0xFF6366F1),
                                        size: 18),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white,
                                    size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  _jabatan,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Form fields ──
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEditableField(
                            controller: _nameCtrl,
                            label: getTxt('name'),
                            icon: Icons.person_outline,
                            enabled: _isEditMode,
                          ),
                          _buildReadOnlyField(
                            value: _email,
                            label: getTxt('email'),
                            icon: Icons.email_outlined,
                          ),
                          _buildReadOnlyField(
                            value: _jabatan,
                            label: getTxt('role'),
                            icon: Icons.work_outline,
                          ),
                          const SizedBox(height: 24),

                          // ── Tombol simpan ──
                          if (_isEditMode)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasChanges
                                      ? const Color(0xFF6366F1)
                                      : Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  elevation: _hasChanges ? 4 : 0,
                                  shadowColor: const Color(0xFF6366F1)
                                      .withOpacity(0.35),
                                ),
                                onPressed: _hasChanges && !_isSaving
                                    ? _updateProfile
                                    : null,
                                child: Text(
                                  getTxt('save'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ),

                          const SizedBox(height: 40),

                          // ── Tombol logout ──
                          if (!_isEditMode)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.logout,
                                  color: Colors.redAccent),
                              label: Text(
                                getTxt('logout'),
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.red.withOpacity(0.1),
                                elevation: 0,
                                minimumSize:
                                    const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(15)),
                              ),
                              onPressed: _logout,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const CircleAvatar(radius: 60, backgroundColor: Colors.white),
            const SizedBox(height: 30),
            _skeletonField(),
            _skeletonField(),
            _skeletonField(),
          ],
        ),
      ),
    );
  }

  Widget _skeletonField() => Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      );

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                  letterSpacing: 0.3)),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF6366F1)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                  letterSpacing: 0.3)),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ],
    );
  }
}