import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const List<String> _kEditBagianList = [
  'Laser', 'Mesin', 'Spot', 'Las', 'Ftw', 'Cat',
  'Assy', 'Ekspedisi & Packing', 'Purchasing', 'Engineering', 'PPIC',
];

class _EPC {
  static const primary      = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFEFF6FF);
  static const border       = Color(0xFFBFDBFE);
  static const bg           = Color(0xFFF0F4FF);
}

class PmEditScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> existingData;
  const PmEditScreen({
    super.key,
    required this.lang,
    required this.existingData,
  });

  @override
  State<PmEditScreen> createState() => _PmEditScreenState();
}

class _PmEditScreenState extends State<PmEditScreen> {
  bool _isSaving = false;

  final _judulCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _alasanCtrl = TextEditingController();
  String? _selectedBagian;
  DateTime _tanggalPm = DateTime.now();
  bool get _isLate => _tanggalPm.day > 10;

  PlatformFile? _pickedFile;
  String? _existingFileUrl;
  String? _existingFileName;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const _txt = {
    'ID': {
      'edit_title'   : 'Edit Laporan PM',
      'judul'        : 'Judul PM',
      'judul_hint'   : 'Contoh: Perawatan mesin laser',
      'bagian'       : 'Bagian',
      'pick_bagian'  : 'Pilih Bagian',
      'file'         : 'File Lampiran (Opsional)',
      'add_file'     : 'Tambah File',
      'file_hint'    : 'PDF, Word, Excel, dan lainnya',
      'change_file'  : 'Ganti File',
      'remove_file'  : 'Hapus File',
      'desc'         : 'Deskripsi (Opsional)',
      'desc_hint'    : 'Jelaskan kegiatan PM...',
      'update'       : 'Perbarui Laporan',
      'err_judul'    : 'Judul wajib diisi!',
      'err_bagian'   : 'Bagian wajib dipilih!',
      'success_edit' : 'Laporan PM berhasil diperbarui!',
      'fail'         : 'Gagal menyimpan laporan',
      'saving'       : 'Menyimpan...',
      'cancel'       : 'Batal',
      'tanggal_pm'      : 'Tanggal Laporan PM',
      'status_terlambat': 'Terlambat',
      'alasan_terlambat': 'Alasan Keterlambatan',
      'alasan_hint'     : 'Jelaskan alasan laporan terlambat...',
      'err_alasan'      : 'Alasan keterlambatan wajib diisi!',
    },
    'EN': {
      'edit_title'   : 'Edit PM Report',
      'judul'        : 'PM Title',
      'judul_hint'   : 'Example: Laser machine maintenance',
      'bagian'       : 'Section',
      'pick_bagian'  : 'Select Section',
      'file'         : 'Attachment File (Optional)',
      'add_file'     : 'Add File',
      'file_hint'    : 'PDF, Word, Excel, and others',
      'change_file'  : 'Change File',
      'remove_file'  : 'Remove File',
      'desc'         : 'Description (Optional)',
      'desc_hint'    : 'Describe PM activity...',
      'update'       : 'Update Report',
      'err_judul'    : 'Title is required!',
      'err_bagian'   : 'Section is required!',
      'success_edit' : 'PM report updated!',
      'fail'         : 'Failed to save',
      'saving'       : 'Saving...',
      'cancel'       : 'Cancel',
      'tanggal_pm'      : 'PM Report Date',
      'status_terlambat': 'Late',
      'alasan_terlambat': 'Reason for Delay',
      'alasan_hint'     : 'Explain why this report is late...',
      'err_alasan'      : 'Reason for delay is required!',
    },
    'ZH': {
      'edit_title'   : '编辑PM报告',
      'judul'        : '标题',
      'judul_hint'   : '例如：激光机器维护',
      'bagian'       : '部门',
      'pick_bagian'  : '选择部门',
      'file'         : '附件文件（可选）',
      'add_file'     : '添加文件',
      'file_hint'    : 'PDF、Word、Excel等',
      'change_file'  : '更换文件',
      'remove_file'  : '删除文件',
      'desc'         : '描述（可选）',
      'desc_hint'    : '描述PM活动...',
      'update'       : '更新报告',
      'err_judul'    : '标题为必填项！',
      'err_bagian'   : '部门为必填项！',
      'success_edit' : 'PM报告已更新！',
      'fail'         : '保存失败',
      'saving'       : '保存中...',
      'cancel'       : '取消',
      'tanggal_pm'      : 'PM报告日期',
      'status_terlambat': '迟到',
      'alasan_terlambat': '延迟原因',
      'alasan_hint'     : '说明延迟报告的原因...',
      'err_alasan'      : '延迟原因为必填项！',
    },
  };

  @override
  void initState() {
    super.initState();
    final d = widget.existingData;
    _judulCtrl.text   = d['judul_pm'] ?? '';
    _descCtrl.text    = d['deskripsi_pm'] ?? '';
    _selectedBagian   = d['bagian'];
    _existingFileUrl  = d['file_pm'];
    _existingFileName = d['file_name_pm'];
    final tglRaw = d['tanggal_pm'];
    if (tglRaw != null) {
      final parsed = DateTime.tryParse(tglRaw.toString());
      if (parsed != null) _tanggalPm = parsed;
    }
    _alasanCtrl.text = d['alasan_terlambat'] ?? '';
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _alasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalPm() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalPm,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _EPC.primary)),
        child: child!),
    );
    if (picked != null) setState(() => _tanggalPm = picked);
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
      default:     return _EPC.primary;
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
    if (_judulCtrl.text.trim().isEmpty) return _showError(t['err_judul']!);
    if (_selectedBagian == null)        return _showError(t['err_bagian']!);
    if (_isLate && _alasanCtrl.text.trim().isEmpty) return _showError(t['err_alasan']!);
    setState(() => _isSaving = true);

    try {
      final sb   = Supabase.instance.client;
      final user = sb.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

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
        'tanggal_pm'      : DateFormat('yyyy-MM-dd').format(_tanggalPm),
        'alasan_terlambat': _isLate ? _alasanCtrl.text.trim() : null,
      };

      await sb.from('preventif_maintenance')
          .update(data)
          .eq('id_pm', widget.existingData['id_pm']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['success_edit']!),
            backgroundColor: CupertinoColors.activeGreen));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('PM edit submit error: $e');
      if (mounted) {
        _showError('${t['fail']!}: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  void _showBagianSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HANDLE
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2)),
            ),
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _EPC.primaryLight,
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.grid_view_rounded,
                      color: _EPC.primary, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  t['pick_bagian']!,
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B)))),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close, size: 18,
                        color: Color(0xFF64748B)))),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            // SECTION LIST
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _kEditBagianList.length,
                itemBuilder: (_, i) {
                  final b   = _kEditBagianList[i];
                  final sel = _selectedBagian == b;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedBagian = b);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: sel ? _EPC.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? _EPC.primary : const Color(0xFFE2E8F0),
                          width: sel ? 1.5 : 1)),
                      child: Row(children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: sel ? _EPC.primary : _EPC.primaryLight,
                            borderRadius: BorderRadius.circular(9)),
                          child: Center(child: Text(
                            b[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14,
                              color: sel ? Colors.white : _EPC.primary)))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(b,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? _EPC.primary : const Color(0xFF1E293B)))),
                        if (sel)
                          const Icon(Icons.check_circle_rounded,
                              color: _EPC.primary, size: 20),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EPC.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: _EPC.primary),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          t['edit_title']!,
          style: GoogleFonts.inter(
              color: _EPC.primary, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _EPC.border, height: 1)),
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
                  _label(t['judul']!, required: true),
                  _textField(_judulCtrl, t['judul_hint']!,
                      CupertinoIcons.text_cursor),
                ]),
                const SizedBox(height: 16),

                // SECTION
                _sectionCard(children: [
                  _label(t['bagian']!, required: true),
                  GestureDetector(
                    onTap: _showBagianSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedBagian != null
                              ? _EPC.primary
                              : _EPC.border,
                          width: _selectedBagian != null ? 1.5 : 1)),
                      child: Row(children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 16,
                          color: _selectedBagian != null
                              ? _EPC.primary
                              : const Color(0xFFBFDBFE)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          _selectedBagian ?? t['pick_bagian']!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: _selectedBagian != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedBagian != null
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFCBD5E1)))),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 15,
                          color: _selectedBagian != null
                              ? _EPC.primary
                              : const Color(0xFFBFDBFE)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // TANGGAL LAPORAN PM
                _sectionCard(children: [
                  _label(t['tanggal_pm']!, required: true),
                  GestureDetector(
                    onTap: _pickTanggalPm,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isLate ? const Color(0xFFEF4444) : _EPC.primary, width: 1.5)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: _isLate ? const Color(0xFFEF4444) : _EPC.primary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          DateFormat('dd MMMM yyyy').format(_tanggalPm),
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))),
                        if (_isLate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(8)),
                            child: Text(t['status_terlambat']!,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444)))),
                        const SizedBox(width: 8),
                        Icon(CupertinoIcons.chevron_down, size: 15, color: _isLate ? const Color(0xFFEF4444) : _EPC.primary),
                      ]),
                    ),
                  ),
                  if (_isLate) ...[
                    const SizedBox(height: 12),
                    _label(t['alasan_terlambat']!, required: true),
                    _textField(_alasanCtrl, t['alasan_hint']!, CupertinoIcons.exclamationmark_bubble, maxLines: 3),
                  ],
                ]),
                const SizedBox(height: 16),

                // ATTACHMENT FILE
                _sectionCard(children: [
                  _label(t['file']!, required: false),
                  _fileWidget(),
                ]),
                const SizedBox(height: 16),

                // DESCRIPTION
                _sectionCard(children: [
                  _label(t['desc']!, required: false),
                  _textField(_descCtrl, t['desc_hint']!,
                      CupertinoIcons.doc_text, maxLines: 4),
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
                      t['update']!,
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
                      radius: 12, color: _EPC.primary),
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
            border: Border.all(color: _EPC.border, width: 1.5)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: _EPC.primaryLight, shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.doc_chart_fill,
                    color: _EPC.primary, size: 26)),
              const SizedBox(height: 10),
              Text(t['add_file']!,
                style: GoogleFonts.inter(
                    color: _EPC.primary,
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
        border: Border.all(color: _EPC.border, width: 1.5)),
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
                fontSize: 13, fontWeight: FontWeight.w600,
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
              color: _EPC.primaryLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _EPC.primary.withValues(alpha: 0.25))),
            child: Text(t['change_file']!,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: _EPC.primary)))),
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
      border: Border.all(color: _EPC.border, width: 1),
      boxShadow: [BoxShadow(
          color: _EPC.primary.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _label(String label, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Row(children: [
      Text(label,
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w600, fontSize: 13,
            color: const Color(0xFF475569))),
      if (required)
        const Text(' *',
          style: TextStyle(
              color: CupertinoColors.destructiveRed,
              fontWeight: FontWeight.bold)),
    ]));

  Widget _textField(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1), fontSize: 15),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: _EPC.primary, size: 20)
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _EPC.border, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _EPC.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16)));
}