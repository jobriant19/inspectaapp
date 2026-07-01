import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_area_tab.dart';
import 'admin_location_tab.dart';
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
          tabAlignment: TabAlignment.start, // ← rata kiri saat scrollable
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
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          AdminLocationTab(lang: _lang),
          AdminUnitTab(lang: _lang),
          AdminSubunitTab(lang: _lang),
          AdminAreaTab(lang: _lang),
        ],
      ),
    );
  }
}