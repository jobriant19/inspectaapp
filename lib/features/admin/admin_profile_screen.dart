import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/image_picker_helper.dart';
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

  // Password change state
  bool _showPasswordSection = false;
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  bool _isNewPassVisible = false;
  bool _isConfirmPassVisible = false;

  // Teks UI
  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'My Profile',
      'change_password': 'Change Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'password_hint': 'Min 6 characters',
      'confirm_hint': 'Re-enter new password',
      'password_mismatch': 'Passwords do not match!',
      'password_too_short': 'Password must be at least 6 characters',
      'password_updated': 'Password updated successfully!',
      'password_error': 'Failed to update password',
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
      'change_password': 'Ubah Password',
      'new_password': 'Password Baru',
      'confirm_password': 'Konfirmasi Password',
      'password_hint': 'Min 6 karakter',
      'confirm_hint': 'Ulangi password baru',
      'password_mismatch': 'Password tidak cocok!',
      'password_too_short': 'Password minimal 6 karakter',
      'password_updated': 'Password berhasil diperbarui!',
      'password_error': 'Gagal memperbarui password',
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
    'ZH': {
      'title': '我的资料',
      'change_password': '修改密码',
      'new_password': '新密码',
      'confirm_password': '确认密码',
      'password_hint': '最少6个字符',
      'confirm_hint': '再次输入新密码',
      'password_mismatch': '两次密码不一致！',
      'password_too_short': '密码至少需要6个字符',
      'password_updated': '密码更新成功！',
      'password_error': '更新密码失败',
      'edit_title': '编辑资料',
      'name': '姓名',
      'email': '电子邮件',
      'role': '角色',
      'save': '保存更改',
      'edit': '编辑',
      'success': '资料已更新！',
      'success_body': '您的资料已成功更新。',
      'error_update': '更新失败',
      'error_body': '更新资料失败，请重试。',
      'close': '关闭',
      'saving': '正在保存资料...',
      'uploading': '正在上传照片...',
      'logout': '退出登录',
      'logout_confirm': '您确定要退出吗？',
      'cancel': '取消',
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
    // Pastikan bgadmin sudah di-cache agar home screen langsung muncul saat pop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/images/bgadmin.png'),
        context,
      ).catchError((_) {});
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
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
    final picked = await ImagePickerHelper.pickImageFromGallery(
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
                color: Colors.black.withValues(alpha:0.12),
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
                color: Colors.black.withValues(alpha:0.15),
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
          _showPasswordSection = false;
          _newPassCtrl.clear();
          _confirmPassCtrl.clear();
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

  Future<void> _updatePassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (newPass.length < 6) {
      _showResultDialog(isSuccess: false, errorDetail: getTxt('password_too_short'));
      return;
    }
    if (newPass != confirmPass) {
      _showResultDialog(isSuccess: false, errorDetail: getTxt('password_mismatch'));
      return;
    }

    setState(() => _isSaving = true);
    _showLoadingDialog();

    final user = Supabase.instance.client.auth.currentUser!;

    try {
      // 1. Update di Supabase Auth via Edge Function
      await Supabase.instance.client.functions.invoke(
        'update-user-password',
        body: {
          'user_id': user.id,
          'new_password': newPass,
        },
      );

      // 2. Update hash di tabel User
      final authService = AuthService();
      final newHash = authService.hashPassword(
        Supabase.instance.client.auth.currentUser!.email ?? '',
        newPass,
      );
      await Supabase.instance.client
          .from('User')
          .update({'pass': newHash})
          .eq('id_user', user.id);

      if (mounted) {
        Navigator.of(context).pop(); // tutup loading
        setState(() {
          _newPassCtrl.clear();
          _confirmPassCtrl.clear();
          _showPasswordSection = false;
          _isSaving = false;
        });
        _showPasswordSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error updating password: $e');
      if (mounted) {
        Navigator.of(context).pop(); // tutup loading
        setState(() => _isSaving = false);
        _showResultDialog(isSuccess: false, errorDetail: e.toString());
      }
    }
  }

  void _showPasswordSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.15),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: Color(0xFF16A34A),
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                getTxt('password_updated'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    getTxt('close'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon lingkaran merah
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
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
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                getTxt('logout_confirm'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Tombol Logout (merah penuh)
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Tombol Batal (outline abu)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    getTxt('cancel'),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF64748B),
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
          _showPasswordSection = false;
          _newPassCtrl.clear();
          _confirmPassCtrl.clear();
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
            color: Color(0xFF059669)),
            onPressed: () {
              if (_isEditMode) {
                setState(() {
                  _isEditMode = false;
                  _nameCtrl.text = _initialName ?? '';
                  _imageFile = null;
                  _imageBytes = null;
                  _imageExt = null;
                  _hasChanges = false;
                  _showPasswordSection = false;
                  _newPassCtrl.clear();
                  _confirmPassCtrl.clear();
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
              color: const Color(0xFF059669),
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha:0.08),
          actions: [
            if (!_isEditMode && !_isLoading)
              TextButton.icon(
                icon: const Icon(Icons.edit_rounded,
                    color: Color(0xFF059669), size: 18),
                label: Text(getTxt('edit'),
                    style: const TextStyle(
                        color: Color(0xFF059669),
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
                    // ── Header dengan background image + overlay hijau ──
                    _AnimatedProfileHeader(
                      jabatan: _jabatan,
                      imageBytes: _imageBytes,
                      imageUrl: _imageUrl,
                      isEditMode: _isEditMode,
                      onTap: _pickImage,
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

                          // ── Section: Change Password (selalu tampil, tidak perlu edit mode) ──
                          _buildPasswordSection(),

                          const SizedBox(height: 24),

                          // ── Tombol simpan ──
                          if (_isEditMode)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasChanges
                                      ? const Color(0xFF059669)
                                      : Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  elevation: _hasChanges ? 4 : 0,
                                  shadowColor: const Color(0xFF059669)
                                      .withValues(alpha:0.35),
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
                                    Colors.red.withValues(alpha:0.1),
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

  Widget _buildPasswordSection() {
    // Hanya tampil saat edit mode aktif
    if (!_isEditMode) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle header
        GestureDetector(
          onTap: () {
            setState(() {
              _showPasswordSection = !_showPasswordSection;
              if (!_showPasswordSection) {
                _newPassCtrl.clear();
                _confirmPassCtrl.clear();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _showPasswordSection
                  ? const Color(0xFFF0FDF4)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showPasswordSection
                    ? const Color(0xFF059669)
                    : Colors.grey.shade200,
                width: _showPasswordSection ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha:0.07),
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
                    color: _showPasswordSection
                        ? const Color(0xFFD1FAE5)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 18,
                    color: _showPasswordSection
                        ? const Color(0xFF059669)
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getTxt('change_password'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _showPasswordSection
                          ? const Color(0xFF059669)
                          : Colors.black54,
                    ),
                  ),
                ),
                Icon(
                  _showPasswordSection
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _showPasswordSection
                      ? const Color(0xFF059669)
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),

        // Form fields (muncul jika toggle aktif)
        if (_showPasswordSection) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              getTxt('new_password'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
                letterSpacing: 0.3,
              ),
            ),
          ),
          _buildPasswordField(
            controller: _newPassCtrl,
            hint: getTxt('password_hint'),
            isVisible: _isNewPassVisible,
            onToggle: () =>
                setState(() => _isNewPassVisible = !_isNewPassVisible),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              getTxt('confirm_password'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
                letterSpacing: 0.3,
              ),
            ),
          ),
          _buildPasswordField(
            controller: _confirmPassCtrl,
            hint: getTxt('confirm_hint'),
            isVisible: _isConfirmPassVisible,
            onToggle: () => setState(
                () => _isConfirmPassVisible = !_isConfirmPassVisible),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 18),
              label: Text(
                getTxt('change_password'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                shadowColor: const Color(0xFF059669).withValues(alpha:0.4),
              ),
              onPressed: _isSaving ? null : _updatePassword,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF059669),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha:0.07),
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
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline,
                color: Color(0xFF059669), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !isVisible,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ),
        ],
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
                  color: Color(0xFF059669),
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
                  ? const Color(0xFF059669)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha:0.07),
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
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF059669), size: 20),
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
                  color: Color(0xFF059669),
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
                color: const Color(0xFF059669).withValues(alpha:0.07),
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
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF059669), size: 20),
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

// ─── Animated Profile Header ──────────────────────────────────────────────────
class _AnimatedProfileHeader extends StatefulWidget {
  final String jabatan;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool isEditMode;
  final VoidCallback onTap;

  const _AnimatedProfileHeader({
    required this.jabatan,
    required this.imageBytes,
    required this.imageUrl,
    required this.isEditMode,
    required this.onTap,
  });

  @override
  State<_AnimatedProfileHeader> createState() =>
      _AnimatedProfileHeaderState();
}

class _AnimatedProfileHeaderState extends State<_AnimatedProfileHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderCtrl;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _borderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: Container(
        width: double.infinity,
        height: 220,
        // ── Fallback warna hijau cerah jika gambar gagal ──
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image TANPA overlay ──
            Image.asset(
              'assets/images/bgadmin.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),

            // ── Dekorasi lingkaran latar (subtle) ──
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: 30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.04),
                ),
              ),
            ),

            // ── Konten utama ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Avatar dengan border gradient hijau-biru ──
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        // Ring gradient seperti admin_home_screen
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34D399), Color(0xFF38BDF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF059669).withValues(alpha:0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFD1FAE5),
                              backgroundImage: widget.imageBytes != null
                                  ? MemoryImage(widget.imageBytes!)
                                      as ImageProvider
                                  : (widget.imageUrl != null &&
                                          widget.imageUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          widget.imageUrl!)
                                      : null),
                              child: (widget.imageBytes == null &&
                                      (widget.imageUrl == null ||
                                          widget.imageUrl!.isEmpty))
                                  ? const Icon(Icons.person,
                                      size: 50, color: Color(0xFF059669))
                                  : null,
                            ),
                          ),
                        ),
                        if (widget.isEditMode)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF10B981), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Color(0xFF10B981), size: 15),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Badge jabatan: border solid hijau, animasi hanya perubahan warna ──
                  AnimatedBuilder(
                    animation: _borderCtrl,
                    builder: (_, child) {
                      // Interpolasi warna border: hijau cerah ↔ biru cerah
                      final borderColor = Color.lerp(
                        const Color(0xFF34D399),
                        const Color(0xFF38BDF8),
                        (_borderCtrl.value < 0.5
                            ? _borderCtrl.value * 2
                            : (1 - _borderCtrl.value) * 2),
                      )!;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 69, 223, 118),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: borderColor,
                            width: 2.5,
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded,
                            color: Colors.white, size: 15),
                        const SizedBox(width: 7),
                        Text(
                          widget.jabatan,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}