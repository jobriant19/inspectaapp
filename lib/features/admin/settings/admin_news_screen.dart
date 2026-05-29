import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/account/news_detail_screen.dart';

class AdminNewsScreen extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialData; 
  const AdminNewsScreen({super.key, required this.lang, this.initialData});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  static const _bg = Color(0xFFF8FAFC);
  static const _primary = Color(0xFFF59E0B);

  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = widget.initialData!;
      _isLoading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('latest_news')
          .select()
          .order('published_at', ascending: false);
      if (mounted) {
        setState(() {
          _data = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterType == 'all') return _data;
    return _data
        .where((d) => (d['type'] ?? '').toLowerCase() == _filterType)
        .toList();
  }

  List<Map<String, dynamic>> get _filteredWithSearch {
    final base = _filtered;
    if (_searchQuery.trim().isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base.where((d) {
      final titleId = (d['title_id'] ?? '').toString().toLowerCase();
      final titleEn = (d['title_en'] ?? '').toString().toLowerCase();
      final titleZh = (d['title_zh'] ?? '').toString().toLowerCase();
      final contentId = (d['content_id'] ?? '').toString().toLowerCase();
      return titleId.contains(q) ||
          titleEn.contains(q) ||
          titleZh.contains(q) ||
          contentId.contains(q);
    }).toList();
  }

  Future<String?> _uploadImageBytes(Uint8List bytes, String ext) async {
    try {
      final fileName = 'news_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Supabase.instance.client.storage
          .from('news-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
              upsert: true,
            ),
          );
      final url = Supabase.instance.client.storage
          .from('news-images')
          .getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;

    final titleIdCtrl  = TextEditingController(text: item?['title_id'] ?? '');
    final titleEnCtrl  = TextEditingController(text: item?['title_en'] ?? '');
    final titleZhCtrl  = TextEditingController(text: item?['title_zh'] ?? '');
    final contentIdCtrl = TextEditingController(text: item?['content_id'] ?? '');
    final contentEnCtrl = TextEditingController(text: item?['content_en'] ?? '');
    final contentZhCtrl = TextEditingController(text: item?['content_zh'] ?? '');
    final durationCtrl = TextEditingController(
      text: (item?['display_duration_days'] ?? 7).toString(),
    );

    String selectedType =
        (item?['type'] ?? 'update').toString().toLowerCase();
    DateTime selectedDate = item?['published_at'] != null
        ? DateTime.tryParse(item!['published_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    Uint8List? pickedImageBytes;
    String? pickedImageExt;
    String? existingImageUrl = item?['image_url'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                        color: _primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.campaign_outlined, color: _primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit
                            ? (widget.lang == 'EN' ? 'Edit News' : 'Edit Berita')
                            : (widget.lang == 'EN' ? 'Add News' : 'Tambah Berita'),
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
                        child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 14),

                // ── Tipe ──
                _dlgLabel(widget.lang == 'EN' ? 'Type' : 'Tipe'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _typeChip('update', selectedType, (v) => setDlg(() => selectedType = v)),
                    const SizedBox(width: 10),
                    _typeChip('maintenance', selectedType, (v) => setDlg(() => selectedType = v)),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Tanggal publish ──
                _dlgLabel(widget.lang == 'EN' ? 'Published Date' : 'Tanggal Tayang'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: _primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setDlg(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Colors.black38, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1E3A8A), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Durasi Tampil Popup ──
                _dlgLabel(widget.lang == 'EN'
                    ? 'Popup Display Duration (days)'
                    : 'Durasi Tampil Popup (hari)'),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Tombol kurang
                      GestureDetector(
                        onTap: () {
                          final current = int.tryParse(durationCtrl.text) ?? 7;
                          if (current > 1) {
                            setDlg(() => durationCtrl.text = (current - 1).toString());
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Icon(Icons.remove_rounded,
                              color: _primary, size: 20),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: durationCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1E3A8A),
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      // Tombol tambah
                      GestureDetector(
                        onTap: () {
                          final current = int.tryParse(durationCtrl.text) ?? 7;
                          setDlg(() => durationCtrl.text = (current + 1).toString());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Icon(Icons.add_rounded, color: _primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Text(
                    widget.lang == 'EN'
                        ? 'News will appear in popup for this many days after published date'
                        : 'Berita akan muncul di popup selama ini sejak tanggal tayang',
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade500, fontSize: 10.5),
                  ),
                ),
                const SizedBox(height: 14),

                // ── PILIH GAMBAR DARI GALERI (Web-compatible) ──
                _dlgLabel('Image (${widget.lang == 'EN' ? 'optional' : 'opsional'})'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 1200,
                    );
                    if (picked != null) {
                      // Baca sebagai bytes agar kompatibel Web & Mobile
                      final bytes = await picked.readAsBytes();
                      final ext = picked.name.split('.').last.toLowerCase();
                      setDlg(() {
                        pickedImageBytes = bytes;
                        pickedImageExt = ext == 'png' ? 'png' : 'jpg';
                        existingImageUrl = null;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 130),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: pickedImageBytes != null || existingImageUrl != null
                            ? _primary.withOpacity(0.5)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: pickedImageBytes != null
                        // ✅ Gunakan Image.memory (bytes) — kompatibel Web & Mobile
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Stack(
                              children: [
                                Image.memory(
                                  pickedImageBytes!,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit_rounded,
                                            color: Colors.white, size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.lang == 'EN' ? 'Change' : 'Ganti',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setDlg(() {
                                      pickedImageBytes = null;
                                      pickedImageExt = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      existingImageUrl!,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _imagePlaceholder(),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.edit_rounded,
                                                color: Colors.white, size: 13),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.lang == 'EN' ? 'Change' : 'Ganti',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setDlg(() {
                                          existingImageUrl = null;
                                          pickedImageBytes = null;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade400,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _imagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Tab konten 3 bahasa ──
                _LangContentForm(
                  lang: widget.lang,
                  titleIdCtrl: titleIdCtrl,
                  titleEnCtrl: titleEnCtrl,
                  titleZhCtrl: titleZhCtrl,
                  contentIdCtrl: contentIdCtrl,
                  contentEnCtrl: contentEnCtrl,
                  contentZhCtrl: contentZhCtrl,
                ),
                const SizedBox(height: 20),

                // ── Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          widget.lang == 'EN' ? 'Cancel' : 'Batal',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleIdCtrl.text.trim().isEmpty ||
                              titleEnCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          await _saveNews(
                            existing: item,
                            type: selectedType,
                            publishedAt: selectedDate,
                            titleId: titleIdCtrl.text.trim(),
                            titleEn: titleEnCtrl.text.trim(),
                            titleZh: titleZhCtrl.text.trim(),
                            contentId: contentIdCtrl.text.trim(),
                            contentEn: contentEnCtrl.text.trim(),
                            contentZh: contentZhCtrl.text.trim(),
                            imageBytes: pickedImageBytes,
                            imageExt: pickedImageExt,
                            existingImageUrl: existingImageUrl,
                            displayDurationDays:
                                int.tryParse(durationCtrl.text) ?? 7,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: Text(
                          widget.lang == 'EN' ? 'Save' : 'Simpan',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.w600),
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

  Widget _imagePlaceholder() {
    return SizedBox(
      height: 130,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: Colors.grey.shade400, size: 38),
          const SizedBox(height: 8),
          Text(
            widget.lang == 'EN'
                ? 'Tap to choose image from gallery'
                : 'Ketuk untuk pilih gambar dari galeri',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type, String selected, ValueChanged<String> onTap) {
    final isActive = type == selected;
    final color =
        type == 'update' ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);
    final icon =
        type == 'update' ? Icons.update_rounded : Icons.build_rounded;
    final label = type == 'update' ? 'Update' : 'Maintenance';

    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: isActive ? 0 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                  color: isActive ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNews({
    required Map<String, dynamic>? existing,
    required String type,
    required DateTime publishedAt,
    required String titleId,
    required String titleEn,
    required String titleZh,
    required String contentId,
    required String contentEn,
    required String contentZh,
    Uint8List? imageBytes,
    String? imageExt,
    String? existingImageUrl,
    required int displayDurationDays,
  }) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                widget.lang == 'EN' ? 'Saving...' : 'Menyimpan...',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 10),
        ),
      );
    }

    String? finalImageUrl = existingImageUrl;

    // Upload gambar baru jika ada
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final uploaded = await _uploadImageBytes(imageBytes, imageExt ?? 'jpg');
      if (uploaded != null) {
        finalImageUrl = uploaded;
      } else {
        if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showResultDialog(
          isSuccess: false,
          message: widget.lang == 'EN'
              ? 'Image upload failed.\nPlease check your storage bucket settings.'
              : 'Upload gambar gagal.\nPeriksa pengaturan bucket storage Anda.',
        );
        return;
      }
    }

    // Build payload — JANGAN sertakan 'id' di sini
    final payload = <String, dynamic>{
      'type': type,
      'published_at':
          '${publishedAt.year}-${publishedAt.month.toString().padLeft(2, '0')}-${publishedAt.day.toString().padLeft(2, '0')}',
      'title_id': titleId,
      'title_en': titleEn,
      'title_zh': titleZh,
      'content_id': contentId,
      'content_en': contentEn,
      'content_zh': contentZh,
      'display_duration_days': displayDurationDays,
    };

    // Hanya masukkan image_url jika nilainya tidak null
    // (jika null berarti gambar dihapus oleh user, set ke null eksplisit)
    payload['image_url'] = finalImageUrl;

    try {
      if (existing == null) {
        // INSERT
        final insertResult = await Supabase.instance.client
            .from('latest_news')
            .insert(payload)
            .select(); // tambah .select() agar dapat response
        debugPrint('INSERT result: $insertResult');
      } else {
        // UPDATE — pastikan ID-nya benar
        final recordId = existing['id'];
        debugPrint('UPDATE id=$recordId payload=$payload');
        final updateResult = await Supabase.instance.client
            .from('latest_news')
            .update(payload)
            .eq('id', recordId)
            .select(); // tambah .select() agar dapat response
        debugPrint('UPDATE result: $updateResult');
      }

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      _showResultDialog(
        isSuccess: true,
        message: existing == null
            ? (widget.lang == 'EN'
                ? 'New article has been added successfully.'
                : widget.lang == 'ZH'
                    ? '新文章已成功添加。'
                    : 'Berita baru berhasil ditambahkan.')
            : (widget.lang == 'EN'
                ? 'Article has been updated successfully.'
                : widget.lang == 'ZH'
                    ? '文章已成功更新。'
                    : 'Berita berhasil diperbarui.'),
      );

      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      debugPrint('SAVE ERROR: $e');
      _showResultDialog(
        isSuccess: false,
        message: widget.lang == 'EN'
            ? 'Failed to save article.\n${e.toString()}'
            : widget.lang == 'ZH'
                ? '保存文章失败。\n${e.toString()}'
                : 'Gagal menyimpan berita.\n${e.toString()}',
      );
    }
  }

  Future<void> _deleteNews(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEB), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: Color(0xFFEF4444), size: 38),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.lang == 'EN'
                        ? 'Delete News?'
                        : widget.lang == 'ZH'
                            ? '删除新闻？'
                            : 'Hapus Berita?',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lang == 'EN'
                        ? 'This action cannot be undone.'
                        : widget.lang == 'ZH'
                            ? '此操作无法撤销。'
                            : 'Tindakan ini tidak dapat dibatalkan.',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: Colors.white, size: 18),
                      label: Text(
                        widget.lang == 'EN'
                            ? 'Delete'
                            : widget.lang == 'ZH'
                                ? '删除'
                                : 'Hapus',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE2E8F0), width: 1.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        widget.lang == 'EN'
                            ? 'Cancel'
                            : widget.lang == 'ZH'
                                ? '取消'
                                : 'Batal',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await Supabase.instance.client
          .from('latest_news')
          .delete()
          .eq('id', id);
      _showSnack(widget.lang == 'EN' ? 'Deleted.' : 'Dihapus.');
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
        foregroundColor: const Color(0xFFF59E0B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lang == 'EN' ? 'Latest News' : 'Kabar Terbaru',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFFF59E0B)),
        ),
      ),
      body: Column(
        children: [
          // ── Banner Add ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: () => _showFormDialog(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primary, _primary.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.lang == 'EN'
                                ? 'Add New Article'
                                : widget.lang == 'ZH'
                                    ? '添加新文章'
                                    : 'Tambah Berita Baru',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                          Text(
                            widget.lang == 'EN'
                                ? 'Tap to add a new article'
                                : widget.lang == 'ZH'
                                    ? '点击以添加新文章'
                                    : 'Ketuk untuk menambah berita baru',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.85)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          // ── Search ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.lang == 'EN'
                      ? 'Search news...'
                      : widget.lang == 'ZH'
                          ? '搜索新闻...'
                          : 'Cari berita...',
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // ── Filter ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Expanded(
                    child: _filterPill(
                        'all',
                        widget.lang == 'EN'
                            ? 'All'
                            : widget.lang == 'ZH'
                                ? '全部'
                                : 'Semua',
                        Colors.black54,
                        Icons.list_rounded)),
                const SizedBox(width: 8),
                Expanded(
                    child: _filterPill('update', 'Update',
                        const Color(0xFF6366F1), Icons.update_rounded)),
                const SizedBox(width: 8),
                Expanded(
                    child: _filterPill(
                        'maintenance',
                        widget.lang == 'EN' ? 'Maint.' : 'Maint.',
                        const Color(0xFFF59E0B),
                        Icons.build_rounded)),
              ],
            ),
          ),
          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredWithSearch.length} ${widget.lang == 'EN' ? 'articles' : widget.lang == 'ZH' ? '篇文章' : 'berita'}',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 12),
              ),
            ),
          ),
          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filteredWithSearch.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.campaign_outlined,
                                size: 56, color: Colors.black12),
                            const SizedBox(height: 12),
                            Text(
                              widget.lang == 'EN'
                                  ? 'No news yet'
                                  : widget.lang == 'ZH'
                                      ? '暂无新闻'
                                      : 'Belum ada berita',
                              style: GoogleFonts.poppins(
                                  color: Colors.black38),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _primary,
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: _filteredWithSearch.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _buildNewsCard(_filteredWithSearch[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(
      String type, String label, Color color, IconData icon) {
    final isActive = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isActive ? color : color.withOpacity(0.35),
              width: 1.5),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                    color: isActive ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString().toLowerCase();
    final isUpdate = type == 'update';
    final color = isUpdate
        ? const Color(0xFF6366F1)
        : const Color(0xFFF59E0B);
    final icon =
        isUpdate ? Icons.update_rounded : Icons.build_rounded;

    final String titleKey = widget.lang == 'ZH'
        ? 'title_zh'
        : widget.lang == 'EN'
            ? 'title_en'
            : 'title_id';
    final String contentKey = widget.lang == 'ZH'
        ? 'content_zh'
        : widget.lang == 'EN'
            ? 'content_en'
            : 'content_id';

    final date = item['published_at']?.toString() ?? '';
    final String? imageUrl = item['image_url'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsDetailScreen(item: item, lang: widget.lang),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail gambar (jika ada) ──
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item[titleKey] ?? '-',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                isUpdate ? 'Update' : 'Maintenance',
                                style: GoogleFonts.poppins(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.calendar_today_rounded,
                                size: 11, color: Colors.black38),
                            const SizedBox(width: 3),
                            Text(date,
                                style: GoogleFonts.poppins(
                                    color: Colors.black38, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _iconBtn(Icons.edit_outlined,
                          const Color(0xFF6366F1),
                          () => _showFormDialog(item: item)),
                      const SizedBox(height: 6),
                      _iconBtn(Icons.delete_outline_rounded,
                          const Color(0xFFEF4444),
                          () => _deleteNews(item['id'])),
                    ],
                  ),
                ],
              ),
            ),
            if ((item[contentKey] ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 8),
                    Text(
                      item[contentKey] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 100,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _dlgLabel(String label) => Text(
        label,
        style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3),
      );

  // ─────────────────────────────────────────────
  // POP UP NOTIFIKASI TENGAH LAYAR (berhasil/gagal)
  // ─────────────────────────────────────────────
  void _showResultDialog({required bool isSuccess, required String message}) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'result',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        // Auto close setelah 2.5 detik
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });

        final Color primary =
            isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        final Color bgLight =
            isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
        final IconData icon =
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
        final String title = isSuccess
            ? (widget.lang == 'EN'
                ? 'Success!'
                : widget.lang == 'ZH'
                    ? '成功！'
                    : 'Berhasil!')
            : (widget.lang == 'EN'
                ? 'Failed!'
                : widget.lang == 'ZH'
                    ? '失败！'
                    : 'Gagal!');

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Ikon lingkaran ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: bgLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: primary.withOpacity(0.25), width: 2),
                    ),
                    child: Icon(icon, color: primary, size: 44),
                  ),
                  const SizedBox(height: 18),
                  // ── Judul ──
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Pesan ──
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Progress bar auto-close ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2500),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: primary.withOpacity(0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primary.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ── Helper widget form konten 3 bahasa (TIDAK BERUBAH) ──
class _LangContentForm extends StatefulWidget {
  final String lang;
  final TextEditingController titleIdCtrl;
  final TextEditingController titleEnCtrl;
  final TextEditingController titleZhCtrl;
  final TextEditingController contentIdCtrl;
  final TextEditingController contentEnCtrl;
  final TextEditingController contentZhCtrl;

  const _LangContentForm({
    required this.lang,
    required this.titleIdCtrl,
    required this.titleEnCtrl,
    required this.titleZhCtrl,
    required this.contentIdCtrl,
    required this.contentEnCtrl,
    required this.contentZhCtrl,
  });

  @override
  State<_LangContentForm> createState() => _LangContentFormState();
}

class _LangContentFormState extends State<_LangContentForm>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _langs = [
    {'code': 'ID', 'flag': '🇮🇩', 'label': 'Indonesia'},
    {'code': 'EN', 'flag': '🇺🇸', 'label': 'English'},
    {'code': 'ZH', 'flag': '🇨🇳', 'label': '中文'},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  TextEditingController _titleCtrl(int i) =>
      [widget.titleIdCtrl, widget.titleEnCtrl, widget.titleZhCtrl][i];

  TextEditingController _contentCtrl(int i) =>
      [widget.contentIdCtrl, widget.contentEnCtrl, widget.contentZhCtrl][i];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.lang == 'EN' ? 'Content per Language' : 'Konten per Bahasa',
          style: GoogleFonts.poppins(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10)),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black45,
            labelPadding: EdgeInsets.zero,
            tabs: _langs
                .map((l) => Tab(
                      child: Text('${l['flag']} ${l['code']}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: TabBarView(
            controller: _tab,
            children: List.generate(3, (i) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldBox(_titleCtrl(i), Icons.title_rounded,
                      maxLines: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _fieldBox(
                        _contentCtrl(i), Icons.article_outlined,
                        maxLines: 5),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _fieldBox(TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
    return Container(
      height: maxLines == 1 ? 46 : null,
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
            color: const Color(0xFF1E3A8A), fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.black38, size: 16)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        ),
      ),
    );
  }
}