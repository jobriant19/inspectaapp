import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/code/qr_scanner_screen.dart';
import '../home/alert/required_field_alert.dart';

class _PC {
  static const primary      = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFEFF6FF);
  static const border       = Color(0xFFBFDBFE);
  static const bg           = Color(0xFFF0F4FF);
}

class PmFormScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? existingData;
  const PmFormScreen({super.key, required this.lang, this.existingData});

  @override
  State<PmFormScreen> createState() => _PmFormScreenState();
}

class _PmFormScreenState extends State<PmFormScreen> {
  bool get _isEdit => widget.existingData != null;
  bool _isSaving   = false;

  final _judulCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _alasanCtrl = TextEditingController();
  String? _selectedBagian;
  Map<String, String> _sectionDisplayMap = {};
  DateTime _bulanPm = DateTime(DateTime.now().year, DateTime.now().month, 1);

  String? _userId;
  String? _userOriginSectionId;
  bool _isProMode = false;

  bool get _isLate {
    final now = DateTime.now();
    final selected = DateTime(_bulanPm.year, _bulanPm.month, 1);
    final current  = DateTime(now.year, now.month, 1);
    if (selected.isBefore(current)) return true;
    if (selected.isAtSameMomentAs(current)) return now.day > 10;
    return false;
  }

  PlatformFile? _pickedFile;
  String? _existingFileUrl;
  String? _existingFileName;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const _txt = {
    'ID': {
      'create_title' : 'Buat Laporan PM',
      'edit_title'   : 'Edit Laporan PM',
      'judul'        : 'Judul PM',
      'judul_hint'   : 'Contoh: Perawatan mesin laser',
      'bagian'       : 'Bagian',
      'pick_bagian'  : 'Pilih Bagian',
      'file'         : 'File Lampiran',
      'add_file'     : 'Tambah File',
      'file_hint'    : 'PDF, Word, Excel, dan lainnya',
      'change_file'  : 'Ganti File',
      'remove_file'  : 'Hapus File',
      'desc'         : 'Deskripsi',
      'desc_hint'    : 'Jelaskan kegiatan PM...',
      'submit'       : 'Simpan Laporan',
      'update'       : 'Perbarui Laporan',
      'err_judul'    : 'Judul wajib diisi!',
      'err_bagian'   : 'Bagian wajib dipilih!',
      'success'      : 'Laporan PM berhasil disimpan!',
      'success_edit' : 'Laporan PM berhasil diperbarui!',
      'fail'         : 'Gagal menyimpan laporan',
      'saving'       : 'Menyimpan...',
      'cancel'       : 'Batal',
      'tanggal_pm'      : 'Tanggal Laporan PM',
      'status_terlambat': 'Terlambat',
      'alasan_terlambat': 'Alasan Keterlambatan',
      'alasan_hint'     : 'Jelaskan alasan laporan terlambat...',
      'err_alasan'      : 'Alasan keterlambatan wajib diisi!',
      'bulan_pm'        : 'Bulan Pengajuan PM',
      'pilih_bulan'     : 'Pilih Bulan',
      'sudah_lapor_title': 'Sudah Melaporkan',
      'sudah_lapor_desc' : 'Anda sudah membuat laporan PM untuk bulan ini. Silakan edit laporan yang sudah ada jika ingin mengubahnya.',
      'ok'              : 'Mengerti',
    },
    'EN': {
      'create_title' : 'Create PM Report',
      'edit_title'   : 'Edit PM Report',
      'judul'        : 'PM Title',
      'judul_hint'   : 'Example: Laser machine maintenance',
      'bagian'       : 'Section',
      'pick_bagian'  : 'Select Section',
      'file'         : 'Attachment File',
      'add_file'     : 'Add File',
      'file_hint'    : 'PDF, Word, Excel, and others',
      'change_file'  : 'Change File',
      'remove_file'  : 'Remove File',
      'desc'         : 'Description',
      'desc_hint'    : 'Describe PM activity...',
      'submit'       : 'Save Report',
      'update'       : 'Update Report',
      'err_judul'    : 'Title is required!',
      'err_bagian'   : 'Section is required!',
      'success'      : 'PM report saved!',
      'success_edit' : 'PM report updated!',
      'fail'         : 'Failed to save',
      'saving'       : 'Saving...',
      'cancel'       : 'Cancel',
      'tanggal_pm'      : 'PM Report Date',
      'status_terlambat': 'Late',
      'alasan_terlambat': 'Reason for Delay',
      'alasan_hint'     : 'Explain why this report is late...',
      'err_alasan'      : 'Reason for delay is required!',
      'bulan_pm'        : 'PM Submission Month',
      'pilih_bulan'     : 'Select Month',
      'sudah_lapor_title': 'Already Reported',
      'sudah_lapor_desc' : 'You have already created a PM report for this month. Please edit the existing report instead.',
      'ok'              : 'Got it',
    },
    'ZH': {
      'create_title' : '创建PM报告',
      'edit_title'   : '编辑PM报告',
      'judul'        : '标题',
      'judul_hint'   : '例如：激光机器维护',
      'bagian'       : '部门',
      'pick_bagian'  : '选择部门',
      'file'         : '附件文件',
      'add_file'     : '添加文件',
      'file_hint'    : 'PDF、Word、Excel等',
      'change_file'  : '更换文件',
      'remove_file'  : '删除文件',
      'desc'         : '描述',
      'desc_hint'    : '描述PM活动...',
      'submit'       : '保存报告',
      'update'       : '更新报告',
      'err_judul'    : '标题为必填项！',
      'err_bagian'   : '部门为必填项！',
      'success'      : 'PM报告已保存！',
      'success_edit' : 'PM报告已更新！',
      'fail'         : '保存失败',
      'saving'       : '保存中...',
      'cancel'       : '取消',
      'tanggal_pm'      : 'PM报告日期',
      'status_terlambat': '迟到',
      'alasan_terlambat': '延迟原因',
      'alasan_hint'     : '说明延迟报告的原因...',
      'err_alasan'      : '延迟原因为必填项！',
      'bulan_pm'        : 'PM提交月份',
      'pilih_bulan'     : '选择月份',
      'sudah_lapor_title': '已报告',
      'sudah_lapor_desc' : '您本月已创建PM报告。请编辑现有报告。',
      'ok'              : '知道了',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSectionDisplayMap();
    if (!_isEdit) {
      _loadUserBagian();
    } else {
      _loadUserContext();
    }
    if (_isEdit) {
      final d = widget.existingData!;
      _judulCtrl.text   = d['judul_pm'] ?? '';
      _descCtrl.text    = d['deskripsi_pm'] ?? '';
      _selectedBagian   = d['bagian'];
      _existingFileUrl  = d['file_pm'];
      _existingFileName = d['file_name_pm'];
      final blnRaw = d['bulan_pm'];
      if (blnRaw != null) {
        final parsed = DateTime.tryParse(blnRaw.toString());
        if (parsed != null) _bulanPm = DateTime(parsed.year, parsed.month, 1);
      }
      _alasanCtrl.text = d['alasan_terlambat'] ?? '';
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _alasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    final sb   = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) return;
    _userId = user.id;
    try {
      final userRow = await sb
          .from('User')
          .select('id_section, is_pro_mode')
          .eq('id_user', user.id)
          .maybeSingle();
      _userOriginSectionId = userRow?['id_section']?.toString();
      _isProMode = (userRow?['is_pro_mode'] as bool?) ?? false;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('PM load user context error: $e');
    }
  }

  Future<void> _loadUserBagian() async {
    await _loadUserContext();
    final sb = Supabase.instance.client;
    if (_userId == null) return;
    try {
      final picRes = await sb
          .from('section')
          .select('nama_section_id')
          .eq('id_pic', _userId!)
          .maybeSingle();
      if (picRes != null) {
        if (mounted) setState(() => _selectedBagian = picRes['nama_section_id'] as String?);
        return;
      }

      if (_userOriginSectionId != null) {
        final originRes = await sb
            .from('section')
            .select('nama_section_id')
            .eq('id_section', _userOriginSectionId!)
            .maybeSingle();
        if (originRes != null && mounted) {
          setState(() => _selectedBagian = originRes['nama_section_id'] as String?);
        }
      }
    } catch (e) {
      debugPrint('PM load section pic error: $e');
    }
  }

  Future<void> _showSectionPicker() async {
    final result = await showPmPickSectionDialog(
      context,
      lang: widget.lang,
      isProMode: _isProMode,
      userId: _userId,
      userOriginSectionId: _userOriginSectionId,
    );
    if (result != null && mounted) {
      setState(() => _selectedBagian = result['nama_section_id']?.toString());
    }
  }

  Future<void> _loadSectionDisplayMap() async {
    try {
      final sb = Supabase.instance.client;
      final res = await sb.from('section').select('nama_section_id, nama_section_en, nama_section_zh');
      final rows = List<Map<String, dynamic>>.from(res);
      final map = <String, String>{};
      for (final r in rows) {
        final idName = (r['nama_section_id'] as String?)?.trim();
        if (idName == null || idName.isEmpty) continue;
        String display = idName;
        if (widget.lang == 'EN') {
          final en = (r['nama_section_en'] as String?)?.trim();
          if (en != null && en.isNotEmpty) display = en;
        } else if (widget.lang == 'ZH') {
          final zh = (r['nama_section_zh'] as String?)?.trim();
          if (zh != null && zh.isNotEmpty) display = zh;
        }
        map[idName.toLowerCase()] = display;
      }
      if (mounted) setState(() => _sectionDisplayMap = map);
    } catch (e) {
      debugPrint('PM form loadSectionDisplayMap error: $e');
    }
  }

  String _displaySectionName(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    return _sectionDisplayMap[raw.trim().toLowerCase()] ?? raw;
  }

  void _showBulanPicker() async {
    final now = DateTime.now();
    DateTime temp = DateTime(_bulanPm.year, _bulanPm.month, 1);
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(color: _PC.primaryLight, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded, color: _PC.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(t['pilih_bulan']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _PC.primary))),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _PC.primary), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: DropdownButton<int>(
                  isExpanded: true, value: temp.month, underline: const SizedBox.shrink(),
                  items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m,
                    child: Text(DateFormat('MMMM').format(DateTime(2024, m, 1)), style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (m) { if (m != null) setLocal(() => temp = DateTime(temp.year, m, 1)); },
                )),
                const SizedBox(width: 10),
                Expanded(child: DropdownButton<int>(
                  isExpanded: true, value: temp.year, underline: const SizedBox.shrink(),
                  items: List.generate(4, (i) => now.year - 3 + i).map((y) => DropdownMenuItem(value: y,
                    child: Text('$y', style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (y) { if (y != null) setLocal(() => temp = DateTime(y, temp.month, 1)); },
                )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: temp.isAfter(DateTime(now.year, now.month, 1)) ? null : () {
                  Navigator.pop(ctx);
                  setState(() => _bulanPm = temp);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _PC.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(t['pilih_bulan']!),
              )),
            ),
          ]),
        ),
      );
    }));
  }

  Future<void> _showAlreadyReportedDialog() async {
    await showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: const Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 32)),
          const SizedBox(height: 16),
          Text(t['sudah_lapor_title']!, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(t['sudah_lapor_desc']!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: _PC.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(t['ok']!),
          )),
        ]),
      ),
    ));
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: CupertinoColors.destructiveRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));

  IconData _fileIcon(String? name) {
    final ext = (name ?? '').split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':  return CupertinoIcons.doc_richtext;
      case 'doc':
      case 'docx': return CupertinoIcons.doc_text_fill;
      case 'xls':
      case 'xlsx': return CupertinoIcons.table;
      case 'ppt':
      case 'pptx': return CupertinoIcons.play_rectangle_fill;
      case 'zip':
      case 'rar':  return CupertinoIcons.archivebox_fill;
      case 'jpg':
      case 'jpeg':
      case 'png':  return CupertinoIcons.photo_fill;
      default:     return CupertinoIcons.doc_fill;
    }
  }

  Color _fileColor(String? name) {
    final ext = (name ?? '').split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':  return const Color(0xFFEF4444);
      case 'doc':
      case 'docx': return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx': return const Color(0xFF16A34A);
      case 'ppt':
      case 'pptx': return const Color(0xFFEA580C);
      default:     return _PC.primary;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<String?> _uploadFile(PlatformFile file, String userId) async {
    final sb    = Supabase.instance.client;
    final bytes = file.bytes;
    if (bytes == null) return null;
    final ext      = file.extension ?? 'bin';
    final fileName = '$userId/pm_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await sb.storage.from('pm_files').uploadBinary(
      fileName, bytes,
      fileOptions: const FileOptions(upsert: false),
    );
    return sb.storage.from('pm_files').getPublicUrl(fileName);
  }

  Future<void> _submit() async {
    final List<MissingFieldItem> missing = [];

    if (_judulCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.edit_note_rounded, label: t['judul']!));
    }
    if (_selectedBagian == null) {
      missing.add(MissingFieldItem(icon: Icons.apartment_outlined, label: t['bagian']!));
    }
    if (_isLate && _alasanCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.report_gmailerrorred_outlined, label: t['alasan_terlambat']!));
    }
    if (_pickedFile == null && _existingFileUrl == null) {
      missing.add(MissingFieldItem(icon: Icons.attach_file_rounded, label: t['file']!));
    }
    if (_descCtrl.text.trim().isEmpty) {
      missing.add(MissingFieldItem(icon: Icons.description_outlined, label: t['desc']!));
    }

    if (missing.isNotEmpty) {
      RequiredFieldAlert.show(context, lang: widget.lang, missingFields: missing);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final sb   = Supabase.instance.client;
      final user = sb.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      if (!_isEdit) {
        final dup = await sb.from('preventif_maintenance')
            .select('id_pm')
            .eq('id_user', user.id)
            .eq('bulan_pm', DateFormat('yyyy-MM-dd').format(DateTime(_bulanPm.year, _bulanPm.month, 1)))
            .maybeSingle();
        if (dup != null) {
          setState(() => _isSaving = false);
          await _showAlreadyReportedDialog();
          return;
        }
      }

      String? fileUrl  = _existingFileUrl;
      String? fileName = _existingFileName;

      if (_pickedFile != null) {
        fileUrl  = await _uploadFile(_pickedFile!, user.id);
        fileName = _pickedFile!.name;
      }

      final data = {
        'judul_pm'     : _judulCtrl.text.trim(),
        'bagian'       : _selectedBagian,
        'deskripsi_pm' : _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'file_pm'      : fileUrl,
        'file_name_pm' : fileName,
        'bulan_pm'        : DateFormat('yyyy-MM-dd').format(DateTime(_bulanPm.year, _bulanPm.month, 1)),
        'is_late'         : _isLate,
        'alasan_terlambat': _isLate ? _alasanCtrl.text.trim() : null,
      };

      if (_isEdit) {
        await sb.from('preventif_maintenance').update(data)
            .eq('id_pm', widget.existingData!['id_pm']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t['success_edit']!),
              backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
        }
      } else {
        await sb.from('preventif_maintenance').insert({...data, 'id_user': user.id});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t['success']!),
              backgroundColor: CupertinoColors.activeGreen));
          await Future.delayed(const Duration(milliseconds: 400));
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('PM submit error: $e');
      if (mounted) {
        _showError('${t['fail']!}: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PC.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? t['edit_title']! : t['create_title']!,
          style: GoogleFonts.poppins(
              color: const Color(0xFF1D72F3),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // TITLE
                _sectionCard(children: [
                  _label(t['judul']!, icon: Icons.edit_note_rounded),
                  _textField(_judulCtrl, t['judul_hint']!),
                ]),
                const SizedBox(height: 16),

                _sectionCard(children: [
                  _label(t['bagian']!, icon: Icons.apartment_outlined),
                  GestureDetector(
                    onTap: _showSectionPicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedBagian != null ? _PC.primary : _PC.border,
                          width: _selectedBagian != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(
                          _displaySectionName(_selectedBagian),
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
                        const Icon(CupertinoIcons.chevron_right, size: 15, color: _PC.primary),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // BULAN PENGAJUAN PM
                _sectionCard(children: [
                  _label(t['bulan_pm']!, icon: Icons.calendar_month_rounded),
                  GestureDetector(
                    onTap: _showBulanPicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isLate ? const Color(0xFFEF4444) : _PC.primary, width: 1.5)),
                      child: Row(children: [
                        Expanded(child: Text(
                          DateFormat('MMMM yyyy').format(_bulanPm),
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))),
                        if (_isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(8)),
                            child: Text(t['status_terlambat']!,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444)))),
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.chevron_down, size: 15, color: _isLate ? const Color(0xFFEF4444) : _PC.primary),
                      ]),
                    ),
                  ),
                  if (_isLate) ...[
                    const SizedBox(height: 12),
                    _label(t['alasan_terlambat']!, icon: Icons.report_gmailerrorred_outlined),
                    _textField(_alasanCtrl, t['alasan_hint']!, maxLines: 3),
                  ],
                ]),
                const SizedBox(height: 16),

                // ATTACHMENT FILE
                _sectionCard(children: [
                  _label(t['file']!, icon: Icons.attach_file_rounded),
                  _fileWidget(),
                ]),
                const SizedBox(height: 16),

                // DESCRIPTION
                _sectionCard(children: [
                  _label(t['desc']!, icon: Icons.description_outlined),
                  _textField(_descCtrl, t['desc_hint']!, maxLines: 4),
                ]),
                const SizedBox(height: 24),

                // SUBMIT
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4))]),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                    child: Text(
                      _isEdit ? t['update']! : t['submit']!,
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          // SAVING OVERLAY
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                    vertical: 28, horizontal: 24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CupertinoActivityIndicator(
                      radius: 12, color: _PC.primary),
                  const SizedBox(height: 12),
                  Text(t['saving']!,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B))),
                ])))),
        ],
      ),
    );
  }

  Widget _fileWidget() {
    final displayName = _pickedFile?.name ?? _existingFileName;
    final hasFile     = displayName != null;

    if (!hasFile) {
      return GestureDetector(
        onTap: _pickFile,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 108),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _PC.border, width: 1.5)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  color: _PC.primaryLight, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.doc_chart_fill,
                  color: _PC.primary, size: 26)),
            const SizedBox(height: 10),
            Text(t['add_file']!,
              style: GoogleFonts.inter(
                  color: _PC.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
            const SizedBox(height: 2),
            Text(t['file_hint']!,
              style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8), fontSize: 11)),
          ]),
        ),
      );
    }

    final fileColor = _fileColor(displayName);
    final fileIcon  = _fileIcon(displayName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PC.border, width: 1.5)),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: fileColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(fileIcon, color: fileColor, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(displayName,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B)),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          if (_pickedFile?.size != null) ...[
            const SizedBox(height: 2),
            Text(_formatBytes(_pickedFile!.size),
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8))),
          ],
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _PC.primaryLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _PC.primary.withValues(alpha: 0.25))),
            child: Text(t['change_file']!,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _PC.primary)))),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() {
            _pickedFile       = null;
            _existingFileUrl  = null;
            _existingFileName = null;
          }),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.25))),
            child: const Icon(CupertinoIcons.trash,
                size: 14, color: Color(0xFFEF4444)))),
      ]),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024)    return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Widget _sectionCard({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _PC.border, width: 1),
      boxShadow: [BoxShadow(
          color: _PC.primary.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _label(String label, {required IconData icon}) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF1D72F3)),
      const SizedBox(width: 6),
      Text(label,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: const Color(0xFF1D72F3))),
      const Text(' *',
        style: TextStyle(
            color: CupertinoColors.destructiveRed,
            fontWeight: FontWeight.bold)),
    ]));

  Widget _textField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1), fontSize: 15),
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _PC.border, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _PC.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16)));
}

Future<Map<String, dynamic>?> showPmPickSectionDialog(
  BuildContext context, {
  required String lang,
  required bool isProMode,
  required String? userId,
  required String? userOriginSectionId,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _PmPickSectionDialog(
      lang: lang,
      isProMode: isProMode,
      userId: userId,
      userOriginSectionId: userOriginSectionId,
    ),
  );
}

class _PmPickSectionDialog extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final String? userId;
  final String? userOriginSectionId;

  const _PmPickSectionDialog({
    required this.lang,
    required this.isProMode,
    required this.userId,
    required this.userOriginSectionId,
  });

  @override
  State<_PmPickSectionDialog> createState() => _PmPickSectionDialogState();
}

class _PmPickSectionDialogState extends State<_PmPickSectionDialog> {
  static const Color _accent       = Color(0xFF1D4ED8);
  static const Color _accentLight  = Color(0xFFEFF6FF);
  static const Color _accentBorder = Color(0xFFBFDBFE);

  List<Map<String, dynamic>> _allSections = [];
  List<Map<String, dynamic>> _filteredSections = [];
  bool _isLoading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadSections();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _title(String lang) {
    switch (lang) {
      case 'EN': return 'Select Section';
      case 'ZH': return '选择部门';
      default: return 'Pilih Bagian';
    }
  }

  String _searchHint(String lang) {
    switch (lang) {
      case 'EN': return 'Search section...';
      case 'ZH': return '搜索部门...';
      default: return 'Cari bagian...';
    }
  }

  String _emptyText(String lang) {
    switch (lang) {
      case 'EN': return 'No sections found';
      case 'ZH': return '未找到部门';
      default: return 'Tidak ada bagian';
    }
  }

  String _countLabel(String lang) {
    final n = _filteredSections.length;
    switch (lang) {
      case 'EN': return '$n sections';
      case 'ZH': return '$n 个部门';
      default: return '$n bagian';
    }
  }

  String _scanTitle(String lang) {
    switch (lang) {
      case 'EN': return 'Scan Section';
      case 'ZH': return '扫描部门';
      default: return 'Pindai Section';
    }
  }

  String _nameOf(Map<String, dynamic> s) {
    if (widget.lang == 'EN') return s['nama_section_en']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    if (widget.lang == 'ZH') return s['nama_section_zh']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    return s['nama_section_id']?.toString() ?? '-';
  }

  Future<void> _loadSections() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('section')
          .select('*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)')
          .order('urutan', ascending: true);

      List<Map<String, dynamic>> sections = List<Map<String, dynamic>>.from(data);

      if (!widget.isProMode) {
        sections = sections.where((s) {
          final idSection = s['id_section']?.toString();
          final idPic = s['id_pic']?.toString();
          final isPic = widget.userId != null && idPic == widget.userId;
          final isOrigin = widget.userOriginSectionId != null && idSection == widget.userOriginSectionId;
          return isPic || isOrigin;
        }).toList();
      }

      if (mounted) {
        setState(() {
          _allSections = sections;
          _filteredSections = _applySearch(sections);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error load section (PM): $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> src) {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return src;
    return src.where((s) => _nameOf(s).toLowerCase().contains(q)).toList();
  }

  void _onSearch() => setState(() => _filteredSections = _applySearch(_allSections));

  Future<void> _openQrScanner() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          lang: widget.lang,
          isProMode: widget.isProMode,
          isVisitorMode: false,
          sectionMode: true,
          overrideTitle: _scanTitle(widget.lang),
        ),
      ),
    );

    if (result == null || !mounted) return;
    final scannedId = result['id']?.toString();
    if (scannedId == null || scannedId.isEmpty) return;

    try {
      final data = await Supabase.instance.client
          .from('section')
          .select('*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)')
          .eq('id_section', scannedId)
          .maybeSingle();
      if (data != null && mounted) {
        Navigator.pop(context, Map<String, dynamic>.from(data));
      }
    } catch (e) {
      debugPrint('Error mengambil data section dari QR (PM): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 340,
        height: screenHeight * 0.72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accentLight, width: 1.5),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _accentLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title(widget.lang),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: _accent),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(CupertinoIcons.xmark, color: Color(0xFF64748B), size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),

          // SEARCH + SCAN QR
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1.3),
                    boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _searchHint(widget.lang),
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFBDBDBD)),
                      prefixIcon: const Icon(CupertinoIcons.search, color: _accent, size: 19),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openQrScanner,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),

          // COUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accentBorder),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(CupertinoIcons.square_grid_2x2_fill, size: 12, color: _accent),
                  const SizedBox(width: 6),
                  Text(
                    _countLabel(widget.lang),
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: _accent),
                  ),
                ]),
              ),
            ),
          ),
          const Divider(height: 1, color: _accentBorder),

          Expanded(
            child: _isLoading
                ? _pmSectionShimmerList()
                : _filteredSections.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(CupertinoIcons.square_grid_2x2, size: 44, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),
                          Text(_emptyText(widget.lang), style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        itemCount: _filteredSections.length,
                        itemBuilder: (_, i) {
                          final s = _filteredSections[i];
                          final name = _nameOf(s);
                          return InkWell(
                            onTap: () => Navigator.pop(context, s),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _accentBorder),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: _accentLight, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _accent, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                                ),
                                const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}

Widget _pmSectionShimmerList() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 60,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}