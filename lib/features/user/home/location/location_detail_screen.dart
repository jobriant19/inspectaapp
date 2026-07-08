import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../shared/code/qr_generator_screen.dart';

class _C {
  static const primary      = Color(0xFF0EA5E9);
  static const primaryLight = Color(0xFFE0F2FE);
  static const textDark     = Color(0xFF0C4A6E);
  static const textGrey     = Color(0xFF64748B);
  static const border       = Color(0xFFBAE6FD);
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
  'unit'   : 'id_unit, nama_unit, gambar_unit, deskripsi_unit, kategori, is_star, '
             'id_pic, User!id_pic(nama), subunit(id_subunit), id_lokasi, lokasi(nama_lokasi), qrcode',
  'subunit': 'id_subunit, nama_subunit, gambar_subunit, deskripsi_subunit, kategori, is_star, '
             'id_pic, User!id_pic(nama), area(id_area), id_unit, id_lokasi, unit(nama_unit), lokasi(nama_lokasi), qrcode',
  'area'   : 'id_area, nama_area, gambar_area, deskripsi_area, kategori, is_star, '
             'id_pic, User!id_pic(nama), id_subunit, id_unit, id_lokasi, '
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
      'ringkasan_sublokasi': 'Sub-Location Summary',
      'pilih_kategori': 'Pilih Unit, Subunit, atau Area di atas untuk melihat daftar',
      'sub_kosong': 'Data tidak ditemukan',
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
    },
  };

  static String get(String lang, String key) => _data[lang]?[key] ?? _data['ID']?[key] ?? key;
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

  String t(String key) => _DetailTexts.get(widget.lang, key);

  Color get _levelColor => _levelColors[widget.level];
  IconData get _levelIcon => _levelIcons[widget.level];

  @override
  void initState() {
    super.initState();
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

  Future<List<dynamic>> _fetchMembersData(String idValue) async {
    final s = Supabase.instance.client;
    const q = 'nama, gambar_user, jabatan(nama_jabatan)';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))
              ],
              image: _data['gambar_$tName'] != null
                  ? DecorationImage(image: NetworkImage(_data['gambar_$tName']), fit: BoxFit.cover)
                  : null,
            ),
            child: _data['gambar_$tName'] == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.black12),
                      const SizedBox(height: 8),
                      Text(t('tidak_ada_gambar'), style: const TextStyle(color: Colors.black26, fontWeight: FontWeight.w600)),
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
                  icon: Icons.category_rounded, iconBg: const Color(0xFFFFF7ED), iconColor: Colors.orange,
                  label: t('kategori'), value: _data['kategori'] ?? '-',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _infoRow(
                  icon: Icons.person_pin_rounded, iconBg: const Color(0xFFF0FDF4), iconColor: Colors.green,
                  label: t('pic'), value: (_data['User'] != null) ? _data['User']['nama'] : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(t('deskripsi'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _C.textDark)),
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
              _data['deskripsi_$tName'] ?? t('tdk_ada'),
              style: const TextStyle(fontSize: 14, height: 1.6, color: _C.textGrey),
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _C.textDark)),
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.touch_app_rounded, size: 36, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                t('pilih_kategori'),
                style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: Center(
              child: Text(t('sub_kosong'),
                  style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Column(
            children: items
                .map((it) => _buildSubResultCard(Map<String, dynamic>.from(it), _selectedSubType!))
                .toList(),
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
                      Text(
                        pic?['nama'] as String? ?? t('pic'),
                        style: const TextStyle(fontSize: 10.5, color: _C.textGrey, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _infoRow({
    required IconData icon, required Color iconBg, required Color iconColor,
    required String label, required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _C.textGrey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _C.textDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnggotaTab(String idValue) {
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
                    onChanged: (v) => setState(() => _searchMember = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: t('cari_anggota'),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      hintStyle: const TextStyle(color: _C.textGrey, fontSize: 13),
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off_rounded, size: 56, color: Colors.grey.shade200),
                      const SizedBox(height: 10),
                      Text(t('kosong'), style: const TextStyle(color: _C.textGrey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final user = filtered[i];
                  final role = user['jabatan']?['nama_jabatan'] ?? 'Staff';
                  final imgUrl = user['gambar_user'] as String?;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: roleColor(role), width: 1.5),
                        ),
                        child: CircleAvatar(
                          backgroundColor: roleBg(role),
                          backgroundImage: (imgUrl != null && imgUrl.isNotEmpty) ? NetworkImage(imgUrl) : null,
                          child: (imgUrl == null || imgUrl.isEmpty)
                              ? Text(user['nama'][0].toUpperCase(), style: TextStyle(color: roleColor(role), fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                      title: Text(
                        user['nama'],
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleBg(role),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: roleColor(role).withValues(alpha: 0.3)),
                          ),
                          child: Text(role, style: TextStyle(color: roleColor(role), fontSize: 11, fontWeight: FontWeight.w700)),
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
    final qrData = _data['qrcode'] as String?;
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
                  boxShadow: [BoxShadow(color: _C.primary.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: QrImageView(data: qrData, version: QrVersions.auto, size: 220),
              )
            else
              Column(
                children: [
                  Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    t('qr_not_generated'),
                    style: const TextStyle(fontSize: 15, color: _C.textGrey, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(t('generate_qr')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _levelColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QRGeneratorScreen(
                            lang: widget.lang,
                            levelName: tName,
                            levelId: _data['id_$tName'].toString(),
                            itemName: _data['nama_$tName'],
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        final refreshed = await Supabase.instance.client
                            .from(tName)
                            .select('*, User!id_pic(nama)')
                            .eq('id_$tName', _data['id_$tName'].toString())
                            .single();
                        setState(() => _data = {..._data, ...refreshed});
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