import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_poin_screen.dart';
import 'admin_target_5r_screen.dart';

class AdminPoinTargetScreen extends StatefulWidget {
  final String lang;
  const AdminPoinTargetScreen({super.key, required this.lang});

  @override
  State<AdminPoinTargetScreen> createState() => _AdminPoinTargetScreenState();
}

class _AdminPoinTargetScreenState extends State<AdminPoinTargetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _kYellow = Color.fromARGB(255, 245, 233, 11);
  static const _kYellowDark = Color.fromARGB(255, 200, 180, 5);

  String _label(String id, String en, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _label(
            'Poin & Target 5R',
            'Points & 5R Target',
            '积分与5R目标',
          ),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _kYellow,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kYellow),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: Colors.black.withOpacity(0.06)),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kYellow, _kYellowDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _kYellow.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 12),
                    unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, fontSize: 12),
                    dividerColor: Colors.transparent,
                    overlayColor:
                        WidgetStateProperty.all(Colors.transparent),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, size: 14),
                            const SizedBox(width: 5),
                            Text(_label('Poin', 'Points', '积分')),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.track_changes_rounded,
                                size: 14),
                            const SizedBox(width: 5),
                            Text(_label(
                                'Target 5R', '5R Target', '5R目标')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Poin — embed AdminPoinScreen tanpa AppBar-nya
          _PoinTab(lang: widget.lang),
          // Tab 2: Target 5R — embed AdminTarget5rScreen tanpa AppBar-nya
          _Target5rTab(lang: widget.lang),
        ],
      ),
    );
  }
}

// ── Wrapper Tab Poin ──────────────────────────────────────────────────────────
class _PoinTab extends StatelessWidget {
  final String lang;
  const _PoinTab({required this.lang});

  @override
  Widget build(BuildContext context) {
    return AdminPoinScreen(lang: lang);
  }
}

// ── Wrapper Tab 5R Target ─────────────────────────────────────────────────────
class _Target5rTab extends StatelessWidget {
  final String lang;
  const _Target5rTab({required this.lang});

  @override
  Widget build(BuildContext context) {
    // AdminTarget5rScreen sudah tidak punya AppBar setelah dimodifikasi.
    return AdminTarget5rScreen(lang: lang);
  }
}