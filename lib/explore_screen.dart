import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String _activeChip = ''; // 'assigned', 'location', 'mine', 'inspection'

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
      'reset': 'Reset',
      'terapkan': 'Terapkan',
      'hari_terlewat': 'hari terlewat',
      'temuan_kosong': 'Belum ada temuan.',
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
      'reset': 'Reset',
      'terapkan': 'Apply',
      'hari_terlewat': 'days overdue',
      'temuan_kosong': 'No findings yet.',
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
      'reset': '重置',
      'terapkan': '应用',
      'hari_terlewat': '天逾期',
      'temuan_kosong': '暂无发现。',
      'memuat': '正在加载发现...',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  int? _selectedLokasiId;
  String _selectedLokasiName = '';
  int? _selectedLokasiLevel;
  Future<List<Map<String, dynamic>>>? _findingsFuture;

  @override
  void initState() {
    super.initState();
    _loadFindings();
  }

  // Dummy Data Temuan
  final List<Map<String, dynamic>> _dummyData = [
    {
      'kategori': 'Profesional',
      'judul': 'Suara Horn tidak terdengar jelas dari dalam gudang sel...',
      'lokasi': 'Gudang Selatan',
      'hari_lewat': 28,
      'warna': Colors.amber,
    },
    {
      'kategori': 'Profesional',
      'judul': 'Barang stok masih diarea assy',
      'lokasi': 'Packing WF',
      'hari_lewat': 25,
      'warna': Colors.amber,
    },
    {
      'kategori': 'Profesional',
      'judul': 'Sampel produk dari Wholesome ditaruh mana?',
      'lokasi': 'PPIC WF',
      'hari_lewat': 25,
      'warna': Colors.amber,
    },
  ];

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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        Icon(Icons.filter_list_alt, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Filter",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        )
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00C9E4)),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Gagal memuat temuan.'),
                );
              }

              final allData = snapshot.data ?? [];

              final filteredData = allData.where((item) {
                final statusOk = _activeTab == 0 ? !_isFinished(item) : _isFinished(item);
                final chipOk = _matchesChip(item);
                return statusOk && chipOk;
              }).toList();

              if (filteredData.isEmpty) {
                return Center(
                  child: Text(
                    getTxt('temuan_kosong'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                physics: const BouncingScrollPhysics(),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  return _buildFindingCard(filteredData[index]);
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
        onTap: () => setState(() => _activeTab = index),
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
                color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade500,
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
          _activeChip = isActive ? '' : value; // Toggle aktif/nonaktif
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

  // --- WIDGET HELPER UNTUK CARD DUMMY ---
  Widget _buildDummyCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Dummy
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                ),
                child: Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey.shade200,
                  child: Stack(
                    children: [
                      const Center(child: Icon(Icons.image, color: Colors.grey, size: 40)),
                      // Label Profesional
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: data['warna'],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning_rounded, size: 12, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(
                                data['kategori'],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              // Detail Teks
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['judul'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['lokasi'],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
            ],
          ),
          // Baris Bawah (Hari Terlewat)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8EE), // Warna krem lembut
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Text(
              "${data['hari_lewat']} ${getTxt('hari_terlewat')}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red, // Warna merah sesuai referensi
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- METHOD UNTUK BOTTOM SHEET FILTER ---
  void _showFilterBottomSheet(BuildContext context) {
    bool isPrioritize = false;
    String selectedRole = '';

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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
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
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 15),
                          
                          // Level Eskalasi
                          _buildFilterSubtitle(getTxt('level_eskalasi')),
                          _buildDropdownSelector(Icons.trending_up, getTxt('pilih_level')),
                          const SizedBox(height: 15),

                          // Lokasi Temuan 
                          _buildFilterSubtitle(getTxt('lokasi_temuan')),
                          _buildLocationPickerButton(context, setModalState),
                          const SizedBox(height: 15),

                          // Temuan Inspeksi (Segmented Style)
                          _buildFilterSubtitle(getTxt('temuan_inspeksi')),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                _buildSegmentButton(getTxt('visitor'), selectedRole, (val) => setModalState(() => selectedRole = val)),
                                _buildSegmentDivider(),
                                _buildSegmentButton(getTxt('eksekutif'), selectedRole, (val) => setModalState(() => selectedRole = val)),
                                _buildSegmentDivider(),
                                _buildSegmentButton(getTxt('profesional'), selectedRole, (val) => setModalState(() => selectedRole = val)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // --- URUTKAN BERDASARKAN ---
                          Text(
                            getTxt('sort_by'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 15),

                          // Jenis Temuan Switch
                          _buildFilterSubtitle(getTxt('jenis_temuan')),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(getTxt('prioritas'), style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                Switch.adaptive(
                                  value: isPrioritize,
                                  activeColor: const Color(0xFF00C9E4),
                                  onChanged: (val) => setModalState(() => isPrioritize = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Waktu
                          _buildFilterSubtitle(getTxt('waktu')),
                          _buildDropdownSelector(Icons.calendar_today_outlined, getTxt('terlama')),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons (Reset & Terapkan)
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(getTxt('reset'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade400, // Abu-abu menyesuaikan desain referensi
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(getTxt('terapkan'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  )
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
      child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87))),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String title, String selectedValue, Function(String) onTap) {
    bool isSelected = selectedValue == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6F7F9) : Colors.transparent, // Cyan transparan jika terpilih
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
  Widget _buildLocationPickerButton(BuildContext context, StateSetter setModalState) {
    return GestureDetector(
      onTap: () async {
        // Membuka Bottom Sheet Hierarki Lokasi
        final result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FilterLocationBottomSheet(
            lang: widget.lang,
          ),
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
          border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.maps_home_work_rounded, size: 20, color: Color(0xFF00C9E4)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedLokasiName.isEmpty ? getTxt('pilih_lokasi') : _selectedLokasiName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _selectedLokasiName.isEmpty ? FontWeight.normal : FontWeight.w600,
                  color: _selectedLokasiName.isEmpty ? Colors.black54 : const Color(0xFF1E3A8A),
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
                child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
              )
            else
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  void _loadFindings() {
    _findingsFuture = _fetchFindings();
  }

  Future<List<Map<String, dynamic>>> _fetchFindings() async {
    final response = await Supabase.instance.client
        .from('temuan')
        .select('''
          id_temuan,
          judul_temuan,
          deskripsi_temuan,
          gambar_temuan,
          created_at,
          status_temuan,
          poin_temuan,
          eskalasi,
          id_lokasi,
          id_unit,
          id_subunit,
          id_area,
          lokasi(nama_lokasi),
          unit(nama_unit),
          subunit(nama_subunit),
          area(nama_area),
          kategoritemuan(nama_kategoritemuan),
          subkategoritemuan(nama_subkategoritemuan)
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  bool _isFinished(Map<String, dynamic> item) {
    final status = (item['status_temuan'] ?? '').toString().toLowerCase();
    return status.contains('selesai') ||
        status.contains('closed') ||
        status.contains('done') ||
        status.contains('completed');
  }

  bool _matchesSelectedLocation(Map<String, dynamic> item) {
    if (_selectedLokasiId == null || _selectedLokasiLevel == null) return true;

    switch (_selectedLokasiLevel) {
      case 0:
        return item['id_lokasi'] == _selectedLokasiId;
      case 1:
        return item['id_unit'] == _selectedLokasiId;
      case 2:
        return item['id_subunit'] == _selectedLokasiId;
      case 3:
        return item['id_area'] == _selectedLokasiId;
      default:
        return true;
    }
  }

  bool _matchesChip(Map<String, dynamic> item) {
    if (_activeChip.isEmpty) return true;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    switch (_activeChip) {
      case 'assigned':
        return item['id_penanggung_jawab']?.toString() == currentUserId;
      case 'location':
        return _matchesSelectedLocation(item);
      case 'mine':
        return item['id_penanggung_jawab']?.toString() == currentUserId;
      case 'inspection':
        return (item['eskalasi'] ?? '').toString().isNotEmpty;
      default:
        return true;
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
    final imageUrl = (data['gambar_temuan'] ?? '').toString();
    final title = (data['judul_temuan'] ?? '-').toString();
    final kategori = data['kategoritemuan']?['nama_kategoritemuan']?.toString() ?? '-';
    final subkategori =
        data['subkategoritemuan']?['nama_subkategoritemuan']?.toString() ?? '';
    final lokasi = _formatLocation(data);
    final tanggal = _formatDate(data['created_at']);
    final poin = (data['poin_temuan'] ?? 0).toString();
    final status = (data['status_temuan'] ?? 'Open').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kategori + (subkategori.isNotEmpty ? ' • $subkategori' : ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lokasi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            tanggal,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: status.toLowerCase().contains('open')
                                  ? Colors.orange.withOpacity(0.12)
                                  : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: status.toLowerCase().contains('open')
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8EE),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Text(
              '$poin Poin',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          )
        ],
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
  int _currentLevel = 0; 
  bool _isLoading = true;
  List<dynamic> _currentData = [];
  List<dynamic> _filteredData = [];
  String _searchQuery = "";

  List<Map<String, dynamic>> _navHistory = [];

  String _getTableName(int level) => ['lokasi', 'unit', 'subunit', 'area'][level];
  String _getIdColumn(int level) => 'id_${_getTableName(level)}';
  String _getNameColumn(int level) => 'nama_${_getTableName(level)}';
  String _getChildColumn(int level) => level < 3 ? ['unit', 'subunit', 'area'][level] : '';

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
        data = await supabase.from('lokasi').select('id_lokasi, nama_lokasi, unit(id_unit)');
      } else if (_currentLevel == 1) {
        data = await supabase.from('unit').select('id_unit, nama_unit, subunit(id_subunit)').eq('id_lokasi', parentId!);
      } else if (_currentLevel == 2) {
        data = await supabase.from('subunit').select('id_subunit, nama_subunit, area(id_area)').eq('id_unit', parentId!);
      } else if (_currentLevel == 3) {
        data = await supabase.from('area').select('id_area, nama_area').eq('id_subunit', parentId!);
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
        String name = item[_getNameColumn(_currentLevel)].toString().toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
      _sortData();
    });
  }

  void _sortData() {
    _filteredData.sort((a, b) {
      final nameCol = _getNameColumn(_currentLevel);
      return a[nameCol].toString().toLowerCase().compareTo(b[nameCol].toString().toLowerCase());
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
    String currentParentName = _navHistory.isEmpty ? "Semua Lokasi" : _navHistory.last['name'];

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
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
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
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                Expanded(
                  child: Text(
                    "Filter: $currentParentName",
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9E4)))
                : _filteredData.isEmpty
                ? const Center(child: Text("Tidak ada data.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredData.length,
                    itemBuilder: (context, index) {
                      final item = _filteredData[index];
                      final int itemId = item[_getIdColumn(_currentLevel)];
                      final String itemName = item[_getNameColumn(_currentLevel)].toString();
                      
                      int subCount = 0;
                      if (_currentLevel < 3) {
                        final listSub = item[_getChildColumn(_currentLevel)] as List<dynamic>?;
                        subCount = listSub?.length ?? 0;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            // Kiri: Icon Kategori
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4), // Hijau sangat muda
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.place_outlined, color: Color(0xFF10B981), size: 24), // Hijau emerald
                              ),
                            ),
                            
                            // Tengah: Informasi Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                  ),
                                  if (_currentLevel < 3) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "$subCount Sub-bagian",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
                                    ),
                                  ]
                                ],
                              ),
                            ),

                            // Kanan: Tombol Aksi (Pilih & Buka)
                            Row(
                              children: [
                                // Tombol Pilih (Centang)
                                GestureDetector(
                                  onTap: () => _selectLocation(itemId, itemName, _currentLevel),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00C9E4).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text("Pilih", style: TextStyle(color: Color(0xFF00C9E4), fontWeight: FontWeight.bold, fontSize: 12)),
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
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.black54, size: 20),
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