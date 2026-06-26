import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_service.dart';
import '../shared/admin_image_picker_widget.dart';

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

  int? _selectedJabatan;
  bool _isVisitor = false;
  bool _isVerificator = false;
  String? _gambarUserUrl;
  String? _selectedLokasiId;
  String? _selectedUnitId;
  String? _selectedSubunitId;
  String? _selectedAreaId;
  String? _selectedSupervisorId;
  String? _selectedBagianKasie;

  List<Map<String, dynamic>> _lokasiList = [];
  List<Map<String, dynamic>> _unitList = [];
  List<Map<String, dynamic>> _subunitList = [];
  List<Map<String, dynamic>> _areaList = [];
  List<Map<String, dynamic>> _supervisorList = [];

  String get _lang => widget.lang;

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
    _selectedLokasiId = u['id_lokasi'] as String?;
    _selectedUnitId = u['id_unit'] as String?;
    _selectedSubunitId = u['id_subunit'] as String?;
    _selectedAreaId = u['id_area'] as String?;
    _selectedSupervisorId = u['id_supervisor'] as String?;
    final bagian = (u['bagian_kasie'] as String?)?.trim();
    _selectedBagianKasie = (bagian == null || bagian.isEmpty) ? null : bagian;

    _loadInitialData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      Supabase.instance.client
          .from('lokasi')
          .select('id_lokasi, nama_lokasi')
          .order('nama_lokasi'),
      Supabase.instance.client
          .from('User')
          .select('id_user, nama')
          .inFilter('id_jabatan', [2, 3])
          .order('nama'),
    ]);

    final lokasiData = List<Map<String, dynamic>>.from(results[0] as List);
    final supervisorData = List<Map<String, dynamic>>.from(results[1] as List);

    if (!mounted) return;
    setState(() {
      _lokasiList = lokasiData;
      _supervisorList = supervisorData;
    });

    if (_selectedLokasiId != null) {
      await _loadUnit(_selectedLokasiId!, restoreUnit: _selectedUnitId);
    }
  }

  Future<void> _loadUnit(String lokasiId, {String? restoreUnit}) async {
    final res = await Supabase.instance.client
        .from('unit')
        .select('id_unit, nama_unit')
        .eq('id_lokasi', lokasiId)
        .order('nama_unit');
    if (!mounted) return;
    setState(() {
      _unitList = List<Map<String, dynamic>>.from(res);
      if (restoreUnit == null) {
        _selectedUnitId = null;
        _selectedSubunitId = null;
        _selectedAreaId = null;
        _subunitList = [];
        _areaList = [];
      }
    });
    if (restoreUnit != null && _unitList.any((u) => u['id_unit']?.toString() == restoreUnit)) {
      setState(() => _selectedUnitId = restoreUnit);
      await _loadSubunit(restoreUnit, restoreSubunit: _selectedSubunitId);
    }
  }

  Future<void> _loadSubunit(String unitId, {String? restoreSubunit}) async {
    final res = await Supabase.instance.client
        .from('subunit')
        .select('id_subunit, nama_subunit')
        .eq('id_unit', unitId)
        .order('nama_subunit');
    if (!mounted) return;
    setState(() {
      _subunitList = List<Map<String, dynamic>>.from(res);
      if (restoreSubunit == null) {
        _selectedSubunitId = null;
        _selectedAreaId = null;
        _areaList = [];
      }
    });
    if (restoreSubunit != null && _subunitList.any((s) => s['id_subunit']?.toString() == restoreSubunit)) {
      setState(() => _selectedSubunitId = restoreSubunit);
      await _loadArea(restoreSubunit, restoreArea: _selectedAreaId);
    }
  }

  Future<void> _loadArea(String subunitId, {String? restoreArea}) async {
    final res = await Supabase.instance.client
        .from('area')
        .select('id_area, nama_area')
        .eq('id_subunit', subunitId)
        .order('nama_area');
    if (!mounted) return;
    setState(() {
      _areaList = List<Map<String, dynamic>>.from(res);
      if (restoreArea == null) {
        _selectedAreaId = null;
      }
    });
    if (restoreArea != null && _areaList.any((a) => a['id_area']?.toString() == restoreArea)) {
      setState(() => _selectedAreaId = restoreArea);
    }
  }

  Future<void> _save() async {
    final nama = _namaCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final userId = widget.user['id_user'] as String?;

    if (nama.isEmpty || email.isEmpty) {
      _showSnack(
        _lang == 'EN'
            ? 'Name and email are required!'
            : _lang == 'ZH'
                ? '姓名和邮箱为必填项！'
                : 'Nama dan email wajib diisi!',
        isError: true,
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
        'id_lokasi': _selectedLokasiId,
        'id_unit': _selectedUnitId,
        'id_subunit': _selectedSubunitId,
        'id_area': _selectedAreaId,
        'id_supervisor': _selectedSupervisorId,
        'bagian_kasie': _selectedJabatan == 3 ? _selectedBagianKasie : null,
      };

      if (pass.isNotEmpty) {
        if (pass.length < 6) {
          _showSnack(
            _lang == 'EN'
                ? 'Password must be at least 6 characters'
                : _lang == 'ZH'
                    ? '密码至少需要6个字符'
                    : 'Password minimal 6 karakter',
            isError: true,
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

      _showSnack(
        _lang == 'EN'
            ? 'User updated successfully!'
            : _lang == 'ZH'
                ? '用户更新成功！'
                : 'Pengguna berhasil diperbarui!',
      );

      widget.onUserUpdated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
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
            fontSize: 16,
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
                  _buildLabel(
                    _lang == 'EN'
                        ? 'Profile Photo'
                        : _lang == 'ZH'
                            ? '头像'
                            : 'Foto Profil',
                  ),
                  const SizedBox(height: 12),
                  AdminImagePickerWidget(
                    currentImageUrl: _gambarUserUrl,
                    storageBucket: 'avatars',
                    storageFolder: 'user',
                    filePrefix: widget.user['id_user'] ?? 'edit-user',
                    height: 56,
                    isCircle: true,
                    placeholder: Text(
                      _namaCtrl.text.isNotEmpty
                          ? _namaCtrl.text[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    onUploaded: (url) => setState(() => _gambarUserUrl = url),
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

                  _buildLabel(
                    _lang == 'EN'
                        ? 'Full Name'
                        : _lang == 'ZH'
                            ? '姓名'
                            : 'Nama Lengkap',
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _namaCtrl,
                    Icons.person_outline,
                    _lang == 'EN'
                        ? 'Enter full name...'
                        : 'Masukkan nama lengkap...',
                  ),
                  const SizedBox(height: 14),

                  _buildLabel('Email'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _emailCtrl,
                    Icons.email_outlined,
                    'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                  ),
                  const SizedBox(height: 14),

                  _buildLabel(
                    _lang == 'EN'
                        ? 'Phone'
                        : _lang == 'ZH'
                            ? '电话'
                            : 'Telepon',
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _phoneCtrl,
                    Icons.phone_outlined,
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
                                  ? const Color(0xFFF59E0B).withOpacity(0.12)
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
                      Icons.lock_outline,
                      _lang == 'EN'
                          ? 'New password (min 6 characters)'
                          : _lang == 'ZH'
                              ? '新密码（最少6个字符）'
                              : 'Password baru (minimal 6 karakter)',
                      obscure: true,
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

                  _buildLabel(
                    _lang == 'EN'
                        ? 'Job Title'
                        : _lang == 'ZH'
                            ? '职位'
                            : 'Jabatan',
                  ),
                  const SizedBox(height: 6),
                  _buildJabatanDropdown(),
                  const SizedBox(height: 14),

                  // KASIE SECTION
                  if (_selectedJabatan == 3) ...[
                    _buildLabel(
                      _lang == 'EN'
                          ? 'Kasie Section'
                          : _lang == 'ZH'
                              ? '科长部门'
                              : 'Bagian Kasie',
                    ),
                    const SizedBox(height: 6),
                    _buildBagianKasieDropdown(),
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
                    Icons.location_on_outlined,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),

                  _buildLabel(
                    _lang == 'EN' ? 'Location' : _lang == 'ZH' ? '位置' : 'Lokasi',
                  ),
                  const SizedBox(height: 6),
                  _buildLocationDropdown(
                    items: _lokasiList,
                    idKey: 'id_lokasi',
                    nameKey: 'nama_lokasi',
                    selectedId: _selectedLokasiId,
                    hint: _lang == 'EN' ? 'Select location' : 'Pilih lokasi',
                    onChanged: (v) {
                      setState(() => _selectedLokasiId = v);
                      if (v != null) _loadUnit(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Unit'),
                  const SizedBox(height: 6),
                  _buildLocationDropdown(
                    items: _unitList,
                    idKey: 'id_unit',
                    nameKey: 'nama_unit',
                    selectedId: _selectedUnitId,
                    hint: _lang == 'EN' ? 'Select unit' : 'Pilih unit',
                    enabled: _selectedLokasiId != null && _unitList.isNotEmpty,
                    onChanged: (v) {
                      setState(() => _selectedUnitId = v);
                      if (v != null) _loadSubunit(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Sub-Unit'),
                  const SizedBox(height: 6),
                  _buildLocationDropdown(
                    items: _subunitList,
                    idKey: 'id_subunit',
                    nameKey: 'nama_subunit',
                    selectedId: _selectedSubunitId,
                    hint: _lang == 'EN' ? 'Select sub-unit' : 'Pilih sub-unit',
                    enabled: _selectedUnitId != null && _subunitList.isNotEmpty,
                    onChanged: (v) {
                      setState(() => _selectedSubunitId = v);
                      if (v != null) _loadArea(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Area'),
                  const SizedBox(height: 6),
                  _buildLocationDropdown(
                    items: _areaList,
                    idKey: 'id_area',
                    nameKey: 'nama_area',
                    selectedId: _selectedAreaId,
                    hint: _lang == 'EN' ? 'Select area' : 'Pilih area',
                    enabled: _selectedSubunitId != null && _areaList.isNotEmpty,
                    onChanged: (v) => setState(() => _selectedAreaId = v),
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

                  _buildLabel(
                    _lang == 'EN'
                        ? 'Select Supervisor'
                        : _lang == 'ZH'
                            ? '选择主管'
                            : 'Pilih Supervisor',
                  ),
                  const SizedBox(height: 6),
                  _buildSupervisorDropdown(),
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
                  color: Colors.black.withOpacity(0.06),
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
                            shadowColor: _primary.withOpacity(0.3),
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
            color: color.withOpacity(0.10),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: Colors.black54,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(color: Colors.grey.shade100, thickness: 1.5);

  Widget _buildTextField(
    TextEditingController ctrl,
    IconData icon,
    String hint, {
    bool obscure = false,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: enabled ? Colors.grey.shade200 : Colors.grey.shade100),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: enabled,
        style: GoogleFonts.poppins(
          color: enabled ? const Color(0xFF1E3A8A) : Colors.black38,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(color: Colors.black26, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.black38, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildJabatanDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedJabatan,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black45),
          hint: Text(
            _lang == 'EN'
                ? 'Select job title'
                : _lang == 'ZH'
                    ? '请选择职位'
                    : 'Pilih jabatan',
            style: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
          ),
          items: widget.jabatanList.map((j) {
            return DropdownMenuItem<int>(
              value: j['id_jabatan'] as int,
              child: Text(
                j['nama_jabatan'],
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedJabatan = v),
        ),
      ),
    );
  }

  Widget _buildBagianKasieDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedBagianKasie,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black45),
          hint: Text(
            _lang == 'EN'
                ? 'Select section'
                : _lang == 'ZH'
                    ? '选择部门'
                    : 'Pilih bagian',
            style: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                _lang == 'EN'
                    ? '— No section —'
                    : _lang == 'ZH'
                        ? '— 无部门 —'
                        : '— Tanpa bagian —',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 13),
              ),
            ),
            ...const [
              'Laser','Mesin','Spot','Las','Ftw','Cat','Assy',
              'Ekspedisi & Packing','Purchasing','Engineering','PPIC'
            ].map((b) => DropdownMenuItem<String?>(
                  value: b,
                  child: Text(b,
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A), fontSize: 13)),
                )),
          ],
          onChanged: (v) => setState(() => _selectedBagianKasie = v),
        ),
      ),
    );
  }

  Widget _buildLocationDropdown({
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required String? selectedId,
    required String hint,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: enabled ? Colors.grey.shade200 : Colors.grey.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => e[idKey]?.toString() == selectedId)
              ? selectedId
              : null,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: enabled ? Colors.black45 : Colors.grey.shade300),
          hint: Text(hint,
              style:
                  GoogleFonts.poppins(color: Colors.black38, fontSize: 13)),
          items: enabled
              ? items
                  .map((item) => DropdownMenuItem<String>(
                        value: item[idKey] as String,
                        child: Text(
                          item[nameKey] ?? '-',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1E3A8A), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList()
              : [],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  Widget _buildSupervisorDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _supervisorList.any(
                  (e) => e['id_user'] == _selectedSupervisorId)
              ? _selectedSupervisorId
              : null,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black45),
          hint: Text(
            _lang == 'EN'
                ? 'Select supervisor (optional)'
                : _lang == 'ZH'
                    ? '选择主管（可选）'
                    : 'Pilih supervisor (opsional)',
            style: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                _lang == 'EN'
                    ? '— No supervisor —'
                    : _lang == 'ZH'
                        ? '— 无主管 —'
                        : '— Tanpa supervisor —',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 13),
              ),
            ),
            ..._supervisorList.map((s) => DropdownMenuItem<String>(
                  value: s['id_user'] as String,
                  child: Text(
                    s['nama'] ?? '-',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF1E3A8A), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (v) => setState(() => _selectedSupervisorId = v),
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
        color: value ? color.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: value ? color.withOpacity(0.25) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: value ? color.withOpacity(0.12) : Colors.grey.shade100,
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
            activeTrackColor: color.withOpacity(0.25),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}