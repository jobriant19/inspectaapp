import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAboutScreen extends StatefulWidget {
  final String lang;
  const AdminAboutScreen({super.key, required this.lang});

  @override
  State<AdminAboutScreen> createState() => _AdminAboutScreenState();
}

class _AdminAboutScreenState extends State<AdminAboutScreen> {
  static const _primary = Color(0xFF6366F1);
  static const _bg = Color(0xFFF8FAFC);

  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameCtrl    = TextEditingController();
  final _versionCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _versionCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('app_info')
          .select()
          .order('id')
          .limit(1)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _data = res;
          if (res != null) {
            _nameCtrl.text    = res['app_name'] ?? '';
            _versionCtrl.text = res['version'] ?? '';
            _websiteCtrl.text = res['website'] ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _versionCtrl.text.trim().isEmpty) {
      _showSnack(
        widget.lang == 'EN'
            ? 'App name and version are required!'
            : 'Nama dan versi wajib diisi!',
        isError: true,
      );
      return;
    }

    final payload = {
      'app_name': _nameCtrl.text.trim(),
      'version': _versionCtrl.text.trim(),
      'website': _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
    };

    try {
      if (_data == null) {
        // Insert baru
        await Supabase.instance.client.from('app_info').insert(payload);
      } else {
        // Update
        await Supabase.instance.client
            .from('app_info')
            .update(payload)
            .eq('id', _data!['id']);
      }
      _showSnack(
        widget.lang == 'EN' ? 'Saved successfully!' : 'Berhasil disimpan!',
      );
      setState(() => _isEditing = false);
      _load();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN' ? 'About Inspecta' : 'Tentang Inspecta',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              icon: Icon(
                _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                color: _primary,
                size: 18,
              ),
              label: Text(
                _isEditing
                    ? (widget.lang == 'EN' ? 'Cancel' : 'Batal')
                    : (widget.lang == 'EN' ? 'Edit' : 'Ubah'),
                style: GoogleFonts.poppins(
                    color: _primary, fontWeight: FontWeight.w600),
              ),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Header card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _data?['app_name'] ?? 'Inspecta',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v${_data?['version'] ?? '-'}',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        if (_data?['website'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _data!['website'],
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Form fields ──
                  _buildField(
                    label: widget.lang == 'EN' ? 'App Name' : 'Nama Aplikasi',
                    ctrl: _nameCtrl,
                    icon: Icons.apps_rounded,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: widget.lang == 'EN' ? 'Version' : 'Versi',
                    ctrl: _versionCtrl,
                    icon: Icons.tag_rounded,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Website',
                    ctrl: _websiteCtrl,
                    icon: Icons.language_rounded,
                    enabled: _isEditing,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 24),

                  // ── Tombol simpan ──
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded,
                            color: Colors.white, size: 20),
                        label: Text(
                          widget.lang == 'EN' ? 'Save Changes' : 'Simpan Perubahan',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          shadowColor: _primary.withOpacity(0.35),
                        ),
                        onPressed: _save,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF8FAFC) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? _primary.withOpacity(0.3) : Colors.grey.shade200,
              width: enabled ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              color: enabled ? const Color(0xFF1E3A8A) : Colors.black38,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon,
                  color: enabled ? _primary : Colors.black26, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              3,
              (_) => Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}