import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/jabatan_helper.dart';

class AccidentResolutionScreen extends StatefulWidget {
  final String reportId;
  final String lang;

  const AccidentResolutionScreen({
    super.key,
    required this.reportId,
    required this.lang,
  });

  @override
  State<AccidentResolutionScreen> createState() =>
      _AccidentResolutionScreenState();
}

class _AccidentResolutionScreenState extends State<AccidentResolutionScreen> {
  Map<String, dynamic>? _resolution;
  bool _isLoading = true;

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;
  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Solusi Laporan',
      'judul': 'Judul Solusi',
      'desc': 'Deskripsi Solusi',
      'korektif': 'Tindakan Korektif',
      'preventif': 'Tindakan Preventif',
      'date': 'Tanggal Solusi',
      'by': 'Diselesaikan oleh',
      'badge': 'SOLUSI HRD',
      'not_found': 'Data tidak ditemukan',
    },
    'EN': {
      'title': 'Report Solution',
      'judul': 'Solution Title',
      'desc': 'Solution Description',
      'korektif': 'Corrective Action',
      'preventif': 'Preventive Action',
      'date': 'Solution Date',
      'by': 'Resolved by',
      'badge': 'HRD SOLUTION',
      'not_found': 'Data not found',
    },
    'ZH': {
      'title': '报告解决方案',
      'judul': '解决方案标题',
      'desc': '解决方案描述',
      'korektif': '纠正措施',
      'preventif': '预防措施',
      'date': '解决日期',
      'by': '解决人',
      'badge': 'HRD解决方案',
      'not_found': '未找到数据',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadResolution();
  }

  Future<void> _loadResolution() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('resolution_accident')
          .select('''
            id_resolution, judul_resolusi, deskripsi_resolusi,
            tindakan_korektif, tindakan_preventif,
            tanggal_resolusi, created_at, foto_resolusi,
            hrd:resolution_accident_id_hrd_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan))
          ''')
          .eq('id_laporan', widget.reportId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _resolution = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading resolution: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF16A34A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t['title']!,
          style: GoogleFonts.poppins(
              color: const Color(0xFF16A34A),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CupertinoColors.systemGrey5, height: 1),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _loadResolution,
              color: const Color(0xFF16A34A),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: _resolution == null
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Text(
                            t['not_found']!,
                            style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ),
                      )
                    : _buildContent(),
              ),
            ),
    );
  }

  Widget _buildContent() {
    final r = _resolution!;
    final hrd = r['hrd'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FOTO SOLUSI
        if (r['foto_resolusi'] != null &&
            r['foto_resolusi'].toString().isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                r['foto_resolusi'],
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.photo,
                        size: 40, color: Color(0xFF16A34A)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // TITLE CARD - style badge disamakan dengan detail screen, warna hijau
        _buildTitleCard(r),
        const SizedBox(height: 20),

        // INFO CARD: TANGGAL & DISELESAIKAN OLEH
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(CupertinoIcons.calendar, t['date']!,
                  _formatDate(r['tanggal_resolusi'])),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              _buildPersonRow(t['by']!, hrd),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // DESKRIPSI SOLUSI
        _buildSectionTitle(CupertinoIcons.doc_text_fill, t['desc']!),
        const SizedBox(height: 10),
        _buildTextCard(r['deskripsi_resolusi']),
        const SizedBox(height: 20),

        // TINDAKAN KOREKTIF
        if (r['tindakan_korektif'] != null &&
            r['tindakan_korektif'].toString().isNotEmpty) ...[
          _buildSectionTitle(
            CupertinoIcons.wrench_fill,
            t['korektif']!,
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _buildTextCard(r['tindakan_korektif'],
              borderColor: const Color(0xFFFFF7ED),
              bgColor: Colors.white),
          const SizedBox(height: 20),
        ],

        // TINDAKAN PREVENTIF
        if (r['tindakan_preventif'] != null &&
            r['tindakan_preventif'].toString().isNotEmpty) ...[
          _buildSectionTitle(
            CupertinoIcons.shield_fill,
            t['preventif']!,
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _buildTextCard(r['tindakan_preventif'],
              borderColor: const Color(0xFFDCFCE7),
              bgColor: Colors.white),
        ],
      ],
    );
  }

  Widget _buildTitleCard(Map<String, dynamic> r) {
    const badgeColor = Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              r['judul_resolusi'] ?? '-',
              style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: badgeColor, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.checkmark_seal_fill,
                    size: 11, color: badgeColor),
                const SizedBox(width: 3),
                Text(t['badge']!,
                    style: GoogleFonts.inter(
                        color: badgeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _labelColumnWidth = 108;

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF16A34A), size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: _labelColumnWidth,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A))),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow(String label, Map<String, dynamic>? hrd) {
    final jabatanText = _jabatanLabel(hrd);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.person_fill,
              color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: _labelColumnWidth,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A))),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                hrd?['gambar_user'] != null
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(hrd!['gambar_user']))
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.person_fill,
                            size: 20, color: Color(0xFF16A34A)),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hrd?['nama'] ?? '-',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black),
                      ),
                      if (jabatanText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildJabatanBadge(hrd),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _jabatanLabel(Map<String, dynamic>? user) {
    if (user == null) return '';
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final jabatanNama =
        (user['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;
    return JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
  }

  Widget _buildJabatanBadge(Map<String, dynamic>? user) {
    if (user == null) return const SizedBox.shrink();
    final idJabatan = user['id_jabatan'] as int?;
    final isVerificator = user['is_verificator'] as bool?;
    final label = _jabatanLabel(user);
    if (label.isEmpty) return const SizedBox.shrink();
    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title,
      {Color color = const Color(0xFF16A34A)}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A))),
      ],
    );
  }

  Widget _buildTextCard(
    String? text, {
    Color borderColor = const Color(0xFFDCFCE7),
    Color bgColor = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        text ?? '-',
        style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.6),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFBBF7D0),
      highlightColor: const Color(0xFFECFDF5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(
                height: 120,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }
}