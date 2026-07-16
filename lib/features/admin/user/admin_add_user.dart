import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/auth_service.dart';
import '../../user/analytics/kts production/kts_section_location_picker.dart';
import '../../user/home/alert/required_field_alert.dart';
import 'camera/admin_user_camera.dart';
import 'picker/admin_user_pick_location.dart';
import 'picker/admin_user_pick_role.dart';
import 'picker/admin_user_pick_supervisor.dart';

class AdminAddUserScreen extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>> jabatanList;
  final VoidCallback onUserAdded;

  const AdminAddUserScreen({
    super.key,
    required this.lang,
    required this.jabatanList,
    required this.onUserAdded,
  });

  @override
  State<AdminAddUserScreen> createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends State<AdminAddUserScreen> {
  static const _primary = Color(0xFF6366F1);

  final AuthService _auth = AuthService();

  final namaCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  int? selectedJabatan;
  bool isVisitor = false;
  bool isVerificator = false;
  bool isSaving = false;
  bool isUploadingPhoto = false;
  bool isPasswordVisible = false;
  bool _successPopupHandled = false;
  String? gambarUserUrl;
  AdminUserLocationSelection _locationSelection = const AdminUserLocationSelection();
  String? selectedSupervisorId;
  String? selectedBagianKasie;
  String? selectedSectionId;

  List<Map<String, dynamic>> supervisorList = [];

  String get _lang => widget.lang;

  Map<String, dynamic>? get _selectedSupervisorData {
    if (selectedSupervisorId == null) return null;
    for (final s in supervisorList) {
      if (s['id_user'] == selectedSupervisorId) return s;
    }
    return null;
  }

  Map<String, dynamic>? get _selectedJabatanData {
    if (selectedJabatan == null) return null;
    for (final j in widget.jabatanList) {
      if (j['id_jabatan'] == selectedJabatan) return j;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    AdminUserPhotoCameraWarmupService.instance.warmUp();
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    phoneCtrl.dispose();
    AdminUserPhotoCameraWarmupService.instance.release();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final res = await Supabase.instance.client
        .from('User')
        .select(
          'id_user, nama, gambar_user, id_jabatan, is_verificator, '
          'jabatan!User_id_jabatan_fkey(nama_jabatan)',
        )
        .inFilter('id_jabatan', [2, 3])
        .order('nama');
    if (mounted) {
      setState(() {
        supervisorList = List<Map<String, dynamic>>.from(res);
      });
    }
  }

  Future<void> _saveUser() async {
    final nama = namaCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    final List<MissingFieldItem> missingFields = [];
    if (gambarUserUrl == null) {
      missingFields.add(MissingFieldItem(
        icon: Icons.photo_camera_outlined,
        label: _lang == 'EN'
            ? 'Profile Photo'
            : _lang == 'ZH'
                ? '头像'
                : 'Foto Profil',
      ));
    }
    if (nama.isEmpty) {
      missingFields.add(MissingFieldItem(
        icon: Icons.person_outline,
        label: _lang == 'EN'
            ? 'Full Name'
            : _lang == 'ZH'
                ? '姓名'
                : 'Nama Lengkap',
      ));
    }
    if (email.isEmpty) {
      missingFields.add(const MissingFieldItem(
        icon: Icons.email_outlined,
        label: 'Email',
      ));
    }
    if (pass.isEmpty) {
      missingFields.add(MissingFieldItem(
        icon: Icons.lock_outline,
        label: _lang == 'EN'
            ? 'Password'
            : _lang == 'ZH'
                ? '密码'
                : 'Kata Sandi',
      ));
    }
    if (selectedJabatan == null) {
      missingFields.add(MissingFieldItem(
        icon: Icons.work_outline_rounded,
        label: _lang == 'EN'
            ? 'Role'
            : _lang == 'ZH'
                ? '角色'
                : 'Role',
      ));
    }

    if (missingFields.isNotEmpty) {
      await RequiredFieldAlert.show(context, lang: _lang, missingFields: missingFields);
      return;
    }

    if (pass.length < 8) {
      _showErrorPopup(
        _lang == 'EN'
            ? 'Password must be at least 8 characters'
            : _lang == 'ZH'
                ? '密码至少需要8个字符'
                : 'Password minimal 8 karakter',
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final res = await _auth.signUpWithEmail(email, pass);
      if (res == null || res.user == null) {
        _showErrorPopup(
          _lang == 'EN'
              ? 'Registration failed. Please try again.'
              : _lang == 'ZH'
                  ? '注册失败，请重试。'
                  : 'Pendaftaran gagal. Silakan coba lagi.',
        );
        setState(() => isSaving = false);
        return;
      }

      final hashedPass = _auth.hashPassword(email, pass);

      await Supabase.instance.client.from('User').insert({
        'id_user': res.user!.id,
        'nama': nama,
        'email': email,
        'pass': hashedPass,
        'phone': phone.isEmpty ? null : phone,
        'id_jabatan': selectedJabatan ?? 4,
        'poin': 0,
        'is_visitor': isVisitor,
        'is_verificator': isVerificator,
        'gambar_user': gambarUserUrl,
        'id_lokasi': _locationSelection.idLokasi,
        'id_unit': _locationSelection.idUnit,
        'id_subunit': _locationSelection.idSubunit,
        'id_area': _locationSelection.idArea,
        'timestamp': DateTime.now().toIso8601String(),
        'id_supervisor': selectedSupervisorId,
        'bagian_kasie': selectedJabatan == 3 ? selectedBagianKasie : null,
        'id_section': selectedJabatan == 3 ? selectedSectionId : null,
      });

      if (mounted) {
        _showSuccessPopup(
          _lang == 'EN'
              ? 'User registered successfully!'
              : _lang == 'ZH'
                  ? '用户注册成功！'
                  : 'Pengguna berhasil didaftarkan!',
        );
      }
    } on AuthException catch (e) {
      _showErrorPopup('Auth Error: ${e.message}');
      setState(() => isSaving = false);
    } catch (e) {
      _showErrorPopup('Error: $e');
      setState(() => isSaving = false);
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
        builder: (_) => AdminUserPhotoCameraScreen(lang: _lang, isEdit: false),
      ),
    );
    AdminUserPhotoCameraWarmupService.instance.warmUp();

    if (picked == null) return;

    setState(() => isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final safeExt = ext == 'png' ? 'png' : 'jpg';
      final fileName =
          'new-user-${DateTime.now().millisecondsSinceEpoch}.$safeExt';

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

      if (mounted) setState(() => gambarUserUrl = url);
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      if (mounted) _showErrorPopup('Error: $e');
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

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
          widget.onUserAdded();
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
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D72F3),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, IconData icon, {bool required = false}) {
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
        if (required)
          Text(
            ' *',
            style: GoogleFonts.poppins(
              color: const Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildLocationPickerField({
    required String hint,
    required String? valueText,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final hasValue = enabled && valueText != null && valueText.isNotEmpty;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: !enabled
              ? Colors.grey.shade50
              : (hasValue ? color.withValues(alpha: 0.05) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !enabled
                ? Colors.grey.shade200
                : (hasValue ? color.withValues(alpha: 0.5) : const Color(0xFFCBD5E1)),
            width: hasValue ? 1.4 : 1.2,
          ),
        ),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: !enabled
                  ? Colors.grey.shade200
                  : (hasValue ? color : color.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon,
                size: 15,
                color: !enabled
                    ? Colors.grey.shade400
                    : (hasValue ? Colors.white : color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasValue ? valueText : hint,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                color: !enabled
                    ? Colors.black26
                    : (hasValue ? color : Colors.black38),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18,
              color: !enabled
                  ? Colors.grey.shade300
                  : (hasValue ? color : Colors.black26)),
        ]),
      ),
    );
  }

  Future<void> _openLocationPicker(int targetLevel) async {
    final result = await showAdminUserPickLocationDialog(
      context,
      lang: _lang,
      initial: _locationSelection,
      targetLevel: targetLevel,
    );
    if (result == null) return;
    setState(() => _locationSelection = result);
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
    TextInputType? keyboardType,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 52,
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
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.poppins(
          color: enabled ? const Color(0xFF1E3A8A) : Colors.black38,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildBagianKasiePicker() {
    const kasieColor = Color(0xFF0891B2);
    final hasValue = selectedBagianKasie != null && selectedBagianKasie!.isNotEmpty;
    return GestureDetector(
      onTap: () async {
        final result = await showKtsSectionLocationPicker(context, lang: _lang);
        if (result == null) return;
        setState(() {
          selectedBagianKasie = result.isAllSections ? null : result.sectionName;
          selectedSectionId  = result.isAllSections ? null : result.sectionId;
        });
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                  ? selectedBagianKasie!
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
          color: value ? color.withValues(alpha:0.25) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  value ? color.withValues(alpha:0.12) : Colors.grey.shade100,
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
              ? 'Add New User'
              : _lang == 'ZH'
                  ? '添加新用户'
                  : 'Tambah Pengguna Baru',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _primary,
          ),
        ),
      ),
      body: Column(
        children: [
          // SCROLLABLE BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PROFILE PHOTO
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
                      Text(
                        ' *',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: isUploadingPhoto ? null : _pickProfilePhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: _primary.withValues(alpha:0.10),
                            backgroundImage: gambarUserUrl != null
                                ? CachedNetworkImageProvider(gambarUserUrl!)
                                : null,
                            child: gambarUserUrl == null
                                ? Text(
                                    namaCtrl.text.isNotEmpty
                                        ? namaCtrl.text[0].toUpperCase()
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
                              child: isUploadingPhoto
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
                  const SizedBox(height: 20),

                  // BASIC INFORMATION
                  _buildSectionLabel(
                    _lang == 'EN'
                        ? 'Basic Information'
                        : _lang == 'ZH'
                            ? '基本信息'
                            : 'Informasi Dasar',
                    Icons.person_outline,
                    _primary,
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Full Name'
                          : _lang == 'ZH'
                              ? '姓名'
                              : 'Nama Lengkap',
                      Icons.person_outline,
                      required: true),
                  const SizedBox(height: 6),
                  _buildTextField(namaCtrl,
                      _lang == 'EN' ? 'Enter full name...' : 'Masukkan nama lengkap...'),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Email', Icons.email_outlined, required: true),
                  const SizedBox(height: 6),
                  _buildTextField(emailCtrl,
                      'email@example.com',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Phone'
                          : _lang == 'ZH'
                              ? '电话'
                              : 'Telepon',
                      Icons.phone_outlined),
                  const SizedBox(height: 6),
                  _buildTextField(
                      phoneCtrl,
                      _lang == 'EN' ? 'e.g. 08123456789' : 'cth. 08123456789',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Password'
                          : _lang == 'ZH'
                              ? '密码'
                              : 'Kata Sandi',
                      Icons.lock_outline,
                      required: true),
                  const SizedBox(height: 6),
                  _buildTextField(
                      passCtrl,
                      _lang == 'EN' ? 'Min 8 characters' : 'Minimal 8 karakter',
                      obscure: !isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: _primary,
                          size: 22,
                        ),
                        onPressed: () => setState(
                            () => isPasswordVisible = !isPasswordVisible),
                      )),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Role'
                          : _lang == 'ZH'
                              ? '角色'
                              : 'Role',
                      Icons.work_outline_rounded,
                      required: true),
                  const SizedBox(height: 6),
                  AdminRolePickerCard(
                    lang: _lang,
                    selectedRole: _selectedJabatanData,
                    onTap: () async {
                      final result = await showAdminPickRoleDialog(
                        context,
                        lang: _lang,
                        jabatanList: widget.jabatanList,
                        selectedJabatanId: selectedJabatan,
                      );
                      if (result == null) return;
                      setState(() {
                        selectedJabatan = result['id_jabatan'] as int?;
                      });
                    },
                  ),

                  // KASIE SECTION 
                  if (selectedJabatan == 3) ...[
                    const SizedBox(height: 12),
                    _buildFieldLabel(
                        _lang == 'EN'
                            ? 'Kasie Section'
                            : _lang == 'ZH'
                                ? '科长部门'
                                : 'Bagian Kasie',
                        Icons.apartment_outlined),
                    const SizedBox(height: 6),
                    _buildBagianKasiePicker(),
                  ],
                  const SizedBox(height: 20),

                  // LOCATION ASSIGNMENT
                  _buildSectionLabel(
                    _lang == 'EN'
                        ? 'Location Assignment'
                        : _lang == 'ZH'
                            ? '位置分配'
                            : 'Penempatan Lokasi',
                    Icons.map,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Location'
                          : _lang == 'ZH'
                              ? '位置'
                              : 'Lokasi',
                      Icons.location_city_rounded),
                  const SizedBox(height: 6),
                  _buildLocationPickerField(
                    hint: _lang == 'EN' ? 'Select location' : 'Pilih lokasi',
                    valueText: _locationSelection.namaLokasi,
                    icon: Icons.location_city_rounded,
                    color: const Color(0xFF10B981),
                    enabled: true,
                    onTap: () => _openLocationPicker(0),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Unit', Icons.business_rounded),
                  const SizedBox(height: 6),
                  _buildLocationPickerField(
                    hint: _lang == 'EN' ? 'Select unit' : 'Pilih unit',
                    valueText: _locationSelection.namaUnit,
                    icon: Icons.business_rounded,
                    color: _primary,
                    enabled: _locationSelection.idLokasi != null,
                    onTap: () => _openLocationPicker(1),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Sub-Unit', Icons.layers_rounded),
                  const SizedBox(height: 6),
                  _buildLocationPickerField(
                    hint: _lang == 'EN' ? 'Select sub-unit' : 'Pilih sub-unit',
                    valueText: _locationSelection.namaSubunit,
                    icon: Icons.layers_rounded,
                    color: const Color(0xFFFBBF24),
                    enabled: _locationSelection.idUnit != null,
                    onTap: () => _openLocationPicker(2),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Area', Icons.place_rounded),
                  const SizedBox(height: 6),
                  _buildLocationPickerField(
                    hint: _lang == 'EN' ? 'Select area' : 'Pilih area',
                    valueText: _locationSelection.namaArea,
                    icon: Icons.place_rounded,
                    color: const Color(0xFFF472B6),
                    enabled: _locationSelection.idSubunit != null,
                    onTap: () => _openLocationPicker(3),
                  ),
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
                  const SizedBox(height: 12),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Select Supervisor'
                          : _lang == 'ZH'
                              ? '选择主管'
                              : 'Pilih Supervisor',
                      Icons.person_search_outlined),
                  const SizedBox(height: 6),
                  AdminSupervisorPickerCard(
                    lang: _lang,
                    selectedSupervisor: _selectedSupervisorData,
                    onTap: () async {
                      final result = await showAdminPickSupervisorDialog(
                        context,
                        lang: _lang,
                        supervisorList: supervisorList,
                        selectedSupervisorId: selectedSupervisorId,
                      );
                      if (result == null) return;
                      setState(() {
                        selectedSupervisorId =
                            result.isEmpty ? null : result['id_user'] as String?;
                      });
                    },
                  ),
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
                  const SizedBox(height: 12),

                  _buildToggleRow(
                    _lang == 'EN'
                        ? 'Visitor Mode'
                        : _lang == 'ZH'
                            ? '访客模式'
                            : 'Mode Pengunjung',
                    Icons.visibility_outlined,
                    isVisitor,
                    (v) => setState(() => isVisitor = v),
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
                    isVerificator,
                    (v) => setState(() => isVerificator = v),
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // STICKY FOOTER
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
            child: isSaving
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _lang == 'EN'
                                ? 'Cancel'
                                : _lang == 'ZH'
                                    ? '取消'
                                    : 'Batal',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saveUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            shadowColor: _primary.withValues(alpha:0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _lang == 'EN'
                                    ? 'Save & Register'
                                    : _lang == 'ZH'
                                        ? '保存并注册'
                                        : 'Simpan & Daftar',
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
}