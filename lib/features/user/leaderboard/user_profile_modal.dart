import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// GANTILAH DENGAN WARNA ASLI APLIKASI ANDA
const Color primaryColor = Color(0xFF0EA5E9);
const Color textPrimaryColor = Color(0xFF0C4A6E);
const Color textSecondaryColor = Color(0xFF64748B);

class UserProfileModal extends StatefulWidget {
  final ScrollController controller;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int userRank;

  const UserProfileModal({
    super.key,
    required this.controller,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.userRank,
  });

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header (User Info)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Handle untuk drag
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                // Info User
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: (widget.userAvatarUrl != null) ? NetworkImage(widget.userAvatarUrl!) : null,
                      child: (widget.userAvatarUrl == null) ? Text(widget.userName[0]) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimaryColor)),
                          const SizedBox(height: 2),
                          // Ganti 1162 dengan total poin user yang sebenarnya dari tabel User
                          FutureBuilder<int>(
                            future: _fetchTotalPoints(widget.userId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Text('... Poin', style: TextStyle(color: textSecondaryColor));
                              return Text('${snapshot.data} Poin', style: const TextStyle(color: textSecondaryColor, fontWeight: FontWeight.w600));
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('#${widget.userRank}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimaryColor)),
                    )
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: textSecondaryColor,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'Log Aktivitas'),
              Tab(text: 'Temuan'),
              Tab(text: 'Penyelesaian'),
            ],
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivityLogTab(widget.userId),
                _buildListTab('temuan', widget.userId), // Tab untuk Temuan
                _buildListTab('penyelesaian', widget.userId), // Tab untuk Penyelesaian
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _fetchTotalPoints(String userId) async {
    final response = await Supabase.instance.client
        .from('User')
        .select('poin')
        .eq('id_user', userId)
        .single();
    return response['poin'] ?? 0;
  }

  Widget _buildActivityLogTab(String userId) {
    return FutureBuilder<List<dynamic>>(
      future: Supabase.instance.client.from('log_poin').select().eq('id_user', userId).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tidak ada aktivitas.'));
        }
        final logs = snapshot.data!;
        return ListView.builder(
          controller: widget.controller,
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final poin = log['poin'] as int;
            final isPositive = poin > 0;
            return ListTile(
              title: Text(log['deskripsi'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(log['created_at'])), style: const TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline, color: isPositive ? Colors.green : Colors.red, size: 18),
                  const SizedBox(width: 4),
                  Text((isPositive ? '+$poin' : '$poin'), style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red, fontSize: 16)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListTab(String type, String userId) {
  late final Future<List<dynamic>> future;

  if (type == 'temuan') {
    // Query untuk Temuan. Menambahkan select relasi untuk konsistensi.
    future = Supabase.instance.client
        .from('temuan')
        .select('*, lokasi(*), area(*)') // Eksplisit mengambil data relasi
        .eq('id_user', userId)
        .order('created_at', ascending: false);
  } else if (type == 'penyelesaian') {
    // Query untuk Penyelesaian
    future = Supabase.instance.client
        .from('penyelesaian')
        // Menggunakan 'temuan!inner' sudah benar.
        .select('*, temuan!inner(*, lokasi(*), area(*))')
        .eq('id_user', userId)
        .order('tanggal_selesai', ascending: false);
  } else {
    future = Future.value([]);
  }

  return FutureBuilder<List<dynamic>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        debugPrint('Error fetching $type: ${snapshot.error}');
        // Ganti pesan error agar lebih informatif
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Gagal memuat data $type.\nError: ${snapshot.error}', textAlign: TextAlign.center),
          ),
        );
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('Tidak ada data $type.'));
      }

      final items = snapshot.data!;
      return ListView.builder(
        controller: widget.controller,
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          String? displayTitle;
          String? displayLocation;
          String? displayImageUrl;
          DateTime? displayDate;

          if (type == 'temuan') {
            displayTitle = item['judul_temuan'];
            displayLocation = item['lokasi']?['nama_lokasi'] ?? item['area']?['nama_area'] ?? 'Lokasi tidak diketahui';
            displayImageUrl = item['gambar_temuan'];
            displayDate = DateTime.tryParse(item['created_at'] ?? '');
          } else { // type == 'penyelesaian'
            
            // ================== PERBAIKAN UTAMA DI SINI ==================
            // 'temuan' adalah sebuah List, jadi kita perlu cek dan ambil elemen pertamanya.
            final temuanList = item['temuan'] as List<dynamic>?;
            Map<String, dynamic>? temuanData;

            if (temuanList != null && temuanList.isNotEmpty) {
              temuanData = temuanList.first as Map<String, dynamic>;
            }
            // =============================================================

            displayTitle = temuanData?['judul_temuan'];
            displayLocation = temuanData?['lokasi']?['nama_lokasi'] ?? temuanData?['area']?['nama_area'] ?? 'Lokasi tidak diketahui';
            displayImageUrl = item['gambar_penyelesaian'];
            displayDate = DateTime.tryParse(item['tanggal_selesai'] ?? '');
          }

          // ... (Sisa kode Card tidak perlu diubah)
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        displayImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(width: 80, height: 80, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400]));
                        },
                      ),
                    ),
                  if (displayImageUrl != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayTitle ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: textSecondaryColor),
                            const SizedBox(width: 4),
                            Expanded(child: Text(displayLocation ?? 'Lokasi tidak diketahui', style: const TextStyle(fontSize: 12, color: textSecondaryColor), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (displayDate != null)
                          Text(
                            type == 'temuan' ? 'Dibuat pada: ${DateFormat('d MMM yyyy').format(displayDate)}' : 'Selesai pada: ${DateFormat('d MMM yyyy').format(displayDate)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
}