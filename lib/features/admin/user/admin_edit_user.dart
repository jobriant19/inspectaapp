import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/auth_service.dart';
import '../../user/analytics/kts production/kts_section_location_picker.dart';
import 'camera/admin_user_camera.dart';
import 'picker/admin_user_pick_location.dart';
import 'picker/admin_user_pick_role.dart';
import 'picker/admin_user_pick_supervisor.dart';

class AdminEditUserScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> jabatanList;
  final VoidCallback onUserUpdated;

  const AdminEditUserScreen({
    super.key,
    required this.lang,
    required this.user,
    required this.jabatanList,
    required this.onUserUpdated,
  });

  @override
  State<AdminEditUserScreen> createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> {
  static const _primary = Color(0xFF6366F1);

  final AuthService _auth = AuthService();

  late final TextEditingController _namaCtrl;
  late final TextEditingController _emailCtrl;
  final TextEditingController _passCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl;

  bool _showPasswordField = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isNewPasswordVisible = false;
  bool _successPopupHandled = false;

  int? _selectedJabatan;
  bool _isVisitor = false;
  bool _isVerificator = false;
  String? _gambarUserUrl;
  AdminUserLocationSelection _locationSelection = const AdminUserLocationSelection();
  String? _selectedSupervisorId;
  String? _selectedBagianKasie;
  String? _selectedSectionId;

  List<Map<String, dynamic>> _supervisorList = [];

  String get _lang => widget.lang;

  Map<String, dynamic>? get _selectedSupervisorData {
    if (_selectedSupervisorId == null) return null;
    for (final s in _supervisorList) {
      if (s['id_user'] == _selectedSupervisorId) return s;
    }
    return null;
  }

  Map<String, dynamic>? get _selectedJabatanData {
    if (_selectedJabatan == null) return null;
    for (final j in widget.jabatanList) {
      if (j['id_jabatan'] == _selectedJabatan) return j;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _namaCtrl = TextEditingController(text: u['nama'] ?? '');
    _emailCtrl = TextEditingController(text: u['email'] ?? '');
    _phoneCtrl = TextEditingController(text: u['phone'] ?? '');
    _selectedJabatan = u['id_jabatan'] as int?;
    _isVisitor = u['is_visitor'] == true;
    _isVerificator = u['is_verificator'] == true;
    _gambarUserUrl = u['gambar_user'] as String?;
    _selectedSupervisorId = u['id_supervisor'] as String?;
    final bagian = (u['bagian_kasie'] as String?)?.trim();
    _selectedBagianKasie = (bagian == null || bagian.isEmpty) ? null : bagian;
    _selectedSectionId = u['id_section'] as String?;

    _loadInitialLocationSelection(
      idLokasi: u['id_lokasi'] as String?,
      idUnit: u['id_unit'] as String?,
      idSubunit: u['id_subunit'] as String?,
      idArea: u['id_area'] as String?,
    );
    _loadInitialData();
    AdminUserPhotoCameraWarmupService.instance.warmUp();
  }

  Future<void> _loadInitialLocationSelection({
    String? idLokasi,
    String? idUnit,
    String? idSubunit,
    String? idArea,
  }) async {
    final resolved = await resolveAdminUserLocationSelection(
      idLokasi: idLokasi,
      idUnit: idUnit,
      idSubunit: idSubunit,
      idArea: idArea,
    );
    if (mounted) setState(() => _locationSelection = resolved);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    AdminUserPhotoCameraWarmupService.instance.release();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final res = await Supabase.instance.client
        .from('User')
        .select(
          'id_user, nama, gambar_user, id_jabatan, is_verificator, '
          'jabatan!User_id_jabatan_fkey(nama_jabatan)',
        )
        .inFilter('id_jabatan', [2, 3])
        .order('nama');

    if (!mounted) return;
    setState(() {
      _supervisorList = List<Map<String, dynamic>>.from(res);
    });
  }

  Future<void> _save() async {
    final nama = _namaCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final userId = widget.user['id_user'] as String?;

    if (nama.isEmpty || email.isEmpty) {
      _showErrorPopup(
        _lang == 'EN'
            ? 'Name and email are required!'
            : _lang == 'ZH'
                ? '姓名和邮箱为必填项！'
                : 'Nama dan email wajib diisi!',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> updateData = {
        'nama': nama,
        'phone': phone.isEmpty ? null : phone,
        'id_jabatan': _selectedJabatan,
        'is_visitor': _isVisitor,
        'is_verificator': _isVerificator,
        'gambar_user': _gambarUserUrl,
        'id_lokasi': _locationSelection.idLokasi,
        'id_unit': _locationSelection.idUnit,
        'id_subunit': _locationSelection.idSubunit,
        'id_area': _locationSelection.idArea,
        'id_supervisor': _selectedSupervisorId,
        'bagian_kasie': _selectedJabatan == 3 ? _selectedBagianKasie : null,
        'id_section': _selectedJabatan == 3 ? _selectedSectionId : null,
      };

      if (pass.isNotEmpty) {
        if (pass.length < 8) {
          _showErrorPopup(
            _lang == 'EN'
                ? 'Password must be at least 8 characters'
                : _lang == 'ZH'
                    ? '密码至少需要8个字符'
                    : 'Password minimal 8 karakter',
          );
          setState(() => _isSaving = false);
          return;
        }
        try {
          await Supabase.instance.client.functions.invoke(
            'update-user-password',
            body: {'user_id': userId, 'new_password': pass},
          );
        } catch (fnErr) {
          debugPrint('Edge function error (non-fatal): $fnErr');
        }
        updateData['pass'] = _auth.hashPassword(email, pass);
      }

      await Supabase.instance.client
          .from('User')
          .update(updateData)
          .eq('id_user', userId!);

      if (mounted) {
        _showSuccessPopup(
          _lang == 'EN'
              ? 'User updated successfully!'
              : _lang == 'ZH'
                  ? '用户更新成功！'
                  : 'Pengguna berhasil diperbarui!',
        );
      }
    } catch (e) {
      _showErrorPopup('Error: $e');
      setState(() => _isSaving = false);
    }
  }

  void _showErrorPopup(String message) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'error',
      barrierColor: Colors.black.withValues(alpha:0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha:0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
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
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha:0.25),
                          width: 2),
                    ),
                    child: const Icon(Icons.error_rounded,
                        color: Color(0xFFDC2626), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _lang == 'EN'
                        ? 'Failed!'
                        : _lang == 'ZH'
                            ? '失败！'
                            : 'Gagal!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2500),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor:
                            const Color(0xFFDC2626).withValues(alpha:0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickProfilePhoto() async {
    final XFile? picked = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserPhotoCameraScreen(lang: _lang, isEdit: true),
      ),
    );
    AdminUserPhotoCameraWarmupService.instance.warmUp();

    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final safeExt = ext == 'png' ? 'png' : 'jpg';
      final userId = widget.user['id_user'] ?? 'edit-user';
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$safeExt';

      await Supabase.instance.client.storage.from('avatars').uploadBinary(
            'user/$fileName',
            bytes,
            fileOptions: FileOptions(
              contentType: safeExt == 'png' ? 'image/png' : 'image/jpeg',
              upsert: true,
            ),
          );

      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl('user/$fileName');

      if (mounted) setState(() => _gambarUserUrl = url);
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      if (mounted) _showErrorPopup('Error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // Popup sukses di tengah layar, style sama seperti admin_news_screen.dart
  void _showSuccessPopup(String message) {
    if (!mounted) return;
    _successPopupHandled = false;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.black.withValues(alpha:0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        void finish() {
          if (_successPopupHandled) return;
          _successPopupHandled = true;
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
          widget.onUserUpdated();
          if (mounted) Navigator.pop(context);
        }

        Future.delayed(const Duration(milliseconds: 2000), finish);

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha:0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
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
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha:0.25),
                          width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _lang == 'EN'
                        ? 'Success!'
                        : _lang == 'ZH'
                            ? '成功！'
                            : 'Berhasil!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2000),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor:
                            const Color(0xFF16A34A).withValues(alpha:0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF16A34A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _lang == 'EN'
              ? 'Edit User'
              : _lang == 'ZH'
                  ? '编辑用户'
                  : 'Edit Pengguna',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AVATAR
                  Row(
                    children: [
                      Icon(Icons.photo_camera_outlined,
                          size: 14, color: _primary),
                      const SizedBox(width: 6),
                      Text(
                        _lang == 'EN'
                            ? 'Profile Photo'
                            : _lang == 'ZH'
                                ? '头像'
                                : 'Foto Profil',
                        style: GoogleFonts.poppins(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: _primary.withValues(alpha:0.10),
                            backgroundImage: _gambarUserUrl != null
                                ? CachedNetworkImageProvider(_gambarUserUrl!)
                                : null,
                            child: _gambarUserUrl == null
                                ? Text(
                                    _namaCtrl.text.isNotEmpty
                                        ? _namaCtrl.text[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.poppins(
                                      color: _primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: _primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: _isUploadingPhoto
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_rounded,
                                      size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BASIC INFORMATION
                  _buildSectionLabel(
                    _lang == 'EN'
                        ? 'Basic Information'
                        : _lang == 'ZH'
                            ? '基本信息'
                            : 'Informasi Dasar',
                    Icons.person_outline,
                    const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                    _lang == 'EN'
                        ? 'Full Name'
                        : _lang == 'ZH'
                            ? '姓名'
                            : 'Nama Lengkap',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _namaCtrl,
                    _lang == 'EN'
                        ? 'Enter full name...'
                        : 'Masukkan nama lengkap...',
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Email', Icons.email_outlined),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _emailCtrl,
                    'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                    _lang == 'EN'
                        ? 'Phone'
                        : _lang == 'ZH'
                            ? '电话'
                            : 'Telepon',
                    Icons.phone_outlined,
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _phoneCtrl,
                    _lang == 'EN' ? 'e.g. 08123456789' : 'cth. 08123456789',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // PASSWORD TOGGLE
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showPasswordField = !_showPasswordField),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _showPasswordField
                            ? const Color(0xFFFFF7ED)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showPasswordField
                              ? const Color(0xFFF59E0B)
                              : Colors.grey.shade200,
                          width: _showPasswordField ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _showPasswordField
                                  ? const Color(0xFFF59E0B).withValues(alpha:0.12)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              size: 16,
                              color: _showPasswordField
                                  ? const Color(0xFFF59E0B)
                                  : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _lang == 'EN'
                                  ? 'Change Password'
                                  : _lang == 'ZH'
                                      ? '更改密码'
                                      : 'Ubah Password',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _showPasswordField
                                    ? const Color(0xFFF59E0B)
                                    : Colors.black54,
                              ),
                            ),
                          ),
                          Icon(
                            _showPasswordField
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: _showPasswordField
                                ? const Color(0xFFF59E0B)
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showPasswordField) ...[
                    const SizedBox(height: 10),
                    _buildTextField(
                      _passCtrl,
                      _lang == 'EN'
                          ? 'New password (min 8 characters)'
                          : _lang == 'ZH'
                              ? '新密码（最少8个字符）'
                              : 'Password baru (minimal 8 karakter)',
                      obscure: !_isNewPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: _primary,
                          size: 22,
                        ),
                        onPressed: () => setState(() =>
                            _isNewPasswordVisible = !_isNewPasswordVisible),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _lang == 'EN'
                            ? 'Leave empty to keep current password'
                            : _lang == 'ZH'
                                ? '留空则保持当前密码'
                                : 'Kosongkan jika tidak ingin mengubah password',
                        style:
                            GoogleFonts.poppins(fontSize: 11, color: Colors.black38),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                    _lang == 'EN'
                        ? 'Role'
                        : _lang == 'ZH'
                            ? '角色'
                            : 'Role',
                    Icons.work_outline_rounded,
                  ),
                  const SizedBox(height: 6),
                  AdminRolePickerCard(
                    lang: _lang,
                    selectedRole: _selectedJabatanData,
                    onTap: () async {
                      final result = await showAdminPickRoleDialog(
                        context,
                        lang: _lang,
                        jabatanList: widget.jabatanList,
                        selectedJabatanId: _selectedJabatan,
                      );
                      if (result == null) return;
                      setState(() {
                        _selectedJabatan = result['id_jabatan'] as int?;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // KASIE SECTION
                  if (_selectedJabatan == 3) ...[
                    _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Kasie Section'
                          : _lang == 'ZH'
                              ? '科长部门'
                              : 'Bagian Kasie',
                      Icons.apartment_outlined,
                    ),
                    const SizedBox(height: 6),
                    _buildBagianKasiePicker(),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 6),
                  _buildDivider(),
                  const SizedBox(height: 20),

                  // LOCATION
                  _buildSectionLabel(
                    _lang == 'EN'
                        ? 'Location Assignment'
                        : _lang == 'ZH'
                            ? '位置分配'
                            : 'Penempatan Lokasi',
                    Icons.location_city_rounded,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                    _lang == 'EN' ? 'Location' : _lang == 'ZH' ? '位置' : 'Lokasi',
                    Icons.location_city_rounded,
                  ),
                  const SizedBox(height: 6),
                  AdminLocationAssignmentCard(
                    lang: _lang,
                    selection: _locationSelection,
                    onTap: () async {
                      final result = await showAdminUserPickLocationDialog(
                        context,
                        lang: _lang,
                        initial: _locationSelection,
                      );
                      if (result == null) return;
                      setState(() => _locationSelection = result);
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildDivider(),
                  const SizedBox(height: 20),

                  // SUPERVISOR
                  _buildSectionLabel(
                    _lang == 'EN'
                        ? 'Supervisor'
                        : _lang == 'ZH'
                            ? '主管'
                            : 'Supervisor',
                    Icons.manage_accounts_outlined,
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                    _lang == 'EN'
                        ? 'Select Supervisor'
                        : _lang == 'ZH'
                            ? '选择主管'
                            : 'Pilih Supervisor',
                    Icons.person_search_outlined,
                  ),
                  const SizedBox(height: 6),
                  // Kartu popup pemilih supervisor (menggantikan dropdown lama).
                  AdminSupervisorPickerCard(
                    lang: _lang,
                    selectedSupervisor: _selectedSupervisorData,
                    onTap: () async {
                      final result = await showAdminPickSupervisorDialog(
                        context,
                        lang: _lang,
                        supervisorList: _supervisorList,
                        selectedSupervisorId: _selectedSupervisorId,
                      );
                      // null -> dialog ditutup tanpa memilih apa pun, biarkan.
                      if (result == null) return;
                      setState(() {
                        // map kosong ({}) berarti user memilih "Tanpa supervisor".
                        _selectedSupervisorId =
                            result.isEmpty ? null : result['id_user'] as String?;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildDivider(),
                  const SizedBox(height: 20),

                  // ROLE & ACCESS
                  _buildSectionLabel(
                    _lang == 'EN'
                        ? 'Role & Access'
                        : _lang == 'ZH'
                            ? '角色与权限'
                            : 'Peran & Akses',
                    Icons.shield_outlined,
                    const Color(0xFF0891B2),
                  ),
                  const SizedBox(height: 14),

                  _buildToggleRow(
                    _lang == 'EN'
                        ? 'Visitor Mode'
                        : _lang == 'ZH'
                            ? '访客模式'
                            : 'Mode Pengunjung',
                    Icons.visibility_outlined,
                    _isVisitor,
                    (v) => setState(() => _isVisitor = v),
                    const Color(0xFF0891B2),
                  ),
                  const SizedBox(height: 10),
                  _buildToggleRow(
                    _lang == 'EN'
                        ? 'Verificator'
                        : _lang == 'ZH'
                            ? '验证员'
                            : 'Verifikator',
                    Icons.verified_user_outlined,
                    _isVerificator,
                    (v) => setState(() => _isVerificator = v),
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // STICKY FOOTER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _isSaving
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _lang == 'EN'
                                ? 'Cancel'
                                : _lang == 'ZH'
                                    ? '取消'
                                    : 'Batal',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            shadowColor: _primary.withValues(alpha:0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _lang == 'EN'
                                    ? 'Update'
                                    : _lang == 'ZH'
                                        ? '更新'
                                        : 'Perbarui',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Container(
          width: 3,
          height: 14,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E3A8A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // Label field dengan ikon di kiri, warna ungu, Poppins w700
  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: _primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() =>
      Divider(color: Colors.grey.shade100, thickness: 1.5);

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
    TextInputType? keyboardType,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? const Color(0xFFCBD5E1) : Colors.grey.shade200,
          width: 1.3,
        ),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: enabled,
        style: GoogleFonts.poppins(
          color: enabled ? const Color(0xFF1E3A8A) : Colors.black38,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildBagianKasiePicker() {
    const kasieColor = Color(0xFF0891B2);
    final hasValue = _selectedBagianKasie != null && _selectedBagianKasie!.isNotEmpty;
    return GestureDetector(
      onTap: () async {
        final result = await showKtsSectionLocationPicker(context, lang: _lang);
        if (result == null) return;
        setState(() {
          _selectedBagianKasie = result.isAllSections ? null : result.sectionName;
          _selectedSectionId  = result.isAllSections ? null : result.sectionId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasValue ? kasieColor.withValues(alpha:0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? kasieColor.withValues(alpha:0.5) : const Color(0xFFCBD5E1),
            width: hasValue ? 1.4 : 1.2,
          ),
        ),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: hasValue ? kasieColor : kasieColor.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.apartment_outlined, size: 15, color: hasValue ? Colors.white : kasieColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasValue
                  ? _selectedBagianKasie!
                  : (_lang == 'EN' ? 'Select section' : _lang == 'ZH' ? '选择部门' : 'Pilih bagian'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                color: hasValue ? kasieColor : Colors.black38,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: hasValue ? kasieColor : Colors.black26),
        ]),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha:0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: value ? color.withValues(alpha:0.25) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: value ? color.withValues(alpha:0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: value ? color : Colors.grey.shade400, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: value ? const Color(0xFF1E3A8A) : Colors.black45,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withValues(alpha:0.25),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}