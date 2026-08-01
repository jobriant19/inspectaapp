import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../finding/detail/finding_detail_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../home/card/kts_finding_card.dart';
import '../ktsproduksi/kts_detail_screen.dart';
import 'explore_indicator_screen.dart';
import 'filter/explore_filter_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String lang;
  const ExploreScreen({super.key, required this.lang});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final Map<String, Future<_FindingsPage>> _findingsCache = {};

  Set<String> _activeChips = {};

  String? _currentUserId;
  String? _userLokasiId;
  String? _userUnitId;
  String? _userSubunitId;
  String? _userAreaId;

  Map<String, dynamic>? _appliedLocationFilter;
  String _appliedInspectionType = '';
  String _appliedSortOrder = 'terbaru';
  String _appliedJenisTemuan = '';
  Map<String, dynamic>? _appliedSectionFilter; 
  String _selectedSectionName = '';
  Map<String, dynamic>? _appliedCauseFactor;

  String _selectedLokasiName = '';

  static const int _pageSize = 10;
  int _currentPage = 1;

  Future<_FindingsPage>? _findingsFuture;
  _FindingsPage? _lastDisplayedPage;

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
      'temuan_kosong': 'Belum ada temuan',
      'temuan_kosong_filter': 'Temuan tidak ditemukan',
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
      'temuan_kosong': 'No findings yet',
      'temuan_kosong_filter': 'No findings found',
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
      'temuan_kosong': '暂无发现',
      'temuan_kosong_filter': '未找到任何发现',
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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
          _loadFindings();
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
                    // IMAGE PLACEHOLDER
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // TEXT PLACEHOLDER
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
              // DEADLINE BAR PLACEHOLDER
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
      if (uri.path.contains('/storage/v1/object/public/')) {
        final newPath = uri.path.replaceFirst(
          '/storage/v1/object/public/', 
          '/storage/v1/render/image/public/'
        );
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
        return originalUrl;
      }
    } catch (e) {
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
          _userLokasiId = response['id_lokasi']?.toString();
          _userUnitId = response['id_unit']?.toString();
          _userSubunitId = response['id_subunit']?.toString();
          _userAreaId = response['id_area']?.toString();
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
    return Material(
      color: Colors.transparent,
      child:  Column(
        children: [
          // 1. TABS: UNFINISHED | FINISHED
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  const Color brightRed = Color(0xFFEF4444);
                  const Color brightGreen = Color(0xFF22C55E);
                  final Color activeIndicatorColor =
                      _tabController.index == 0 ? brightRed : brightGreen;
                  return TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    tabAlignment: TabAlignment.fill,
                    indicator: BoxDecoration(
                      color: activeIndicatorColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Text(
                          getTxt('belum_selesai'),
                          style: GoogleFonts.poppins(
                            fontWeight: _tabController.index == 0
                                ? FontWeight.w800
                                : FontWeight.w700,
                            fontSize: 16,
                            color: _tabController.index == 0
                                ? Colors.white
                                : brightRed,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          getTxt('selesai'),
                          style: GoogleFonts.poppins(
                            fontWeight: _tabController.index == 1
                                ? FontWeight.w800
                                : FontWeight.w700,
                            fontSize: 16,
                            color: _tabController.index == 1
                                ? Colors.white
                                : brightGreen,
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
                        boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list_alt, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text("Filter", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildFilterChip(getTxt('ditugaskan'), 'assigned'),
                  if (_appliedJenisTemuan != 'kts') _buildFilterChip(getTxt('lokasi'), 'location'),
                  _buildFilterChip(getTxt('temuan_saya'), 'mine'),
                  _buildFilterChip(getTxt('inspeksi'), 'inspection'),
                ],
              ),
            ),
          ),

          // FINDING LIST
          Expanded(
            child: FutureBuilder<_FindingsPage>(
              future: _findingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  _lastDisplayedPage = snapshot.data;
                }

                final bool isRefreshing = snapshot.connectionState == ConnectionState.waiting;
                final resultPage = _lastDisplayedPage;

                if (resultPage == null) {
                  return isRefreshing
                      ? _buildShimmerLoader()
                      : const SizedBox.shrink();
                }

                final allData = resultPage.items;
                final totalPages = resultPage.totalCount == 0
                    ? 1
                    : (resultPage.totalCount / _pageSize).ceil();

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
                            _appliedLocationFilter != null ||
                                    _appliedInspectionType.isNotEmpty
                                ? getTxt('temuan_kosong_filter')
                                : getTxt('temuan_kosong'),
                            style: GoogleFonts.poppins(
                              color: Color(0xFF1D72F3),
                              fontSize: 16,
                              fontWeight: FontWeight.w800
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (isRefreshing)
                      const LinearProgressIndicator(
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D72F3)),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: allData.length,
                        itemBuilder: (context, index) {
                          return _buildFindingCard(allData[index]);
                        },
                      ),
                    ),
                    if (totalPages > 1)
                      ExploreIndicatorScreen(
                        currentPage: _currentPage,
                        totalPages: totalPages,
                        onPageChanged: _goToPage,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isActive = _activeChips.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _activeChips.remove(value);
          } else {
            _activeChips.add(value);
            _appliedInspectionType = '';
            if (value == 'location') {
              _appliedLocationFilter = null;
              _selectedLokasiName = '';
            }
          }
          _loadFindings();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1D72FE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF1D72FE) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (page == _currentPage) return;
    setState(() => _currentPage = page);
    _loadFindings(resetPage: false);
  }

  void _showFilterBottomSheet(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ExploreFilterScreen(
        lang: widget.lang,
        initialLocationFilter: _appliedLocationFilter,
        initialInspectionType: _appliedInspectionType,
        initialSortOrder: _appliedSortOrder,
        initialLocationName: _selectedLokasiName,
        initialJenisTemuan: _appliedJenisTemuan,
        initialSectionFilter: _appliedSectionFilter,
        initialSectionName: _selectedSectionName,
        initialCauseFactor: _appliedCauseFactor,
      ),
    );

    if (result == null) return;

    if (result['action'] == 'reset') {
      _findingsCache.clear();
      setState(() {
        _appliedLocationFilter = null;
        _appliedInspectionType = '';
        _appliedSortOrder = 'terbaru';
        _selectedLokasiName = '';
        _appliedJenisTemuan = '';
        _appliedSectionFilter = null;
        _selectedSectionName = '';
        _appliedCauseFactor = null;
        _activeChips = {};
      });
      _loadFindings();
    } else if (result['action'] == 'apply') {
      setState(() {
        _appliedLocationFilter = result['locationFilter'];
        _appliedInspectionType = result['inspectionType'];
        _appliedSortOrder = result['sortOrder'];
        _selectedLokasiName = result['locationName'];
        _appliedJenisTemuan = result['jenisTemuan'];
        _appliedSectionFilter = result['sectionFilter'];
        _selectedSectionName = result['sectionName'] ?? '';
        _appliedCauseFactor = result['causeFactor'];
        _activeChips = {};
      });
      _loadFindings();
    }
  }

  String _buildCacheKey(int page) {
    final sortedChips = _activeChips.toList()..sort();
    return 'tab:${_tabController.index}_'
        'chips:${sortedChips.join("+")}_'
        'loc:${_appliedLocationFilter?['id']}_'
        'locall:${_appliedLocationFilter?['all']}_'
        'loclevel:${_appliedLocationFilter?['level']}_'
        'sectionid:${_appliedSectionFilter?['id']}_'
        'sectionall:${_appliedSectionFilter?['all']}_'
        'sectionlevel:${_appliedSectionFilter?['level']}_'
        'factor:${_appliedCauseFactor?['id']}_'
        'type:${_appliedInspectionType}_'
        'sort:${_appliedSortOrder}_'
        'jenis:${_appliedJenisTemuan}_'
        'page:$page';
  }

  void _loadFindings({bool resetPage = true}) {
    if (resetPage) _currentPage = 1;
    final cacheKey = _buildCacheKey(_currentPage);

    if (_findingsCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _findingsFuture = _findingsCache[cacheKey];
        });
      }
      return;
    }

    final newFuture = _fetchFindings(_currentPage);
    _findingsCache[cacheKey] = newFuture;
    if (mounted) {
      setState(() {
        _findingsFuture = newFuture;
      });
    }
    newFuture.then((page) {
      if (mounted) _prefetchAdjacentPages(page.totalCount);
    });
  }

  void _prefetchAdjacentPages(int totalCount) {
    final totalPages = totalCount == 0 ? 1 : (totalCount / _pageSize).ceil();
    for (final p in [_currentPage - 1, _currentPage + 1]) {
      if (p < 1 || p > totalPages) continue;
      final key = _buildCacheKey(p);
      if (_findingsCache.containsKey(key)) continue;
      _findingsCache[key] = _fetchFindings(p);
    }
  }

  int _typePriorityRank(Map<String, dynamic> item) {
    final isVisitor = item['is_visitor'] == true;
    final isEksekutif = item['is_eksekutif'] == true;
    final isPro = item['is_pro'] == true;
    final isKts = item['jenis_temuan'] == 'KTS Production';

    if (isVisitor) return 0;
    if (isEksekutif) return 1;
    if (isPro) return 2;
    if (isKts) return 3;
    return 4;
  }

  Future<_FindingsPage> _fetchFindings(int page) async {
    try {
      final bool isKtsMode = _appliedJenisTemuan == 'kts';
      final bool needsInnerPenyelesaian =
          isKtsMode && (_appliedSectionFilter != null || _appliedCauseFactor != null);
      final String penyelesaianRelation = needsInnerPenyelesaian
          ? 'penyelesaian!temuan_id_penyelesaian_fkey!inner'
          : 'penyelesaian!temuan_id_penyelesaian_fkey';

      var query = Supabase.instance.client.from('temuan').select('''
        id_temuan, judul_temuan, deskripsi_temuan, gambar_temuan, created_at, status_temuan,
        poin_temuan, target_waktu_selesai, jenis_temuan,
        id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab, id_penyelesaian,
        lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
        kategoritemuan(nama_kategoritemuan),
        is_pro, is_visitor, is_eksekutif,
        no_order, jumlah_item, nama_item_manual,
        item_produksi:id_item(id_item, nama_item, gambar_item),
        subkategoritemuan:id_subkategoritemuan_uuid(id_subkategoritemuan, nama_subkategoritemuan),
        User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
        User_Creator:User!temuan_id_user_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
        $penyelesaianRelation(
          *,
          User_Solver:User!id_user(nama, gambar_user),
          section:id_section(nama_section_id, nama_section_en, nama_section_zh),
          faktor_penyebab:id_subkategoritemuan_penyebab(id_subkategoritemuan, nama_subkategoritemuan)
        )
      ''');

      // FILTER TAB
      if (_tabController.index == 0) {
        query = query.neq('status_temuan', 'Selesai');
      } else {
        query = query.eq('status_temuan', 'Selesai');
      }

      // FINDING TYPE FILTER (5R / KTS)
      if (_appliedJenisTemuan == '5r') {
        query = query.neq('jenis_temuan', 'KTS Production');
      } else if (_appliedJenisTemuan == 'kts') {
        query = query.eq('jenis_temuan', 'KTS Production');
      }

      // CAUSE SECTION & CAUSE FACTOR FILTER ONLY KTS
      if (isKtsMode) {
        if (_appliedSectionFilter != null) {
          if (_appliedSectionFilter!['all'] == true) {
            query = query.not('penyelesaian.id_section', 'is', null);
          } else {
            query = query.eq('penyelesaian.id_section', _appliedSectionFilter!['id'].toString());
          }
        }
        if (_appliedCauseFactor != null) {
          query = query.eq(
            'penyelesaian.id_subkategoritemuan_penyebab',
            _appliedCauseFactor!['id'].toString(),
          );
        }
      }

      // FILTER CHIPS
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
            return const _FindingsPage(items: [], totalCount: 0);
          }
        }
      }

      if (_appliedLocationFilter != null && _appliedJenisTemuan != 'kts') {
        final level = _appliedLocationFilter!['level'] as int;
        final isAllLevel = _appliedLocationFilter!['all'] == true;

        if (isAllLevel) {
          switch (level) {
            case 0: query = query.not('id_lokasi', 'is', null); break;
            case 1: query = query.not('id_unit', 'is', null); break;
            case 2: query = query.not('id_subunit', 'is', null); break;
            case 3: query = query.not('id_area', 'is', null); break;
          }
        } else {
          final id = _appliedLocationFilter!['id'].toString();
          switch (level) {
            case 0: query = query.eq('id_lokasi', id); break;
            case 1: query = query.eq('id_unit', id); break;
            case 2: query = query.eq('id_subunit', id); break;
            case 3: query = query.eq('id_area', id); break;
          }
        }
      }

      if (_appliedInspectionType.isNotEmpty) {
        switch (_appliedInspectionType) {
          case 'visitor': query = query.eq('is_visitor', true); break;
          case 'eksekutif': query = query.eq('is_eksekutif', true); break;
          case 'profesional': query = query.eq('is_pro', true); break;
        }
      }

      final int from = (page - 1) * _pageSize;
      final int to = from + _pageSize - 1;

      final orderedQuery = () {
        switch (_appliedSortOrder) {
          case 'terlama':
            return query.order('created_at', ascending: true);
          case 'deadline':
            if (isKtsMode) {
              return query.order('jumlah_item', ascending: false, nullsFirst: false);
            }
            final deadlineQuery = query
                .not('target_waktu_selesai', 'is', null)
                .gte('target_waktu_selesai', DateTime.now().toIso8601String());
            return deadlineQuery.order('target_waktu_selesai', ascending: true, nullsFirst: false);
          case 'terbaru':
          default:
            return query.order('created_at', ascending: false);
        }
      }();

      final response = await orderedQuery.range(from, to).count(CountOption.exact);

      final items = List<Map<String, dynamic>>.from(response.data);

      if (_appliedSortOrder == 'terbaru') {
        items.sort((a, b) {
          final aPriority = _typePriorityRank(a);
          final bPriority = _typePriorityRank(b);
          if (aPriority != bPriority) return aPriority.compareTo(bPriority);
          final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
          final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
          return db.compareTo(da);
        });
      }

      return _FindingsPage(items: items, totalCount: response.count);
    } catch (error) {
      debugPrint("Terjadi kesalahan saat fetch findings: $error");
      return const _FindingsPage(items: [], totalCount: 0);
    }
  }

  Map<String, dynamic> _locationBadgeInfo(Map<String, dynamic> item, {int? filterLevel}) {
    if (filterLevel != null) {
      switch (filterLevel) {
        case 0:
          if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) {
            return {'label': item['lokasi']['nama_lokasi'].toString(), 'icon': Icons.location_city_rounded, 'color': const Color(0xFF10B981)};
          }
          break;
        case 1:
          if (item['unit'] != null && item['unit']['nama_unit'] != null) {
            return {'label': item['unit']['nama_unit'].toString(), 'icon': Icons.business_rounded, 'color': const Color(0xFF6366F1)};
          }
          break;
        case 2:
          if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) {
            return {'label': item['subunit']['nama_subunit'].toString(), 'icon': Icons.layers_rounded, 'color': const Color(0xFFFBBF24)};
          }
          break;
        case 3:
          if (item['area'] != null && item['area']['nama_area'] != null) {
            return {'label': item['area']['nama_area'].toString(), 'icon': Icons.place_rounded, 'color': const Color(0xFFF472B6)};
          }
          break;
      }
    }
    if (item['area'] != null && item['area']['nama_area'] != null) {
      return {'label': item['area']['nama_area'].toString(), 'icon': Icons.place_rounded, 'color': const Color(0xFFF472B6)};
    }
    if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) {
      return {'label': item['subunit']['nama_subunit'].toString(), 'icon': Icons.layers_rounded, 'color': const Color(0xFFFBBF24)};
    }
    if (item['unit'] != null && item['unit']['nama_unit'] != null) {
      return {'label': item['unit']['nama_unit'].toString(), 'icon': Icons.business_rounded, 'color': const Color(0xFF6366F1)};
    }
    if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) {
      return {'label': item['lokasi']['nama_lokasi'].toString(), 'icon': Icons.location_city_rounded, 'color': const Color(0xFF10B981)};
    }
    return {'label': '-', 'icon': Icons.location_off_rounded, 'color': const Color(0xFF94A3B8)};
  }

  Widget _buildLocationBadgeWidget(Map<String, dynamic> data, {int? filterLevel}) {
    final loc = _locationBadgeInfo(data, filterLevel: filterLevel);
    final Color color = loc['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(loc['icon'] as IconData, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              loc['label'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildFindingCard(Map<String, dynamic> data) {
    final transformedImageUrl = _getTransformedImageUrl((data['gambar_temuan'] ?? '').toString());
    final title = (data['judul_temuan'] ?? '-').toString();
    final tanggal = _formatDate(data['created_at']);
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final status = (data['status_temuan'] ?? '').toString();

    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;

    final s = status.toLowerCase();
    final isFinished = [
      'selesai',
      'done',
      'completed',
      'closed'
    ].any((e) => s.contains(e));
    
    final String statusText = isFinished ? getTxt('selesai') : getTxt('belum_selesai');

    late Color statusColor;
    late Color statusBg;
    late IconData statusIcon;

    if (isFinished) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFF0FDF4);
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
      statusIcon = Icons.pending_actions_rounded;
    }

    List<Widget> badges = [];
    List<String> inspectionTypes = [];

    if (isPro) inspectionTypes.add('pro');
    if (isVisitor) inspectionTypes.add('visitor');
    if (isEksekutif) inspectionTypes.add('eksekutif');

    if (inspectionTypes.contains('pro')) {
      badges.add(_buildInspectionBadge(_inspectionLabel('pro'), const Color.fromARGB(255, 255, 244, 45), Colors.black));
    }
    if (inspectionTypes.contains('visitor')) {
      badges.add(_buildInspectionBadge(_inspectionLabel('visitor'), const Color(0xFF3B82F6), Colors.white));
    }
    if (inspectionTypes.contains('eksekutif')) {
      badges.add(_buildInspectionBadge(_inspectionLabel('eksekutif'), const Color(0xFFEF4444), Colors.white));
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

    Widget? timeIndicator;

    if (isFinished) {
      String completionDateText = '-';
      
      final penyelesaianData = data['penyelesaian'] as Map<String, dynamic>?; 

      if (penyelesaianData != null) {
        completionDateText = _formatDate(penyelesaianData['tanggal_selesai']);
      }
      
      timeIndicator = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusBg,
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
          if (selisihTerlewat.inDays > 0) { timeText = "${selisihTerlewat.inDays} ${getTxt('hari_terlewat')}"; }
          else if (selisihTerlewat.inHours > 0) { timeText = "${selisihTerlewat.inHours} ${getTxt('jam_terlewat')}"; }
          else { timeText = "${selisihTerlewat.inMinutes} ${getTxt('menit_terlewat')}"; }
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
            color: timeColor.withValues(alpha:0.08),
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

    final isKts = (data['jenis_temuan'] ?? '') == 'KTS Production';
    if (isKts) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: KtsFindingCard(
          data: data,
          lang: widget.lang,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => KtsDetailScreen(
                ktsId: data['id_temuan'].toString(),
                lang: widget.lang,
                initialData: data,
              ),
            ));
          },
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        final isKts = (data['jenis_temuan'] ?? '') == 'KTS Production';
        if (isKts) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => KtsDetailScreen(
              ktsId: data['id_temuan'].toString(),
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
              color: borderColor.withValues(alpha:0.18),
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
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withValues(alpha:0.15), width: 1.5),
                    ),
                    child: ClipRRect(
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

                  // CONTENT
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
                            
                            // FINDING TYPE BADGE (KTS / 5R)
                            () {
                              final jenis = (data['jenis_temuan'] ?? '').toString();
                              final isKts = jenis == 'KTS Production';
                              final labelText = isKts ? 'KTS' : '5R';
                              final labelColor = isKts 
                                  ? const Color(0xFFFBBF24) 
                                  : const Color(0xFF38BDF8);
                              return Container(
                                margin: const EdgeInsets.only(right: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 5),
                                decoration: BoxDecoration(
                                  color: labelColor.withValues(alpha:0.15),
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
                            
                            // POINT BADGE
                            if (poin > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$poin',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        
                        if (badges.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Wrap(spacing: 6, runSpacing: 4, children: badges),
                          ),

                        // SPESIFIC LOCATION BADGE
                        Row(children: [
                          Flexible(
                            child: _buildLocationBadgeWidget(
                              data,
                              filterLevel: _appliedLocationFilter?['level'] as int?,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),

                        // DATE & STATUS BAR
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                tanggal,
                                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 14, color: statusColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      statusText,
                                      style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor),
                                    ),
                                  ],
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
            ),
            if (timeIndicator != null) timeIndicator,
          ],
        ),
      ),
    );
  }

  String _inspectionLabel(String key) {
    const labels = {
      'pro': {'ID': 'PROFESIONAL', 'EN': 'PROFESSIONAL', 'ZH': '专业'},
      'visitor': {'ID': 'PENGUNJUNG', 'EN': 'VISITOR', 'ZH': '访客'},
      'eksekutif': {'ID': 'EKSEKUTIF', 'EN': 'EXECUTIVE', 'ZH': '行政'},
    };
    return labels[key]?[widget.lang] ?? labels[key]!['ID']!;
  }

  Widget _buildInspectionBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _FindingsPage {
  final List<Map<String, dynamic>> items;
  final int totalCount;
  const _FindingsPage({required this.items, required this.totalCount});
}