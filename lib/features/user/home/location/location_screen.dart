import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_detail_screen.dart';
import 'specific_location_indicator.dart';

class _LastActivity {
  final DateTime? lastTemuan;
  final DateTime? lastPenyelesaian;
  const _LastActivity({this.lastTemuan, this.lastPenyelesaian});
}

class _UserLastLocation {
  final String? lastTemuanLokasiId;
  final String? lastTemuanUnitId;
  final String? lastTemuanSubunitId;
  final String? lastTemuanAreaId;
  final String? lastSelesaiLokasiId;
  final String? lastSelesaiUnitId;
  final String? lastSelesaiSubunitId;
  final String? lastSelesaiAreaId;

  const _UserLastLocation({
    this.lastTemuanLokasiId,
    this.lastTemuanUnitId,
    this.lastTemuanSubunitId,
    this.lastTemuanAreaId,
    this.lastSelesaiLokasiId,
    this.lastSelesaiUnitId,
    this.lastSelesaiSubunitId,
    this.lastSelesaiAreaId,
  });

  bool isLastTemuan(String levelType, String levelId) {
    switch (levelType) {
      case 'lokasi':  return lastTemuanLokasiId  == levelId;
      case 'unit':    return lastTemuanUnitId     == levelId;
      case 'subunit': return lastTemuanSubunitId  == levelId;
      case 'area':    return lastTemuanAreaId     == levelId;
      default:        return false;
    }
  }

  bool isLastSelesai(String levelType, String levelId) {
    switch (levelType) {
      case 'lokasi':  return lastSelesaiLokasiId  == levelId;
      case 'unit':    return lastSelesaiUnitId    == levelId;
      case 'subunit': return lastSelesaiSubunitId == levelId;
      case 'area':    return lastSelesaiAreaId    == levelId;
      default:        return false;
    }
  }
}

class _C {
  static const primary     = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight= Color(0xFFE0F2FE);
  static const bg          = Color(0xFFF8FAFC);
  static const card        = Colors.white;
  static const textDark    = Color(0xFF0C4A6E);
  static const textGrey    = Color(0xFF64748B);
  static const border      = Color(0xFFBAE6FD);
  static const star        = Color(0xFFF59E0B);
  static const shimmerBase = Color(0xFFE8F4FD);
}

class _AppTexts {
  static const Map<String, Map<String, String>> _data = {
    'ID': {
      // LOCATION SCREEN
      'cari'                      : 'Cari',
      'lokasi_saya'               : 'Lokasi Saya',
      'sublokasi'                 : 'Sublokasi',
      'detail'                    : 'Lihat Detail',
      'kategori'                  : 'Kategori',
      'tanpa_kategori'            : 'Tanpa Kategori',
      'pic_kosong'                : 'Belum ada PIC',
      'temuan_terakhir'           : 'Temuan 5R Terakhir',
      'selesai_terakhir'          : 'Penyelesaian 5R Terakhir',
      'belum_ada_aktivitas'       : 'Belum ada aktivitas',
      'favorit'                   : 'Favorit',
      'badge_temuan_saya'         : 'Temuan Terakhir Anda',
      'badge_selesai_saya'        : 'Penyelesaian Terakhir Anda',
      'aktivitas_terakhir_label'  : 'Lokasi Aktivitas Terakhir',
      'favorit_semua'             : 'Favorit & Semua',
      'tidak_ada_data'            : 'Tidak ada data',
      'lokasi_blm_diatur'         : 'Lokasi Belum Diatur',
      'lokasi_blm_diatur_sub'     : 'Data lokasi Anda belum diisi.\nHubungi administrator untuk mengatur lokasi Anda.',
      'level0_empty'              : 'Lokasi belum ditetapkan',
      'level1_empty'              : 'Unit belum ditetapkan',
      'level2_empty'              : 'Subunit belum ditetapkan',
      'level3_empty'              : 'Area belum ditetapkan',
      'tidak_ada_gambar'          : 'Tidak ada gambar',
      // BOTTOM SHEET
      'info'                      : 'Info',
      'anggota'                   : 'Anggota',
      'cari_anggota'              : 'Cari anggota...',
      'pic'                       : 'Penanggung Jawab',
      'deskripsi'                 : 'Deskripsi',
      'tdk_ada'                   : 'Tidak ada deskripsi tersedia',
      'kosong'                    : 'Belum ada anggota',
      'generate_qr'               : 'Buat Kode QR',
      'qr_not_generated'          : 'Kode QR belum dibuat.',
      'qrcode'                    : 'QR Code',
      'search_result'             : 'Hasil Pencarian',
      'unit_empty'                : 'Unit tidak ditemukan',
      'subunit_empty'             : 'Subunit tidak ditemukan',
      'area_empty'                : 'Area tidak ditemukan',
      'level_lokasi'              : 'Lokasi',
      'level_unit'                : 'Unit',
      'level_subunit'             : 'Subunit',
      'level_area'                : 'Area',
      'my_lokasi_badge'           : 'Lokasi Saya',
      'my_unit_badge'             : 'Unit Saya',
      'my_subunit_badge'          : 'Subunit Saya',
      'my_area_badge'             : 'Area Saya',
      'my_responsibility'         : 'Tanggung Jawab Saya',
      'reset_pencarian'           : 'Reset Pencarian',
      'coba_kata_kunci_lain'      : 'Coba gunakan kata kunci lain atau reset pencarian Anda.',
    },
    'EN': {
      // LOCATION SCREEN
      'cari'                      : 'Search',
      'lokasi_saya'               : 'My Location',
      'sublokasi'                 : 'Sub-locations',
      'detail'                    : 'View Detail',
      'kategori'                  : 'Category',
      'tanpa_kategori'            : 'No Category',
      'pic_kosong'                : 'No PIC',
      'temuan_terakhir'           : 'Last 5R Finding',
      'selesai_terakhir'          : 'Last 5R Resolved',
      'belum_ada_aktivitas'       : 'No activity yet',
      'favorit'                   : 'Favorites',
      'badge_temuan_saya'         : 'Your Last Finding',
      'badge_selesai_saya'        : 'Your Last Solution',
      'aktivitas_terakhir_label'  : 'Recent Activity Location',
      'favorit_semua'             : 'Favorites & All',
      'tidak_ada_data'            : 'No data found',
      'lokasi_blm_diatur'         : 'Location Not Set',
      'lokasi_blm_diatur_sub'     : 'Your location data is not filled in yet.\nContact administrator to set up your location.',
      'level0_empty'              : 'Location not assigned',
      'level1_empty'              : 'Unit not assigned',
      'level2_empty'              : 'Subunit not assigned',
      'level3_empty'              : 'Area not assigned',
      'tidak_ada_gambar'          : 'No image available',
      // BOTTOM SHEET
      'info'                      : 'Info',
      'anggota'                   : 'Members',
      'cari_anggota'              : 'Search member...',
      'pic'                       : 'Person in Charge',
      'deskripsi'                 : 'Description',
      'tdk_ada'                   : 'No description available',
      'kosong'                    : 'No members found',
      'generate_qr'               : 'Generate QR Code',
      'qr_not_generated'          : 'QR Code has not been generated yet.',
      'qrcode'                    : 'QR Code',
      'search_result'             : 'Search Results',
      'unit_empty'                : 'Unit not found',
      'subunit_empty'             : 'Subunit not found',
      'area_empty'                : 'Area not found',
      'level_lokasi'              : 'Location',
      'level_unit'                : 'Unit',
      'level_subunit'             : 'Subunit',
      'level_area'                : 'Area',
      'my_lokasi_badge'           : 'My Location',
      'my_unit_badge'             : 'My Unit',
      'my_subunit_badge'          : 'My Subunit',
      'my_area_badge'             : 'My Area',
      'my_responsibility'         : 'My Responsibility',
      'reset_pencarian'           : 'Reset Search',
      'coba_kata_kunci_lain'      : 'Try using different keywords or reset your search.',
    },
    'ZH': {
      // LOCATION SCREEN
      'cari'                      : '搜索',
      'lokasi_saya'               : '我的位置',
      'sublokasi'                 : '子位置',
      'detail'                    : '查看详情',
      'kategori'                  : '类别',
      'tanpa_kategori'            : '无类别',
      'pic_kosong'                : '没有负责人',
      'temuan_terakhir'           : '最近5R发现',
      'selesai_terakhir'          : '最近5R处理',
      'belum_ada_aktivitas'       : '暂无活动',
      'favorit'                   : '收藏',
      'badge_temuan_saya'         : '您的最近发现',
      'badge_selesai_saya'        : '您的最近完成',
      'aktivitas_terakhir_label'  : '最近活动位置',
      'favorit_semua'             : '收藏 & 全部',
      'tidak_ada_data'            : '没有数据',
      'lokasi_blm_diatur'         : '位置未设置',
      'lokasi_blm_diatur_sub'     : '您的位置数据尚未填写。\n请联系管理员设置您的位置。',
      'level0_empty'              : '未分配位置',
      'level1_empty'              : '未分配单位',
      'level2_empty'              : '未分配子单位',
      'level3_empty'              : '未分配区域',
      'tidak_ada_gambar'          : '没有图片',
      // BOTTOM SHEET
      'info'                      : '信息',
      'anggota'                   : '成员',
      'cari_anggota'              : '搜索成员...',
      'pic'                       : '负责人',
      'deskripsi'                 : '描述',
      'tdk_ada'                   : '没有可用描述',
      'kosong'                    : '未找到成员',
      'generate_qr'               : '生成二维码',
      'qr_not_generated'          : '二维码尚未生成。',
      'qrcode'                    : '二维码',
      'search_result'             : '搜索结果',
      'unit_empty'                : '未找到单位',
      'subunit_empty'             : '未找到子单位',
      'area_empty'                : '未找到区域',
      'level_lokasi'              : '位置',
      'level_unit'                : '单位',
      'level_subunit'             : '子单位',
      'level_area'                : '区域',
      'my_lokasi_badge'           : '我的位置',
      'my_unit_badge'             : '我的单位',
      'my_subunit_badge'          : '我的子单位',
      'my_area_badge'             : '我的区域',
      'my_responsibility'         : '我的责任',
      'reset_pencarian'           : '重置搜索',
      'coba_kata_kunci_lain'      : '请尝试其他关键词或重置搜索。',
    },
  };

  static String get(String lang, String key) {
    return _data[lang]?[key] ?? _data['ID']?[key] ?? key;
  }
}

class LocationScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final String userRole;
  final String? userUnitId;
  final String? userLokasiId; 

  const LocationScreen({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.userRole,
    this.userUnitId,
    this.userLokasiId,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  int  _currentLevel = 0;

  @override
  bool get wantKeepAlive => true;
  bool _isLoading    = true;
  List<dynamic> _currentData  = [];
  List<dynamic> _filteredData = [];
  String _searchQuery = '';
  bool   _isLokasiSaya = false;

  List<Map<String, dynamic>> _navHistory     = [];
  Map<String, dynamic>?      _currentParentData;

  final Set<String> _favoritSet = {};

  // CACHE 
  final Map<String, _LastActivity> _activityCache = {};
  _UserLastLocation _userLastLocation = const _UserLastLocation();
  final Map<int, List<dynamic>> _levelCache = {};

  Map<String, dynamic>? _suggestTemuan;
  Map<String, dynamic>? _suggestSelesai;

  // GLOBAL SEARCH STATE
  bool   _isGlobalSearch    = false;
  bool   _isGlobalLoading   = false;
  List<_LocSearchResult> _globalResults = [];
  String? _activeFilter = 'lokasi';

  // MY LOCATION STATE
  String? _myLocationLokasiId;
  String? _myLocationUnitId;
  String? _myLocationSubunitId;
  String? _myLocationAreaId;

  // PAGINATION STATE
  int _currentPage = 1;
  static const int _perPage = 5;

  String t(String key) => _AppTexts.get(widget.lang, key);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  static const Color _barBlue = Color(0xFF1D72F3);
  static const List<Color> _levelColors = [
    Color(0xFF10B981), Color(0xFF6366F1), Color(0xFFFBBF24), Color(0xFFF472B6),
  ];
  static const List<IconData> _levelIcons = [
    Icons.location_city_rounded, Icons.business_rounded, Icons.layers_rounded, Icons.place_rounded,
  ];

  bool _isMyLocationOfType(String type, String id) {
    switch (type) {
      case 'lokasi':  return _myLocationLokasiId  == id;
      case 'unit':    return _myLocationUnitId    == id;
      case 'subunit': return _myLocationSubunitId == id;
      case 'area':    return _myLocationAreaId    == id;
      default: return false;
    }
  }

  bool _isPicOfItem(Map<String, dynamic> raw) =>
      _currentUserId != null && raw['id_pic']?.toString() == _currentUserId;

  Widget _levelPill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _myBadgeChip(String type) {
    const myLabelKeys = {
      'lokasi': 'my_lokasi_badge', 'unit': 'my_unit_badge',
      'subunit': 'my_subunit_badge', 'area': 'my_area_badge',
    };
    const idx = {'lokasi': 0, 'unit': 1, 'subunit': 2, 'area': 3};
    final color = _levelColors[idx[type] ?? 0];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_pin_circle_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(t(myLabelKeys[type]!), style: GoogleFonts.poppins(fontSize: 8.5, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _picBadgeChip() {
    const color = Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(t('my_responsibility'), style: GoogleFonts.poppins(fontSize: 8.5, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  List<Widget> _buildBadgeStarOverlay({
    required bool isPic,
    required bool isMyLoc,
    required String type,
    required String id,
    required Map<String, dynamic> raw,
  }) {
    if (!isPic && !isMyLoc) {
      return [
        Positioned(top: 8, right: 8, child: _starButton(type, id, raw)),
      ];
    } else if (isPic && isMyLoc) {
      return [
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _picBadgeChip(),
              const SizedBox(height: 6),
              _myBadgeChip(type),
            ],
          ),
        ),
        Positioned(bottom: 6, right: 8, child: _starButton(type, id, raw)),
      ];
    } else {
      final badge = isPic ? _picBadgeChip() : _myBadgeChip(type);
      return [
        Positioned(
          top: 8,
          right: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              const SizedBox(height: 6),
              _starButton(type, id, raw),
            ],
          ),
        ),
      ];
    }
  }

  Widget _starButton(String type, String id, Map<String, dynamic> raw) {
    final bool isStarred = _isFavorit(type, id);
    return GestureDetector(
      onTap: () => _toggleFavorit(type, id),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _C.star.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isStarred ? Icons.star_rounded : Icons.star_border_rounded,
          color: _C.star,
          size: 18,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initAll() async {
    await Future.wait([
      _loadFavorit(),
      _loadMyLocationData(),
      _loadUserLastLocation(),
    ]);
    await _prefetchAllLevels();
  }

  Future<void> _prefetchAllLevels() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _supabase.from('lokasi').select(
            'id_lokasi, nama_lokasi, gambar_lokasi, deskripsi_lokasi, '
            'is_star, id_pic, User!id_pic(nama, gambar_user), unit(id_unit), qrcode'),
        _supabase.from('unit').select(
            'id_unit, nama_unit, gambar_unit, deskripsi_unit, '
            'is_star, id_pic, User!id_pic(nama, gambar_user), subunit(id_subunit), '
            'id_lokasi, lokasi(nama_lokasi), qrcode'),
        _supabase.from('subunit').select(
            'id_subunit, nama_subunit, gambar_subunit, deskripsi_subunit, '
            'is_star, id_pic, User!id_pic(nama, gambar_user), area(id_area), '
            'id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi), qrcode'),
        _supabase.from('area').select(
            'id_area, nama_area, gambar_area, deskripsi_area, '
            'is_star, id_pic, User!id_pic(nama, gambar_user), '
            'id_subunit, id_unit, id_lokasi, '
            'subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi), qrcode'),
      ]);

      _levelCache[0] = results[0];
      _levelCache[1] = results[1];
      _levelCache[2] = results[2];
      _levelCache[3] = results[3];

      List<dynamic> data = List<dynamic>.from(_levelCache[_currentLevel] ?? []);
      if (_isLokasiSaya) data = _filterByMyLocation(data, _currentLevel);

      if (mounted) {
        setState(() {
          _currentData = data;
          _isLoading   = false;
          _currentPage = 1;
          _onSearch(_searchQuery);
        });
        _updateSuggestItems();
        for (int lvl = 0; lvl < 4; lvl++) {
          _prefetchAllActivities(_getLevelName(lvl), _levelCache[lvl] ?? []);
        }
      }
    } catch (e) {
      debugPrint('Prefetch all levels error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavorit() async {
    if (_currentUserId == null) return;
    try {
      final rows = await _supabase
          .from('favorit_lokasi')
          .select('level_type, level_id')
          .eq('id_user', _currentUserId!);
      if (mounted) {
        setState(() {
          _favoritSet.clear();
          for (final r in rows) {
            _favoritSet.add('${r['level_type']}:${r['level_id']}');
          }
        });
      }
    } catch (e) {
      debugPrint('Load favorit error: $e');
    }
  }

  Future<void> _loadUserLastLocation() async {
    if (_currentUserId == null) return;
    try {
      final rows = await _supabase.rpc(
        'get_user_last_activity_location',
        params: {'p_user_id': _currentUserId},
      );
      if (rows is List && rows.isNotEmpty && mounted) {
        final r = rows[0];
        setState(() {
          _userLastLocation = _UserLastLocation(
            lastTemuanLokasiId  : r['last_temuan_lokasi_id']?.toString(),
            lastTemuanUnitId    : r['last_temuan_unit_id']?.toString(),
            lastTemuanSubunitId : r['last_temuan_subunit_id']?.toString(),
            lastTemuanAreaId    : r['last_temuan_area_id']?.toString(),
            lastSelesaiLokasiId : r['last_selesai_lokasi_id']?.toString(),
            lastSelesaiUnitId   : r['last_selesai_unit_id']?.toString(),
            lastSelesaiSubunitId: r['last_selesai_subunit_id']?.toString(),
            lastSelesaiAreaId   : r['last_selesai_area_id']?.toString(),
          );
        });
        _updateSuggestItems();
      }
    } catch (e) {
      debugPrint('Load user last location error: $e');
    }
  }

  void _updateSuggestItems() {
    final tName = _getLevelName();
    Map<String, dynamic>? foundTemuan;
    Map<String, dynamic>? foundSelesai;

    for (final item in _currentData) {
      final id = item['id_$tName']?.toString();
      if (id == null) continue;

      if (_userLastLocation.isLastTemuan(tName, id)) foundTemuan = item;
      if (_userLastLocation.isLastSelesai(tName, id)) foundSelesai = item;
    }

    if (mounted) {
      setState(() {
        _suggestTemuan  = foundTemuan;
        _suggestSelesai = foundSelesai;
      });
    }
  }

  Future<void> _loadMyLocationData() async {
    if (_currentUserId == null) return;
    try {
      final userData = await _supabase
          .from('User')
          .select('id_lokasi, id_unit, id_subunit, id_area')
          .eq('id_user', _currentUserId!)
          .maybeSingle();

      if (userData != null && mounted) {
        setState(() {
          _myLocationLokasiId  = userData['id_lokasi'];
          _myLocationUnitId    = userData['id_unit'];
          _myLocationSubunitId = userData['id_subunit'];
          _myLocationAreaId    = userData['id_area'];
        });
      }
    } catch (e) {
      debugPrint('Load my location data error: $e');
    }
  }

  bool _isFavorit(String levelType, String levelId) =>
      _favoritSet.contains('$levelType:$levelId');

  Future<void> _toggleFavorit(String levelType, String levelId) async {
    if (_currentUserId == null) return;
    final key    = '$levelType:$levelId';
    final wasFav = _favoritSet.contains(key);

    setState(() {
      if (wasFav) { _favoritSet.remove(key); } else { _favoritSet.add(key); }
      _onSearch(_searchQuery);
    });

    try {
      if (wasFav) {
        await _supabase
            .from('favorit_lokasi')
            .delete()
            .eq('id_user', _currentUserId!)
            .eq('level_type', levelType)
            .eq('level_id', levelId);
      } else {
        await _supabase.from('favorit_lokasi').insert({
          'id_user'   : _currentUserId,
          'level_type': levelType,
          'level_id'  : levelId,
        });
      }
    } catch (e) {
      setState(() {
        if (wasFav) { _favoritSet.add(key); } else { _favoritSet.remove(key); }
        _onSearch(_searchQuery);
      });
      debugPrint('Toggle favorit error: $e');
    }
  }

  Future<void> _prefetchAllActivities(
      String tName, List<dynamic> items) async {
    final toFetch = <String>[];
    for (final item in items) {
      final id = item['id_$tName']?.toString();
      if (id != null && !_activityCache.containsKey('$tName:$id')) {
        toFetch.add(id);
      }
    }
    if (toFetch.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    const batchSize = 5;
    for (int i = 0; i < toFetch.length; i += batchSize) {
      final batch = toFetch.skip(i).take(batchSize).toList();
      try {
        await Future.wait(batch.map((id) => _fetchActivity(tName, id)));
      } catch (e) {
        for (final id in batch) {
          _activityCache['$tName:$id'] = const _LastActivity();
        }
        debugPrint('Prefetch activity error: $e');
      }
    }
    if (mounted) setState(() {});
  }

  Future<_LastActivity> _fetchActivity(String levelType, String levelId) async {
    final key = '$levelType:$levelId';
    if (_activityCache.containsKey(key)) return _activityCache[key]!;
    final idCol = 'id_$levelType';
    try {
      final results = await Future.wait([
        _supabase
            .from('temuan')
            .select('created_at')
            .eq(idCol, levelId)
            .eq('jenis_temuan', '5R')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle(),
        _supabase
            .from('temuan')
            .select('penyelesaian!inner(tanggal_selesai)')
            .eq(idCol, levelId)
            .eq('jenis_temuan', '5R')
            .order('tanggal_selesai', referencedTable: 'penyelesaian', ascending: false)
            .limit(1)
            .maybeSingle(),
      ]);

      final temuanRow  = results[0];
      final selesaiRow = results[1];

      final activity = _LastActivity(
        lastTemuan: temuanRow?['created_at'] != null
            ? DateTime.tryParse(temuanRow!['created_at'].toString())
            : null,
        lastPenyelesaian: selesaiRow?['penyelesaian']?['tanggal_selesai'] != null
            ? DateTime.tryParse(selesaiRow!['penyelesaian']['tanggal_selesai'].toString())
            : null,
      );
      _activityCache[key] = activity;
      return activity;
    } catch (e) {
      _activityCache[key] = const _LastActivity();
      debugPrint('Fetch 5R activity error ($levelType:$levelId): $e');
      return const _LastActivity();
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }

  Future<void> _fetchData({String? parentId, Map<String, dynamic>? parentData}) async {
    final tName = _getLevelName();
    List<dynamic> data = List<dynamic>.from(_levelCache[_currentLevel] ?? []);

    if (parentId != null && _currentLevel > 0) {
      const filterColumns = ['id_lokasi', 'id_unit', 'id_subunit'];
      final filterCol = filterColumns[_currentLevel - 1];
      data = data.where((item) => item[filterCol]?.toString() == parentId).toList();
    }

    if (_isLokasiSaya) {
      data = _filterByMyLocation(data, _currentLevel);
    }

    if (mounted) {
      setState(() {
        _currentData       = data;
        _currentParentData = parentData;
        _isLoading         = false;
        _currentPage       = 1;
        _onSearch(_searchQuery);
      });
      _updateSuggestItems();
      _prefetchAllActivities(tName, data);
    }
  }

  List<dynamic> _filterByMyLocation(List<dynamic> data, int level) {
    String? filterId;
    String idKey;
    switch (level) {
      case 0: filterId = _myLocationLokasiId;  idKey = 'id_lokasi';  break;
      case 1: filterId = _myLocationUnitId;    idKey = 'id_unit';    break;
      case 2: filterId = _myLocationSubunitId; idKey = 'id_subunit'; break;
      case 3: filterId = _myLocationAreaId;    idKey = 'id_area';    break;
      default: return data;
    }
    if (filterId == null) return [];
    return data.where((item) => item[idKey]?.toString() == filterId).toList();
  }

  void _onSearch(String query) {
    _searchQuery = query.toLowerCase();
    if (query.trim().isEmpty) {
      setState(() {
        _isGlobalSearch = false;
        _globalResults  = [];
        _activeFilter   = _getLevelName(_currentLevel);
        _currentPage    = 1;
      });
      final tName = _getLevelName();
      setState(() {
        _filteredData = _currentData.where((item) {
          final nama = item['nama_$tName'];
          return nama != null && nama.toString().toLowerCase().contains(_searchQuery);
        }).toList();
        _filteredData.sort((a, b) {
          final idA = a['id_$tName']?.toString() ?? '';
          final idB = b['id_$tName']?.toString() ?? '';
          final favA = _isFavorit(tName, idA) ? 0 : 1;
          final favB = _isFavorit(tName, idB) ? 0 : 1;
          if (favA != favB) return favA.compareTo(favB);
          return (a['nama_$tName'] ?? '').toString().toLowerCase()
              .compareTo((b['nama_$tName'] ?? '').toString().toLowerCase());
        });
      });
      return;
    }
    setState(() => _isGlobalSearch = true);
    _performGlobalSearch(query);
  }

  void _performGlobalSearch(String query) {
    final q = query.trim().toLowerCase();
    final results = <_LocSearchResult>[];

    for (final r in (_levelCache[0] ?? [])) {
      if ((r['nama_lokasi']?.toString() ?? '').toLowerCase().contains(q)) {
        results.add(_makeLocResult(r, 'lokasi', 0));
      }
    }
    for (final r in (_levelCache[1] ?? [])) {
      if ((r['nama_unit']?.toString() ?? '').toLowerCase().contains(q)) {
        results.add(_makeLocResult(r, 'unit', 1));
      }
    }
    for (final r in (_levelCache[2] ?? [])) {
      if ((r['nama_subunit']?.toString() ?? '').toLowerCase().contains(q)) {
        results.add(_makeLocResult(r, 'subunit', 2));
      }
    }
    for (final r in (_levelCache[3] ?? [])) {
      if ((r['nama_area']?.toString() ?? '').toLowerCase().contains(q)) {
        results.add(_makeLocResult(r, 'area', 3));
      }
    }

    final filtered = _isLokasiSaya
        ? results.where((r) => _isInMyLocationScope(r)).toList()
        : results;

    filtered.sort((a, b) {
      final favA = _isFavorit(a.type, a.id) ? 0 : 1;
      final favB = _isFavorit(b.type, b.id) ? 0 : 1;
      if (favA != favB) return favA.compareTo(favB);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    const order = ['lokasi', 'unit', 'subunit', 'area'];
    final hasMatchOnActiveTab = filtered.any((r) => r.type == _activeFilter);
    String newActiveFilter = _activeFilter ?? 'lokasi';
    if (!hasMatchOnActiveTab) {
      for (final type in order) {
        if (filtered.any((r) => r.type == type)) {
          newActiveFilter = type;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _globalResults    = filtered;
        _isGlobalLoading  = false;
        _activeFilter     = newActiveFilter;
        _currentPage      = 1;
      });
    }
  }

  bool _isInMyLocationScope(_LocSearchResult r) {
    switch (r.type) {
      case 'lokasi':
        return r.id == _myLocationLokasiId;
      case 'unit':
        return r.id == _myLocationUnitId ||
            r.raw['id_lokasi']?.toString() == _myLocationLokasiId;
      case 'subunit':
        return r.id == _myLocationSubunitId ||
            r.raw['id_unit']?.toString() == _myLocationUnitId ||
            r.raw['id_lokasi']?.toString() == _myLocationLokasiId;
      case 'area':
        return r.id == _myLocationAreaId ||
            r.raw['id_subunit']?.toString() == _myLocationSubunitId ||
            r.raw['id_unit']?.toString() == _myLocationUnitId ||
            r.raw['id_lokasi']?.toString() == _myLocationLokasiId;
      default:
        return false;
    }
  }

  _LocSearchResult _makeLocResult(Map<String, dynamic> r, String type, int level) {
    final id   = r['id_$type']?.toString() ?? '';
    final name = r['nama_$type']?.toString() ?? '';
    final img  = r['gambar_$type'] as String?;
    String? breadcrumb;
    if (type == 'unit')    breadcrumb = r['lokasi']?['nama_lokasi']?.toString();
    if (type == 'subunit') breadcrumb = r['unit']?['nama_unit']?.toString();
    if (type == 'area')    breadcrumb = r['subunit']?['nama_subunit']?.toString();
    return _LocSearchResult(id: id, name: name, type: type, level: level, imgUrl: img, breadcrumb: breadcrumb, raw: r);
  }

  String _getLevelName([int? level]) =>
      ['lokasi', 'unit', 'subunit', 'area'][level ?? _currentLevel];

  void _goBack() {
    if (_navHistory.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _navHistory.removeLast();
      _currentLevel--;
      _searchQuery = '';
    });
    if (_navHistory.isEmpty) {
      _fetchData();
    } else {
      final prev = _navHistory.last;
      _fetchData(parentId: prev['id'], parentData: prev['data']);
    }
  }

  void _showDetailModal() {
    if (_currentParentData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationDetailScreen(
          level: _currentLevel - 1,
          data : _currentParentData!,
          lang : widget.lang,
        ),
      ),
    );
  }

  void _showDetailModalForItem(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationDetailScreen(
          level: _currentLevel,
          data : item,
          lang : widget.lang,
        ),
      ),
    );
  }

  void _toggleLokasiSaya() {
    final parentId = _navHistory.isNotEmpty ? _navHistory.last['id'] as String? : null;

    setState(() {
      _isLokasiSaya = !_isLokasiSaya;

      List<dynamic> data = List<dynamic>.from(_levelCache[_currentLevel] ?? []);
      if (parentId != null && _currentLevel > 0) {
        const filterColumns = ['id_lokasi', 'id_unit', 'id_subunit'];
        final filterCol = filterColumns[_currentLevel - 1];
        data = data.where((item) => item[filterCol]?.toString() == parentId).toList();
      }
      if (_isLokasiSaya) data = _filterByMyLocation(data, _currentLevel);
      _currentData = data;
      _currentPage = 1;
    });
    _onSearch(_searchQuery);
    _updateSuggestItems();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final title = _navHistory.isEmpty
        ? _getLevelName().toUpperCase()
        : _navHistory.last['name'] as String;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(title),
      body: Column(
        children: [
          _buildSearchBar(),
          if (!_isLoading && _currentLevel > 0 && _currentParentData != null)
            _buildParentCard(),
          if (!_isLoading) _buildSuggestSection(),
          Expanded(
            child: _isGlobalSearch
                ? _buildGlobalSearchResults()
                : _isLoading ? _buildShimmerList() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSearchResults() {
    if (_isGlobalLoading) {
      return _buildShimmerList();
    }

    final displayed = _globalResults.where((r) => r.type == _activeFilter).toList();

    if (displayed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/team_illustration.png', width: 160, height: 160,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: _C.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.search_off_rounded, size: 52, color: _C.primary.withValues(alpha: 0.45)),
                  )),
              const SizedBox(height: 18),
              Text(t('tidak_ada_data'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.textDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(t('coba_kata_kunci_lain'),
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _resetSearchAndFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _C.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restart_alt_rounded, size: 15, color: _C.primary),
                      const SizedBox(width: 6),
                      Text(t('reset_pencarian'),
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _C.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    String subLabelOf(int level, Map<String, dynamic> raw) {
      switch (level) {
        case 0:
          final units = raw['unit'] as List?;
          return '${units?.length ?? 0} ${t('level_unit')}';
        case 1:
          final subunits = raw['subunit'] as List?;
          return '${subunits?.length ?? 0} ${t('level_subunit')}';
        case 2:
          final areas = raw['area'] as List?;
          return '${areas?.length ?? 0} ${t('level_area')}';
        default:
          return '';
      }
    }

    final totalPages = (displayed.length / _perPage).ceil();
    final safePage    = _currentPage.clamp(1, totalPages);
    final startIdx    = (safePage - 1) * _perPage;
    final endIdx      = (startIdx + _perPage) > displayed.length ? displayed.length : startIdx + _perPage;
    final pageItems   = displayed.sublist(startIdx, endIdx);

    const _levelTypeIdx = {'lokasi': 0, 'unit': 1, 'subunit': 2, 'area': 3};
    final indicatorColor = _levelColors[_levelTypeIdx[_activeFilter] ?? 0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Text('${t('search_result')} (${displayed.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, color: _C.textDark, fontSize: 13)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            itemCount: pageItems.length,
            itemBuilder: (_, i) {
              final r        = pageItems[i];
              final isFav    = _isFavorit(r.type, r.id);
              final clr      = _levelColors[r.level];
              final ico      = _levelIcons[r.level];
              final subCount = subLabelOf(r.level, r.raw);

              final bool isMyLoc  = _isMyLocationOfType(r.type, r.id);
              final bool isPic    = _isPicOfItem(r.raw);
              final bool hasBadge = isMyLoc || isPic;

              Widget? breadcrumbPill;
              if (r.breadcrumb != null) {
                breadcrumbPill = _levelPill(
                  icon: r.level > 0 ? _levelIcons[r.level - 1] : ico,
                  label: r.breadcrumb!,
                  color: r.level > 0 ? _levelColors[r.level - 1] : clr,
                );
              }

              Widget? subCountPill;
              if (subCount.isNotEmpty && r.level < 3) {
                subCountPill = _levelPill(
                  icon: _levelIcons[r.level + 1],
                  label: subCount,
                  color: _levelColors[r.level + 1],
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFav ? _C.star.withValues(alpha: 0.5) : _C.border,
                    width: isFav ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                                child: SizedBox(
                                  width: 80,
                                  child: r.imgUrl != null
                                      ? Image.network(r.imgUrl!, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: clr.withValues(alpha: 0.1),
                                            child: Center(child: Icon(ico, color: clr, size: 28)),
                                          ))
                                      : Container(
                                          color: clr.withValues(alpha: 0.1),
                                          child: Center(child: Icon(ico, color: clr, size: 28)),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(0, 12, hasBadge ? 84 : 44, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final itemData = Map<String, dynamic>.from(r.raw);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => LocationDetailScreen(
                                                level: r.level,
                                                data : itemData,
                                                lang : widget.lang,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(r.name,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: clr,
                                                      height: 1.25),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis),
                                            ),
                                            const SizedBox(width: 5),
                                            const Icon(Icons.info_outline_rounded,
                                                size: 15, color: _C.primary),
                                          ],
                                        ),
                                      ),
                                      if (breadcrumbPill != null) ...[
                                        const SizedBox(height: 6),
                                        breadcrumbPill,
                                      ],
                                      const SizedBox(height: 6),
                                      if (breadcrumbPill == null) ...[
                                        _levelPill(icon: ico, label: t('level_${r.type}'), color: clr),
                                        if (subCountPill != null) ...[
                                          const SizedBox(height: 6),
                                          subCountPill,
                                        ],
                                      ] else
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _levelPill(icon: ico, label: t('level_${r.type}'), color: clr),
                                            if (subCountPill != null) subCountPill,
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._buildBadgeStarOverlay(
                          isPic: isPic,
                          isMyLoc: isMyLoc,
                          type: r.type,
                          id: r.id,
                          raw: r.raw,
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius:
                            const BorderRadius.vertical(bottom: Radius.circular(16)),
                        border: const Border(
                            top: BorderSide(color: _C.border, width: 1)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: _activityChip(
                              icon: Icons.search_rounded,
                              color: const Color(0xFF0EA5E9),
                              label: t('temuan_terakhir'),
                              value: '-',
                            ),
                          ),
                          Container(
                              width: 1, height: 28, color: _C.border,
                              margin: const EdgeInsets.symmetric(horizontal: 8)),
                          Expanded(
                            child: _activityChip(
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF10B981),
                              label: t('selesai_terakhir'),
                              value: '-',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 4, 16, 12 + MediaQuery.of(context).padding.bottom),
            child: SpecificLocationPageIndicator(
              currentPage: safePage,
              totalPages: totalPages,
              color: indicatorColor,
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    final Map<String, String> screenTitles = {
      'ID': 'Lokasi Spesifik',
      'EN': 'Specific Location',
      'ZH': '特定位置',
    };
    final appBarTitle = _navHistory.isEmpty
        ? (screenTitles[widget.lang] ?? 'Lokasi Spesifik')
        : title;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _barBlue),
        onPressed: _goBack,
      ),
      title: Text(
        appBarTitle,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: _barBlue,
          fontSize: 17,
        ),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      iconTheme: const IconThemeData(color: _barBlue),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 12),
            child: Row(
              children: [
                Expanded(child: _buildSpecificSearchField()),
                const SizedBox(width: 12),
                _buildMyLocationButton(),
              ],
            ),
          ),
          _buildFilterChips(),
        ],
      ),
    );
  }

  void _resetSearchAndFilter() {
    _searchController.clear();
    final List<dynamic> data = List<dynamic>.from(_levelCache[0] ?? []);
    setState(() {
      _searchQuery       = '';
      _isGlobalSearch     = false;
      _globalResults      = [];
      _isLokasiSaya       = false;
      _navHistory         = [];
      _currentLevel       = 0;
      _currentParentData  = null;
      _currentData        = data;
      _activeFilter       = _getLevelName(0);
      _currentPage        = 1;
    });
    _onSearch('');
    _updateSuggestItems();
    _prefetchAllActivities('lokasi', data);
  }

  Widget _buildSpecificSearchField() {
    final bool active = _isGlobalSearch;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? _barBlue : Colors.grey.shade300,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _barBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: '${t('cari')} ${t('level_${_activeFilter ?? _getLevelName()}')}',
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (active)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _isGlobalSearch = false;
                  _globalResults  = [];
                  _searchQuery    = '';
                  _activeFilter   = _getLevelName(_currentLevel);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _barBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: _barBlue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    const myLabelKeys = ['my_lokasi_badge', 'my_unit_badge', 'my_subunit_badge', 'my_area_badge'];
    final icon  = _levelIcons[_currentLevel];
    final label = t(myLabelKeys[_currentLevel]);

    return GestureDetector(
      onTap: _toggleLokasiSaya,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: _isLokasiSaya
              ? const LinearGradient(
                  colors: [_barBlue, Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isLokasiSaya ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isLokasiSaya ? _barBlue : Colors.grey.shade300,
            width: 1.4,
          ),
          boxShadow: _isLokasiSaya
              ? [
                  BoxShadow(
                    color: _barBlue.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: _isLokasiSaya ? Colors.white : _barBlue,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: _isLokasiSaya ? Colors.white : _barBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'lokasi',  'label': t('level_lokasi')},
      {'key': 'unit',    'label': t('level_unit')},
      {'key': 'subunit', 'label': t('level_subunit')},
      {'key': 'area',    'label': t('level_area')},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
      child: Row(
        children: List.generate(filters.length, (i) {
          final key    = filters[i]['key']!;
          final label  = filters[i]['label']!;
          final active = _activeFilter == key;
          final color  = _levelColors[i];
          final icon   = _levelIcons[i];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (active) return;

                if (_isGlobalSearch) {
                  setState(() {
                    _activeFilter = key;
                    _currentPage  = 1;
                  });
                  return;
                }

                List<dynamic> data = List<dynamic>.from(_levelCache[i] ?? []);
                if (_isLokasiSaya) data = _filterByMyLocation(data, i);

                setState(() {
                  _activeFilter      = key;
                  _currentLevel      = i;
                  _navHistory        = [];
                  _currentData       = data;
                  _isGlobalSearch    = false;
                  _globalResults     = [];
                  _currentParentData = null;
                  _suggestTemuan     = null;
                  _suggestSelesai    = null;
                  _searchQuery       = '';
                  _currentPage       = 1;
                });
                _onSearch('');
                _updateSuggestItems();
                _prefetchAllActivities(key, data);
              },
              child: Container(
                margin: EdgeInsets.only(right: i < filters.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? color : Colors.grey.shade300),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: active ? Colors.white : color),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFBAE6FD),
      highlightColor: const Color(0xFFE0F2FE),
      period: const Duration(milliseconds: 1200),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: 5,
        itemBuilder: (_, __) => _buildShimmerCard(),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // MAIN LINE
          Row(
            children: [
              // IMAGE PLACEHOLDER
              Container(
                width: 80,
                height: 90,
                decoration: const BoxDecoration(
                  color: _C.shimmerBase,
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              const SizedBox(width: 12),
              // TEXT PLACEHOLDER
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _C.shimmerBase,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // SUBINFO
                      Container(
                        height: 11,
                        width: 120,
                        decoration: BoxDecoration(
                          color: _C.shimmerBase,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // STAR PLACEHOLDER
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _C.shimmerBase,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // ACTIVITY FOOTER
          Container(
            height: 38,
            decoration: const BoxDecoration(
              color: _C.shimmerBase,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCard() {
    final tName     = _getLevelName(_currentLevel - 1);
    final imgUrl    = _currentParentData!['gambar_$tName'] as String?;
    final pic       = _currentParentData!['User'] as Map?;
    final kat       = _currentParentData!['kategori'] as String?;
    final parentName= _currentParentData!['nama_$tName'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C4A6E), Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _C.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              image: imgUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imgUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: imgUrl == null
                ? const Center(
                    child: Icon(Icons.domain_rounded,
                        color: Colors.white70, size: 36))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentName,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: Text(
                        (pic?['nama'] as String? ?? 'U')
                            .substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        pic?['nama'] as String? ?? t('pic_kosong'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (kat != null && kat.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(kat,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: _showDetailModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(t('detail'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestSection() {
    final hasSuggest = _suggestTemuan != null || _suggestSelesai != null;
    if (!hasSuggest) return const SizedBox.shrink();

    final tName = _getLevelName();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.tips_and_updates_rounded,
                    color: _C.primary, size: 14),
              ),
              const SizedBox(width: 7),
              Text(
                t('aktivitas_terakhir_label'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_suggestTemuan != null)
            _buildSuggestCard(
                item: _suggestTemuan!, tName: tName, isTemuan: true),

          if (_suggestSelesai != null &&
              _suggestSelesai!['id_$tName'] != _suggestTemuan?['id_$tName'])
            _buildSuggestCard(
                item: _suggestSelesai!, tName: tName, isTemuan: false),

          if (_suggestTemuan != null &&
              _suggestSelesai != null &&
              _suggestSelesai!['id_$tName'] == _suggestTemuan!['id_$tName'])
            _buildSuggestCard(
                item: _suggestTemuan!, tName: tName,
                isTemuan: true, isSelesai: true),

          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFBAE6FD))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  t('favorit_semua'),
                  style: const TextStyle(
                      fontSize: 10, color: _C.textGrey,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFBAE6FD))),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildSuggestCard({
    required Map<String, dynamic> item,
    required String tName,
    required bool isTemuan,
    bool isSelesai = false,
  }) {
    final rawId = item['id_$tName'];
    if (rawId == null) return const SizedBox.shrink();
    final id = item['id_$tName']?.toString();
    if (id == null) return const SizedBox.shrink();

    final name   = item['nama_$tName']?.toString() ?? '';
    final imgUrl = item['gambar_$tName'] as String?;
    final isFav  = _isFavorit(tName, id);
    final levelClr = _levelColors[_currentLevel];
    final levelIco = _levelIcons[_currentLevel];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LocationDetailScreen(
              level: _currentLevel,
              data : item,
              lang : widget.lang,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: levelClr.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: levelClr.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: levelClr.withValues(alpha: 0.12),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
                image: imgUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imgUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imgUrl == null
                  ? Center(
                      child: Icon(levelIco,
                          color: levelClr, size: 22))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: levelClr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (isTemuan)
                          _suggestBadge(
                            label: t('badge_temuan_saya'),
                            color: const Color(0xFF0EA5E9),
                            icon : Icons.location_on_rounded,
                          ),
                        if (isSelesai)
                          _suggestBadge(
                            label: t('badge_selesai_saya'),
                            color: const Color(0xFF10B981),
                            icon : Icons.check_circle_rounded,
                          ),
                        if (!isTemuan && !isSelesai)
                          _suggestBadge(
                            label: t('badge_selesai_saya'),
                            color: const Color(0xFF10B981),
                            icon : Icons.check_circle_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? _C.star : Colors.grey.shade300,
                  size: 22,
                ),
                onPressed: () => _toggleFavorit(tName, id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLokasiSaya && _filteredData.isEmpty) return _buildMyLocationEmptyState();
    if (_filteredData.isEmpty) return _buildLevelEmptyState();

    final totalPages = (_filteredData.length / _perPage).ceil();
    final safePage    = _currentPage.clamp(1, totalPages);
    final startIdx    = (safePage - 1) * _perPage;
    final endIdx      = (startIdx + _perPage) > _filteredData.length
        ? _filteredData.length
        : startIdx + _perPage;
    final pageItems   = _filteredData.sublist(startIdx, endIdx);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            itemCount: pageItems.length,
            itemBuilder: (ctx, i) => _buildLocationCard(pageItems[i]),
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 4, 16, 12 + MediaQuery.of(context).padding.bottom),
            child: SpecificLocationPageIndicator(
              currentPage: safePage,
              totalPages: totalPages,
              color: _levelColors[_currentLevel],
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),
          ),
      ],
    );
  }

  Widget _buildLevelEmptyState() {
    const levelKeys = ['tidak_ada_data', 'unit_empty', 'subunit_empty', 'area_empty'];
    final msgKey = levelKeys[_currentLevel];
    final color  = _levelColors[_currentLevel];
    final icon   = _levelIcons[_currentLevel];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              width: 170, height: 170,
              errorBuilder: (_, __, ___) => Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.30), width: 2),
                ),
                child: Icon(icon, size: 56, color: color.withValues(alpha: 0.55)),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(t('level_${_getLevelName(_currentLevel)}'),
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(t(msgKey),
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5),
                textAlign: TextAlign.center),
            if (_isLokasiSaya) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _resetSearchAndFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt_rounded, size: 15, color: color),
                      const SizedBox(width: 6),
                      Text(t('reset_pencarian'),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyLocationEmptyState() {
    final levelKey = 'level${_currentLevel}_empty';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/team_illustration.png',
              width: 180, height: 180,
              errorBuilder: (_, __, ___) => Container(
                width: 140, height: 140,
                decoration: const BoxDecoration(
                    color: _C.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.location_off_rounded,
                    size: 70, color: _C.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t('lokasi_blm_diatur'),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: _C.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _C.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 15, color: _C.primary),
                  const SizedBox(width: 7),
                  Text(
                    t(levelKey),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _C.primaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('lokasi_blm_diatur_sub'),
              style: const TextStyle(
                  fontSize: 13, color: _C.textGrey, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> item) {
    final tName = _getLevelName();
    final rawId = item['id_$tName'];
    if (rawId == null) return const SizedBox.shrink();
    final id = item['id_$tName']?.toString();
    if (id == null) return const SizedBox.shrink();

    final name      = item['nama_$tName']?.toString() ?? '';
    final imgUrl    = item['gambar_$tName'] as String?;
    final isFav     = _isFavorit(tName, id);
    final cachedActivity = _activityCache['$tName:$id'];

    final bool isMyLoc  = _isMyLocationOfType(tName, id);
    final bool isPic    = _isPicOfItem(item);
    final bool hasBadge = isMyLoc || isPic;

    String subLabel() {
      if (_currentLevel >= 3) return '';
      switch (_currentLevel) {
        case 0:
          final units = item['unit'] as List?;
          return '${units?.length ?? 0} ${t('level_unit')}';
        case 1:
          final subunits = item['subunit'] as List?;
          return '${subunits?.length ?? 0} ${t('level_subunit')}';
        case 2:
          final areas = item['area'] as List?;
          return '${areas?.length ?? 0} ${t('level_area')}';
        default:
          return '';
      }
    }

    String? breadcrumb;
    if (_currentLevel == 1 && _navHistory.isEmpty) {
      breadcrumb = item['lokasi']?['nama_lokasi']?.toString();
    } else if (_currentLevel == 2 && _navHistory.isEmpty) {
      breadcrumb = item['unit']?['nama_unit']?.toString();
    } else if (_currentLevel == 3 && _navHistory.isEmpty) {
      breadcrumb = item['subunit']?['nama_subunit']?.toString();
    }

    final clr = _levelColors[_currentLevel];
    final ico = _levelIcons[_currentLevel];

    Widget? breadcrumbPill;
    if (breadcrumb != null && _currentLevel > 0) {
      final parentLevel = _currentLevel - 1;
      breadcrumbPill = _levelPill(
        icon: _levelIcons[parentLevel],
        label: breadcrumb,
        color: _levelColors[parentLevel],
      );
    }

    Widget? subCountPill;
    final subText = subLabel();
    if (subText.isNotEmpty && _currentLevel < 3) {
      subCountPill = _levelPill(
        icon: _levelIcons[_currentLevel + 1],
        label: subText,
        color: _levelColors[_currentLevel + 1],
      );
    }

    return GestureDetector(
      onTap: () => _showDetailModalForItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFav ? _C.star.withValues(alpha: 0.5) : _C.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isFav
                  ? _C.star.withValues(alpha: 0.1)
                  : _C.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                        ),
                        child: SizedBox(
                          width: 80, height: 90,
                          child: imgUrl != null
                              ? Image.network(imgUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: clr.withValues(alpha: 0.1),
                                    child: Center(child: Icon(ico, color: clr, size: 30)),
                                  ))
                              : Container(
                                  color: clr.withValues(alpha: 0.1),
                                  child: Center(child: Icon(ico, color: clr, size: 30)),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 12, hasBadge ? 90 : 46, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: clr,
                                      height: 1.25),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              if (breadcrumbPill != null) ...[
                                const SizedBox(height: 6),
                                breadcrumbPill,
                              ],
                              const SizedBox(height: 6),
                              if (breadcrumbPill == null) ...[
                                _levelPill(icon: ico, label: t('level_$tName'), color: clr),
                                if (subCountPill != null) ...[
                                  const SizedBox(height: 6),
                                  subCountPill,
                                ],
                              ] else
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _levelPill(icon: ico, label: t('level_$tName'), color: clr),
                                    if (subCountPill != null) subCountPill,
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._buildBadgeStarOverlay(
                  isPic: isPic,
                  isMyLoc: isMyLoc,
                  type: tName,
                  id: id,
                  raw: item,
                ),
              ],
            ),
            _buildActivityFooter(cachedActivity),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFooter(_LastActivity? activity) {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: const Border(top: BorderSide(color: _C.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: activity == null
          ? Shimmer.fromColors(
              baseColor: const Color(0xFFBAE6FD),
              highlightColor: const Color(0xFFE0F2FE),
              period: const Duration(milliseconds: 1200),
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: _activityChip(
                    icon : Icons.search_rounded,
                    color: const Color(0xFF0EA5E9),
                    label: t('temuan_terakhir'),
                    value: _formatDate(activity.lastTemuan),
                  ),
                ),
                Container(
                    width: 1, height: 30, color: _C.border,
                    margin: const EdgeInsets.symmetric(horizontal: 10)),
                Expanded(
                  child: _activityChip(
                    icon : Icons.check_circle_outline_rounded,
                    color: const Color(0xFF10B981),
                    label: t('selesai_terakhir'),
                    value: _formatDate(activity.lastPenyelesaian),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _activityChip({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final bool isEmpty = value == '-';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 9.5, color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1)),
              const SizedBox(height: 1),
              Text(
                isEmpty ? t('belum_ada_aktivitas') : value,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isEmpty ? Colors.grey.shade400 : _C.textDark,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocSearchResult {
  final String  id;
  final String  name;
  final String  type;
  final int     level;
  final String? imgUrl;
  final String? breadcrumb;
  final Map<String, dynamic> raw;
  const _LocSearchResult({
    required this.id, required this.name, required this.type,
    required this.level, this.imgUrl, this.breadcrumb, required this.raw,
  });
}