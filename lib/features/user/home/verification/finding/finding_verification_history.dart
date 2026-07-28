import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

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
              id_temuan,
              judul_temuan,
              deskripsi_temuan,
              gambar_temuan,
              status_temuan,
              is_verif,
              hasil_verifikasi_mayoritas,
              created_at,
              lokasi:id_lokasi (nama_lokasi),
              area:id_area (nama_area),
              unit:id_unit (nama_unit),
              kategoritemuan:id_kategoritemuan_uuid (nama_kategoritemuan),
              penyelesaian:id_penyelesaian (
                gambar_penyelesaian,
                catatan_penyelesaian,
                tanggal_selesai
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
        });
      }
    } catch (e) {
      debugPrint('Load history error: $e');
      if (mounted) setState(() => _historyLoading = false);
    }
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyList.length,
      itemBuilder: (_, i) => _buildHistoryCard(_historyList[i]),
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
          height: 90,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
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

    final stats =
        tid != null ? (_voteStats[tid] ?? {}) : <String, dynamic>{};
    final int validCount = (stats['valid_count'] as int?) ?? 0;
    final int invalidCount = (stats['invalid_count'] as int?) ?? 0;
    final int totalVotes = (stats['total'] as int?) ?? 0;
    final int totalVerificators =
        (stats['total_verificators'] as int?) ?? 0;

    final int netPoint =
        tid != null ? (_historyPointMap[tid] ?? 0) : 0;

    Color accent;
    String statusLabel;
    IconData statusIcon;

    if (!isFinalized || finalOutcome == null) {
      accent = Colors.orange.shade400;
      statusLabel = t('pending');
      statusIcon = Icons.hourglass_empty_rounded;
    } else {
      final bool inMajority = userVote == finalOutcome;
      accent = inMajority
          ? const Color(0xFF16A34A)
          : const Color(0xFFDC2626);
      statusLabel = inMajority ? t('majority') : t('minority');
      statusIcon = inMajority
          ? Icons.emoji_events_rounded
          : Icons.highlight_off_rounded;
    }

    final String voteLabel = userVote ? t('valid') : t('invalid');
    final Color voteColor =
        userVote ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    String loc = '-';
    if (data['area']?['nama_area'] != null) {
      loc = data['area']['nama_area'].toString();
    } else if (data['unit']?['nama_unit'] != null) {
      loc = data['unit']['nama_unit'].toString();
    } else if (data['lokasi']?['nama_lokasi'] != null) {
      loc = data['lokasi']['nama_lokasi'].toString();
    }

    String date = '-';
    try {
      final rawDate = data['waktu_verifikasi'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        date = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final double validRatio =
        totalVotes > 0 ? validCount / totalVotes : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha:0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha:0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 88,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      bottomLeft: Radius.circular(4)),
                ),
              ),
              const SizedBox(width: 10),
              _HistoryThumb(url: imageUrl, label: t('finding')),
              const SizedBox(width: 6),
              _HistoryThumb(url: completionImageUrl, label: t('completion')),
              const SizedBox(width: 10),
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
                              color: const Color(0xFF1E3A8A),
                              height: 1.25)),
                      const SizedBox(height: 5),
                      Row(children: [
                        _VotePill(
                            label: voteLabel,
                            color: voteColor,
                            icon: userVote
                                ? Icons.thumb_up_rounded
                                : Icons.thumb_down_rounded),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Row(children: [
                            Icon(Icons.place_outlined,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(loc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade500)),
                            ),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.access_time_rounded,
                            size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(date,
                            style: GoogleFonts.poppins(
                                fontSize: 9.5, color: Colors.grey.shade400)),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: accent.withValues(alpha:0.3), width: 1.5),
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
              color: accent.withValues(alpha:0.12)),
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
                          color: const Color(0xFF1E3A8A).withValues(alpha:0.7)),
                      const SizedBox(width: 5),
                      Text(t('vote_breakdown'),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A))),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFinalized
                            ? const Color(0xFF16A34A).withValues(alpha:0.1)
                            : Colors.orange.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isFinalized
                              ? const Color(0xFF16A34A).withValues(alpha:0.3)
                              : Colors.orange.withValues(alpha:0.3),
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
                                ? t('finalized')
                                : t('not_finalized'),
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
                Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _VoteCountChip(
                          icon: Icons.thumb_up_rounded,
                          label: t('votes_valid'),
                          count: validCount,
                          color: const Color(0xFF16A34A)),
                      Text(
                          '$totalVotes / $totalVerificators ${_lang == 'EN' ? 'voters' : _lang == 'ZH' ? '投票者' : 'pemilih'}',
                          style: GoogleFonts.poppins(
                              fontSize: 9.5, color: Colors.grey.shade500)),
                      _VoteCountChip(
                          icon: Icons.thumb_down_rounded,
                          label: t('votes_invalid'),
                          count: invalidCount,
                          color: const Color(0xFFDC2626),
                          iconOnRight: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(children: [
                      Container(
                          height: 8,
                          width: double.infinity,
                          color: const Color(0xFFDC2626).withValues(alpha:0.18)),
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
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: finalOutcome == null
                            ? Colors.orange.withValues(alpha:0.07)
                            : finalOutcome
                                ? const Color(0xFF16A34A).withValues(alpha:0.07)
                                : const Color(0xFFDC2626).withValues(alpha:0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: finalOutcome == null
                              ? Colors.orange.withValues(alpha:0.2)
                              : finalOutcome
                                  ? const Color(0xFF16A34A).withValues(alpha:0.2)
                                  : const Color(0xFFDC2626).withValues(alpha:0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('majority_result'),
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(
                                finalOutcome == null
                                    ? Icons.hourglass_empty_rounded
                                    : finalOutcome
                                        ? Icons.thumb_up_rounded
                                        : Icons.thumb_down_rounded,
                                size: 13,
                                color: finalOutcome == null
                                    ? Colors.orange
                                    : finalOutcome
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text(
                                finalOutcome == null
                                    ? t('pending')
                                    : finalOutcome
                                        ? t('valid')
                                        : t('invalid'),
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: finalOutcome == null
                                        ? Colors.orange
                                        : finalOutcome
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFDC2626))),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final int displayPoint = isFinalized ? netPoint : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: displayPoint >= 0
                                ? const Color(0xFF1E3A8A).withValues(alpha:0.05)
                                : const Color(0xFFDC2626).withValues(alpha:0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: displayPoint >= 0
                                  ? const Color(0xFF1E3A8A).withValues(alpha:0.15)
                                  : const Color(0xFFDC2626).withValues(alpha:0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t('your_points'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(
                                    displayPoint >= 0
                                        ? Icons.star_rounded
                                        : Icons.star_half_rounded,
                                    size: 13,
                                    color: displayPoint >= 0
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFDC2626)),
                                const SizedBox(width: 4),
                                Text(
                                    !isFinalized
                                        ? '-'
                                        : displayPoint > 0
                                            ? '+$displayPoint'
                                            : '$displayPoint',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: displayPoint >= 0
                                            ? const Color(0xFF1E3A8A)
                                            : const Color(0xFFDC2626))),
                                const SizedBox(width: 3),
                                Text(_lang == 'ZH' ? '积分' : 'Poin',
                                    style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        color: Colors.grey.shade500)),
                              ]),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryThumb extends StatelessWidget {
  final String? url;
  final String label;
  const _HistoryThumb({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500)),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 52,
            height: 52,
            color: Colors.grey.shade100,
            child: (url != null && url!.isNotEmpty)
                ? Image.network(url!,
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

class _VotePill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _VotePill({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha:0.3), width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 9, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

class _VoteCountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool iconOnRight;

  const _VoteCountChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.iconOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 11, color: color);
    final textWidget = Text('$count $label',
        style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700, color: color));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconOnRight
          ? [textWidget, const SizedBox(width: 3), iconWidget]
          : [iconWidget, const SizedBox(width: 3), textWidget],
    );
  }
}