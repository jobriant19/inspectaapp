import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _kAccentGreen = Color(0xFF16A34A);
const Color _kAccentGreenLight = Color(0xFFF0FDF4);
const Color _kAccentGreenBorder = Color(0xFFBBF7D0);

const double _kFactorDialogWidth = 340;
const double _kFactorDialogHeightFactor = 0.72;

Future<Map<String, dynamic>?> showKtsPickFactorDialog(
  BuildContext context, {
  required String lang,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _KtsPickFactorDialog(lang: lang),
  );
}

Widget _factorPickerShimmerList() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 56,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _KtsPickFactorDialog extends StatefulWidget {
  final String lang;
  const _KtsPickFactorDialog({required this.lang});

  @override
  State<_KtsPickFactorDialog> createState() => _KtsPickFactorDialogState();
}

class _KtsPickFactorDialogState extends State<_KtsPickFactorDialog> {
  List<Map<String, dynamic>> _allFactors = [];
  List<Map<String, dynamic>> _filteredFactors = [];
  bool _isLoading = true;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadFactors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _title(String lang) {
    switch (lang) {
      case 'EN':
        return 'Select Cause Factor';
      case 'ZH':
        return '选择原因因素';
      default:
        return 'Pilih Faktor Penyebab';
    }
  }

  String _searchHint(String lang) {
    switch (lang) {
      case 'EN':
        return 'Type cause factor name...';
      case 'ZH':
        return '输入原因因素名称搜索...';
      default:
        return 'Ketik nama faktor penyebab...';
    }
  }

  String _emptyText(String lang) {
    switch (lang) {
      case 'EN':
        return 'No cause factors found';
      case 'ZH':
        return '未找到原因因素';
      default:
        return 'Faktor penyebab tidak ditemukan';
    }
  }

  String _countLabel(String lang) {
    final n = _filteredFactors.length;
    switch (lang) {
      case 'EN':
        return '$n factors';
      case 'ZH':
        return '$n 个因素';
      default:
        return '$n faktor';
    }
  }

  Future<void> _loadFactors() async {
    setState(() => _isLoading = true);
    try {
      final katData = await Supabase.instance.client
          .from('kategoritemuan')
          .select('id_kategoritemuan')
          .eq('nama_kategoritemuan', 'KTS Produksi')
          .maybeSingle();
      if (katData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final String katId = katData['id_kategoritemuan'].toString();

      final data = await Supabase.instance.client
          .from('subkategoritemuan')
          .select('id_subkategoritemuan, nama_subkategoritemuan')
          .eq('id_kategoritemuan', katId)
          .order('nama_subkategoritemuan');

      final factors = List<Map<String, dynamic>>.from(data);
      if (mounted) {
        setState(() {
          _allFactors = factors;
          _filteredFactors = _applySearch(factors);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error load cause factors: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> src) {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return src;
    return src
        .where((f) => (f['nama_subkategoritemuan']?.toString() ?? '').toLowerCase().contains(q))
        .toList();
  }

  void _onSearch() => setState(() => _filteredFactors = _applySearch(_allFactors));

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: _kFactorDialogWidth,
        height: screenHeight * _kFactorDialogHeightFactor,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kAccentGreenLight, width: 1.5),
        ),
        child: Column(children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _kAccentGreenLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(CupertinoIcons.tag_fill, color: _kAccentGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title(widget.lang),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: _kAccentGreen),
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

          // SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kAccentGreen.withValues(alpha: 0.4), width: 1.3),
                boxShadow: [BoxShadow(color: _kAccentGreen.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: _searchHint(widget.lang),
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFBDBDBD)),
                  prefixIcon: const Icon(CupertinoIcons.search, color: _kAccentGreen, size: 19),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: _kAccentGreenLight, shape: BoxShape.circle),
                            child: const Icon(CupertinoIcons.xmark, size: 13, color: _kAccentGreen),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // COUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kAccentGreenLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccentGreenBorder),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(CupertinoIcons.tag_fill, size: 12, color: _kAccentGreen),
                  const SizedBox(width: 6),
                  Text(
                    _countLabel(widget.lang),
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kAccentGreen),
                  ),
                ]),
              ),
            ]),
          ),
          const Divider(height: 1, color: _kAccentGreenBorder),

          // LIST
          Expanded(
            child: _isLoading
                ? _factorPickerShimmerList()
                : _filteredFactors.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(CupertinoIcons.tag, size: 44, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),
                          Text(_emptyText(widget.lang), style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        itemCount: _filteredFactors.length,
                        itemBuilder: (_, i) {
                          final f = _filteredFactors[i];
                          final name = f['nama_subkategoritemuan']?.toString() ?? '-';
                          return InkWell(
                            onTap: () => Navigator.pop(context, f),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kAccentGreenBorder),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: _kAccentGreenLight, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(CupertinoIcons.tag_fill, color: _kAccentGreen, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                  ),
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