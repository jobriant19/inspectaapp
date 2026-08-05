import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/utils/app_branding_cache.dart';

class AdminAboutScreen extends StatefulWidget {
  final String lang;
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
  late String _appName;
  late String _appVersion;
  late String _appWebsite;
  late String _appTagline;
  late String _appCopyright;
  String? _logoUrl;

  bool _editingName      = false;
  bool _editingVersion   = false;
  bool _editingWebsite   = false;
  bool _editingTagline   = false;
  bool _editingCopyright = false;
  bool _isSaving         = false;
  bool _isUploadingLogo  = false;

  final _nameCtrl      = TextEditingController();
  final _versionCtrl   = TextEditingController();
  final _websiteCtrl   = TextEditingController();
  final _taglineCtrl   = TextEditingController();
  final _copyrightCtrl = TextEditingController();

  final _nameFocus      = FocusNode();
  final _versionFocus   = FocusNode();
  final _websiteFocus   = FocusNode();
  final _taglineFocus   = FocusNode();
  final _copyrightFocus = FocusNode();

  String _t(String en, String id, [String? zh]) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh ?? id;
    return id;
  }

  String get _screenTitle => widget.lang == 'EN'
      ? 'About Inspecta'
      : widget.lang == 'ZH'
          ? '关于 Inspecta'
          : 'Tentang Inspecta';

  @override
  void initState() {
    super.initState();
    _data         = widget.initialData;
    _appName      = widget.initialData?['app_name'] ?? 'Inspecta';
    _appVersion   = widget.initialData?['version']  ?? '-';
    _appWebsite   = widget.initialData?['website']  ?? '';
    _appTagline   = _localizedTagline(widget.initialData);
    _appCopyright = _localizedCopyright(widget.initialData);
    _logoUrl      = widget.initialData?['logo_url'] as String?;

    _nameCtrl.text      = _appName;
    _versionCtrl.text   = _appVersion;
    _websiteCtrl.text   = _appWebsite;
    _taglineCtrl.text   = _appTagline;
    _copyrightCtrl.text = _appCopyright;

    if (widget.initialData == null) _loadSilent();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _versionCtrl.dispose();
    _websiteCtrl.dispose();
    _taglineCtrl.dispose();
    _copyrightCtrl.dispose();
    _nameFocus.dispose();
    _versionFocus.dispose();
    _websiteFocus.dispose();
    _taglineFocus.dispose();
    _copyrightFocus.dispose();
    super.dispose();
  }

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
        _data         = res;
        _appName      = res['app_name'] ?? 'Inspecta';
        _appVersion   = res['version']  ?? '-';
        _appWebsite   = res['website']  ?? '';
        _appTagline   = _localizedTagline(res);
        _appCopyright = _localizedCopyright(res);
        _logoUrl      = res['logo_url'] as String?;
        _nameCtrl.text      = _appName;
        _versionCtrl.text   = _appVersion;
        _websiteCtrl.text   = _appWebsite;
        _taglineCtrl.text   = _appTagline;
        _copyrightCtrl.text = _appCopyright;
      });
      await AppBrandingCache.save(res);
    } catch (e) {
      debugPrint('AdminAboutScreen background load error: $e');
    }
  }

  String _localizedTagline(Map<String, dynamic>? row) {
    if (row == null) return 'Make Your Discipline day!';
    switch (widget.lang) {
      case 'EN':
        return (row['tagline_en'] ?? row['tagline'] ?? 'Make Your Discipline day!').toString();
      case 'ZH':
        return (row['tagline_zh'] ?? row['tagline'] ?? 'Make Your Discipline day!').toString();
      default:
        return (row['tagline'] ?? 'Make Your Discipline day!').toString();
    }
  }

  String _localizedCopyright(Map<String, dynamic>? row) {
    final fallback = '© ${DateTime.now().year} $_appName';
    if (row == null) return fallback;
    String? val;
    switch (widget.lang) {
      case 'EN':
        val = row['copyright_en'] as String?;
        break;
      case 'ZH':
        val = row['copyright_zh'] as String?;
        break;
      default:
        val = row['copyright'] as String?;
    }
    return (val != null && val.trim().isNotEmpty) ? val : fallback;
  }

  Future<void> _saveTagline(String value) async {
    final source = value.trim().isEmpty ? 'Make Your Discipline day!' : value.trim();
    setState(() => _isSaving = true);
    try {
      Map<String, String> taglineAll;
      try {
        taglineAll = await TranslationHelper.instance
            .translateDescriptionAllLangs(source, widget.lang);
      } catch (e) {
        debugPrint('Error translating tagline: $e');
        taglineAll = {'id': source, 'en': source, 'zh': source};
      }

      final payload = {
        'tagline'    : taglineAll['id']!.isEmpty ? source : taglineAll['id'],
        'tagline_en' : taglineAll['en']!.isEmpty ? source : taglineAll['en'],
        'tagline_zh' : taglineAll['zh']!.isEmpty ? source : taglineAll['zh'],
      };

      if (_data == null) {
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
        setState(() => _data = {..._data!, ...payload});
      }

      setState(() {
        _appTagline     = _localizedTagline(_data);
        _editingTagline = false;
      });
      if (_data != null) await AppBrandingCache.save(_data!);
      _showSnack(_t('Saved!', 'Tersimpan!', '已保存！'));
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveCopyright(String value) async {
    final source = value.trim().isEmpty
        ? '© ${DateTime.now().year} $_appName'
        : value.trim();
    setState(() => _isSaving = true);
    try {
      Map<String, String> copyrightAll;
      try {
        copyrightAll = await TranslationHelper.instance
            .translateDescriptionAllLangs(source, widget.lang);
      } catch (e) {
        debugPrint('Error translating copyright: $e');
        copyrightAll = {'id': source, 'en': source, 'zh': source};
      }

      final payload = {
        'copyright'    : copyrightAll['id']!.isEmpty ? source : copyrightAll['id'],
        'copyright_en' : copyrightAll['en']!.isEmpty ? source : copyrightAll['en'],
        'copyright_zh' : copyrightAll['zh']!.isEmpty ? source : copyrightAll['zh'],
      };

      if (_data == null) {
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
        setState(() => _data = {..._data!, ...payload});
      }

      setState(() {
        _appCopyright     = _localizedCopyright(_data);
        _editingCopyright = false;
      });
      _showSnack(_t('Saved!', 'Tersimpan!', '已保存！'));
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveField({
    required String field,
    required String value,
    required VoidCallback onDone,
  }) async {
    setState(() => _isSaving = true);
    try {
      final payload = {field: value.trim().isEmpty ? null : value.trim()};
      if (_data == null) {
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
        setState(() => _data = {..._data!, ...payload});
      }
      onDone();
      if (field == 'app_name' && _data != null) {
        await AppBrandingCache.save(_data!);
      }
      _showSnack(_t('Saved!', 'Tersimpan!', '已保存！'));
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
          .from('avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      if (_data != null) {
        await Supabase.instance.client
            .from('app_info')
            .update({'logo_url': publicUrl})
            .eq('id', _data!['id']);
        _data = {..._data!, 'logo_url': publicUrl};
      }

      setState(() => _logoUrl = publicUrl);
      await AppBrandingCache.save({'app_name': _appName, 'logo_url': publicUrl});
      _showSnack(_t('Logo updated!', 'Logo diperbarui!', '徽标已更新！'));
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
      _data = {..._data!, 'logo_url': null};
      setState(() => _logoUrl = null);
      await AppBrandingCache.save({'app_name': _appName, 'logo_url': ''});
      _showSnack(_t('Logo removed.', 'Logo dihapus.', '徽标已删除。'));
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showErrorPopup('Could not launch $url');
      }
    }
  }

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
          _screenTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _primary,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
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
            _buildLogoSection(),
            const SizedBox(height: 16),

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
                _saveTagline(_taglineCtrl.text);
              },
              onCancel: () => setState(() {
                _editingTagline   = false;
                _taglineCtrl.text = _appTagline;
              }),
            ),
            const SizedBox(height: 36),

            _buildEditableCard(
              icon: Icons.info_outline_rounded,
              label: _t('App Version', 'Versi Aplikasi', '应用版本'),
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

            _buildEditableWebsiteCard(),
            const SizedBox(height: 32),

            // COPYRIGHT
            _buildInlineField(
              value: _appCopyright,
              ctrl: _copyrightCtrl,
              focusNode: _copyrightFocus,
              isEditing: _editingCopyright,
              textStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF727272),
              ),
              editStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF727272),
              ),
              textAlign: TextAlign.center,
              onTapEdit: () => setState(() {
                _editingCopyright = true;
                _copyrightCtrl.text = _appCopyright;
                Future.delayed(
                  const Duration(milliseconds: 50),
                  () => _copyrightFocus.requestFocus(),
                );
              }),
              onSave: () => _saveCopyright(_copyrightCtrl.text),
              onCancel: () => setState(() {
                _editingCopyright   = false;
                _copyrightCtrl.text = _appCopyright;
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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
        // EDIT LOGO BUTTON
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // CHANGE LOGO BUTTON
            GestureDetector(
              onTap: _isUploadingLogo ? null : _pickLogoFromGallery,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha:0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
            // DELETE LOGO BUTTON
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
                        color: Colors.red.withValues(alpha:0.3),
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
            Icon(Icons.edit_rounded, size: 16, color: _primary.withValues(alpha:0.5)),
          ],
        ),
      );
    }

    // EDIT MODE
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primary.withValues(alpha:0.4), width: 1.5),
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
              child: Text(_t('Cancel', 'Batal', '取消'),
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
              child: Text(_t('Save', 'Simpan', '保存'),
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

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
            color: _primary.withValues(alpha:0.07),
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
                            fontWeight: FontWeight.w600)),
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
              // EDIT BUTTON / SAVE / CANCEL
              if (!isEditing)
                GestureDetector(
                  onTap: onTapEdit,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha:0.08),
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

  Widget _buildEditableWebsiteCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha:0.07),
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
                      _t('Official Website', 'Website Resmi', '官方网站'),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600),
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
                              : _t('Not set', 'Belum diatur', '未设置'),
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
                      color: _primary.withValues(alpha:0.08),
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

  void _showSuccessPopup(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha:0.35),
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
                    color: const Color(0xFF10B981).withValues(alpha:0.2),
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
                      color: const Color(0xFF10B981).withValues(alpha:0.12),
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
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      _showErrorPopup(msg);
    } else {
      _showSuccessPopup(msg);
    }
  }

  void _showErrorPopup(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha:0.35),
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
                    color: const Color(0xFFEF4444).withValues(alpha:0.2),
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
                      color: const Color(0xFFEF4444).withValues(alpha:0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    msg,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }
}