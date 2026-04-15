import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AccidentReportFormScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic>? initialData;

  const AccidentReportFormScreen({
    super.key,
    required this.lang,
    this.initialData,
  });

  @override
  State<AccidentReportFormScreen> createState() => _AccidentReportFormScreenState();
}

class _AccidentReportFormScreenState extends State<AccidentReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deskripsiController;
  final List<String> _kategoriOptions = ['Ringan', 'Sedang', 'Berat', 'Near Miss'];
  String? _selectedKategori;
  XFile? _selectedImage;
  bool _isLoading = false;
  bool get _isEditing => widget.initialData != null;

  final Map<String, Map<String, String>> _text = {
    'EN': {
      'add_title': 'Add Accident Report',
      'edit_title': 'Edit Accident Report',
      'photo': 'Accident Photo',
      'add_photo': 'Add Photo',
      'change_photo': 'Change Photo',
      'description': 'Description',
      'description_hint': 'Explain the incident in detail...',
      'category': 'Category',
      'category_hint': 'Select incident category',
      'save': 'Save Report',
      'saving': 'Saving...',
      'error': 'An error occurred',
      'success': 'Report saved successfully!',
      'validation_error': 'Please fill all required fields and add a photo.',
    },
    'ID': {
      'add_title': 'Tambah Laporan Kecelakaan',
      'edit_title': 'Ubah Laporan Kecelakaan',
      'photo': 'Foto Kecelakaan',
      'add_photo': 'Tambah Foto',
      'change_photo': 'Ubah Foto',
      'description': 'Deskripsi',
      'description_hint': 'Jelaskan insiden secara detail...',
      'category': 'Kategori',
      'category_hint': 'Pilih kategori insiden',
      'save': 'Simpan Laporan',
      'saving': 'Menyimpan...',
      'error': 'Terjadi kesalahan',
      'success': 'Laporan berhasil disimpan!',
      'validation_error': 'Harap isi semua kolom wajib dan tambahkan foto.',
    },
    'ZH': {
      'add_title': '添加事故报告',
      'edit_title': '编辑事故报告',
      'photo': '事故照片',
      'add_photo': '添加照片',
      'change_photo': '更换照片',
      'description': '描述',
      'description_hint': '详细说明事件...',
      'category': '类别',
      'category_hint': '选择事件类别',
      'save': '保存报告',
      'saving': '保存中...',
      'error': '发生错误',
      'success': '报告已成功保存！',
      'validation_error': '请填写所有必填字段并添加照片。',
    },
  };

  String getTxt(String key) => _text[widget.lang]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _deskripsiController = TextEditingController(text: widget.initialData?['deskripsi']);
    _selectedKategori = widget.initialData?['kategori'];
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Validasi tambahan: gambar harus ada saat membuat baru
    if (!_isEditing && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getTxt('validation_error')), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.initialData?['gambar_url'];
      final user = Supabase.instance.client.auth.currentUser;

      // 1. Upload gambar jika ada gambar baru (dimodifikasi untuk web & mobile)
      if (_selectedImage != null) {
        // --- MODIFIKASI UTAMA UNTUK UPLOAD ---
        // Baca file sebagai bytes agar kompatibel di semua platform
        final imageBytes = await _selectedImage!.readAsBytes();
        // Gunakan .name untuk mendapatkan nama file asli (lebih aman di web)
        final imageExtension = _selectedImage!.name.split('.').last.toLowerCase();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
        final filePath = '${user!.id}/$fileName';
        
        // Gunakan uploadBinary untuk mengunggah dari bytes
        await Supabase.instance.client.storage.from('accident_reports').uploadBinary(
              filePath,
              imageBytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: false,
                // Sertakan contentType untuk penanganan file yang lebih baik
                contentType: _selectedImage!.mimeType,
              ),
            );
        // ---------------------------------------
        imageUrl = Supabase.instance.client.storage.from('accident_reports').getPublicUrl(filePath);
      }
      
      final Map<String, dynamic> data = {
        'deskripsi': _deskripsiController.text,
        'kategori': _selectedKategori!,
        'gambar_url': imageUrl,
      };

      if (_isEditing) {
        // UPDATE
        await Supabase.instance.client.from('laporan_kecelakaan')
          .update(data)
          .eq('id', widget.initialData!['id']);
      } else {
        // INSERT
        data['id_user'] = user!.id;
        data['nama_pelapor'] = user.userMetadata?['full_name'] ?? 'User';
        await Supabase.instance.client.from('laporan_kecelakaan').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getTxt('success')), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Kirim sinyal sukses
      }

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${getTxt('error')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? getTxt('edit_title') : getTxt('add_title'), style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Text(getTxt('photo'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        // --- MODIFIKASI UTAMA UNTUK DISPLAY GAMBAR ---
                        ? (kIsWeb
                            ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                        // ---------------------------------------------
                        : (widget.initialData?['gambar_url'] != null
                            ? Image.network(widget.initialData!['gambar_url'], fit: BoxFit.cover)
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
                                    const SizedBox(height: 8),
                                    Text(getTxt('add_photo'), style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Category
              Text(getTxt('category'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                hint: Text(getTxt('category_hint')),
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: _kategoriOptions.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedKategori = newValue;
                  });
                },
                validator: (value) => value == null ? 'Kategori harus dipilih' : null,
              ),
              const SizedBox(height: 24),
              // Description
              Text(getTxt('description'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: getTxt('description_hint'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Deskripsi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF00C9E4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(getTxt('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}