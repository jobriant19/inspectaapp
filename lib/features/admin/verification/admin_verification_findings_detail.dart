import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminVerificationFindingsDetailScreen extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> item;
  final int initialTab;

  const AdminVerificationFindingsDetailScreen({
    super.key,
    required this.lang,
    required this.item,
    this.initialTab = 0,
  });

  @override
  State<AdminVerificationFindingsDetailScreen> createState() =>
      _AdminVerificationFindingsDetailScreenState();
}

class _AdminVerificationFindingsDetailScreenState
    extends State<AdminVerificationFindingsDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _completionColor = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _openImageViewer(String? url) {
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _FindingImageViewer(imageUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final typeColor = _typeColor(item);
    final typeBadge = _typeBadgeLabel(item);
    final bool isFindingsTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailImage(
                      isFindingsTab
                          ? item['gambar_temuan']?.toString()
                          : item['penyelesaian']?['gambar_penyelesaian']?.toString(),
                      isFindingsTab ? _primaryColor : _completionColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTopInfoRow(item, typeColor, typeBadge),
                    const SizedBox(height: 10),
                    _buildHeadingText(item),
                    const SizedBox(height: 14),
                    _isKts(item)
                        ? (isFindingsTab
                            ? _buildFindingRowsKts(item)
                            : _buildCompletionRowsKts(item))
                        : (isFindingsTab
                            ? _buildFindingRows5R(item)
                            : _buildCompletionRows5R(item)),
                    const SizedBox(height: 14),
                    _buildVoteBreakdown(item),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: _primaryColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _primaryColor),
          ),
          Expanded(
            child: Center(
              child: Text(
                t('Detail Verifikasi', 'Verification Detail', '验证详情'),
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, Icons.search_rounded,
                t('Temuan', 'Findings', '发现'), _primaryColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(1, Icons.task_alt_rounded,
                t('Selesai', 'Completion', '完成'), _completionColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label, Color color) {
    final bool isActive = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? color : color.withValues(alpha: 0.3),
              width: isActive ? 1.5 : 1),
          boxShadow: isActive
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
            Icon(icon, size: 16, color: isActive ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRow(IconData icon, String label, String value, {bool isLast = false}) {
    final Color tabColor = _tabController.index == 0 ? _primaryColor : _completionColor;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: tabColor),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: tabColor)),
          ]),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tabColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tabColor.withValues(alpha: 0.2)),
            ),
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w700, color: color, height: 1.0)),
      ]),
    );
  }

  Widget _buildDetailImage(String? url, Color borderColor) {
    final bool hasImage = url != null && url.isNotEmpty;
    return GestureDetector(
      onTap: () => _openImageViewer(url),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              hasImage
                  ? Image.network(url,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 48, color: Colors.grey.shade400)))
                  : Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 48, color: Colors.grey.shade400)),
              if (hasImage)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteBreakdown(Map<String, dynamic> item) {
    final bool? finalOutcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final int validVotes = item['vote_valid'] as int? ?? 0;
    final int invalidVotes = item['vote_invalid'] as int? ?? 0;
    final int totalVotes = item['total_votes'] as int? ?? 0;
    final double validRatio = totalVotes > 0 ? validVotes / totalVotes : 0.0;
    final bool hasVotes = totalVotes > 0;
    final Color tabColor = _tabController.index == 0 ? _primaryColor : _completionColor;
    const Color validColor = Color(0xFF16A34A);
    const Color invalidColor = Color(0xFFE11D48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.how_to_vote_rounded, size: 14, color: tabColor),
          const SizedBox(width: 6),
          Text(t('Rincian Suara', 'Vote Breakdown', '投票详情'),
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: tabColor)),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.thumb_up_rounded, size: 13, color: validColor),
                    const SizedBox(width: 4),
                    Text('$validVotes ${t("Valid", "Valid", "有效")}',
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: validColor)),
                  ]),
                  Row(children: [
                    Text('$invalidVotes ${t("Tidak Valid", "Invalid", "无效")}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w800, color: invalidColor)),
                    const SizedBox(width: 4),
                    const Icon(Icons.thumb_down_rounded, size: 13, color: invalidColor),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasVotes
                    ? Stack(children: [
                        Container(
                            height: 10, width: double.infinity, color: invalidColor.withValues(alpha: 0.18)),
                        FractionallySizedBox(
                          widthFactor: validRatio.clamp(0.0, 1.0),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFF16A34A), Color(0xFF4ADE80)]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ])
                    : Container(height: 10, width: double.infinity, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: _buildResultBox(
                    icon: finalOutcome == null
                        ? Icons.hourglass_empty_rounded
                        : finalOutcome
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_down_rounded,
                    iconColor: finalOutcome == null
                        ? Colors.orange
                        : finalOutcome
                            ? validColor
                            : invalidColor,
                    label: t('Hasil Mayoritas', 'Majority Result', '多数结果'),
                    value: finalOutcome == null
                        ? t('Menunggu', 'Pending', '待定')
                        : finalOutcome
                            ? t('Valid', 'Valid', '有效')
                            : t('Tidak Valid', 'Invalid', '无效'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildResultBox(
                    icon: Icons.how_to_vote_rounded,
                    iconColor: const Color(0xFF1E3A8A),
                    label: t('Total Suara', 'Total Votes', '总票数'),
                    value: '$totalVotes ${t("suara", "votes", "票")}',
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 2),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
            ],
          ),
        ),
      ]),
    );
  }

  String _subkategoriFull(Map<String, dynamic> item) {
    final sub = item['subkategoritemuan'] as Map?;
    final subName = sub?['nama_subkategoritemuan']?.toString() ?? '';
    final katName = sub?['kategoritemuan']?['nama_kategoritemuan']?.toString() ?? '';
    if (subName.isEmpty) return '';
    return katName.isNotEmpty ? '$katName - $subName' : subName;
  }

  String _faktorPenyebabLabel(Map<String, dynamic> item) {
    return item['penyelesaian']?['faktor_penyebab_sub']?['nama_subkategoritemuan']
            ?.toString() ??
        '';
  }

  Widget _buildPicRow(Map<String, dynamic> item) {
    final Color tabColor = _tabController.index == 0 ? _primaryColor : _completionColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.badge_rounded, size: 14, color: tabColor),
            const SizedBox(width: 6),
            Text(t('Penanggung Jawab', 'PIC', '负责人'),
                style: GoogleFonts.poppins(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: tabColor)),
          ]),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tabColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tabColor.withValues(alpha: 0.2)),
            ),
            child: Builder(builder: (_) {
              final pic = item['penanggung_jawab'] as Map?;
              final name = pic?['nama']?.toString() ?? '-';
              final avatarUrl = pic?['gambar_user']?.toString();
              return Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: tabColor.withValues(alpha: 0.15),
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Icon(Icons.person, size: 16, color: tabColor)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                ),
              ]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadges(Map<String, dynamic> item) {
    final badges = <Widget>[];
    if (item['is_pro'] == true) {
      badges.add(_miniStatusBadge(Icons.workspace_premium_rounded,
          t('Pro', 'Pro', 'Pro'), const Color(0xFFF59E0B)));
    }
    if (item['is_visitor'] == true) {
      badges.add(_miniStatusBadge(Icons.person_pin_circle_rounded,
          t('Visitor', 'Visitor', '访客'), const Color(0xFF0EA5E9)));
    }
    if (item['is_eksekutif'] == true) {
      badges.add(_miniStatusBadge(Icons.verified_user_rounded,
          t('Eksekutif', 'Executive', '高管'), const Color(0xFFDC2626)));
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: badges);
  }

  Widget _miniStatusBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: Colors.white),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    );
  }

  Widget _buildTopInfoRow(Map<String, dynamic> item, Color typeColor, String typeBadge) {
    final bool isFindingsTab = _tabController.index == 0;
    final Color tabColor = isFindingsTab ? _primaryColor : _completionColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _sectionLabel(
          isFindingsTab ? Icons.search_rounded : Icons.task_alt_rounded,
          isFindingsTab ? t('Temuan', 'Finding', '发现') : t('Selesai', 'Completion', '完成'),
          tabColor,
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildStatusBadges(item)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: typeColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: typeColor.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(typeBadge,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildHeadingText(Map<String, dynamic> item) {
    final bool isFindingsTab = _tabController.index == 0;
    final String text = isFindingsTab
        ? (item['judul_temuan']?.toString() ?? '-')
        : (item['penyelesaian']?['catatan_penyelesaian']?.toString() ?? '-');
    return Text(text,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black));
  }

  Widget _wrapDetailCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: rows.isEmpty
          ? Text(
              t('Belum ada data.', 'No data yet.', '暂无数据。'),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  // FINDINGS - 5R
  Widget _buildFindingRows5R(Map<String, dynamic> item) {
    final deskripsi = item['deskripsi_temuan']?.toString() ?? '';
    final lokasi = _locationLabel(item);
    final subkategori = _subkategoriFull(item);
    String targetStr = '';
    try {
      final raw = item['target_waktu_selesai']?.toString();
      if (raw != null && raw.isNotEmpty) {
        targetStr = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(raw).toLocal());
      }
    } catch (_) {}
    final poinTemuan = item['poin_temuan'];
    final picMap = item['penanggung_jawab'] as Map?;
    final hasPic = picMap != null && (picMap['nama']?.toString().isNotEmpty ?? false);
    final isVisitor = item['is_visitor'] == true;
    final namaVisitor = item['nama_visitor']?.toString() ?? '';
    final perusahaanVisitor = item['perusahaan_visitor']?.toString() ?? '';
    final isLate = item['is_late'] == true;
    final latetime = item['latetime']?.toString() ?? '';
    final perpanjang = item['perpanjang'] as Map?;

    final rows = <Widget>[];
    void add(IconData icon, String label, String value) {
      if (value.trim().isEmpty || value == '-') return;
      rows.add(_buildCompletionRow(icon, label, value));
    }

    add(Icons.notes_rounded, t('Deskripsi', 'Description', '描述'), deskripsi);
    add(Icons.map, t('Lokasi', 'Location', '位置'), lokasi);
    add(Icons.category_outlined, t('Subkategori', 'Subcategory', '子类别'), subkategori);
    add(Icons.event_rounded, t('Target Selesai', 'Target Due', '目标完成'), targetStr);
    if (poinTemuan != null) add(Icons.star_rounded, t('Poin Temuan', 'Finding Points', '发现积分'), '$poinTemuan');
    if (hasPic) rows.add(_buildPicRow(item));
    if (isVisitor) {
      add(Icons.person_pin_circle_rounded, t('Nama Visitor', 'Visitor Name', '访客姓名'), namaVisitor);
      add(Icons.apartment_rounded, t('Perusahaan', 'Company', '公司'), perusahaanVisitor);
    }
    if (isLate) add(Icons.warning_amber_rounded, t('Keterlambatan', 'Late Time', '延迟时间'), latetime);
    if (perpanjang != null) {
      final alasan = perpanjang['alasan_perpanjang']?.toString() ?? '';
      String perpanjangDate = '';
      try {
        final raw = perpanjang['tanggal_selesai']?.toString();
        if (raw != null && raw.isNotEmpty) {
          perpanjangDate = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(raw).toLocal());
        }
      } catch (_) {}
      add(Icons.update_rounded, t('Alasan Perpanjangan', 'Extension Reason', '延期原因'), alasan);
      add(Icons.event_available_rounded, t('Selesai Perpanjangan', 'Extended Due', '延期完成日期'), perpanjangDate);
    }

    return _wrapDetailCard(rows);
  }

  // FINDINGS - KTS
  Widget _buildFindingRowsKts(Map<String, dynamic> item) {
    final deskripsi = item['deskripsi_temuan']?.toString() ?? '';
    final section = _locationLabel(item);
    final faktorPenyebab = _faktorPenyebabLabel(item);
    final noOrder = item['no_order']?.toString() ?? '';
    final namaItemManual = item['nama_item_manual']?.toString() ?? '';
    final jumlahItem = item['jumlah_item'];
    final poinTemuan = item['poin_temuan'];
    final picMap = item['penanggung_jawab'] as Map?;
    final hasPic = picMap != null && (picMap['nama']?.toString().isNotEmpty ?? false);
    final isVisitor = item['is_visitor'] == true;
    final namaVisitor = item['nama_visitor']?.toString() ?? '';
    final perusahaanVisitor = item['perusahaan_visitor']?.toString() ?? '';
    final isLate = item['is_late'] == true;
    final latetime = item['latetime']?.toString() ?? '';
    final perpanjang = item['perpanjang'] as Map?;

    final rows = <Widget>[];
    void add(IconData icon, String label, String value) {
      if (value.trim().isEmpty || value == '-') return;
      rows.add(_buildCompletionRow(icon, label, value));
    }

    add(Icons.notes_rounded, t('Deskripsi', 'Description', '描述'), deskripsi);
    add(Icons.map, t('Section', 'Section', '区域'), section);
    add(Icons.report_problem_outlined, t('Faktor Penyebab', 'Cause Factor', '原因因素'), faktorPenyebab);
    add(Icons.confirmation_number_outlined, t('No Order', 'Order No.', '订单编号'), noOrder);
    add(Icons.inventory_2_outlined, t('Nama Item', 'Item Name', '项目名称'), namaItemManual);
    if (jumlahItem != null) add(Icons.numbers_rounded, t('Jumlah Item', 'Item Qty', '项目数量'), '$jumlahItem');
    if (poinTemuan != null) add(Icons.star_rounded, t('Poin Temuan', 'Finding Points', '发现积分'), '$poinTemuan');
    if (hasPic) rows.add(_buildPicRow(item));
    if (isVisitor) {
      add(Icons.person_pin_circle_rounded, t('Nama Visitor', 'Visitor Name', '访客姓名'), namaVisitor);
      add(Icons.apartment_rounded, t('Perusahaan', 'Company', '公司'), perusahaanVisitor);
    }
    if (isLate) add(Icons.warning_amber_rounded, t('Keterlambatan', 'Late Time', '延迟时间'), latetime);
    if (perpanjang != null) {
      final alasan = perpanjang['alasan_perpanjang']?.toString() ?? '';
      String perpanjangDate = '';
      try {
        final raw = perpanjang['tanggal_selesai']?.toString();
        if (raw != null && raw.isNotEmpty) {
          perpanjangDate = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(raw).toLocal());
        }
      } catch (_) {}
      add(Icons.update_rounded, t('Alasan Perpanjangan', 'Extension Reason', '延期原因'), alasan);
      add(Icons.event_available_rounded, t('Selesai Perpanjangan', 'Extended Due', '延期完成日期'), perpanjangDate);
    }

    return _wrapDetailCard(rows);
  }

  // COMPLETION - 5R
  Widget _buildCompletionRows5R(Map<String, dynamic> item) {
    final penyelesaian = item['penyelesaian'] as Map?;
    final cost = num.tryParse(penyelesaian?['additional_cost']?.toString() ?? '');
    final poin = num.tryParse(penyelesaian?['poin_penyelesaian']?.toString() ?? '');
    String tanggalSelesai = '';
    try {
      final raw = penyelesaian?['tanggal_selesai']?.toString();
      if (raw != null && raw.isNotEmpty) {
        tanggalSelesai = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(raw).toLocal());
      }
    } catch (_) {}

    final rows = <Widget>[];
    if (cost != null && cost > 0) {
      rows.add(_buildCompletionRow(Icons.payments_outlined, t('Biaya Tambahan', 'Additional Cost', '额外费用'), cost.toStringAsFixed(0)));
    }
    if (poin != null) {
      rows.add(_buildCompletionRow(Icons.star_rounded, t('Poin', 'Points', '积分'), '$poin'));
    }
    if (tanggalSelesai.isNotEmpty) {
      rows.add(_buildCompletionRow(Icons.event_available_rounded, t('Tanggal Selesai', 'Completion Date', '完成日期'), tanggalSelesai));
    }
    return _wrapDetailCard(rows);
  }

  // COMPLETION - KTS
  Widget _buildCompletionRowsKts(Map<String, dynamic> item) {
    final penyelesaian = item['penyelesaian'] as Map?;
    final penyebab = penyelesaian?['penyebab']?.toString() ?? '';
    final bagian = penyelesaian?['bagian']?.toString() ?? '';
    final cost = num.tryParse(penyelesaian?['additional_cost']?.toString() ?? '');
    final poin = num.tryParse(penyelesaian?['poin_penyelesaian']?.toString() ?? '');
    String tanggalSelesai = '';
    try {
      final raw = penyelesaian?['tanggal_selesai']?.toString();
      if (raw != null && raw.isNotEmpty) {
        tanggalSelesai = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(raw).toLocal());
      }
    } catch (_) {}

    final rows = <Widget>[];
    if (penyebab.isNotEmpty) rows.add(_buildCompletionRow(Icons.report_problem_outlined, t('Penyebab', 'Cause', '原因'), penyebab));
    if (bagian.isNotEmpty) rows.add(_buildCompletionRow(Icons.precision_manufacturing_outlined, t('Bagian', 'Part', '部件'), bagian));
    if (cost != null && cost > 0) rows.add(_buildCompletionRow(Icons.payments_outlined, t('Biaya Tambahan', 'Additional Cost', '额外费用'), cost.toStringAsFixed(0)));
    if (poin != null) rows.add(_buildCompletionRow(Icons.star_rounded, t('Poin', 'Points', '积分'), '$poin'));
    if (tanggalSelesai.isNotEmpty) rows.add(_buildCompletionRow(Icons.event_available_rounded, t('Tanggal Selesai', 'Completion Date', '完成日期'), tanggalSelesai));
    return _wrapDetailCard(rows);
  }
}

class _FindingImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FindingImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, color: Colors.white54, size: 60),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}