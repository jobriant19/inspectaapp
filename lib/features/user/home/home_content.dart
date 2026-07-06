import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../audit/form/audit_form_screen.dart';
import '../../audit/selfie/audit_selfie_screen.dart';
import '../preventif_maintenance/preventif_maintenance_screen.dart';
import 'location/location_screen.dart';
import '../ktsproduksi/kts_production_screen.dart';
import '../accident/accident_report_screen.dart';
import 'choose_mode_sheet.dart';
import 'verification/verification_intro_screen.dart';
import 'home_latest_activity.dart';

// Supabase shorthand
final _sb = Supabase.instance.client;

class HomeContent extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;
  final bool isUserDataLoading;
  final bool isAtAtmi;
  final String userName;
  final String userRole;
  final String userLocationName;
  final int userPoin;
  final int displayedPoin;
  final String? userImage;
  final String? userUnitId;
  final String? userLokasiId;
  final Map<String, dynamic>? latestLogPoin;
  final bool isLatestLogLoading;
  final VoidCallback? onRequestRefresh;
  final VoidCallback onRefresh;
  final VoidCallback onViewActivityLog;
  final Function(bool) onProModeChanged;
  final Function(bool) onVisitorModeChanged;
  final Widget Function() buildInfoCard;
  final Function(int)? onVerifPointEarned;
  final bool isExecVerificator;
  final int? userJabatanId;
  final bool shouldRefreshFindings;
  final bool isPreventiveMaintenanceVisible;
  final VoidCallback? onRefreshDone;

  const HomeContent({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.isVisitorMode,
    required this.isUserDataLoading,
    required this.isAtAtmi,
    required this.userName,
    required this.userRole,
    required this.userLocationName,
    required this.userPoin,
    required this.displayedPoin,
    required this.onRefresh,
    required this.onViewActivityLog,
    required this.onProModeChanged,
    required this.onVisitorModeChanged,
    required this.buildInfoCard,
    this.onVerifPointEarned,
    this.userImage,
    this.userUnitId,
    this.userLokasiId,
    this.latestLogPoin,
    this.isLatestLogLoading = false,
    this.isExecVerificator = false,
    this.userJabatanId,
    this.onRequestRefresh,
    this.shouldRefreshFindings = false,
    this.isPreventiveMaintenanceVisible = false,
    this.onRefreshDone,
  });

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  static const double _kSectionGap = 20;
  Future<List<Map<String, dynamic>>>? _pendingAuditsFuture;
  final GlobalKey<HomeLatestActivityState> _latestActivityKey =
      GlobalKey<HomeLatestActivityState>();

  // Dictionary
  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'inspeksi': 'Inspection',
      'choose_mode': 'Choose Mode',
      'telusur': 'Browse & Manage',
      'lokasi': 'Location',
      'laporan': 'Accident Report',
      'kts_produksi': 'Production KTS',
      'verifikasi': 'Verification',
      'verifikasi_sub': 'Review pending reports',
      'audit_tasks': 'Pending Audit Tasks',
      'preventive_maintenance': 'Preventive Maintenance',
      'preventive_maintenance_sub': 'Schedule & manage maintenance',
    },
    'ID': {
      'inspeksi': 'Inspeksi',
      'choose_mode': 'Pilih Mode',
      'telusur': 'Telusur & Atur',
      'lokasi': 'Lokasi',
      'laporan': 'Laporan Kecelakaan',
      'kts_produksi': 'KTS Produksi',
      'verifikasi': 'Verifikasi',
      'verifikasi_sub': 'Tinjau laporan yang menunggu',
      'audit_tasks': 'Tugas Audit',
      'preventive_maintenance': 'Pemeliharaan Preventif',
      'preventive_maintenance_sub': 'Jadwal & kelola pemeliharaan',
    },
    'ZH': {
      'inspeksi': '检查',
      'choose_mode': '选择模式',
      'telusur': '浏览与管理',
      'lokasi': '地点',
      'laporan': '事故报告',
      'kts_produksi': '生产KTS',
      'verifikasi': '验证',
      'verifikasi_sub': '查看待审报告',
      'audit_tasks': '待完成审计任务',
      'preventive_maintenance': '预防性维护',
      'preventive_maintenance_sub': '计划和管理维护',
    },
  };

  String _t(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _pendingAuditsFuture = _fetchPendingAudits();
  }

  // Refresh Findings (delegasi ke HomeLatestActivity)
  void refreshFindings() {
    _latestActivityKey.currentState?.refreshFindings();
  }

  // Fetch Pending Audit Tasks
  Future<List<Map<String, dynamic>>> _fetchPendingAudits() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final rows = await _sb
          .from('audit_schedule')
          .select(
              'id_schedule, level_type, id_ref, periode_mulai, periode_selesai, status, '
              'id_jenis_audit, JenisAudit:jenis_audit(nama_id, nama_en, nama_zh)') // ✅ BARU
          .eq('id_auditor', userId)
          .inFilter('status', ['pending', 'in_progress'])
          .lte('periode_mulai', today)
          .gte('periode_selesai', today);

      if (rows.isEmpty) return [];

      // Group by Level Fetch Location Name
      final byLevel = <String, List<String>>{};
      for (final r in rows) {
        final level = r['level_type'] as String;
        byLevel.putIfAbsent(level, () => []).add(r['id_ref'].toString());
      }

      // Fetch All Paralel Location Name per Level
      final nameMap = <String, String>{};
      await Future.wait(byLevel.entries.map((e) async {
        final level = e.key;
        final ids = e.value;
        try {
          final res = await _sb
              .from(level)
              .select('id_$level, nama_$level')
              .inFilter('id_$level', ids);
          for (final r in res) {
            nameMap[r['id_$level'].toString()] = r['nama_$level']?.toString() ?? r['id_$level'].toString();
          }
        } catch (_) {}
      }));

      return List<Map<String, dynamic>>.from(rows).map((row) {
        // ✅ BARU: label jenis audit sesuai bahasa
        String? jenisLabel;
        final jenisData = row['JenisAudit'] as Map<String, dynamic>?;
        if (jenisData != null) {
          jenisLabel = widget.lang == 'EN'
              ? jenisData['nama_en']?.toString()
              : widget.lang == 'ZH'
                  ? jenisData['nama_zh']?.toString()
                  : jenisData['nama_id']?.toString();
        }
        return {
          ...row,
          'location_name': nameMap[row['id_ref'].toString()] ?? row['id_ref'].toString(),
          'jenis_audit_label': jenisLabel, // ✅ BARU
        };
      }).toList();
    } catch (e) {
      debugPrint('Pending audits error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          widget.isUserDataLoading ? _buildInfoCardSkeleton() : widget.buildInfoCard(),
          const SizedBox(height: _kSectionGap),

          _buildChooseModeButton(),
          _buildPendingAuditSection(),

          if (widget.isExecVerificator) ...[
            const SizedBox(height: _kSectionGap),
            _buildExecVerifButton(),
          ],

          const SizedBox(height: _kSectionGap),

          // Browse & Manage
          _SectionLabel(text: _t('telusur')),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.location_on,
            iconColor: Colors.lightBlue,
            iconBg: Colors.blue.withValues(alpha:0.1),
            label: _t('lokasi'),
            onTap: () => _push(LocationScreen(
              lang: widget.lang,
              isProMode: widget.isProMode,
              userRole: widget.userRole,
              userUnitId: widget.userUnitId,
              userLokasiId: widget.userLokasiId,
            )),
          ),
          const SizedBox(height: 12),
          _buildNavTile(
            icon: Icons.factory_outlined,
            iconColor: Colors.lightBlue,
            iconBg: Colors.blue.withValues(alpha:0.1),
            label: _t('kts_produksi'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KtsProduksiListScreen(lang: widget.lang)),
              );
              _latestActivityKey.currentState?.refreshFindingsQuietly();
              widget.onRefresh();
            },
          ),
          const SizedBox(height: 12),
          _buildNavTile(
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            iconBg: Colors.red.withValues(alpha:0.1),
            label: _t('laporan'),
            onTap: () => _push(AccidentReportListScreen(lang: widget.lang)),
          ),

          if (widget.isPreventiveMaintenanceVisible) ...[
            const SizedBox(height: 12),
            _buildPreventiveMaintenanceButton(),
          ],

          const SizedBox(height: 25),

          // Recent Findings (Latest Activity) — dipindah ke home_latest_activity.dart
          HomeLatestActivity(
            key: _latestActivityKey,
            lang: widget.lang,
            onRequestRefresh: widget.onRequestRefresh,
            onRefresh: widget.onRefresh,
            shouldRefreshFindings: widget.shouldRefreshFindings,
            onRefreshDone: widget.onRefreshDone,
          ),
        ],
      ),
    );
  }

  // Navigator Helper with Slide Transition
  void _push(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        maintainState: true,
      ),
    );
  }

  // Choose Mode Button
  Widget _buildChooseModeButton() {
    final anyActive = widget.isProMode || widget.isVisitorMode;
    return GestureDetector(
      onTap: () => showChooseModeSheet(
        context: context,
        isProMode: widget.isProMode,
        isVisitorMode: widget.isVisitorMode,
        lang: widget.lang,
        onProModeChanged: widget.onProModeChanged,
        onVisitorModeChanged: widget.onVisitorModeChanged,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: anyActive
              ? const LinearGradient(
                  colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                )
              : null,
          color: anyActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: anyActive ? Colors.transparent : const Color(0xFF00C9E4).withValues(alpha:0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9E4).withValues(alpha:anyActive ? 0.25 : 0.08),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: anyActive ? Colors.white.withValues(alpha:0.2) : const Color(0xFF00C9E4).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded, size: 20, color: anyActive ? Colors.white : const Color(0xFF00C9E4)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('choose_mode'),
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: anyActive ? Colors.white : const Color(0xFF1E3A8A),
                    ),
                  ),
                  if (anyActive) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (widget.isProMode) _ModeBadge(label: _modeBadgeLabel('pro'), color: const Color(0xFF4ADE80)),
                        if (widget.isProMode && widget.isVisitorMode) const SizedBox(width: 6),
                        if (widget.isVisitorMode) _ModeBadge(label: _modeBadgeLabel('visitor'), color: const Color(0xFFFBBF24)),
                      ],
                    ),
                  ] else
                    Text(
                      widget.lang == 'ZH' ? '点击以自定义模式'
                          : widget.lang == 'ID' ? 'Ketuk untuk atur mode'
                          : 'Tap to customize mode',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: anyActive ? Colors.white70 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _modeBadgeLabel(String type) {
    if (type == 'pro') return 'Pro';
    return widget.lang == 'ZH' ? '访客' : widget.lang == 'ID' ? 'Pengunjung' : 'Visitor';
  }

  // Pending Audit Section
  Widget _buildPendingAuditSection() {
    // ✅ BARU: sembunyikan jika tidak berada di PT ATMI Solo
    if (!widget.isAtAtmi) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pendingAuditsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: _kSectionGap),
            _SectionLabel(text: _t('audit_tasks')),
            const SizedBox(height: 10),
            for (int i = 0; i < tasks.length; i++) ...[
              _buildAuditTaskCard(tasks[i]),
              if (i != tasks.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAuditTaskCard(Map<String, dynamic> task) {
    const teal = Color(0xFF14B8A6);
    final level = task['level_type'] as String;
    final locationName = task['location_name'] as String;
    final from = task['periode_mulai']?.toString() ?? '';
    final to = task['periode_selesai']?.toString() ?? '';

    final levelLabel = {
      'unit': 'Unit', 'subunit': 'Sub-Unit', 'area': 'Area',
    }[level] ?? (widget.lang == 'EN' ? 'Location' : 'Lokasi');

    return GestureDetector(
      onTap: () async {
        // Step 1: Selfie dulu
        final selfieUrl = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => AuditSelfieScreen(
              lang: widget.lang,
              locationName: locationName,
              levelType: level,
              idRef: task['id_ref'].toString(),
            ),
          ),
        );
        // Jika user cancel selfie, batalkan navigasi ke form
        if (selfieUrl == null || !mounted) return;

        // Step 2: Buka form audit dengan selfieUrl
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuditFormScreen(
              lang: widget.lang,
              levelType: level,
              idRef: task['id_ref'].toString(),
              locationName: locationName,
              idSchedule: task['id_schedule'].toString(),
              selfieUrl: selfieUrl,
              idJenisAudit: task['id_jenis_audit']?.toString(),
            ),
          ),
        );
        if (mounted) {
          setState(() {
            _pendingAuditsFuture = _fetchPendingAudits();
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: teal.withValues(alpha:0.30), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.fact_check_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locationName,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  // ✅ BARU: Badge jenis audit
                  if (task['jenis_audit_label'] != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task['jenis_audit_label'].toString(),
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text('$levelLabel  •  $from → $to',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // Executive Verification Button
  Widget _buildExecVerifButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => VerificationIntroScreen(
            lang: widget.lang,
            userJabatanId: widget.userJabatanId,
            onPointEarned: widget.onVerifPointEarned,
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF0891B2)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha:0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.18), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.verified_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('verifikasi'),
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(_t('verifikasi_sub'),
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // Preventive Maintenance Button
  Widget _buildPreventiveMaintenanceButton() {
    const Color pmColor = Color(0xFF1D4ED8);
    return GestureDetector(
      onTap: () => _push(PreventifMaintenanceScreen(lang: widget.lang)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: pmColor.withValues(alpha:0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.build_circle_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('preventive_maintenance'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _t('preventive_maintenance_sub'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  // Nav Tile
  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 140,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

// Reusable Section Label
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black54),
    );
  }
}

// Mode Badge
class _ModeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ModeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha:0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}