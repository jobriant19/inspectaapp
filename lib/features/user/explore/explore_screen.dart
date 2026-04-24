import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../finding/finding_detail_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../home/kts_finding_card.dart';
import '../ktsproduksi/kts_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String lang;
  const ExploreScreen({super.key, required this.lang});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final Map<String, Future<List<Map<String, dynamic>>>> _findingsCache = {};

  // State untuk Filter Chips
  Set<String> _activeChips = {};

  String? _currentUserId;
  int? _userLokasiId;
  int? _userUnitId;
  int? _userSubunitId;
  int? _userAreaId;

  // Filter yang Diterapkan dari BottomSheet
  Map<String, dynamic>? _appliedLocationFilter;
  String _appliedInspectionType = ''; // 'visitor', 'eksekutif', 'profesional'
  String _appliedSortOrder = 'terbaru'; // 'terbaru', 'terlama', 'deadline'
  String _appliedJenisTemuan = ''; // '' = semua, '5r' = 5R, 'kts' = KTS Production

  // State untuk UI di BottomSheet
  int? _selectedLokasiId;
  String _selectedLokasiName = '';
  int? _selectedLokasiLevel;

  Future<List<Map<String, dynamic>>>? _findingsFuture;

  // Dictionary Bahasa
  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'belum_selesai': 'Belum Selesai',
      'selesai': 'Selesai',
      'ditugaskan': 'Ditugaskan ke saya',
      'lokasi': 'Lokasi saya',
      'temuan_saya': 'Temuan saya',
      'inspeksi': 'Inspeksi',
      'filter_title': 'Urutkan & Filter Temuan',
      'filter_by': 'Filter berdasarkan',
      'level_eskalasi': 'Level Eskalasi',
      'pilih_level': 'Pilih Level',
      'lokasi_temuan': 'Lokasi temuan',
      'pilih_lokasi': 'Pilih Lokasi',
      'temuan_inspeksi': 'Temuan Inspeksi',
      'visitor': 'Visitor',
      'eksekutif': 'Eksekutif',
      'profesional': 'Profesional',
      'sort_by': 'Urutkan berdasarkan',
      'jenis_temuan': 'Jenis Temuan',
      'prioritas': 'Prioritaskan Temuan Inspeksi',
      'waktu': 'Waktu',
      'terlama': 'Temuan Terlama',
      'terbaru': 'Temuan Terbaru',
      'deadline': 'Deadline Terdekat',
      'reset': 'Reset',
      'terapkan': 'Terapkan',
      'hari_terlewat': 'hari terlewat',
      'jam_terlewat': 'jam terlewat',
      'menit_terlewat': 'menit terlewat',
      'hari_tersisa': 'hari tersisa',
      'deadline_hari_ini': 'Deadline hari ini',
      'temuan_kosong': 'Belum ada temuan.',
      'temuan_kosong_filter': 'Temuan tidak ditemukan.',
      'memuat': 'Memuat temuan...',
      'selesai_pada_label': 'Selesai pada',
      'filter_5r': 'Temuan 5R',
      'filter_kts': 'KTS Produksi',
    },
    'EN': {
      'belum_selesai': 'Unfinished',
      'selesai': 'Finished',
      'ditugaskan': 'Assigned to me',
      'lokasi': 'My location',
      'temuan_saya': 'My findings',
      'inspeksi': 'Inspection',
      'filter_title': 'Sort & Filter Findings',
      'filter_by': 'Filter by',
      'level_eskalasi': 'Escalation Level',
      'pilih_level': 'Select Level',
      'lokasi_temuan': 'Finding Location',
      'pilih_lokasi': 'Select Location',
      'temuan_inspeksi': 'Inspection Finding',
      'visitor': 'Visitor',
      'eksekutif': 'Executive',
      'profesional': 'Professional',
      'sort_by': 'Sort by',
      'jenis_temuan': 'Finding Type',
      'prioritas': 'Prioritize Inspection Findings',
      'waktu': 'Time',
      'terlama': 'Oldest Findings',
      'terbaru': 'Newest Findings',
      'deadline': 'Nearest Deadline',
      'reset': 'Reset',
      'terapkan': 'Apply',
      'hari_terlewat': 'days overdue',
      'jam_terlewat' : 'hours overdue',
      'menit_terlewat' : 'minutes overdue',
      'hari_tersisa': 'days left',
      'deadline_hari_ini': 'Deadline today',
      'temuan_kosong': 'No findings yet.',
      'temuan_kosong_filter': 'No findings found.',
      'memuat': 'Loading findings...',
      'selesai_pada_label': 'Completed on',
      'filter_5r': '5R Findings',
      'filter_kts': 'KTS Production',
    },
    'ZH': {
      'belum_selesai': '未完成',
      'selesai': '已完成',
      'ditugaskan': '分配给我',
      'lokasi': '我的位置',
      'temuan_saya': '我的发现',
      'inspeksi': '检查',
      'filter_title': '排序和过滤发现',
      'filter_by': '过滤依据',
      'level_eskalasi': '升级级别',
      'pilih_level': '选择级别',
      'lokasi_temuan': '发现位置',
      'pilih_lokasi': '选择位置',
      'temuan_inspeksi': '检查发现',
      'visitor': '访客',
      'eksekutif': '行政',
      'profesional': '专业',
      'sort_by': '排序依据',
      'jenis_temuan': '发现类型',
      'prioritas': '优先检查发现',
      'waktu': '时间',
      'terlama': '最旧的发现',
      'terbaru': '最新发现',
      'deadline': '最近的截止日期',
      'reset': '重置',
      'terapkan': '应用',
      'hari_terlewat': '天逾期',
      'jam_terlewat': '小时逾期',
      'menit_terlewat': '分钟逾期', 
      'hari_tersisa': '天剩余',
      'deadline_hari_ini': '截止日期是今天',
      'temuan_kosong': '暂无发现。',
      'temuan_kosong_filter': '未找到任何发现。',
      'memuat': '正在加载发现...',
      'selesai_pada_label': '完成于',
      'filter_5r': '5R发现',
      'filter_kts': 'KTS生产',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // BARU: Listener yang paling andal
    _tabController.addListener(() {
      // Cek jika animasi sudah selesai DAN tab-nya bukan yang sebelumnya
      if (!_tabController.indexIsChanging) {
          _loadFindings(); // Panggil _loadFindings setiap kali tab selesai berpindah
      }
    });

    _fetchInitialUserData().then((_) {
      _loadFindings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placeholder Gambar
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Placeholder Teks
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Container(height: 16, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                          const SizedBox(height: 6),
                          Container(height: 16, width: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                          const SizedBox(height: 12),
                          Container(height: 12, width: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(height: 12, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                              Container(height: 28, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Placeholder Deadline Bar
              Container(
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTransformedImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) {
      return '';
    }

    try {
      final uri = Uri.parse(originalUrl);
      
      // Cek apakah ini URL Supabase Storage yang valid.
      // Jika path-nya mengandung '/storage/v1/object/public/',
      // kita bisa melakukan transformasi.
      if (uri.path.contains('/storage/v1/object/public/')) {
        // Ganti '/public/' menjadi '/render/image/public/' untuk mengaktifkan API transformasi.
        final newPath = uri.path.replaceFirst(
          '/storage/v1/object/public/', 
          '/storage/v1/render/image/public/'
        );

        // Buat URL baru dengan path yang sudah diubah dan tambahkan parameter transformasi.
        // width=200 & height=200: Minta gambar ukuran 200x200 pixel. Cukup untuk thumbnail.
        // resize=cover: Potong gambar agar pas dengan ukuran 200x200 tanpa distorsi.
        final transformedUri = uri.replace(
          path: newPath,
          queryParameters: {
            'width': '200',
            'height': '200',
            'resize': 'cover',
          },
        );
        return transformedUri.toString();
      } else {
        // Jika bukan URL Supabase Storage, kembalikan URL aslinya.
        return originalUrl;
      }
    } catch (e) {
      // Jika terjadi error saat parsing URL, kembalikan URL asli sebagai fallback.
      debugPrint("Error transforming image URL: $e");
      return originalUrl;
    }
  }

  Future<void> _fetchInitialUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('User')
          .select('id_lokasi, id_unit, id_subunit, id_area')
          .eq('id_user', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _currentUserId = user.id;
          _userLokasiId = response['id_lokasi'];
          _userUnitId = response['id_unit'];
          _userSubunitId = response['id_subunit']; 
          _userAreaId = response['id_area'];
        });
      } else if (mounted) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data for filter: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(  // TAMBAH INI
      color: Colors.transparent,
      child:  Column(
        children: [
          // 1. TABS: Belum Selesai | Selesai
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                tabAlignment: TabAlignment.fill,
                indicator: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF0EA5E9),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: getTxt('belum_selesai')),
                  Tab(text: getTxt('selesai')),
                ],
              ),
            ),
          ),

          // FILTER CHIPS (assigned, location, my findings, inspection)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showFilterBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.filter_list_alt, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text("Filter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildFilterChip(getTxt('ditugaskan'), 'assigned'),
                  // Sembunyikan chip lokasi jika filter KTS aktif
                  if (_appliedJenisTemuan != 'kts') _buildFilterChip(getTxt('lokasi'), 'location'),
                  _buildFilterChip(getTxt('temuan_saya'), 'mine'),
                  _buildFilterChip(getTxt('inspeksi'), 'inspection'),
                ],
              ),
            ),
          ),

          // 3. LIST DATA TEMUAN ASLI
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _findingsFuture,
              builder: (context, snapshot) {
                // 1. Tampilkan loading indicator saat menunggu
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return _buildShimmerLoader();
                }

                // 2. Tampilkan pesan error jika terjadi kesalahan
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat temuan. Error: ${snapshot.error}'),
                  );
                }

                // 3. Jika data berhasil dimuat (bahkan jika kosong)
                final allData = snapshot.data ?? [];

                // 4. Tampilkan UI "Data Kosong" jika list kosong
                if (allData.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/team_illustration.png',
                            width: 200,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            // Gunakan teks berbeda jika filter aktif
                            _appliedLocationFilter != null ||
                                    _appliedInspectionType.isNotEmpty
                                ? getTxt('temuan_kosong_filter')
                                : getTxt('temuan_kosong'),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 5. Tampilkan ListView jika ada data
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: allData.length,
                  itemBuilder: (context, index) {
                    // Anda tidak perlu lagi variabel 'filteredData'
                    return _buildFindingCard(allData[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER UNTUK CHIPS ---
  Widget _buildFilterChip(String label, String value) {
    bool isActive = _activeChips.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _activeChips.remove(value);
          } else {
            _activeChips.add(value);
            // Reset filter bottom sheet saat chip diaktifkan
            _appliedLocationFilter = null;
            _appliedInspectionType = '';
          }
          _loadFindings();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // --- METHOD UNTUK BOTTOM SHEET FILTER ---
  void _showFilterBottomSheet(BuildContext context) {
    Map<String, dynamic>? tempLocationFilter = _appliedLocationFilter;
    String tempInspectionType = _appliedInspectionType;
    String tempSortOrder = _appliedSortOrder;
    String tempLocationName = _selectedLokasiName;
    String tempJenisTemuan = _appliedJenisTemuan;
  
    // Label inspeksi sesuai bahasa
    final inspLabel = {
      'ID': {'visitor': 'Visitor', 'eksekutif': 'Eksekutif', 'profesional': 'Profesional'},
      'EN': {'visitor': 'Visitor', 'eksekutif': 'Executive', 'profesional': 'Professional'},
      'ZH': {'visitor': '访客', 'eksekutif': '行政', 'profesional': '专业'},
    }[widget.lang] ?? {'visitor': 'Visitor', 'eksekutif': 'Executive', 'profesional': 'Professional'};
  
    // Warna tiap badge inspeksi (konsisten dengan card)
    const inspColors = {
      'visitor': Color(0xFF3B82F6),
      'eksekutif': Color(0xFFEF4444),
      'profesional': Color(0xFFF59E0B),
    };
  
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
  
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          getTxt('filter_title'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: const Color(0xFFF1F5F9)),
  
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
  
                          // ── FILTER ──
                          _filterSectionHeader(getTxt('filter_by')),
                          const SizedBox(height: 14),

                          // Jenis Temuan
                          _filterLabel(getTxt('jenis_temuan')),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setModalState(() {
                                    tempJenisTemuan = tempJenisTemuan == '5r' ? '' : '5r';
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: tempJenisTemuan == '5r'
                                          ? const Color(0xFF38BDF8)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: tempJenisTemuan == '5r'
                                            ? const Color(0xFF38BDF8)
                                            : const Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                      boxShadow: tempJenisTemuan == '5r'
                                          ? [BoxShadow(
                                              color: const Color(0xFF38BDF8).withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3))]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        getTxt('filter_5r'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: tempJenisTemuan == '5r'
                                              ? Colors.white
                                              : const Color(0xFF38BDF8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setModalState(() {
                                    tempJenisTemuan = tempJenisTemuan == 'kts' ? '' : 'kts';
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: tempJenisTemuan == 'kts'
                                          ? const Color(0xFFFBBF24)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: tempJenisTemuan == 'kts'
                                            ? const Color(0xFFFBBF24)
                                            : const Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                      boxShadow: tempJenisTemuan == 'kts'
                                          ? [BoxShadow(
                                              color: const Color(0xFFFBBF24).withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3))]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        getTxt('filter_kts'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: tempJenisTemuan == 'kts'
                                              ? Colors.white
                                              : const Color(0xFFFBBF24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
  
                          // Lokasi Temuan
                          _filterLabel(getTxt('lokasi_temuan')),
                          GestureDetector(
                            onTap: () async {
                              final result = await showModalBottomSheet<Map<String, dynamic>>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => FilterLocationBottomSheet(lang: widget.lang),
                              );
                              if (result != null) {
                                setModalState(() {
                                  tempLocationFilter = result;
                                  tempLocationName = result['name'];
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: tempLocationName.isEmpty ? Colors.white : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: tempLocationName.isEmpty
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF0284C7),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.maps_home_work_rounded,
                                    size: 20,
                                    color: tempLocationName.isEmpty
                                        ? const Color(0xFF0284C7)
                                        : const Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tempLocationName.isEmpty ? getTxt('pilih_lokasi') : tempLocationName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: tempLocationName.isEmpty ? FontWeight.normal : FontWeight.w600,
                                        color: tempLocationName.isEmpty ? Colors.grey : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (tempLocationName.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => setModalState(() {
                                        tempLocationFilter = null;
                                        tempLocationName = '';
                                      }),
                                      child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                    )
                                  else
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0284C7), size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
  
                          // Temuan Inspeksi — setiap pilihan berwarna sesuai badge
                          _filterLabel(getTxt('temuan_inspeksi')),
                          Row(
                            children: ['visitor', 'eksekutif', 'profesional'].map((val) {
                              final isActive = tempInspectionType == val;
                              final color = inspColors[val]!;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setModalState(() {
                                    tempInspectionType = isActive ? '' : val;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: EdgeInsets.only(right: val != 'profesional' ? 8 : 0),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isActive ? color : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isActive ? color : const Color(0xFFCBD5E1), width: 1.5),
                                      boxShadow: isActive
                                          ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        inspLabel[val]!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isActive ? Colors.white : color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 28),
  
                          // ── URUTKAN ──
                          _filterSectionHeader(getTxt('sort_by')),
                          const SizedBox(height: 14),
  
                          _filterLabel(getTxt('waktu')),
                          // Sort selector sebagai toggle buttons
                          Column(
                            children: [
                              _buildSortOption(
                                value: 'terbaru',
                                label: getTxt('terbaru'),
                                icon: Icons.arrow_downward_rounded,
                                currentValue: tempSortOrder,
                                onTap: (v) => setModalState(() => tempSortOrder = v),
                              ),
                              const SizedBox(height: 8),
                              _buildSortOption(
                                value: 'terlama',
                                label: getTxt('terlama'),
                                icon: Icons.arrow_upward_rounded,
                                currentValue: tempSortOrder,
                                onTap: (v) => setModalState(() => tempSortOrder = v),
                              ),
                              const SizedBox(height: 8),
                              _buildSortOption(
                                value: 'deadline',
                                label: getTxt('deadline'),
                                icon: Icons.timer_rounded,
                                currentValue: tempSortOrder,
                                onTap: (v) => setModalState(() => tempSortOrder = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
  
                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        // Reset
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              _findingsCache.clear();
                              setState(() {
                                _appliedLocationFilter = null;
                                _appliedInspectionType = '';
                                _appliedSortOrder = 'terbaru';
                                _selectedLokasiName = '';
                                _appliedJenisTemuan = '';
                                
                                _activeChips = {};
                              });
                              Navigator.pop(context);
                              _loadFindings();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  getTxt('reset'),
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Terapkan
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _appliedLocationFilter = tempLocationFilter;
                                _appliedInspectionType = tempInspectionType;
                                _appliedSortOrder = tempSortOrder;
                                _selectedLokasiName = tempLocationName;
                                _appliedJenisTemuan = tempJenisTemuan;
                                _activeChips = {};
                              });
                              Navigator.pop(context);
                              _loadFindings();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  getTxt('terapkan'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterSectionHeader(String text) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _filterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSortOption({
    required String value,
    required String label,
    required IconData icon,
    required String currentValue,
    required Function(String) onTap,
  }) {
    final isActive = currentValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF0284C7).withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0284C7) : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: isActive ? Colors.white : const Color(0xFF0284C7)),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0284C7) : const Color(0xFF334155),
              ),
            ),
            const Spacer(),
            if (isActive)
              const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF0284C7)),
          ],
        ),
      ),
    );
  }
  // Komponen UI Pendukung untuk Bottom Sheet
  Widget _buildFilterSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildDropdownSelector(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    String title,
    String value,
    String groupValue,
    Function(String) onTap,
  ) {
    bool isSelected = groupValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6F7F9) : Colors.transparent,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF00C9E4) : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade300);
  }

  // --- WIDGET HELPER: TOMBOL PEMICU PILIH LOKASI ---
  Widget _buildLocationPickerButton(
    BuildContext context,
    StateSetter setModalState,
  ) {
    return GestureDetector(
      onTap: () async {
        // Membuka Bottom Sheet Hierarki Lokasi
        final result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FilterLocationBottomSheet(lang: widget.lang),
        );

        // Jika user memilih lokasi, perbarui state filter
        if (result != null) {
          setState(() {
            _selectedLokasiId = result['id'];
            _selectedLokasiName = result['name'];
            _selectedLokasiLevel = result['level'];
          });
          setModalState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1E3A8A).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.maps_home_work_rounded,
              size: 20,
              color: Color(0xFF00C9E4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedLokasiName.isEmpty
                    ? getTxt('pilih_lokasi')
                    : _selectedLokasiName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _selectedLokasiName.isEmpty
                      ? FontWeight.normal
                      : FontWeight.w600,
                  color: _selectedLokasiName.isEmpty
                      ? Colors.black54
                      : const Color(0xFF1E3A8A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedLokasiName.isNotEmpty)
              GestureDetector(
                onTap: () => setModalState(() {
                  _selectedLokasiId = null;
                  _selectedLokasiName = '';
                }),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _loadFindings() {
    final sortedChips = _activeChips.toList()..sort();
    String cacheKey =
      'tab:${_tabController.index}_' +
      'chips:${sortedChips.join("+")}_' +
      'loc:${_appliedLocationFilter?['id']}_' +
      'type:${_appliedInspectionType}_' +
      'sort:${_appliedSortOrder}_' +
      'jenis:${_appliedJenisTemuan}';

    if (_findingsCache.containsKey(cacheKey)) {
      setState(() {
        _findingsFuture = _findingsCache[cacheKey];
      });
    } else {
      final newFuture = _fetchFindings();
      _findingsCache[cacheKey] = newFuture;
      setState(() {
        _findingsFuture = newFuture;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFindings() async {
    try {
      var query = Supabase.instance.client.from('temuan').select('''
        id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan,
        poin_temuan, target_waktu_selesai, jenis_temuan,
        id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab,
        lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
        kategoritemuan(nama_kategoritemuan),
        is_pro, is_visitor, is_eksekutif,
        no_order, jumlah_item, nama_item_manual,
        item_produksi:id_item(id_item, nama_item, gambar_item),
        subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan),
        penyelesaian!temuan_id_penyelesaian_fkey(
          *,
          User_Solver:User!id_user(nama, gambar_user)
        )
      ''');

      // Filter Tab
      if (_tabController.index == 0) {
        query = query.neq('status_temuan', 'Selesai');
      } else {
        query = query.eq('status_temuan', 'Selesai');
      }

      // Filter jenis temuan (5R / KTS)
      if (_appliedJenisTemuan == '5r') {
        query = query.neq('jenis_temuan', 'KTS Production');
      } else if (_appliedJenisTemuan == 'kts') {
        query = query.eq('jenis_temuan', 'KTS Production');
      }

      // Filter Chips
      if (_activeChips.isNotEmpty && _currentUserId != null) {
        if (_activeChips.contains('assigned')) {
          query = query.eq('id_penanggung_jawab', _currentUserId!);
        }
        if (_activeChips.contains('mine')) {
          query = query.eq('id_user', _currentUserId!);
        }
        if (_activeChips.contains('inspection')) {
          query = query.eq('is_pro', true);
        }
        if (_activeChips.contains('location') && _appliedJenisTemuan != 'kts') {
          final List<String> orFilters = [];
          if (_userAreaId != null) {
            orFilters.add('id_area.eq.$_userAreaId');
          } else if (_userSubunitId != null) {
            orFilters.add('id_subunit.eq.$_userSubunitId');
          } else if (_userUnitId != null) {
            orFilters.add('id_unit.eq.$_userUnitId');
          } else if (_userLokasiId != null) {
            orFilters.add('id_lokasi.eq.$_userLokasiId');
          }
          if (orFilters.isNotEmpty) {
            query = query.or(orFilters.join(','));
          } else {
            query = query.eq('id_temuan', -1);
          }
        }
      }

      // Filter lokasi dari bottom sheet (sembunyikan jika KTS)
      if (_appliedLocationFilter != null && _appliedJenisTemuan != 'kts') {
        final level = _appliedLocationFilter!['level'] as int;
        final id = _appliedLocationFilter!['id'];
        switch (level) {
          case 0: query = query.eq('id_lokasi', id); break;
          case 1: query = query.eq('id_unit', id); break;
          case 2: query = query.eq('id_subunit', id); break;
          case 3: query = query.eq('id_area', id); break;
        }
      }

      // Filter inspection type dari bottom sheet
      if (_appliedInspectionType.isNotEmpty) {
        switch (_appliedInspectionType) {
          case 'visitor': query = query.eq('is_visitor', true); break;
          case 'eksekutif': query = query.eq('is_eksekutif', true); break;
          case 'profesional': query = query.eq('is_pro', true); break;
        }
      }

      final response = await () {
        switch (_appliedSortOrder) {
          case 'terlama':
            return query.order('created_at', ascending: true);
          case 'deadline':
            return query.order('target_waktu_selesai', ascending: true, nullsFirst: false);
          case 'terbaru':
          default:
            return query.order('created_at', ascending: false);
        }
      }();
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint("Terjadi kesalahan saat fetch findings: $error");
      return [];
    }
  }

  String _formatLocation(Map<String, dynamic> item) {
    if (item['area'] != null && item['area']['nama_area'] != null) {
      return item['area']['nama_area'].toString();
    }
    if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) {
      return item['subunit']['nama_subunit'].toString();
    }
    if (item['unit'] != null && item['unit']['nama_unit'] != null) {
      return item['unit']['nama_unit'].toString();
    }
    if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) {
      return item['lokasi']['nama_lokasi'].toString();
    }
    return '-';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildFindingCard(Map<String, dynamic> data) {
    // --- A. PARSING DATA & VARIABEL DASAR ---
    final transformedImageUrl = _getTransformedImageUrl((data['gambar_temuan'] ?? '').toString());
    final title = (data['judul_temuan'] ?? '-').toString();
    final lokasi = _formatLocation(data);
    final tanggal = _formatDate(data['created_at']);
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final status = (data['status_temuan'] ?? '').toString();

    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;

    // --- B. LOGIKA STATUS: SELESAI vs BELUM SELESAI ---
    final s = status.toLowerCase();
    final isFinished = [
      'selesai',
      'done',
      'completed',
      'closed'
    ].any((e) => s.contains(e));
    
    // Perbaikan: Gunakan teks dari kamus bahasa
    final String statusText = isFinished ? getTxt('selesai') : getTxt('belum_selesai');

    late Color statusColor;
    late Color statusBg;
    late IconData statusIcon;

    if (isFinished) {
      // Perbaikan: Style untuk status "Selesai"
      statusColor = const Color(0xFF16A34A); // Hijau cerah
      statusBg = const Color(0xFFF0FDF4); // Latar belakang hijau muda
      statusIcon = Icons.check_circle_rounded; // Ikon centang
    } else {
      // Style untuk status "Belum Selesai" (merah)
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
      statusIcon = Icons.pending_actions_rounded;
    }

    // --- C. LOGIKA BADGE INSPEKSI & BORDER STROKE ---
    List<Widget> badges = [];
    List<String> inspectionTypes = [];

    if (isPro) inspectionTypes.add('pro');
    if (isVisitor) inspectionTypes.add('visitor');
    if (isEksekutif) inspectionTypes.add('eksekutif');

    if (inspectionTypes.contains('pro')) {
      badges.add(_buildInspectionBadge('PROFESIONAL', const Color.fromARGB(255, 255, 244, 45), Colors.black));
    }
    if (inspectionTypes.contains('visitor')) {
      badges.add(_buildInspectionBadge('VISITOR', const Color(0xFF3B82F6), Colors.white));
    }
    if (inspectionTypes.contains('eksekutif')) {
      badges.add(_buildInspectionBadge('EKSEKUTIF', const Color(0xFFEF4444), Colors.white));
    }

    inspectionTypes.sort();
    String combinationKey = inspectionTypes.join('+');

    final Color borderColor;
    switch (combinationKey) {
      case 'eksekutif+pro+visitor': borderColor = const Color(0xFF38BDF8); break;
      case 'pro+visitor': borderColor = const Color(0xFF38BDF8); break;
      case 'eksekutif+pro': borderColor = const Color(0xFF38BDF8); break;
      case 'eksekutif+visitor': borderColor = const Color(0xFF38BDF8); break;
      case 'pro': borderColor = const Color(0xFF38BDF8); break;
      case 'visitor': borderColor = const Color(0xFF38BDF8); break;
      case 'eksekutif': borderColor = const Color(0xFF38BDF8); break;
      default:
        final jenisTemuan = (data['jenis_temuan'] ?? '').toString();
        borderColor = jenisTemuan == 'KTS Production'
            ? const Color(0xFFFDE68A)
            : const Color(0xFF38BDF8);
          }

    // --- D. LOGIKA INDIKATOR WAKTU (DEADLINE vs SELESAI) ---
    Widget? timeIndicator;

    if (isFinished) {
      // PERUBAHAN: Tampilan untuk temuan yang SUDAH selesai
      String completionDateText = '-';
      
      // 1. Ambil data sebagai Map, bukan List. Bisa jadi null jika tidak ada data.
      final penyelesaianData = data['penyelesaian'] as Map<String, dynamic>?; 

      // 2. Cek apakah Map tersebut tidak null.
      if (penyelesaianData != null) {
        // 3. Langsung akses 'tanggal_selesai' dari Map tersebut.
        completionDateText = _formatDate(penyelesaianData['tanggal_selesai']);
      }
      
      timeIndicator = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusBg, // Latar belakang hijau
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.event_available_rounded, size: 14, color: statusColor),
            const SizedBox(width: 6),
            Text(
              "${getTxt('selesai_pada_label')} $completionDateText",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      );
    } else {
      // Logika lama (tetap dipertahankan) untuk temuan BELUM selesai
      final deadline = DateTime.tryParse(data['target_waktu_selesai']?.toString() ?? '');
      if (deadline != null) {
        final now = DateTime.now();
        final difference = deadline.difference(now);
        Color timeColor;
        String timeText;
        IconData timeIcon;

        if (difference.isNegative) { 
          timeColor = Colors.red.shade700;
          timeIcon = Icons.warning_amber_rounded;
          final selisihTerlewat = difference.abs();
          if (selisihTerlewat.inDays > 0) timeText = "${selisihTerlewat.inDays} ${getTxt('hari_terlewat')}";
          else if (selisihTerlewat.inHours > 0) timeText = "${selisihTerlewat.inHours} ${getTxt('jam_terlewat')}";
          else timeText = "${selisihTerlewat.inMinutes} ${getTxt('menit_terlewat')}";
        } else {
          final sisaHari = difference.inDays;
          if (sisaHari == 0) {
            timeColor = Colors.orange.shade800;
            timeIcon = Icons.today_rounded;
            timeText = getTxt('deadline_hari_ini');
          } else {
            timeColor = Colors.green.shade800;
            timeIcon = Icons.timer_outlined;
            timeText = "$sisaHari ${getTxt('hari_tersisa')}";
          }
        }

        timeIndicator = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Row(
            children: [
              Icon(timeIcon, size: 14, color: timeColor),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: timeColor,
                ),
              ),
            ],
          ),
        );
      }
    }

    // Gunakan KtsFindingCard untuk jenis KTS
    final isKts = (data['jenis_temuan'] ?? '') == 'KTS Production';
    if (isKts) {
      return KtsFindingCard(
        data: data,
        lang: widget.lang,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => KtsDetailScreen(
              ktsId: data['id_temuan'] as int,
              lang: widget.lang,
              initialData: data,
            ),
          ));
        },
      );
    }
    // --- E. BUILD WIDGET CARD ---
    return GestureDetector(
      onTap: () {
        final isKts = (data['jenis_temuan'] ?? '') == 'KTS Production';
        if (isKts) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => KtsDetailScreen(
              ktsId: data['id_temuan'] as int,
              lang: widget.lang,
              initialData: data,
            ),
          ));
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FindingDetailScreen(initialData: data, lang: widget.lang),
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PERBAIKAN: GAMBAR DENGAN BORDER
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      // Stroke hitam transparan agar tidak terlalu keras
                      border: Border.all(color: Colors.black.withOpacity(0.15), width: 1.5),
                    ),
                    child: ClipRRect(
                      // Radius lebih kecil agar border tidak tertutup
                      borderRadius: BorderRadius.circular(12.5),
                      child: Container(
                        color: const Color(0xFFF8FAFC),
                        child: transformedImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: transformedImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: const Color(0xFFF0F4F8)),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image_rounded, color: Colors.grey),
                            )
                          : const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // KONTEN
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.3,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Label jenis temuan (KTS / 5R)
                            () {
                              final jenis = (data['jenis_temuan'] ?? '').toString();
                              final isKts = jenis == 'KTS Production';
                              final labelText = isKts ? 'KTS' : '5R';
                              final labelColor = isKts ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8);
                              return Container(
                                margin: const EdgeInsets.only(right: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                decoration: BoxDecoration(
                                  color: labelColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: labelColor, width: 1.2),
                                ),
                                child: Text(
                                  labelText,
                                  style: TextStyle(
                                    color: labelColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }(),
                            const SizedBox(width: 0),
                          ],
                        ),

                        const SizedBox(height: 6),
                        
                        if (badges.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Wrap(spacing: 6, runSpacing: 4, children: badges),
                          ),

                        Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                lokasi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(
                              tanggal,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 13, color: statusColor),
                                  const SizedBox(width: 4),
                                  // PERBAIKAN: Gunakan statusText yang sudah dilokalisasi
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (timeIndicator != null) timeIndicator,
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET UNTUK MEMBUAT BADGE INSPEKSI (Tetap ada) ---
  Widget _buildInspectionBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET BOTTOM SHEET KHUSUS FILTER: HIERARKI LOKASI YANG ELEGAN & BERBEDA
// ============================================================================
class FilterLocationBottomSheet extends StatefulWidget {
  final String lang;
  const FilterLocationBottomSheet({super.key, required this.lang});

  @override
  State<FilterLocationBottomSheet> createState() => _FilterLocationBottomSheetState();
}

class _FilterLocationBottomSheetState extends State<FilterLocationBottomSheet> {
  int _level = 0;
  bool _isLoading = true;
  List<dynamic> _data = [];
  List<dynamic> _filtered = [];
  final List<Map<String, dynamic>> _history = [];
  final _searchCtrl = TextEditingController();

  static const _idCols = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'];
  static const _namCols = ['nama_lokasi', 'nama_unit', 'nama_subunit', 'nama_area'];

  String get _idCol => _idCols[_level];
  String get _nameCol => _namCols[_level];

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_data)
          : _data.where((item) => item[_nameCol].toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _fetch({int? parentId}) async {
    setState(() => _isLoading = true);
    _searchCtrl.clear();
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];
      if (_level == 0) {
        data = await supabase.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
      } else if (_level == 1) {
        data = await supabase.from('unit').select('id_unit, nama_unit').eq('id_lokasi', parentId!).order('nama_unit');
      } else if (_level == 2) {
        data = await supabase.from('subunit').select('id_subunit, nama_subunit').eq('id_unit', parentId!).order('nama_subunit');
      } else if (_level == 3) {
        data = await supabase.from('area').select('id_area, nama_area').eq('id_subunit', parentId!).order('nama_area');
      }
      if (mounted) {
        setState(() {
          _data = data;
          _filtered = List.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goDeeper(Map<String, dynamic> item) {
    if (_level >= 3) return;
    _history.add({'level': _level, 'id': item[_idCol], 'name': item[_nameCol]});
    setState(() => _level++);
    _fetch(parentId: item[_idCols[_level - 1]]);
  }

  void _select(Map<String, dynamic> item) {
    final parts = [..._history.map((h) => h['name'] as String), item[_nameCol].toString()];
    Navigator.pop(context, {
      'id': item[_idCol],
      'name': parts.join(' / '),
      'level': _level,
    });
  }

  void _goBack() {
    if (_history.isEmpty) { Navigator.pop(context); return; }
    _history.removeLast();
    setState(() => _level--);
    _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
  }

  @override
  Widget build(BuildContext context) {
    final lvlLabels = {
      'EN': ['Location', 'Unit', 'Sub-Unit', 'Area'],
      'ID': ['Lokasi', 'Unit', 'Sub-Unit', 'Area'],
      'ZH': ['地点', '单位', '子单位', '区域'],
    };
    final labels = lvlLabels[widget.lang] ?? lvlLabels['ID']!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_history.isEmpty ? Icons.close : Icons.arrow_back_ios_new_rounded,
                      color: const Color(0xFF0284C7), size: 20),
                  onPressed: _goBack,
                ),
                Expanded(
                  child: Text(
                    _history.isEmpty ? labels[_level] : _history.last['name'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(20)),
                  child: Text('${_filtered.length}',
                      style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
          // Breadcrumb
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(4, (i) {
                final isActive = i == _level;
                final isPast = i < _level;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: isPast ? () {
                        final steps = _level - i;
                        for (int s = 0; s < steps; s++) { if (_history.isNotEmpty) _history.removeLast(); }
                        setState(() => _level = i);
                        _fetch(parentId: _history.isEmpty ? null : _history.last['id']);
                      } : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF0284C7) : isPast ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(labels[i], style: TextStyle(
                          color: isActive ? Colors.white : isPast ? const Color(0xFF0284C7) : Colors.grey.shade300,
                          fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        )),
                      ),
                    ),
                    if (i < 3) Icon(Icons.chevron_right, size: 12,
                        color: i < _level ? const Color(0xFF0284C7) : Colors.grey.shade300),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF0284C7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: widget.lang == 'EN' ? 'Search...' : widget.lang == 'ZH' ? '搜索...' : 'Cari...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
                : _filtered.isEmpty
                    ? Center(child: Text(widget.lang == 'EN' ? 'No data found' : 'Data tidak ditemukan',
                        style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final item = _filtered[i];
                          final name = item[_nameCol]?.toString() ?? '-';
                          final isLastLevel = _level == 3;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                              boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: InkWell(
                              onTap: isLastLevel ? () => _select(item) : () => _goDeeper(item),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                                      child: Icon([Icons.location_city, Icons.workspaces, Icons.layers, Icons.place][_level],
                                          color: const Color(0xFF0284C7), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E3A8A)))),
                                    GestureDetector(
                                      onTap: () => _select(item),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF0284C7)),
                                        ),
                                        child: Text(widget.lang == 'EN' ? 'Select' : widget.lang == 'ZH' ? '选择' : 'Pilih',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                                      ),
                                    ),
                                    if (!isLastLevel) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _goDeeper(item),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}