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
  final List<Map<String, dynamic>>? initialPendingAudits;

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
    this.initialPendingAudits,
  });

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  static const double _kSectionGap = 20;
  Future<List<Map<String, dynamic>>>? _pendingAuditsFuture;
  List<Map<String, dynamic>>? _pendingAuditsSync;
  final GlobalKey<HomeLatestActivityState> _latestActivityKey =
      GlobalKey<HomeLatestActivityState>();
  bool _isChooseModeSheetOpen = false;

  static const Map<String, Map<String, String>> _texts = {
    'EN': {
      'inspeksi': 'Inspection',
      'choose_mode': 'Choose Mode',
      'telusur': 'Browse & Manage',
      'lokasi': 'Specific Location',
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
      'lokasi': 'Lokasi Spesifik',
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
      'lokasi': '特定地点',
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
    if (widget.initialPendingAudits != null) {
      _pendingAuditsSync = widget.initialPendingAudits;
      _pendingAuditsFuture = Future.value(widget.initialPendingAudits);
    } else {
      _pendingAuditsFuture = _fetchPendingAudits();
    }
  }

  void refreshFindings() {
    _latestActivityKey.currentState?.refreshFindings();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingAudits() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final rows = await _sb
          .from('audit_schedule')
          .select(
              'id_schedule, level_type, id_ref, periode_mulai, periode_selesai, status, '
              'id_jenis_audit, JenisAudit:jenis_audit(nama_id, nama_en, nama_zh)')
          .eq('id_auditor', userId)
          .inFilter('status', ['pending', 'in_progress'])
          .lte('periode_mulai', today)
          .gte('periode_selesai', today);

      if (rows.isEmpty) return [];

      final byLevel = <String, List<String>>{};
      for (final r in rows) {
        final level = r['level_type'] as String;
        byLevel.putIfAbsent(level, () => []).add(r['id_ref'].toString());
      }

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
          'jenis_audit_label': jenisLabel,
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INFO CARD
          widget.isUserDataLoading ? _buildInfoCardSkeleton() : widget.buildInfoCard(),
          const SizedBox(height: _kSectionGap),

          _buildChooseModeButton(),

          if (widget.isExecVerificator) ...[
            const SizedBox(height: _kSectionGap),
            _buildExecVerifButton(),
          ],

          _buildPendingAuditSection(),

          if (widget.isPreventiveMaintenanceVisible) ...[
            const SizedBox(height: _kSectionGap),
            _buildPreventiveMaintenanceButton(),
          ],

          const SizedBox(height: _kSectionGap),

          // BROWSE & MANAGE
          _SectionLabel(text: _t('telusur')),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.map,
            iconColor: Colors.green,
            iconBg: Colors.green.withValues(alpha:0.1),
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

          const SizedBox(height: 25),

          // LATEST ACTIVITY
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

  Widget _buildChooseModeButton() {
    final anyActive = widget.isProMode || widget.isVisitorMode;
    return GestureDetector(
      onTap: () async {
        if (_isChooseModeSheetOpen) return;
        _isChooseModeSheetOpen = true;
        await showChooseModeSheet(
          context: context,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
          lang: widget.lang,
          onProModeChanged: widget.onProModeChanged,
          onVisitorModeChanged: widget.onVisitorModeChanged,
        );
        _isChooseModeSheetOpen = false;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1D72F3).withValues(alpha:0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9E4).withValues(alpha:0.08),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C9E4), Color(0xFF1D72F3)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
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
                      color: const Color(0xFF1D72F3),
                    ),
                  ),
                  if (anyActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (widget.isProMode) ...[
                            _buildActiveModeBadge(
                              icon: Icons.workspace_premium_rounded,
                              label: _modeBadgeLabel('pro'),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                              ),
                            ),
                            if (widget.isVisitorMode) const SizedBox(width: 6),
                          ],
                          if (widget.isVisitorMode)
                            _buildActiveModeBadge(
                              icon: Icons.visibility_rounded,
                              label: _modeBadgeLabel('visitor'),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Text(
                      widget.lang == 'ZH' ? '点击以自定义模式'
                          : widget.lang == 'ID' ? 'Ketuk untuk atur mode'
                          : 'Tap to customize mode',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.black),
          ],
        ),
      ),
    );
  }

  String _modeBadgeLabel(String type) {
    if (type == 'pro') return 'Pro';
    return widget.lang == 'ZH' ? '访客' : widget.lang == 'ID' ? 'Pengunjung' : 'Visitor';
  }

  Widget _buildActiveModeBadge({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAuditSection() {
    if (!widget.isAtAtmi) return const SizedBox.shrink();

    if (_pendingAuditsSync != null) {
      final tasks = _pendingAuditsSync!;
      if (tasks.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: _kSectionGap),
          for (int i = 0; i < tasks.length; i++) ...[
            _buildAuditTaskCard(tasks[i]),
            if (i != tasks.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

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
            for (int i = 0; i < tasks.length; i++) ...[
              _buildAuditTaskCard(tasks[i]),
              if (i != tasks.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const Map<String, IconData> _auditLevelIcons = {
    'lokasi': Icons.location_city_rounded,
    'unit': Icons.business_rounded,
    'subunit': Icons.layers_rounded,
    'area': Icons.place_rounded,
  };

  String _formatAuditPeriod(String fromRaw, String toRaw) {
    try {
      final fParts = fromRaw.split('-');
      final tParts = toRaw.split('-');
      if (fParts.length != 3 || tParts.length != 3) return '$fromRaw - $toRaw';

      final fYear = fParts[0];
      final fMonth = int.parse(fParts[1]);
      final fDay = int.parse(fParts[2]);
      final tYear = tParts[0];
      final tMonth = int.parse(tParts[1]);
      final tDay = int.parse(tParts[2]);

      final fMonthLabel = (fMonth >= 1 && fMonth <= 12) ? _monthAbbr[fMonth - 1] : fParts[1];
      final tMonthLabel = (tMonth >= 1 && tMonth <= 12) ? _monthAbbr[tMonth - 1] : tParts[1];

      if (fYear == tYear && fMonth == tMonth) {
        return '$fDay - $tDay $tMonthLabel $tYear';
      } else if (fYear == tYear) {
        return '$fDay $fMonthLabel - $tDay $tMonthLabel $tYear';
      } else {
        return '$fDay $fMonthLabel $fYear - $tDay $tMonthLabel $tYear';
      }
    } catch (_) {
      return '$fromRaw - $toRaw';
    }
  }

  Widget _buildAuditTaskCard(Map<String, dynamic> task) {
    const auditColor = Color(0xFF14B8A6);
    final level = task['level_type'] as String;
    final locationName = task['location_name'] as String;
    final period = _formatAuditPeriod(
      task['periode_mulai']?.toString() ?? '',
      task['periode_selesai']?.toString() ?? '',
    );

    final levelLabel = {
      'lokasi': widget.lang == 'EN' ? 'Location' : 'Lokasi',
      'unit': 'Unit', 'subunit': 'Sub-Unit', 'area': 'Area',
    }[level] ?? (widget.lang == 'EN' ? 'Location' : 'Lokasi');

    final levelIcon = _auditLevelIcons[level] ?? Icons.place_rounded;
    return GestureDetector(
      onTap: () async {
        // AUDIT SELFIE
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
        if (selfieUrl == null || !mounted) return;

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
            _pendingAuditsSync = null;
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
          boxShadow: [BoxShadow(color: auditColor.withValues(alpha:0.30), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      locationName,
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (task['jenis_audit_label'] != null)
                        _buildAuditChip(
                          icon: Icons.assignment_rounded,
                          label: task['jenis_audit_label'].toString(),
                        ),
                      _buildAuditChip(
                        icon: levelIcon,
                        label: levelLabel,
                      ),
                      _buildAuditChip(
                        icon: Icons.calendar_month_rounded,
                        label: period,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

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
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha:0.30), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.20), borderRadius: BorderRadius.circular(10)),
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
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha:0.92))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildPreventiveMaintenanceButton() {
    const Color pmColor = Color(0xFF2563EB);
    return GestureDetector(
      onTap: () => _push(PreventifMaintenanceScreen(lang: widget.lang)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: pmColor.withValues(alpha:0.30),
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
                color: Colors.white.withValues(alpha:0.20),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha:0.92),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

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
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black54),
    );
  }
}