import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _accentColor = Color(0xFF0D9488);

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

  // ── Helper jenis_temuan & lokasi spesifik ──
  bool _isKts(Map<String, dynamic> item) {
    return (item['jenis_temuan']?.toString() ?? '') == 'KTS Production';
  }

  Color _typeColor(Map<String, dynamic> item) {
    return _isKts(item) ? const Color(0xFFF97316) : const Color(0xFF2563EB);
  }

  String _subkategoriLabel(Map<String, dynamic> item) {
    return item['subkategoritemuan']?['nama_subkategoritemuan']?.toString() ?? '-';
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

  // ══════════════════════════════════════════════
  // LOAD TEMUAN VERIFIKASI
  // ══════════════════════════════════════════════

  Future<void> _loadTemuanVerifikasi() async {
    setState(() => _temuanLoading = true);
    try {
      final response = await _client
          .from('temuan')
          .select('''
            id_temuan, judul_temuan, gambar_temuan, created_at, jenis_temuan,
            is_verif, hasil_verifikasi_mayoritas, status_temuan,
            subkategoritemuan:id_subkategoritemuan_uuid (nama_subkategoritemuan),
            lokasi:id_lokasi (nama_lokasi),
            unit:id_unit (nama_unit),
            subunit:id_subunit (nama_subunit),
            area:id_area (nama_area),
            penyelesaian:id_penyelesaian (
              gambar_penyelesaian, catatan_penyelesaian,
              section:id_section (nama_section_id, nama_section_en, nama_section_zh)
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

  void _showTemuanDetail(Map<String, dynamic> item) {
    final bool isFinalized = item['is_verif'] as bool? ?? false;
    final bool? outcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final int validVotes = item['vote_valid'] as int? ?? 0;
    final int invalidVotes = item['vote_invalid'] as int? ?? 0;
    final int totalVotes = item['total_votes'] as int? ?? 0;
    final String? imageUrl = item['gambar_temuan']?.toString();
    final String title = item['judul_temuan']?.toString() ?? '-';
    final String lokasi = _locationLabel(item);
    final String subkategori = _subkategoriLabel(item);

    String dateStr = '-';
    try {
      final dt =
          DateTime.parse(item['created_at']?.toString() ?? '').toLocal();
      dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {}

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    if (!isFinalized) {
      statusColor = Colors.orange.shade500;
      statusIcon = Icons.pending_rounded;
      statusLabel = t('Menunggu', 'Pending', '待定');
    } else if (outcome == true) {
      statusColor = const Color(0xFF16A34A);
      statusIcon = Icons.check_circle_rounded;
      statusLabel = t('Valid', 'Valid', '有效');
    } else {
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
      statusLabel = t('Tidak Valid', 'Invalid', '无效');
    }

    final double validRatio =
        totalVotes > 0 ? validVotes / totalVotes : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0FDF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _accentColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Detail Temuan', 'Finding Detail', '发现详情'),
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                          Text(dateStr,
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        Icon(statusIcon, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(statusLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey.shade100,
                              child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48)),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF134E4A))),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildAdminDetailRow(Icons.map_rounded,
                              t('Lokasi', 'Location', '地点'), lokasi),
                          _buildAdminDetailRow(Icons.category_outlined,
                              t('Sub Kategori', 'Subcategory', '子类别'), subkategori),
                          _buildAdminDetailRow(Icons.calendar_today,
                              t('Tanggal', 'Date', '日期'), dateStr),
                          _buildAdminDetailRow(
                            Icons.verified_rounded,
                            t('Status', 'Status', '状态'),
                            isFinalized
                                ? t('Final', 'Finalized', '已完成')
                                : t('Menunggu', 'Pending', '待定'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Statistik Verifikasi', 'Verification Statistics', '验证统计'),
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF134E4A)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                const Icon(Icons.thumb_up_rounded,
                                    size: 11, color: Color(0xFF16A34A)),
                                const SizedBox(width: 3),
                                Text('$validVotes ${t("Valid", "Valid", "有效")}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF16A34A))),
                              ]),
                              Text('$totalVotes ${t("Total Suara", "Total Votes", "总票数")}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10, color: Colors.grey.shade500)),
                              Row(children: [
                                Text('$invalidVotes ${t("Tidak Valid", "Invalid", "无效")}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFDC2626))),
                                const SizedBox(width: 3),
                                const Icon(Icons.thumb_down_rounded,
                                    size: 11, color: Color(0xFFDC2626)),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(children: [
                              Container(
                                  height: 8,
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.18)),
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
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(statusIcon, size: 18, color: statusColor),
                                const SizedBox(width: 8),
                                Text(
                                  '${t("Hasil Mayoritas", "Majority Result", "多数结果")}: $statusLabel',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade500)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF134E4A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: _temuanLoading
              ? _buildListShimmer()
              : _filteredTemuan.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadTemuanVerifikasi,
                      color: _primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: _filteredTemuan.length,
                        itemBuilder: (_, i) =>
                            _buildTemuanCard(_filteredTemuan[i]),
                      ),
                    ),
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
            onChanged: (v) => setState(() => _temuanSearch = v),
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
                        setState(() => _temuanSearch = '');
                      },
                      child: Icon(Icons.clear_rounded,
                          color: Colors.grey.shade400, size: 18))
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
            onTap: () => setState(() => _temuanFilter = value),
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
    final bool isFinalized = item['is_verif'] as bool? ?? false;
    final bool? finalOutcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final int validVotes = item['vote_valid'] as int? ?? 0;
    final int invalidVotes = item['vote_invalid'] as int? ?? 0;
    final int totalVotes = item['total_votes'] as int? ?? 0;
    final String? imageUrl = item['gambar_temuan']?.toString();
    final String title = item['judul_temuan']?.toString() ?? '-';
    final String lokasi = _locationLabel(item);
    final String subkategori = _subkategoriLabel(item);
    final Color typeColor = _typeColor(item);

    String dateStr = '-';
    try {
      final dt = DateTime.parse(item['created_at']?.toString() ?? '').toLocal();
      dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {}

    Color accent;
    IconData statusIcon;
    String statusLabel;
    if (!isFinalized || finalOutcome == null) {
      accent = Colors.orange.shade400;
      statusLabel = t('Menunggu', 'Pending', '待定');
      statusIcon = Icons.hourglass_empty_rounded;
    } else {
      accent = finalOutcome ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
      statusLabel = finalOutcome ? t('Valid', 'Valid', '有效') : t('Tidak Valid', 'Invalid', '无效');
      statusIcon = finalOutcome ? Icons.emoji_events_rounded : Icons.highlight_off_rounded;
    }

    final double validRatio = totalVotes > 0 ? validVotes / totalVotes : 0.0;

    return GestureDetector(
      onTap: () => _showTemuanDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.08),
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
                  width: 6,
                  height: 96,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(19),
                        bottomLeft: Radius.circular(4)),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      _buildHistoryThumb(
                        url: imageUrl,
                        label: t('Temuan', 'Finding', '发现'),
                        icon: Icons.search_rounded,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 6),
                      _buildHistoryThumb(
                        url: item['penyelesaian']?['gambar_penyelesaian']?.toString(),
                        label: t('Selesai', 'Completion', '完成'),
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
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
                                color: const Color(0xFF134E4A),
                                height: 1.25)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.map_rounded,
                                size: 10, color: typeColor),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(lokasi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: typeColor)),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.access_time_rounded,
                                size: 10, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(dateStr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 6),
                        constraints: const BoxConstraints(maxWidth: 76),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: typeColor.withValues(alpha: 0.35)),
                        ),
                        child: Text(subkategori,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: typeColor)),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Icon(statusIcon, color: accent, size: 22),
                      ),
                      const SizedBox(height: 3),
                      Text(statusLabel,
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                    ],
                  ),
                ),
              ],
            ),

            Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 1,
                color: accent.withValues(alpha: 0.12)),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.how_to_vote_rounded,
                            size: 13,
                            color: const Color(0xFF134E4A).withValues(alpha: 0.7)),
                        const SizedBox(width: 5),
                        Text(t('Rincian Suara', 'Vote Breakdown', '投票详情'),
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF134E4A))),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isFinalized
                              ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isFinalized
                                ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                              isFinalized
                                  ? Icons.verified_rounded
                                  : Icons.pending_rounded,
                              size: 10,
                              color: isFinalized
                                  ? const Color(0xFF16A34A)
                                  : Colors.orange),
                          const SizedBox(width: 3),
                          Text(
                              isFinalized
                                  ? t('Final', 'Finalized', '已完成')
                                  : t('Berlangsung', 'In Progress', '进行中'),
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isFinalized
                                      ? const Color(0xFF16A34A)
                                      : Colors.orange)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.thumb_up_rounded,
                            size: 11, color: Color(0xFF16A34A)),
                        const SizedBox(width: 3),
                        Text('$validVotes ${t("Valid", "Valid", "有效")}',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF16A34A))),
                      ]),
                      Row(children: [
                        Text('$invalidVotes ${t("Tidak Valid", "Invalid", "无效")}',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626))),
                        const SizedBox(width: 3),
                        const Icon(Icons.thumb_down_rounded,
                            size: 11, color: Color(0xFFDC2626)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(children: [
                      Container(
                          height: 8,
                          width: double.infinity,
                          color: const Color(0xFFDC2626).withValues(alpha: 0.18)),
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
                    ]),
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
                                          color: Colors.grey.shade600)),
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
                                          fontWeight: FontWeight.w800,
                                          color: finalOutcome == null
                                              ? Colors.orange.shade700
                                              : finalOutcome
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFDC2626))),
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
                                          color: Colors.grey.shade600)),
                                  const SizedBox(height: 1),
                                  Text('$totalVotes ${t("suara", "votes", "票")}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF1E3A8A))),
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
          ],
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 9, color: color),
              const SizedBox(width: 3),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: color)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            t('Tidak ada data.', 'No data found.', '未找到数据。'),
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
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