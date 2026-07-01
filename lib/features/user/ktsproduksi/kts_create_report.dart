import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class KtsProduksiFormScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? existingData;
  const KtsProduksiFormScreen({super.key, required this.lang, this.existingData});

  @override
  State<KtsProduksiFormScreen> createState() => _KtsProduksiFormScreenState();
}

class _KtsProduksiFormScreenState extends State<KtsProduksiFormScreen> {
  bool get _isEdit => widget.existingData != null;
  bool _isSaving = false;

  final _noOrderCtrl  = TextEditingController();
  final _judulCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _itemSearchCtrl = TextEditingController();

  Map<String, dynamic>? _selectedAssignee;

  XFile? _imageFile;
  String? _existingImageUrl;
  final _qtyCtrl = TextEditingController(text: '1');

  static const Color _kPrimary      = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight = Color(0xFFEFF6FF);
  static const Color _kBorder       = Color(0xFFBFDBFE);
  static const Color _kBg           = Color(0xFFF0F4FF);

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'create_title': 'Buat Laporan', 'edit_title': 'Edit Laporan',
      'no_order': 'No. Order', 'no_order_hint': 'Masukkan nomor order...',
      'judul': 'Judul KTS', 'judul_hint': 'Contoh: Part tidak sesuai',
      'item': 'Item Produksi', 'item_hint': 'Cari item...',
      'qty': 'Jumlah', 'photo': 'Foto Bukti', 'add_photo': 'Tambah Foto',
      'desc': 'Deskripsi (Opsional)', 'desc_hint': 'Jelaskan temuan secara detail...',
      'submit': 'Simpan Laporan', 'update': 'Perbarui Laporan',
      'err_order': 'No. Order wajib diisi!', 'err_judul': 'Judul wajib diisi!',
      'err_item': 'Item produksi wajib diisi!',
      'success': 'Laporan berhasil disimpan! +20 poin', 'success_edit': 'Laporan berhasil diperbarui!',
      'fail': 'Gagal menyimpan laporan', 'saving': 'Menyimpan...', 'cancel': 'Batal',
    },
    'EN': {
      'create_title': 'Create Report', 'edit_title': 'Edit Report',
      'no_order': 'Order No.', 'no_order_hint': 'Enter order number...',
      'judul': 'KTS Title', 'judul_hint': 'Example: Part mismatch',
      'item': 'Production Item', 'item_hint': 'Search item...',
      'qty': 'Qty', 'photo': 'Evidence Photo', 'add_photo': 'Add Photo',
      'desc': 'Description (Optional)', 'desc_hint': 'Explain the finding...',
      'submit': 'Save Report', 'update': 'Update Report',
      'err_order': 'Order No. is required!', 'err_judul': 'Title is required!',
      'err_item': 'Production item is required!',
      'success': 'Report saved! +20 points', 'success_edit': 'Report updated!',
      'fail': 'Failed to save report', 'saving': 'Saving...', 'cancel': 'Cancel',
    },
    'ZH': {
      'create_title': '创建报告', 'edit_title': '编辑报告',
      'no_order': '订单号', 'no_order_hint': '输入订单号...',
      'judul': '标题', 'judul_hint': '例如：零件不符',
      'item': '生产项目', 'item_hint': '搜索项目...',
      'qty': '数量', 'photo': '证据照片', 'add_photo': '添加照片',
      'desc': '描述（可选）', 'desc_hint': '详细说明...',
      'submit': '保存报告', 'update': '更新报告',
      'err_order': '订单号为必填项！', 'err_judul': '标题为必填项！',
      'err_item': '生产项目为必填项！',
      'success': '报告已保存！+20积分', 'success_edit': '报告已更新！',
      'fail': '保存报告失败', 'saving': '保存中...', 'cancel': '取消',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (_isEdit) _populateData();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profile = await Supabase.instance.client
          .from('User')
          .select('id_user, nama, id_jabatan, id_lokasi, id_unit, id_subunit, id_area, jabatan!User_id_jabatan_fkey(nama_jabatan), gambar_user')
          .eq('id_user', user.id)
          .single();
      if (mounted && _selectedAssignee == null) {
        setState(() {
          _selectedAssignee = {
            'id_user': profile['id_user'],
            'nama': profile['nama'],
            'jabatan': profile['jabatan'],
            'gambar_user': profile['gambar_user'],
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  void _showAssigneePicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _KtsAssigneePickerSheet(lang: widget.lang, currentUserId: _selectedAssignee?['id_user']?.toString()),
    );
    if (result != null) setState(() => _selectedAssignee = result);
  }

  void _populateData() {
    final d = widget.existingData!;
    _noOrderCtrl.text = d['no_order'] ?? '';
    _judulCtrl.text = d['judul_temuan'] ?? '';
    _descCtrl.text = d['deskripsi_temuan']?.toString() ?? '';
    _qtyCtrl.text = (d['jumlah_item'] ?? 1).toString();
    _existingImageUrl = d['gambar_temuan'];
    _itemSearchCtrl.text = d['nama_item_manual'] ?? d['item_produksi']?['nama_item'] ?? '';
    if (d['penanggung_jawab'] != null) {
      _selectedAssignee = Map<String, dynamic>.from(d['penanggung_jawab']);
    } else if (d['id_penanggung_jawab'] != null) {
      _loadAssigneeById(d['id_penanggung_jawab'].toString());
    }
  }

  Future<void> _loadAssigneeById(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('User')
          .select('id_user, nama, jabatan!User_id_jabatan_fkey(nama_jabatan), gambar_user')
          .eq('id_user', userId)
          .single();
      if (mounted) setState(() => _selectedAssignee = data);
    } catch (e) {
      debugPrint('Error loading assignee: $e');
    }
  }

  @override
  void dispose() {
    _noOrderCtrl.dispose();
    _judulCtrl.dispose();
    _descCtrl.dispose();
    _itemSearchCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 20), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            Text(
              widget.lang == 'EN' ? 'Add Evidence Photo' : widget.lang == 'ZH' ? '添加证据照片' : 'Tambah Foto Bukti',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 20),
            // CAMERA OPTION
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                XFile? img;
                if (kIsWeb) {
                  img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                } else {
                  img = await _openKtsCameraScreen();
                }
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder, width: 1.5)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)), child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 22)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lang == 'EN' ? 'Take Photo' : widget.lang == 'ZH' ? '拍照' : 'Ambil Foto', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B))),
                        Text(widget.lang == 'EN' ? 'Open camera directly' : widget.lang == 'ZH' ? '直接打开相机' : 'Buka kamera langsung', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right, size: 16, color: _kPrimary),
                  ],
                ),
              ),
            ),
            // GALLERY OPTION
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (img != null && mounted) setState(() => _imageFile = img);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder, width: 1.5)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(12)), child: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, color: _kPrimary, size: 22)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lang == 'EN' ? 'Choose from Gallery' : widget.lang == 'ZH' ? '从相册选择' : 'Pilih dari Galeri', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B))),
                        Text(widget.lang == 'EN' ? 'Select existing photo' : widget.lang == 'ZH' ? '选择现有照片' : 'Pilih foto yang sudah ada', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                    const Spacer(),
                    const Icon(CupertinoIcons.chevron_right, size: 16, color: _kPrimary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(t['cancel']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF64748B)))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<XFile?> _openKtsCameraScreen() async {
    if (kIsWeb) return null;
    return await Navigator.push<XFile?>(context, MaterialPageRoute(builder: (_) => const KtsCameraScreen()));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: CupertinoColors.destructiveRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _submit() async {
    if (_noOrderCtrl.text.trim().isEmpty) return _showError(t['err_order']!);
    if (_judulCtrl.text.trim().isEmpty) return _showError(t['err_judul']!);
    if (_itemSearchCtrl.text.trim().isEmpty) return _showError(t['err_item']!);

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName = '${user.id}/kts_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('temuan_images').uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
        imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);
      }

      final data = {
        'no_order': _noOrderCtrl.text.trim(),
        'judul_temuan': _judulCtrl.text.trim(),
        'id_subkategoritemuan_uuid': null,
        'id_kategoritemuan_uuid': null,
        'id_item': null,
        'nama_item_manual': _itemSearchCtrl.text.trim(),
        'id_penanggung_jawab': _selectedAssignee?['id_user'],
        'jumlah_item': int.tryParse(_qtyCtrl.text.trim()) ?? 1,
        'gambar_temuan': imageUrl,
        'deskripsi_temuan': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'jenis_temuan': 'KTS Production',
        'poin_temuan': 20,
        'status_temuan': 'Belum',
      };

      if (_isEdit) {
        final updateData = Map<String, dynamic>.from(data);
        updateData.remove('jenis_temuan');
        updateData.remove('poin_temuan');
        updateData.remove('status_temuan');
        await supabase.from('temuan').update(updateData).eq('id_temuan', widget.existingData!['id_temuan']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['success_edit']!), backgroundColor: CupertinoColors.activeGreen));
          Navigator.pop(context, true);
        }
      } else {
        await supabase.from('temuan').insert({...data, 'id_user': user.id});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['success']!), backgroundColor: CupertinoColors.activeGreen));
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('KTS submit error: $e');
      if (mounted) {
        _showError('${t['fail']!}: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(CupertinoIcons.back, color: _kPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? t['edit_title']! : t['create_title']!, style: GoogleFonts.inter(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: _kBorder, height: 1)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(children: [
                  _buildLabel(t['no_order']!, isRequired: true),
                  _buildTextField(_noOrderCtrl, t['no_order_hint']!, CupertinoIcons.number),
                  const SizedBox(height: 20),
                  _buildLabel(t['judul']!, isRequired: true),
                  _buildTextField(_judulCtrl, t['judul_hint']!, CupertinoIcons.text_cursor),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(t['item']!, isRequired: true),
                            _buildTextField(_itemSearchCtrl, t['item_hint']!, CupertinoIcons.cube_box),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(t['qty']!, isRequired: true),
                            _buildQtyField(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(widget.lang == 'ZH' ? '负责人' : widget.lang == 'EN' ? 'Person in Charge' : 'Penanggung Jawab', isRequired: false),
                  _buildTapField(icon: CupertinoIcons.person_fill, text: _selectedAssignee?['nama'] ?? (widget.lang == 'ZH' ? '选择负责人' : widget.lang == 'EN' ? 'Select PIC' : 'Pilih Penanggung Jawab'), hasValue: _selectedAssignee != null, onTap: _showAssigneePicker),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['photo']!, isRequired: false),
                  _buildPhotoWidget(),
                ]),
                const SizedBox(height: 16),
                _buildSectionCard(children: [
                  _buildLabel(t['desc']!, isRequired: false),
                  _buildTextField(_descCtrl, t['desc_hint']!, CupertinoIcons.doc_text, maxLines: 4),
                ]),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isSaving) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha:0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(_isEdit ? t['update']! : t['submit']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha:0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF475569))),
          if (isRequired) const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
        prefixIcon: maxLines == 1 ? Icon(icon, color: _kPrimary, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTapField({required IconData icon, required String text, required VoidCallback onTap, bool hasValue = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? _kPrimary : _kBorder, width: hasValue ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasValue ? _kPrimary : const Color(0xFFCBD5E1), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 15, color: hasValue ? Colors.black87 : const Color(0xFFCBD5E1), fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal))),
            const Icon(CupertinoIcons.chevron_down, color: _kPrimary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              final current = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
              if (current > 1) {
                _qtyCtrl.text = (current - 1).toString();
              }
            },
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: SizedBox(
              width: 44,
              height: 52,
              child: Center(child: Icon(CupertinoIcons.minus, size: 16, color: _kPrimary)),
            ),
          ),
          Container(width: 1, height: 28, color: _kBorder),
          Expanded(
            child: TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed < 1) {
                  _qtyCtrl.text = '1';
                  _qtyCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _qtyCtrl.text.length),
                  );
                }
              },
            ),
          ),
          Container(width: 1, height: 28, color: _kBorder),
          InkWell(
            onTap: () {
              final current = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
              _qtyCtrl.text = (current + 1).toString();
            },
            borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
            child: SizedBox(
              width: 44,
              height: 52,
              child: const Center(child: Icon(CupertinoIcons.add, size: 16, color: _kPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget() {
    final hasPhoto = _imageFile != null || _existingImageUrl != null;
    if (!hasPhoto) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder, width: 1.5)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle), child: const Icon(CupertinoIcons.camera, color: _kPrimary, size: 28)),
              const SizedBox(height: 12),
              Text(t['add_photo']!, style: GoogleFonts.inter(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imageFile != null
              ? (kIsWeb
                  ? Image.network(_imageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(_imageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover))
              : Image.network(_existingImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          right: 12, bottom: 12,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.6), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.camera_rotate, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(widget.lang == 'EN' ? 'Retake' : 'Ganti', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha:0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha:0.2), blurRadius: 30, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha:0.4), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(CupertinoIcons.hammer_fill, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const CupertinoActivityIndicator(radius: 12, color: _kPrimary),
              const SizedBox(height: 14),
              Text(t['saving']!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text(
                _isEdit
                    ? (widget.lang == 'EN' ? 'Updating your report...' : widget.lang == 'ZH' ? '正在更新报告...' : 'Memperbarui laporan Anda...')
                    : (widget.lang == 'EN' ? 'Uploading & saving report...' : widget.lang == 'ZH' ? '正在上传并保存...' : 'Mengunggah & menyimpan laporan...'),
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.star_fill, color: _kPrimary, size: 16),
                      const SizedBox(width: 6),
                      Text(widget.lang == 'EN' ? 'You will earn +20 points!' : widget.lang == 'ZH' ? '您将获得+20积分！' : 'Anda akan mendapat +20 poin!', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class KtsCameraScreen extends StatefulWidget {
  const KtsCameraScreen({super.key});
  @override
  State<KtsCameraScreen> createState() => _KtsCameraScreenState();
}

class _KtsCameraScreenState extends State<KtsCameraScreen> with WidgetsBindingObserver {
  CameraController? _ctrl;
  List<CameraDescription>? _cameras;
  int _camIndex = 0;
  bool _ready = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _ctrl!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _init() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) await _setCamera(_camIndex);
  }

  Future<void> _setCamera(int i) async {
    await _ctrl?.dispose();
    _ctrl = CameraController(_cameras![i], ResolutionPreset.high, enableAudio: false);
    try {
      await _ctrl!.initialize();
      if (mounted) setState(() => _ready = true);
    } on CameraException catch (e) {
      debugPrint('Camera error: ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 16)));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_ctrl!)),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black.withValues(alpha:0.4),
                child: Row(children: [
                  IconButton(icon: const Icon(CupertinoIcons.back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  Expanded(child: Center(child: Text('FOTO KTS', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
                  const SizedBox(width: 48),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (img != null && mounted) Navigator.pop(context, img);
                  },
                  child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle), child: const Icon(CupertinoIcons.photo, color: Colors.white)),
                ),
                // CAPTURE BUTTON
                GestureDetector(
                  onTap: () async {
                    if (_ctrl == null || _ctrl!.value.isTakingPicture) return;
                    try {
                      final pic = await _ctrl!.takePicture();
                      if (mounted) Navigator.pop(context, pic);
                    } on CameraException catch (e) {
                      debugPrint('Snap error: ${e.code}');
                    }
                  },
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    child: Padding(padding: const EdgeInsets.all(4), child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                  ),
                ),
                // SWITCH CAMERA
                GestureDetector(
                  onTap: () {
                    if (_cameras == null || _cameras!.length < 2) return;
                    setState(() { _ready = false; _camIndex = (_camIndex + 1) % _cameras!.length; });
                    _setCamera(_camIndex);
                  },
                  child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle), child: const Icon(CupertinoIcons.switch_camera, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KtsAssigneePickerSheet extends StatefulWidget {
  final String lang;
  final String? currentUserId;
  const _KtsAssigneePickerSheet({required this.lang, this.currentUserId});

  @override
  State<_KtsAssigneePickerSheet> createState() => _KtsAssigneePickerSheetState();
}

class _KtsAssigneePickerSheetState extends State<_KtsAssigneePickerSheet> {
  static const Color _kPrimary      = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight = Color(0xFFEFF6FF);
  static const Color _kBorder       = Color(0xFFBFDBFE);

  List<Map<String, dynamic>> _lokasiList = [];
  List<Map<String, dynamic>> _unitList = [];
  List<Map<String, dynamic>> _subunitList = [];
  List<Map<String, dynamic>> _areaList = [];

  String? _selLokasiId;
  String? _selUnitId;
  String? _selSubunitId;
  String? _selAreaId;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoadingLocations = true;
  bool _isLoadingUsers = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadLocations();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await Supabase.instance.client.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
      if (mounted) setState(() { _lokasiList = List<Map<String, dynamic>>.from(data); _isLoadingLocations = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUnit(String lokasiId) async {
    final res = await Supabase.instance.client.from('unit').select('id_unit, nama_unit').eq('id_lokasi', lokasiId).order('nama_unit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchSubunit(String unitId) async {
    final res = await Supabase.instance.client.from('subunit').select('id_subunit, nama_subunit').eq('id_unit', unitId).order('nama_subunit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchArea(String subunitId) async {
    final res = await Supabase.instance.client.from('area').select('id_area, nama_area').eq('id_subunit', subunitId).order('nama_area');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _loadUsers({String? lokasiId, String? unitId, String? subunitId, String? areaId}) async {
    setState(() => _isLoadingUsers = true);
    try {
      dynamic query = Supabase.instance.client.from('User').select('id_user, nama, jabatan!User_id_jabatan_fkey(nama_jabatan), gambar_user');
      if (areaId != null) { query = query.eq('id_area', areaId); }
      else if (subunitId != null) { query = query.eq('id_subunit', subunitId); }
      else if (unitId != null) { query = query.eq('id_unit', unitId); }
      else if (lokasiId != null) { query = query.eq('id_lokasi', lokasiId); }

      final data = await query.order('nama');
      List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(data);

      if (widget.currentUserId != null) {
        users.sort((a, b) {
          if (a['id_user'] == widget.currentUserId) return -1;
          if (b['id_user'] == widget.currentUserId) return 1;
          return (a['nama'] as String).compareTo(b['nama'] as String);
        });
      }

      if (mounted) setState(() { _allUsers = users; _filteredUsers = users; _isLoadingUsers = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() { _filteredUsers = _allUsers.where((u) => u['nama'].toString().toLowerCase().contains(q)).toList(); });
  }

  void _applyFilter() => _loadUsers(lokasiId: _selLokasiId, unitId: _selUnitId, subunitId: _selSubunitId, areaId: _selAreaId);

  Widget _buildFilterChips({required String label, required IconData icon, required List<Map<String, dynamic>> items, required String idKey, required String nameKey, required String? selectedId, required Function(String id) onSelect}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 13, color: _kPrimary), const SizedBox(width: 6), Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) {
            final id = item[idKey].toString();
            final name = item[nameKey] as String;
            final isSelected = selectedId == id;
            return GestureDetector(
              onTap: () => onSelect(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? _kPrimary : _kBorder),
                  boxShadow: isSelected ? [BoxShadow(color: _kPrimary.withValues(alpha:0.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF1E293B))),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(CupertinoIcons.person_2_fill, color: _kPrimary, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.lang == 'ZH' ? '选择负责人' : widget.lang == 'EN' ? 'Select Person in Charge' : 'Pilih Penanggung Jawab', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
              IconButton(icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF94A3B8), size: 20), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Container(
            color: const Color(0xFFF8FAFF),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(CupertinoIcons.location, size: 14, color: _kPrimary),
                  const SizedBox(width: 6),
                  Text(widget.lang == 'EN' ? 'Filter Location' : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  const Spacer(),
                  if (_selLokasiId != null)
                    GestureDetector(
                      onTap: () {
                        setState(() { _selLokasiId = null; _selUnitId = null; _selSubunitId = null; _selAreaId = null; _unitList = []; _subunitList = []; _areaList = []; });
                        _loadUsers();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kPrimary.withValues(alpha:0.3))),
                        child: Text(widget.lang == 'EN' ? 'Reset' : 'Reset', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                _isLoadingLocations
                    ? const CupertinoActivityIndicator()
                    : _buildFilterChips(
                        label: widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi',
                        icon: CupertinoIcons.building_2_fill,
                        items: _lokasiList,
                        idKey: 'id_lokasi', nameKey: 'nama_lokasi',
                        selectedId: _selLokasiId,
                        onSelect: (id) async {
                          final units = await _fetchUnit(id);
                          setState(() { _selLokasiId = id; _selUnitId = null; _selSubunitId = null; _selAreaId = null; _unitList = units; _subunitList = []; _areaList = []; });
                          _applyFilter();
                        },
                      ),
                if (_selLokasiId != null && _unitList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFilterChips(label: 'Unit', icon: CupertinoIcons.squares_below_rectangle, items: _unitList, idKey: 'id_unit', nameKey: 'nama_unit', selectedId: _selUnitId, onSelect: (id) async {
                    final subs = await _fetchSubunit(id);
                    setState(() { _selUnitId = id; _selSubunitId = null; _selAreaId = null; _subunitList = subs; _areaList = []; });
                    _applyFilter();
                  }),
                ],
                if (_selUnitId != null && _subunitList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFilterChips(label: 'Sub-Unit', icon: CupertinoIcons.layers_alt_fill, items: _subunitList, idKey: 'id_subunit', nameKey: 'nama_subunit', selectedId: _selSubunitId, onSelect: (id) async {
                    final areas = await _fetchArea(id);
                    setState(() { _selSubunitId = id; _selAreaId = null; _areaList = areas; });
                    _applyFilter();
                  }),
                ],
                if (_selSubunitId != null && _areaList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFilterChips(label: 'Area', icon: CupertinoIcons.location_fill, items: _areaList, idKey: 'id_area', nameKey: 'nama_area', selectedId: _selAreaId, onSelect: (id) { setState(() => _selAreaId = id); _applyFilter(); }),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xFFE0E7FF), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextFormField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.lang == 'ZH' ? '搜索成员...' : widget.lang == 'EN' ? 'Search member...' : 'Cari anggota...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14),
                prefixIcon: const Icon(CupertinoIcons.search, color: _kPrimary, size: 18),
                filled: true, fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(children: [
              const Icon(CupertinoIcons.person_2, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text('${_filteredUsers.length} ${widget.lang == 'EN' ? 'members' : 'anggota'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            ]),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 12),
          Expanded(
            child: _isLoadingUsers
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredUsers.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(CupertinoIcons.person_crop_circle_badge_xmark, size: 48, color: Color(0xFFE2E8F0)), const SizedBox(height: 12), Text(widget.lang == 'EN' ? 'No users found' : 'Tidak ada pengguna', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14))]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (_, i) {
                          final user = _filteredUsers[i];
                          final isMe = user['id_user'] == widget.currentUserId;
                          final String name = user['nama'] ?? '';
                          final String role = user['jabatan']?['nama_jabatan'] ?? '';
                          final String? avatarUrl = user['gambar_user'];
                          final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(context, user),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isMe ? _kPrimaryLight : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isMe ? _kPrimary.withValues(alpha:0.25) : const Color(0xFFF1F5F9)),
                                ),
                                child: Row(children: [
                                  Stack(children: [
                                    CircleAvatar(radius: 22, backgroundColor: _kPrimaryLight, backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null, child: avatarUrl == null ? Text(initial, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold)) : null),
                                    if (isMe)
                                      Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 10))),
                                  ]),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B)))),
                                        if (isMe)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                                            child: Text(widget.lang == 'EN' ? 'Me' : 'Saya', style: GoogleFonts.inter(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w700)),
                                          ),
                                      ]),
                                      if (role.isNotEmpty) Text(role, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                                    ],
                                  )),
                                  const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}