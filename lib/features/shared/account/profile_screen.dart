import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shimmer/shimmer.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/utils/jabatan_helper.dart';

class ProfileScreen extends StatefulWidget {
  final String lang;
  final String? initialUserName;
  final String? initialUserImage;
  final String? initialUserRole;
  final String? initialUserLocation;
  final bool? isVerificator;
  final int? userJabatanId;

  const ProfileScreen({
    super.key, 
    required this.lang,
    this.initialUserName,
    this.initialUserImage,
    this.initialUserRole,
    this.initialUserLocation,
    this.isVerificator,
    this.userJabatanId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _email = '', _jabatan = '', _lokasi = '';
  String? _initialName, _imageUrl;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _imageExt;
  bool _isSaving = false;
  bool _isScreenLoading = true;
  bool _isEditMode = false;
  bool _hasChanges = false;

  // Password change state
  bool _showPasswordSection = false;
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();
  bool _isNewPassVisible = false;
  bool _isConfirmPassVisible = false;

  final Map<String, Map<String, String>> _txt = {
    'EN': { 'profile_title': 'My Profile', 'edit_title': 'Edit Profile', 'name': 'Name', 'email': 'Email Address', 'role': 'Job Title', 'location': 'Location', 'save': 'Save Changes', 'success': 'Profile Updated!', 'success_body': 'Your profile has been successfully updated.', 'edit': 'Edit', 'verifier': 'Verifier', 'error_update': 'Update Failed', 'error_body': 'Failed to update profile. Please try again.', 'close': 'Close', 'saving': 'Saving your profile...', 'uploading': 'Uploading photo...', 'change_password': 'Change Password',
            'new_password': 'New Password',
            'confirm_password': 'Confirm Password',
            'password_hint': 'Min 6 characters',
            'confirm_hint': 'Re-enter new password',
            'password_mismatch': 'Passwords do not match!',
            'password_too_short': 'Password must be at least 6 characters',
            'password_updated': 'Password updated successfully!',
            'password_error': 'Failed to update password' },
    'ID': { 'profile_title': 'Profil Saya', 'edit_title': 'Ubah Profil', 'name': 'Nama', 'email': 'Alamat Email', 'role': 'Jabatan', 'location': 'Lokasi', 'save': 'Simpan Perubahan', 'success': 'Profil Diperbarui!', 'success_body': 'Profil Anda berhasil diperbarui.', 'edit': 'Ubah', 'verifier': 'Verifier', 'error_update': 'Gagal Memperbarui', 'error_body': 'Gagal memperbarui profil. Silakan coba lagi.', 'close': 'Tutup', 'saving': 'Menyimpan profil Anda...', 'uploading': 'Mengunggah foto...', 'change_password': 'Ubah Password',
            'new_password': 'Password Baru',
            'confirm_password': 'Konfirmasi Password',
            'password_hint': 'Min 6 karakter',
            'confirm_hint': 'Ulangi password baru',
            'password_mismatch': 'Password tidak cocok!',
            'password_too_short': 'Password minimal 6 karakter',
            'password_updated': 'Password berhasil diperbarui!',
            'password_error': 'Gagal memperbarui password' },
    'ZH': { 'profile_title': '我的资料', 'edit_title': '编辑资料', 'name': '姓名', 'email': '电子邮件', 'role': '职位', 'location': '地点', 'save': '保存更改', 'success': '资料已更新！', 'success_body': '您的资料已成功更新。', 'edit': '编辑', 'verifier': '验证者', 'error_update': '更新失败', 'error_body': '无法更新资料，请重试。', 'close': '关闭', 'saving': '正在保存资料...', 'uploading': '正在上传照片...', 'change_password': '修改密码',
            'new_password': '新密码',
            'confirm_password': '确认密码',
            'password_hint': '最少6个字符',
            'confirm_hint': '再次输入新密码',
            'password_mismatch': '两次密码不一致！',
            'password_too_short': '密码至少需要6个字符',
            'password_updated': '密码更新成功！',
            'password_error': '更新密码失败' },
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

  @override
  void dispose() {
    _nameController.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (widget.initialUserName != null && widget.initialUserName != "Loading...") {
      setState(() {
        _nameController.text = widget.initialUserName!;
        _initialName = widget.initialUserName!;
        _imageUrl = widget.initialUserImage;
        _jabatan = (widget.isVerificator == true)
          ? getTxt('verifier')
          : widget.initialUserRole!;
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
    final picked = await ImagePickerHelper.pickImageFromGallery(
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes(); // Baca langsung ke bytes
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.12), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1D72F3)),
                  backgroundColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _imageBytes != null ? getTxt('uploading') : getTxt('saving'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '...',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.15), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFFDCFCE7) : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isSuccess ? const Color(0xFF16A34A) : Colors.red.shade400,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                getTxt(isSuccess ? 'success' : 'error_update'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? const Color(0xFF16A34A) : Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isSuccess ? getTxt('success_body') : '${getTxt('error_body')}\n\n$errorDetail',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? const Color(0xFF16A34A) : Colors.red.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(getTxt('close'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BAGIAN UTAMA PERBAIKAN: METHOD UNTUK MENYIMPAN PROFIL ---
  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    _showLoadingDialog(); // Tampilkan loading dialog

    final user = Supabase.instance.client.auth.currentUser!;
    String? finalImageUrl = _imageUrl;

    try {
      if (_imageBytes != null && _imageExt != null) {
        final ext = _imageExt!;
        final fileName = '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$ext';
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
              fileOptions: FileOptions(contentType: contentType, upsert: true),
            );

        finalImageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(filePath);
      }

      await Supabase.instance.client
          .from('User')
          .update({
            'nama': _nameController.text.trim(),
            if (finalImageUrl != null) 'gambar_user': finalImageUrl,
          })
          .eq('id_user', user.id);

      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading dialog
        setState(() {
          _initialName = _nameController.text.trim();
          _imageUrl = finalImageUrl;
          _imageFile = null;
          _imageBytes = null;
          _imageExt = null;
          _isEditMode = false;
          _hasChanges = false;
        });
        _showResultDialog(isSuccess: true);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Tutup loading dialog
        _showResultDialog(isSuccess: false, errorDetail: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      await Supabase.instance.client.functions.invoke(
        'update-user-password',
        body: {
          'user_id': user.id,
          'new_password': newPass,
        },
      );

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

  Widget _buildPasswordSection() {
    if (!_isEditMode) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  ? const Color(0xFFEFF6FF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showPasswordSection
                    ? const Color(0xFF1D72F3)
                    : Colors.grey.shade200,
                width: _showPasswordSection ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D72F3).withValues(alpha:0.07),
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
                        ? const Color(0xFFBFDBFE)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 18,
                    color: _showPasswordSection
                        ? const Color(0xFF1D72F3)
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
                          ? const Color(0xFF1D72F3)
                          : Colors.black54,
                    ),
                  ),
                ),
                Icon(
                  _showPasswordSection
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _showPasswordSection
                      ? const Color(0xFF1D72F3)
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        if (_showPasswordSection) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              getTxt('new_password'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D72F3),
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
                color: Color(0xFF1D72F3),
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
                backgroundColor: const Color(0xFF1D72F3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                shadowColor: const Color(0xFF1D72F3).withValues(alpha:0.4),
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
          color: const Color(0xFF1D72F3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D72F3).withValues(alpha:0.07),
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
              color: const Color(0xFFBFDBFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline,
                color: Color(0xFF1D72F3), size: 20),
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
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13),
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

  Widget _buildRoleBadge() {
    // is_verificator TRUE selalu menang, abaikan id_jabatan
    final bool isVerif = widget.isVerificator == true ||
        _jabatan.toLowerCase().contains('verif');

    // Resolve id_jabatan dari nama jika parameter tidak tersedia
    int? resolvedId = widget.userJabatanId;
    if (!isVerif && resolvedId == null) {
      final lower = _jabatan.toLowerCase();
      if (lower.contains('eksekutif') || lower.contains('executive')) { resolvedId = 1; }
      else if (lower.contains('manager') || lower.contains('manajer'))  { resolvedId = 2; }
      else if (lower.contains('kasi') || lower.contains('kepala seksi')) { resolvedId = 3; }
      else { resolvedId = 4; }
    }

    final colors  = JabatanHelper.getGradientColors(
      isVerificatorFlag: isVerif ? true : null,
      idJabatan: resolvedId,
    );
    final icon = JabatanHelper.getRoleIcon(
      isVerificatorFlag: isVerif ? true : null,
      idJabatan: resolvedId,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha:0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            _jabatan,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEditMode, // Izinkan swipe back langsung jika bukan edit mode
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Hanya masuk sini jika canPop = false (yaitu saat _isEditMode = true)
        setState(() {
          _isEditMode = false;
          _nameController.text = _initialName ?? '';
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
        backgroundColor: const Color(0xFFEFF6FF),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D72F3)),
            onPressed: () {
              if (_isEditMode) {
                setState(() {
                  _isEditMode = false;
                  _nameController.text = _initialName ?? '';
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
            getTxt(_isEditMode ? 'edit_title' : 'profile_title'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Color(0xFF1D72F3), fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha:0.08),
          iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
          actions: [
            if (!_isEditMode && !_isScreenLoading)
              TextButton.icon(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF1D72F3), size: 18),
                label: Text(getTxt('edit'), style: const TextStyle(color: Color(0xFF1D72F3), fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _isEditMode = true),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
              ),
          ],
        ),
        body: _isScreenLoading
            ? _buildSkeletonBody()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header avatar biru
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 230,
                        color: const Color(0xFF1D72F3),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/images/bgadmin.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                            // Dekorasi lingkaran latar (subtle)
                            Positioned(
                              top: -30, right: -20,
                              child: Container(
                                width: 130, height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha:0.06),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -40, left: 30,
                              child: Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha:0.04),
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2.5),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF93C5FD), Color(0xFF00C9E4)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha:0.18),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
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
                                              radius: 54,
                                              backgroundColor: const Color(0xFFBFDBFE),
                                              backgroundImage: _imageBytes != null
                                                  ? MemoryImage(_imageBytes!) as ImageProvider
                                                  : (_imageUrl != null && _imageUrl!.isNotEmpty
                                                      ? NetworkImage(_imageUrl!)
                                                      : null),
                                              child: (_imageBytes == null &&
                                                      (_imageUrl == null || _imageUrl!.isEmpty))
                                                  ? const Icon(Icons.person,
                                                      size: 54, color: Color(0xFF1D72F3))
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (_isEditMode)
                                          Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: const Color(0xFF1D72F3), width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black.withValues(alpha:0.12),
                                                    blurRadius: 8),
                                              ],
                                            ),
                                            child: const Icon(Icons.camera_alt,
                                                color: Color(0xFF1D72F3), size: 18),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildRoleBadge(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Form fields
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoFieldEditable(
                            controller: _nameController,
                            label: getTxt('name'),
                            icon: Icons.person_outline,
                            enabled: _isEditMode,
                          ),
                          _buildInfoField(_email, getTxt('email'), Icons.email_outlined),
                          _buildInfoField(_jabatan, getTxt('role'), Icons.work_outline),
                          _buildInfoField(_lokasi, getTxt('location'), Icons.location_on_outlined),
                          const SizedBox(height: 24),
                          _buildPasswordSection(),
                          const SizedBox(height: 16),
                          if (_isEditMode)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasChanges ? const Color(0xFF1D72F3) : Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: _hasChanges ? 4 : 0,
                                  shadowColor: const Color(0xFF1D72F3).withValues(alpha:0.35),
                                ),
                                onPressed: _hasChanges && !_isSaving ? _updateProfile : null,
                                child: Text(
                                  getTxt('save'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
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

  Widget _buildInfoFieldEditable({
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
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D72F3), letterSpacing: 0.3),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), // sama persis dengan _buildInfoField
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled ? const Color(0xFF1D72F3) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [BoxShadow(color: const Color(0xFF1D72F3).withValues(alpha:0.07), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1D72F3), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
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

  Widget _buildInfoField(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D72F3), letterSpacing: 0.3),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF1D72F3).withValues(alpha:0.07), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1D72F3), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}