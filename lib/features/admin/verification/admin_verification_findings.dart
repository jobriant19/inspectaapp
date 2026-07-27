import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'admin_verification_findings_detail.dart';
import 'admin_verification_indicator.dart';

class AdminVerificationFindingsTab extends StatefulWidget {
  final String lang;
  const AdminVerificationFindingsTab({super.key, required this.lang});

  @override
  State<AdminVerificationFindingsTab> createState() =>
      _AdminVerificationFindingsTabState();
}

class _AdminVerificationFindingsTabState
    extends State<AdminVerificationFindingsTab> {
  final _client = Supabase.instance.client;

  bool _temuanLoading = true;
  List<Map<String, dynamic>> _temuanList = [];
  String _temuanFilter = 'all';
  String _temuanSearch = '';
  final _temuanSearchCtrl = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 5;

  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _locationColor = Color(0xFF1D72F3);

  @override
  void initState() {
    super.initState();
    _loadTemuanVerifikasi();
  }

  @override
  void dispose() {
    _temuanSearchCtrl.dispose();
    super.dispose();
  }

  String t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  bool _isKts(Map<String, dynamic> item) {
    return (item['jenis_temuan']?.toString() ?? '') == 'KTS Production';
  }

  Color _typeColor(Map<String, dynamic> item) {
    return _isKts(item) ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
  }

  String _typeBadgeLabel(Map<String, dynamic> item) {
    return _isKts(item) ? 'KTS' : '5R';
  }

  String _locationLabel(Map<String, dynamic> item) {
    if (_isKts(item)) {
      final section = item['penyelesaian']?['section'];
      if (section == null) return '-';
      String? name;
      if (widget.lang == 'EN') {
        name = section['nama_section_en']?.toString();
      } else if (widget.lang == 'ZH') {
        name = section['nama_section_zh']?.toString();
      } else {
        name = section['nama_section_id']?.toString();
      }
      if (name == null || name.isEmpty) {
        name = section['nama_section_id']?.toString();
      }
      return (name != null && name.isNotEmpty) ? name : '-';
    }
    final area = item['area']?['nama_area']?.toString();
    if (area != null && area.isNotEmpty) return area;
    final subunit = item['subunit']?['nama_subunit']?.toString();
    if (subunit != null && subunit.isNotEmpty) return subunit;
    final unit = item['unit']?['nama_unit']?.toString();
    if (unit != null && unit.isNotEmpty) return unit;
    final lokasi = item['lokasi']?['nama_lokasi']?.toString();
    if (lokasi != null && lokasi.isNotEmpty) return lokasi;
    return '-';
  }

  void _openDetail(Map<String, dynamic> item, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminVerificationFindingsDetailScreen(
          lang: widget.lang,
          item: item,
          initialTab: initialTab,
        ),
      ),
    );
  }

  Future<void> _loadTemuanVerifikasi() async {
    setState(() => _temuanLoading = true);
    try {
      final response = await _client
        .from('temuan')
        .select('''
          id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, created_at, jenis_temuan,
          is_verif, hasil_verifikasi_mayoritas, status_temuan,
          target_waktu_selesai, poin_temuan, no_order, nama_item_manual, jumlah_item,
          is_pro, is_visitor, is_eksekutif, nama_visitor, perusahaan_visitor,
          is_late, latetime, id_perpanjang,
          subkategoritemuan:id_subkategoritemuan_uuid (
            nama_subkategoritemuan,
            kategoritemuan:id_kategoritemuan (nama_kategoritemuan)
          ),
          lokasi:id_lokasi (nama_lokasi),
          unit:id_unit (nama_unit),
          subunit:id_subunit (nama_subunit),
          area:id_area (nama_area),
          penanggung_jawab:id_penanggung_jawab (nama, gambar_user),
          perpanjang:id_perpanjang (waktu_perpanjang, alasan_perpanjang, tanggal_selesai),
          penyelesaian:id_penyelesaian (
            gambar_penyelesaian, catatan_penyelesaian, tanggal_selesai,
            penyebab, bagian, poin_penyelesaian, additional_cost,
            section:id_section (nama_section_id, nama_section_en, nama_section_zh),
            faktor_penyebab_sub:id_subkategoritemuan_penyebab (nama_subkategoritemuan)
          )
        ''')
        .eq('status_temuan', 'Selesai')
        .order('created_at', ascending: false);

      final rawList = response as List;

      final ids = rawList
          .map((r) => r['id_temuan']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      final Map<String, Map<String, int>> voteMap = {};

      if (ids.isNotEmpty) {
        final votes = await _client
            .from('verifikasi_log')
            .select('id_temuan, jawaban_benar')
            .inFilter('id_temuan', ids);

        for (final v in votes) {
          final id = v['id_temuan']?.toString() ?? '';
          if (id.isEmpty) continue;
          voteMap.putIfAbsent(id, () => {'valid': 0, 'invalid': 0});
          if (v['jawaban_benar'] == true) {
            voteMap[id]!['valid'] = voteMap[id]!['valid']! + 1;
          } else {
            voteMap[id]!['invalid'] = voteMap[id]!['invalid']! + 1;
          }
        }
      }

      final list = rawList.map<Map<String, dynamic>>((item) {
        final id = item['id_temuan']?.toString() ?? '';
        final stats = voteMap[id] ?? {'valid': 0, 'invalid': 0};
        final int v = stats['valid'] ?? 0;
        final int iv = stats['invalid'] ?? 0;
        return {
          ...Map<String, dynamic>.from(item as Map),
          'vote_valid': v,
          'vote_invalid': iv,
          'total_votes': v + iv,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _temuanList = list;
          _temuanLoading = false;
        });
      }
    } catch (e) {
      debugPrint('loadTemuanVerifikasi error: $e');
      if (mounted) setState(() => _temuanLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTemuan {
    var list = _temuanList;
    if (_temuanFilter == 'finalized') {
      list = list.where((i) => i['is_verif'] == true).toList();
    } else if (_temuanFilter == 'pending') {
      list = list.where((i) => i['is_verif'] != true).toList();
    }
    if (_temuanSearch.isNotEmpty) {
      final q = _temuanSearch.toLowerCase();
      list = list.where((i) =>
          (i['judul_temuan']?.toString() ?? '').toLowerCase().contains(q) ||
          (i['lokasi']?['nama_lokasi']?.toString() ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredTemuan;
    final totalPages = items.isEmpty ? 1 : (items.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final pageStart = (_currentPage - 1) * _itemsPerPage;
    final pageEnd = (pageStart + _itemsPerPage).clamp(0, items.length);
    final pageItems =
        items.isEmpty ? <Map<String, dynamic>>[] : items.sublist(pageStart, pageEnd);

    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: _temuanLoading
              ? _buildListShimmer()
              : items.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadTemuanVerifikasi,
                      color: _primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: pageItems.length,
                        itemBuilder: (_, i) =>
                            _buildTemuanCard(pageItems[i]),
                      ),
                    ),
        ),
        if (!_temuanLoading && totalPages > 1)
          AdminVerificationIndicator(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: (p) => setState(() => _currentPage = p),
          ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        children: [
          TextField(
            controller: _temuanSearchCtrl,
            onChanged: (v) => setState(() {
              _temuanSearch = v;
              _currentPage = 1;
            }),
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: t('Cari...', 'Search...', '搜索...'),
              hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: _primaryColor, size: 18),
              suffixIcon: _temuanSearchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _temuanSearchCtrl.clear();
                      setState(() {
                        _temuanSearch = '';
                        _currentPage = 1;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Color(0xFFEF4444)),
                    ),
                  )
                : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
          ),
          const SizedBox(height: 10),
          _buildStatusFilterRow(),
        ],
      ),
    );
  }

  Widget _buildStatusFilterRow() {
    final options = <Map<String, dynamic>>[
      {
        'value': 'all',
        'label': t('Semua', 'All', '全部'),
        'icon': Icons.list_alt_rounded,
        'color': _primaryColor,
      },
      {
        'value': 'pending',
        'label': t('Pending', 'Pending', '待定'),
        'icon': Icons.pending_rounded,
        'color': Colors.orange.shade500,
      },
      {
        'value': 'finalized',
        'label': t('Final', 'Finalized', '已完成'),
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF16A34A),
      },
    ];

    return Row(
      children: options.map((opt) {
        final value = opt['value'] as String;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final color = opt['color'] as Color;
        final isSelected = _temuanFilter == value;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _temuanFilter = value;
              _currentPage = 1;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: isSelected ? Colors.white : color),
                  const SizedBox(width: 5),
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : color)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemuanCard(Map<String, dynamic> item) {
    final bool? finalOutcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final int validVotes = item['vote_valid'] as int? ?? 0;
    final int invalidVotes = item['vote_invalid'] as int? ?? 0;
    final int totalVotes = item['total_votes'] as int? ?? 0;
    final String? imageUrl = item['gambar_temuan']?.toString();
    final String title = item['judul_temuan']?.toString() ?? '-';
    final String lokasi = _locationLabel(item);
    final Color typeColor = _typeColor(item);
    final String typeBadge = _typeBadgeLabel(item);

    String dateStr = '-';
    try {
      final dt = DateTime.parse(item['created_at']?.toString() ?? '').toLocal();
      dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {}

    final double validRatio = totalVotes > 0 ? validVotes / totalVotes : 0.0;
    final bool hasVotes = totalVotes > 0;
    const Color validVoteColor = Color(0xFF16A34A);
    const Color invalidVoteColor = Color(0xFFE11D48);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: typeColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: typeColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 96,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      bottomLeft: Radius.circular(4)),
                ),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openDetail(item, initialTab: 0),
                      child: _buildHistoryThumb(
                        url: imageUrl,
                        label: t('Temuan', 'Finding', '发现'),
                        icon: Icons.search_rounded,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _openDetail(item, initialTab: 1),
                      child: _buildHistoryThumb(
                        url: item['penyelesaian']?['gambar_penyelesaian']?.toString(),
                        label: t('Selesai', 'Completion', '完成'),
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openDetail(item, initialTab: 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                height: 1.25)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _locationColor.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _locationColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.map_rounded,
                                size: 11, color: _locationColor),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(lokasi,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: _locationColor)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.access_time_filled_rounded,
                                size: 11, color: Colors.grey.shade700),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(dateStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF334155))),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openDetail(item, initialTab: 0),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: typeColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Text(typeBadge,
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 1,
              color: typeColor.withValues(alpha: 0.12)),

          GestureDetector(
            onTap: () => _openDetail(item, initialTab: 0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.how_to_vote_rounded,
                          size: 13,
                          color: const Color(0xFF134E4A).withValues(alpha: 0.7)),
                      const SizedBox(width: 5),
                      Text(t('Rincian Suara', 'Vote Breakdown', '投票详情'),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF134E4A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.thumb_up_rounded,
                            size: 11, color: validVoteColor),
                        const SizedBox(width: 3),
                        Text('$validVotes ${t("Valid", "Valid", "有效")}',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: validVoteColor)),
                      ]),
                      Row(children: [
                        Text('$invalidVotes ${t("Tidak Valid", "Invalid", "无效")}',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: invalidVoteColor)),
                        const SizedBox(width: 3),
                        Icon(Icons.thumb_down_rounded,
                            size: 11, color: invalidVoteColor),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: hasVotes
                        ? Stack(children: [
                            Container(
                                height: 8,
                                width: double.infinity,
                                color: const Color(0xFFE11D48).withValues(alpha: 0.18)),
                            FractionallySizedBox(
                              widthFactor: validRatio.clamp(0.0, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [Color(0xFF16A34A), Color(0xFF4ADE80)]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ])
                        : Container(
                            height: 8,
                            width: double.infinity,
                            color: Colors.grey.shade300,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: finalOutcome == null
                              ? Colors.orange.withValues(alpha: 0.1)
                              : finalOutcome
                                  ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                                  : const Color(0xFFDC2626).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: finalOutcome == null
                                ? Colors.orange.withValues(alpha: 0.35)
                                : finalOutcome
                                    ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                                    : const Color(0xFFDC2626).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: finalOutcome == null
                                    ? Colors.orange
                                    : finalOutcome
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  finalOutcome == null
                                      ? Icons.hourglass_empty_rounded
                                      : finalOutcome
                                          ? Icons.thumb_up_rounded
                                          : Icons.thumb_down_rounded,
                                  size: 14,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(t('Hasil Mayoritas', 'Majority Result', '多数结果'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black)),
                                  const SizedBox(height: 1),
                                  Text(
                                      finalOutcome == null
                                          ? t('Menunggu', 'Pending', '待定')
                                          : finalOutcome
                                              ? t('Valid', 'Valid', '有效')
                                              : t('Tidak Valid', 'Invalid', '无效'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.how_to_vote_rounded,
                                  size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(t('Total Suara', 'Total Votes', '总票数'),
                                      style: GoogleFonts.poppins(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black)),
                                  const SizedBox(height: 1),
                                  Text('$totalVotes ${t("suara", "votes", "票")}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryThumb({
    required String? url,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 9, color: color),
              const SizedBox(width: 3),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1.0)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: Colors.grey.shade100,
            child: (url != null && url.isNotEmpty)
                ? Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        size: 20,
                        color: Colors.grey.shade400))
                : Icon(Icons.image_not_supported_outlined,
                    size: 20, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final bool isFiltering = _temuanSearch.isNotEmpty || _temuanFilter != 'all';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              height: 170,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off_rounded,
                    size: 56, color: _primaryColor.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isFiltering
                  ? t('Tidak Ditemukan', 'Not Found', '未找到匹配项')
                  : t('Belum Ada Data', 'No Data Yet', '暂无数据'),
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? t(
                      'Coba ubah kata kunci pencarian atau filter untuk menemukan yang Anda cari.',
                      'Try adjusting your search keyword or filter to find what you\'re looking for.',
                      '尝试调整搜索关键词或筛选条件以查找您需要的内容。')
                  : t(
                      'Temuan yang sudah selesai akan muncul di sini untuk diverifikasi.',
                      'Completed findings will show up here for verification.',
                      '已完成的发现将显示在此处以供验证。'),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  _temuanSearchCtrl.clear();
                  setState(() {
                    _temuanSearch = '';
                    _temuanFilter = 'all';
                    _currentPage = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _primaryColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: _primaryColor),
                      const SizedBox(width: 6),
                      Text(t('Hapus pencarian & filter', 'Clear search & filter', '清除搜索与筛选'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: _primaryColor)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}