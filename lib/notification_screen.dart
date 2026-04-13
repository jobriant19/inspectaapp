import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'finding_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  final String lang;
  const NotificationScreen({super.key, required this.lang});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<Map<String, dynamic>>> _assignedFindingsFuture;

  // Dictionary untuk teks multi-bahasa, disesuaikan untuk layar notifikasi.
  final Map<String, Map<String, String>> _texts = {
    'ID': {
      'title': 'Tugas Saya',
      'empty_title': 'Tidak Ada Tugas',
      'empty_subtitle': 'Saat ini belum ada temuan yang ditugaskan kepada Anda. Nikmati waktu luang Anda!',
      'loading': 'Memuat tugas...',
      'error': 'Gagal memuat tugas',
      // Teks untuk Card (diambil dari explore_screen)
      'belum_selesai': 'Belum Selesai',
      'selesai': 'Selesai',
      'hari_terlewat': 'hari terlewat',
      'jam_terlewat' : 'jam terlewat',
      'menit_terlewat' : 'menit terlewat',
      'hari_tersisa': 'hari tersisa',
      'deadline_hari_ini': 'Deadline hari ini',
      'selesai_pada_label': 'Selesai pada',
    },
    'EN': {
      'title': 'My Tasks',
      'empty_title': 'No Tasks Assigned',
      'empty_subtitle': 'There are currently no findings assigned to you. Enjoy your free time!',
      'loading': 'Loading tasks...',
      'error': 'Failed to load tasks',
      // Teks untuk Card (diambil dari explore_screen)
      'belum_selesai': 'Unfinished',
      'selesai': 'Finished',
      'hari_terlewat': 'days overdue',
      'jam_terlewat' : 'hours overdue',
      'menit_terlewat' : 'minutes overdue',
      'hari_tersisa': 'days left',
      'deadline_hari_ini': 'Deadline today',
      'selesai_pada_label': 'Completed on',
    },
    'ZH': {
      'title': '我的任务',
      'empty_title': '没有分配任务',
      'empty_subtitle': '当前没有分配给您的发现。享受您的空闲时间！',
      'loading': '正在加载任务...',
      'error': '加载任务失败',
      // Teks untuk Card (diambil dari explore_screen)
      'belum_selesai': '未完成',
      'selesai': '已完成',
      'hari_terlewat': '天逾期',
      'jam_terlewat': '小时逾期',
      'menit_terlewat': '分钟逾期', 
      'hari_tersisa': '天剩余',
      'deadline_hari_ini': '截止日期是今天',
      'selesai_pada_label': '完成于',
    },
  };

  String getTxt(String key) => _texts[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _assignedFindingsFuture = _fetchAssignedFindings();
  }

  /// Mengambil data temuan yang ditugaskan ke user yang sedang login
  /// dan statusnya belum 'Selesai'.
  Future<List<Map<String, dynamic>>> _fetchAssignedFindings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Jika tidak ada user, kembalikan list kosong
      return [];
    }

    try {
      final response = await Supabase.instance.client
          .from('temuan')
          .select('''
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
          ''')
          .eq('id_penanggung_jawab', user.id) // Filter utama: sesuai ID penanggung jawab
          .neq('status_temuan', 'Selesai')    // Filter tambahan: hanya yang belum selesai
          .order('created_at', ascending: false); // Urutkan dari yang terbaru

      return response;
    } catch (e) {
      debugPrint("Error fetching assigned findings: $e");
      // Jika terjadi error, lempar kembali untuk ditangani FutureBuilder
      throw Exception(getTxt('error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTxt('title')),
        backgroundColor: const Color(0xFF0EA5E9), // Warna biru dari ExploreScreen
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _assignedFindingsFuture,
        builder: (context, snapshot) {
          // 1. Saat sedang loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00C9E4)),
                  const SizedBox(height: 16),
                  Text(getTxt('loading'), style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 2. Jika terjadi error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${getTxt('error')}: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final findings = snapshot.data ?? [];

          // 3. Jika tidak ada data (tampilan kosong)
          if (findings.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/team_illustration.png', // Gambar dari ExploreScreen
                        width: 220,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.notifications_off_outlined,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        getTxt('empty_title'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getTxt('empty_subtitle'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // 4. Jika ada data, tampilkan list
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: findings.length,
            itemBuilder: (context, index) {
              return _buildFindingCard(findings[index]);
            },
          );
        },
      ),
    );
  }

  // =========================================================================
  // WIDGET CARD & HELPER (Disalin dari explore_screen.dart untuk konsistensi)
  // =========================================================================

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
    final imageUrl = (data['gambar_temuan'] ?? '').toString();
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
    final isFinished = ['selesai', 'done', 'completed', 'closed'].any((e) => s.contains(e));
    
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
      case 'eksekutif+pro+visitor': borderColor = const Color(0xFF9333EA); break;
      case 'pro+visitor': borderColor = const Color(0xFF16A34A); break;
      case 'eksekutif+pro': borderColor = const Color(0xFFEA580C); break;
      case 'eksekutif+visitor': borderColor = const Color(0xFF2563EB); break;
      case 'pro': borderColor = const Color(0xFFF59E0B); break;
      case 'visitor': borderColor = const Color(0xFF3B82F6); break;
      case 'eksekutif': borderColor = const Color(0xFFEF4444); break;
      default: borderColor = const Color(0xFFF1F5F9);
    }

    // --- D. LOGIKA INDIKATOR WAKTU (DEADLINE vs SELESAI) ---
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
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_available_rounded, size: 14, color: statusColor),
            const SizedBox(width: 6),
            Text("${getTxt('selesai_pada_label')} $completionDateText", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
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
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
          ),
          child: Row(
            children: [
              Icon(timeIcon, size: 14, color: timeColor),
              const SizedBox(width: 6),
              Text(timeText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: timeColor)),
            ],
          ),
        );
      }
    }

    // --- E. BUILD WIDGET CARD ---
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => FindingDetailScreen(initialData: data, lang: widget.lang),
        )).then((result) {
          // Jika detail screen ditutup dan mengembalikan nilai 'true' (artinya temuan diselesaikan),
          // maka refresh daftar notifikasi.
          if (result == true) {
            setState(() {
              _assignedFindingsFuture = _fetchAssignedFindings();
            });
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: borderColor == const Color(0xFFF1F5F9) ? 1.0 : 1.5),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
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
                      border: Border.all(color: Colors.black.withOpacity(0.15), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: Container(
                        color: const Color(0xFFF8FAFC),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey))
                            : const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFFF6B3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text('$poin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                                  const SizedBox(width: 3),
                                  const Text('Poin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (badges.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Wrap(spacing: 6, runSpacing: 4, children: badges)),
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Expanded(child: Text(lokasi, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(tanggal, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 13, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(statusText, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
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

  Widget _buildInspectionBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}