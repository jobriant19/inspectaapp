import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'point/admin_poin_screen.dart';
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

  static const _kYellow = Color(0xFFD4A50A);

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kYellow),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _label(
            'Poin & Target 5R',
            'Points & 5R Target',
            '积分与5R目标',
          ),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _kYellow,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Column(
            children: [
              Container(color: Colors.grey.shade200, height: 1),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: _kYellow,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: _kYellow.withValues(alpha:0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.zero,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    dividerColor: Colors.transparent,
                    overlayColor:
                        WidgetStateProperty.all(Colors.transparent),
                    tabs: [
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, size: 16),
                            const SizedBox(width: 7),
                            Text(_label('Poin', 'Points', '积分')),
                          ],
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.track_changes_rounded,
                                size: 16),
                            const SizedBox(width: 7),
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
          _PoinTab(lang: widget.lang),
          _Target5rTab(lang: widget.lang),
        ],
      ),
    );
  }
}

class _PoinTab extends StatelessWidget {
  final String lang;
  const _PoinTab({required this.lang});

  @override
  Widget build(BuildContext context) {
    return AdminPoinScreen(lang: lang);
  }
}

class _Target5rTab extends StatelessWidget {
  final String lang;
  const _Target5rTab({required this.lang});

  @override
  Widget build(BuildContext context) {
    return AdminTarget5rScreen(lang: lang);
  }
}