import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

String _felt(String lang, String id, String en, String zh) =>
    lang == 'ID' ? id : lang == 'ZH' ? zh : en;

/// Popup filter "Cause Factor" khusus KTS Production.
/// Mengambil data dari tabel subkategoritemuan yang berada di bawah
/// kategoritemuan 'KTS Produksi' (pola sama seperti dropdown Faktor Penyebab
/// pada kts_produksi_screen.dart & kts_detail_screen.dart).
class ExploreFactorFilterScreen extends StatefulWidget {
  final String lang;
  const ExploreFactorFilterScreen({super.key, required this.lang});

  @override
  State<ExploreFactorFilterScreen> createState() => _ExploreFactorFilterScreenState();
}

class _ExploreFactorFilterScreenState extends State<ExploreFactorFilterScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _allFactors = [];
  List<Map<String, dynamic>> _filteredFactors = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _fetchFactors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFactors() async {
    try {
      final katData = await _supabase
          .from('kategoritemuan')
          .select('id_kategoritemuan')
          .eq('nama_kategoritemuan', 'KTS Produksi')
          .maybeSingle();

      if (katData == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final String katId = katData['id_kategoritemuan'].toString();

      final data = await _supabase
          .from('subkategoritemuan')
          .select('id_subkategoritemuan, nama_subkategoritemuan')
          .eq('id_kategoritemuan', katId)
          .order('nama_subkategoritemuan');

      _allFactors = List<Map<String, dynamic>>.from(data);
      _filteredFactors = _allFactors;
    } catch (e) {
      debugPrint('Error fetching cause factor list: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredFactors = q.isEmpty
          ? _allFactors
          : _allFactors
              .where((f) => (f['nama_subkategoritemuan'] ?? '').toString().toLowerCase().contains(q))
              .toList();
    });
  }

  void _selectFactor(Map<String, dynamic> f) {
    Navigator.pop(context, {
      'id': f['id_subkategoritemuan'].toString(),
      'name': f['nama_subkategoritemuan'].toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 480,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.category_rounded, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _felt(widget.lang, 'Filter Faktor Penyebab', 'Filter Cause Factor', '筛选原因因素'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),

              // SEARCH FIELD
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _searchCtrl.text.isNotEmpty ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
                          decoration: InputDecoration(
                            hintText: _felt(widget.lang, 'Cari faktor penyebab...', 'Search cause factor...', '搜索原因因素...'),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFD97706)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // LIST FAKTOR
              Expanded(
                child: _loading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade50,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          itemCount: 6,
                          itemBuilder: (_, __) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            height: 56,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      )
                    : _filteredFactors.isEmpty
                        ? Center(
                            child: Text(
                              _felt(widget.lang, 'Tidak ada faktor ditemukan', 'No factors found', '未找到因素'),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: _filteredFactors.length,
                            itemBuilder: (_, i) {
                              final f = _filteredFactors[i];
                              return GestureDetector(
                                onTap: () => _selectFactor(f),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD97706).withValues(alpha: 0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.tag_rounded, size: 16, color: Color(0xFFD97706)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          f['nama_subkategoritemuan'] ?? '-',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}