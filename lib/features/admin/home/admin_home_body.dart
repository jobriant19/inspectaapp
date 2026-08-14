import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_home_button_access.dart';
import 'admin_home_info_card.dart';
import 'admin_home_management_menu.dart';

class AdminHomeBody extends StatefulWidget {
  final String lang;
  final String? initialUserName;
  final String? initialUserImage;
  final int? initialTotalUsers;
  final int? initialTotalLokasi;
  final int? initialTotalKategori;
  final int? initialTotalTemuan;
  final int? initialTotalUnit;
  final int? initialTotalSubunit;
  final int? initialTotalArea;

  const AdminHomeBody({
    super.key,
    required this.lang,
    this.initialUserName,
    this.initialUserImage,
    this.initialTotalUsers,
    this.initialTotalLokasi,
    this.initialTotalKategori,
    this.initialTotalTemuan,
    this.initialTotalUnit,
    this.initialTotalSubunit,
    this.initialTotalArea,
  });

  @override
  State<AdminHomeBody> createState() => _AdminHomeBodyState();
}

class _AdminHomeBodyState extends State<AdminHomeBody> {
  String _adminName = 'Admin';
  String _adminJabatan = 'Admin';
  bool _isLoadingStats = true;

  int _totalUsers = 0;
  int _totalLokasi = 0;
  int _totalUnit = 0;
  int _totalSubunit = 0;
  int _totalArea = 0;
  int _totalKategori = 0;
  int _totalTemuan = 0;

  @override
  void initState() {
    super.initState();
    _adminName = widget.initialUserName ?? 'Admin';

    if (widget.initialTotalUsers != null) {
      _totalUsers    = widget.initialTotalUsers!;
      _totalLokasi   = widget.initialTotalLokasi ?? 0;
      _totalKategori = widget.initialTotalKategori ?? 0;
      _totalTemuan   = widget.initialTotalTemuan ?? 0;
      _totalUnit     = widget.initialTotalUnit ?? 0;
      _totalSubunit  = widget.initialTotalSubunit ?? 0;
      _totalArea     = widget.initialTotalArea ?? 0;
      _isLoadingStats = false;
    }

    GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
    ]).catchError((_) => <void>[]);

    _fetchStats();
    _loadAdminInfo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/bgadmin.png'), context)
          .catchError((_) {});
    });
  }

  @override
  void didUpdateWidget(covariant AdminHomeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUserName != null &&
        widget.initialUserName != oldWidget.initialUserName) {
      setState(() => _adminName = widget.initialUserName!);
    }
  }

  Future<void> _fetchStats({bool showLoading = false}) async {
    if (showLoading) setState(() => _isLoadingStats = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client.from('User').count(),
        Supabase.instance.client.from('lokasi').count(),
        Supabase.instance.client.from('kategoritemuan').count(),
        Supabase.instance.client.from('temuan').count(),
        Supabase.instance.client.from('unit').count(),
        Supabase.instance.client.from('subunit').count(),
        Supabase.instance.client.from('area').count(),
      ]);
      if (mounted) {
        setState(() {
          _totalUsers    = results[0];
          _totalLokasi   = results[1];
          _totalKategori = results[2];
          _totalTemuan   = results[3];
          _totalUnit     = results[4];
          _totalSubunit  = results[5];
          _totalArea     = results[6];
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadAdminInfo() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final row = await Supabase.instance.client
          .from('User')
          .select('nama, gambar_user, jabatan!User_id_jabatan_fkey(nama_jabatan)')
          .eq('id_user', userId)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() {
          _adminName = row['nama'] ?? _adminName;
          _adminJabatan = row['jabatan']?['nama_jabatan'] ?? 'Admin';
        });
      }
    } catch (e) {
      debugPrint('Error loading admin info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return RefreshIndicator(
      onRefresh: () => _fetchStats(showLoading: false),
      color: const Color(0xFF059669),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 90 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminHomeInfoCard(
              adminName: _adminName,
              adminJabatan: _adminJabatan,
              lang: lang,
              isLoadingStats: _isLoadingStats,
              totalUsers: _totalUsers,
              totalLokasi: _totalLokasi,
              totalUnit: _totalUnit,
              totalSubunit: _totalSubunit,
              totalArea: _totalArea,
              totalKategori: _totalKategori,
              totalTemuan: _totalTemuan,
            ),
            const SizedBox(height: 16),
            AdminHomeButtonAccess(lang: lang),
            const SizedBox(height: 24),
            _buildSectionLabel(
              lang == 'EN'
                  ? 'Management Menu'
                  : lang == 'ZH'
                      ? '管理菜单'
                      : 'Menu Manajemen',
            ),
            const SizedBox(height: 14),
            AdminHomeManagementMenu(
              lang: lang,
              onRefreshStats: () => _fetchStats(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF34D399)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 29, 199, 97),
          ),
        ),
      ],
    );
  }
}