import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/auth_service.dart'; // ← sesuaikan path

class AdminUserScreen extends StatefulWidget {
  final String lang;
  const AdminUserScreen({super.key, required this.lang});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _jabatanList = [];
  bool _isLoading = true;
  String _search = '';

  static const _primary = Color(0xFF6366F1);
  static const _bg = Color(0xFFF8FAFC);

  final AuthService _auth = AuthService();

  String get _langCode => widget.lang;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('User')
            .select(
              'id_user, nama, email, poin, gambar_user, is_visitor, '
              'is_verificator, id_jabatan, jabatan(nama_jabatan), '
              'lokasi!fk_user_lokasi(nama_lokasi)',
            )
            .order('nama'),
        Supabase.instance.client
            .from('jabatan')
            .select('id_jabatan, nama_jabatan')
            .order('id_jabatan'),
      ]);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(results[0] as List);
          _jabatanList =
              List<Map<String, dynamic>>.from(results[1] as List);
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_users)
        : _users.where((u) {
            return (u['nama'] ?? '').toLowerCase().contains(q) ||
                (u['email'] ?? '').toLowerCase().contains(q);
          }).toList();
  }

  // ─── DIALOG: Tambah / Edit User ───
  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final namaCtrl =
        TextEditingController(text: user?['nama'] ?? '');
    final emailCtrl =
        TextEditingController(text: user?['email'] ?? '');
    final passCtrl = TextEditingController();
    int? selectedJabatan = user?['id_jabatan'] as int?;
    bool isVisitor = user?['is_visitor'] == true;
    bool isVerificator = user?['is_verificator'] == true;
    bool isSavingDialog = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_rounded
                            : Icons.person_add_rounded,
                        color: _primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit
                            ? (_langCode == 'EN'
                                ? 'Edit User'
                                : 'Edit Pengguna')
                            : (_langCode == 'EN'
                                ? 'Add New User'
                                : 'Tambah Pengguna Baru'),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildDivider(),
                const SizedBox(height: 20),

                // ── Nama ──
                _buildDlgLabel(
                    _langCode == 'EN' ? 'Full Name' : 'Nama Lengkap'),
                const SizedBox(height: 6),
                _buildDlgTextField(
                  namaCtrl,
                  Icons.person_outline,
                  _langCode == 'EN'
                      ? 'Enter full name...'
                      : 'Masukkan nama lengkap...',
                ),
                const SizedBox(height: 16),

                // ── Email ──
                _buildDlgLabel('Email'),
                const SizedBox(height: 6),
                _buildDlgTextField(
                  emailCtrl,
                  Icons.email_outlined,
                  'email@example.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isEdit,
                ),
                const SizedBox(height: 16),

                // ── Password (hanya saat tambah) ──
                if (!isEdit) ...[
                  _buildDlgLabel(
                      _langCode == 'EN' ? 'Password' : 'Kata Sandi'),
                  const SizedBox(height: 6),
                  _buildDlgTextField(
                    passCtrl,
                    Icons.lock_outline,
                    _langCode == 'EN'
                        ? 'Min 6 characters'
                        : 'Minimal 6 karakter',
                    obscure: true,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Jabatan Dropdown ──
                _buildDlgLabel(
                    _langCode == 'EN' ? 'Job Title' : 'Jabatan'),
                const SizedBox(height: 6),
                _buildJabatanDropdown(
                  selectedJabatan: selectedJabatan,
                  onChanged: (v) =>
                      setDlg(() => selectedJabatan = v),
                ),
                const SizedBox(height: 20),

                // ── Divider ──
                _buildDivider(),
                const SizedBox(height: 16),

                // ── Toggle Visitor ──
                _buildToggleRow(
                  _langCode == 'EN'
                      ? 'Visitor Mode'
                      : 'Mode Pengunjung',
                  Icons.visibility_outlined,
                  isVisitor,
                  (v) => setDlg(() => isVisitor = v),
                  const Color(0xFF0891B2),
                ),
                const SizedBox(height: 10),

                // ── Toggle Verificator ──
                _buildToggleRow(
                  _langCode == 'EN' ? 'Verificator' : 'Verifikator',
                  Icons.verified_user_outlined,
                  isVerificator,
                  (v) => setDlg(() => isVerificator = v),
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 24),

                // ── Action Buttons ──
                if (isSavingDialog)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(
                          color: _primary),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.shade300),
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: Text(
                              _langCode == 'EN'
                                  ? 'Cancel'
                                  : 'Batal',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            setDlg(() => isSavingDialog = true);
                            await _saveUser(
                              isEdit: isEdit,
                              userId: user?['id_user'],
                              nama: namaCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              pass: passCtrl.text.trim(),
                              idJabatan: selectedJabatan,
                              isVisitor: isVisitor,
                              isVerificator: isVerificator,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            elevation: 2,
                            shadowColor:
                                _primary.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEdit
                                    ? Icons.save_rounded
                                    : Icons.person_add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEdit
                                    ? (_langCode == 'EN'
                                        ? 'Update'
                                        : 'Perbarui')
                                    : (_langCode == 'EN'
                                        ? 'Save & Register'
                                        : 'Simpan & Daftar'),
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveUser({
    required bool isEdit,
    String? userId,
    required String nama,
    required String email,
    required String pass,
    int? idJabatan,
    required bool isVisitor,
    required bool isVerificator,
  }) async {
    if (nama.isEmpty || email.isEmpty) {
      _showSnack(
          _langCode == 'EN'
              ? 'Name and email are required!'
              : 'Nama dan email wajib diisi!',
          isError: true);
      return;
    }

    try {
      if (isEdit && userId != null) {
        // ── Update user yang sudah ada ──
        await Supabase.instance.client.from('User').update({
          'nama': nama,
          'id_jabatan': idJabatan,
          'is_visitor': isVisitor,
          'is_verificator': isVerificator,
        }).eq('id_user', userId);

        _showSnack(_langCode == 'EN'
            ? 'User updated successfully!'
            : 'Pengguna berhasil diperbarui!');
      } else {
        // ── Registrasi user baru (sama persis seperti login_screen.dart) ──
        if (pass.isEmpty) {
          _showSnack(
              _langCode == 'EN'
                  ? 'Password is required!'
                  : 'Password wajib diisi!',
              isError: true);
          return;
        }
        if (pass.length < 6) {
          _showSnack(
              _langCode == 'EN'
                  ? 'Password must be at least 6 characters'
                  : 'Password minimal 6 karakter',
              isError: true);
          return;
        }

        // 1. Hash password dengan Argon2 (sama seperti login_screen.dart)
        final hashedPass =
            await _auth.hashPassword(email, pass);

        // 2. Daftar ke Supabase Auth
        final res =
            await _auth.signUpWithEmail(email, hashedPass);

        if (res == null || res.user == null) {
          _showSnack(
              _langCode == 'EN'
                  ? 'Registration failed. Please try again.'
                  : 'Pendaftaran gagal. Silakan coba lagi.',
              isError: true);
          return;
        }

        // 3. Insert ke tabel User (sama seperti login_screen.dart)
        await Supabase.instance.client.from('User').insert({
          'id_user': res.user!.id,
          'nama': nama,
          'email': email,
          'pass': hashedPass,
          'id_jabatan': idJabatan ?? 4, // default Staff
          'poin': 0,
          'is_visitor': isVisitor,
          'is_verificator': isVerificator,
          'timestamp': DateTime.now().toIso8601String(),
        });

        _showSnack(_langCode == 'EN'
            ? 'User registered successfully!'
            : 'Pengguna berhasil didaftarkan!');
      }

      _loadData();
    } on AuthException catch (e) {
      _showSnack('Auth Error: ${e.message}', isError: true);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteUser(String userId, String nama) async {
    final ok = await _confirmDelete(nama);
    if (!ok) return;
    try {
      await Supabase.instance.client
          .from('User')
          .delete()
          .eq('id_user', userId);
      _showSnack(_langCode == 'EN'
          ? 'User deleted.'
          : 'Pengguna dihapus.');
      _loadData();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        title: Text(
          _langCode == 'EN'
              ? 'User Management'
              : 'Kelola Pengguna',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: _primary),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _buildSearchField(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        backgroundColor: _primary,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded,
            color: Colors.white),
        label: Text(
          _langCode == 'EN' ? 'Add User' : 'Tambah',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : _filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _primary,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _buildUserCard(_filtered[i]),
                  ),
                ),
    );
  }

  // ══════════════════════════════════════
  // WIDGET HELPERS
  // ══════════════════════════════════════

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        onChanged: (v) => setState(() {
          _search = v;
          _applyFilter();
        }),
        style: GoogleFonts.poppins(
            color: const Color(0xFF1E3A8A), fontSize: 14),
        decoration: InputDecoration(
          hintText: _langCode == 'EN'
              ? 'Search by name or email...'
              : 'Cari nama atau email...',
          hintStyle: GoogleFonts.poppins(
              color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(Icons.search,
              color: Colors.black38, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final jabatan = user['jabatan']?['nama_jabatan'] ?? '-';
    final isVerif = user['is_verificator'] == true;
    final isVisitor = user['is_visitor'] == true;
    final avatarUrl = user['gambar_user'] as String?;
    final name = user['nama'] ?? '';
    final email = user['email'] ?? '';
    final poin = user['poin'] ?? 0;

    // Warna berdasarkan jabatan
    Color roleColor = const Color(0xFF6366F1);
    final idJabatan = user['id_jabatan'];
    if (idJabatan == 1) roleColor = const Color(0xFFDC2626); // Eksekutif
    if (idJabatan == 2) roleColor = const Color(0xFF7C3AED); // Manager
    if (idJabatan == 3) roleColor = const Color(0xFF0891B2); // Kasie
    if (idJabatan == 6) roleColor = const Color(0xFF059669); // Admin

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ──
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: roleColor.withOpacity(0.12),
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              // Badge poin kecil
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '$poin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                      color: Colors.black38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    _buildChip(jabatan, roleColor,
                        Icons.work_outline),
                    if (isVisitor)
                      _buildChip(
                        _langCode == 'EN'
                            ? 'Visitor'
                            : 'Pengunjung',
                        const Color(0xFF0891B2),
                        Icons.visibility_outlined,
                      ),
                    if (isVerif)
                      _buildChip(
                        _langCode == 'EN'
                            ? 'Verificator'
                            : 'Verifikator',
                        const Color(0xFFF59E0B),
                        Icons.verified_user_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action Buttons ──
          Column(
            children: [
              _buildIconBtn(
                Icons.edit_outlined,
                const Color(0xFF6366F1),
                () => _showUserDialog(user: user),
              ),
              const SizedBox(height: 8),
              _buildIconBtn(
                Icons.delete_outline_rounded,
                const Color(0xFFEF4444),
                () => _deleteUser(user['id_user'], name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline,
                size: 56, color: _primary.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            _langCode == 'EN'
                ? 'No users found'
                : 'Tidak ada pengguna',
            style: GoogleFonts.poppins(
              color: Colors.black38,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialog Helpers ──

  Widget _buildDivider() => Divider(
        color: Colors.grey.shade100,
        thickness: 1.5,
      );

  Widget _buildDlgLabel(String label) {
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

  Widget _buildDlgTextField(
    TextEditingController ctrl,
    IconData icon,
    String hint, {
    bool obscure = false,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFFF8FAFC)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: enabled
                ? Colors.grey.shade200
                : Colors.grey.shade100),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: enabled,
        style: GoogleFonts.poppins(
          color: enabled
              ? const Color(0xFF1E3A8A)
              : Colors.black38,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              color: Colors.black26, fontSize: 13),
          prefixIcon:
              Icon(icon, color: Colors.black38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildJabatanDropdown({
    required int? selectedJabatan,
    required ValueChanged<int?> onChanged,
  }) {
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
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black45),
          hint: Text(
            _langCode == 'EN'
                ? 'Select job title'
                : 'Pilih jabatan',
            style: GoogleFonts.poppins(
                color: Colors.black38, fontSize: 13),
          ),
          items: _jabatanList.map((j) {
            return DropdownMenuItem<int>(
              value: j['id_jabatan'] as int,
              child: Text(
                j['nama_jabatan'],
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A),
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          style: GoogleFonts.poppins(
              color: const Color(0xFF1E3A8A)),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              value ? color.withOpacity(0.25) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: value
                  ? color.withOpacity(0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: value ? color : Colors.grey.shade400,
                size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: value
                    ? const Color(0xFF1E3A8A)
                    : Colors.black45,
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

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              _langCode == 'EN'
                  ? 'Delete User?'
                  : 'Hapus Pengguna?',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              '${_langCode == 'EN' ? 'Are you sure to delete' : 'Yakin menghapus'} "$name"?',
              style: GoogleFonts.poppins(
                  color: Colors.black54, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                    _langCode == 'EN' ? 'Cancel' : 'Batal',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                    _langCode == 'EN' ? 'Delete' : 'Hapus',
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
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
            child: Text(msg,
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}