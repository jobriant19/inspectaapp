import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../user/home/alert/required_field_alert.dart';

// ============================================================
// SHARED: Translate helper (ID / EN / ZH)
// ============================================================
class TranslateFailedException implements Exception {
  final String reason;
  TranslateFailedException(this.reason);
  @override
  String toString() => 'TranslateFailedException: $reason';
}

Future<String> _translateCategoryText(String text, String langPair) async {
  if (text.trim().isEmpty) return text;
  final normalizedPair = langPair
      .replaceAll('|zh', '|zh-CN')
      .replaceAll('zh|', 'zh-CN|');
  // TIP: tambahkan &de=email_anda@domain.com pada URL di bawah untuk
  // menaikkan kuota harian gratis MyMemory dari 5.000 menjadi 50.000 kata/hari.
  final uri = Uri.parse(
    'https://api.mymemory.translated.net/get'
    '?q=${Uri.encodeComponent(text)}&langpair=$normalizedPair'
    '&de=amprem5203@gmail.com',
  );
  final res = await http.get(uri).timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) {
    throw TranslateFailedException('HTTP ${res.statusCode}');
  }
  final data = jsonDecode(res.body);
  final translated = data['responseData']?['translatedText']?.toString() ?? '';
  final upper = translated.toUpperCase();
  if (translated.isEmpty ||
      upper.startsWith('MYMEMORY WARNING') ||
      upper.startsWith('PLEASE') ||
      upper.contains('QUERY LENGTH LIMIT') ||
      upper.contains('INVALID')) {
    // Translate gagal (kuota habis / server bermasalah) — JANGAN fallback diam-diam.
    throw TranslateFailedException(
        translated.isEmpty ? 'Empty response from translate API' : translated);
  }
  return translated;
}

Future<Map<String, String>> _translateAllLangs(
    String sourceText, String currentLang) async {
  if (sourceText.isEmpty) return {'id': '', 'en': '', 'zh': ''};
  switch (currentLang) {
    case 'EN':
      final results = await Future.wait([
        _translateCategoryText(sourceText, 'en|id'),
        _translateCategoryText(sourceText, 'en|zh'),
      ]);
      return {'id': results[0], 'en': sourceText, 'zh': results[1]};
    case 'ZH':
      final results = await Future.wait([
        _translateCategoryText(sourceText, 'zh|id'),
        _translateCategoryText(sourceText, 'zh|en'),
      ]);
      return {'id': results[0], 'en': results[1], 'zh': sourceText};
    default:
      final results = await Future.wait([
        _translateCategoryText(sourceText, 'id|en'),
        _translateCategoryText(sourceText, 'id|zh'),
      ]);
      return {'id': sourceText, 'en': results[0], 'zh': results[1]};
  }
}

void _showTranslatingDialog(BuildContext context, String lang, Color color) {
  // PENTING: fungsi ini SENGAJA tidak async/return Future yang di-await
  // oleh pemanggilnya. showDialog() hanya selesai (resolve) setelah
  // di-pop — kalau dipanggil pakai `await`, kode setelahnya (yang berisi
  // proses translate dan pop dialog ini) tidak akan pernah jalan →
  // dialog macet selamanya. Cukup panggil tanpa 'await'.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      backgroundColor: color.withValues(alpha:0.12),
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.translate_rounded, color: color, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              lang == 'EN'
                  ? 'Translating...'
                  : lang == 'ZH'
                      ? '翻译中...'
                      : 'Menerjemahkan...',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 4),
            Text(
              lang == 'EN'
                  ? 'Preparing ID / EN / ZH versions'
                  : lang == 'ZH'
                      ? '正在准备 ID / EN / ZH 版本'
                      : 'Menyiapkan versi ID / EN / ZH',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showTranslateFailedDialog(BuildContext context, String lang, Color color) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFFFEBEB), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              lang == 'EN' ? 'Translation Failed' : lang == 'ZH' ? '翻译失败' : 'Terjemahan Gagal',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              lang == 'EN'
                  ? 'Could not reach the translation service. Nothing was saved. Please check your internet connection and try again.'
                  : lang == 'ZH'
                      ? '无法连接翻译服务，数据未保存。请检查网络连接后重试。'
                      : 'Tidak dapat terhubung ke layanan terjemahan. Data belum tersimpan. Periksa koneksi internet Anda lalu coba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  lang == 'EN' ? 'OK' : lang == 'ZH' ? '确定' : 'Mengerti',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// ADMIN CATEGORY SCREEN
// ============================================================
class AdminCategoryScreen extends StatefulWidget {
  final String lang;
  const AdminCategoryScreen({super.key, required this.lang});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedTab = 0; // 0 = 5R Finding, 1 = KTS Production

  static const _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF59E0B),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        shadowColor: Colors.black.withValues(alpha:0.08),
        title: Text(
          widget.lang == 'EN'
              ? 'Category Management'
              : widget.lang == 'ZH'
                  ? '分类管理'
                  : 'Kelola Kategori',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: const Color(0xFFF59E0B),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: const Color(0xFFF59E0B),
              indicatorWeight: 3,
              labelColor: const Color(0xFFF59E0B),
              unselectedLabelColor: Colors.black38,
              isScrollable: false,
              tabAlignment: TabAlignment.fill,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'EN'
                            ? 'Categories'
                            : widget.lang == 'ZH'
                                ? '分类'
                                : 'Kategori',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list_alt_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        widget.lang == 'EN'
                            ? 'Sub-Categories'
                            : widget.lang == 'ZH'
                                ? '子分类'
                                : 'Sub-Kategori',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildFilterPills(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _KategoriList(
                  key: ValueKey('kat_$_selectedTab'),
                  lang: widget.lang,
                  isKts: _selectedTab == 1,
                  color: _selectedTab == 0
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFFBBF24),
                ),
                _SubkategoriList(
                  key: ValueKey('subkat_$_selectedTab'),
                  lang: widget.lang,
                  isKts: _selectedTab == 1,
                  color: _selectedTab == 0
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFFBBF24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 0
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFFBAE6FD),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cleaning_services_rounded,
                      size: 15,
                      color: _selectedTab == 0
                          ? Colors.white
                          : const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '5R Finding',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedTab == 0
                            ? Colors.white
                            : const Color(0xFF0EA5E9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 1
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFFBBF24).withValues(alpha:0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.precision_manufacturing_rounded,
                      size: 15,
                      color: _selectedTab == 1
                          ? Colors.white
                          : const Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'KTS Production',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedTab == 1
                            ? Colors.white
                            : const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DAFTAR KATEGORI
// ============================================================
class _KategoriList extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;

  const _KategoriList({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
  });

  @override
  State<_KategoriList> createState() => _KategoriListState();
}

class _KategoriListState extends State<_KategoriList>
  with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String _search = '';
  String _sortPoin = 'none';   // 'none' | 'asc' | 'desc'
  String _sortOrder = 'none';  // 'none' | 'asc' | 'desc'

  static const _bg = Color(0xFFF8FAFC);
  static const _subColor = Color(0xFF8B5CF6);  // ungu khusus jumlah sub-kategori
  static const _poinColor = Color(0xFFF59E0B); // oranye khusus poin

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_KategoriList old) {
    super.didUpdateWidget(old);
    if (old.isKts != widget.isKts) _loadIfEmpty();
  }

  // Tambahkan method baru di bawahnya:
  Future<void> _loadIfEmpty() async {
    if (_data.isEmpty) {
      _load();
    } else {
      // Data sudah ada, langsung filter ulang tanpa loading
      setState(() {});
    }
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('kategoritemuan')
          .select(
            'id_kategoritemuan, nama_kategoritemuan, nama_kategoritemuan_en, '
            'nama_kategoritemuan_zh, deskripsi_kategoritemuan, '
            'deskripsi_kategoritemuan_en, deskripsi_kategoritemuan_zh, '
            'poin_kategoritemuan, jenis_kategori, '
            'subkategoritemuan(id_subkategoritemuan, '
            'nama_subkategoritemuan, poin_subkategoritemuan)',
          )
          .order('nama_kategoritemuan');

      final all = List<Map<String, dynamic>>.from(res);
      final filtered = all.where((item) {
        final jenis = (item['jenis_kategori'] ?? '').toString().toUpperCase();
        if (widget.isKts) return jenis == 'KTS';
        return jenis == '5R';
      }).toList();

      if (mounted) {
        setState(() {
          _data = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error load kategori: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _localizedNama(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['nama_kategoritemuan_en'] ?? item['nama_kategoritemuan'] ?? '-').toString();
      case 'ZH':
        return (item['nama_kategoritemuan_zh'] ?? item['nama_kategoritemuan'] ?? '-').toString();
      default:
        return (item['nama_kategoritemuan'] ?? '-').toString();
    }
  }

  String _localizedDesk(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['deskripsi_kategoritemuan_en'] ?? item['deskripsi_kategoritemuan'] ?? '').toString();
      case 'ZH':
        return (item['deskripsi_kategoritemuan_zh'] ?? item['deskripsi_kategoritemuan'] ?? '').toString();
      default:
        return (item['deskripsi_kategoritemuan'] ?? '').toString();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_data);

    if (q.isNotEmpty) {
      result = result
          .where((d) => _localizedNama(d).toLowerCase().contains(q))
          .toList();
    }
    // Sort by poin
    if (_sortPoin == 'asc') {
      result.sort((a, b) => ((a['poin_kategoritemuan'] ?? 0) as int)
          .compareTo((b['poin_kategoritemuan'] ?? 0) as int));
    } else if (_sortPoin == 'desc') {
      result.sort((a, b) => ((b['poin_kategoritemuan'] ?? 0) as int)
          .compareTo((a['poin_kategoritemuan'] ?? 0) as int));
    }
    // Sort by name
    if (_sortOrder == 'asc') {
      result.sort((a, b) => _localizedNama(a).compareTo(_localizedNama(b)));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => _localizedNama(b).compareTo(_localizedNama(a)));
    }
    return result;
  }

  Widget? _buildActiveChips() {
    final chips = <Widget>[];
    if (_sortPoin != 'none') {
      chips.add(_buildFilterChip(
        _sortPoin == 'asc' ? '⭐ Poin ↑' : '⭐ Poin ↓',
        widget.color,
        () => setState(() { _sortPoin = 'none'; }),
      ));
    }
    if (_sortOrder != 'none') {
      chips.add(_buildFilterChip(
        _sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
        widget.color,
        () => setState(() { _sortOrder = 'none'; }),
      ));
    }
    if (chips.isEmpty) return null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildFilterChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            label: widget.lang == 'EN' ? 'Sort by Points' : widget.lang == 'ZH' ? '按积分排序' : 'Urut Poin',
            icon: Icons.star_rounded,
            isActive: _sortPoin != 'none',
            activeLabel: _sortPoin == 'asc' ? '↑' : _sortPoin == 'desc' ? '↓' : null,
            onTap: () => _showPoinSortDialog(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            label: widget.lang == 'EN' ? 'Sort' : widget.lang == 'ZH' ? '排序' : 'Urutan',
            icon: Icons.sort_by_alpha_rounded,
            isActive: _sortOrder != 'none',
            activeLabel: _sortOrder == 'asc' ? 'A→Z' : _sortOrder == 'desc' ? 'Z→A' : null,
            onTap: () => _showSortDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    String? activeLabel,
  }) {
    final color = widget.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade200,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: color.withValues(alpha:0.2), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                isActive && activeLabel != null ? '$label $activeLabel' : label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  void _showPoinSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSortOptionDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Sort by Points' : widget.lang == 'ZH' ? '按积分排序' : 'Urut berdasarkan Poin',
        icon: Icons.star_rounded,
        color: widget.color,
        currentValue: _sortPoin,
        options: [
          {'value': 'none', 'label': widget.lang == 'EN' ? 'Default' : widget.lang == 'ZH' ? '默认' : 'Default'},
          {'value': 'desc', 'label': widget.lang == 'EN' ? 'Highest Points First' : widget.lang == 'ZH' ? '积分从高到低' : 'Poin Terbesar Dulu'},
          {'value': 'asc', 'label': widget.lang == 'EN' ? 'Lowest Points First' : widget.lang == 'ZH' ? '积分从低到高' : 'Poin Terkecil Dulu'},
        ],
        onSelect: (v) {
          setState(() => _sortPoin = v);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSortOptionDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Sort Order' : widget.lang == 'ZH' ? '排序方式' : 'Urutan Abjad',
        icon: Icons.sort_by_alpha_rounded,
        color: widget.color,
        currentValue: _sortOrder,
        options: [
          {'value': 'none', 'label': widget.lang == 'EN' ? 'Default (No Sort)' : widget.lang == 'ZH' ? '默认' : 'Default (Tanpa Urutan)'},
          {'value': 'asc', 'label': 'A → Z (Ascending)'},
          {'value': 'desc', 'label': 'Z → A (Descending)'},
        ],
        onSelect: (v) {
          setState(() => _sortOrder = v);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item != null ? _localizedNama(item) : '');
    final descCtrl = TextEditingController(text: item != null ? _localizedDesk(item) : '');
    final poinCtrl = TextEditingController(
        text: (item?['poin_kategoritemuan'] ?? 0).toString());
    final String jenisKategori = widget.isKts ? 'KTS' : '5R';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _LightFormDialog(
        title: isEdit
            ? (widget.lang == 'EN' ? 'Edit Category' : widget.lang == 'ZH' ? '编辑分类' : 'Edit Kategori')
            : (widget.lang == 'EN' ? 'Add Category' : widget.lang == 'ZH' ? '添加分类' : 'Tambah Kategori'),
        icon: Icons.category_rounded,
        color: widget.color,
        lang: widget.lang,
        badge: widget.isKts ? 'KTS Production' : '5R Finding',
        fields: [
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Category Name' : widget.lang == 'ZH' ? '分类名称' : 'Nama Kategori',
            ctrl: namaCtrl,
            icon: Icons.category_rounded,
            required: true,
          ),
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
            ctrl: descCtrl,
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          _FieldConfig(
            label: widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin',
            ctrl: poinCtrl,
            icon: Icons.star_rounded,
            keyboardType: TextInputType.number,
          ),
        ],
        onSave: () async {
          if (namaCtrl.text.trim().isEmpty) return;

          final namaSource = namaCtrl.text.trim();
          final descSource = descCtrl.text.trim();

          final bool namaChanged = !isEdit || namaSource != _localizedNama(item);
          final bool descChanged = !isEdit || descSource != _localizedDesk(item);
          final bool needsTranslate = namaChanged || (descChanged && descSource.isNotEmpty);

          Map<String, String> namaAll = isEdit && !namaChanged
              ? {
                  'id': (item['nama_kategoritemuan'] ?? namaSource).toString(),
                  'en': (item['nama_kategoritemuan_en'] ?? namaSource).toString(),
                  'zh': (item['nama_kategoritemuan_zh'] ?? namaSource).toString(),
                }
              : {'id': namaSource, 'en': namaSource, 'zh': namaSource};
          Map<String, String> descAll = isEdit && !descChanged
              ? {
                  'id': (item['deskripsi_kategoritemuan'] ?? '').toString(),
                  'en': (item['deskripsi_kategoritemuan_en'] ?? '').toString(),
                  'zh': (item['deskripsi_kategoritemuan_zh'] ?? '').toString(),
                }
              : {'id': '', 'en': '', 'zh': ''};

          if (needsTranslate) {
            // JANGAN pakai 'await' di sini — lihat catatan di _showTranslatingDialog
            if (mounted) _showTranslatingDialog(context, widget.lang, widget.color);
            try {
              final translateResults = await Future.wait([
                if (namaChanged) _translateAllLangs(namaSource, widget.lang),
                if (descChanged && descSource.isNotEmpty) _translateAllLangs(descSource, widget.lang),
              ]);
              int idx = 0;
              if (namaChanged) namaAll = translateResults[idx++];
              if (descChanged && descSource.isNotEmpty) descAll = translateResults[idx++];
              if (mounted) Navigator.of(context, rootNavigator: true).pop();
            } catch (e) {
              debugPrint('Error translating kategori: $e');
              if (mounted) Navigator.of(context, rootNavigator: true).pop();
              if (mounted) _showTranslateFailedDialog(context, widget.lang, widget.color);
              return; // STOP — jangan simpan data yang belum berhasil diterjemahkan
            }
          }

          final data = {
            'nama_kategoritemuan': namaAll['id'],
            'nama_kategoritemuan_en': namaAll['en'],
            'nama_kategoritemuan_zh': namaAll['zh'],
            'deskripsi_kategoritemuan':
                descAll['id']!.isEmpty ? null : descAll['id'],
            'deskripsi_kategoritemuan_en':
                descAll['en']!.isEmpty ? null : descAll['en'],
            'deskripsi_kategoritemuan_zh':
                descAll['zh']!.isEmpty ? null : descAll['zh'],
            'poin_kategoritemuan': int.tryParse(poinCtrl.text.trim()) ?? 0,
            'jenis_kategori': jenisKategori,
          };
          if (isEdit) {
            await Supabase.instance.client
                .from('kategoritemuan')
                .update(data)
                .eq('id_kategoritemuan', item['id_kategoritemuan']);
          } else {
            await Supabase.instance.client.from('kategoritemuan').insert(data);
          }
          _load();
        },
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    final subs = List<Map<String, dynamic>>.from(
        item['subkategoritemuan'] as List? ?? []);
    final poin = item['poin_kategoritemuan'] ?? 0;
    final descRaw = _localizedDesk(item);
    final desc = descRaw.isEmpty ? '-' : descRaw;
    final nama = _localizedNama(item);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color.withValues(alpha:0.14), widget.color.withValues(alpha:0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha:0.18),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: widget.color.withValues(alpha:0.25), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Icon(Icons.category_rounded, color: widget.color, size: 24),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 6)]),
                          child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(nama, style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w800, fontSize: 19)),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13.5, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _detailChip('${widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin'}: $poin', _poinColor, Icons.star_rounded),
                      _detailChip('${subs.length} ${widget.lang == 'EN' ? 'sub-cat' : widget.lang == 'ZH' ? '子类' : 'sub-kat'}', _subColor, Icons.list_alt_rounded),
                      _detailChip(widget.isKts ? 'KTS' : '5R', widget.isKts ? const Color(0xFF0891B2) : const Color(0xFF6366F1), Icons.label_rounded),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: subs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/team_illustration.png',
                            width: 150,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.lang == 'EN' ? 'No sub-categories yet' : widget.lang == 'ZH' ? '暂无子分类' : 'Belum ada sub-kategori',
                            style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.lang == 'EN'
                                ? 'Add sub-categories to organize this category better'
                                : widget.lang == 'ZH'
                                    ? '添加子分类以更好地组织此分类'
                                    : 'Tambahkan sub-kategori untuk mengelompokkan kategori ini',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      itemCount: subs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final sub = subs[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: widget.color.withValues(alpha:0.14)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30, height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _subColor.withValues(alpha:0.12),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text('${i + 1}', style: GoogleFonts.poppins(color: _subColor, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(sub['nama_subkategoritemuan'] ?? '-',
                                  style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.w600))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _poinColor.withValues(alpha:0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text('${sub['poin_subkategoritemuan'] ?? 0} pt',
                                    style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                      label: Text(widget.lang == 'EN' ? 'Edit' : widget.lang == 'ZH' ? '编辑' : 'Ubah',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () { Navigator.pop(ctx); _showAddEditDialog(item: item); },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
                      label: Text(widget.lang == 'EN' ? 'Delete' : widget.lang == 'ZH' ? '删除' : 'Hapus',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _deleteItem(item['id_kategoritemuan'], item['nama_kategoritemuan'] ?? '');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _deleteItem(String id, String name) async {
    final ok = await _confirmDeleteDialog(context, name, widget.lang);
    if (!ok) return;
    try {
      await Supabase.instance.client.from('kategoritemuan').delete().eq('id_kategoritemuan', id);
      if (mounted) {
        setState(() {
          _data.removeWhere((d) => d['id_kategoritemuan'] == id);
        });
      }
      _load();
    } catch (e) {
      debugPrint('Error delete kategori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lang == 'EN' ? 'Failed to delete' : widget.lang == 'ZH' ? '删除失败' : 'Gagal menghapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _filtered;
    final addTitle = widget.lang == 'EN'
        ? 'Add New Category'
        : widget.lang == 'ZH' ? '添加新分类' : 'Tambah Kategori Baru';
    final addSubtitle = widget.lang == 'EN'
        ? 'Tap to add a new category'
        : widget.lang == 'ZH' ? '点击以添加新分类' : 'Ketuk untuk menambah kategori baru';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Banner Add Button ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: GestureDetector(
              onTap: () => _showAddEditDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha:0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: widget.color.withValues(alpha:0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(addTitle, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text(addSubtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withValues(alpha:0.85))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha:0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.lang == 'EN' ? 'Search categories...' : widget.lang == 'ZH' ? '搜索分类...' : 'Cari kategori...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // ── Filter Row ──
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterRow(),
          ),
          const SizedBox(height: 8),
          // ── Active chips ──
          if (_buildActiveChips() != null) _buildActiveChips()!,
          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.color.withValues(alpha:0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_rounded, size: 13, color: widget.color),
                    const SizedBox(width: 5),
                    Text(
                      '${data.length} ${widget.lang == 'EN' ? 'categories' : widget.lang == 'ZH' ? '个分类' : 'kategori'}',
                      style: GoogleFonts.poppins(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : data.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.color,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: data.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildCard(data[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final subs = List<Map<String, dynamic>>.from(item['subkategoritemuan'] as List? ?? []);
    final poin = item['poin_kategoritemuan'] ?? 0;
    final nama = _localizedNama(item);

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha:0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: widget.color.withValues(alpha:0.10), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.category_rounded, color: widget.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip('${subs.length} sub', _subColor, Icons.list_alt_rounded),
                      _chip('$poin pt', _poinColor, Icons.star_rounded),
                    ],
                  ),
                ],
              ),
            ),
            // ── Edit & chevron ──
            GestureDetector(
              onTap: () => _showAddEditDialog(item: item),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
              ),
            ),
            GestureDetector(
              onTap: () => _deleteItem(item['id_kategoritemuan'], nama),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.20)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(height: 88, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              width: 190,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(widget.lang == 'EN' ? 'No categories yet' : widget.lang == 'ZH' ? '暂无分类' : 'Belum ada kategori',
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(widget.lang == 'EN' ? 'Tap + to add your first category' : widget.lang == 'ZH' ? '点击+添加您的第一个分类' : 'Tekan + untuk menambah kategori pertama',
                style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DAFTAR SUB-KATEGORI
// ============================================================
class _SubkategoriList extends StatefulWidget {
  final String lang;
  final bool isKts;
  final Color color;

  const _SubkategoriList({
    super.key,
    required this.lang,
    required this.isKts,
    required this.color,
  });

  @override
  State<_SubkategoriList> createState() => _SubkategoriListState();
}

class _SubkategoriListState extends State<_SubkategoriList>
  with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _allKategori = [];
  bool _isLoading = true;
  String _search = '';
  String _sortPoin = 'none';
  String _sortOrder = 'none';

  static const _bg = Color(0xFFF8FAFC);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SubkategoriList old) {
    super.didUpdateWidget(old);
    if (old.isKts != widget.isKts) _loadIfEmpty();
  }

  Future<void> _loadIfEmpty() async {
    if (_data.isEmpty) {
      _load();
    } else {
      setState(() {});
    }
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('subkategoritemuan')
            .select(
              'id_subkategoritemuan, id_kategoritemuan, '
              'nama_subkategoritemuan, nama_subkategoritemuan_en, '
              'nama_subkategoritemuan_zh, deskripsi_subkategoritemuan, '
              'deskripsi_subkategoritemuan_en, deskripsi_subkategoritemuan_zh, '
              'poin_subkategoritemuan, '
              'kategoritemuan(id_kategoritemuan, nama_kategoritemuan, '
              'nama_kategoritemuan_en, nama_kategoritemuan_zh, '
              'deskripsi_kategoritemuan, deskripsi_kategoritemuan_en, '
              'deskripsi_kategoritemuan_zh, poin_kategoritemuan, jenis_kategori)',
            )
            .order('nama_subkategoritemuan'),
        Supabase.instance.client
            .from('kategoritemuan')
            .select('id_kategoritemuan, nama_kategoritemuan, nama_kategoritemuan_en, nama_kategoritemuan_zh, jenis_kategori')
            .order('nama_kategoritemuan'),
      ]);

      final allSub = List<Map<String, dynamic>>.from(results[0] as List);
      final allKat = List<Map<String, dynamic>>.from(results[1] as List);

      final filteredSub = allSub.where((sub) {
        final jenis = (sub['kategoritemuan']?['jenis_kategori'] ?? '').toString().toUpperCase();
        if (widget.isKts) return jenis == 'KTS';
        return jenis == '5R';
      }).toList();

      final filteredKat = allKat.where((k) {
        final jenis = (k['jenis_kategori'] ?? '').toString().toUpperCase();
        if (widget.isKts) return jenis == 'KTS';
        return jenis == '5R';
      }).toList();

      if (mounted) {
        setState(() {
          _data = filteredSub;
          _allKategori = filteredKat;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error load subkategori: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _localizedNama(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['nama_subkategoritemuan_en'] ?? item['nama_subkategoritemuan'] ?? '-').toString();
      case 'ZH':
        return (item['nama_subkategoritemuan_zh'] ?? item['nama_subkategoritemuan'] ?? '-').toString();
      default:
        return (item['nama_subkategoritemuan'] ?? '-').toString();
    }
  }

  String _localizedDesk(Map<String, dynamic> item) {
    switch (widget.lang) {
      case 'EN':
        return (item['deskripsi_subkategoritemuan_en'] ?? item['deskripsi_subkategoritemuan'] ?? '').toString();
      case 'ZH':
        return (item['deskripsi_subkategoritemuan_zh'] ?? item['deskripsi_subkategoritemuan'] ?? '').toString();
      default:
        return (item['deskripsi_subkategoritemuan'] ?? '').toString();
    }
  }

  String _localizedParentNama(Map<String, dynamic> item) {
    final parent = item['kategoritemuan'];
    if (parent == null) return '-';
    switch (widget.lang) {
      case 'EN':
        return (parent['nama_kategoritemuan_en'] ?? parent['nama_kategoritemuan'] ?? '-').toString();
      case 'ZH':
        return (parent['nama_kategoritemuan_zh'] ?? parent['nama_kategoritemuan'] ?? '-').toString();
      default:
        return (parent['nama_kategoritemuan'] ?? '-').toString();
    }
  }

  String _localizedParentDesk(Map<String, dynamic> item) {
    final parent = item['kategoritemuan'];
    if (parent == null) return '';
    switch (widget.lang) {
      case 'EN':
        return (parent['deskripsi_kategoritemuan_en'] ?? parent['deskripsi_kategoritemuan'] ?? '').toString();
      case 'ZH':
        return (parent['deskripsi_kategoritemuan_zh'] ?? parent['deskripsi_kategoritemuan'] ?? '').toString();
      default:
        return (parent['deskripsi_kategoritemuan'] ?? '').toString();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    List<Map<String, dynamic>> result = List.from(_data);

    if (q.isNotEmpty) {
      result = result
          .where((d) => _localizedNama(d).toLowerCase().contains(q))
          .toList();
    }
    if (_sortPoin == 'asc') {
      result.sort((a, b) => ((a['poin_subkategoritemuan'] ?? 0) as int)
          .compareTo((b['poin_subkategoritemuan'] ?? 0) as int));
    } else if (_sortPoin == 'desc') {
      result.sort((a, b) => ((b['poin_subkategoritemuan'] ?? 0) as int)
          .compareTo((a['poin_subkategoritemuan'] ?? 0) as int));
    }
    if (_sortOrder == 'asc') {
      result.sort((a, b) => _localizedNama(a).compareTo(_localizedNama(b)));
    } else if (_sortOrder == 'desc') {
      result.sort((a, b) => _localizedNama(b).compareTo(_localizedNama(a)));
    }
    return result;
  }

  Widget? _buildActiveChips() {
    final chips = <Widget>[];
    if (_sortPoin != 'none') {
      chips.add(_buildFilterChip(
        _sortPoin == 'asc' ? '⭐ Poin ↑' : '⭐ Poin ↓',
        widget.color,
        () => setState(() => _sortPoin = 'none'),
      ));
    }
    if (_sortOrder != 'none') {
      chips.add(_buildFilterChip(
        _sortOrder == 'asc' ? '🔤 A→Z' : '🔤 Z→A',
        widget.color,
        () => setState(() => _sortOrder = 'none'),
      ));
    }
    if (chips.isEmpty) return null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  Widget _buildFilterChip(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        GestureDetector(onTap: onRemove, child: Icon(Icons.close_rounded, size: 13, color: color)),
      ]),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            label: widget.lang == 'EN' ? 'Sort by Points' : widget.lang == 'ZH' ? '按积分排序' : 'Urut Poin',
            icon: Icons.star_rounded,
            isActive: _sortPoin != 'none',
            activeLabel: _sortPoin == 'asc' ? '↑' : _sortPoin == 'desc' ? '↓' : null,
            onTap: _showPoinSortDialog,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterButton(
            label: widget.lang == 'EN' ? 'Sort' : widget.lang == 'ZH' ? '排序' : 'Urutan',
            icon: Icons.sort_by_alpha_rounded,
            isActive: _sortOrder != 'none',
            activeLabel: _sortOrder == 'asc' ? 'A→Z' : _sortOrder == 'desc' ? 'Z→A' : null,
            onTap: _showSortDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    String? activeLabel,
  }) {
    final color = widget.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? color : Colors.grey.shade200, width: isActive ? 1.5 : 1),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha:0.2), blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                isActive && activeLabel != null ? '$label $activeLabel' : label,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.white : color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  void _showPoinSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSortOptionDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Sort by Points' : widget.lang == 'ZH' ? '按积分排序' : 'Urut berdasarkan Poin',
        icon: Icons.star_rounded,
        color: widget.color,
        currentValue: _sortPoin,
        options: [
          {'value': 'none', 'label': widget.lang == 'EN' ? 'Default' : widget.lang == 'ZH' ? '默认' : 'Default'},
          {'value': 'desc', 'label': widget.lang == 'EN' ? 'Highest Points First' : widget.lang == 'ZH' ? '积分从高到低' : 'Poin Terbesar Dulu'},
          {'value': 'asc', 'label': widget.lang == 'EN' ? 'Lowest Points First' : widget.lang == 'ZH' ? '积分从低到高' : 'Poin Terkecil Dulu'},
        ],
        onSelect: (v) { setState(() => _sortPoin = v); Navigator.pop(ctx); },
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _buildSortOptionDialog(
        ctx: ctx,
        title: widget.lang == 'EN' ? 'Sort Order' : widget.lang == 'ZH' ? '排序方式' : 'Urutan Abjad',
        icon: Icons.sort_by_alpha_rounded,
        color: widget.color,
        currentValue: _sortOrder,
        options: [
          {'value': 'none', 'label': widget.lang == 'EN' ? 'Default (No Sort)' : widget.lang == 'ZH' ? '默认' : 'Default (Tanpa Urutan)'},
          {'value': 'asc', 'label': 'A → Z (Ascending)'},
          {'value': 'desc', 'label': 'Z → A (Descending)'},
        ],
        onSelect: (v) { setState(() => _sortOrder = v); Navigator.pop(ctx); },
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item != null ? _localizedNama(item) : '');
    final descCtrl = TextEditingController(text: item != null ? _localizedDesk(item) : '');
    final poinCtrl = TextEditingController(text: (item?['poin_subkategoritemuan'] ?? 0).toString());
    String? selectedKatId = item?['id_kategoritemuan']?.toString();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => _LightFormDialog(
          title: isEdit
              ? (widget.lang == 'EN' ? 'Edit Sub-Category' : widget.lang == 'ZH' ? '编辑子分类' : 'Edit Sub-Kategori')
              : (widget.lang == 'EN' ? 'Add Sub-Category' : widget.lang == 'ZH' ? '添加子分类' : 'Tambah Sub-Kategori'),
          icon: Icons.list_alt_rounded,
          color: widget.color,
          lang: widget.lang,
          badge: widget.isKts ? 'KTS Production' : '5R Finding',
          fields: [
            _FieldConfig(
              label: widget.lang == 'EN' ? 'Sub-Category Name' : widget.lang == 'ZH' ? '子分类名称' : 'Nama Sub-Kategori',
              ctrl: namaCtrl, icon: Icons.list_alt_rounded,
              required: true,
            ),
            _FieldConfig(
              label: widget.lang == 'EN' ? 'Description' : widget.lang == 'ZH' ? '描述' : 'Deskripsi',
              ctrl: descCtrl, icon: Icons.notes_rounded, maxLines: 3,
            ),
            _FieldConfig(
              label: widget.lang == 'EN' ? 'Points' : widget.lang == 'ZH' ? '积分' : 'Poin',
              ctrl: poinCtrl, icon: Icons.star_rounded, keyboardType: TextInputType.number,
            ),
          ],
          extraWidget: _KategoriDropdown(
            lang: widget.lang,
            color: widget.color,
            items: _allKategori,
            selectedId: selectedKatId,
            onChanged: (v) => setDlg(() => selectedKatId = v),
          ),
          onSave: () async {
            if (namaCtrl.text.trim().isEmpty || selectedKatId == null) return;

            final namaSource = namaCtrl.text.trim();
            final descSource = descCtrl.text.trim();

            final bool namaChanged = !isEdit || namaSource != _localizedNama(item);
            final bool descChanged = !isEdit || descSource != _localizedDesk(item);
            final bool needsTranslate = namaChanged || (descChanged && descSource.isNotEmpty);

            Map<String, String> namaAll = isEdit && !namaChanged
                ? {
                    'id': (item['nama_subkategoritemuan'] ?? namaSource).toString(),
                    'en': (item['nama_subkategoritemuan_en'] ?? namaSource).toString(),
                    'zh': (item['nama_subkategoritemuan_zh'] ?? namaSource).toString(),
                  }
                : {'id': namaSource, 'en': namaSource, 'zh': namaSource};
            Map<String, String> descAll = isEdit && !descChanged
                ? {
                    'id': (item['deskripsi_subkategoritemuan'] ?? '').toString(),
                    'en': (item['deskripsi_subkategoritemuan_en'] ?? '').toString(),
                    'zh': (item['deskripsi_subkategoritemuan_zh'] ?? '').toString(),
                  }
                : {'id': '', 'en': '', 'zh': ''};

            if (needsTranslate) {
              // JANGAN pakai 'await' di sini — lihat catatan di _showTranslatingDialog
              if (mounted) _showTranslatingDialog(context, widget.lang, widget.color);
              try {
                final translateResults = await Future.wait([
                  if (namaChanged) _translateAllLangs(namaSource, widget.lang),
                  if (descChanged && descSource.isNotEmpty) _translateAllLangs(descSource, widget.lang),
                ]);
                int idx = 0;
                if (namaChanged) namaAll = translateResults[idx++];
                if (descChanged && descSource.isNotEmpty) descAll = translateResults[idx++];
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
              } catch (e) {
                debugPrint('Error translating subkategori: $e');
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
                if (mounted) _showTranslateFailedDialog(context, widget.lang, widget.color);
                return; // STOP — jangan simpan data yang belum berhasil diterjemahkan
              }
            }

            final data = {
              'id_kategoritemuan': selectedKatId,
              'nama_subkategoritemuan': namaAll['id'],
              'nama_subkategoritemuan_en': namaAll['en'],
              'nama_subkategoritemuan_zh': namaAll['zh'],
              'deskripsi_subkategoritemuan': descAll['id']!.isEmpty ? null : descAll['id'],
              'deskripsi_subkategoritemuan_en': descAll['en']!.isEmpty ? null : descAll['en'],
              'deskripsi_subkategoritemuan_zh': descAll['zh']!.isEmpty ? null : descAll['zh'],
              'poin_subkategoritemuan': int.tryParse(poinCtrl.text.trim()) ?? 0,
            };
            if (isEdit) {
              await Supabase.instance.client.from('subkategoritemuan').update(data).eq('id_subkategoritemuan', item['id_subkategoritemuan']);
            } else {
              await Supabase.instance.client.from('subkategoritemuan').insert(data);
            }
            _load();
          },
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> item) {
    final parent = item['kategoritemuan'];
    final parentNama = _localizedParentNama(item);
    final parentDescRaw = _localizedParentDesk(item);
    final parentDesc = parentDescRaw.isEmpty ? '-' : parentDescRaw;
    final parentPoin = parent?['poin_kategoritemuan'] ?? 0;
    final poin = item['poin_subkategoritemuan'] ?? 0;
    final descRaw = _localizedDesk(item);
    final desc = descRaw.isEmpty ? '-' : descRaw;
    final nama = _localizedNama(item);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color.withValues(alpha:0.14), widget.color.withValues(alpha:0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha:0.18),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: widget.color.withValues(alpha:0.25), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Icon(Icons.list_alt_rounded, color: widget.color, size: 24),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 6)]),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(nama, style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w800, fontSize: 19)),
                    if (desc != '-') ...[
                      const SizedBox(height: 8),
                      Text(desc, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 13.5, height: 1.5)),
                    ],
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _detailChip('$poin pt', const Color(0xFFF59E0B), Icons.star_rounded),
                      _detailChip(widget.isKts ? 'KTS' : '5R', widget.color, Icons.label_rounded),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.account_tree_rounded, size: 13, color: Colors.black45),
                    const SizedBox(width: 5),
                    Text(widget.lang == 'EN' ? 'Parent Category' : widget.lang == 'ZH' ? '父分类' : 'Kategori Induk',
                        style: GoogleFonts.poppins(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF6366F1).withValues(alpha:0.08), const Color(0xFF6366F1).withValues(alpha:0.02)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha:0.18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha:0.14), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.category_rounded, color: Color(0xFF6366F1), size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(parentNama, style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontWeight: FontWeight.w700, fontSize: 13.5)),
                          if (parentDesc != '-') ...[
                            const SizedBox(height: 3),
                            Text(parentDesc, style: GoogleFonts.poppins(color: Colors.black54, fontSize: 11.5, height: 1.4)),
                          ],
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha:0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text('$parentPoin pt',
                            style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: Colors.grey.shade100, thickness: 1, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                        label: Text(widget.lang == 'EN' ? 'Edit' : widget.lang == 'ZH' ? '编辑' : 'Ubah',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () { Navigator.pop(ctx); _showAddEditDialog(item: item); },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white),
                        label: Text(widget.lang == 'EN' ? 'Delete' : widget.lang == 'ZH' ? '删除' : 'Hapus',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async { Navigator.pop(ctx); await _deleteItem(item['id_subkategoritemuan'], item['nama_subkategoritemuan'] ?? ''); },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _deleteItem(String id, String name) async {
    final ok = await _confirmDeleteDialog(context, name, widget.lang);
    if (!ok) return;
    try {
      await Supabase.instance.client.from('subkategoritemuan').delete().eq('id_subkategoritemuan', id);
      if (mounted) {
        setState(() {
          _data.removeWhere((d) => d['id_subkategoritemuan'] == id);
        });
      }
      _load();
    } catch (e) {
      debugPrint('Error delete subkategori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lang == 'EN' ? 'Failed to delete' : widget.lang == 'ZH' ? '删除失败' : 'Gagal menghapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = _filtered;
    final addTitle = widget.lang == 'EN'
        ? 'Add New Sub-Category'
        : widget.lang == 'ZH' ? '添加新子分类' : 'Tambah Sub-Kategori Baru';
    final addSubtitle = widget.lang == 'EN'
        ? 'Tap to add a new sub-category'
        : widget.lang == 'ZH' ? '点击以添加新子分类' : 'Ketuk untuk menambah sub-kategori baru';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Banner Add Button ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: GestureDetector(
              onTap: () => _showAddEditDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withValues(alpha:0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: widget.color.withValues(alpha:0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.25), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(addTitle, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text(addSubtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withValues(alpha:0.85))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha:0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.lang == 'EN' ? 'Search sub-categories...' : widget.lang == 'ZH' ? '搜索子分类...' : 'Cari sub-kategori...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // ── Filter Row ──
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterRow(),
          ),
          const SizedBox(height: 8),
          // ── Active chips ──
          if (_buildActiveChips() != null) _buildActiveChips()!,
          // ── Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.color.withValues(alpha:0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt_rounded, size: 13, color: widget.color),
                    const SizedBox(width: 5),
                    Text(
                      '${data.length} sub-${widget.lang == 'EN' ? 'categories' : widget.lang == 'ZH' ? '分类' : 'kategori'}',
                      style: GoogleFonts.poppins(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ── List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : data.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.color,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: data.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildCard(data[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final parentNama = _localizedParentNama(item);
    final poin = item['poin_subkategoritemuan'] ?? 0;
    final nama = _localizedNama(item);

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha:0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: widget.color.withValues(alpha:0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.list_alt_rounded, color: widget.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: GoogleFonts.poppins(color: widget.color, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha:0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha:0.20)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.category_rounded, size: 11, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(parentNama,
                            style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 10.5, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha:0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha:0.25)),
                    ),
                    child: Text('$poin pt', style: GoogleFonts.poppins(color: const Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showAddEditDialog(item: item),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha:0.10), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 16),
              ),
            ),
            GestureDetector(
              onTap: () => _deleteItem(item['id_subkategoritemuan'], nama),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha:0.10), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              width: 190,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            Text(widget.lang == 'EN' ? 'No sub-categories yet' : widget.lang == 'ZH' ? '暂无子分类' : 'Belum ada sub-kategori',
                style: GoogleFonts.poppins(color: const Color(0xFF1E3A8A), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(widget.lang == 'EN' ? 'Tap + to add your first sub-category' : widget.lang == 'ZH' ? '点击+添加您的第一个子分类' : 'Tekan + untuk menambah sub-kategori pertama',
                style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHARED: Dropdown Kategori untuk form sub-kategori
// ============================================================
class _KategoriDropdown extends StatelessWidget {
  final String lang;
  final Color color;
  final List<Map<String, dynamic>> items;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _KategoriDropdown({
    required this.lang,
    required this.color,
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang == 'EN' ? 'Parent Category' : lang == 'ZH' ? '父分类' : 'Kategori Induk',
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedId,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.black45),
              hint: Text(
                lang == 'EN' ? 'Select category' : lang == 'ZH' ? '选择分类' : 'Pilih kategori',
                style: GoogleFonts.poppins(
                    color: Colors.black38, fontSize: 13),
              ),
              items: items.map((k) {
                final namaLokal = lang == 'EN'
                    ? (k['nama_kategoritemuan_en'] ?? k['nama_kategoritemuan'] ?? '-')
                    : lang == 'ZH'
                        ? (k['nama_kategoritemuan_zh'] ?? k['nama_kategoritemuan'] ?? '-')
                        : (k['nama_kategoritemuan'] ?? '-');
                return DropdownMenuItem<String>(
                  value: k['id_kategoritemuan'].toString(),
                  child: Text(
                    namaLokal,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E3A8A),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SHARED: Light Form Dialog (cerah, konsisten)
// ============================================================
class _FieldConfig {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool required;

  const _FieldConfig({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.required = false,
  });
}

class _LightFormDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String lang;
  final String badge;
  final List<_FieldConfig> fields;
  final Widget? extraWidget;
  final Future<void> Function() onSave;

  const _LightFormDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.lang,
    required this.badge,
    required this.fields,
    required this.onSave,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    color: color.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
            const SizedBox(height: 12),

            // ── Badge jenis ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha:0.20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_rounded, color: color, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    badge,
                    style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100, thickness: 1.5),
            const SizedBox(height: 14),

            // ── Extra widget (dropdown parent) ──
            if (extraWidget != null) ...[
              extraWidget!,
              const SizedBox(height: 16),
            ],

            // ── Fields ──
            ...fields.map((f) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(f.icon, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(
                          f.label,
                          style: GoogleFonts.poppins(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (f.required) ...[
                          const SizedBox(width: 3),
                          Text(
                            '*',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: f.ctrl,
                        maxLines: f.maxLines,
                        keyboardType: f.keyboardType,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: f.label,
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.black26, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                )),

            // ── Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.grey.shade600,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      lang == 'EN' ? 'Cancel' : lang == 'ZH' ? '取消' : 'Batal',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      final missing = fields
                          .where((f) =>
                              f.required && f.ctrl.text.trim().isEmpty)
                          .toList();
                      if (missing.isNotEmpty) {
                        RequiredFieldAlert.show(
                          context,
                          lang: lang,
                          missingFields: missing
                              .map((f) => MissingFieldItem(
                                  icon: f.icon, label: f.label))
                              .toList(),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await onSave();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: color.withValues(alpha:0.3),
                    ),
                    child: Text(
                      lang == 'EN' ? 'Save' : lang == 'ZH' ? '保存' : 'Simpan',
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
    );
  }
}

// ============================================================
// SHARED: Konfirmasi hapus
// ============================================================
Future<bool> _confirmDeleteDialog(
    BuildContext context, String name, String lang) async {
  return await showDialog<bool>(
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
                    color: Color(0xFFFFEBEB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFEF4444),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  lang == 'EN'
                      ? 'Delete?'
                      : lang == 'ZH'
                          ? '删除？'
                          : 'Hapus?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${lang == 'EN' ? 'Are you sure to delete' : lang == 'ZH' ? '确定要删除' : 'Yakin menghapus'} "$name"?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
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
                      lang == 'EN'
                          ? 'Delete'
                          : lang == 'ZH'
                              ? '删除'
                              : 'Hapus',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      lang == 'EN'
                          ? 'Cancel'
                          : lang == 'ZH'
                              ? '取消'
                              : 'Batal',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

// ─────────────────────────────────────────
// SHARED: Sort option dialog (reusable)
// ─────────────────────────────────────────
Widget _buildSortOptionDialog({
  required BuildContext ctx,
  required String title,
  required IconData icon,
  required Color color,
  required String currentValue,
  required List<Map<String, String>> options,
  required void Function(String) onSelect,
}) {
  return Dialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.04),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)))),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: options.map((opt) {
              final isSelected = currentValue == opt['value'];
              return GestureDetector(
                onTap: () => onSelect(opt['value']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha:0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(opt['label']!, style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : const Color(0xFF1E3A8A)))),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}