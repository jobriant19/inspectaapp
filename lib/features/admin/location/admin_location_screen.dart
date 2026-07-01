import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_area_tab.dart';
import 'admin_location_tab.dart';
import 'admin_section_tab.dart';
import 'admin_subunit_tab.dart';
import 'admin_unit_tab.dart';

class AdminLocationScreen extends StatefulWidget {
  final String lang;
  const AdminLocationScreen({super.key, required this.lang});

  @override
  State<AdminLocationScreen> createState() => _AdminLocationScreenState();
}

class _AdminLocationScreenState extends State<AdminLocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _primary = Color(0xFF10B981);
  static const _bg = Color(0xFFF8FAFC);

  final List<IconData> _tabIcons = [
    Icons.location_city_rounded,
    Icons.business_rounded,
    Icons.layers_rounded,
    Icons.place_rounded,
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

  String get _lang => widget.lang;

  @override
  Widget build(BuildContext context) {
    final tabLabels = _lang == 'EN'
        ? ['Location', 'Unit', 'Sub-Unit', 'Area']
        : _lang == 'ZH'
            ? ['位置', '单位', '子单位', '区域']
            : ['Lokasi', 'Unit', 'Sub-Unit', 'Area'];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        shadowColor: Colors.black.withValues(alpha:0.08),
        title: Text(
          _lang == 'EN' ? 'Location Management' : _lang == 'ZH' ? '位置管理' : 'Kelola Lokasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: _primary),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: Colors.black38,
          indicatorWeight: 3,
          isScrollable: true, 
          tabAlignment: TabAlignment.start,
          tabs: List.generate(
            4,
            (i) => Tab(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tabIcons[i], size: 15),
                    const SizedBox(width: 5),
                    Text(
                      tabLabels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => AdminSectionTab(lang: _lang),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.dashboard_customize_rounded, color: _primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _lang == 'EN' ? 'Section Settings' : _lang == 'ZH' ? '部门设置' : 'Pengaturan Section',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A)),
                          ),
                          Text(
                            _lang == 'EN'
                                ? 'Manage Laser, Mesin, Assy, and other sections'
                                : _lang == 'ZH'
                                    ? '管理激光、机械、组装等部门'
                                    : 'Kelola Laser, Mesin, Assy, dan section lainnya',
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.black38),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 13),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                AdminLocationTab(lang: _lang),
                AdminUnitTab(lang: _lang),
                AdminSubunitTab(lang: _lang),
                AdminAreaTab(lang: _lang),
              ],
            ),
          ),
        ],
      ),
    );
  }
}