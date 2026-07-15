import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/auth_service.dart';
import '../../user/analytics/kts production/kts_section_location_picker.dart';
import 'camera/admin_user_camera.dart';
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
  String? selectedLokasiId;
  String? selectedUnitId;
  String? selectedSubunitId;
  String? selectedAreaId;
  String? selectedSupervisorId;
  String? selectedBagianKasie;
  String? selectedSectionId;

  List<Map<String, dynamic>> lokasiList = [];
  List<Map<String, dynamic>> unitList = [];
  List<Map<String, dynamic>> subunitList = [];
  List<Map<String, dynamic>> areaList = [];
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
    final results = await Future.wait([
      Supabase.instance.client
          .from('lokasi')
          .select('id_lokasi, nama_lokasi')
          .order('nama_lokasi'),
      Supabase.instance.client
          .from('User')
          .select(
            'id_user, nama, gambar_user, id_jabatan, is_verificator, '
            'jabatan!User_id_jabatan_fkey(nama_jabatan)',
          )
          .inFilter('id_jabatan', [2, 3])
          .order('nama'),
    ]);
    if (mounted) {
      setState(() {
        lokasiList = List<Map<String, dynamic>>.from(results[0] as List);
        supervisorList = List<Map<String, dynamic>>.from(results[1] as List);
      });
    }
  }

  Future<void> _loadUnit(String lokasiId) async {
    final res = await Supabase.instance.client
        .from('unit')
        .select('id_unit, nama_unit')
        .eq('id_lokasi', lokasiId)
        .order('nama_unit');
    if (mounted) {
      setState(() {
        unitList = List<Map<String, dynamic>>.from(res);
        subunitList = [];
        areaList = [];
        selectedUnitId = null;
        selectedSubunitId = null;
        selectedAreaId = null;
      });
    }
  }

  Future<void> _loadSubunit(String unitId) async {
    final res = await Supabase.instance.client
        .from('subunit')
        .select('id_subunit, nama_subunit')
        .eq('id_unit', unitId)
        .order('nama_subunit');
    if (mounted) {
      setState(() {
        subunitList = List<Map<String, dynamic>>.from(res);
        areaList = [];
        selectedSubunitId = null;
        selectedAreaId = null;
      });
    }
  }

  Future<void> _loadArea(String subunitId) async {
    final res = await Supabase.instance.client
        .from('area')
        .select('id_area, nama_area')
        .eq('id_subunit', subunitId)
        .order('nama_area');
    if (mounted) {
      setState(() {
        areaList = List<Map<String, dynamic>>.from(res);
        selectedAreaId = null;
      });
    }
  }

  Future<void> _saveUser() async {
    final nama = namaCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

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
    if (pass.isEmpty) {
      _showErrorPopup(
        _lang == 'EN'
            ? 'Password is required!'
            : _lang == 'ZH'
                ? '密码为必填项！'
                : 'Password wajib diisi!',
      );
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
        'id_lokasi': selectedLokasiId,
        'id_unit': selectedUnitId,
        'id_subunit': selectedSubunitId,
        'id_area': selectedAreaId,
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

  Widget _buildLocationDropdown<T>({
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required T? selectedId,
    required String hint,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    required Color color,
    bool enabled = true,
  }) {
    final hasValue = enabled &&
        items.any((e) => e[idKey]?.toString() == selectedId?.toString());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: !enabled
            ? Colors.grey.shade50
            : (hasValue ? color.withValues(alpha:0.05) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !enabled
              ? Colors.grey.shade100
              : (hasValue ? color.withValues(alpha:0.45) : const Color(0xFFCBD5E1)),
          width: hasValue ? 1.4 : 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: hasValue ? selectedId : null,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: !enabled ? Colors.grey.shade300 : (hasValue ? color : Colors.black45)),
          hint: Row(children: [
            Icon(icon, size: 16, color: !enabled ? Colors.grey.shade300 : Colors.black26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(hint,
                  style: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          selectedItemBuilder: enabled
              ? (ctx) => items.map((item) {
                    return Row(children: [
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(color: color.withValues(alpha:0.14), borderRadius: BorderRadius.circular(7)),
                        child: Icon(icon, size: 13, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item[nameKey] ?? '-',
                          style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]);
                  }).toList()
              : null,
          items: enabled
              ? items.map((item) {
                  final id = item[idKey] as T;
                  final isSelected = selectedId?.toString() == id.toString();
                  return DropdownMenuItem<T>(
                    value: id,
                    child: Row(children: [
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(icon, size: 13, color: isSelected ? Colors.white : color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item[nameKey] ?? '-',
                          style: GoogleFonts.poppins(
                            color: isSelected ? color : const Color(0xFF1E3A8A),
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) Icon(Icons.check_circle_rounded, size: 16, color: color),
                    ]),
                  );
                }).toList()
              : [],
          onChanged: enabled ? onChanged : null,
        ),
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

  Widget _buildDivider() => Divider(color: Colors.grey.shade100, thickness: 1.5);

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
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Full Name'
                          : _lang == 'ZH'
                              ? '姓名'
                              : 'Nama Lengkap',
                      Icons.person_outline),
                  const SizedBox(height: 6),
                  _buildTextField(namaCtrl,
                      _lang == 'EN' ? 'Enter full name...' : 'Masukkan nama lengkap...'),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Email', Icons.email_outlined),
                  const SizedBox(height: 6),
                  _buildTextField(emailCtrl,
                      'email@example.com',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),

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
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Password'
                          : _lang == 'ZH'
                              ? '密码'
                              : 'Kata Sandi',
                      Icons.lock_outline),
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
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Role'
                          : _lang == 'ZH'
                              ? '角色'
                              : 'Role',
                      Icons.work_outline_rounded),
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
                    const SizedBox(height: 14),
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
                  const SizedBox(height: 24),

                  _buildDivider(),
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
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                      _lang == 'EN'
                          ? 'Location'
                          : _lang == 'ZH'
                              ? '位置'
                              : 'Lokasi',
                      Icons.map),
                  const SizedBox(height: 6),
                  _buildLocationDropdown<String>(
                    items: lokasiList,
                    idKey: 'id_lokasi',
                    nameKey: 'nama_lokasi',
                    selectedId: selectedLokasiId,
                    hint: _lang == 'EN' ? 'Select location' : 'Pilih lokasi',
                    icon: Icons.location_on_outlined,
                    color: const Color(0xFF10B981),
                    onChanged: (v) {
                      setState(() => selectedLokasiId = v);
                      if (v != null) _loadUnit(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Unit', Icons.apartment_outlined),
                  const SizedBox(height: 6),
                  _buildLocationDropdown<String>(
                    items: unitList,
                    idKey: 'id_unit',
                    nameKey: 'nama_unit',
                    selectedId: selectedUnitId,
                    hint: _lang == 'EN' ? 'Select unit' : 'Pilih unit',
                    icon: Icons.apartment_outlined,
                    color: _primary,
                    enabled:
                        selectedLokasiId != null && unitList.isNotEmpty,
                    onChanged: (v) {
                      setState(() => selectedUnitId = v);
                      if (v != null) _loadSubunit(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Sub-Unit', Icons.layers_outlined),
                  const SizedBox(height: 6),
                  _buildLocationDropdown<String>(
                    items: subunitList,
                    idKey: 'id_subunit',
                    nameKey: 'nama_subunit',
                    selectedId: selectedSubunitId,
                    hint: _lang == 'EN' ? 'Select sub-unit' : 'Pilih sub-unit',
                    icon: Icons.layers_outlined,
                    color: const Color(0xFFFBBF24),
                    enabled:
                        selectedUnitId != null && subunitList.isNotEmpty,
                    onChanged: (v) {
                      setState(() => selectedSubunitId = v);
                      if (v != null) _loadArea(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildFieldLabel('Area', Icons.pin_drop_outlined),
                  const SizedBox(height: 6),
                  _buildLocationDropdown<String>(
                    items: areaList,
                    idKey: 'id_area',
                    nameKey: 'nama_area',
                    selectedId: selectedAreaId,
                    hint: _lang == 'EN' ? 'Select area' : 'Pilih area',
                    icon: Icons.pin_drop_outlined,
                    color: const Color(0xFFF472B6),
                    enabled:
                        selectedSubunitId != null && areaList.isNotEmpty,
                    onChanged: (v) => setState(() => selectedAreaId = v),
                  ),
                  const SizedBox(height: 24),

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
                      Icons.person_search_outlined),
                  const SizedBox(height: 6),
                  // Kartu popup pemilih supervisor (menggantikan dropdown lama).
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
                      // null -> dialog ditutup tanpa memilih apa pun, biarkan.
                      if (result == null) return;
                      setState(() {
                        // map kosong ({}) berarti user memilih "Tanpa supervisor".
                        selectedSupervisorId =
                            result.isEmpty ? null : result['id_user'] as String?;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 32),
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