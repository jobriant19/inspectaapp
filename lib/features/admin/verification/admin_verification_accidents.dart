import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'admin_verification_accidents_detail.dart';
import 'admin_verification_indicator.dart';

class AdminVerificationAccidentsTab extends StatefulWidget {
  final String lang;
  const AdminVerificationAccidentsTab({super.key, required this.lang});

  @override
  State<AdminVerificationAccidentsTab> createState() =>
      _AdminVerificationAccidentsTabState();
}

class _AdminVerificationAccidentsTabState
    extends State<AdminVerificationAccidentsTab> {
  final _client = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _list = [];
  String _filter = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 5;

  static const Color _accentColor = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _loadAccidentVerifikasi();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  Future<void> _loadAccidentVerifikasi() async {
    setState(() => _loading = true);
    try {
      final response = await _client
          .from('accident_report')
          .select('''
            id_laporan, judul, deskripsi, foto_bukti, created_at, updated_at,
            tanggal_kejadian, waktu_kejadian, penyebab, tingkat_keparahan,
            departemen_terdampak, tindakan_diambil, status, poin_laporan,
            is_verif, hasil_verifikasi_mayoritas,
            nama_pihak_terdampak, nama_saksi,
            lokasi:id_lokasi (nama_lokasi),
            pelapor:id_pelapor (nama, gambar_user),
            supervisor:id_supervisor (nama),
            pihak_terdampak:id_pihak_terdampak (nama, gambar_user),
            saksi:id_saksi (nama, gambar_user),
            resolution:resolution_accident (
              id_resolution, judul_resolusi, deskripsi_resolusi,
              tindakan_korektif, tindakan_preventif, tanggal_resolusi, foto_resolusi,
              hrd:id_hrd (nama, gambar_user)
            )
          ''')
          .order('created_at', ascending: false);

      final ids = (response as List).map((r) => r['id_laporan']).toList();
      Map<String, Map<String, int>> voteMap = {};

      if (ids.isNotEmpty) {
        final votes = await _client
            .from('accident_verifikasi_log')
            .select('id_laporan, jawaban_benar')
            .inFilter('id_laporan', ids);

        for (final v in votes) {
          final id = v['id_laporan']?.toString() ?? '';
          voteMap.putIfAbsent(id, () => {'valid': 0, 'invalid': 0});
          if (v['jawaban_benar'] == true) {
            voteMap[id]!['valid'] = voteMap[id]!['valid']! + 1;
          } else {
            voteMap[id]!['invalid'] = voteMap[id]!['invalid']! + 1;
          }
        }
      }

      Map<String, Map<String, Map<String, String>>> verifDetailMapAll = {};
      if (ids.isNotEmpty) {
        try {
          final allVoteLogs = await _client
              .from('accident_verifikasi_log')
              .select('''
                id_laporan,
                jawaban_benar,
                id_verificator,
                waktu_verifikasi,
                verificator:id_verificator (
                  nama,
                  id_jabatan,
                  gambar_user,
                  jabatan:id_jabatan (nama_jabatan)
                )
              ''')
              .inFilter('id_laporan', ids);

          for (final v in allVoteLogs) {
            final lid = v['id_laporan']?.toString() ?? '';
            final vid = v['id_verificator']?.toString();
            if (vid == null) continue;
            final rawVerif = v['verificator'];
            if (rawVerif == null) continue;
            final nama = rawVerif['nama']?.toString() ?? vid;
            final jabatanId = rawVerif['id_jabatan'];
            final jabatanName = rawVerif['jabatan']?['nama_jabatan']?.toString() ?? '';
            final fotoUrl = rawVerif['gambar_user']?.toString() ?? '';
            verifDetailMapAll.putIfAbsent(lid, () => {});
            verifDetailMapAll[lid]![vid] = {
              'nama': nama,
              'jabatan': jabatanName,
              'jabatan_id': jabatanId?.toString() ?? '',
              'foto_url': fotoUrl,
            };
          }
        } catch (e) {
          debugPrint('loadVerifDetail error: $e');
        }
      }

      final list = (response).map<Map<String, dynamic>>((item) {
        final id = item['id_laporan']?.toString() ?? '';
        final stats = voteMap[id] ?? {'valid': 0, 'invalid': 0};
        return {
          ...Map<String, dynamic>.from(item as Map),
          'vote_valid': stats['valid'],
          'vote_invalid': stats['invalid'],
          'total_votes': (stats['valid']! + stats['invalid']!),
          'verif_detail_map': verifDetailMapAll[id] ?? {},
        };
      }).toList();

      if (mounted) {
        setState(() {
          _list = list;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('loadAccidentVerifikasi error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    var list = _list;
    if (_filter == 'finalized') {
      list = list.where((i) => i['is_verif'] == true).toList();
    } else if (_filter == 'pending') {
      list = list.where((i) => i['is_verif'] != true).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((i) =>
          (i['judul']?.toString() ?? '').toLowerCase().contains(q) ||
          (i['lokasi']?['nama_lokasi']?.toString() ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Color _severityColor(String severity) {
    return severity == 'Berat'
        ? const Color(0xFFDC2626)
        : severity == 'Menengah'
            ? const Color(0xFFF97316)
            : const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredList;
    final totalPages = items.isEmpty ? 1 : (items.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final pageStart = (_currentPage - 1) * _itemsPerPage;
    final pageEnd = (pageStart + _itemsPerPage).clamp(0, items.length);
    final pageItems = items.isEmpty ? <Map<String, dynamic>>[] : items.sublist(pageStart, pageEnd);

    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: _loading
              ? _buildListShimmer()
              : items.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAccidentVerifikasi,
                      color: _accentColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: pageItems.length,
                        itemBuilder: (_, i) => _buildAccidentCard(pageItems[i]),
                      ),
                    ),
        ),
        if (!_loading && totalPages > 1)
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
            controller: _searchCtrl,
            onChanged: (v) => setState(() {
              _search = v;
              _currentPage = 1;
            }),
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: t('Cari...', 'Search...', '搜索...'),
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: _accentColor, size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
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
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _accentColor, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
      {'value': 'all', 'label': t('Semua', 'All', '全部'), 'icon': Icons.list_alt_rounded, 'color': _accentColor},
      {'value': 'pending', 'label': t('Pending', 'Pending', '待定'), 'icon': Icons.pending_rounded, 'color': Colors.orange.shade500},
      {'value': 'finalized', 'label': t('Final', 'Finalized', '已完成'), 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF16A34A)},
    ];

    return Row(
      children: options.map((opt) {
        final value = opt['value'] as String;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final color = opt['color'] as Color;
        final isSelected = _filter == value;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _filter = value;
              _currentPage = 1;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: isSelected ? Colors.white : color),
                  const SizedBox(width: 5),
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : color)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccidentCard(Map<String, dynamic> item) {
    final bool isFinalized = item['is_verif'] as bool? ?? false;
    final bool? finalOutcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final String? imageUrl = item['foto_bukti']?.toString();
    final String title = item['judul']?.toString() ?? '-';
    final String lokasiName = item['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String severity = item['tingkat_keparahan']?.toString() ?? '-';

    String dateStr = '-';
    try {
      final rawDate = item['updated_at'] ?? item['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final Color accent;
    final IconData statusIcon;
    final String statusLabel;

    if (!isFinalized || finalOutcome == null) {
      accent = Colors.orange.shade500;
      statusIcon = Icons.hourglass_empty_rounded;
      statusLabel = t('Menunggu', 'Pending', '待定');
    } else if (finalOutcome) {
      accent = const Color(0xFF16A34A);
      statusIcon = Icons.verified_rounded;
      statusLabel = t('Valid', 'Valid', '有效');
    } else {
      accent = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
      statusLabel = t('Tidak Valid', 'Invalid', '无效');
    }

    final Color sevColor = _severityColor(severity);

    final Map<String, Map<String, String>> verifDetailMap = (item['verif_detail_map'] as Map?)?.map(
          (k, v) => MapEntry(
            k.toString(),
            (v as Map).map((dk, dv) => MapEntry(dk.toString(), dv?.toString() ?? '')),
          ),
        ) ??
        {};

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminVerificationAccidentsDetailScreen(lang: widget.lang, item: item),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade100,
                          child: imageUrl != null
                              ? Image.network(imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.warning_amber_rounded, color: sevColor, size: 28))
                              : Icon(Icons.warning_amber_rounded, color: sevColor, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 60),
                              child: Text(title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E3A8A),
                                      height: 1.25)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0891B2).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF0891B2).withValues(alpha: 0.3)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.map, size: 12, color: Color(0xFF0891B2)),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(lokasiName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF0891B2))),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.access_time_filled_rounded, size: 11, color: Colors.grey.shade700),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(dateStr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.grey.shade100),
                if (verifDetailMap.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 5),
                          Text(t('Diverifikasi Oleh', 'Verified By', '由...验证'),
                              style: GoogleFonts.poppins(
                                  fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
                        ]),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: verifDetailMap.entries.map((entry) {
                            final nama = entry.value['nama'] ?? '-';
                            final jabatan = entry.value['jabatan'] ?? '';
                            final jabatanId = entry.value['jabatan_id'] ?? '';
                            final fotoUrl = entry.value['foto_url'] ?? '';

                            Color badgeColor;
                            IconData badgeIcon;
                            if (jabatanId == '5') {
                              badgeColor = const Color(0xFFEC4899);
                              badgeIcon = Icons.people_rounded;
                            } else if (jabatanId == '2') {
                              badgeColor = const Color(0xFF3B82F6);
                              badgeIcon = Icons.workspace_premium_rounded;
                            } else {
                              badgeColor = const Color(0xFF8B5CF6);
                              badgeIcon = Icons.badge_rounded;
                            }

                            return Container(
                              padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.25), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: badgeColor.withValues(alpha: 0.15),
                                      border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.5),
                                    ),
                                    child: ClipOval(
                                      child: fotoUrl.isNotEmpty
                                          ? Image.network(fotoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(badgeIcon, size: 14, color: badgeColor))
                                          : Icon(badgeIcon, size: 14, color: badgeColor),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(nama,
                                          style: GoogleFonts.poppins(
                                              fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor)),
                                      if (jabatan.isNotEmpty)
                                        Text(jabatan,
                                            style: GoogleFonts.poppins(
                                                fontSize: 9,
                                                color: badgeColor.withValues(alpha: 0.7),
                                                fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.hourglass_top_rounded, size: 13, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t('Belum ada yang memverifikasi', 'No verifier yet', '暂无验证者'),
                            style: GoogleFonts.poppins(
                                fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sevColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(19),
                        bottomLeft: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(color: sevColor.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 11, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(severity,
                            style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: Colors.white),
                        const SizedBox(height: 2),
                        Text(statusLabel,
                            style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
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

  Widget _buildEmptyState() {
    final bool isFiltering = _search.isNotEmpty || _filter != 'all';
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
                  color: _accentColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.health_and_safety_rounded, size: 56, color: _accentColor.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isFiltering
                  ? t('Tidak Ditemukan', 'Not Found', '未找到匹配项')
                  : t('Belum Ada Laporan', 'No Reports Yet', '暂无报告'),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _accentColor),
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
                      'Laporan kecelakaan akan muncul di sini untuk diverifikasi.',
                      'Accident reports will show up here for verification.',
                      '事故报告将显示在此处以供验证。'),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() {
                    _search = '';
                    _filter = 'all';
                    _currentPage = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _accentColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 15, color: _accentColor),
                      const SizedBox(width: 6),
                      Text(t('Hapus pencarian & filter', 'Clear search & filter', '清除搜索与筛选'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _accentColor)),
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
          height: 130,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}