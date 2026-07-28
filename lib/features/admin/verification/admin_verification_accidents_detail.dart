import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../user/accident/picker/accident_pick_cause.dart';
import '../../user/accident/picker/accident_pick_severity.dart';

class AdminVerificationAccidentsDetailScreen extends StatelessWidget {
  final String lang;
  final Map<String, dynamic> item;

  const AdminVerificationAccidentsDetailScreen({
    super.key,
    required this.lang,
    required this.item,
  });

  static const Color _accentColor = Color(0xFFDC2626);
  static const Color _solutionColor = Color(0xFF4338CA);
  static const Color _blueColor = Color(0xFF1D72F3);

  String t(String id, String en, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  Map<String, dynamic>? _getResolution(Map<String, dynamic> item) {
    final raw = item['resolution'];
    if (raw is List && raw.isNotEmpty) return Map<String, dynamic>.from(raw.first as Map);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  void _openImageViewer(BuildContext context, String? url) {
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => _AccidentImageViewer(imageUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinalized = item['is_verif'] as bool? ?? false;
    final bool? outcome = item['hasil_verifikasi_mayoritas'] as bool?;
    final String? imageUrl = item['foto_bukti']?.toString();
    final String title = item['judul']?.toString() ?? '-';
    final String lokasi = item['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String pelapor = item['pelapor']?['nama']?.toString() ?? '-';
    final String pelaporFoto = item['pelapor']?['gambar_user']?.toString() ?? '';
    final String supervisor = item['supervisor']?['nama']?.toString() ?? '';
    final String pihakTerdampak = item['pihak_terdampak']?['nama']?.toString() ??
        item['nama_pihak_terdampak']?.toString() ?? '';
    final String pihakTerdampakFoto = item['pihak_terdampak']?['gambar_user']?.toString() ?? '';
    final String saksi = item['saksi']?['nama']?.toString() ??
        item['nama_saksi']?.toString() ?? '';
    final String saksiFoto = item['saksi']?['gambar_user']?.toString() ?? '';
    final String? rawSeverity = item['tingkat_keparahan']?.toString();
    final String? rawCause = item['penyebab']?.toString();
    final String deskripsi = item['deskripsi']?.toString() ?? '-';
    final String departemen = item['departemen_terdampak']?.toString() ?? '';
    final String tindakan = item['tindakan_diambil']?.toString() ?? '';

    final resolution = _getResolution(item);

    // SEVERITY
    final String severityLabel = AccidentSeverityData.labelOf(rawSeverity, lang);
    final Color sevColor = AccidentSeverityData.colorOf(rawSeverity);
    final IconData sevIcon = AccidentSeverityData.iconOf(rawSeverity);

    // CAUSE
    final String causeLabel = AccidentCauseData.labelOf(rawCause, lang);
    final Color causeColor = AccidentCauseData.colorOf(rawCause);
    final IconData causeIcon = AccidentCauseData.iconOf(rawCause);

    String dateStr = '-';
    try {
      final dt = DateTime.parse(item['created_at']?.toString() ?? '').toLocal();
      dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {}

    String kejadianStr = '-';
    try {
      final tgl = item['tanggal_kejadian']?.toString();
      final wkt = item['waktu_kejadian']?.toString();
      if (tgl != null && tgl.isNotEmpty) {
        final dt = DateTime.parse(tgl);
        kejadianStr = DateFormat('dd MMM yyyy').format(dt);
        if (wkt != null && wkt.isNotEmpty) {
          kejadianStr += ', ${wkt.substring(0, wkt.length >= 5 ? 5 : wkt.length)}';
        }
      }
    } catch (_) {}

    final Color accent;
    final IconData statusIcon;
    final String statusLabel;
    if (!isFinalized || outcome == null) {
      accent = Colors.orange.shade500;
      statusIcon = Icons.hourglass_empty_rounded;
      statusLabel = t('Menunggu', 'Pending', '待定');
    } else if (outcome) {
      accent = const Color(0xFF16A34A);
      statusIcon = Icons.verified_rounded;
      statusLabel = t('Valid', 'Valid', '有效');
    } else {
      accent = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
      statusLabel = t('Tidak Valid', 'Invalid', '无效');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailImage(context, imageUrl, _accentColor),
                    const SizedBox(height: 12),
                    _buildTopInfoRow(statusIcon, statusLabel, accent, severityLabel, sevIcon, sevColor),
                    const SizedBox(height: 10),
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPersonRow(Icons.person_outline, t('Pelapor', 'Reporter', '报告人'), pelapor, pelaporFoto),
                          _buildBadgeDetailRow(
                            Icons.map,
                            t('Lokasi Kejadian', 'Incident Location', '事故地点'),
                            _buildValueBadge(Icons.location_city_rounded, lokasi, const Color(0xFF10B981)),
                          ),
                          _buildDetailRow(Icons.event_busy_rounded, t('Waktu Kejadian', 'Incident Time', '事故时间'), kejadianStr),
                          if (departemen.isNotEmpty)
                            _buildBadgeDetailRow(
                              Icons.apartment_rounded,
                              t('Departemen Terdampak', 'Affected Department', '受影响部门'),
                              _buildValueBadge(Icons.business_rounded, departemen, const Color(0xFF6366F1)),
                            ),
                          if (causeLabel.isNotEmpty && causeLabel != '-')
                            _buildBadgeDetailRow(
                              Icons.build_circle_outlined,
                              t('Penyebab', 'Cause', '原因'),
                              _buildValueBadge(causeIcon, causeLabel, causeColor),
                            ),
                          if (supervisor.isNotEmpty)
                            _buildDetailRow(Icons.supervisor_account_rounded, t('Supervisor', 'Supervisor', '主管'), supervisor),
                          _buildPersonRow(Icons.personal_injury_rounded, t('Pihak Terdampak', 'Affected Party', '受影响人员'), pihakTerdampak, pihakTerdampakFoto),
                          _buildPersonRow(Icons.remove_red_eye_rounded, t('Saksi', 'Witness', '目击者'), saksi, saksiFoto),
                          _buildDetailRow(Icons.calendar_today, t('Dilaporkan Pada', 'Reported On', '报告日期'), dateStr, isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // INCIDENT DESCRIPTION
                    if (deskripsi.isNotEmpty && deskripsi != '-') ...[
                      _buildSectionTitle(Icons.description_outlined, t('Deskripsi Kejadian', 'Incident Description', '事故描述')),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
                        ),
                        child: Text(deskripsi,
                            style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black, height: 1.6)),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ACTION TAKEN 
                    if (tindakan.isNotEmpty) ...[
                      _buildSectionTitle(Icons.medical_services_outlined, t('Tindakan yang Diambil', 'Action Taken', '已采取的措施'),
                          color: _blueColor),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
                        ),
                        child: Text(tindakan,
                            style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black, height: 1.6)),
                      ),
                    ],

                    if (resolution != null) ...[
                      const SizedBox(height: 16),
                      _buildSolutionSection(context, resolution),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _accentColor),
          ),
          Expanded(
            child: Center(
              child: Text(
                t('Detail Verifikasi Kecelakaan', 'Accident Verification Detail', '事故验证详情'),
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _accentColor),
              ),
            ),
          ),
          const SizedBox(width: 20),
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

  Widget _buildSectionTitle(IconData icon, String title, {Color color = _blueColor}) {
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
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _blueColor)),
      ],
    );
  }

  Widget _buildTopInfoRow(IconData statusIcon, String statusLabel, Color accent,
      String severityLabel, IconData sevIcon, Color sevColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _sectionLabel(statusIcon, statusLabel, accent),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sevColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: sevColor.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(sevIcon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(severityLabel,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
      ],
    );
  }

  Widget _buildDetailImage(BuildContext context, String? url, Color borderColor) {
    final bool hasImage = url != null && url.isNotEmpty;
    return GestureDetector(
      onTap: () => _openImageViewer(context, url),
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

  Widget _buildValueBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color, bool isLast = false}) {
    if (value.trim().isEmpty || value == '-') return const SizedBox.shrink();
    final Color c = color ?? _accentColor;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
          ]),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withValues(alpha: 0.2)),
            ),
            child: Text(value,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeDetailRow(IconData icon, String label, Widget badge, {Color? color, bool isLast = false}) {
    final Color c = color ?? _accentColor;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
          ]),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withValues(alpha: 0.2)),
            ),
            child: Align(alignment: Alignment.centerLeft, child: badge),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow(IconData icon, String label, String name, String avatarUrl,
      {Color? color, bool isLast = false}) {
    if (name.trim().isEmpty || name == '-') return const SizedBox.shrink();
    final Color c = color ?? _accentColor;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
          ]),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: c.withValues(alpha: 0.15),
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? Icon(Icons.person, size: 14, color: c) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionSection(BuildContext context, Map<String, dynamic> resolution) {
    final String judul = resolution['judul_resolusi']?.toString() ?? '-';
    final String deskripsi = resolution['deskripsi_resolusi']?.toString() ?? '-';
    final String korektif = resolution['tindakan_korektif']?.toString() ?? '';
    final String preventif = resolution['tindakan_preventif']?.toString() ?? '';
    final String? foto = resolution['foto_resolusi']?.toString();
    final hrd = resolution['hrd'] as Map?;
    final String hrdName = hrd?['nama']?.toString() ?? '-';
    final String hrdFoto = hrd?['gambar_user']?.toString() ?? '';

    String tanggalStr = '-';
    try {
      final raw = resolution['tanggal_resolusi']?.toString();
      if (raw != null && raw.isNotEmpty) {
        tanggalStr = DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.fact_check_rounded, size: 15, color: _solutionColor),
          const SizedBox(width: 6),
          Text(t('Solusi Penanganan', 'Resolution', '解决方案'),
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _solutionColor)),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _solutionColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (foto != null && foto.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _openImageViewer(context, foto),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      foto,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported_outlined, size: 40)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(judul,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _solutionColor)),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.notes_rounded, t('Deskripsi', 'Description', '描述'), deskripsi,
                  color: _solutionColor),
              if (korektif.isNotEmpty)
                _buildDetailRow(Icons.build_rounded, t('Tindakan Korektif', 'Corrective Action', '纠正措施'),
                    korektif, color: _solutionColor),
              if (preventif.isNotEmpty)
                _buildDetailRow(Icons.shield_rounded, t('Tindakan Preventif', 'Preventive Action', '预防措施'),
                    preventif, color: _solutionColor),
              _buildDetailRow(Icons.event_available_rounded, t('Tanggal Resolusi', 'Resolution Date', '解决日期'),
                  tanggalStr, color: _solutionColor),
              _buildPersonRow(Icons.badge_rounded, t('Ditangani Oleh', 'Handled By', '处理人'), hrdName, hrdFoto,
                  color: _solutionColor, isLast: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccidentImageViewer extends StatelessWidget {
  final String imageUrl;
  const _AccidentImageViewer({required this.imageUrl});

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