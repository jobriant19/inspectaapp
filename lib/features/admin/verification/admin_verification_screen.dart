import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ============================================================
// ADMIN VERIFICATION SCREEN
// Mengatur konfigurasi sistem verifikasi dan menampilkan
// hasil semua verifikasi (temuan & accident report)
// ============================================================
class AdminVerificationScreen extends StatefulWidget {
  final String lang;
  const AdminVerificationScreen({super.key, required this.lang});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with TickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabController;

  // ── Config state ──
  bool _configLoading = true;
  bool _configSaving = false;
  int _durasiHari = 7;
  int _minSuara = 3;
  bool _autoValid = true;

  // ── Temuan verifikasi state ──
  bool _temuanLoading = true;
  List<Map<String, dynamic>> _temuanList = [];
  String _temuanFilter = 'all'; // all, finalized, pending
  String _temuanSearch = '';
  final _temuanSearchCtrl = TextEditingController();

  // ── Accident verifikasi state ──
  bool _accidentLoading = true;
  List<Map<String, dynamic>> _accidentList = [];
  String _accidentFilter = 'all';
  String _accidentSearch = '';
  final _accidentSearchCtrl = TextEditingController();

  // ── Stats ──
  int _statTemuanTotal = 0;
  int _statTemuanFinal = 0;
  int _statTemuanPending = 0;
  int _statAccidentTotal = 0;
  int _statAccidentFinal = 0;
  int _statAccidentPending = 0;

  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _accentColor = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConfig();
    _loadTemuanVerifikasi();
    _loadAccidentVerifikasi();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _temuanSearchCtrl.dispose();
    _accidentSearchCtrl.dispose();
    super.dispose();
  }

  String t(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  // ══════════════════════════════════════════════
  // LOAD & SAVE CONFIG
  // ══════════════════════════════════════════════

  Future<void> _loadConfig() async {
    setState(() => _configLoading = true);
    try {
      final rows = await _client
          .from('verifikasi_config')
          .select('kode, nilai_int');
      for (final row in rows) {
        switch (row['kode']) {
          case 'durasi_verifikasi_hari':
            _durasiHari = row['nilai_int'] ?? 7;
            break;
          case 'min_suara_finalisasi':
            _minSuara = row['nilai_int'] ?? 3;
            break;
          case 'auto_valid_jika_timeout':
            _autoValid = (row['nilai_int'] ?? 1) == 1;
            break;
        }
      }
    } catch (e) {
      debugPrint('loadConfig error: $e');
    }
    if (mounted) setState(() => _configLoading = false);
  }

  Future<void> _saveConfig() async {
    setState(() => _configSaving = true);
    try {
      final updates = [
        {'kode': 'durasi_verifikasi_hari', 'nilai_int': _durasiHari},
        {'kode': 'min_suara_finalisasi', 'nilai_int': _minSuara},
        {'kode': 'auto_valid_jika_timeout', 'nilai_int': _autoValid ? 1 : 0},
      ];
      for (final u in updates) {
        await _client
            .from('verifikasi_config')
            .update({
              'nilai_int': u['nilai_int'] as int,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('kode', u['kode'] as String);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t(
            'Konfigurasi berhasil disimpan!',
            'Configuration saved successfully!',
            '配置保存成功！',
          )),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      debugPrint('saveConfig error: $e');
    }
    if (mounted) setState(() => _configSaving = false);
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
            id_temuan, judul_temuan, gambar_temuan, created_at,
            is_verif, hasil_verifikasi_mayoritas, status_temuan,
            kategoritemuan:id_kategoritemuan_uuid (nama_kategoritemuan),
            lokasi:id_lokasi (nama_lokasi),
            penyelesaian:id_penyelesaian (gambar_penyelesaian, catatan_penyelesaian)
          ''')
          .eq('status_temuan', 'Selesai')
          .order('created_at', ascending: false);

      final rawList = response as List;

      // Kumpulkan semua id_temuan
      final ids = rawList
          .map((r) => r['id_temuan']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      // Map: id_temuan → {valid, invalid}
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

      _statTemuanTotal = list.length;
      _statTemuanFinal = list.where((i) => i['is_verif'] == true).length;
      _statTemuanPending = list.where((i) => i['is_verif'] != true).length;

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

  // ══════════════════════════════════════════════
  // LOAD ACCIDENT VERIFIKASI
  // ══════════════════════════════════════════════

  Future<void> _loadAccidentVerifikasi() async {
    setState(() => _accidentLoading = true);
    try {
      final response = await _client
          .from('accident_report')
          .select('''
            id_laporan, judul, foto_bukti, created_at, updated_at,
            is_verif, hasil_verifikasi_mayoritas, status, tingkat_keparahan,
            lokasi:id_lokasi (nama_lokasi),
            pelapor:id_pelapor (nama)
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

      // Ambil verif detail map (siapa saja yang sudah vote)
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

      final list = (response as List).map<Map<String, dynamic>>((item) {
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

      _statAccidentTotal = list.length;
      _statAccidentFinal = list.where((i) => i['is_verif'] == true).length;
      _statAccidentPending = list.where((i) => i['is_verif'] != true).length;

      if (mounted) {
        setState(() {
          _accidentList = list;
          _accidentLoading = false;
        });
      }
    } catch (e) {
      debugPrint('loadAccidentVerifikasi error: $e');
      if (mounted) setState(() => _accidentLoading = false);
    }
  }

  // ══════════════════════════════════════════════
  // FILTERED LISTS
  // ══════════════════════════════════════════════

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

  List<Map<String, dynamic>> get _filteredAccident {
    var list = _accidentList;
    if (_accidentFilter == 'finalized') {
      list = list.where((i) => i['is_verif'] == true).toList();
    } else if (_accidentFilter == 'pending') {
      list = list.where((i) => i['is_verif'] != true).toList();
    }
    if (_accidentSearch.isNotEmpty) {
      final q = _accidentSearch.toLowerCase();
      list = list.where((i) =>
          (i['judul']?.toString() ?? '').toLowerCase().contains(q) ||
          (i['lokasi']?['nama_lokasi']?.toString() ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════

  // ── Detail popup Temuan (diklik dari card admin) ──
  void _showTemuanDetail(Map<String, dynamic> item) {
    final bool isFinalized = item['is_verif'] as bool? ?? false;
    final bool? outcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final int validVotes = item['vote_valid'] as int? ?? 0;
    final int invalidVotes = item['vote_invalid'] as int? ?? 0;
    final int totalVotes = item['total_votes'] as int? ?? 0;
    final String? imageUrl = item['gambar_temuan']?.toString();
    final String title = item['judul_temuan']?.toString() ?? '-';
    final String lokasi = item['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String kategori =
        item['kategoritemuan']?['nama_kategoritemuan']?.toString() ?? '-';

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
                        color: Colors.white.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.25),
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
                    // Foto temuan
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
                    // Info utama
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
                          _buildAdminDetailRow(Icons.location_on_outlined,
                              t('Lokasi', 'Location', '地点'), lokasi),
                          _buildAdminDetailRow(Icons.category_outlined,
                              t('Kategori', 'Category', '类别'), kategori),
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
                    // Statistik voting
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
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
                          // Vote count row
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
                          // Vote bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(children: [
                              Container(
                                  height: 8,
                                  color: const Color(0xFFDC2626).withOpacity(0.18)),
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
                          // Majority result banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withOpacity(0.25)),
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

  // ── Detail popup Accident (diklik dari card admin) ──
  void _showAccidentDetailAdmin(Map<String, dynamic> item) {
    final bool isFinalized = item['is_verif'] as bool? ?? false;
    final bool? outcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final int validVotes = item['vote_valid'] as int? ?? 0;
    final int invalidVotes = item['vote_invalid'] as int? ?? 0;
    final int totalVotes = item['total_votes'] as int? ?? 0;
    final String? imageUrl = item['foto_bukti']?.toString();
    final String title = item['judul']?.toString() ?? '-';
    final String lokasi = item['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String pelapor = item['pelapor']?['nama']?.toString() ?? '-';
    final String severity = item['tingkat_keparahan']?.toString() ?? '-';
    final String deskripsi = item['deskripsi']?.toString() ?? '-';
    final String penyebab = item['penyebab']?.toString() ?? '-';
    final String status = item['status']?.toString() ?? '-';

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
      statusIcon = Icons.verified_rounded;
      statusLabel = t('Valid', 'Valid', '有效');
    } else {
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
      statusLabel = t('Tidak Valid', 'Invalid', '无效');
    }

    final Color sevColor = severity == 'Berat'
        ? const Color(0xFFDC2626)
        : severity == 'Menengah'
            ? const Color(0xFFF97316)
            : const Color(0xFF16A34A);

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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.health_and_safety_outlined,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Detail Laporan Kecelakaan',
                                'Accident Report Detail', '事故报告详情'),
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
                        color: Colors.white.withOpacity(0.25),
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
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 12,
                                        color: Colors.white),
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
                          _buildAdminDetailRow(Icons.person_outline,
                              t('Pelapor', 'Reporter', '报告人'), pelapor),
                          _buildAdminDetailRow(
                              Icons.location_on_outlined,
                              t('Lokasi', 'Location', '地点'),
                              lokasi),
                          _buildAdminDetailRow(Icons.build_circle_outlined,
                              t('Penyebab', 'Cause', '原因'), penyebab),
                          _buildAdminDetailRow(
                              Icons.warning_amber_rounded,
                              t('Keparahan', 'Severity', '严重程度'),
                              severity),
                          _buildAdminDetailRow(
                              Icons.info_outline_rounded,
                              t('Status Laporan', 'Report Status', '报告状态'),
                              status),
                          _buildAdminDetailRow(Icons.calendar_today,
                              t('Tanggal', 'Date', '日期'), dateStr),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Deskripsi
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
                              t('Deskripsi Kejadian',
                                  'Incident Description', '事故描述'),
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

                    if (item['tindakan_diambil'] != null &&
                        item['tindakan_diambil'].toString().isNotEmpty) ...[
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
                                t('Tindakan yang Diambil', 'Action Taken', '已采取的措施'),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade800),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text(item['tindakan_diambil'].toString(),
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

  // ── Helper row detail bottom sheet ──
  Widget _buildAdminDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.07),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConfigTab(),
                  _buildTemuanTab(),
                  _buildAccidentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: _primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Manajemen Verifikasi', 'Verification Management',
                      '验证管理'),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF134E4A),
                  ),
                ),
                Text(
                  t('Konfigurasi & Monitoring Verifikasi',
                      'Configure & Monitor Verifications', '配置和监控验证'),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Badge stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryColor, _accentColor],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final labels = [
      t('Konfigurasi', 'Config', '配置'),
      t('Temuan', 'Findings', '发现'),
      t('Kecelakaan', 'Accidents', '事故'),
    ];
    final icons = [
      Icons.settings_rounded,
      Icons.assignment_turned_in_rounded,
      Icons.health_and_safety_rounded,
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: _primaryColor,
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 11),
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: List.generate(3, (i) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icons[i], size: 13),
                const SizedBox(width: 4),
                Text(labels[i]),
              ],
            ),
          )),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 1: KONFIGURASI
  // ══════════════════════════════════════════════

  Widget _buildConfigTab() {
    if (_configLoading) {
      return _buildShimmer();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.white70, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('Konfigurasi Sistem Verifikasi',
                            'Verification System Config', '验证系统配置'),
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      Text(
                        t('Ubah parameter verifikasi temuan di sini.',
                            'Edit finding verification parameters here.',
                            '在此编辑参数。'),
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Durasi Verifikasi ──
          _buildConfigSection(
            icon: Icons.timer_rounded,
            title: t('Durasi Verifikasi (Hari)',
                'Verification Duration (Days)', '验证时长（天）'),
            subtitle: t(
              'Temuan yang melebihi durasi ini akan difinalisasi otomatis.',
              'Findings exceeding this duration will be auto-finalized.',
              '超过此时限的发现将自动完成。',
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _durasiHari.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: _primaryColor,
                        inactiveColor: _primaryColor.withOpacity(0.2),
                        onChanged: (v) =>
                            setState(() => _durasiHari = v.toInt()),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        '$_durasiHari',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 hari',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey.shade500)),
                    Text('30 hari',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Minimum Suara Finalisasi ──
          _buildConfigSection(
            icon: Icons.how_to_vote_rounded,
            title: t('Minimum Suara Mayoritas',
                'Minimum Majority Votes', '最少多数票'),
            subtitle: t(
              'Jika suara mayoritas mencapai angka ini, verifikasi langsung difinalisasi.',
              'When majority votes reach this number, verification is immediately finalized.',
              '当多数票达到此数字时，验证立即完成。',
            ),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _minSuara.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _primaryColor,
                    inactiveColor: _primaryColor.withOpacity(0.2),
                    onChanged: (v) => setState(() => _minSuara = v.toInt()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$_minSuara',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Auto Valid jika Timeout ──
          _buildConfigSection(
            icon: Icons.auto_mode_rounded,
            title: t('Hasil Otomatis jika Timeout',
                'Auto Result on Timeout', '超时自动结果'),
            subtitle: t(
              'Jika tidak ada suara hingga batas waktu, hasil ditetapkan sebagai:',
              'If no votes until timeout, result is set as:',
              '如果超时无投票，结果设置为：',
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  _buildToggleOption(
                    label: t('Valid', 'Valid', '有效'),
                    icon: Icons.thumb_up_rounded,
                    isSelected: _autoValid,
                    color: const Color(0xFF16A34A),
                    onTap: () => setState(() => _autoValid = true),
                  ),
                  _buildToggleOption(
                    label: t('Tidak Valid', 'Invalid', '无效'),
                    icon: Icons.thumb_down_rounded,
                    isSelected: !_autoValid,
                    color: const Color(0xFFDC2626),
                    onTap: () => setState(() => _autoValid = false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Save Button ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _configSaving ? null : _saveConfig,
              icon: _configSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(
                t('Simpan Konfigurasi', 'Save Configuration', '保存配置'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Manual Auto-Finalize Button ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await _client.rpc('auto_finalize_timeout_temuan');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(t(
                        'Auto-finalisasi berhasil dijalankan.',
                        'Auto-finalization ran successfully.',
                        '自动完成运行成功。',
                      )),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                    _loadTemuanVerifikasi();
                  }
                } catch (e) {
                  debugPrint('manual finalize error: $e');
                }
              },
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: Text(
                t('Jalankan Auto-Finalisasi Sekarang',
                    'Run Auto-Finalization Now', '立即运行自动完成'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConfigSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: _primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF134E4A))),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: Colors.grey.shade500,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : color, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : color)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 2: TEMUAN VERIFIKASI
  // ══════════════════════════════════════════════

  Widget _buildTemuanTab() {
    return Column(
      children: [
        _buildStatsRow(
          total: _statTemuanTotal,
          finalized: _statTemuanFinal,
          pending: _statTemuanPending,
          color: _primaryColor,
        ),
        _buildSearchAndFilter(
          searchCtrl: _temuanSearchCtrl,
          filter: _temuanFilter,
          onFilterChanged: (v) => setState(() => _temuanFilter = v),
          onSearchChanged: (v) => setState(() => _temuanSearch = v),
          color: _primaryColor,
        ),
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

  Widget _buildTemuanCard(Map<String, dynamic> item) {
    final bool isFinalized = item['is_verif'] as bool? ?? false;
    final bool? finalOutcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final int validVotes = item['vote_valid'] as int? ?? 0;
    final int invalidVotes = item['vote_invalid'] as int? ?? 0;
    final int totalVotes = item['total_votes'] as int? ?? 0;
    final String? imageUrl = item['gambar_temuan']?.toString();
    final String title = item['judul_temuan']?.toString() ?? '-';
    final String lokasi = item['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String kategori =
        item['kategoritemuan']?['nama_kategoritemuan']?.toString() ?? '-';

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
          border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            // ── Row utama ──
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
                _AdminHistoryThumb(url: imageUrl, label: t('Temuan', 'Finding', '发现')),
                const SizedBox(width: 4),
                _AdminHistoryThumb(
                  url: item['penyelesaian']?['gambar_penyelesaian']?.toString(),
                  label: t('Selesai', 'Completion', '完成'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(kategori,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor)),
                        ),
                        const SizedBox(height: 4),
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF134E4A),
                                height: 1.25)),
                        const SizedBox(height: 5),
                        Row(children: [
                          Icon(Icons.place_outlined,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(lokasi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: Colors.grey.shade500)),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.access_time_rounded,
                              size: 10, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(dateStr,
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
                          color: accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
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

            // ── Divider ──
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 1,
                color: accent.withOpacity(0.12)),

            // ── Vote Breakdown (sama persis dengan executive history) ──
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
                            color: const Color(0xFF134E4A).withOpacity(0.7)),
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
                              ? const Color(0xFF16A34A).withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isFinalized
                                ? const Color(0xFF16A34A).withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
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
                      Text('$totalVotes ${t("suara", "votes", "票")}',
                          style: GoogleFonts.poppins(
                              fontSize: 9.5, color: Colors.grey.shade500)),
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
                          color: const Color(0xFFDC2626).withOpacity(0.18)),
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
                  // Majority result + total votes
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: finalOutcome == null
                              ? Colors.orange.withOpacity(0.07)
                              : finalOutcome
                                  ? const Color(0xFF16A34A).withOpacity(0.07)
                                  : const Color(0xFFDC2626).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: finalOutcome == null
                                ? Colors.orange.withOpacity(0.2)
                                : finalOutcome
                                    ? const Color(0xFF16A34A).withOpacity(0.2)
                                    : const Color(0xFFDC2626).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('Hasil Mayoritas', 'Majority Result', '多数结果'),
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
                                      ? t('Menunggu', 'Pending', '待定')
                                      : finalOutcome
                                          ? t('Valid', 'Valid', '有效')
                                          : t('Tidak Valid', 'Invalid', '无效'),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1E3A8A).withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('Total Suara', 'Total Votes', '总票数'),
                                style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.how_to_vote_rounded,
                                  size: 13, color: Color(0xFF1E3A8A)),
                              const SizedBox(width: 4),
                              Text('$totalVotes',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E3A8A))),
                              const SizedBox(width: 3),
                              Text(t('suara', 'votes', '票'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: Colors.grey.shade500)),
                            ]),
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

  // ══════════════════════════════════════════════
  // TAB 3: ACCIDENT VERIFIKASI
  // ══════════════════════════════════════════════

  Widget _buildAccidentTab() {
    const Color accColor = Color(0xFFDC2626);

    return Column(
      children: [
        _buildStatsRow(
          total: _statAccidentTotal,
          finalized: _statAccidentFinal,
          pending: _statAccidentPending,
          color: accColor,
        ),
        _buildSearchAndFilter(
          searchCtrl: _accidentSearchCtrl,
          filter: _accidentFilter,
          onFilterChanged: (v) => setState(() => _accidentFilter = v),
          onSearchChanged: (v) => setState(() => _accidentSearch = v),
          color: accColor,
        ),
        Expanded(
          child: _accidentLoading
              ? _buildListShimmer()
              : _filteredAccident.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAccidentVerifikasi,
                      color: accColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: _filteredAccident.length,
                        itemBuilder: (_, i) =>
                            _buildAccidentCard(_filteredAccident[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAccidentCard(Map<String, dynamic> item) {
    final bool isFinalized = item['is_verif'] as bool? ?? false;
    final bool? finalOutcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final String? imageUrl = item['foto_bukti']?.toString();
    final String title = item['judul']?.toString() ?? '-';
    final String lokasiName = item['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String pelaporName = item['pelapor']?['nama']?.toString() ?? '-';
    final String severity = item['tingkat_keparahan']?.toString() ?? '-';

    String finalisasiDateStr = '-';
    try {
      final rawDate = item['updated_at'] ?? item['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        finalisasiDateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    // Tentukan accent & label berdasarkan status
    final Color accent;
    final IconData statusIcon;
    final String statusLabel;

    if (!isFinalized || finalOutcome == null) {
      // Pending — tampilkan dengan warna orange
      accent = Colors.orange.shade400;
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

    final Color sevColor = severity == 'Berat'
        ? const Color(0xFFDC2626)
        : severity == 'Menengah'
            ? const Color(0xFFF97316)
            : const Color(0xFF16A34A);

    final Map<String, Map<String, String>> verifDetailMap =
        (item['verif_detail_map'] as Map?)?.map(
              (k, v) => MapEntry(
                k.toString(),
                (v as Map).map((dk, dv) =>
                    MapEntry(dk.toString(), dv?.toString() ?? '')),
              ),
            ) ??
            {};

    return GestureDetector(
      onTap: () => _showAccidentDetailAdmin(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            // ── Header: foto + info utama ──
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
                              color: const Color(0xFFDC2626).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              t('KECELAKAAN', 'ACCIDENT', '事故'),
                              style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFDC2626)),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sevColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: sevColor.withOpacity(0.4), width: 1),
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
                        const SizedBox(height: 4),
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
                        const SizedBox(height: 2),
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
                        Row(children: [
                          Icon(
                            isFinalized
                                ? Icons.verified_rounded
                                : Icons.access_time_rounded,
                            size: 11,
                            color: const Color(0xFF1E3A8A),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isFinalized
                                  ? '${t("Final", "Finalized", "已完成")}: $finalisasiDateStr'
                                  : finalisasiDateStr,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E3A8A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.4),
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
            ),

            // ── Divider ──
            Container(height: 1, color: Colors.grey.shade100),

            // ── Verified By (hanya jika ada) ──
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
                        t('Diverifikasi Oleh', 'Verified By', '由...验证'),
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
                        } else {
                          badgeColor = const Color(0xFF8B5CF6);
                          badgeIcon = Icons.badge_rounded;
                        }

                        return Container(
                          padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: badgeColor.withOpacity(0.25), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: badgeColor.withOpacity(0.15),
                                  border: Border.all(
                                      color: badgeColor.withOpacity(0.4),
                                      width: 1.5),
                                ),
                                child: ClipOval(
                                  child: fotoUrl.isNotEmpty
                                      ? Image.network(fotoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                              badgeIcon,
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
                                            color: badgeColor.withOpacity(0.7),
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
                    t('Belum ada yang memverifikasi', 'No verifier yet', '暂无验证者'),
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

  // ══════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════

  Widget _buildStatsRow({
    required int total,
    required int finalized,
    required int pending,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildStatChip(
            label: t('Total', 'Total', '总计'),
            value: total,
            color: color,
            icon: Icons.list_alt_rounded,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            label: t('Final', 'Finalized', '已完成'),
            value: finalized,
            color: const Color(0xFF16A34A),
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            label: t('Pending', 'Pending', '待定'),
            value: pending,
            color: Colors.orange.shade500,
            icon: Icons.pending_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text('$value',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 9.5, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter({
    required TextEditingController searchCtrl,
    required String filter,
    required ValueChanged<String> onFilterChanged,
    required ValueChanged<String> onSearchChanged,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: t('Cari...', 'Search...', '搜索...'),
              hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: color, size: 18),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        searchCtrl.clear();
                        onSearchChanged('');
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
                  borderSide: BorderSide(color: color.withOpacity(0.2))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips — full width dibagi 3 rata
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _buildFilterChip(
                    t('Semua', 'All', '全部'), 'all', filter, onFilterChanged, color),
                _buildFilterChip(
                    t('Final', 'Finalized', '已完成'), 'finalized', filter, onFilterChanged, color),
                _buildFilterChip(
                    t('Pending', 'Pending', '待定'), 'pending', filter, onFilterChanged, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current,
    ValueChanged<String> onChanged, Color color) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildVoteChip(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    ]);
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

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
              4,
              (_) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    height: 100,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                  )),
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

  // ── Helper thumb untuk findings card ──
  Widget _AdminHistoryThumb({required String? url, required String label}) {
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

  // ── Helper vote pill untuk findings card ──
  Widget _AdminVotePill(
      {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 1)),
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