import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'findings_verification_detail.dart';
import 'finding_verification_indicator.dart';

class FindingVerificationHistory extends StatefulWidget {
  final String lang;

  const FindingVerificationHistory({super.key, required this.lang});

  @override
  State<FindingVerificationHistory> createState() =>
      _FindingVerificationHistoryState();
}

class _FindingVerificationHistoryState
    extends State<FindingVerificationHistory> {
  final _client = Supabase.instance.client;
  late String _lang;

  bool _historyLoading = false;
  List<Map<String, dynamic>> _historyList = [];
  Map<String, Map<String, dynamic>> _voteStats = {};
  Map<String, int> _historyPointMap = {};

  int _currentPage = 1;
  static const int _itemsPerPage = 5;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'finding': 'Finding',
      'completion': 'Completion',
      'hist_empty': 'No history yet.',
      'majority': 'Majority',
      'minority': 'Minority',
      'pending': 'Pending',
      'valid': 'Valid',
      'invalid': 'Invalid',
      'vote_breakdown': 'Vote Breakdown',
      'majority_result': 'Majority Result',
      'your_points': 'Your Points',
      'votes_valid': 'Valid',
      'votes_invalid': 'Invalid',
      'finalized': 'Finalized',
      'not_finalized': 'In Progress',
    },
    'ID': {
      'finding': 'Temuan',
      'completion': 'Penyelesaian',
      'hist_empty': 'Belum ada riwayat.',
      'majority': 'Mayoritas',
      'minority': 'Minoritas',
      'pending': 'Menunggu',
      'valid': 'Valid',
      'invalid': 'Tidak Valid',
      'vote_breakdown': 'Rincian Suara',
      'majority_result': 'Hasil Mayoritas',
      'your_points': 'Poin Anda',
      'votes_valid': 'Valid',
      'votes_invalid': 'Tidak Valid',
      'finalized': 'Final',
      'not_finalized': 'Berlangsung',
    },
    'ZH': {
      'finding': '发现',
      'completion': '完成',
      'hist_empty': '暂无历史记录。',
      'majority': '多数',
      'minority': '少数',
      'pending': '待定',
      'valid': '有效',
      'invalid': '无效',
      'vote_breakdown': '投票详情',
      'majority_result': '多数结果',
      'your_points': '您的积分',
      'votes_valid': '有效',
      'votes_invalid': '无效',
      'finalized': '已终结',
      'not_finalized': '进行中',
    },
  };

  String t(String key) => _txt[_lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _lang = widget.lang;
    _loadHistory();
  }

  bool _isKts(Map<String, dynamic> item) {
    return (item['jenis_temuan']?.toString() ?? '') == 'KTS Production';
  }

  String _locationLabel(Map<String, dynamic> item) {
    if (_isKts(item)) {
      final section = item['penyelesaian']?['section'];
      if (section == null) return '-';
      String? name;
      if (_lang == 'EN') {
        name = section['nama_section_en']?.toString();
      } else if (_lang == 'ZH') {
        name = section['nama_section_zh']?.toString();
      } else {
        name = section['nama_section_id']?.toString();
      }
      if (name == null || name.isEmpty) name = section['nama_section_id']?.toString();
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

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final userId = _client.auth.currentUser!.id;

      final response = await _client
          .from('verifikasi_log')
          .select('''
            id_log,
            jawaban_benar,
            waktu_verifikasi,
            temuan:id_temuan (
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
            )
          ''')
          .eq('id_verificator', userId)
          .order('waktu_verifikasi', ascending: false);

      final List<Map<String, dynamic>> processed = [];
      final List<String> temuanIds = [];

      for (final item in response) {
        final rawTemuan = item['temuan'];
        if (rawTemuan == null) continue;
        final data = Map<String, dynamic>.from(rawTemuan as Map);
        data['user_vote'] = item['jawaban_benar'] as bool? ?? false;
        data['waktu_verifikasi'] = item['waktu_verifikasi'];
        data['id_log'] = item['id_log'];
        processed.add(data);
        final tid = data['id_temuan']?.toString();
        if (tid != null && tid.isNotEmpty) temuanIds.add(tid);
      }

      final Map<String, Map<String, dynamic>> voteStats = {};
      if (temuanIds.isNotEmpty) {
        final allVotes = await _client
            .from('verifikasi_log')
            .select('id_temuan, jawaban_benar')
            .inFilter('id_temuan', temuanIds);

        int totalVerificators = 0;
        try {
          final jabatanUsers = await _client
              .from('User')
              .select('id_user')
              .eq('id_jabatan', 1);

          final verifUsers = await _client
              .from('User')
              .select('id_user')
              .eq('is_verificator', true);

          final Set<String> allIds = {};
          for (final v in jabatanUsers) {
            allIds.add(v['id_user'].toString());
          }
          for (final v in verifUsers) {
            allIds.add(v['id_user'].toString());
          }
          totalVerificators = allIds.length;

          if (totalVerificators == 0) totalVerificators = 1;
        } catch (e) {
          debugPrint('Load verificators error: $e');
          totalVerificators = 1;
        }

        for (final tid in temuanIds) {
          final votesForTemuan =
              allVotes.where((v) => v['id_temuan']?.toString() == tid).toList();
          final int validCount =
              votesForTemuan.where((v) => v['jawaban_benar'] == true).length;
          final int invalidCount =
              votesForTemuan.where((v) => v['jawaban_benar'] == false).length;
          voteStats[tid] = {
            'valid_count': validCount,
            'invalid_count': invalidCount,
            'total': validCount + invalidCount,
            'total_verificators': totalVerificators,
          };
        }
      }

      for (final data in processed) {
        final tid = data['id_temuan']?.toString();
        final stats = tid != null ? voteStats[tid] : null;
        data['vote_valid'] = (stats?['valid_count'] as int?) ?? 0;
        data['vote_invalid'] = (stats?['invalid_count'] as int?) ?? 0;
        data['total_votes'] = (stats?['total'] as int?) ?? 0;
      }

      final Map<String, int> pointMap = {};
      try {
        final pointLogs = await _client
            .from('log_poin')
            .select('poin, tipe_aktivitas, created_at, deskripsi')
            .eq('id_user', userId)
            .inFilter('tipe_aktivitas', [
              'verifikasi_partisipasi',
              'verifikasi_benar',
              'verifikasi_salah',
            ])
            .order('created_at', ascending: false);

        for (int i = 0; i < processed.length; i++) {
          final tid = processed[i]['id_temuan']?.toString();
          if (tid == null || tid.isEmpty) continue;

          int net = 0;
          for (final log in pointLogs) {
            final desc = log['deskripsi']?.toString() ?? '';
            final tipe = log['tipe_aktivitas']?.toString() ?? '';

            if (tipe == 'verifikasi_partisipasi') {
              final rawWaktu = processed[i]['waktu_verifikasi'];
              if (rawWaktu != null) {
                final verifyTime =
                    DateTime.parse(rawWaktu.toString()).toUtc();
                final rawCt = log['created_at'];
                if (rawCt != null) {
                  final logTime = DateTime.parse(rawCt.toString()).toUtc();
                  if (logTime.difference(verifyTime).inSeconds.abs() <= 30) {
                    net += (log['poin'] as num).toInt();
                  }
                }
              }
            }
            else if (desc.contains('#T$tid')) {
              net += (log['poin'] as num).toInt();
            }
          }
          pointMap[tid] = net;
        }
      } catch (e) {
        debugPrint('Load point map error: $e');
      }

      if (mounted) {
        setState(() {
          _historyList = processed;
          _voteStats = voteStats;
          _historyPointMap = pointMap;
          _historyLoading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      debugPrint('Load history error: $e');
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  void _openDetail(Map<String, dynamic> data, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FindingsVerificationDetailScreen(
          lang: _lang,
          item: data,
          initialTab: initialTab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_historyLoading) return _buildHistoryShimmer();
    if (_historyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(t('hist_empty'),
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    final totalPages = (_historyList.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final pageStart = (_currentPage - 1) * _itemsPerPage;
    final pageEnd = (pageStart + _itemsPerPage).clamp(0, _historyList.length);
    final pageItems = _historyList.sublist(pageStart, pageEnd);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: pageItems.length,
            itemBuilder: (_, i) => _buildHistoryCard(pageItems[i]),
          ),
        ),
        if (totalPages > 1)
          FindingVerificationIndicator(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: (p) => setState(() => _currentPage = p),
          ),
      ],
    );
  }

  Widget _buildHistoryShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 96,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    final String? tid = data['id_temuan']?.toString();
    final String title = data['judul_temuan']?.toString() ?? '-';
    final String? imageUrl = data['gambar_temuan']?.toString();
    final String? completionImageUrl =
        data['penyelesaian']?['gambar_penyelesaian']?.toString();
    final bool userVote = data['user_vote'] as bool? ?? false;
    final bool? finalOutcome = data['hasil_verifikasi_mayoritas'] as bool?;
    final bool isFinalized = data['is_verif'] as bool? ?? false;

    final stats = tid != null ? (_voteStats[tid] ?? {}) : <String, dynamic>{};
    final int validCount = (stats['valid_count'] as int?) ?? 0;
    final int invalidCount = (stats['invalid_count'] as int?) ?? 0;
    final int totalVotes = (stats['total'] as int?) ?? 0;
    final int totalVerificators = (stats['total_verificators'] as int?) ?? 0;

    final int netPoint = tid != null ? (_historyPointMap[tid] ?? 0) : 0;

    Color accent;
    String statusLabel;
    IconData statusIcon;

    if (!isFinalized || finalOutcome == null) {
      accent = Colors.orange.shade400;
      statusLabel = t('pending');
      statusIcon = Icons.hourglass_empty_rounded;
    } else {
      final bool inMajority = userVote == finalOutcome;
      accent = inMajority ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
      statusLabel = inMajority ? t('majority') : t('minority');
      statusIcon = inMajority ? Icons.emoji_events_rounded : Icons.highlight_off_rounded;
    }

    final Color typeColor = _isKts(data) ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
    final String typeBadge = _isKts(data) ? 'KTS' : '5R';
    final String loc = _locationLabel(data);

    String date = '-';
    try {
      final rawDate = data['waktu_verifikasi'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        date = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final double validRatio = totalVotes > 0 ? validCount / totalVotes : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    color: accent,
                  ),
                  const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openDetail(data, initialTab: 0),
                      child: _buildHistoryThumb(
                        url: imageUrl,
                        label: t('finding'),
                        icon: Icons.search_rounded,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _openDetail(data, initialTab: 1),
                      child: _buildHistoryThumb(
                        url: completionImageUrl,
                        label: t('completion'),
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
                  onTap: () => _openDetail(data, initialTab: 0),
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
                            color: const Color(0xFF1D72F3).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha: 0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.map_rounded, size: 11, color: Color(0xFF1D72F3)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(loc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
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
                            Icon(Icons.access_time_filled_rounded, size: 11, color: Colors.grey.shade700),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(date,
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 5R & KTS LABEL
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: typeColor.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(typeBadge,
                          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(height: 6),
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
                        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: accent)),
                  ],
                ),
              ),
            ],
          ),
        ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 1,
              color: accent.withValues(alpha: 0.12)),
          GestureDetector(
            onTap: () => _openDetail(data, initialTab: 0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(children: [
                    Icon(Icons.how_to_vote_rounded,
                        size: 13, color: const Color(0xFF1E3A8A).withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Text(t('vote_breakdown'),
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.thumb_up_rounded, size: 11, color: Color(0xFF16A34A)),
                        const SizedBox(width: 3),
                        Text('$validCount ${t('votes_valid')}',
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A))),
                      ]),
                      // VOTERS COUNT
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.groups_rounded, size: 12, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 4),
                          Text(
                              '$totalVotes/$totalVerificators ${_lang == 'EN' ? 'voters' : _lang == 'ZH' ? '投票者' : 'pemilih'}',
                              style: GoogleFonts.poppins(
                                  fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF38BDF8))),
                        ]),
                      ),
                      Row(children: [
                        Text('$invalidCount ${t('votes_invalid')}',
                            style: GoogleFonts.poppins(
                                fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626))),
                        const SizedBox(width: 3),
                        const Icon(Icons.thumb_down_rounded, size: 11, color: Color(0xFFDC2626)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                      child: _buildInfoBox(
                        icon: finalOutcome == null
                            ? Icons.hourglass_empty_rounded
                            : finalOutcome
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_down_rounded,
                        iconColor: finalOutcome == null
                            ? Colors.orange
                            : finalOutcome
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                        label: t('majority_result'),
                        value: finalOutcome == null
                            ? t('pending')
                            : finalOutcome
                                ? t('valid')
                                : t('invalid'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoBox(
                        icon: (isFinalized ? netPoint : 0) >= 0
                            ? Icons.star_rounded
                            : Icons.star_half_rounded,
                        iconColor: const Color(0xFFFACC15),
                        label: t('your_points'),
                        value: !isFinalized
                            ? '-'
                            : (netPoint > 0 ? '+$netPoint' : '$netPoint'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 1),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
            ],
          ),
        ),
      ]),
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
                      fontSize: 8, fontWeight: FontWeight.w700, color: color, height: 1.0)),
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
}