import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KtsKasieItem {
  final String id;
  final String nama;
  const KtsKasieItem({required this.id, required this.nama});
}

class KtsKasiePickResult {
  final bool isAllKasie;
  final String? kasieId;
  final String? kasieNama;

  const KtsKasiePickResult.all()
      : isAllKasie = true,
        kasieId = null,
        kasieNama = null;

  const KtsKasiePickResult.kasie(this.kasieId, this.kasieNama)
      : isAllKasie = false;
}

Future<KtsKasiePickResult?> showKtsKasiePicker(
  BuildContext context, {
  required String lang,
  required List<KtsKasieItem> kasieList,
  Color accentColor = const Color(0xFFAB47BC),
}) {
  return showDialog<KtsKasiePickResult>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: _KtsKasiePickerSheet(lang: lang, accentColor: accentColor, kasieList: kasieList),
    ),
  );
}

class _KtsKasiePickerSheet extends StatefulWidget {
  final String lang;
  final Color accentColor;
  final List<KtsKasieItem> kasieList;
  const _KtsKasiePickerSheet({required this.lang, required this.accentColor, required this.kasieList});

  @override
  State<_KtsKasiePickerSheet> createState() => _KtsKasiePickerSheetState();
}

class _KtsKasiePickerSheetState extends State<_KtsKasiePickerSheet> {
  Color get _kPrimary => widget.accentColor;
  Color get _kPrimaryLight => widget.accentColor.withValues(alpha: 0.08);
  Color get _kBorder => widget.accentColor.withValues(alpha: 0.35);

  final TextEditingController _searchCtrl = TextEditingController();
  List<KtsKasieItem> _filtered = [];
  int _currentPage = 1;
  static const int _perPage = 5;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.kasieList)..sort((a, b) => a.nama.compareTo(b.nama));
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = widget.kasieList
          .where((k) => q.isEmpty || k.nama.toLowerCase().contains(q))
          .toList()
        ..sort((a, b) => a.nama.compareTo(b.nama));
      _currentPage = 1;
    });
  }

  Widget _buildCountLabel() {
    final count = _filtered.length;
    final text = widget.lang == 'EN'
        ? '$count kasie'
        : widget.lang == 'ZH'
            ? '$count 位科长'
            : '$count kasie';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_outline_rounded, size: 12, color: _kPrimary),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kPrimary)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    final hasQuery = _searchCtrl.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(Icons.person_search_rounded, size: 40, color: _kPrimary.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 14),
        Text(_t('Tidak ada kasie', 'No kasie found', '未找到科长'),
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
            textAlign: TextAlign.center),
        if (hasQuery) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _searchCtrl.clear(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, size: 14, color: _kPrimary),
                const SizedBox(width: 6),
                Text(_t('Hapus pencarian', 'Clear search', '清除搜索'),
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildKasieCard(KtsKasieItem k) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context, KtsKasiePickResult.kasie(k.id, k.nama)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.person_rounded, color: _kPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(k.nama,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 480 ? 480.0 : size.width - 40;
    final dialogHeight = (size.height * 0.78).clamp(420.0, 640.0);

    final totalPages = _filtered.isEmpty ? 1 : (_filtered.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final start = (safePage - 1) * _perPage;
    final end = (start + _perPage) > _filtered.length ? _filtered.length : start + _perPage;
    final pageItems = _filtered.isEmpty ? <KtsKasieItem>[] : _filtered.sublist(start, end);

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.supervisor_account_rounded, color: _kPrimary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_t('Pilih Kasie', 'Select Kasie', '选择科长'),
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder, width: 1.2),
              ),
              child: TextField(
                controller: _searchCtrl,
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: _t('Cari kasie...', 'Search kasie...', '搜索科长...'),
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFBDBDBD), fontWeight: FontWeight.w600),
                  prefixIcon: Icon(CupertinoIcons.search, color: _kPrimary, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: Container(
                            margin: const EdgeInsets.all(10),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                          ),
                        )
                      : null,
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Align(alignment: Alignment.centerLeft, child: _buildCountLabel()),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 14),
          Expanded(
            child: Column(children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context, const KtsKasiePickResult.all()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: _kPrimaryLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kPrimary.withValues(alpha: 0.35)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(CupertinoIcons.square_stack_3d_up_fill, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_t('Semua Kasie', 'All Kasie', '所有科长'),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: _kPrimary)),
                            ),
                            Icon(CupertinoIcons.chevron_right, size: 14, color: _kPrimary),
                          ]),
                        ),
                      ),
                    ),
                    if (_filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...pageItems.map(_buildKasieCard),
                  ],
                ),
              ),
              if (totalPages > 1 && _filtered.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _KasiePagePickerIndicator(
                    currentPage: safePage,
                    totalPages: totalPages,
                    color: _kPrimary,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _KasiePagePickerIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;
  final ValueChanged<int> onPageChanged;

  const _KasiePagePickerIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.color,
    required this.onPageChanged,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) { start = 1; end = _maxVisibleButtons; }
    else if (end > totalPages) { end = totalPages; start = totalPages - (_maxVisibleButtons - 1); }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: canPrev ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: canPrev ? color : Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(children: [
            for (final p in pageNumbers) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => p == currentPage ? null : onPageChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p == currentPage ? color : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: p == currentPage ? null : Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Text('$p',
                        style: GoogleFonts.poppins(color: p == currentPage ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ),
              if (p != pageNumbers.last) const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: canNext ? () => onPageChanged(currentPage + 1) : null,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: canNext ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 15, color: canNext ? color : Colors.grey.shade400),
          ),
        ),
      ]),
    );
  }
}