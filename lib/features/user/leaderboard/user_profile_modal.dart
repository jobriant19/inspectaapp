import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/jabatan_helper.dart';
import '../finding/detail/finding_detail_screen.dart';
import '../home/card/finding_card.dart';
import '../home/card/kts_finding_card.dart';
import '../ktsproduksi/kts_detail_screen.dart';

const Color _primary     = Color(0xFF0EA5E9);
const Color _secondary   = Color(0xFF64748B);
const Color _surface     = Color(0xFFF0F9FF);

class UserProfileModal extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int userRank;
  final String lang; 

  const UserProfileModal({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.userRank,
    required this.lang,
  });

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentLang;

  // ── HEADER STATE ──
  bool _isHeaderLoading = true;
  String _userNameResolved = '';
  String? _userAvatarUrlResolved;
  String _userJabatan = '';
  int? _userJabatanId;
  bool _isVerificatorUser = false;
  bool _isVisitor = false;
  String _userLokasiSpesifik = '-';
  String? _userLokasiLevel;

  // ── ACTIVITY TAB STATE ──
  bool _isActivityLoading = true;
  List<Map<String, dynamic>> _activityLogs = [];
  int _activityPage = 1;

  // ── TEMUAN (RAW DATA) STATE ──
  bool _isTemuanLoading = true;
  List<Map<String, dynamic>> _temuanList = [];

  // ── PENYELESAIAN (RAW DATA) STATE ──
  bool _isPenyelesaianLoading = true;
  List<Map<String, dynamic>> _penyelesaianList = [];

  // ── TAB 5R FINDING STATE ──
  int _fiveRPage = 1;

  // ── TAB KTS PRODUCTION STATE ──
  int _ktsPage = 1;

  static const int _perPage = 7; // 7 kartu per halaman (semua tab)

  static const Map<String, Color> _levelColors = {
    'lokasi': Color(0xFF10B981),
    'unit': Color(0xFF6366F1),
    'subunit': Color(0xFFFBBF24),
    'area': Color(0xFFF472B6),
  };

  Color get _locationColor =>
      _levelColors[_userLokasiLevel?.toLowerCase()] ?? const Color(0xFFF472B6);

  final Map<String, Map<String, String>> _txt = {
    'ID': {
      'tab_activity': 'Log Aktivitas',
      'tab_5r': '5R Finding',
      'tab_kts': 'KTS Production',
      'total_poin': 'TOTAL POIN',
      'points_earned': 'poin terkumpul',
      'empty_activity': 'Belum ada aktivitas',
      'empty_5r': 'Belum ada temuan 5R',
      'empty_kts': 'Belum ada temuan KTS Production',
      'empty_subtitle': 'Semua temuan akan muncul di sini setelah dilaporkan atau diselesaikan.',
      'log': 'log',
      'visitor': 'Pengunjung',
      'verifier_role': 'Verifier',
    },
    'EN': {
      'tab_activity': 'Activity Log',
      'tab_5r': '5R Finding',
      'tab_kts': 'KTS Production',
      'total_poin': 'TOTAL POINTS',
      'points_earned': 'points earned',
      'empty_activity': 'No activity yet',
      'empty_5r': 'No 5R findings yet',
      'empty_kts': 'No KTS Production findings yet',
      'empty_subtitle': 'All findings will appear here once reported or resolved.',
      'log': 'log',
      'visitor': 'Visitor',
      'verifier_role': 'Verifier',
    },
    'ZH': {
      'tab_activity': '活动记录',
      'tab_5r': '5R发现',
      'tab_kts': 'KTS生产',
      'total_poin': '总积分',
      'points_earned': '积分',
      'empty_activity': '暂无活动',
      'empty_5r': '暂无5R发现',
      'empty_kts': '暂无KTS生产发现',
      'empty_subtitle': '报告或解决后，所有发现都会显示在这里。',
      'log': '记录',
      'visitor': '访客',
      'verifier_role': '验证者',
    },
  };

  String _t(String key) =>
      _txt[_currentLang]?[key] ?? _txt['ID']?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _tabController = TabController(length: 3, vsync: this);

    _userNameResolved = widget.userName;
    _userAvatarUrlResolved = widget.userAvatarUrl;

    _fetchHeaderData();
    _fetchActivityLogs();
    _fetchTemuan();
    _fetchPenyelesaian();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String?>> _resolveLocation({
    required dynamic idLokasi,
    required dynamic idUnit,
    required dynamic idSubunit,
    required dynamic idArea,
  }) async {
    final client = Supabase.instance.client;
    try {
      if (idArea != null) {
        final data = await client
            .from('area')
            .select('nama_area')
            .eq('id_area', idArea)
            .maybeSingle();
        return {'name': data?['nama_area'] as String?, 'level': 'area'};
      } else if (idSubunit != null) {
        final data = await client
            .from('subunit')
            .select('nama_subunit')
            .eq('id_subunit', idSubunit)
            .maybeSingle();
        return {'name': data?['nama_subunit'] as String?, 'level': 'subunit'};
      } else if (idUnit != null) {
        final data = await client
            .from('unit')
            .select('nama_unit')
            .eq('id_unit', idUnit)
            .maybeSingle();
        return {'name': data?['nama_unit'] as String?, 'level': 'unit'};
      } else if (idLokasi != null) {
        final data = await client
            .from('lokasi')
            .select('nama_lokasi')
            .eq('id_lokasi', idLokasi)
            .maybeSingle();
        return {'name': data?['nama_lokasi'] as String?, 'level': 'lokasi'};
      }
    } catch (e) {
      debugPrint('Error resolving location: $e');
    }
    return {'name': null, 'level': null};
  }

  Future<void> _fetchHeaderData() async {
    try {
      final row = await Supabase.instance.client
          .from('User')
          .select(
              'nama, gambar_user, id_jabatan, is_visitor, is_verificator, '
              'id_lokasi, id_unit, id_subunit, id_area, jabatan(nama_jabatan)')
          .eq('id_user', widget.userId)
          .maybeSingle();

      if (row == null) {
        if (mounted) setState(() => _isHeaderLoading = false);
        return;
      }

      final isVisitor = row['is_visitor'] as bool? ?? false;
      final isVerificator = row['is_verificator'] as bool? ?? false;
      final idJabatan = row['id_jabatan'] as int?;

      final loc = await _resolveLocation(
        idLokasi: row['id_lokasi'],
        idUnit: row['id_unit'],
        idSubunit: row['id_subunit'],
        idArea: row['id_area'],
      );

      String jabatanName;
      if (isVisitor) {
        jabatanName = _t('visitor');
      } else if (isVerificator) {
        jabatanName = _t('verifier_role');
      } else {
        jabatanName = row['jabatan']?['nama_jabatan'] ?? 'Staff';
      }

      String? dbImage = row['gambar_user'] as String?;
      if (dbImage != null && dbImage.trim().isEmpty) dbImage = null;

      if (mounted) {
        setState(() {
          _userNameResolved = (row['nama'] as String?) ?? widget.userName;
          _userAvatarUrlResolved = dbImage ?? widget.userAvatarUrl;
          _userJabatan = jabatanName;
          _userJabatanId = idJabatan;
          _isVerificatorUser = isVerificator;
          _isVisitor = isVisitor;
          _userLokasiSpesifik = loc['name'] ?? '-';
          _userLokasiLevel = loc['level'];
          _isHeaderLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching header data: $e');
      if (mounted) setState(() => _isHeaderLoading = false);
    }
  }

  Future<void> _fetchActivityLogs() async {
    try {
      final logs = await Supabase.instance.client
          .from('log_poin')
          .select('poin, deskripsi, tipe_aktivitas, created_at')
          .eq('id_user', widget.userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _activityLogs = List<Map<String, dynamic>>.from(logs);
          _isActivityLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
      if (mounted) setState(() => _isActivityLoading = false);
    }
  }

  Future<void> _fetchTemuan() async {
    try {
      final data = await Supabase.instance.client
          .from('temuan')
          .select('''
            id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, poin_temuan, status_temuan,
            created_at, jenis_temuan, no_order, jumlah_item, nama_item_manual,
            is_pro, is_visitor, is_eksekutif, target_waktu_selesai,
            id_user, id_penyelesaian, id_penanggung_jawab,
            item_produksi:id_item(id_item, nama_item, gambar_item, kode_item),
            area(nama_area), subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi),
            kategoritemuan(nama_kategoritemuan),
            subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan),
            penanggung_jawab:id_penanggung_jawab(id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
            User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
            pelapor:id_user(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
            User_Creator:User!temuan_id_user_fkey(nama, gambar_user),
            penyelesaian!temuan_id_penyelesaian_fkey(
              id_penyelesaian, gambar_penyelesaian, catatan_penyelesaian, tanggal_selesai,
              poin_penyelesaian, additional_cost, id_user, penyebab, bagian,
              id_subkategoritemuan_penyebab,
              faktor_penyebab:id_subkategoritemuan_penyebab(id_subkategoritemuan, nama_subkategoritemuan),
              section:id_section(nama_section_id, nama_section_en, nama_section_zh),
              User_Solver:User!id_user(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan))
            )
          ''')
          .eq('id_user', widget.userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _temuanList = List<Map<String, dynamic>>.from(data);
          _isTemuanLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching temuan: $e');
      if (mounted) setState(() => _isTemuanLoading = false);
    }
  }

  Future<void> _fetchPenyelesaian() async {
    try {
      final data = await Supabase.instance.client
          .from('penyelesaian')
          .select('''
            id_penyelesaian, gambar_penyelesaian, catatan_penyelesaian, tanggal_selesai,
            poin_penyelesaian, additional_cost, id_user, penyebab, bagian,
            id_subkategoritemuan_penyebab,
            faktor_penyebab:id_subkategoritemuan_penyebab(id_subkategoritemuan, nama_subkategoritemuan),
            section:id_section(nama_section_id, nama_section_en, nama_section_zh),
            User_Solver:User!id_user(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
            temuan!inner(
              id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, jenis_temuan, no_order,
              jumlah_item, nama_item_manual, is_pro, is_visitor, is_eksekutif, target_waktu_selesai,
              id_user, id_penanggung_jawab,
              item_produksi:id_item(id_item, nama_item, gambar_item, kode_item),
              area(nama_area), subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi),
              kategoritemuan(nama_kategoritemuan),
              subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan),
              penanggung_jawab:id_penanggung_jawab(id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
              User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
              pelapor:id_user(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
              User_Creator:User!temuan_id_user_fkey(nama, gambar_user)
            )
          ''')
          .eq('id_user', widget.userId)
          .order('tanggal_selesai', ascending: false);
      if (mounted) {
        setState(() {
          _penyelesaianList = List<Map<String, dynamic>>.from(data);
          _isPenyelesaianLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching penyelesaian: $e');
      if (mounted) setState(() => _isPenyelesaianLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Detail',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: const Color(0xFF1D72F3),
          ),
        ),
      ),
      body: Column(
        children: [
          _isHeaderLoading ? _buildHeaderSkeleton() : _buildHeader(),

          // TAB BAR — 3 bahasa
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: _secondary,
              labelStyle:
                  GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(text: _t('tab_activity')),
                Tab(text: _t('tab_5r')),
                Tab(text: _t('tab_kts')),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityTab(),
                _build5RTab(),
                _buildKtsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _darken(Color color, [double amount = 0.16]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: _isVisitor ? _buildVisitorHeaderCard() : _buildProfileHeaderCard(),
    );
  }

  Widget _buildProfileHeaderCard() {
    final Color roleColor = JabatanHelper.getPrimaryColor(
      isVerificatorFlag: _isVerificatorUser,
      idJabatan: _userJabatanId,
    );
    final IconData roleIcon = JabatanHelper.getRoleIcon(
      isVerificatorFlag: _isVerificatorUser,
      idJabatan: _userJabatanId,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: JabatanHelper.getCardGradient(
            isVerificatorFlag: _isVerificatorUser,
            idJabatan: _userJabatanId,
          ),
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AVATAR
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF1D72F3),
              backgroundImage: _userAvatarUrlResolved != null
                  ? NetworkImage(_userAvatarUrlResolved!)
                  : null,
              child: _userAvatarUrlResolved == null
                  ? const Icon(Icons.person, color: Colors.white, size: 35)
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // NAME + ROLE BADGE + LOCATION BADGE (tanpa poin & rank)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _userNameResolved,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [roleColor, _darken(roleColor)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75), width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 11.5, color: Colors.white),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _userJabatan,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_locationColor, _darken(_locationColor)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: _locationColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _userLokasiSpesifik,
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.clip,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _userAvatarUrlResolved != null
                ? NetworkImage(_userAvatarUrlResolved!)
                : null,
            child: _userAvatarUrlResolved == null
                ? const Icon(Icons.person_outline, color: Color(0xFF1D72F3), size: 35)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userNameResolved,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D72F3),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _userJabatan,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 35, backgroundColor: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 18, width: 150, color: Colors.white),
                    const SizedBox(height: 10),
                    Container(height: 20, width: 90, color: Colors.white),
                    const SizedBox(height: 10),
                    Container(height: 22, width: 130, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getFireColor(int points) {
    if (points >= 1000) return const Color(0xFFEF4444);
    if (points >= 500) return const Color(0xFFF97316);
    if (points >= 100) return const Color(0xFF22C55E);
    if (points > 0) return const Color(0xFF3B82F6);
    return Colors.grey.shade400;
  }

  Color _getTipeColor(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':
        return const Color(0xFFEC4899);
      case 'login_harian':
        return const Color(0xFF3B82F6);
      case 'login_pertama_hari_ini':
        return const Color(0xFFF59E0B);
      case 'penalti':
        return const Color(0xFFEF4444);
      default:
        return isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    }
  }

  IconData _getTipeIcon(String tipe, bool isPositive) {
    switch (tipe) {
      case 'login_pertama':
        return Icons.celebration_rounded;
      case 'login_harian':
        return Icons.today_rounded;
      case 'login_pertama_hari_ini':
        return Icons.emoji_events_rounded;
      case 'penalti':
        return Icons.warning_amber_rounded;
      default:
        return isPositive ? Icons.star_rounded : Icons.remove_circle_outline_rounded;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return _currentLang == 'ZH' ? '刚刚' : (_currentLang == 'EN' ? 'Just now' : 'Baru saja');
    }
    if (diff.inHours < 1) {
      return _currentLang == 'ZH'
          ? '${diff.inMinutes}分钟前'
          : (_currentLang == 'EN' ? '${diff.inMinutes} min ago' : '${diff.inMinutes} menit lalu');
    }
    if (diff.inDays < 1) {
      return _currentLang == 'ZH'
          ? '${diff.inHours}小时前'
          : (_currentLang == 'EN' ? '${diff.inHours} hr ago' : '${diff.inHours} jam lalu');
    }
    if (diff.inDays < 7) {
      return _currentLang == 'ZH'
          ? '${diff.inDays}天前'
          : (_currentLang == 'EN' ? '${diff.inDays} days ago' : '${diff.inDays} hari lalu');
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  int _recencyLevel(dynamic value) {
    if (value == null) return 3;
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return 3;
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return 0;
    if (diff.inDays < 1) return 1;
    if (diff.inDays < 7) return 2;
    return 3;
  }

  Widget _buildActivityTab() {
    if (_isActivityLoading) return _buildActivitySkeleton();

    final totalPoin = _activityLogs.fold<int>(
        0, (sum, l) => sum + ((l['poin'] as num?)?.toInt() ?? 0));
    final fireColor = _getFireColor(totalPoin);

    final totalPages =
        _activityLogs.isEmpty ? 1 : (_activityLogs.length / _perPage).ceil();
    final safePage = _activityPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > _activityLogs.length
        ? _activityLogs.length
        : startIdx + _perPage;
    final pagedLogs = _activityLogs.isEmpty
        ? <Map<String, dynamic>>[]
        : _activityLogs.sublist(startIdx, endIdx);

    return Column(
      children: [
        // SUMMARY CARD — sama persis seperti activity_log_tab.dart
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.22),
                border: Border.all(color: fireColor.withValues(alpha: 0.7), width: 2),
              ),
              child: Icon(Icons.local_fire_department_rounded, color: fireColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('total_poin'),
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$totalPoin',
                    style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0),
                  ),
                  Text(
                    _t('points_earned'),
                    style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white.withValues(alpha: 0.22),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded,
                    color: Colors.white.withValues(alpha: 0.9), size: 18),
                const SizedBox(height: 4),
                Text(
                  '${_activityLogs.length}',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  _t('log'),
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ]),
        ),

        // LIST + INDIKATOR HALAMAN
        Expanded(
          child: _activityLogs.isEmpty
              ? _buildEmptyState(_t('empty_activity'), Icons.history_rounded)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: pagedLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildActivityLogCard(pagedLogs[i]),
                      ),
                    ),
                    _buildPageIndicatorBar(
                      currentPage: safePage,
                      totalPages: totalPages,
                      onPageChanged: (p) => setState(() => _activityPage = p),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActivityLogCard(Map<String, dynamic> log) {
    final int poin = (log['poin'] as num).toInt();
    final bool isPositive = poin >= 0;
    final String tipe = (log['tipe_aktivitas'] ?? '').toString();
    final String desc = (log['deskripsi'] ?? '').toString();
    final String tanggal = _formatDate(log['created_at']);
    final Color color = _getTipeColor(tipe, isPositive);
    final IconData icon = _getTipeIcon(tipe, isPositive);

    final int recency = _recencyLevel(log['created_at']);
    late final Color timeColor;
    late final IconData timeIcon;
    switch (recency) {
      case 0:
        timeColor = const Color(0xFF0EA5E9);
        timeIcon = Icons.bolt_rounded;
        break;
      case 1:
        timeColor = const Color(0xFF0D9488);
        timeIcon = Icons.access_time_filled_rounded;
        break;
      case 2:
        timeColor = const Color(0xFF64748B);
        timeIcon = Icons.schedule_rounded;
        break;
      default:
        timeColor = const Color(0xFF475569);
        timeIcon = Icons.event_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.4),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: timeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: timeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(timeIcon, size: 11, color: timeColor),
                    const SizedBox(width: 4),
                    Text(
                      tanggal,
                      style: GoogleFonts.poppins(
                          fontSize: 10.5, fontWeight: FontWeight.w700, color: timeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(
            isPositive ? '+$poin' : '$poin',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ]),
    );
  }

  Widget _buildActivitySkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            height: 96,
            decoration:
                BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 70,
                decoration:
                    BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _mergePenyelesaianAsTemuan(Map<String, dynamic> item) {
    final temuanRel = item['temuan'];
    Map<String, dynamic> temuanData = {};
    if (temuanRel is List && temuanRel.isNotEmpty) {
      temuanData = Map<String, dynamic>.from(temuanRel.first as Map);
    } else if (temuanRel is Map) {
      temuanData = Map<String, dynamic>.from(temuanRel);
    }

    return <String, dynamic>{
      ...temuanData,
      'id_temuan': temuanData['id_temuan'],
      'gambar_temuan': item['gambar_penyelesaian'] ?? temuanData['gambar_temuan'],
      'poin_temuan': item['poin_penyelesaian'] ?? 0,
      'created_at': item['tanggal_selesai'],
      'status_temuan': 'selesai',
      'penyelesaian': {
        'id_penyelesaian': item['id_penyelesaian'],
        'gambar_penyelesaian': item['gambar_penyelesaian'],
        'catatan_penyelesaian': item['catatan_penyelesaian'],
        'tanggal_selesai': item['tanggal_selesai'],
        'poin_penyelesaian': item['poin_penyelesaian'],
        'additional_cost': item['additional_cost'],
        'penyebab': item['penyebab'],
        'bagian': item['bagian'],
        'id_subkategoritemuan_penyebab': item['id_subkategoritemuan_penyebab'],
        'faktor_penyebab': item['faktor_penyebab'],
        'section': item['section'],
        'id_user': item['id_user'],
        'User_Solver': item['User_Solver'],
      },
    };
  }

  List<Map<String, dynamic>> get _combinedFindingList {
    final combined = <Map<String, dynamic>>[
      ..._temuanList,
      ..._penyelesaianList.map(_mergePenyelesaianAsTemuan),
    ];
    combined.sort((a, b) {
      final da = DateTime.tryParse((a['created_at'] ?? '').toString());
      final db = DateTime.tryParse((b['created_at'] ?? '').toString());
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return combined;
  }

  List<Map<String, dynamic>> get _fiveRFindingList => _combinedFindingList
      .where((e) => (e['jenis_temuan'] ?? '').toString() != 'KTS Production')
      .toList();

  List<Map<String, dynamic>> get _ktsFindingList {
    final list = _temuanList
        .where((e) => (e['jenis_temuan'] ?? '').toString() == 'KTS Production')
        .toList();
    list.sort((a, b) {
      final da = DateTime.tryParse((a['created_at'] ?? '').toString());
      final db = DateTime.tryParse((b['created_at'] ?? '').toString());
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return list;
  }

  void _openFindingDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FindingDetailScreen(
          initialData: item,
          lang: _currentLang,
        ),
      ),
    );
  }

  void _openKtsDetail(Map<String, dynamic> item) {
    final ktsId = item['id_temuan']?.toString();
    if (ktsId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KtsDetailScreen(
          ktsId: ktsId,
          lang: _currentLang,
          initialData: item,
        ),
      ),
    );
  }

  Widget _build5RTab() {
    if (_isTemuanLoading || _isPenyelesaianLoading) return _buildCardListSkeleton();

    final list = _fiveRFindingList;
    if (list.isEmpty) {
      return _buildEmptyState(_t('empty_5r'), Icons.search_off_rounded);
    }

    final totalPages = (list.length / _perPage).ceil();
    final safePage = _fiveRPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > list.length
        ? list.length
        : startIdx + _perPage;
    final paged = list.sublist(startIdx, endIdx);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            itemCount: paged.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = paged[i];
              return FindingCard(
                data: item,
                lang: _currentLang,
                onTap: () => _openFindingDetail(item),
              );
            },
          ),
        ),
        _buildPageIndicatorBar(
          currentPage: safePage,
          totalPages: totalPages,
          onPageChanged: (p) => setState(() => _fiveRPage = p),
        ),
      ],
    );
  }

  Widget _buildKtsTab() {
    if (_isTemuanLoading || _isPenyelesaianLoading) return _buildCardListSkeleton();

    final list = _ktsFindingList;
    if (list.isEmpty) {
      return _buildEmptyState(_t('empty_kts'), Icons.check_circle_outline_rounded);
    }

    final totalPages = (list.length / _perPage).ceil();
    final safePage = _ktsPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage) > list.length
        ? list.length
        : startIdx + _perPage;
    final paged = list.sublist(startIdx, endIdx);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            itemCount: paged.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = paged[i];
              return KtsFindingCard(
                data: item,
                lang: _currentLang,
                onTap: () => _openKtsDetail(item),
              );
            },
          ),
        ),
        _buildPageIndicatorBar(
          currentPage: safePage,
          totalPages: totalPages,
          onPageChanged: (p) => setState(() => _ktsPage = p),
        ),
      ],
    );
  }

  Widget _buildCardListSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 116,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/team_illustration.png',
                width: 180,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primary.withValues(alpha: 0.08),
                  ),
                  child: Icon(icon, size: 34, color: _primary.withValues(alpha: 0.45)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                _t('empty_subtitle'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, fontWeight: FontWeight.w500, color: _secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicatorBar({
    required int currentPage,
    required int totalPages,
    required ValueChanged<int> onPageChanged,
  }) {
    if (totalPages <= 1) return const SizedBox(height: 12);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 4, 16, MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      child: _ProfilePageIndicator(
        currentPage: currentPage,
        totalPages: totalPages,
        onPageChanged: onPageChanged,
        color: _primary,
      ),
    );
  }
}

class _ProfilePageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Color color;

  const _ProfilePageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.color,
  });

  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _arrowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: canPrev,
            onTap: () {
              if (!canPrev) return;
              onPageChanged(currentPage - 1);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (final p in pageNumbers) ...[
                  Expanded(child: _pageButton(p)),
                  if (p != pageNumbers.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _arrowButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: canNext,
            onTap: () {
              if (!canNext) return;
              onPageChanged(currentPage + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _pageButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
              color: isActive ? Colors.white : color, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.16) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}