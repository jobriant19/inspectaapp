import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/jabatan_helper.dart';
import '../../leaderboard/user_profile_modal.dart';
import 'specific_location_indicator.dart';

class _C {
  static const primary      = Color(0xFF0EA5E9);
  static const primaryLight = Color(0xFFE0F2FE);
  static const textDark     = Color(0xFF0C4A6E);
  static const textGrey     = Color(0xFF64748B);
}

const Color _activeBlue = Color(0xFF1D72F3);

const List<Color> _levelColors = [
  Color(0xFF10B981), Color(0xFF6366F1), Color(0xFFFBBF24), Color(0xFFF472B6),
];
const List<IconData> _levelIcons = [
  Icons.location_city_rounded, Icons.business_rounded, Icons.layers_rounded, Icons.place_rounded,
];
const List<String> _levelKeys = ['lokasi', 'unit', 'subunit', 'area'];

const Map<String, String> _subSelectMap = {
  'unit'   : 'id_unit, nama_unit, gambar_unit, deskripsi_unit, is_star, '
             'id_pic, User!id_pic(nama, gambar_user), subunit(id_subunit), id_lokasi, lokasi(nama_lokasi), qrcode',
  'subunit': 'id_subunit, nama_subunit, gambar_subunit, deskripsi_subunit, is_star, '
             'id_pic, User!id_pic(nama, gambar_user), area(id_area), id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi), qrcode',
  'area'   : 'id_area, nama_area, gambar_area, deskripsi_area, is_star, '
             'id_pic, User!id_pic(nama, gambar_user), id_subunit, id_unit, id_lokasi, '
             'subunit(nama_subunit), unit(nama_unit), lokasi(nama_lokasi), qrcode',
};

class _DetailTexts {
  static const Map<String, Map<String, String>> _data = {
    'ID': {
      'info': 'Info', 'anggota': 'Anggota', 'cari_anggota': 'Cari anggota...',
      'pic': 'Penanggung Jawab', 'deskripsi': 'Deskripsi',
      'tdk_ada': 'Tidak ada deskripsi tersedia', 'kosong': 'Belum ada anggota',
      'generate_qr': 'Buat Kode QR', 'qr_not_generated': 'Kode QR belum dibuat.',
      'qrcode': 'QR Code', 'tidak_ada_gambar': 'Tidak ada gambar', 'kategori': 'Kategori',
      'level_lokasi': 'Lokasi', 'level_unit': 'Unit', 'level_subunit': 'Subunit', 'level_area': 'Area',
      'ringkasan_sublokasi': 'Ringkasan Bagian Lokasi',
      'pilih_kategori': 'Pilih Unit, Subunit, atau Area di atas untuk melihat daftar',
      'sub_kosong': 'Data tidak ditemukan',
      'qr_active_title': 'QR Code Aktif',
      'qr_scan_hint': 'Tunjukkan kode ini untuk verifikasi lokasi',
      'qr_empty_title': 'QR Code Belum Tersedia',
      'anggota_kosong_title': 'Belum Ada Anggota',
      'anggota_kosong_subtitle': 'Saat ini belum ada anggota yang terdaftar di lokasi ini',
      'pic_kosong': 'Belum ada PIC',
      'reset_pencarian': 'Reset Pencarian',
      'anggota_tidak_ditemukan_title': 'Anggota Tidak Ditemukan',
      'anggota_tidak_ditemukan_subtitle': 'Coba gunakan kata kunci lain atau reset pencarian Anda.',
      'pilih_kategori_subtitle': 'Data akan muncul di sini setelah Anda memilih salah satu kategori.',
      'sub_kosong_subtitle': 'Belum ada data yang tersedia untuk kategori ini.',
    },
    'EN': {
      'info': 'Info', 'anggota': 'Members', 'cari_anggota': 'Search member...',
      'pic': 'Person in Charge', 'deskripsi': 'Description',
      'tdk_ada': 'No description available', 'kosong': 'No members found',
      'generate_qr': 'Generate QR Code', 'qr_not_generated': 'QR Code has not been generated yet.',
      'qrcode': 'QR Code', 'tidak_ada_gambar': 'No image available', 'kategori': 'Category',
      'level_lokasi': 'Location', 'level_unit': 'Unit', 'level_subunit': 'Subunit', 'level_area': 'Area',
      'ringkasan_sublokasi': 'Sub-Location Summary',
      'pilih_kategori': 'Select Unit, Subunit, or Area above to view the list',
      'sub_kosong': 'No data found',
      'qr_active_title': 'QR Code Active',
      'qr_scan_hint': 'Show this code for location verification',
      'qr_empty_title': 'QR Code Not Available Yet',
      'anggota_kosong_title': 'No Members Yet',
      'anggota_kosong_subtitle': 'There are currently no members registered at this location',
      'pic_kosong': 'No PIC yet',
      'reset_pencarian': 'Reset Search',
      'anggota_tidak_ditemukan_title': 'No Members Found',
      'anggota_tidak_ditemukan_subtitle': 'Try using different keywords or reset your search.',
      'pilih_kategori_subtitle': 'Data will appear here once you select a category.',
      'sub_kosong_subtitle': 'No data available for this category yet.',
    },
    'ZH': {
      'info': '信息', 'anggota': '成员', 'cari_anggota': '搜索成员...',
      'pic': '负责人', 'deskripsi': '描述',
      'tdk_ada': '没有可用描述', 'kosong': '未找到成员',
      'generate_qr': '生成二维码', 'qr_not_generated': '二维码尚未生成。',
      'qrcode': '二维码', 'tidak_ada_gambar': '没有图片', 'kategori': '类别',
      'level_lokasi': '位置', 'level_unit': '单位', 'level_subunit': '子单位', 'level_area': '区域',
      'ringkasan_sublokasi': '子位置摘要',
      'pilih_kategori': '请选择上方的单位、子单位或区域以查看列表',
      'sub_kosong': '未找到数据',
      'qr_active_title': '二维码已激活',
      'qr_scan_hint': '出示此二维码以验证位置',
      'qr_empty_title': '二维码尚未生成',
      'anggota_kosong_title': '暂无成员',
      'anggota_kosong_subtitle': '该位置目前没有注册成员',
      'pic_kosong': '暂无负责人',
      'reset_pencarian': '重置搜索',
      'anggota_tidak_ditemukan_title': '未找到成员',
      'anggota_tidak_ditemukan_subtitle': '请尝试其他关键词或重置搜索。',
      'pilih_kategori_subtitle': '选择类别后，数据将显示在此处。',
      'sub_kosong_subtitle': '该类别暂无可用数据。',
    },
  };

  static String get(String lang, String key) => _data[lang]?[key] ?? _data['ID']?[key] ?? key;
}

class LocationFullscreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const LocationFullscreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                panEnabled: true,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationDetailScreen extends StatefulWidget {
  final int level;
  final Map<String, dynamic> data;
  final String lang;

  const LocationDetailScreen({
    super.key,
    required this.level,
    required this.data,
    this.lang = 'ID',
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  int _tabIndex = 0;
  String _searchMember = '';
  final TextEditingController _searchMemberController = TextEditingController();
  late Future<List<dynamic>> _membersFuture;
  Future<Map<String, int>>? _subCountsFuture;
  late Map<String, dynamic> _data;

  String? _selectedSubType;
  final Map<String, Future<List<dynamic>>> _subItemsCache = {};
  static const double _headerHeight = 112.0;

  int _subItemsPage = 1;
  static const int _subItemsPerPage = 5;
  int _membersPage = 1;
  static const int _membersPerPage = 8;

  static String? _cachedAppLogoUrl;
  static bool _appLogoFetched = false;

  String t(String key) => _DetailTexts.get(widget.lang, key);

  Color get _levelColor => _levelColors[widget.level];
  IconData get _levelIcon => _levelIcons[widget.level];

  @override
  void initState() {
    super.initState();
    _prefetchAppLogo();
    _data = widget.data;
    final tName = _levelKeys[widget.level];
    final idValue = _data['id_$tName'].toString();
    _membersFuture = _fetchMembersData(idValue);
    if (widget.level < 3) {
      _subCountsFuture = _fetchSubCounts(idValue);
      _subCountsFuture!.then((counts) {
        if (!mounted) return;
        const order = ['unit', 'subunit', 'area'];
        for (final type in order) {
          if (counts.containsKey(type)) {
            _onSubTypeTap(type);
            break;
          }
        }
      });
    }
  }

  Future<void> _prefetchAppLogo() async {
    if (_appLogoFetched) return; 
    try {
      final res = await Supabase.instance.client
          .from('app_info')
          .select('logo_url')
          .order('id')
          .limit(1)
          .maybeSingle();
      _cachedAppLogoUrl = res?['logo_url'] as String?;
      _appLogoFetched = true;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Prefetch app logo error: $e');
    }
  }

  Future<List<dynamic>> _fetchMembersData(String idValue) async {
    final s = Supabase.instance.client;
    const q = 'id_user, nama, gambar_user, id_jabatan, is_verificator, jabatan(nama_jabatan)';
    if (widget.level == 0) {
      return await s.from('User').select(q).eq('id_lokasi', idValue);
    } else if (widget.level == 1) {
      return await s.from('User').select(q).eq('id_unit', idValue);
    } else if (widget.level == 2) {
      final d = await s.from('subunit').select('id_unit').eq('id_subunit', idValue).maybeSingle();
      if (d?['id_unit'] == null) return [];
      return await s.from('User').select(q).eq('id_unit', d!['id_unit'].toString());
    } else {
      final d = await s.from('area').select('id_unit').eq('id_area', idValue).maybeSingle();
      if (d?['id_unit'] == null) return [];
      return await s.from('User').select(q).eq('id_unit', d!['id_unit'].toString());
    }
  }

  Future<Map<String, int>> _fetchSubCounts(String idValue) async {
    final s = Supabase.instance.client;
    final Map<String, int> counts = {};
    try {
      if (widget.level == 0) {
        final results = await Future.wait([
          s.from('unit').select('id_unit').eq('id_lokasi', idValue),
          s.from('subunit').select('id_subunit').eq('id_lokasi', idValue),
          s.from('area').select('id_area').eq('id_lokasi', idValue),
        ]);
        counts['unit']    = (results[0] as List).length;
        counts['subunit'] = (results[1] as List).length;
        counts['area']    = (results[2] as List).length;
      } else if (widget.level == 1) {
        final results = await Future.wait([
          s.from('subunit').select('id_subunit').eq('id_unit', idValue),
          s.from('area').select('id_area').eq('id_unit', idValue),
        ]);
        counts['subunit'] = (results[0] as List).length;
        counts['area']    = (results[1] as List).length;
      } else if (widget.level == 2) {
        final r = await s.from('area').select('id_area').eq('id_subunit', idValue);
        counts['area'] = (r as List).length;
      }
    } catch (e) {
      debugPrint('Fetch sub counts error: $e');
    }
    return counts;
  }

  Future<List<dynamic>> _fetchSubItems(String type) async {
    final s = Supabase.instance.client;
    const filterColumns = ['id_lokasi', 'id_unit', 'id_subunit'];
    final filterCol = filterColumns[widget.level];
    final idValue = _data['id_${_levelKeys[widget.level]}'].toString();
    final select = _subSelectMap[type]!;
    final rows = await s.from(type).select(select).eq(filterCol, idValue);
    return rows as List<dynamic>;
  }

  void _onSubTypeTap(String type) {
    setState(() {
      _subItemsPage = 1;
      if (_selectedSubType == type) {
        _selectedSubType = null;
      } else {
        _selectedSubType = type;
        _subItemsCache.putIfAbsent(type, () => _fetchSubItems(type));
      }
    });
  }

  @override
  void dispose() {
    _searchMemberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tName = _levelKeys[widget.level];
    final itemName = _data['nama_$tName'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _levelColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _levelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_levelIcon, size: 16, color: _levelColor),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                itemName.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _levelColor,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
            child: Row(
              children: [
                _buildTabItem(Icons.info_rounded, t('info'), 0),
                const SizedBox(width: 8),
                _buildTabItem(Icons.groups_rounded, t('anggota'), 1),
                const SizedBox(width: 8),
                _buildTabItem(Icons.qr_code_2_rounded, t('qrcode'), 2),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildInfoTab(tName),
          _buildAnggotaTab(_data['id_$tName']?.toString() ?? ''),
          _buildQrTab(tName),
        ],
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String title, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? _activeBlue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? _activeBlue : Colors.grey.shade300),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _activeBlue.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(String tName) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildTopInfoContent(tName)),
        if (widget.level < 3)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              height: _headerHeight,
              child: _buildStickyHeader(),
            ),
          ),
        if (widget.level < 3)
          SliverToBoxAdapter(child: _buildSubResultsArea()),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildTopInfoContent(String tName) {
    final picName = (_data['User'] != null) ? _data['User']['nama'] as String? : null;
    final hasPic  = picName != null && picName.isNotEmpty;
    final hasImage = _data['gambar_$tName'] != null;
    final desc     = _data['deskripsi_$tName'] as String?;
    final hasDesc  = desc != null && desc.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasImage
                ? () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black.withValues(alpha: 0.95),
                        transitionDuration: const Duration(milliseconds: 200),
                        reverseTransitionDuration: Duration.zero,
                        pageBuilder: (_, __, ___) => LocationFullscreenImageViewer(
                          imageUrl: _data['gambar_$tName'] as String,
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                gradient: hasImage
                    ? null
                    : LinearGradient(
                        colors: [_levelColor.withValues(alpha: 0.16), _levelColor.withValues(alpha: 0.04)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: hasImage ? null : Border.all(color: _levelColor.withValues(alpha: 0.25), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
                ],
                image: hasImage
                    ? DecorationImage(image: NetworkImage(_data['gambar_$tName']), fit: BoxFit.cover)
                    : null,
              ),
              child: hasImage
                  ? Stack(
                      children: [
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: _levelColor.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Icon(_levelIcon, size: 46, color: _levelColor),
                        ),
                        const SizedBox(height: 12),
                        Text(t('tidak_ada_gambar'),
                            style: GoogleFonts.poppins(color: _levelColor, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Icon(Icons.badge_rounded, size: 15, color: _levelColor),
              const SizedBox(width: 6),
              Text(t('pic'),
                  style: GoogleFonts.poppins(color: _levelColor, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          if (hasPic)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _levelColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _levelColor.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _levelColor.withValues(alpha: 0.18),
                    child: Icon(Icons.person_rounded, color: _levelColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(picName,
                        style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFBBF24).withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.person_off_rounded, size: 16, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t('pic_kosong'),
                        style: GoogleFonts.poppins(color: const Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          Row(
            children: [
              Icon(Icons.notes_rounded, size: 15, color: _levelColor),
              const SizedBox(width: 6),
              Text(t('deskripsi'),
                  style: GoogleFonts.poppins(color: _levelColor, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _levelColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _levelColor.withValues(alpha: 0.20)),
            ),
            child: Text(
              hasDesc ? desc : t('tdk_ada'),
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: FutureBuilder<Map<String, int>>(
        future: _subCountsFuture,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return Shimmer.fromColors(
              baseColor: const Color(0xFFBAE6FD),
              highlightColor: const Color(0xFFE0F2FE),
              period: const Duration(milliseconds: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 15, width: 150,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(3, (i) => Expanded(
                      child: Container(
                        height: 40,
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                  ),
                ],
              ),
            );
          }

          final counts = snap.data!;
          final types = ['unit', 'subunit', 'area'].where((tp) => counts.containsKey(tp)).toList();

          if (types.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: _C.primaryLight, borderRadius: BorderRadius.circular(7)),
                    child: const Icon(Icons.donut_small_rounded, color: _C.primary, size: 14),
                  ),
                  const SizedBox(width: 7),
                  Text(t('ringkasan_sublokasi'),
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1D72F3))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(types.length, (i) =>
                    _subTypeChip(types[i], counts[types[i]]!, isLast: i == types.length - 1)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _subTypeChip(String type, int count, {required bool isLast}) {
    final idx = _levelKeys.indexOf(type);
    final color = _levelColors[idx];
    final icon = _levelIcons[idx];
    final label = t('level_$type');
    final active = _selectedSubType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onSubTypeTap(type),
        child: Container(
          margin: EdgeInsets.only(right: isLast ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? color : Colors.grey.shade300),
            boxShadow: active
                ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? Colors.white : color),
              const SizedBox(width: 5),
              Text('$count',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: active ? Colors.white : Colors.black87)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubResultsArea() {
    if (_selectedSubType == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/team_illustration.png',
                width: 150, height: 150,
                errorBuilder: (_, __, ___) => Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: _levelColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(color: _levelColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(Icons.touch_app_rounded, size: 46, color: _levelColor.withValues(alpha: 0.55)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t('pilih_kategori'),
                style: GoogleFonts.poppins(color: _C.textDark, fontWeight: FontWeight.w700, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                t('pilih_kategori_subtitle'),
                style: GoogleFonts.poppins(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 11.5, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final subColor = _levelColors[_levelKeys.indexOf(_selectedSubType!)];
    final subIcon  = _levelIcons[_levelKeys.indexOf(_selectedSubType!)];

    return FutureBuilder<List<dynamic>>(
      future: _subItemsCache[_selectedSubType],
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFBAE6FD),
              highlightColor: const Color(0xFFE0F2FE),
              period: const Duration(milliseconds: 1200),
              child: Column(
                children: List.generate(3, (i) => Container(
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                )),
              ),
            ),
          );
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/team_illustration.png',
                    width: 140, height: 140,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: subColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                        border: Border.all(color: subColor.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Icon(subIcon, size: 42, color: subColor.withValues(alpha: 0.55)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(t('sub_kosong'),
                      style: GoogleFonts.poppins(color: _C.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(t('sub_kosong_subtitle'),
                      style: GoogleFonts.poppins(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 11.5, height: 1.5),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final totalPages = (items.length / _subItemsPerPage).ceil();
        final safePage    = _subItemsPage.clamp(1, totalPages);
        final startIdx    = (safePage - 1) * _subItemsPerPage;
        final endIdx      = (startIdx + _subItemsPerPage) > items.length ? items.length : startIdx + _subItemsPerPage;
        final pageItems   = items.sublist(startIdx, endIdx);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Column(
            children: [
              ...pageItems.map((it) => _buildSubResultCard(Map<String, dynamic>.from(it), _selectedSubType!)),
              if (totalPages > 1) ...[
                const SizedBox(height: 6),
                SpecificLocationPageIndicator(
                  currentPage: safePage,
                  totalPages: totalPages,
                  color: subColor,
                  onPageChanged: (p) => setState(() => _subItemsPage = p),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubResultCard(Map<String, dynamic> item, String type) {
    final level  = _levelKeys.indexOf(type);
    final color  = _levelColors[level];
    final icon   = _levelIcons[level];
    final name   = item['nama_$type']?.toString() ?? '';
    final imgUrl = item['gambar_$type'] as String?;
    final pic    = item['User'] as Map?;

    final picName    = (pic?['nama'] as String?)?.trim().isNotEmpty == true
        ? pic!['nama'] as String
        : t('pic');
    final picImgUrl  = pic?['gambar_user'] as String?;
    final hasPicImg  = picImgUrl != null && picImgUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LocationDetailScreen(
              level: level,
              data : item,
              lang : widget.lang,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                child: SizedBox(
                  width: 64,
                  child: imgUrl != null
                      ? Image.network(imgUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: color.withValues(alpha: 0.1),
                            child: Center(child: Icon(icon, color: color, size: 24)),
                          ))
                      : Container(
                          color: color.withValues(alpha: 0.1),
                          child: Center(child: Icon(icon, color: color, size: 24)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: hasPicImg
                                ? () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        opaque: false,
                                        barrierColor: Colors.black.withValues(alpha: 0.95),
                                        transitionDuration: const Duration(milliseconds: 200),
                                        reverseTransitionDuration: Duration.zero,
                                        pageBuilder: (_, __, ___) => LocationFullscreenImageViewer(
                                          imageUrl: picImgUrl,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: color.withValues(alpha: 0.18),
                              backgroundImage: hasPicImg ? NetworkImage(picImgUrl) : null,
                              child: !hasPicImg
                                  ? Icon(Icons.person_rounded, color: color, size: 11)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              picName,
                              style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.black, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded, color: color, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnggotaTab(String idValue) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _levelColor.withValues(alpha: 0.35), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: _levelColor.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchMemberController,
              onChanged: (v) => setState(() {
                _searchMember = v.toLowerCase();
                _membersPage  = 1;
              }),
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _C.textDark),
              decoration: InputDecoration(
                hintText: t('cari_anggota'),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                prefixIcon: Icon(Icons.search_rounded, color: _levelColor, size: 20),
                suffixIcon: _searchMember.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: _levelColor, size: 18),
                        onPressed: () {
                          _searchMemberController.clear();
                          setState(() {
                            _searchMember = '';
                            _membersPage  = 1;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _membersFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                  baseColor: const Color(0xFFBAE6FD),
                  highlightColor: const Color(0xFFE0F2FE),
                  period: const Duration(milliseconds: 1200),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 6,
                    itemBuilder: (_, __) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 72,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                );
              }

              final all = snap.data ?? [];
              var filtered = all.where((u) => u['nama'].toString().toLowerCase().contains(_searchMember)).toList();

              const prio = {'eksekutif': 1, 'manager': 2, 'kasie': 3, 'staff': 4};
              filtered.sort((a, b) {
                final ra = a['jabatan']?['nama_jabatan']?.toString().toLowerCase() ?? 'staff';
                final rb = b['jabatan']?['nama_jabatan']?.toString().toLowerCase() ?? 'staff';
                return (prio[ra] ?? 5).compareTo(prio[rb] ?? 5);
              });

              if (filtered.isEmpty) {
                if (_searchMember.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/team_illustration.png',
                            width: 150, height: 150,
                            errorBuilder: (_, __, ___) => Container(
                              width: 110, height: 110,
                              decoration: BoxDecoration(
                                color: _levelColor.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.group_off_rounded, size: 48, color: _levelColor.withValues(alpha: 0.5)),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            t('anggota_tidak_ditemukan_title'),
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _C.textDark),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('anggota_tidak_ditemukan_subtitle'),
                            style: GoogleFonts.poppins(fontSize: 12.5, color: _C.textGrey, fontWeight: FontWeight.w500, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              _searchMemberController.clear();
                              setState(() {
                                _searchMember = '';
                                _membersPage  = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: _levelColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: _levelColor.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.restart_alt_rounded, size: 15, color: _levelColor),
                                  const SizedBox(width: 6),
                                  Text(t('reset_pencarian'),
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _levelColor)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _levelColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/team_illustration.png',
                            width: 108,
                            height: 108,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.groups_rounded, size: 64, color: _levelColor.withValues(alpha: 0.5)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          t('anggota_kosong_title'),
                          style: GoogleFonts.poppins(fontSize: 15.5, fontWeight: FontWeight.w800, color: _C.textDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t('anggota_kosong_subtitle'),
                          style: GoogleFonts.poppins(
                              fontSize: 12.5, color: _C.textGrey, fontWeight: FontWeight.w500, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final totalPages = (filtered.length / _membersPerPage).ceil();
              final safePage    = _membersPage.clamp(1, totalPages);
              final startIdx    = (safePage - 1) * _membersPerPage;
              final endIdx      = (startIdx + _membersPerPage) > filtered.length ? filtered.length : startIdx + _membersPerPage;
              final pageItems   = filtered.sublist(startIdx, endIdx);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pageItems.length,
                      itemBuilder: (ctx, i) {
                        final user = pageItems[i];
                        final userId = user['id_user']?.toString();
                        final name = user['nama']?.toString() ?? '';
                        final imgUrl = user['gambar_user'] as String?;
                        final idJabatan = user['id_jabatan'] as int?;
                        final isVerificator = user['is_verificator'] as bool?;
                        final jabatanRaw = user['jabatan'];
                        final jabatanNama = jabatanRaw is Map ? jabatanRaw['nama_jabatan']?.toString() : null;

                        return GestureDetector(
                          onTap: userId == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfileModal(
                                        userId: userId,
                                        userName: name,
                                        userAvatarUrl: (imgUrl != null && imgUrl.isNotEmpty) ? imgUrl : null,
                                        userRank: 0,
                                        lang: widget.lang,
                                      ),
                                    ),
                                  );
                                },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _levelColor.withValues(alpha: 0.5), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (imgUrl != null && imgUrl.isNotEmpty)
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _levelColor.withValues(alpha: 0.15),
                                    backgroundImage: NetworkImage(imgUrl),
                                    onBackgroundImageError: (_, __) {},
                                  )
                                else
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _levelColor,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _levelColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      _buildMemberJabatanBadge(
                                        idJabatan: idJabatan,
                                        jabatanNama: jabatanNama,
                                        isVerificator: isVerificator,
                                        lang: widget.lang,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (totalPages > 1)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, 10, 16, 12 + MediaQuery.of(context).padding.bottom),
                      child: SpecificLocationPageIndicator(
                        currentPage: safePage,
                        totalPages: totalPages,
                        color: _levelColor,
                        onPageChanged: (p) => setState(() => _membersPage = p),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQrTab(String tName) {
    final qrData = _data['qrcode'] as String?;
    final itemName = _data['nama_$tName'] as String? ?? '';
    final picMap = _data['User'] as Map?;
    final picName = picMap?['nama'] as String?;
    final picImage = picMap?['gambar_user'] as String?;

    if (qrData == null || qrData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 130,
                height: 130,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _levelColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_scanner_rounded, size: 62, color: _levelColor.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 22),
              Text(
                t('qr_empty_title'),
                style: GoogleFonts.poppins(fontSize: 15.5, fontWeight: FontWeight.w800, color: _C.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                t('qr_not_generated'),
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: Color(0xFF1D72F3), fontWeight: FontWeight.w700, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _levelColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _levelColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, size: 16, color: _levelColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.lang == 'EN'
                          ? 'This QR code is used to scan and submit a 5R finding report at this specific location.'
                          : widget.lang == 'ZH'
                              ? '此二维码用于扫描并在该特定位置提交5R发现报告。'
                              : 'Kode QR ini digunakan untuk discan guna membuat laporan temuan 5R pada lokasi spesifik ini.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _levelColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            (_cachedAppLogoUrl != null && _cachedAppLogoUrl!.isNotEmpty)
                ? Image.network(
                    _cachedAppLogoUrl!,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/logo1.PNG',
                      height: 36,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  )
                : Image.asset(
                    'assets/images/logo1.PNG',
                    height: 36,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_levelColor.withValues(alpha: 0.16), _levelColor.withValues(alpha: 0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _levelColor.withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _levelColor.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: QrImageView(data: qrData, version: QrVersions.auto, size: 190),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_levelIcon, size: 16, color: _levelColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    itemName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _levelColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${t('pic')} : ',
                  style: GoogleFonts.poppins(color: _levelColor, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                CircleAvatar(
                  radius: 11,
                  backgroundColor: _levelColor.withValues(alpha: 0.18),
                  backgroundImage: (picImage != null && picImage.isNotEmpty) ? NetworkImage(picImage) : null,
                  child: (picImage == null || picImage.isEmpty)
                      ? Icon(Icons.person_rounded, color: _levelColor, size: 12)
                      : null,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    (picName != null && picName.isNotEmpty) ? picName : t('pic_kosong'),
                    style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildMemberJabatanBadge({
  required int? idJabatan,
  required String? jabatanNama,
  required bool? isVerificator,
  required String lang,
}) {
  final label = JabatanHelper.getDisplayRole(
    isVerificatorFlag: isVerificator,
    idJabatan: idJabatan,
    jabatanFromDb: jabatanNama,
    lang: lang,
  );
  if (label.isEmpty) return const SizedBox.shrink();
  final color = JabatanHelper.getPrimaryColor(isVerificatorFlag: isVerificator, idJabatan: idJabatan);
  final icon = JabatanHelper.getRoleIcon(isVerificatorFlag: isVerificator, idJabatan: idJabatan);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _StickyHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          minHeight: 0,
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}