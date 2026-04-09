import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/resolution_camera_screen.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/user_picker_bottom_sheet.dart';
import 'camera_finding_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 

// Model Comment tidak berubah, jadi tetap
class Comment {
  final String id;
  final String content;
  final DateTime createdAt;
  final String userId;
  final String userName;
  final String? userAvatarUrl;

  Comment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    final user = map['User'] as Map<String, dynamic>?;
    return Comment(
      id: map['id_komentar'].toString(),
      content: map['isi_komentar'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['id_user'] as String,
      userName: user?['nama'] as String? ?? 'Pengguna Anonim',
      userAvatarUrl: user?['gambar_user'] as String?,
    );
  }
}

class FindingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String lang;

  const FindingDetailScreen({
    super.key,
    required this.initialData,
    required this.lang,
  });

  @override
  State<FindingDetailScreen> createState() => _FindingDetailScreenState();
}

class _FindingDetailScreenState extends State<FindingDetailScreen> {
  // Data State
  late Future<Map<String, dynamic>> _findingDetailFuture;
  late Future<List<Comment>> _commentsFuture;
  
  // Resolution State
  XFile? _resolutionImageFile;
  final _resolutionNotesController = TextEditingController();
  final _resolutionCostController = TextEditingController();
  bool _isFinishing = false;

  // Comment State
  final _commentController = TextEditingController();
  final List<Map<String, dynamic>> _mentionedUsers = [];
  bool _isPostingComment = false;

  // Dictionary
  late Map<String, String> _texts;

  @override
  void initState() {
    super.initState();
    _setupTranslations();
    _loadData();
  }

  @override
  void dispose() {
    _resolutionNotesController.dispose();
    _resolutionCostController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _loadData() {
    final findingId = widget.initialData['id_temuan'];
    _findingDetailFuture = _fetchFindingDetails(findingId);
    _commentsFuture = _fetchComments(findingId);
    setState(() {}); // Refresh UI
  }

  // ===== DATA FETCHING =====
  Future<Map<String, dynamic>> _fetchFindingDetails(int findingId) async {
    final response = await Supabase.instance.client
        .from('temuan')
        .select('''
          *,
          lokasi(nama_lokasi),
          unit(nama_unit),
          subunit(nama_subunit),
          area(nama_area),
          kategoritemuan(nama_kategoritemuan),
          subkategoritemuan(nama_subkategoritemuan),
          User_PIC:id_penanggung_jawab(nama, gambar_user),
          User_Creator:User!id_user(nama, gambar_user),
          penyelesaian!temuan_id_penyelesaian_fkey( 
            *,
            User_Solver:User!id_user(nama, gambar_user)
          )
        ''')
        .eq('id_temuan', findingId)
        .single();
    return response;
  }

  Future<List<Comment>> _fetchComments(int findingId) async {
    final response = await Supabase.instance.client
        .from('komentar')
        .select('*, User(nama, gambar_user)')
        .eq('id_temuan', findingId)
        .order('created_at', ascending: true);
    return response.map((map) => Comment.fromMap(map)).toList();
  }
  
  // ===== LOGIC ACTIONS =====
  Future<void> _pickResolutionImage() async {
    final result = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (context) => const ResolutionCameraScreen()),
    );
    if (result != null) {
      setState(() {
        _resolutionImageFile = result;
      });
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPostingComment = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final mentionedUserIds = _mentionedUsers.map((e) => e['id_user'] as String).toList();

      await Supabase.instance.client.from('komentar').insert({
        'id_temuan': widget.initialData['id_temuan'],
        'id_user': user.id,
        'isi_komentar': content,
        'mentioned_users': mentionedUserIds.isNotEmpty ? mentionedUserIds : null,
      });

      _commentController.clear();
      _mentionedUsers.clear();
      _loadData(); // Refresh comment list
    } catch (e) {
      _showErrorSnackbar('Gagal mengirim komentar: $e');
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _finishFinding({bool createNewAfter = false}) async {
    if (_resolutionImageFile == null) {
      _showErrorSnackbar(_texts['err_proof_required']!);
      return;
    }
    
    setState(() => _isFinishing = true);
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // ... (Bagian upload gambar tidak berubah)
      final imageBytes = await _resolutionImageFile!.readAsBytes();
      final fileName = 'resolution/${widget.initialData['id_temuan']}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('temuan_images').uploadBinary(
            fileName, imageBytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final imageUrl = supabase.storage.from('temuan_images').getPublicUrl(fileName);

      final costText = _resolutionCostController.text.trim();
      final additionalCost = double.tryParse(costText);

      // 2. Insert ke tabel 'penyelesaian' 
      final penyelesaianResponse = await supabase.from('penyelesaian').insert({
        // 'id_temuan': widget.initialData['id_temuan'], // <-- BARIS INI DIHAPUS
        'id_user': user.id,
        'gambar_penyelesaian': imageUrl,
        'catatan_penyelesaian': _resolutionNotesController.text.trim(),
        'additional_cost': additionalCost,
        'tanggal_selesai': DateTime.now().toIso8601String(),
      }).select().single();

      final penyelesaianId = penyelesaianResponse['id_penyelesaian'];

      // ... (Sisa fungsi tidak berubah)
      await supabase
          .from('temuan')
          .update({'status_temuan': 'Selesai', 'id_penyelesaian': penyelesaianId})
          .eq('id_temuan', widget.initialData['id_temuan']);
      
      _showSuccessSnackbar(_texts['finish_success']!);

      if (createNewAfter) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CameraFindingScreen(
          lang: widget.lang, isProMode: false, isVisitorMode: false,
          selectedLocationName: _formatLocation(widget.initialData),
        )));
      } else {
        if (!mounted) return;
        Navigator.pop(context, true);
      }

    } catch (e) {
      _showErrorSnackbar('${_texts['finish_fail']}: $e');
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  void _showUserMentionPicker() async {
    final selectedUser = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserPickerBottomSheet(lang: widget.lang),
    );

    if (selectedUser != null) {
      setState(() {
        final userName = selectedUser['nama'];
        _commentController.text += "@$userName ";
        _mentionedUsers.add(selectedUser);
      });
    }
  }

  // ===== UI HELPERS =====
  String _formatLocation(Map<String, dynamic> item) {
    // ... (kode ini sama seperti sebelumnya, tidak perlu diubah)
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
    return 'Lokasi tidak diketahui';
  }
  
  String _formatDateTime(String? dateStr, {String format = 'dd MMM yyyy, HH:mm'}) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      // Coba parsing langsung, ini berhasil jika formatnya sudah ISO (ada 'T')
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat(format, 'id_ID').format(dt);
    } catch (e) {
      // Jika gagal, coba ganti spasi dengan 'T' (untuk format dari database)
      try {
        final parsableDateStr = dateStr.replaceFirst(' ', 'T');
        final dt = DateTime.parse(parsableDateStr).toLocal();
        return DateFormat(format, 'id_ID').format(dt);
      } catch (e2) {
        // Jika masih gagal juga, kembalikan string mentah tapi tanpa mikrodetik
        return dateStr.substring(0, 19).replaceAll('T', ' ');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  // ===== WIDGET BUILDERS =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _findingDetailFuture,
        initialData: widget.initialData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final b = (data['status_temuan'] as String? ?? '').toLowerCase();
          final isNotFinished = ['belum'].any((e) => b.contains(e));
          final s = (data['status_temuan'] as String? ?? '').toLowerCase();
          final isFinished = ['closed', 'selesai', 'done', 'completed'].any((e) => s.contains(e));
          final resolutionData = data['penyelesaian'] as Map<String, dynamic>?;

          // Struktur yang benar adalah menempatkan semua widget di dalam Sliver
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              _buildImageHeader(data),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(data),
                      const SizedBox(height: 16),
                      _buildInspectionBadges(data),
                      const SizedBox(height: 20),
                      _buildDetailedInfoSection(data),
                      const SizedBox(height: 24),
                      _buildFindingInfoGrid(data), // <-- Sekarang sudah benar
                      const SizedBox(height: 24),
                      
                      if (isFinished && resolutionData != null)
                        _buildCompletedResolutionSection(resolutionData)
                      else
                        _buildResolutionSection(),
                      
                      const SizedBox(height: 24),
                      _buildCommentsSection(),
                      const SizedBox(height: 16),

                      // --- URUTAN YANG BENAR DI SINI ---
                      // 1. Input Komentar (selalu ada)
                      _buildCommentInputBar(),
                      
                      // 2. Tombol Aksi (hanya jika belum selesai)
                      if (isNotFinished)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0), // beri jarak dari input komentar
                          child: _buildActionButtons(),
                        ),

                      // Beri jarak di bawah agar tidak terlalu mepet
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    // ... (kode sama)
     return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(_texts['detail_title']!,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
      ),
    );
  }

  SliverToBoxAdapter _buildImageHeader(Map<String, dynamic> data) {
    // ... (kode sama)
    final imageUrl = data['gambar_temuan'] as String?;
    final idTemuan = data['id_temuan'];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Hero(
          tag: 'finding_image_$idTemuan',
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 50))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTitleSection(Map<String, dynamic> data) {
    final title = data['judul_temuan'] as String? ?? 'Tanpa Judul';
    final location = _formatLocation(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.location_on_outlined, color: Colors.grey.shade600, size: 16),
          const SizedBox(width: 4),
          Text(location, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ]),
      ],
    );
  }

  // WIDGET BARU
  Widget _buildInspectionBadges(Map<String, dynamic> data) {
    final isPro = data['is_pro'] == true;
    final isVisitor = data['is_visitor'] == true;
    final isEksekutif = data['is_eksekutif'] == true;
    
    if (!isPro && !isVisitor && !isEksekutif) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (isPro) _buildBadge(_texts['professional']!, Colors.amber.shade700),
        if (isVisitor) _buildBadge(_texts['visitor']!, Colors.blue.shade700),
        if (isEksekutif) _buildBadge(_texts['executive']!, Colors.red.shade700),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // WIDGET BARU
  Widget _buildFindingInfoGrid(Map<String, dynamic> data) {
    // Ambil data dengan aman, berikan nilai default jika null
    final creator = data['User_Creator'] as Map<String, dynamic>?;
    final creatorName = creator?['nama'] as String? ?? 'Pengguna';
    final creatorAvatarUrl = creator?['gambar_user'] as String?;

    final category = data['kategoritemuan']?['nama_kategoritemuan'] as String? ?? '-';
    final subCategory = data['subkategoritemuan']?['nama_subkategoritemuan'] as String? ?? '-';

    final createdAt = data['created_at'] as String?;
    final deadline = data['target_waktu_selesai'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Creator (Dibuat Oleh)
          Text(_texts['created_by']!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: creatorAvatarUrl != null ? NetworkImage(creatorAvatarUrl) : null,
                child: creatorAvatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(creatorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
          
          const Divider(height: 24),

          // Detail Waktu
          _buildInfoRow(Icons.calendar_today_outlined, _texts['reported_on']!, _formatDateTime(createdAt)),
          if (deadline != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.timer_outlined, 'Tenggat Waktu', _formatDateTime(deadline)),
          ],
          
          const Divider(height: 24),

          // Detail Kategori
          _buildInfoRow(Icons.category_outlined, _texts['category']!, category),
          if(subCategory != '-') ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.label_important_outline, _texts['subcategory']!, subCategory),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 20),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  Widget _buildDetailedInfoSection(Map<String, dynamic> data) {
    final assignee = data['User_PIC'] as Map<String, dynamic>?;
    final deadline = data['target_waktu_selesai'] as String?;
    final poin = data['poin_temuan'] as int?;
    final eskalasi = data['eskalasi'] as String?;
    final deskripsi = data['deskripsi_temuan'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CATATAN/DESKRIPSI ---
          if (deskripsi != null && deskripsi.isNotEmpty) ...[
            const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(deskripsi, style: const TextStyle(color: Colors.black87, height: 1.5)),
            const Divider(height: 32),
          ],

          // --- PENANGGUNG JAWAB (PIC) ---
          if (assignee != null) ...[
            const Text('Penanggung Jawab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: (assignee['gambar_user'] != null) ? NetworkImage(assignee['gambar_user']) : null,
                  child: (assignee['gambar_user'] == null) ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(assignee['nama'] ?? '...', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Ditugaskan untuk menyelesaikan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 32),
          ],

          // --- DETAIL LAINNYA (DEADLINE, POIN, ESKALASI) ---
          if (deadline != null || poin != null || eskalasi != null)
            _buildInfoRow(Icons.task_alt_outlined, 'Status', data['status_temuan'] ?? '-'),

          if (deadline != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_month_outlined, 'Tenggat Waktu', _formatDateTime(deadline, format: 'dd MMMM yyyy')),
          ],
          
          if (poin != null && poin > 0) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.star_outline, 'Poin Temuan', '$poin Poin'),
          ],

          if (eskalasi != null && eskalasi.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.escalator_warning_outlined, 'Level Eskalasi', eskalasi),
          ],
        ],
      ),
    );
  }
  
    Widget _buildCompletedResolutionSection(Map<String, dynamic> resolutionData) {
    final imageUrl = resolutionData['gambar_penyelesaian'] as String?;
    final notes = resolutionData['catatan_penyelesaian'] as String?;
    final cost = resolutionData['additional_cost'] as num?;
    final completedDate = resolutionData['tanggal_selesai'] as String?;
    final solver = resolutionData['User_Solver'] as Map<String, dynamic>?;
    final solverName = solver?['nama'] as String? ?? '...';
    final solverAvatarUrl = solver?['gambar_user'] as String?;

    String formattedCost = 'Rp 0';
    if (cost != null) {
      formattedCost = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(cost);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_texts['resolution_result']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Info Penyelesai
              if (solver != null) ...[
                Text(_texts['resolved_by']!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: solverAvatarUrl != null ? NetworkImage(solverAvatarUrl) : null,
                      child: solverAvatarUrl == null ? const Icon(Icons.person, color: Colors.grey, size: 20) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(solverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    )
                  ],
                ),
                const Divider(height: 24),
              ],

              if (completedDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildInfoRow(Icons.check_circle_outline, _texts['completed_on']!, _formatDateTime(completedDate)),
                ),

              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                ),
                
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_texts['notes']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(notes),
              ],

              if (cost != null && cost > 0) ...[
                const SizedBox(height: 16),
                Text(_texts['cost']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(formattedCost, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET BARU
  Widget _buildResolutionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_texts['resolution']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const SizedBox(height: 12),
        // Bagian Upload Gambar
        if (_resolutionImageFile == null)
          GestureDetector(
            onTap: _pickResolutionImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.shade200, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Colors.blueGrey, size: 40),
                  const SizedBox(height: 8),
                  Text(_texts['upload_proof']!, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
        else
          // Tampilan setelah gambar dipilih
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(_resolutionImageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.file(File(_resolutionImageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              TextButton.icon(onPressed: _pickResolutionImage, icon: const Icon(Icons.edit_outlined, size: 16), label: Text(_texts['change_photo']!)),
            ],
          ),
        const SizedBox(height: 16),

        // Bagian Catatan Penyelesaian
        Text(_texts['resolution_notes']!, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _resolutionNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: _texts['resolution_notes_hint'],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white,
          ),
        ),
        
        const SizedBox(height: 16), // <-- Spasi baru

        // Bagian Biaya Penyelesaian (BARU)
        const Text('Biaya Penyelesaian (Opsional)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _resolutionCostController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Contoh: 50000',
            prefixText: 'Rp ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    // ... (kode sama)
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aktivitas & Komentar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        const SizedBox(height: 12),
        FutureBuilder<List<Comment>>(
          future: _commentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
            }
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            final comments = snapshot.data ?? [];
            if (comments.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Belum ada komentar.', style: TextStyle(color: Colors.grey))));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) => _buildCommentItem(comments[index]),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildCommentItem(Comment comment) {
    // ... (kode sama)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: comment.userAvatarUrl != null ? NetworkImage(comment.userAvatarUrl!) : null,
          child: comment.userAvatarUrl == null ? const Icon(Icons.person_outline, color: Colors.grey, size: 18) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd MMM, HH:mm').format(comment.createdAt.toLocal()), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.content, style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
  
  // WIDGET BARU (disesuaikan untuk mention)
  Widget _buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.alternate_email),
            onPressed: _showUserMentionPicker,
            tooltip: _texts['mention_user'],
            color: Colors.blueGrey,
          ),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: _texts['comment_hint'],
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              minLines: 1, maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          _isPostingComment
          ? const SizedBox(width: 44, height: 44, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          : IconButton(
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: _postComment,
            ),
        ],
      ),
    );
  }

  // WIDGET BARU
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: _isFinishing 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _finishFinding(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_texts['finish']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _finishFinding(createNewAfter: true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF16A34A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_texts['finish_and_new']!, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
    );
  }

  // Setup Terjemahan
  void _setupTranslations() {
    const Map<String, Map<String, String>> translations = {
      'ID': {
        'detail_title': 'Detail Temuan',
        'professional': 'Profesional',
        'visitor': 'Visitor',
        'executive': 'Eksekutif',
        'creator': 'Dibuat oleh',
        'category': 'Kategori',
        'subcategory': 'Sub-Kategori',
        'reported_on': 'Dilaporkan pada',
        'resolution': 'Penyelesaian',
        'upload_proof': 'Unggah Bukti Penyelesaian',
        'change_photo': 'Ganti Foto',
        'resolution_notes': 'Catatan Penyelesaian (Opsional)',
        'resolution_notes_hint': 'Jelaskan tindakan yang telah dilakukan...',
        'mention_user': 'Sebut pengguna',
        'comment_hint': 'Tulis komentar...',
        'finish': 'Selesai',
        'finish_and_new': 'Selesaikan & Buat Temuan Baru',
        'err_proof_required': 'Bukti penyelesaian wajib diunggah!',
        'finish_success': 'Temuan berhasil diselesaikan!',
        'finish_fail': 'Gagal menyelesaikan temuan',
        'created_by': 'Dibuat oleh', // <-- BARU
        'resolved_by': 'Diselesaikan oleh', // <-- BARU
        'completed_on': 'Selesai pada', // <-- BARU
        'resolution_result': 'Hasil Penyelesaian', // <-- BARU
        'notes': 'Catatan:', // <-- BARU
        'cost': 'Biaya yang Dikeluarkan:', // <-- BARU
      },
      'EN': {
        'detail_title': 'Finding Detail',
        'professional': 'Professional',
        'visitor': 'Visitor',
        'executive': 'Executive',
        'creator': 'Created by',
        'category': 'Category',
        'subcategory': 'Sub-Category',
        'reported_on': 'Reported on',
        'resolution': 'Resolution',
        'upload_proof': 'Upload Proof of Resolution',
        'change_photo': 'Change Photo',
        'resolution_notes': 'Resolution Notes (Optional)',
        'resolution_notes_hint': 'Describe the actions taken...',
        'mention_user': 'Mention a user',
        'comment_hint': 'Write a comment...',
        'finish': 'Finish',
        'finish_and_new': 'Finish & Create New',
        'err_proof_required': 'Proof of resolution is required!',
        'finish_success': 'Finding finished successfully!',
        'finish_fail': 'Failed to finish finding',
        'created_by': 'Created by', // <-- BARU
        'resolved_by': 'Resolved by', // <-- BARU
        'completed_on': 'Completed on', // <-- BARU
        'resolution_result': 'Resolution Result', // <-- BARU
        'notes': 'Notes:', // <-- BARU
        'cost': 'Cost Incurred:', // <-- BARU
      },
      'ZH': {
        'detail_title': '发现详情',
        'professional': '专业的',
        'visitor': '访客',
        'executive': '行政人员',
        'creator': '创建者',
        'category': '类别',
        'subcategory': '子类别',
        'reported_on': '报告于',
        'resolution': '解决方案',
        'upload_proof': '上传解决方案证明',
        'change_photo': '更换照片',
        'resolution_notes': '解决方案说明（可选）',
        'resolution_notes_hint': '描述已采取的行动...',
        'mention_user': '提及用户',
        'comment_hint': '写评论...',
        'finish': '完成',
        'finish_and_new': '完成并创建新的',
        'err_proof_required': '必须上传解决方案证明！',
        'finish_success': '发现已成功完成！',
        'finish_fail': '完成发现失败',
        'created_by': '创建者', // <-- BARU
        'resolved_by': '解决者', // <-- BARU
        'completed_on': '完成于', // <-- BARU
        'resolution_result': '解决方案结果', // <-- BARU
        'notes': '笔记：', // <-- BARU
        'cost': '产生的费用：', // <-- BARU
      },
    };
    _texts = translations[widget.lang] ?? translations['EN']!;
  }

  Widget _buildUserCard({
    required String name,
    required String? avatarUrl,
    required String role,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              Text(role, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}