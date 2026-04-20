import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../shared/code/qr_generator_screen.dart';

// ── Model aktivitas terakhir ──────────────────────────────────────────────────
class _LastActivity {
  final DateTime? lastTemuan;
  final DateTime? lastPenyelesaian;
  const _LastActivity({this.lastTemuan, this.lastPenyelesaian});
}

class _UserLastLocation {
  final int? lastTemuanLokasiId;
  final int? lastTemuanUnitId;
  final int? lastTemuanSubunitId;
  final int? lastTemuanAreaId;
  final int? lastSelesaiLokasiId;
  final int? lastSelesaiUnitId;
  final int? lastSelesaiSubunitId;
  final int? lastSelesaiAreaId;

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

  bool isLastTemuan(String levelType, int levelId) {
    switch (levelType) {
      case 'lokasi':  return lastTemuanLokasiId   == levelId;
      case 'unit':    return lastTemuanUnitId      == levelId;
      case 'subunit': return lastTemuanSubunitId   == levelId;
      case 'area':    return lastTemuanAreaId      == levelId;
      default:        return false;
    }
  }

  bool isLastSelesai(String levelType, int levelId) {
    switch (levelType) {
      case 'lokasi':  return lastSelesaiLokasiId   == levelId;
      case 'unit':    return lastSelesaiUnitId     == levelId;
      case 'subunit': return lastSelesaiSubunitId  == levelId;
      case 'area':    return lastSelesaiAreaId     == levelId;
      default:        return false;
    }
  }
}

// ── Warna tema ────────────────────────────────────────────────────────────────
class _C {
  static const primary     = Color(0xFF0EA5E9);
  static const primaryDark = Color(0xFF0369A1);
  static const primaryLight= Color(0xFFE0F2FE);
  static const bg          = Color(0xFFF0F9FF);
  static const card        = Colors.white;
  static const textDark    = Color(0xFF0C4A6E);
  static const textGrey    = Color(0xFF64748B);
  static const border      = Color(0xFFBAE6FD);
  static const star        = Color(0xFFF59E0B);
  // Shimmer colors
  static const shimmerBase = Color(0xFFE8F4FD);
  static const shimmerHigh = Color(0xFFFFFFFF);
}

// ── Semua teks multibahasa terpusat ──────────────────────────────────────────
class _AppTexts {
  static const Map<String, Map<String, String>> _data = {
    'ID': {
      // Location Screen
      'cari'                      : 'Cari',
      'lokasi_saya'               : 'Lokasi Saya',
      'sublokasi'                 : 'Sublokasi',
      'detail'                    : 'Lihat Detail',
      'kategori'                  : 'Kategori',
      'tanpa_kategori'            : 'Tanpa Kategori',
      'pic_kosong'                : 'Belum ada PIC',
      'temuan_terakhir'           : 'Temuan terakhir',
      'selesai_terakhir'          : 'Selesai terakhir',
      'belum_ada_aktivitas'       : 'Belum ada aktivitas',
      'favorit'                   : 'Favorit',
      'badge_temuan_saya'         : '📍 Temuan Terakhir Anda',
      'badge_selesai_saya'        : '✅ Penyelesaian Terakhir Anda',
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
      // Bottom Sheet
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
    },
    'EN': {
      // Location Screen
      'cari'                      : 'Search',
      'lokasi_saya'               : 'My Location',
      'sublokasi'                 : 'Sub-locations',
      'detail'                    : 'View Detail',
      'kategori'                  : 'Category',
      'tanpa_kategori'            : 'No Category',
      'pic_kosong'                : 'No PIC',
      'temuan_terakhir'           : 'Last finding',
      'selesai_terakhir'          : 'Last resolved',
      'belum_ada_aktivitas'       : 'No activity yet',
      'favorit'                   : 'Favorites',
      'badge_temuan_saya'         : '📍 Your Last Finding',
      'badge_selesai_saya'        : '✅ Your Last Resolution',
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
      // Bottom Sheet
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
    },
    'ZH': {
      // Location Screen
      'cari'                      : '搜索',
      'lokasi_saya'               : '我的位置',
      'sublokasi'                 : '子位置',
      'detail'                    : '查看详情',
      'kategori'                  : '类别',
      'tanpa_kategori'            : '无类别',
      'pic_kosong'                : '没有负责人',
      'temuan_terakhir'           : '最近发现',
      'selesai_terakhir'          : '最近完成',
      'belum_ada_aktivitas'       : '暂无活动',
      'favorit'                   : '收藏',
      'badge_temuan_saya'         : '📍 您的最近发现',
      'badge_selesai_saya'        : '✅ 您的最近完成',
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
      // Bottom Sheet
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
    },
  };

  /// Ambil teks berdasarkan lang dan key.
  /// Fallback: ID → key itu sendiri
  static String get(String lang, String key) {
    return _data[lang]?[key] ?? _data['ID']?[key] ?? key;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LocationScreen
// ══════════════════════════════════════════════════════════════════════════════
class LocationScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final String userRole;
  final int? userUnitId;
  final int? userLokasiId;

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

class _LocationScreenState extends State<LocationScreen> {
  final _supabase = Supabase.instance.client;

  int  _currentLevel = 0;
  bool _isLoading    = true;
  List<dynamic> _currentData  = [];
  List<dynamic> _filteredData = [];
  String _searchQuery = '';
  bool   _isLokasiSaya = false;

  List<Map<String, dynamic>> _navHistory     = [];
  Map<String, dynamic>?      _currentParentData;

  // Favorit
  final Set<String> _favoritSet = {};

  // Cache aktivitas terakhir — di-fetch SEKALIGUS saat data masuk
  final Map<String, _LastActivity> _activityCache = {};
  _UserLastLocation _userLastLocation = const _UserLastLocation();

  Map<String, dynamic>? _suggestTemuan;
  Map<String, dynamic>? _suggestSelesai;

  // My Location IDs
  int? _myLocationLokasiId;
  int? _myLocationUnitId;
  int? _myLocationSubunitId;
  int? _myLocationAreaId;

  // Helper teks
  String t(String key) => _AppTexts.get(widget.lang, key);

  String? get _currentUserId => _supabase.auth.currentUser?.id;
  bool get _hasFullAccess =>
      widget.isProMode || widget.userRole == 'Eksekutif';

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // Jalankan semua init secara PARALEL agar lebih cepat
    _initAll();
  }

  Future<void> _initAll() async {
    // Parallel: favorit + my location + user last location + data utama
    await Future.wait([
      _loadFavorit(),
      _loadMyLocationData(),
      _loadUserLastLocation(),
    ]);
    // Fetch data utama SETELAH metadata siap
    // sehingga suggest & favorit langsung muncul tanpa reload
    await _fetchData();
  }

  // ── Favorit ───────────────────────────────────────────────────────────────
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
            lastTemuanLokasiId  : r['last_temuan_lokasi_id'],
            lastTemuanUnitId    : r['last_temuan_unit_id'],
            lastTemuanSubunitId : r['last_temuan_subunit_id'],
            lastTemuanAreaId    : r['last_temuan_area_id'],
            lastSelesaiLokasiId : r['last_selesai_lokasi_id'],
            lastSelesaiUnitId   : r['last_selesai_unit_id'],
            lastSelesaiSubunitId: r['last_selesai_subunit_id'],
            lastSelesaiAreaId   : r['last_selesai_area_id'],
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
      final rawId = item['id_$tName'];
      if (rawId == null) continue;
      final id = rawId is int ? rawId : int.tryParse(rawId.toString());
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

  bool _isFavorit(String levelType, int levelId) =>
      _favoritSet.contains('$levelType:$levelId');

  Future<void> _toggleFavorit(String levelType, int levelId) async {
    if (_currentUserId == null) return;
    final key    = '$levelType:$levelId';
    final wasFav = _favoritSet.contains(key);

    setState(() {
      if (wasFav) { _favoritSet.remove(key); } else { _favoritSet.add(key); }
      // Re-sort setelah toggle favorit
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
      // Rollback
      setState(() {
        if (wasFav) { _favoritSet.add(key); } else { _favoritSet.remove(key); }
        _onSearch(_searchQuery);
      });
      debugPrint('Toggle favorit error: $e');
    }
  }

  // ── Aktivitas terakhir — di-fetch SEKALIGUS (batch) ──────────────────────
  /// Fetch aktivitas untuk SEMUA item sekaligus setelah list tersedia.
  /// Hasilnya disimpan ke cache, lalu setState agar card langsung update.
  Future<void> _prefetchAllActivities(
      String tName, List<dynamic> items) async {
    // Kumpulkan id yang belum ada di cache
    final toFetch = <int>[];
    for (final item in items) {
      final rawId = item['id_$tName'];
      if (rawId == null) continue;
      final id = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (id != null && !_activityCache.containsKey('$tName:$id')) {
        toFetch.add(id);
      }
    }
    if (toFetch.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    // Fetch paralel, max 5 request bersamaan untuk efisiensi
    const batchSize = 5;
    for (int i = 0; i < toFetch.length; i += batchSize) {
      final batch = toFetch.skip(i).take(batchSize).toList();
      await Future.wait(batch.map((id) => _fetchActivity(tName, id)));
    }
    if (mounted) setState(() {});
  }

  Future<_LastActivity> _fetchActivity(String levelType, int levelId) async {
    final key = '$levelType:$levelId';
    if (_activityCache.containsKey(key)) return _activityCache[key]!;
    try {
      final rows = await _supabase.rpc('get_location_last_activity', params: {
        'p_level_type': levelType,
        'p_level_id'  : levelId,
      });
      final row = (rows as List).isNotEmpty ? rows[0] : null;
      final activity = _LastActivity(
        lastTemuan: row?['last_temuan_at'] != null
            ? DateTime.tryParse(row['last_temuan_at']) : null,
        lastPenyelesaian: row?['last_penyelesaian_at'] != null
            ? DateTime.tryParse(row['last_penyelesaian_at']) : null,
      );
      _activityCache[key] = activity;
      return activity;
    } catch (e) {
      _activityCache[key] = const _LastActivity();
      return const _LastActivity();
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }

  // ── Fetch data level ──────────────────────────────────────────────────────
  Future<void> _fetchData({int? parentId, Map<String, dynamic>? parentData}) async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> data = [];
      final tName = _getLevelName();

      if (_currentLevel == 0) {
        if (_isLokasiSaya && _myLocationLokasiId != null) {
          data = await _supabase.from('lokasi').select(
            'id_lokasi, nama_lokasi, gambar_lokasi, deskripsi_lokasi, '
            'kategori, is_star, id_pic, User!id_pic(nama), unit(id_unit), qrcode')
            .eq('id_lokasi', _myLocationLokasiId!);
        } else if (!_isLokasiSaya) {
          data = await _supabase.from('lokasi').select(
            'id_lokasi, nama_lokasi, gambar_lokasi, deskripsi_lokasi, '
            'kategori, is_star, id_pic, User!id_pic(nama), unit(id_unit), qrcode');
        }
      } else if (_currentLevel == 1) {
        if (_isLokasiSaya && _myLocationUnitId != null) {
          data = await _supabase.from('unit').select(
            'id_unit, nama_unit, gambar_unit, deskripsi_unit, '
            'kategori, is_star, id_pic, User!id_pic(nama), subunit(id_subunit), qrcode')
            .eq('id_lokasi', parentId!)
            .eq('id_unit', _myLocationUnitId!);
        } else if (!_hasFullAccess && widget.userUnitId != null && !_isLokasiSaya) {
          data = await _supabase.from('unit').select(
            'id_unit, nama_unit, gambar_unit, deskripsi_unit, '
            'kategori, is_star, id_pic, User!id_pic(nama), subunit(id_subunit), qrcode')
            .eq('id_lokasi', parentId!)
            .eq('id_unit', widget.userUnitId!);
        } else if (!_isLokasiSaya) {
          data = await _supabase.from('unit').select(
            'id_unit, nama_unit, gambar_unit, deskripsi_unit, '
            'kategori, is_star, id_pic, User!id_pic(nama), subunit(id_subunit), qrcode')
            .eq('id_lokasi', parentId!);
        }
      } else if (_currentLevel == 2) {
        if (_isLokasiSaya && _myLocationSubunitId != null) {
          data = await _supabase.from('subunit').select(
            'id_subunit, nama_subunit, gambar_subunit, deskripsi_subunit, '
            'kategori, is_star, id_pic, User!id_pic(nama), area(id_area), qrcode')
            .eq('id_unit', parentId!)
            .eq('id_subunit', _myLocationSubunitId!);
        } else if (!_isLokasiSaya) {
          data = await _supabase.from('subunit').select(
            'id_subunit, nama_subunit, gambar_subunit, deskripsi_subunit, '
            'kategori, is_star, id_pic, User!id_pic(nama), area(id_area), qrcode')
            .eq('id_unit', parentId!);
        }
      } else if (_currentLevel == 3) {
        if (_isLokasiSaya && _myLocationAreaId != null) {
          data = await _supabase.from('area').select(
            'id_area, nama_area, gambar_area, deskripsi_area, '
            'kategori, is_star, id_pic, User!id_pic(nama), qrcode')
            .eq('id_subunit', parentId!)
            .eq('id_area', _myLocationAreaId!);
        } else if (!_isLokasiSaya) {
          data = await _supabase.from('area').select(
            'id_area, nama_area, gambar_area, deskripsi_area, '
            'kategori, is_star, id_pic, User!id_pic(nama), qrcode')
            .eq('id_subunit', parentId!);
        }
      }

      if (mounted) {
        setState(() {
          _currentData       = data;
          _currentParentData = parentData;
          _isLoading         = false;
          _onSearch(_searchQuery);
        });
        _updateSuggestItems();
        // Pre-fetch semua aktivitas sekaligus (background)
        _prefetchAllActivities(tName, data);
      }
    } catch (e) {
      debugPrint('Error Load Location: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Search & sort ─────────────────────────────────────────────────────────
  void _onSearch(String query) {
    _searchQuery = query.toLowerCase();
    final tName  = _getLevelName();
    setState(() {
      _filteredData = _currentData.where((item) {
        final nama = item['nama_$tName'];
        if (nama == null) return false;
        return nama.toString().toLowerCase().contains(_searchQuery);
      }).toList();

      _filteredData.sort((a, b) {
        final rawIdA = a['id_$tName'];
        final rawIdB = b['id_$tName'];
        final idA = rawIdA is int ? rawIdA : int.tryParse(rawIdA?.toString() ?? '') ?? 0;
        final idB = rawIdB is int ? rawIdB : int.tryParse(rawIdB?.toString() ?? '') ?? 0;

        final favA = _isFavorit(tName, idA) ? 0 : 1;
        final favB = _isFavorit(tName, idB) ? 0 : 1;
        if (favA != favB) return favA.compareTo(favB);

        return (a['nama_$tName'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['nama_$tName'] ?? '').toString().toLowerCase());
      });
    });
  }

  String _getLevelName([int? level]) =>
      ['lokasi', 'unit', 'subunit', 'area'][level ?? _currentLevel];

  // ── Navigasi ──────────────────────────────────────────────────────────────
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailBottomSheet(
        level: _currentLevel - 1,
        data : _currentParentData!,
        lang : widget.lang,
      ),
    );
  }

  void _showDetailModalForItem(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailBottomSheet(
        level: _currentLevel,
        data : item,
        lang : widget.lang,
      ),
    );
  }

  void _toggleLokasiSaya() {
    setState(() => _isLokasiSaya = !_isLokasiSaya);
    _fetchData(
      parentId  : _navHistory.isNotEmpty ? _navHistory.last['id'] : null,
      parentData: _currentParentData,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
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
          if (!_isLoading && _currentLevel > 0) _buildSublokasiCount(),
          Expanded(child: _isLoading ? _buildShimmerList() : _buildList()),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _C.primaryDark, size: 20),
        onPressed: _goBack,
      ),
      title: Text(title,
          style: const TextStyle(
              color: _C.textDark, fontWeight: FontWeight.bold, fontSize: 17)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: '${t('cari')} ${_getLevelName()}',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle:
                            const TextStyle(color: _C.textGrey, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _toggleLokasiSaya,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _isLokasiSaya ? _C.primary : Colors.white,
                border: Border.all(
                    color: _isLokasiSaya ? _C.primary : _C.border),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isLokasiSaya
                    ? [BoxShadow(
                        color: _C.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))]
                    : [],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.my_location_rounded,
                      size: 15,
                      color: _isLokasiSaya ? Colors.white : _C.primary),
                  const SizedBox(width: 5),
                  Text(
                    t('lokasi_saya'),
                    style: TextStyle(
                      color: _isLokasiSaya ? Colors.white : _C.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer List ──────────────────────────────────────────────────────────
  /// Widget shimmer yang ditampilkan selama loading data
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor  : _C.shimmerBase,
      highlightColor: _C.shimmerHigh,
      period: const Duration(milliseconds: 1200),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        // Tampilkan 5 card shimmer
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
          // Baris utama
          Row(
            children: [
              // Placeholder gambar
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
              // Placeholder teks
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _C.shimmerBase,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Sub-info
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
              // Placeholder bintang
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
          // Footer aktivitas
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

  // ── Parent Card ───────────────────────────────────────────────────────────
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

  // ── Sublokasi count ───────────────────────────────────────────────────────
  Widget _buildSublokasiCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.layers_rounded,
                color: _C.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            '${t('sublokasi')} (${_filteredData.length})',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _C.textDark, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Suggest Section ───────────────────────────────────────────────────────
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
                      fontWeight: FontWeight.w500),
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
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) return const SizedBox.shrink();

    final name   = item['nama_$tName']?.toString() ?? '';
    final imgUrl = item['gambar_$tName'] as String?;
    final isFav  = _isFavorit(tName, id);

    return GestureDetector(
      onTap: () {
        if (_currentLevel == 3) return;
        setState(() {
          _navHistory.add({
            'level': _currentLevel, 'id': id,
            'name': name, 'data': item,
          });
          _currentLevel++;
          _searchQuery = '';
        });
        _fetchData(parentId: id, parentData: item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isTemuan
                ? const Color(0xFF0EA5E9).withValues(alpha: 0.5)
                : const Color(0xFF10B981).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isTemuan
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFF10B981))
                  .withValues(alpha: 0.1),
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
                color: _C.primaryLight,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
                image: imgUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imgUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imgUrl == null
                  ? const Center(
                      child: Icon(Icons.domain_rounded,
                          color: _C.primary, size: 22))
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
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: _C.textDark),
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

  // ── List ──────────────────────────────────────────────────────────────────
  Widget _buildList() {
    if (_isLokasiSaya && _filteredData.isEmpty) {
      return _buildMyLocationEmptyState();
    }
    if (_filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              t('tidak_ada_data'),
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filteredData.length,
      itemBuilder: (ctx, i) => _buildLocationCard(_filteredData[i]),
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

  // ── Location Card ─────────────────────────────────────────────────────────
  Widget _buildLocationCard(Map<String, dynamic> item) {
    final tName = _getLevelName();
    final rawId = item['id_$tName'];
    if (rawId == null) return const SizedBox.shrink();
    final id = rawId is int ? rawId : int.tryParse(rawId.toString());
    if (id == null) return const SizedBox.shrink();

    final name      = item['nama_$tName']?.toString() ?? '';
    final imgUrl    = item['gambar_$tName'] as String?;
    final isFav     = _isFavorit(tName, id);
    final childName = _currentLevel < 3
        ? ['unit', 'subunit', 'area'][_currentLevel] : '';
    final childCount= _currentLevel < 3
        ? (item[childName] as List?)?.length ?? 0 : 0;

    // Ambil dari cache (sudah di-prefetch)
    final cachedActivity = _activityCache['$tName:$id'];

    return GestureDetector(
      onTap: () {
        if (_currentLevel == 3) return;
        setState(() {
          _navHistory.add({
            'level': _currentLevel, 'id': id,
            'name': name, 'data': item,
          });
          _currentLevel++;
          _searchQuery = '';
        });
        _fetchData(parentId: id, parentData: item);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFav
                ? _C.star.withValues(alpha: 0.5) : _C.border,
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
            // Baris utama
            Row(
              children: [
                Container(
                  width: 80, height: 90,
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                    image: imgUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imgUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imgUrl == null
                      ? const Center(
                          child: Icon(Icons.domain_rounded,
                              color: _C.primary, size: 30))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _showDetailModalForItem(item),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _C.textDark),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.info_outline_rounded,
                                  size: 15, color: _C.primary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (_currentLevel < 3)
                          Row(
                            children: [
                              const Icon(Icons.account_tree_outlined,
                                  size: 13, color: _C.textGrey),
                              const SizedBox(width: 4),
                              Text(
                                '$childCount ${t('sublokasi')}',
                                style: const TextStyle(
                                    fontSize: 11, color: _C.textGrey,
                                    fontWeight: FontWeight.w500),
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
                      isFav
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFav ? _C.star : Colors.grey.shade300,
                      size: 26,
                    ),
                    onPressed: () => _toggleFavorit(tName, id),
                  ),
                ),
              ],
            ),
            // ── Footer aktivitas (dari cache, tidak perlu FutureBuilder) ──
            _buildActivityFooter(cachedActivity),
          ],
        ),
      ),
    );
  }

  /// Footer aktivitas yang menampilkan data dari cache langsung.
  /// Jika cache belum ada, tampilkan shimmer kecil.
  Widget _buildActivityFooter(_LastActivity? activity) {
    return Container(
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: const Border(top: BorderSide(color: _C.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: activity == null
          // Shimmer kecil saat aktivitas belum ada di cache
          ? Shimmer.fromColors(
              baseColor     : _C.shimmerBase,
              highlightColor: _C.shimmerHigh,
              period: const Duration(milliseconds: 1200),
              child: Container(
                height: 16,
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
                    width: 1, height: 28, color: _C.border,
                    margin: const EdgeInsets.symmetric(horizontal: 8)),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 9, color: color,
                      fontWeight: FontWeight.w600)),
              Text(
                value == '-' ? t('belum_ada_aktivitas') : value,
                style: TextStyle(
                    fontSize: 9,
                    color: value == '-'
                        ? Colors.grey.shade400 : _C.textDark,
                    fontWeight: FontWeight.w500),
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

// ══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET DETAIL
// ══════════════════════════════════════════════════════════════════════════════
class _DetailBottomSheet extends StatefulWidget {
  final int level;
  final Map<String, dynamic> data;
  final String lang;

  const _DetailBottomSheet({
    required this.level,
    required this.data,
    this.lang = 'ID',
  });

  @override
  State<_DetailBottomSheet> createState() => _DetailBottomSheetState();
}

class _DetailBottomSheetState extends State<_DetailBottomSheet> {
  int    _tabIndex = 0;
  String _searchMember = '';
  final TextEditingController _searchMemberController =
      TextEditingController();
  late Future<List<dynamic>> _membersFuture;

  // Gunakan _AppTexts terpusat
  String t(String key) => _AppTexts.get(widget.lang, key);

  @override
  void initState() {
    super.initState();
    final tName = ['lokasi', 'unit', 'subunit', 'area'][widget.level];
    _membersFuture = _fetchMembersData(widget.data['id_$tName']);
  }

  Future<List<dynamic>> _fetchMembersData(int idValue) async {
    final s = Supabase.instance.client;
    const q = 'nama, gambar_user, jabatan(nama_jabatan)';
    if (widget.level == 0) {
      return await s.from('User').select(q).eq('id_lokasi', idValue);
    } else if (widget.level == 1) {
      return await s.from('User').select(q).eq('id_unit', idValue);
    } else if (widget.level == 2) {
      final d = await s.from('subunit').select('id_unit')
          .eq('id_subunit', idValue).maybeSingle();
      if (d?['id_unit'] == null) return [];
      return await s.from('User').select(q).eq('id_unit', d!['id_unit']);
    } else {
      final d = await s.from('area').select('id_unit')
          .eq('id_area', idValue).maybeSingle();
      if (d?['id_unit'] == null) return [];
      return await s.from('User').select(q).eq('id_unit', d!['id_unit']);
    }
  }

  @override
  void dispose() {
    _searchMemberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tName    = ['lokasi', 'unit', 'subunit', 'area'][widget.level];
    final itemName = widget.data['nama_$tName'] as String;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F9FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 45, height: 5,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(itemName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    letterSpacing: 0.5, color: _C.textDark)),
          ),
          const SizedBox(height: 14),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTabItem(t('info'), 0),
                _buildTabItem(t('anggota'), 1),
                _buildTabItem(t('qrcode'), 2),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _buildInfoTab(tName),
                _buildAnggotaTab(widget.data['id_$tName']),
                _buildQrTab(tName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: active ? _C.primary : Colors.transparent,
                  width: 3),
            ),
          ),
          child: Center(
            child: Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? _C.textDark : Colors.grey.shade400)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(String tName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ],
              image: widget.data['gambar_$tName'] != null
                  ? DecorationImage(
                      image: NetworkImage(widget.data['gambar_$tName']),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: widget.data['gambar_$tName'] == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported_outlined,
                          size: 50, color: Colors.black12),
                      const SizedBox(height: 8),
                      Text(t('tidak_ada_gambar'),
                          style: const TextStyle(
                              color: Colors.black26,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  icon: Icons.category_rounded,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: Colors.orange,
                  label: t('kategori'),
                  value: widget.data['kategori'] ?? '-',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _infoRow(
                  icon: Icons.person_pin_rounded,
                  iconBg: const Color(0xFFF0FDF4),
                  iconColor: Colors.green,
                  label: t('pic'),
                  value: (widget.data['User'] != null)
                      ? widget.data['User']['nama'] : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(t('deskripsi'),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: _C.textDark)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Text(
              widget.data['deskripsi_$tName'] ?? t('tdk_ada'),
              style: const TextStyle(
                  fontSize: 14, height: 1.6, color: _C.textGrey),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: _C.textGrey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14,
                      color: _C.textDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnggotaTab(int idValue) {
    Color roleColor(String r) {
      switch (r.toLowerCase()) {
        case 'eksekutif': return const Color(0xFF6B21A8);
        case 'manager':   return const Color(0xFF1E3A8A);
        case 'kasie':     return const Color(0xFF047857);
        default:          return _C.primary;
      }
    }
    Color roleBg(String r) {
      switch (r.toLowerCase()) {
        case 'eksekutif': return const Color(0xFFF3E8FF);
        case 'manager':   return const Color(0xFFDBEAFE);
        case 'kasie':     return const Color(0xFFD1FAE5);
        default:          return _C.primaryLight;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _C.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchMemberController,
                    onChanged: (v) =>
                        setState(() => _searchMember = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: t('cari_anggota'),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      hintStyle: const TextStyle(
                          color: _C.textGrey, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _membersFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                // Shimmer untuk tab anggota
                return Shimmer.fromColors(
                  baseColor     : _C.shimmerBase,
                  highlightColor: _C.shimmerHigh,
                  period: const Duration(milliseconds: 1200),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 6,
                    itemBuilder: (_, __) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                );
              }

              final all = snap.data ?? [];
              var filtered = all
                  .where((u) => u['nama']
                      .toString()
                      .toLowerCase()
                      .contains(_searchMember))
                  .toList();

              const prio = {
                'eksekutif': 1, 'manager': 2, 'kasie': 3, 'staff': 4
              };
              filtered.sort((a, b) {
                final ra = a['jabatan']?['nama_jabatan']
                        ?.toString().toLowerCase() ?? 'staff';
                final rb = b['jabatan']?['nama_jabatan']
                        ?.toString().toLowerCase() ?? 'staff';
                return (prio[ra] ?? 5).compareTo(prio[rb] ?? 5);
              });

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off_rounded,
                          size: 56, color: Colors.grey.shade200),
                      const SizedBox(height: 10),
                      Text(t('kosong'),
                          style: const TextStyle(
                              color: _C.textGrey,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final user   = filtered[i];
                  final role   = user['jabatan']?['nama_jabatan'] ?? 'Staff';
                  final imgUrl = user['gambar_user'] as String?;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: roleColor(role), width: 1.5),
                        ),
                        child: CircleAvatar(
                          backgroundColor: roleBg(role),
                          backgroundImage: (imgUrl != null && imgUrl.isNotEmpty)
                              ? NetworkImage(imgUrl) : null,
                          child: (imgUrl == null || imgUrl.isEmpty)
                              ? Text(user['nama'][0].toUpperCase(),
                                  style: TextStyle(
                                      color: roleColor(role),
                                      fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                      title: Text(user['nama'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13,
                              color: _C.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleBg(role),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: roleColor(role)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(role,
                              style: TextStyle(
                                  color: roleColor(role),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQrTab(String tName) {
    final qrData = widget.data['qrcode'] as String?;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (qrData != null && qrData.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _C.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220),
              )
            else
              Column(
                children: [
                  Icon(Icons.qr_code_scanner,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(t('qr_not_generated'),
                      style: const TextStyle(
                          fontSize: 15, color: _C.textGrey,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(t('generate_qr')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QRGeneratorScreen(
                            lang     : widget.lang,
                            levelName: tName,
                            levelId  : widget.data['id_$tName'],
                            itemName : widget.data['nama_$tName'],
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        final refreshed = await Supabase.instance.client
                            .from(tName)
                            .select('*, User!id_pic(nama)')
                            .eq('id_$tName', widget.data['id_$tName'])
                            .single();
                        setState(() => widget.data.addAll(refreshed));
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}