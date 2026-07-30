import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../user/finding/detail/finding_detail_screen.dart';
import '../../user/home/card/finding_card.dart';
import '../../user/home/card/kts_finding_card.dart';
import '../../user/ktsproduksi/kts_detail_screen.dart';

class AssignedFindingsTab extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialData;
  final String Function(String) t;

  const AssignedFindingsTab({
    super.key,
    required this.lang,
    required this.t,
    this.initialData,
  });

  @override
  State<AssignedFindingsTab> createState() => _AssignedFindingsTabState();
}

class _AssignedFindingsTabState extends State<AssignedFindingsTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _sortOrder = 'terbaru';
  int _currentPage = 1;
  static const int _perPage = 5;

  static const Color _primary = Color(0xFF0284C7);
  static const Color _red = Color(0xFFDC2626);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _items = widget.initialData!;
    } else {
      _fetchFindings();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchFindings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('temuan')
          .select(
            'id_temuan, judul_temuan, gambar_temuan, created_at, '
            'status_temuan, poin_temuan, target_waktu_selesai, '
            'jenis_temuan, id_lokasi, id_unit, id_subunit, id_area, '
            'id_penanggung_jawab, is_pro, is_visitor, is_eksekutif, '
            'lokasi(nama_lokasi), unit(nama_unit), '
            'subunit(nama_subunit), area(nama_area)',
          )
          .eq('id_penanggung_jawab', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching findings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _lt(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  List<Map<String, dynamic>> get _unfinishedItems {
    return _items.where((e) {
      final s = (e['status_temuan'] ?? '').toString();
      return !['Selesai', 'done', 'completed', 'closed'].any((x) => s.contains(x));
    }).toList();
  }

  DateTime? _deadlineOf(Map<String, dynamic> e) =>
      DateTime.tryParse((e['target_waktu_selesai'] ?? '').toString());


  void _clearSearchAndFilter() {
    _searchCtrl.clear();
    setState(() {
      _search = '';
      _sortOrder = 'terbaru';
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get _processedItems {
    List<Map<String, dynamic>> result = List.from(_unfinishedItems);

    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      result = result
          .where((e) => (e['judul_temuan'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }

    switch (_sortOrder) {
      case 'terlama':
        result.sort((a, b) {
          final da = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime(2000);
          final db = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime(2000);
          return da.compareTo(db);
        });
        break;
      case 'deadline':
        final now = DateTime.now();
        result = result.where((e) {
          final d = _deadlineOf(e);
          return d != null && !d.isBefore(now);
        }).toList();
        result.sort((a, b) => _deadlineOf(a)!.compareTo(_deadlineOf(b)!));
        break;
      case 'terlewat':
        result = result.where((e) {
          final d = _deadlineOf(e);
          return d != null && d.isBefore(DateTime.now());
        }).toList();
        result.sort((a, b) => _deadlineOf(a)!.compareTo(_deadlineOf(b)!));
        break;
      case 'terbaru':
      default:
        result.sort((a, b) {
          final da = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime(2000);
          final db = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime(2000);
          return db.compareTo(da);
        });
        break;
    }

    return result;
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _AssignedFilterDialog(
        lang: widget.lang,
        currentSort: _sortOrder,
      ),
    );
    if (result == null) return;
    setState(() {
      if (result['action'] == 'reset') {
        _sortOrder = 'terbaru';
      } else if (result['action'] == 'apply') {
        _sortOrder = result['sort'] as String;
      }
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return _buildShimmer();

    final unfinishedTotal = _unfinishedItems.length;

    if (unfinishedTotal == 0) {
      return _buildEmpty(
        widget.t('empty_findings'),
        widget.t('empty_findings_sub'),
        Icons.assignment_ind_outlined,
      );
    }

    final allData = _processedItems;
    final totalPages = allData.isEmpty ? 1 : (allData.length / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > allData.length ? allData.length : startIdx + _perPage;
    final pageItems =
        allData.isEmpty ? <Map<String, dynamic>>[] : allData.sublist(startIdx, endIdx);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _red.withValues(alpha: 0.08),
              const Color(0xFFEF4444).withValues(alpha: 0.05),
            ]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _red.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.pending_actions_rounded, color: _red, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.lang == 'ID'
                    ? '$unfinishedTotal temuan masih menunggu penyelesaian Anda'
                    : '$unfinishedTotal findings are waiting for your action',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _red),
              ),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 8),
              _buildFilterButton(),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: pageItems.isEmpty
              ? _buildFilteredEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: pageItems.length,
                  itemBuilder: (context, index) {
                    final item = pageItems[index];
                    final jenis = (item['jenis_temuan'] ?? '').toString().toLowerCase();
                    final isKts = jenis.contains('kts');
                    final deadlineWidget = _buildDeadlineIndicator(item);

                    final Widget card = isKts
                        ? KtsFindingCard(
                            data: item,
                            lang: widget.lang,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KtsDetailScreen(
                                    ktsId: item['id_temuan'].toString(),
                                    lang: widget.lang,
                                    initialData: item,
                                  ),
                                ),
                              );
                            },
                          )
                        : FindingCard(
                            data: item,
                            lang: widget.lang,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FindingDetailScreen(
                                      initialData: item, lang: widget.lang),
                                ),
                              );
                            },
                          );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          card,
                          if (deadlineWidget != null) deadlineWidget,
                        ],
                      ),
                    );
                  },
                ),
        ),

        if (totalPages > 1)
          Padding(
            padding: EdgeInsets.fromLTRB(
              16, 4, 16, MediaQuery.of(context).viewPadding.bottom + 12,
            ),
            child: _AssignedFindingsPageIndicator(
              currentPage: safePage,
              totalPages: totalPages,
              onPageChanged: (p) => setState(() => _currentPage = p),
              color: _primary,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() {
          _search = v;
          _currentPage = 1;
        }),
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.poppins(fontSize: 13, color: _primary),
        decoration: InputDecoration(
          hintText: _lt('Cari temuan...', 'Search findings...', '搜索发现...'),
          hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
          prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 18),
          suffixIcon: _search.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() {
                      _search = '';
                      _currentPage = 1;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 14, color: _red),
                  ),
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  IconData _iconForSort(String sort) {
    switch (sort) {
      case 'terlama':
        return Icons.arrow_upward_rounded;
      case 'deadline':
        return Icons.timer_rounded;
      case 'terlewat':
        return Icons.warning_amber_rounded;
      case 'terbaru':
      default:
        return Icons.tune_rounded;
    }
  }

  Widget _buildFilterButton() {
    final bool isActive = _sortOrder != 'terbaru';
    return GestureDetector(
      onTap: _showFilterDialog,
      child: Container(
        height: 42,
        width: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _primary.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _primary : const Color(0xFFE2E8F0),
            width: isActive ? 1.4 : 1,
          ),
        ),
        child: Icon(
          _iconForSort(_sortOrder),
          color: isActive ? _primary : Colors.black45,
          size: 18,
        ),
      ),
    );
  }

  Widget? _buildDeadlineIndicator(Map<String, dynamic> item) {
    final deadline = _deadlineOf(item);
    if (deadline == null) return null;

    final now = DateTime.now();
    final difference = deadline.difference(now);
    late final Color color;
    late final IconData icon;
    late final String text;

    if (difference.isNegative) {
      color = Colors.red.shade700;
      icon = Icons.warning_amber_rounded;
      final over = difference.abs();
      if (over.inDays > 0) {
        text = '${over.inDays} ${_lt('hari terlewat', 'days overdue', '天逾期')}';
      } else if (over.inHours > 0) {
        text = '${over.inHours} ${_lt('jam terlewat', 'hours overdue', '小时逾期')}';
      } else {
        text = '${over.inMinutes} ${_lt('menit terlewat', 'minutes overdue', '分钟逾期')}';
      }
    } else {
      final days = difference.inDays;
      if (days == 0) {
        color = Colors.orange.shade800;
        icon = Icons.today_rounded;
        text = _lt('Deadline hari ini', 'Deadline today', '截止日期是今天');
      } else {
        color = Colors.green.shade800;
        icon = Icons.timer_outlined;
        text = '$days ${_lt('hari tersisa', 'days left', '天剩余')}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C9E4).withValues(alpha:0.08),
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF00C9E4).withValues(alpha:0.5)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredEmpty() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded,
                    size: 46, color: _primary.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _lt('Temuan Tidak Ditemukan', 'No matching findings', '未找到匹配的发现'),
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _lt(
                'Coba ubah kata kunci pencarian atau filter untuk menemukan yang Anda cari.',
                "Try adjusting your search keyword or filter to find what you're looking for.",
                '尝试调整搜索关键词或筛选条件以查找您需要的内容。',
              ),
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _clearSearchAndFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 15, color: _primary),
                    const SizedBox(width: 6),
                    Text(_lt('Hapus pencarian & filter', 'Clear search & filter', '清除搜索与筛选'),
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
                  ],
                ),
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
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class _AssignedFindingsPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _AssignedFindingsPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.color,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _arrowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: canPrev,
            onTap: () {
              if (!canPrev) return;
              onPageChanged(currentPage - 1);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (final p in pageNumbers) ...[
                  Expanded(child: _pageButton(p)),
                  if (p != pageNumbers.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _arrowButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: canNext,
            onTap: () {
              if (!canNext) return;
              onPageChanged(currentPage + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
              color: isActive ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.16) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}

class _AssignedFilterDialog extends StatefulWidget {
  final String lang;
  final String currentSort;

  const _AssignedFilterDialog({required this.lang, required this.currentSort});

  @override
  State<_AssignedFilterDialog> createState() => _AssignedFilterDialogState();
}

class _AssignedFilterDialogState extends State<_AssignedFilterDialog> {
  late String tempSort;

  String _lt(String id, String en, String zh) {
    if (widget.lang == 'ID') return id;
    if (widget.lang == 'ZH') return zh;
    return en;
  }

  @override
  void initState() {
    super.initState();
    tempSort = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 480,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
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
                          color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _lt('Filter Temuan Ditugaskan', 'Filter Assigned Findings', '筛选分配的发现'),
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1D72F3)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(_lt('Urutkan berdasarkan', 'Sort by', '排序依据'),
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildSortOption(
                        value: 'terbaru',
                        label: _lt('Temuan Terbaru', 'Newest Findings', '最新发现'),
                        icon: Icons.arrow_downward_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildSortOption(
                        value: 'terlama',
                        label: _lt('Temuan Terlama', 'Oldest Findings', '最旧的发现'),
                        icon: Icons.arrow_upward_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildSortOption(
                        value: 'deadline',
                        label: _lt('Mendekati Deadline', 'Nearest Deadline', '最近的截止日期'),
                        icon: Icons.timer_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildSortOption(
                        value: 'terlewat',
                        label: _lt('Sudah Terlewat', 'Overdue', '已逾期'),
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              // ACTION BUTTONS
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: const BoxDecoration(
                    color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => tempSort = 'terbaru'); 
                          Navigator.pop(context, {'action': 'reset', 'sort': 'terbaru'});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(_lt('Reset', 'Reset', '重置'),
                                style: const TextStyle(
                                    color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, {'action': 'apply', 'sort': tempSort}),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: Text(_lt('Terapkan', 'Apply', '应用'),
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ),
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

  Widget _buildSortOption({required String value, required String label, required IconData icon}) {
    final isActive = tempSort == value;
    return GestureDetector(
      onTap: () => setState(() => tempSort = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
              width: isActive ? 1.5 : 1),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF0284C7) : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: isActive ? Colors.white : const Color(0xFF0284C7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? const Color(0xFF0284C7) : const Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 8),
            if (isActive) const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF0284C7)),
          ],
        ),
      ),
    );
  }
}