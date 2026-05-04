import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminNewsScreen extends StatefulWidget {
  final String lang;
  const AdminNewsScreen({super.key, required this.lang});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  static const _bg = Color(0xFFF8FAFC);
  static const _primary = Color(0xFFF59E0B);

  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _filterType = 'all'; // 'all', 'update', 'maintenance'

  @override
  void initState() {
    super.initState();
    _load();
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

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;

    final titleIdCtrl  = TextEditingController(text: item?['title_id'] ?? '');
    final titleEnCtrl  = TextEditingController(text: item?['title_en'] ?? '');
    final titleZhCtrl  = TextEditingController(text: item?['title_zh'] ?? '');
    final contentIdCtrl = TextEditingController(text: item?['content_id'] ?? '');
    final contentEnCtrl = TextEditingController(text: item?['content_en'] ?? '');
    final contentZhCtrl = TextEditingController(text: item?['content_zh'] ?? '');
    final imageCtrl    = TextEditingController(text: item?['image_url'] ?? '');
    String selectedType =
        (item?['type'] ?? 'update').toString().toLowerCase();
    DateTime selectedDate = item?['published_at'] != null
        ? DateTime.tryParse(item!['published_at'].toString()) ?? DateTime.now()
        : DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                      child: Icon(Icons.campaign_outlined,
                          color: _primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit
                            ? (widget.lang == 'EN'
                                ? 'Edit News'
                                : 'Edit Berita')
                            : (widget.lang == 'EN'
                                ? 'Add News'
                                : 'Tambah Berita'),
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
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 14),

                // ── Tipe ──
                _dlgLabel(widget.lang == 'EN' ? 'Type' : 'Tipe'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _typeChip('update', selectedType, (v) {
                      setDlg(() => selectedType = v);
                    }),
                    const SizedBox(width: 10),
                    _typeChip('maintenance', selectedType, (v) {
                      setDlg(() => selectedType = v);
                    }),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Tanggal publish ──
                _dlgLabel(
                    widget.lang == 'EN' ? 'Published Date' : 'Tanggal Tayang'),
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
                          colorScheme: const ColorScheme.light(
                              primary: _primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setDlg(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: Colors.black38, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1E3A8A),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Image URL (opsional) ──
                _dlgLabel('Image URL (${widget.lang == 'EN' ? 'optional' : 'opsional'})'),
                const SizedBox(height: 6),
                _dlgField(imageCtrl, Icons.image_outlined, maxLines: 1),
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
                            imageUrl: imageCtrl.text.trim().isEmpty
                                ? null
                                : imageCtrl.text.trim(),
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
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _typeChip(
      String type, String selected, ValueChanged<String> onTap) {
    final isActive = type == selected;
    final color = type == 'update'
        ? const Color(0xFF6366F1)
        : const Color(0xFFF59E0B);
    final icon = type == 'update'
        ? Icons.update_rounded
        : Icons.build_rounded;
    final label = type == 'update'
        ? 'Update'
        : 'Maintenance';

    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: isActive ? 0 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
    String? imageUrl,
  }) async {
    final payload = {
      'type': type,
      'published_at':
          '${publishedAt.year}-${publishedAt.month.toString().padLeft(2, '0')}-${publishedAt.day.toString().padLeft(2, '0')}',
      'title_id': titleId,
      'title_en': titleEn,
      'title_zh': titleZh,
      'content_id': contentId,
      'content_en': contentEn,
      'content_zh': contentZh,
      'image_url': imageUrl,
    };
    try {
      if (existing == null) {
        await Supabase.instance.client.from('latest_news').insert(payload);
      } else {
        await Supabase.instance.client
            .from('latest_news')
            .update(payload)
            .eq('id', existing['id']);
      }
      _showSnack(widget.lang == 'EN' ? 'Saved!' : 'Tersimpan!');
      _load();
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteNews(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              widget.lang == 'EN' ? 'Delete News?' : 'Hapus Berita?',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold),
            ),
            content: Text(
              widget.lang == 'EN'
                  ? 'This action cannot be undone.'
                  : 'Tindakan ini tidak dapat dibatalkan.',
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(widget.lang == 'EN' ? 'Cancel' : 'Batal',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444)),
                child: Text(widget.lang == 'EN' ? 'Delete' : 'Hapus',
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
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
        foregroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        title: Text(
          widget.lang == 'EN' ? 'Latest News' : 'Kabar Terbaru',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          widget.lang == 'EN' ? 'Add News' : 'Tambah Berita',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Filter bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                _filterPill('all',
                    widget.lang == 'EN' ? 'All' : 'Semua', Colors.black54),
                const SizedBox(width: 8),
                _filterPill('update', 'Update', const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                _filterPill('maintenance', 'Maintenance',
                    const Color(0xFFF59E0B)),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_outlined,
                                size: 56,
                                color: Colors.black12),
                            const SizedBox(height: 12),
                            Text(
                              widget.lang == 'EN'
                                  ? 'No news yet'
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _buildNewsCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String type, String label, Color color) {
    final isActive = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
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
    final icon = isUpdate
        ? Icons.update_rounded
        : Icons.build_rounded;

    // Pilih judul berdasarkan bahasa
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                        fontSize: 13,
                      ),
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isUpdate ? 'Update' : 'Maintenance',
                            style: GoogleFonts.poppins(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.calendar_today_rounded,
                            size: 11, color: Colors.black38),
                        const SizedBox(width: 3),
                        Text(
                          date,
                          style: GoogleFonts.poppins(
                              color: Colors.black38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Column(
                children: [
                  _iconBtn(Icons.edit_outlined, const Color(0xFF6366F1),
                      () => _showFormDialog(item: item)),
                  const SizedBox(height: 6),
                  _iconBtn(Icons.delete_outline_rounded,
                      const Color(0xFFEF4444),
                      () => _deleteNews(item['id'])),
                ],
              ),
            ],
          ),
          if ((item[contentKey] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
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
        ],
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
          borderRadius: BorderRadius.circular(8),
        ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
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
          letterSpacing: 0.3,
        ),
      );

  Widget _dlgField(TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
            color: const Color(0xFF1E3A8A), fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.black38, size: 18)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ── Helper widget form konten 3 bahasa ──
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

  TextEditingController _titleCtrl(int i) => [
        widget.titleIdCtrl,
        widget.titleEnCtrl,
        widget.titleZhCtrl,
      ][i];

  TextEditingController _contentCtrl(int i) => [
        widget.contentIdCtrl,
        widget.contentEnCtrl,
        widget.contentZhCtrl,
      ][i];

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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black45,
            labelPadding: EdgeInsets.zero,
            tabs: _langs
                .map((l) => Tab(
                      child: Text(
                        '${l['flag']} ${l['code']}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
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
                    child: _fieldBox(_contentCtrl(i), Icons.article_outlined,
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
        border: Border.all(color: Colors.grey.shade200),
      ),
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