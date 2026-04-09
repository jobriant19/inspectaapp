import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'finding_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String lang;
  const ExploreScreen({super.key, required this.lang});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // State untuk Tab Aktif (0: Belum Selesai, 1: Selesai)
  int _activeTab = 0;

  // State untuk Filter Chips
  String _activeChip = '';

  String? _currentUserId;
  int? _userLokasiId;
  int? _userUnitId;

  // Filter yang Diterapkan dari BottomSheet
  Map<String, dynamic>? _appliedLocationFilter;
  String _appliedInspectionType = ''; // 'visitor', 'eksekutif', 'profesional'
  String _appliedSortOrder = 'terbaru'; // 'terbaru', 'terlama', 'deadline'

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
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _fetchInitialUserData().then((_) {
      _loadFindings();
    });
  }

  Future<void> _fetchInitialUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('User')
          .select('id_lokasi, id_unit')
          .eq('id_user', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _currentUserId = user.id;
          _userLokasiId = response['id_lokasi'];
          _userUnitId = response['id_unit'];
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
    return Column(
      children: [
        // 1. TABS: Belum Selesai | Selesai
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              _buildTabItem(getTxt('belum_selesai'), 0),
              _buildTabItem(getTxt('selesai'), 1),
            ],
          ),
        ),

        // 2. FILTER & CHIPS
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Tombol Filter Kustom (Desain Baru, Gradient, & Bebas Plagiasi)
                GestureDetector(
                  onTap: () => _showFilterBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C9E4), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.filter_list_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Filter",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Chips
                _buildFilterChip(getTxt('ditugaskan'), 'assigned'),
                _buildFilterChip(getTxt('lokasi'), 'location'),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00C9E4)),
                );
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
    );
  }

  // --- WIDGET HELPER UNTUK TABS ---
  Widget _buildTabItem(String title, int index) {
    bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeTab = index);
          _loadFindings();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF1E3A8A) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1E3A8A)
                    : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER UNTUK CHIPS ---
  Widget _buildFilterChip(String label, String value) {
    bool isActive = _activeChip == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle chip
          _activeChip = isActive ? '' : value;

          // Jika chip diaktifkan, reset filter dari bottom sheet
          if (_activeChip.isNotEmpty) {
            _appliedLocationFilter = null;
            _appliedInspectionType = '';
          }

          // --- TAMBAHAN PENTING ---
          // Panggil _loadFindings() untuk memuat ulang data sesuai filter baru
          _loadFindings();
        });
      },
      child: Container(
        // ... sisa kode widget ini tetap sama ...
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Judul
                  Center(
                    child: Text(
                      getTxt('filter_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- FILTER BERDASARKAN ---
                          Text(
                            getTxt('filter_by'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Lokasi Temuan (Ganti dengan yang Fungsional)
                          _buildFilterSubtitle(getTxt('lokasi_temuan')),
                          GestureDetector(
                            onTap: () async {
                              final result =
                                  await showModalBottomSheet<
                                    Map<String, dynamic>
                                  >(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        FilterLocationBottomSheet(
                                          lang: widget.lang,
                                        ),
                                  );

                              if (result != null) {
                                setModalState(() {
                                  tempLocationFilter = result;
                                  tempLocationName = result['name'];
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1E3A8A,
                                  ).withOpacity(0.2),
                                  width: 1.5,
                                ),
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
                                      tempLocationName.isEmpty
                                          ? getTxt('pilih_lokasi')
                                          : tempLocationName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: tempLocationName.isEmpty
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                        color: tempLocationName.isEmpty
                                            ? Colors.black54
                                            : const Color(0xFF1E3A8A),
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
                          ),
                          const SizedBox(height: 15),

                          // Temuan Inspeksi (Segmented Style Fungsional)
                          _buildFilterSubtitle(getTxt('temuan_inspeksi')),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                _buildSegmentButton(
                                  getTxt('visitor'),
                                  'visitor',
                                  tempInspectionType,
                                  (val) => setModalState(
                                    () => tempInspectionType =
                                        (tempInspectionType == val ? '' : val),
                                  ),
                                ),
                                _buildSegmentDivider(),
                                _buildSegmentButton(
                                  getTxt('eksekutif'),
                                  'eksekutif',
                                  tempInspectionType,
                                  (val) => setModalState(
                                    () => tempInspectionType =
                                        (tempInspectionType == val ? '' : val),
                                  ),
                                ),
                                _buildSegmentDivider(),
                                _buildSegmentButton(
                                  getTxt('profesional'),
                                  'profesional',
                                  tempInspectionType,
                                  (val) => setModalState(
                                    () => tempInspectionType =
                                        (tempInspectionType == val ? '' : val),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // --- URUTKAN BERDASARKAN ---
                          Text(
                            getTxt('sort_by'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Waktu (Dropdown Fungsional)
                          _buildFilterSubtitle(getTxt('waktu')),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: tempSortOrder,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'terbaru',
                                    child: Text(getTxt('terbaru')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'terlama',
                                    child: Text(getTxt('terlama')),
                                  ),
                                  DropdownMenuItem(
                                    value: 'deadline',
                                    child: Text(getTxt('deadline')),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setModalState(() {
                                      tempSortOrder = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons (Reset & Terapkan Fungsional)
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              // Reset state utama, lalu tutup dan refresh
                              setState(() {
                                _appliedLocationFilter = null;
                                _appliedInspectionType = '';
                                _appliedSortOrder = 'terbaru';
                                _selectedLokasiName =
                                    ''; // Reset juga nama di UI utama
                                _activeChip = ''; // Reset juga filter chip
                              });
                              Navigator.pop(context);
                              _loadFindings();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              getTxt('reset'),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              // Terapkan state sementara ke state utama, tutup, dan refresh
                              setState(() {
                                _appliedLocationFilter = tempLocationFilter;
                                _appliedInspectionType = tempInspectionType;
                                _appliedSortOrder = tempSortOrder;
                                _selectedLokasiName = tempLocationName;
                                _activeChip =
                                    ''; // Filter chip dan filter detail tidak bisa aktif bersamaan
                              });
                              Navigator.pop(context);
                              _loadFindings();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF1E3A8A,
                              ), // Warna primer
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              getTxt('terapkan'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
    _findingsFuture = _fetchFindings();
  }

  Future<List<Map<String, dynamic>>> _fetchFindings() async {
    // 1. Tentukan query dasar dengan select()
    var query = Supabase.instance.client.from('temuan').select('''
          id_temuan, judul_temuan, gambar_temuan, created_at, status_temuan,
          poin_temuan, target_waktu_selesai,
          id_lokasi, id_unit, id_subunit, id_area, id_penanggung_jawab,
          lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area),
          kategoritemuan(nama_kategoritemuan), subkategoritemuan(nama_subkategoritemuan),
          is_pro, is_visitor, is_eksekutif,
          penyelesaian!temuan_id_penyelesaian_fkey(
            *,
            User_Solver:User!id_user(nama, gambar_user)
          )
        ''');

    // 2. Terapkan semua filter satu per satu ke query

    // Filter Tab (Belum Selesai / Selesai)
    final finishedStatus = ['Closed', 'Selesai', 'done', 'completed'];
    if (_activeTab == 0) {
      query = query.not('status_temuan', 'in', '(${finishedStatus.join(',')})');
    } else {
      query = query.filter(
        'status_temuan',
        'in',
        '(${finishedStatus.join(',')})',
      );
    }

    // Filter Chips
    if (_activeChip.isNotEmpty && _currentUserId != null) {
      switch (_activeChip) {
        case 'assigned':
          query = query.eq('id_penanggung_jawab', _currentUserId!);
          break;
        case 'location':
          final orFilter = [
            if (_userLokasiId != null) 'id_lokasi.eq.$_userLokasiId',
            if (_userUnitId != null) 'id_unit.eq.$_userUnitId',
          ].join(',');

          if (orFilter.isNotEmpty) {
            query = query.or(orFilter);
          }
          break;
        case 'mine':
          query = query.eq('id_user', _currentUserId!);
          break;
        case 'inspection':
          query = query.eq('is_pro', true);
          break;
      }
    }

    // Filter dari Bottom Sheet
    if (_appliedLocationFilter != null) {
      final level = _appliedLocationFilter!['level'] as int;
      final id = _appliedLocationFilter!['id'];
      final col = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'][level];
      query = query.eq(col, id);
    }

    if (_appliedInspectionType.isNotEmpty) {
      switch (_appliedInspectionType) {
        case 'visitor':
          query = query.eq('is_visitor', true);
          break;
        case 'eksekutif':
          query = query.eq('is_eksekutif', true);
          break;
        case 'profesional':
          query = query.eq('is_pro', true);
          break;
      }
    }

    // 3. Terapkan Urutan (Sorting)
    // NullsLast penting untuk deadline agar temuan tanpa deadline tidak muncul di atas
    switch (_appliedSortOrder) {
      case 'terlama':
        query.order('created_at', ascending: true);
        break;

      case 'deadline':
        query.order('target_waktu_selesai', ascending: true, nullsFirst: false);
        break;

      case 'terbaru':
      default:
        query.order('created_at', ascending: false);
        break;
    }

    // 4. Eksekusi query final
    // Hasil dari eksekusi adalah List<Map<String, dynamic>>
    final response = await query;
    return response;
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
    final idTemuan = data['id_temuan'];
    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final title = (data['judul_temuan'] ?? '-').toString();
    final kategori = data['kategoritemuan']?['nama_kategoritemuan']?.toString() ?? '';
    final subkategori = data['subkategoritemuan']?['nama_subkategoritemuan']?.toString() ?? '';
    final lokasi = _formatLocation(data);
    final tanggal = _formatDate(data['created_at']);
    final poin = int.tryParse((data['poin_temuan'] ?? 0).toString()) ?? 0;
    final status = (data['status_temuan'] ?? 'Belum Selesai').toString();

    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;

    // --- B. LOGIKA STATUS: SELESAI vs BELUM SELESAI ---
    final s = status.toLowerCase();
    final isFinished = [
      'Selesai',
      'done',
      'completed',
    ].any((e) => s.contains(e));

    late Color statusColor;
    late Color statusBg;
    late IconData statusIcon;

    if (isFinished) {
      statusColor = const Color(0xFF16A34A); // Green-700
      statusBg = const Color(0xFFF0FDF4); // Green-50
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFDC2626); // Red-600
      statusBg = const Color(0xFFFEF2F2); // Red-50
      statusIcon = Icons.pending_actions_rounded;
    }

    // --- C. LOGIKA BADGE INSPEKSI & BORDER STROKE ---
    List<Widget> badges = [];
    List<String> inspectionTypes = [];

    // Kuning untuk Pro
    if (isPro) {
      inspectionTypes.add('pro');
      badges.add(
        _buildInspectionBadge('PROFESIONAL', const Color.fromARGB(255, 255, 244, 45), Colors.black),
      );
    }
    // Biru untuk Visitor
    if (isVisitor) {
      inspectionTypes.add('visitor');
      badges.add(
        _buildInspectionBadge('VISITOR', const Color(0xFF3B82F6), Colors.white),
      );
    }
    // Merah untuk Eksekutif
    if (isEksekutif) {
      inspectionTypes.add('eksekutif');
      badges.add(
        _buildInspectionBadge(
          'EKSEKUTIF',
          const Color(0xFFEF4444),
          Colors.white,
        ),
      );
    }

    // Menentukan warna border berdasarkan kombinasi
    final Color borderColor;
    inspectionTypes
        .sort(); // Urutkan agar kombinasi konsisten (cth: pro+visitor)
    String combinationKey = inspectionTypes.join('+');

    switch (combinationKey) {
      // Kombinasi 3
      case 'eksekutif+pro+visitor':
        borderColor = const Color(0xFF9333EA);
        break; // Purple
      // Kombinasi 2
      case 'pro+visitor':
        borderColor = const Color(0xFF16A34A);
        break; // Green
      case 'eksekutif+pro':
        borderColor = const Color(0xFFEA580C);
        break; // Orange
      case 'eksekutif+visitor':
        borderColor = const Color(0xFF2563EB);
        break; // Indigo
      // Tunggal
      case 'pro':
        borderColor = const Color(0xFFF59E0B);
        break; // Amber (kuning)
      case 'visitor':
        borderColor = const Color(0xFF3B82F6);
        break; // Blue (biru)
      case 'eksekutif':
        borderColor = const Color(0xFFEF4444);
        break; // Red (merah)
      // Default
      default:
        borderColor = const Color(0xFFF1F5F9); // Warna abu-abu netral
    }

    // --- D. LOGIKA INDIKATOR WAKTU (DEADLINE) ---
    Widget? timeIndicator;
    if (!isFinished) {
      final deadline = DateTime.tryParse(data['target_waktu_selesai']?.toString() ?? '');
      if (deadline != null) {
        final now = DateTime.now();
        final difference = deadline.difference(now);

        Color timeColor;
        String timeText;
        IconData timeIcon;

        if (difference.isNegative) { // Terlewat (isNegative lebih akurat)
          timeColor = Colors.red.shade700;
          timeIcon = Icons.warning_amber_rounded;
          final selisihTerlewat = difference.abs(); // Ambil nilai absolut untuk perhitungan

          if (selisihTerlewat.inDays > 0) {
            timeText = "${selisihTerlewat.inDays} ${getTxt('hari_terlewat')}";
          } else if (selisihTerlewat.inHours > 0) {
            timeText = "${selisihTerlewat.inHours} ${getTxt('jam_terlewat') ?? 'hours overdue'}";
          } else {
            // Jika kurang dari 1 jam, tampilkan menit
            timeText = "${selisihTerlewat.inMinutes} ${getTxt('menit_terlewat') ?? 'minutes overdue'}";
          }
        } else { // Belum terlewat (Tersisa)
          final sisaHari = difference.inDays;
          if (sisaHari == 0) { // Deadline hari ini, tapi belum terlewat jamnya
            timeColor = Colors.orange.shade800;
            timeIcon = Icons.today_rounded;
            timeText = getTxt('deadline_hari_ini') ?? 'Deadline Today';
          } else { // Tersisa lebih dari 1 hari
            timeColor = Colors.green.shade800;
            timeIcon = Icons.timer_outlined;
            timeText = "$sisaHari ${getTxt('hari_tersisa') ?? 'days left'}";
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

    // --- E. BUILD WIDGET CARD ---
    return GestureDetector( // <-- WIDGET PEMBUNGKUS BARU
      onTap: () {
        // Aksi navigasi ke halaman detail
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FindingDetailScreen(
              initialData: data,
              lang: widget.lang, // Teruskan bahasa yang aktif
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Border dinamis berdasarkan tipe inspeksi
          border: Border.all(
            color: borderColor,
            width: borderColor == const Color(0xFFF1F5F9) ? 1.0 : 1.5,
          ),
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
                  // GAMBAR
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 92,
                          height: 92,
                          color: const Color(0xFFF8FAFC),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                        ),
                      ),
                      // --- BADGE DIPINDAHKAN KE KONTEN KANAN ---
                    ],
                  ),
                  const SizedBox(width: 12),

                  // KONTEN
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // JUDUL + POIN EKSKLUSIF (DIpertahankan)
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFFF6B3D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$poin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text(
                                    'Poin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // --- Kumpulan Badge Inspeksi DITARUH DI SINI ---
                        if (badges.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: badges,
                            ),
                          ),

                        Row(
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                lokasi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tanggal,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 13, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    status,
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
            // --- Indikator Waktu (jika ada) ---
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
  State<FilterLocationBottomSheet> createState() =>
      _FilterLocationBottomSheetState();
}

class _FilterLocationBottomSheetState extends State<FilterLocationBottomSheet> {
  int _currentLevel = 0;
  bool _isLoading = true;
  List<dynamic> _currentData = [];
  List<dynamic> _filteredData = [];
  String _searchQuery = "";

  List<Map<String, dynamic>> _navHistory = [];

  String _getTableName(int level) =>
      ['lokasi', 'unit', 'subunit', 'area'][level];
  String _getIdColumn(int level) => 'id_${_getTableName(level)}';
  String _getNameColumn(int level) => 'nama_${_getTableName(level)}';
  String _getChildColumn(int level) =>
      level < 3 ? ['unit', 'subunit', 'area'][level] : '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({int? parentId}) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> data = [];

      if (_currentLevel == 0) {
        data = await supabase
            .from('lokasi')
            .select('id_lokasi, nama_lokasi, unit(id_unit)');
      } else if (_currentLevel == 1) {
        data = await supabase
            .from('unit')
            .select('id_unit, nama_unit, subunit(id_subunit)')
            .eq('id_lokasi', parentId!);
      } else if (_currentLevel == 2) {
        data = await supabase
            .from('subunit')
            .select('id_subunit, nama_subunit, area(id_area)')
            .eq('id_unit', parentId!);
      } else if (_currentLevel == 3) {
        data = await supabase
            .from('area')
            .select('id_area, nama_area')
            .eq('id_subunit', parentId!);
      }

      if (mounted) {
        setState(() {
          _currentData = data;
          _filteredData = List.from(data);
          _sortData();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching locations for filter: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredData = _currentData.where((item) {
        String name = item[_getNameColumn(_currentLevel)]
            .toString()
            .toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
      _sortData();
    });
  }

  void _sortData() {
    _filteredData.sort((a, b) {
      final nameCol = _getNameColumn(_currentLevel);
      return a[nameCol].toString().toLowerCase().compareTo(
        b[nameCol].toString().toLowerCase(),
      );
    });
  }

  void _drillDown(Map<String, dynamic> item) {
    if (_currentLevel == 3) return; // Tidak bisa drill down lebih dari area
    setState(() {
      _navHistory.add({
        'level': _currentLevel,
        'id': item[_getIdColumn(_currentLevel)],
        'name': item[_getNameColumn(_currentLevel)],
      });
      _currentLevel++;
      _searchQuery = "";
    });
    _fetchData(parentId: item[_getIdColumn(_currentLevel - 1)]);
  }

  void _goBack() {
    if (_navHistory.isEmpty) return;
    setState(() {
      _navHistory.removeLast();
      _currentLevel--;
      _searchQuery = "";
    });
    if (_navHistory.isEmpty) {
      _fetchData();
    } else {
      _fetchData(parentId: _navHistory.last['id']);
    }
  }

  // Mengirim hasil pilihan kembali ke Explore Screen
  void _selectLocation(int id, String name, int level) {
    Navigator.pop(context, {'id': id, 'name': name, 'level': level});
  }

  @override
  Widget build(BuildContext context) {
    String currentParentName = _navHistory.isEmpty
        ? "Semua Lokasi"
        : _navHistory.last['name'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Background soft abu-abu
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle Bar Modern
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Row(
              children: [
                if (_navHistory.isNotEmpty)
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    "Filter: $currentParentName",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar Soft Design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: _onSearch,
                      decoration: const InputDecoration(
                        hintText: "Cari area spesifik...",
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // List Data Modern Card
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00C9E4)),
                  )
                : _filteredData.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada data.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final item = _filteredData[index];
                      final int itemId = item[_getIdColumn(_currentLevel)];
                      final String itemName =
                          item[_getNameColumn(_currentLevel)].toString();

                      int subCount = 0;
                      if (_currentLevel < 3) {
                        final listSub =
                            item[_getChildColumn(_currentLevel)]
                                as List<dynamic>?;
                        subCount = listSub?.length ?? 0;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Kiri: Icon Kategori
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF0FDF4,
                                  ), // Hijau sangat muda
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.place_outlined,
                                  color: Color(0xFF10B981),
                                  size: 24,
                                ), // Hijau emerald
                              ),
                            ),

                            // Tengah: Informasi Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  if (_currentLevel < 3) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "$subCount Sub-bagian",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Kanan: Tombol Aksi (Pilih & Buka)
                            Row(
                              children: [
                                // Tombol Pilih (Centang)
                                GestureDetector(
                                  onTap: () => _selectLocation(
                                    itemId,
                                    itemName,
                                    _currentLevel,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF00C9E4,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      "Pilih",
                                      style: TextStyle(
                                        color: Color(0xFF00C9E4),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Tombol Drill Down (Hanya jika belum area terakhir)
                                if (_currentLevel < 3)
                                  GestureDetector(
                                    onTap: () => _drillDown(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(right: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_right_rounded,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 15),
                              ],
                            ),
                          ],
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
