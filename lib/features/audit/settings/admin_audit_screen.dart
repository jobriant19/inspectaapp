import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../schedule/audit_schedule_screen.dart';
import '../question/audit_question_manager_screen.dart';
import 'audit_area_screen.dart';
import 'audit_location_screen.dart';
import 'audit_subunit_screen.dart';
import 'audit_unit_screen.dart';

class _AC {
  static const primary  = Color(0xFF8B5CF6);
  static const green    = Color(0xFF10B981);
  static const surface  = Color(0xFFF8FAFC);
}

class AdminAuditScreen extends StatefulWidget {
  final String lang;
  const AdminAuditScreen({super.key, required this.lang});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  List<String> get _tabLabels => [
    _t('Location', 'Lokasi', '位置'),
    _t('Unit', 'Unit', '单元'),
    _t('Sub-Unit', 'Sub-Unit', '子单元'),
    _t('Area', 'Area', '区域'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openQuestionManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuditQuestionManagerScreen(lang: widget.lang),
      ),
    );
  }

  void _openScheduleManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuditScheduleScreen(lang: widget.lang),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AC.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _AC.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Audit Settings', 'Audit Settings', '审计设置'),
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700, color: _AC.primary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: _t('Questions', 'Pertanyaan', '问题'),
                        subtitle: _t('Manage by audit type', 'Kelola per jenis audit', '按审计类型管理'),
                        icon: Icons.help_outline_rounded,
                        colors: [_AC.primary, _AC.primary.withValues(alpha: 0.78)],
                        onTap: _openQuestionManager,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: _t('Schedule', 'Jadwal Audit', '审计计划'),
                        subtitle: _t('Assign auditors', 'Atur penjadwalan', '分配审计员'),
                        icon: Icons.event_note_rounded,
                        colors: [_AC.green, _AC.green.withValues(alpha: 0.78)],
                        onTap: _openScheduleManager,
                      ),
                    ),
                  ],
                ),
              ),
              // TAB BAR
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: _AC.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      color: _AC.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: _AC.primary,
                    labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 11.5),
                    unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 11.5),
                    dividerColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: _tabLabels.map((l) => Tab(child: Text(l))).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          AuditLocationScreen(lang: widget.lang),
          AuditUnitScreen(lang: widget.lang),
          AuditSubunitScreen(lang: widget.lang),
          AuditAreaScreen(lang: widget.lang),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
                color: colors[0].withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 9, color: Colors.white.withValues(alpha: 0.82)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}