import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/utils/jabatan_helper.dart';
import '../../../accident/picker/accident_pick_cause.dart';
import '../../../accident/picker/accident_pick_severity.dart';
import 'accident_verification_detail.dart';
import 'accident_verification_indicator.dart';

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

  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 5;

  static const Map<String, Map<String, String>> _txt = {
    'EN': {
      'hist_empty': 'No history yet.',
      'valid': 'Valid',
      'invalid': 'Invalid',
      'search_hint': 'Search...',
      'hist_empty_search_title': 'Not Found',
      'hist_empty_search_desc':
          'Try adjusting your search keyword to find what you\'re looking for.',
      'clear_search': 'Clear search',
    },
    'ID': {
      'hist_empty': 'Belum ada riwayat.',
      'valid': 'Valid',
      'invalid': 'Tidak Valid',
      'search_hint': 'Cari...',
      'hist_empty_search_title': 'Tidak Ditemukan',
      'hist_empty_search_desc':
          'Coba ubah kata kunci pencarian untuk menemukan yang Anda cari.',
      'clear_search': 'Hapus pencarian',
    },
    'ZH': {
      'hist_empty': '暂无历史记录。',
      'valid': '有效',
      'invalid': '无效',
      'search_hint': '搜索...',
      'hist_empty_search_title': '未找到匹配项',
      'hist_empty_search_desc': '请尝试调整搜索关键词以查找您需要的内容。',
      'clear_search': '清除搜索',
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredHistoryList {
    var list = _accidentHistoryList
        .where((i) => i['hasil_verifikasi_mayoritas'] == true)
        .toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((i) {
        final judul = (i['judul']?.toString() ?? '').toLowerCase();
        final lokasi =
            (i['lokasi']?['nama_lokasi']?.toString() ?? '').toLowerCase();
        return judul.contains(q) || lokasi.contains(q);
      }).toList();
    }
    return list;
  }

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
                is_verificator,
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
            final isVerificatorFlag = rawVerif['is_verificator'];
            verifDetailMap[vid] = {
              'nama': nama,
              'jabatan': jabatanName,
              'jabatan_id': jabatanId?.toString() ?? '',
              'foto_url': fotoUrl,
              'is_verificator': isVerificatorFlag?.toString() ?? '',
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

  @override
  Widget build(BuildContext context) {
    if (_accidentHistoryLoading) return _buildHistoryShimmer();

    final filtered = _filteredHistoryList;
    final totalPages =
        filtered.isEmpty ? 1 : (filtered.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final pageStart = (_currentPage - 1) * _itemsPerPage;
    final pageEnd = (pageStart + _itemsPerPage).clamp(0, filtered.length);
    final pageItems = filtered.isEmpty
        ? <Map<String, dynamic>>[]
        : filtered.sublist(pageStart, pageEnd);

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: pageItems.length,
                  itemBuilder: (_, i) => _buildAccidentHistoryCard(pageItems[i]),
                ),
        ),
        if (filtered.isNotEmpty && totalPages > 1)
          AccidentVerificationIndicator(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: (p) => setState(() => _currentPage = p),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() {
          _search = v;
          _currentPage = 1;
        }),
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: t('search_hint'),
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1D72F3), size: 18),
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
              borderSide: BorderSide(color: const Color(0xFF1D72F3).withValues(alpha: 0.2))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1D72F3), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isFiltering = _search.isNotEmpty;
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
                  color: const Color(0xFF1D72F3).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFiltering ? Icons.search_off_rounded : Icons.history_toggle_off_rounded,
                  size: 56,
                  color: const Color(0xFF1D72F3).withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isFiltering ? t('hist_empty_search_title') : t('hist_empty'),
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? t('hist_empty_search_desc')
                  : (_lang == 'ID'
                      ? 'Laporan yang sudah valid akan muncul di sini.'
                      : _lang == 'ZH'
                          ? '已验证有效的报告将显示在此处。'
                          : 'Reports marked as valid will show up here.'),
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
                    _currentPage = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D72F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF1D72F3)),
                      const SizedBox(width: 6),
                      Text(t('clear_search'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1D72F3))),
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

    final rawSeverity = data['tingkat_keparahan'] as String?;
    final String severityLabel = AccidentSeverityData.labelOf(rawSeverity, _lang);
    final Color sevColor = AccidentSeverityData.colorOf(rawSeverity);
    final IconData severityIcon = AccidentSeverityData.iconOf(rawSeverity);

    final rawCause = data['penyebab'] as String?;
    final String causeLabel = AccidentCauseData.labelOf(rawCause, _lang);
    final Color causeColor = AccidentCauseData.colorOf(rawCause);
    final IconData causeIcon = AccidentCauseData.iconOf(rawCause);

    final String lokasiName = data['lokasi']?['nama_lokasi']?.toString() ?? '-';

    String finalisasiDateStr = '-';
    try {
      final rawDate = data['updated_at'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        finalisasiDateStr = DateFormat('dd MMM yyyy').format(dt);
      }
    } catch (_) {}

    final stats = lid != null ? (_accidentVoteStats[lid] ?? {}) : <String, dynamic>{};

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
    final String statusLabel = finalOutcome == true ? t('valid') : t('invalid');
    final IconData statusIcon =
        finalOutcome == true ? Icons.verified_rounded : Icons.cancel_rounded;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccidentVerificationDetailScreen(
            lang: _lang,
            data: data,
            stats: stats,
            userJabatanId: widget.userJabatanId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130, minWidth: 80),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                sevColor.withValues(alpha: 0.15),
                                sevColor.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.black.withValues(alpha: 0.15), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.5),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.warning_amber_rounded,
                                        color: sevColor, size: 30),
                                  )
                                : Icon(Icons.warning_amber_rounded,
                                    color: sevColor, size: 30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      height: 1.3,
                                      color: const Color(0xFF0F172A)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: sevColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: sevColor, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(severityIcon, size: 11, color: sevColor),
                                    const SizedBox(width: 3),
                                    Text(severityLabel,
                                        style: GoogleFonts.inter(
                                            color: sevColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // LOCATION BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_city_rounded,
                                    size: 12, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    lokasiName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF10B981)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // FACTOR CHIP
                          Row(children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: causeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(causeIcon, size: 10, color: causeColor),
                                    const SizedBox(width: 4),
                                    Text(causeLabel,
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: causeColor,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),

                          // COMPLETION DATE + STATUS VALID/INVALID
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1.1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 5),
                                Text(finalisasiDateStr,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: const Color(0xFF475569),
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: accent.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, size: 13, color: accent),
                                      const SizedBox(width: 4),
                                      Text(statusLabel,
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: accent)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // VERIFIED BY
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 10),
              if (verifDetailMap.isNotEmpty) ...[
                Row(children: [
                  const Icon(Icons.verified_user_rounded,
                      size: 14, color: Color(0xFF1D72F3)),
                  const SizedBox(width: 6),
                  Text(
                    _lang == 'ID'
                        ? 'Diverifikasi Oleh'
                        : _lang == 'ZH'
                            ? '验证人'
                            : 'Verified By',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D72F3)),
                  ),
                ]),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
                  ),
                  child: Column(
                    children: verifDetailMap.entries.map((entry) {
                      final isLast = entry.key == verifDetailMap.keys.last;
                      return Column(
                        children: [
                          _buildVerifiedPersonRow(entry.value),
                          if (!isLast)
                            Container(height: 1, color: const Color(0xFFF1F5F9)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ] else
                Row(children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    _lang == 'ID'
                        ? 'Belum ada yang memverifikasi'
                        : _lang == 'ZH'
                            ? '暂无验证人'
                            : 'No verifier yet',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedPersonRow(Map<String, String> verifier) {
    final nama = (verifier['nama']?.isNotEmpty ?? false) ? verifier['nama']! : '-';
    final fotoUrl = verifier['foto_url'] ?? '';
    final jabatanNama = verifier['jabatan'] ?? '';
    final idJabatan = int.tryParse(verifier['jabatan_id'] ?? '');
    final isVerificatorRaw = verifier['is_verificator'] ?? '';
    final bool? isVerificatorFlag = isVerificatorRaw == 'true'
        ? true
        : (isVerificatorRaw == 'false' ? false : null);

    final String jabatanLabel = JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificatorFlag,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama.isNotEmpty ? jabatanNama : null,
      lang: _lang,
    );
    final Color badgeColor = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificatorFlag, idJabatan: idJabatan);
    final IconData badgeIcon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificatorFlag, idJabatan: idJabatan);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          fotoUrl.isNotEmpty
              ? CircleAvatar(radius: 18, backgroundImage: NetworkImage(fotoUrl))
              : Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded,
                      size: 18, color: Color(0xFF1D72F3)),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: Colors.black)),
                if (jabatanLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: badgeColor.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(badgeIcon, size: 11, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(jabatanLabel,
                          style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: badgeColor)),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}