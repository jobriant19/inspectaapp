import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AccidentVerificationHistoryScreen extends StatefulWidget {
  final String lang;
  final int? userJabatanId;

  const AccidentVerificationHistoryScreen({
    super.key,
    required this.lang,
    this.userJabatanId,
  });

  @override
  State<AccidentVerificationHistoryScreen> createState() =>
      AccidentVerificationHistoryScreenState();
}

class AccidentVerificationHistoryScreenState
    extends State<AccidentVerificationHistoryScreen> {
  final _client = Supabase.instance.client;
  late String _lang;

  bool _accidentHistoryLoading = false;
  List<Map<String, dynamic>> _accidentHistoryList = [];
  Map<String, Map<String, dynamic>> _accidentVoteStats = {};

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'hist_empty': 'No history yet.',
      'valid': 'Valid',
      'invalid': 'Invalid',
    },
    'ID': {
      'hist_empty': 'Belum ada riwayat.',
      'valid': 'Valid',
      'invalid': 'Tidak Valid',
    },
    'ZH': {
      'hist_empty': '暂无历史记录。',
      'valid': '有效',
      'invalid': '无效',
    },
  };

  String t(String key) => _txt[_lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _lang = widget.lang;
    loadAccidentHistory();
  }

  @override
  void didUpdateWidget(covariant AccidentVerificationHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lang = widget.lang;
  }

  // ================================================================
  // LOAD DATA
  // ================================================================
  Future<void> loadAccidentHistory() async {
    setState(() => _accidentHistoryLoading = true);
    try {
      final allReports = await _client
          .from('accident_report')
          .select('''
            id_laporan, judul, deskripsi, foto_bukti,
            tanggal_kejadian, waktu_kejadian, penyebab,
            tingkat_keparahan, departemen_terdampak, tindakan_diambil,
            status, created_at, updated_at, is_verif,
            hasil_verifikasi_mayoritas,
            lokasi:id_lokasi(nama_lokasi),
            pelapor:id_pelapor(nama),
            pihak_terdampak:id_pihak_terdampak(nama)
          ''')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> processed = [];
      final List<String> lapdoranIds = [];

      for (final item in allReports) {
        final data = Map<String, dynamic>.from(item as Map);
        processed.add(data);
        final lid = data['id_laporan']?.toString();
        if (lid != null) lapdoranIds.add(lid);
      }

      final Map<String, Map<String, dynamic>> voteStats = {};

      if (lapdoranIds.isNotEmpty) {
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
            .inFilter('id_laporan', lapdoranIds);

        for (final lid in lapdoranIds) {
          final votesForLaporan = allVoteLogs
              .where((v) => v['id_laporan']?.toString() == lid)
              .toList();

          final int validCount =
              votesForLaporan.where((v) => v['jawaban_benar'] == true).length;
          final int invalidCount =
              votesForLaporan.where((v) => v['jawaban_benar'] == false).length;

          final Map<String, Map<String, String>> verifDetailMap = {};
          for (final v in votesForLaporan) {
            final vid = v['id_verificator']?.toString();
            if (vid == null) continue;
            final rawVerif = v['verificator'];
            if (rawVerif == null) continue;
            final nama = rawVerif['nama']?.toString() ?? vid;
            final jabatanId = rawVerif['id_jabatan'];
            final jabatanName =
                rawVerif['jabatan']?['nama_jabatan']?.toString() ?? '';
            final fotoUrl = rawVerif['gambar_user']?.toString() ?? '';
            verifDetailMap[vid] = {
              'nama': nama,
              'jabatan': jabatanName,
              'jabatan_id': jabatanId?.toString() ?? '',
              'foto_url': fotoUrl,
            };
          }

          voteStats[lid] = {
            'valid_count': validCount,
            'invalid_count': invalidCount,
            'total': validCount + invalidCount,
            'total_hrd': validCount + invalidCount,
            'verif_detail_map': verifDetailMap,
          };
        }
      }

      if (mounted) {
        setState(() {
          _accidentHistoryList = processed;
          _accidentVoteStats = voteStats;
          _accidentHistoryLoading = false;
        });
      }
    } catch (e) {
      debugPrint('loadAccidentHistory error: $e');
      if (mounted) setState(() => _accidentHistoryLoading = false);
    }
  }

  // ================================================================
  // UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    if (_accidentHistoryLoading) return _buildHistoryShimmer();
    if (_accidentHistoryList.isEmpty) {
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
      itemCount: _accidentHistoryList.length,
      itemBuilder: (_, i) => _buildAccidentHistoryCard(_accidentHistoryList[i]),
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

  Widget _buildAccidentHistoryCard(Map<String, dynamic> data) {
    final String? lid = data['id_laporan']?.toString();
    final String title = data['judul']?.toString() ?? '-';
    final String? imageUrl = data['foto_bukti']?.toString();
    final bool? finalOutcome = data['hasil_verifikasi_mayoritas'] as bool?;
    final String severity = data['tingkat_keparahan'] ?? '';
    final String lokasiName = data['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String pelaporName = data['pelapor']?['nama']?.toString() ?? '-';

    String finalisasiDateStr = '-';
    try {
      final rawDate = data['updated_at'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        finalisasiDateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final stats =
        lid != null ? (_accidentVoteStats[lid] ?? {}) : <String, dynamic>{};

    final Map<String, Map<String, String>> verifDetailMap =
        (stats['verif_detail_map'] as Map?)?.map(
              (k, v) => MapEntry(
                k.toString(),
                (v as Map).map((dk, dv) =>
                    MapEntry(dk.toString(), dv?.toString() ?? '')),
              ),
            ) ??
            {};

    final Color accent =
        finalOutcome == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final String statusLabel =
        finalOutcome == true ? t('valid') : t('invalid');
    final IconData statusIcon =
        finalOutcome == true ? Icons.verified_rounded : Icons.cancel_rounded;

    final Color sevColor = severity == 'Berat'
        ? const Color(0xFFDC2626)
        : severity == 'Menengah'
            ? const Color(0xFFF97316)
            : const Color(0xFF16A34A);

    final int totalVotes = (stats['total'] as int?) ?? 0;
    final double validRatio = totalVotes > 0
        ? ((stats['valid_count'] as int?) ?? 0) / totalVotes
        : 0.0;

    return GestureDetector(
      onTap: () => _showAccidentHistoryDetail(
          data, stats, accent, statusLabel, statusIcon,
          statusLabel, accent, validRatio),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha:0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha:0.08),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                              errorBuilder: (_, __, ___) => Icon(
                                  Icons.warning_amber_rounded,
                                  color: sevColor, size: 28))
                          : Icon(Icons.warning_amber_rounded,
                              color: sevColor, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _lang == 'ID' ? 'KECELAKAAN'
                                  : _lang == 'ZH' ? '事故' : 'ACCIDENT',
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sevColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: sevColor.withValues(alpha:0.4), width: 1),
                            ),
                            child: Text(severity,
                                style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: sevColor)),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E3A8A),
                                height: 1.25)),
                        const SizedBox(height: 5),
                        Row(children: [
                          const Icon(Icons.place_rounded,
                              size: 12, color: Color(0xFF0891B2)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(lokasiName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0891B2))),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.person_outline,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(pelaporName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade600)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1E3A8A).withValues(alpha:0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF1E3A8A)
                                    .withValues(alpha:0.12)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 11, color: Color(0xFF1E3A8A)),
                              const SizedBox(width: 4),
                              Text(
                                '${_lang == 'ID' ? 'Final' : 'Finalized'}: $finalisasiDateStr',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha:0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: Colors.white, size: 18),
                            const SizedBox(height: 3),
                            Text(
                              statusLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      const Icon(Icons.verified_user_rounded,
                          size: 13, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 5),
                      Text(
                        _lang == 'ID' ? 'Diverifikasi Oleh'
                            : _lang == 'ZH' ? '由...验证' : 'Verified By',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E3A8A)),
                      ),
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
                        } else if (jabatanId == '1') {
                          badgeColor = const Color(0xFFFB7185);
                          badgeIcon = Icons.workspace_premium_rounded;
                        } else {
                          badgeColor = const Color(0xFF8B5CF6);
                          badgeIcon = Icons.badge_rounded;
                        }

                        return Container(
                          padding:
                              const EdgeInsets.fromLTRB(6, 5, 10, 5),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha:0.07),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: badgeColor.withValues(alpha:0.25),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: badgeColor.withValues(alpha:0.15),
                                  border: Border.all(
                                      color: badgeColor.withValues(alpha:0.4),
                                      width: 1.5),
                                ),
                                child: ClipOval(
                                  child: fotoUrl.isNotEmpty
                                      ? Image.network(fotoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Icon(badgeIcon,
                                                  size: 14,
                                                  color: badgeColor))
                                      : Icon(badgeIcon,
                                          size: 14, color: badgeColor),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(nama,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: badgeColor)),
                                  if (jabatan.isNotEmpty)
                                    Text(jabatan,
                                        style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color:
                                                badgeColor.withValues(alpha:0.7),
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
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    _lang == 'ID'
                        ? 'Belum ada yang memverifikasi'
                        : 'No verifier yet',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  void _showAccidentHistoryDetail(
    Map<String, dynamic> data,
    Map<String, dynamic> stats,
    Color accent,
    String statusLabel,
    IconData statusIcon,
    String voteLabel,
    Color voteColor,
    double validRatio,
  ) {
    final String title = data['judul']?.toString() ?? '-';
    final String? imageUrl = data['foto_bukti']?.toString();
    final String severity = data['tingkat_keparahan'] ?? '';
    final String deskripsi = data['deskripsi']?.toString() ?? '-';
    final String lokasiName = data['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String pelaporName = data['pelapor']?['nama']?.toString() ?? '-';
    final String tanggal =
        data['tanggal_kejadian']?.toString() ?? '-';
    final String waktu =
        data['waktu_kejadian']?.toString().substring(0, 5) ?? '-';
    final String penyebab = data['penyebab']?.toString() ?? '-';

    String dateStr = '-';
    try {
      final rawDate = data['waktu_verifikasi'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final Color sevColor = severity == 'Berat'
        ? const Color(0xFFDC2626)
        : severity == 'Menengah'
            ? const Color(0xFFF97316)
            : const Color(0xFF16A34A);

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
            color: Color(0xFFF0F7FF),
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
                    colors: widget.userJabatanId == 2
                        ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
                        : [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.health_and_safety_outlined,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lang == 'ID'
                                ? 'Detail Laporan Kecelakaan'
                                : _lang == 'ZH'
                                    ? '事故报告详情'
                                    : 'Accident Report Detail',
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
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha:0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ],
                      ),
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
                        child: Stack(children: [
                          Image.network(
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
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: sevColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(severity,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ]),
                            ),
                          ),
                        ]),
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
                                  color: const Color(0xFF1E3A8A))),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildDetailInfoRow(Icons.person_outline,
                              _lang == 'ID' ? 'Pelapor' : 'Reporter',
                              pelaporName),
                          _buildDetailInfoRow(Icons.personal_injury_outlined,
                              _lang == 'ID' ? 'Pihak Terdampak' : 'Affected',
                              data['pihak_terdampak']?['nama']?.toString() ?? '-'),
                          _buildDetailInfoRow(Icons.location_on_outlined,
                              _lang == 'ID' ? 'Lokasi' : 'Location', lokasiName),
                          _buildDetailInfoRow(Icons.calendar_today,
                              _lang == 'ID' ? 'Tanggal' : 'Date', tanggal),
                          _buildDetailInfoRow(Icons.access_time,
                              _lang == 'ID' ? 'Waktu' : 'Time', waktu),
                          _buildDetailInfoRow(Icons.build_circle_outlined,
                              _lang == 'ID' ? 'Penyebab' : 'Cause', penyebab),
                          if (data['supervisor_user']?['nama'] != null)
                            _buildDetailInfoRow(
                                Icons.supervisor_account_outlined,
                                'Supervisor',
                                data['supervisor_user']['nama'].toString()),
                          if (data['saksi_user']?['nama'] != null)
                            _buildDetailInfoRow(
                                Icons.visibility_outlined,
                                _lang == 'ID' ? 'Saksi' : 'Witness',
                                data['saksi_user']['nama'].toString()),
                          if (data['departemen_terdampak'] != null)
                            _buildDetailInfoRow(
                                Icons.business_outlined,
                                _lang == 'ID' ? 'Departemen' : 'Department',
                                data['departemen_terdampak'].toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.description_outlined,
                                size: 14, color: Colors.orange.shade800),
                            const SizedBox(width: 6),
                            Text(
                              _lang == 'ID'
                                  ? 'Deskripsi Kejadian'
                                  : _lang == 'ZH'
                                      ? '事故描述'
                                      : 'Incident Description',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade800),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(deskripsi,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF1E3A8A),
                                  height: 1.5)),
                        ],
                      ),
                    ),

                    if (data['tindakan_diambil'] != null &&
                        data['tindakan_diambil'].toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.medical_services_outlined,
                                  size: 14, color: Colors.green.shade800),
                              const SizedBox(width: 6),
                              Text(
                                _lang == 'ID'
                                    ? 'Tindakan yang Diambil'
                                    : 'Action Taken',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade800),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text(data['tindakan_diambil'].toString(),
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF1E3A8A),
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ],

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

  Widget _buildDetailInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha:0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: const Color(0xFF1E3A8A)),
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
                        color: const Color(0xFF1E3A8A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}