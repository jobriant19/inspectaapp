import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../shared/admin_image_picker_widget.dart';

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
  String? gambarUserUrl;
  String? selectedLokasiId;
  String? selectedUnitId;
  String? selectedSubunitId;
  String? selectedAreaId;
  String? selectedSupervisorId;
  String? selectedBagianKasie;

  List<Map<String, dynamic>> lokasiList = [];
  List<Map<String, dynamic>> unitList = [];
  List<Map<String, dynamic>> subunitList = [];
  List<Map<String, dynamic>> areaList = [];
  List<Map<String, dynamic>> supervisorList = [];

  String get _lang => widget.lang;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    phoneCtrl.dispose();
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
          .select('id_user, nama')
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
    if (pass.isEmpty) {
      _showSnack(
        _lang == 'EN'
            ? 'Password is required!'
            : _lang == 'ZH'
                ? '密码为必填项！'
                : 'Password wajib diisi!',
        isError: true,
      );
      return;
    }
    if (pass.length < 6) {
      _showSnack(
        _lang == 'EN'
            ? 'Password must be at least 6 characters'
            : _lang == 'ZH'
                ? '密码至少需要6个字符'
                : 'Password minimal 6 karakter',
        isError: true,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final res = await _auth.signUpWithEmail(email, pass);
      if (res == null || res.user == null) {
        _showSnack(
          _lang == 'EN'
              ? 'Registration failed. Please try again.'
              : _lang == 'ZH'
                  ? '注册失败，请重试。'
                  : 'Pendaftaran gagal. Silakan coba lagi.',
          isError: true,
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
      });

      _showSnack(
        _lang == 'EN'
            ? 'User registered successfully!'
            : _lang == 'ZH'
                ? '用户注册成功！'
                : 'Pengguna berhasil didaftarkan!',
      );

      widget.onUserAdded();
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      _showSnack('Auth Error: ${e.message}', isError: true);
      setState(() => isSaving = false);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
      setState(() => isSaving = false);
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
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
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
          value: selectedJabatan,
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
          onChanged: (v) => setState(() => selectedJabatan = v),
        ),
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
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                enabled ? Colors.grey.shade200 : Colors.grey.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.any(
                  (e) => e[idKey]?.toString() == selectedId?.toString())
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
              ? items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item[idKey] as T,
                    child: Text(
                      item[nameKey] ?? '-',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A), fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            fontSize: 16,
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
                  _buildLabel(_lang == 'EN'
                      ? 'Profile Photo'
                      : _lang == 'ZH'
                          ? '头像'
                          : 'Foto Profil'),
                  const SizedBox(height: 12),
                  AdminImagePickerWidget(
                    currentImageUrl: gambarUserUrl,
                    storageBucket: 'avatars',
                    storageFolder: 'user',
                    filePrefix: 'new-user',
                    height: 56,
                    isCircle: true,
                    placeholder: Text(
                      namaCtrl.text.isNotEmpty
                          ? namaCtrl.text[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    onUploaded: (url) =>
                        setState(() => gambarUserUrl = url),
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

                  _buildLabel(_lang == 'EN'
                      ? 'Full Name'
                      : _lang == 'ZH'
                          ? '姓名'
                          : 'Nama Lengkap'),
                  const SizedBox(height: 6),
                  _buildTextField(namaCtrl, Icons.person_outline,
                      _lang == 'EN' ? 'Enter full name...' : 'Masukkan nama lengkap...'),
                  const SizedBox(height: 14),

                  _buildLabel('Email'),
                  const SizedBox(height: 6),
                  _buildTextField(emailCtrl, Icons.email_outlined,
                      'email@example.com',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),

                  _buildLabel(_lang == 'EN'
                      ? 'Phone'
                      : _lang == 'ZH'
                          ? '电话'
                          : 'Telepon'),
                  const SizedBox(height: 6),
                  _buildTextField(
                      phoneCtrl, Icons.phone_outlined,
                      _lang == 'EN' ? 'e.g. 08123456789' : 'cth. 08123456789',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),

                  _buildLabel(_lang == 'EN'
                      ? 'Password'
                      : _lang == 'ZH'
                          ? '密码'
                          : 'Kata Sandi'),
                  const SizedBox(height: 6),
                  _buildTextField(
                      passCtrl, Icons.lock_outline,
                      _lang == 'EN' ? 'Min 6 characters' : 'Minimal 6 karakter',
                      obscure: true),
                  const SizedBox(height: 14),

                  _buildLabel(_lang == 'EN'
                      ? 'Job Title'
                      : _lang == 'ZH'
                          ? '职位'
                          : 'Jabatan'),
                  const SizedBox(height: 6),
                  _buildJabatanDropdown(),

                  // KASIE SECTION 
                  if (selectedJabatan == 3) ...[
                    const SizedBox(height: 14),
                    _buildLabel(_lang == 'EN'
                        ? 'Kasie Section'
                        : _lang == 'ZH'
                            ? '科长部门'
                            : 'Bagian Kasie'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: selectedBagianKasie,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.black45),
                          hint: Text(
                            _lang == 'EN'
                                ? 'Select section'
                                : _lang == 'ZH'
                                    ? '选择部门'
                                    : 'Pilih bagian',
                            style: GoogleFonts.poppins(
                                color: Colors.black38, fontSize: 13),
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
                              'Laser', 'Mesin', 'Spot', 'Las', 'Ftw', 'Cat',
                              'Assy', 'Ekspedisi & Packing', 'Purchasing',
                              'Engineering', 'PPIC',
                            ].map((b) => DropdownMenuItem<String?>(
                                  value: b,
                                  child: Text(b,
                                      style: GoogleFonts.poppins(
                                          color: const Color(0xFF1E3A8A),
                                          fontSize: 13)),
                                )),
                          ],
                          onChanged: (v) =>
                              setState(() => selectedBagianKasie = v),
                        ),
                      ),
                    ),
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
                    Icons.location_on_outlined,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),

                  _buildLabel(_lang == 'EN'
                      ? 'Location'
                      : _lang == 'ZH'
                          ? '位置'
                          : 'Lokasi'),
                  const SizedBox(height: 6),
                  _buildLocationDropdown<String>(
                    items: lokasiList,
                    idKey: 'id_lokasi',
                    nameKey: 'nama_lokasi',
                    selectedId: selectedLokasiId,
                    hint: _lang == 'EN' ? 'Select location' : 'Pilih lokasi',
                    onChanged: (v) {
                      setState(() => selectedLokasiId = v);
                      if (v != null) _loadUnit(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Unit'),
                  const SizedBox(height: 6),
                  _buildLocationDropdown<String>(
                    items: unitList,
                    idKey: 'id_unit',
                    nameKey: 'nama_unit',
                    selectedId: selectedUnitId,
                    hint: _lang == 'EN' ? 'Select unit' : 'Pilih unit',
                    enabled:
                        selectedLokasiId != null && unitList.isNotEmpty,
                    onChanged: (v) {
                      setState(() => selectedUnitId = v);
                      if (v != null) _loadSubunit(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Sub-Unit'),
                  const SizedBox(height: 6),
                  _buildLocationDropdown<String>(
                    items: subunitList,
                    idKey: 'id_subunit',
                    nameKey: 'nama_subunit',
                    selectedId: selectedSubunitId,
                    hint: _lang == 'EN' ? 'Select sub-unit' : 'Pilih sub-unit',
                    enabled:
                        selectedUnitId != null && subunitList.isNotEmpty,
                    onChanged: (v) {
                      setState(() => selectedSubunitId = v);
                      if (v != null) _loadArea(v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildLabel('Area'),
                  const SizedBox(height: 6),
                  _buildLocationDropdown<String>(
                    items: areaList,
                    idKey: 'id_area',
                    nameKey: 'nama_area',
                    selectedId: selectedAreaId,
                    hint: _lang == 'EN' ? 'Select area' : 'Pilih area',
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

                  _buildLabel(_lang == 'EN'
                      ? 'Select Supervisor'
                      : _lang == 'ZH'
                          ? '选择主管'
                          : 'Pilih Supervisor'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: supervisorList.any(
                                (e) => e['id_user'] == selectedSupervisorId)
                            ? selectedSupervisorId
                            : null,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.black45),
                        hint: Text(
                          _lang == 'EN'
                              ? 'Select supervisor (optional)'
                              : _lang == 'ZH'
                                  ? '选择主管（可选）'
                                  : 'Pilih supervisor (opsional)',
                          style: GoogleFonts.poppins(
                              color: Colors.black38, fontSize: 13),
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
                          ...supervisorList.map(
                            (s) => DropdownMenuItem<String>(
                              value: s['id_user'] as String,
                              child: Text(
                                s['nama'] ?? '-',
                                style: GoogleFonts.poppins(
                                    color: const Color(0xFF1E3A8A),
                                    fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedSupervisorId = v),
                      ),
                    ),
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