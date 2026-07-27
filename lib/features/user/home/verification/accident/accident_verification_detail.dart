import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/utils/jabatan_helper.dart';
import '../../../accident/picker/accident_pick_cause.dart';
import '../../../accident/picker/accident_pick_severity.dart';
import 'accident_verification_edit.dart';

class AccidentVerificationDetailScreen extends StatelessWidget {
  final String lang;
  final Map<String, dynamic> data;
  final Map<String, dynamic> stats;
  final int? userJabatanId;

  const AccidentVerificationDetailScreen({
    super.key,
    required this.lang,
    required this.data,
    required this.stats,
    this.userJabatanId,
  });

  static const Color _accentColor = Color(0xFFDC2626);
  static const Color _blueColor = Color(0xFF1D72F3);

  String t(String id, String en, String zh) {
    if (lang == 'EN') return en;
    if (lang == 'ZH') return zh;
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final bool? finalOutcome = data['hasil_verifikasi_mayoritas'] as bool?;
    final String? imageUrl = data['foto_bukti']?.toString();
    final String title = data['judul']?.toString() ?? '-';

    final String? rawSeverity = data['tingkat_keparahan']?.toString();
    final String? rawCause = data['penyebab']?.toString();
    final String deskripsi = data['deskripsi']?.toString() ?? '-';
    final String lokasiName = data['lokasi']?['nama_lokasi']?.toString() ?? '-';
    final String pelaporName = data['pelapor']?['nama']?.toString() ?? '-';
    final String pihakTerdampak = data['pihak_terdampak']?['nama']?.toString() ?? '';
    final String tanggal = data['tanggal_kejadian']?.toString() ?? '-';
    final String waktuRaw = data['waktu_kejadian']?.toString() ?? '';
    final String waktu = waktuRaw.length >= 5 ? waktuRaw.substring(0, 5) : '-';
    final String departemen = data['departemen_terdampak']?.toString() ?? '';
    final String tindakan = data['tindakan_diambil']?.toString() ?? '';

    final String severityLabel = AccidentSeverityData.labelOf(rawSeverity, lang);
    final Color sevColor = AccidentSeverityData.colorOf(rawSeverity);
    final IconData sevIcon = AccidentSeverityData.iconOf(rawSeverity);

    final String causeLabel = AccidentCauseData.labelOf(rawCause, lang);
    final Color causeColor = AccidentCauseData.colorOf(rawCause);
    final IconData causeIcon = AccidentCauseData.iconOf(rawCause);

    final Color accent =
        finalOutcome == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData statusIcon =
        finalOutcome == true ? Icons.verified_rounded : Icons.cancel_rounded;
    final String statusLabel = finalOutcome == true
        ? t('Valid', 'Valid', '有效')
        : t('Tidak Valid', 'Invalid', '无效');

    String dateStr = '-';
    try {
      final rawDate = data['updated_at'] ?? data['created_at'];
      if (rawDate != null) {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      }
    } catch (_) {}

    final Map<String, Map<String, String>> verifDetailMap =
        (stats['verif_detail_map'] as Map?)?.map(
              (k, v) => MapEntry(
                k.toString(),
                (v as Map)
                    .map((dk, dv) => MapEntry(dk.toString(), dv?.toString() ?? '')),
              ),
            ) ??
            {};

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
                    _buildDetailImage(context, imageUrl, severityLabel, sevIcon, sevColor),
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
                          _buildPersonRow(Icons.person_outline,
                              t('Pelapor', 'Reporter', '报告人'), pelaporName, ''),
                          _buildBadgeDetailRow(
                            Icons.map,
                            t('Lokasi Kejadian', 'Incident Location', '事故地点'),
                            _buildValueBadge(Icons.location_city_rounded, lokasiName,
                                const Color(0xFF10B981)),
                          ),
                          _buildDetailRow(
                            Icons.event_busy_rounded,
                            t('Waktu Kejadian', 'Incident Time', '事故时间'),
                            waktu == '-' ? tanggal : '$tanggal, $waktu',
                          ),
                          if (departemen.isNotEmpty)
                            _buildBadgeDetailRow(
                              Icons.apartment_rounded,
                              t('Departemen Terdampak', 'Affected Department', '受影响部门'),
                              _buildValueBadge(Icons.business_rounded, departemen,
                                  const Color(0xFF6366F1)),
                            ),
                          if (causeLabel.isNotEmpty && causeLabel != '-')
                            _buildBadgeDetailRow(
                              Icons.build_circle_outlined,
                              t('Penyebab', 'Cause', '原因'),
                              _buildValueBadge(causeIcon, causeLabel, causeColor),
                            ),
                          if (pihakTerdampak.isNotEmpty)
                            _buildPersonRow(Icons.personal_injury_rounded,
                                t('Pihak Terdampak', 'Affected Party', '受影响人员'),
                                pihakTerdampak, ''),
                          _buildDetailRow(
                              Icons.calendar_today,
                              t('Difinalisasi Pada', 'Finalized On', '完成日期'),
                              dateStr,
                              isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (deskripsi.isNotEmpty && deskripsi != '-') ...[
                      _buildSectionTitle(Icons.description_outlined,
                          t('Deskripsi Kejadian', 'Incident Description', '事故描述')),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                height: 1.6)),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (tindakan.isNotEmpty) ...[
                      _buildSectionTitle(
                          Icons.medical_services_outlined,
                          t('Tindakan yang Diambil', 'Action Taken', '已采取的措施'),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                height: 1.6)),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildSectionTitle(Icons.verified_user_rounded,
                        t('Diverifikasi Oleh', 'Verified By', '验证人'),
                        color: _blueColor),
                    const SizedBox(height: 10),
                    if (verifDetailMap.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
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
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded, size: 15, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(
                            t('Belum ada yang memverifikasi', 'No verifier yet', '暂无验证人'),
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ]),
                      ),

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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: _accentColor),
          ),
          Expanded(
            child: Center(
              child: Text(
                t('Detail Riwayat Verifikasi', 'Verification History Detail', '验证历史详情'),
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

  Widget _buildDetailImage(BuildContext context, String? url, String severityLabel,
      IconData sevIcon, Color sevColor) {
    return GestureDetector(
      onTap: () {
        if (url == null || url.isEmpty) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black.withValues(alpha: 0.95),
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, __, ___) => AccidentFullscreenImageViewer(imageUrl: url),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withValues(alpha: 0.4), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              (url != null && url.isNotEmpty)
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
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sevColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(sevIcon, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(severityLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
              if (url != null && url.isNotEmpty)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        ),
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
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
      ],
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
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color, bool isLast = false}) {
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
                style: GoogleFonts.poppins(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeDetailRow(IconData icon, String label, Widget badge,
      {Color? color, bool isLast = false}) {
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
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
            ]),
          ),
        ],
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
      lang: lang,
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
                  decoration:
                      const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF1D72F3)),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.black)),
                if (jabatanLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(badgeIcon, size: 11, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(jabatanLabel,
                          style: GoogleFonts.inter(
                              fontSize: 10.5, fontWeight: FontWeight.w700, color: badgeColor)),
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