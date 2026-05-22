import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminAboutScreen extends StatefulWidget {
  final String lang;
  // Data dikirim dari AdminSettingsScreen agar tidak ada loading
  final Map<String, dynamic>? initialData;

  const AdminAboutScreen({
    super.key,
    required this.lang,
    this.initialData,
  });

  @override
  State<AdminAboutScreen> createState() => _AdminAboutScreenState();
}

class _AdminAboutScreenState extends State<AdminAboutScreen> {
  static const _primary = Color(0xFF1D72F3);
  static const _bg = Color(0xFFEFF6FF);

  Map<String, dynamic>? _data;

  // Nilai aktif yang ditampilkan dan diedit
  late String _appName;
  late String _appVersion;
  late String _appWebsite;
  late String _appTagline;
  String? _logoUrl;

  // State edit per-field
  bool _editingName    = false;
  bool _editingVersion = false;
  bool _editingWebsite = false;
  bool _editingTagline = false;
  bool _isSaving       = false;
  bool _isUploadingLogo = false;

  // Controller per-field
  final _nameCtrl    = TextEditingController();
  final _versionCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();

  // FocusNode per-field
  final _nameFocus    = FocusNode();
  final _versionFocus = FocusNode();
  final _websiteFocus = FocusNode();
  final _taglineFocus = FocusNode();

  String _t(String en, String id) => widget.lang == 'EN' ? en : id;

  @override
  void initState() {
    super.initState();
    // Langsung isi dari cache — TIDAK ada loading sama sekali
    _data       = widget.initialData;
    _appName    = widget.initialData?['app_name'] ?? 'Inspecta';
    _appVersion = widget.initialData?['version']  ?? '-';
    _appWebsite = widget.initialData?['website']  ?? '';
    _appTagline = widget.initialData?['tagline']  ?? 'Make Your Discipline day!';
    _logoUrl    = widget.initialData?['logo_url'] as String?;

    _nameCtrl.text    = _appName;
    _versionCtrl.text = _appVersion;
    _websiteCtrl.text = _appWebsite;
    _taglineCtrl.text = _appTagline;

    // Refresh diam-diam di background kalau data belum ada / perlu update
    if (widget.initialData == null) _loadSilent();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _versionCtrl.dispose();
    _websiteCtrl.dispose();
    _taglineCtrl.dispose();
    _nameFocus.dispose();
    _versionFocus.dispose();
    _websiteFocus.dispose();
    _taglineFocus.dispose();
    super.dispose();
  }

  // Refresh tanpa loading indicator — hanya update state di background
  Future<void> _loadSilent() async {
    try {
      final res = await Supabase.instance.client
          .from('app_info')
          .select()
          .order('id')
          .limit(1)
          .maybeSingle();
      if (!mounted || res == null) return;
      setState(() {
        _data       = res;
        _appName    = res['app_name'] ?? 'Inspecta';
        _appVersion = res['version']  ?? '-';
        _appWebsite = res['website']  ?? '';
        _appTagline = res['tagline']  ?? 'Make Your Discipline day!';
        _logoUrl    = res['logo_url'] as String?;
        _nameCtrl.text    = _appName;
        _versionCtrl.text = _appVersion;
        _websiteCtrl.text = _appWebsite;
        _taglineCtrl.text = _appTagline;
      });
    } catch (e) {
      debugPrint('AdminAboutScreen background load error: $e');
    }
  }

  // ── Simpan satu field ke DB ──────────────────────────────────────────────
  Future<void> _saveField({
    required String field,
    required String value,
    required VoidCallback onDone,
  }) async {
    setState(() => _isSaving = true);
    try {
      final payload = {field: value.trim().isEmpty ? null : value.trim()};
      if (_data == null) {
        // Belum ada row → insert
        final inserted = await Supabase.instance.client
            .from('app_info')
            .insert({
              'app_name': _appName,
              'version' : _appVersion,
              ...payload,
            })
            .select()
            .single();
        setState(() => _data = inserted);
      } else {
        await Supabase.instance.client
            .from('app_info')
            .update(payload)
            .eq('id', _data!['id']);
      }
      onDone();
      _showSnack(_t('Saved!', 'Tersimpan!'));
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Upload logo dari galeri ──────────────────────────────────────────────
  Future<void> _pickLogoFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();

    setState(() => _isUploadingLogo = true);
    try {
      final fileName = 'logo-${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = 'app_logo/$fileName';
      final contentType = switch (ext) {
        'png'  => 'image/png',
        'gif'  => 'image/gif',
        'webp' => 'image/webp',
        _      => 'image/jpeg',
      };

      await Supabase.instance.client.storage
          .from('avatars') // ← ganti sesuai bucket Anda
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Simpan ke DB
      if (_data != null) {
        await Supabase.instance.client
            .from('app_info')
            .update({'logo_url': publicUrl})
            .eq('id', _data!['id']);
      }

      setState(() => _logoUrl = publicUrl);
      _showSnack(_t('Logo updated!', 'Logo diperbarui!'));
    } catch (e) {
      _showSnack('Upload error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    if (_data == null) return;
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('app_info')
          .update({'logo_url': null})
          .eq('id', _data!['id']);
      setState(() => _logoUrl = null);
      _showSnack(_t('Logo removed.', 'Logo dihapus.'));
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Launch URL ───────────────────────────────────────────────────────────
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.lang == 'EN' ? 'About Inspecta' : 'Tentang Inspecta',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _primary,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        centerTitle: true,
        // Indikator simpan global
        actions: [
          if (_isSaving || _isUploadingLogo)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            // ── 1. LOGO ───────────────────────────────────────────────────
            _buildLogoSection(),
            const SizedBox(height: 16),

            // ── 2. APP NAME (editable inline) ─────────────────────────────
            _buildInlineField(
              value: _appName,
              ctrl: _nameCtrl,
              focusNode: _nameFocus,
              isEditing: _editingName,
              textStyle: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
              editStyle: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
              textAlign: TextAlign.center,
              onTapEdit: () => setState(() {
                _editingName = true;
                _nameCtrl.text = _appName;
                Future.delayed(
                  const Duration(milliseconds: 50),
                  () => _nameFocus.requestFocus(),
                );
              }),
              onSave: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                _saveField(
                  field: 'app_name',
                  value: _nameCtrl.text,
                  onDone: () => setState(() {
                    _appName    = _nameCtrl.text.trim();
                    _editingName = false;
                  }),
                );
              },
              onCancel: () => setState(() {
                _editingName  = false;
                _nameCtrl.text = _appName;
              }),
            ),
            const SizedBox(height: 4),

            // ── 3. TAGLINE (editable inline) ──────────────────────────────
            _buildInlineField(
              value: _appTagline,
              ctrl: _taglineCtrl,
              focusNode: _taglineFocus,
              isEditing: _editingTagline,
              textStyle: GoogleFonts.poppins(
                fontSize: 18,
                color: const Color(0xFF131313),
                fontWeight: FontWeight.w700,
              ),
              editStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF131313),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              onTapEdit: () => setState(() {
                _editingTagline = true;
                _taglineCtrl.text = _appTagline;
                Future.delayed(
                  const Duration(milliseconds: 50),
                  () => _taglineFocus.requestFocus(),
                );
              }),
              onSave: () {
                _saveField(
                  field: 'tagline',
                  value: _taglineCtrl.text,
                  onDone: () => setState(() {
                    _appTagline    = _taglineCtrl.text.trim().isEmpty
                        ? 'Make Your Discipline day!'
                        : _taglineCtrl.text.trim();
                    _editingTagline = false;
                  }),
                );
              },
              onCancel: () => setState(() {
                _editingTagline   = false;
                _taglineCtrl.text = _appTagline;
              }),
            ),
            const SizedBox(height: 36),

            // ── 4. VERSION CARD (editable inline) ────────────────────────
            _buildEditableCard(
              icon: Icons.info_outline_rounded,
              label: _t('App Version', 'Versi Aplikasi'),
              value: _appVersion,
              ctrl: _versionCtrl,
              focusNode: _versionFocus,
              isEditing: _editingVersion,
              onTapEdit: () => setState(() {
                _editingVersion = true;
                _versionCtrl.text = _appVersion;
                Future.delayed(
                  const Duration(milliseconds: 50),
                  () => _versionFocus.requestFocus(),
                );
              }),
              onSave: () {
                if (_versionCtrl.text.trim().isEmpty) return;
                _saveField(
                  field: 'version',
                  value: _versionCtrl.text,
                  onDone: () => setState(() {
                    _appVersion    = _versionCtrl.text.trim();
                    _editingVersion = false;
                  }),
                );
              },
              onCancel: () => setState(() {
                _editingVersion   = false;
                _versionCtrl.text = _appVersion;
              }),
            ),
            const SizedBox(height: 14),

            // ── 5. WEBSITE CARD (editable inline) ────────────────────────
            _buildEditableWebsiteCard(),
            const SizedBox(height: 14),

            // ── 6. BUILT WITH (static) ────────────────────────────────────
            _buildBuiltWithCard(),
            const SizedBox(height: 40),

            // ── 7. COPYRIGHT ──────────────────────────────────────────────
            Text(
              '© ${DateTime.now().year} $_appName',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF727272),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Widget: Logo section ─────────────────────────────────────────────────
  Widget _buildLogoSection() {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: double.infinity,
          height: 120,
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _isUploadingLogo
                ? Center(
                    child: CircularProgressIndicator(
                      color: _primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : (_logoUrl != null
                    ? Image.network(
                        _logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/logo1.PNG',
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(
                        'assets/images/logo1.PNG',
                        fit: BoxFit.contain,
                      )),
          ),
        ),
        // Tombol edit logo — pojok kanan atas
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Tombol ganti logo
            GestureDetector(
              onTap: _isUploadingLogo ? null : _pickLogoFromGallery,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
            // Tombol hapus logo (hanya muncul jika ada logo custom)
            if (_logoUrl != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _isSaving ? null : _removeLogo,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Widget: Inline field (untuk nama & tagline — tampil sebagai Text) ────
  Widget _buildInlineField({
    required String value,
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required bool isEditing,
    required TextStyle textStyle,
    required TextStyle editStyle,
    required TextAlign textAlign,
    required VoidCallback onTapEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    if (!isEditing) {
      return GestureDetector(
        onTap: onTapEdit,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(value, style: textStyle, textAlign: textAlign),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_rounded, size: 16, color: _primary.withOpacity(0.5)),
          ],
        ),
      );
    }

    // Mode edit
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withOpacity(0.4), width: 1.5),
          ),
          child: TextField(
            controller: ctrl,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            style: editStyle,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text(_t('Cancel', 'Batal'),
                  style: GoogleFonts.poppins(color: Colors.black45)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(_t('Save', 'Simpan'),
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Widget: Card editable (untuk Version) ───────────────────────────────
  Widget _buildEditableCard({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required bool isEditing,
    required VoidCallback onTapEdit,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    if (!isEditing)
                      Text(value,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B))),
                    if (isEditing)
                      TextField(
                        controller: ctrl,
                        focusNode: focusNode,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                          hintText: label,
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.black26, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              // Tombol edit / save / cancel
              if (!isEditing)
                GestureDetector(
                  onTap: onTapEdit,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.edit_rounded, color: _primary, size: 16),
                  ),
                ),
              if (isEditing) ...[
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey.shade500, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _isSaving ? null : onSave,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Widget: Website card editable ────────────────────────────────────────
  Widget _buildEditableWebsiteCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language_rounded,
                    color: _primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Official Website', 'Website Resmi'),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    if (!_editingWebsite)
                      GestureDetector(
                        onTap: _appWebsite.isNotEmpty
                            ? () => _launchURL(_appWebsite)
                            : null,
                        child: Text(
                          _appWebsite.isNotEmpty
                              ? _appWebsite
                              : _t('Not set', 'Belum diatur'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _appWebsite.isNotEmpty
                                ? _primary
                                : Colors.black26,
                            decoration: _appWebsite.isNotEmpty
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            decorationColor: _primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (_editingWebsite)
                      TextField(
                        controller: _websiteCtrl,
                        focusNode: _websiteFocus,
                        keyboardType: TextInputType.url,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primary),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                          hintText: 'https://example.com',
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.black26, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              // Tombol
              if (!_editingWebsite) ...[
                GestureDetector(
                  onTap: () => setState(() {
                    _editingWebsite = true;
                    _websiteCtrl.text = _appWebsite;
                    Future.delayed(
                      const Duration(milliseconds: 50),
                      () => _websiteFocus.requestFocus(),
                    );
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_rounded, color: _primary, size: 16),
                  ),
                ),
                if (_appWebsite.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.open_in_new_rounded,
                      color: _primary, size: 18),
                ],
              ],
              if (_editingWebsite) ...[
                GestureDetector(
                  onTap: () => setState(() {
                    _editingWebsite   = false;
                    _websiteCtrl.text = _appWebsite;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey.shade500, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _isSaving
                      ? null
                      : () => _saveField(
                            field: 'website',
                            value: _websiteCtrl.text,
                            onDone: () => setState(() {
                              _appWebsite    = _websiteCtrl.text.trim();
                              _editingWebsite = false;
                            }),
                          ),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Widget: Built With (static) ──────────────────────────────────────────
  Widget _buildBuiltWithCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.code_rounded,
                    color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                _t('Built with', 'Dibangun dengan'),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/flutter.png',
                        height: 26,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.flutter_dash,
                            color: Color(0xFF54C5F8),
                            size: 26),
                      ),
                      const SizedBox(width: 8),
                      Text('Flutter',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0553B1))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FAF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/supabase.png',
                        height: 26,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.storage_rounded,
                            color: Color(0xFF3ECF8E),
                            size: 26),
                      ),
                      const SizedBox(width: 8),
                      Text('Supabase',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A7A4A))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSuccessPopup(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.elasticOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    msg,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Auto-dismiss setelah 1.5 detik
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  /// Snackbar merah untuk error saja
  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (!isError) {
      _showSuccessPopup(msg);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}