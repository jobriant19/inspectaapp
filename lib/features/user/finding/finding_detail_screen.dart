import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'resolution_camera_screen.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/user_picker_bottom_sheet.dart';
import 'camera_finding_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  Map<String, dynamic>? _currentFindingData;
  late Future<List<Comment>> _commentsFuture;

  // Resolution State
  XFile? _resolutionImageFile;
  final _resolutionNotesController = TextEditingController();
  final _resolutionCostController = TextEditingController();
  bool _isFinishing = false;
  bool _isExtending = false;
  final _extensionReasonController = TextEditingController();
  DateTime? _extensionNewDate;

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
    _loadData(silent: true);
  }

  @override
  void dispose() {
    _resolutionNotesController.dispose();
    _resolutionCostController.dispose();
    _commentController.dispose();
    _extensionReasonController.dispose();
    super.dispose();
  }

  void _loadData({bool silent = false}) {
    final findingId = widget.initialData['id_temuan'].toString();
    _findingDetailFuture = _fetchFindingDetails(findingId);
    _commentsFuture = _fetchComments(findingId);
    if (!silent) setState(() {});
  }

  // ===== DATA FETCHING =====
  Future<Map<String, dynamic>> _fetchFindingDetails(String findingId) async {
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
          User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user),
          User_Creator:User!temuan_id_user_fkey(nama, gambar_user),
          penyelesaian!temuan_id_penyelesaian_fkey( 
            *,
            User_Solver:User!id_user(nama, gambar_user)
          )
        ''')
        .eq('id_temuan', findingId)
        .single();
    return response;
  }

  Future<List<Comment>> _fetchComments(String findingId) async {
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

      final mentionedUserIds = _mentionedUsers
          .map((e) => e['id_user'] as String)
          .toList();

      await Supabase.instance.client.from('komentar').insert({
        'id_temuan': widget.initialData['id_temuan'].toString(),
        'id_user': user.id,
        'isi_komentar': content,
        'mentioned_users': mentionedUserIds.isNotEmpty
            ? mentionedUserIds
            : null,
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

  Future<void> _submitExtension() async {
    if (_extensionReasonController.text.trim().isEmpty) {
      _showErrorSnackbar(_texts['extension_err_reason']!);
      return;
    }
    if (_extensionNewDate == null) {
      _showErrorSnackbar(_texts['extension_err_date']!);
      return;
    }

    // Validasi: tanggal baru harus setelah deadline lama (jika ada)
    final currentDeadline = _currentFindingData != null
        ? DateTime.tryParse(_currentFindingData!['target_waktu_selesai']?.toString() ?? '')
        : null;

    if (currentDeadline != null && _extensionNewDate!.isBefore(currentDeadline)) {
      _showErrorSnackbar(_texts['extension_err_date_past']!);
      return;
    }

    setState(() => _isExtending = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Insert ke tabel perpanjang
      final perpanjangResponse = await supabase
          .from('perpanjang')
          .insert({
            'waktu_perpanjang': DateTime.now().toIso8601String(),
            'alasan_perpanjang': _extensionReasonController.text.trim(),
            'tanggal_selesai': _extensionNewDate!.toIso8601String(),
          })
          .select()
          .single();

      final perpanjangId = perpanjangResponse['id_perpanjang'].toString();

      // 2. Update temuan: set id_perpanjang dan target_waktu_selesai baru
      await supabase
          .from('temuan')
          .update({
            'id_perpanjang': perpanjangId,
            'target_waktu_selesai': _extensionNewDate!.toIso8601String(),
          })
          .eq('id_temuan', widget.initialData['id_temuan'].toString());

      if (mounted) {
        Navigator.pop(context); // tutup bottom sheet
        _showSuccessSnackbar(_texts['extension_success']!);
        _loadData(); // refresh data
      }
    } catch (e) {
      debugPrint('Extension error: $e');
      if (mounted) {
        _showErrorSnackbar('${_texts['extension_fail']!}: $e');
      }
    } finally {
      if (mounted) setState(() => _isExtending = false);
    }
  }

  void _showExtensionBottomSheet(Map<String, dynamic> data) {
    _extensionReasonController.clear();
    _extensionNewDate = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.schedule_rounded,
                            color: Color(0xFF1E3A8A), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _texts['extension']!,
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Deadline lama (jika ada)
                  if (data['target_waktu_selesai'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Deadline saat ini: ${_formatDateTime(data['target_waktu_selesai'], format: 'dd MMM yyyy')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Alasan
                  Text(_texts['extension_reason']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _extensionReasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _texts['extension_reason_hint']!,
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pilih tanggal baru
                  Text(_texts['extension_new_date']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1E3A8A),
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() => _extensionNewDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _extensionNewDate != null
                            ? const Color(0xFF1E3A8A).withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _extensionNewDate != null
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade300,
                          width: _extensionNewDate != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: const Color(0xFF1E3A8A), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _extensionNewDate != null
                                ? DateFormat('EEEE, d MMMM yyyy').format(_extensionNewDate!)
                                : (_texts['extension_new_date']!),
                            style: TextStyle(
                              fontSize: 14,
                              color: _extensionNewDate != null
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                              fontWeight: _extensionNewDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isExtending ? null : _submitExtension,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isExtending
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.schedule_send_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(_texts['extension_submit']!,
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _finishFinding({bool createNewAfter = false}) async {
    if (_resolutionImageFile == null) {
      _showErrorSnackbar(_texts['err_proof_required']!);
      return;
    }

    // Tampilkan loading dialog di tengah layar
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00C9E4)),
              const SizedBox(height: 20),
              Text(
                widget.lang == 'EN'
                    ? 'Saving resolution...'
                    : widget.lang == 'ZH'
                    ? '正在保存...'
                    : 'Menyimpan penyelesaian...',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() => _isFinishing = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final imageBytes = await _resolutionImageFile!.readAsBytes();
      final fileName =
          'resolution/${widget.initialData['id_temuan']}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage
          .from('temuan_images')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      final imageUrl = supabase.storage
          .from('temuan_images')
          .getPublicUrl(fileName);

      final costText = _resolutionCostController.text.trim();
      final additionalCost = double.tryParse(costText);

      // Ambil poin dari temuan untuk penyelesaian
      final temuanData = await supabase
          .from('temuan')
          .select('poin_temuan')
          .eq('id_temuan', widget.initialData['id_temuan'].toString())
          .maybeSingle();

      final int poinPenyelesaian =
          (temuanData?['poin_temuan'] as num?)?.toInt() ?? 0;

      final penyelesaianResponse = await supabase
          .from('penyelesaian')
          .insert({
            'id_user': user.id,
            'gambar_penyelesaian': imageUrl,
            'catatan_penyelesaian': _resolutionNotesController.text.trim(),
            'additional_cost': additionalCost,
            'tanggal_selesai': DateTime.now().toIso8601String(),
            'poin_penyelesaian': poinPenyelesaian,
          })
          .select()
          .single();

      final penyelesaianId = penyelesaianResponse['id_penyelesaian'].toString();

      await supabase
          .from('temuan')
          .update({
            'status_temuan': 'Selesai',
            'id_penyelesaian': penyelesaianId,
          })
          .eq('id_temuan', widget.initialData['id_temuan'].toString());

      // Tutup loading dialog
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      _showSuccessSnackbar(_texts['finish_success']!);

      if (createNewAfter) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CameraFindingScreen(
              lang: widget.lang,
              isProMode: false,
              isVisitorMode: false,
              selectedLocationName: _formatLocation(widget.initialData),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Tutup loading dialog jika error
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showErrorSnackbar('${_texts['finish_fail']}: $e');
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  void _showUserMentionPicker() async {
    // Guard clause untuk memastikan data sudah dimuat
    if (_currentFindingData == null) {
      _showErrorSnackbar('Data temuan belum dimuat sepenuhnya.');
      return;
    }

    final selectedUser = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserPickerBottomSheet(
        lang: widget.lang,
        // Kirim ID lokasi dari data temuan saat ini
        idArea: _currentFindingData!['id_area'],
        idSubunit: _currentFindingData!['id_subunit'],
        idUnit: _currentFindingData!['id_unit'],
        idLokasi: _currentFindingData!['id_lokasi'],
      ),
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

  String _formatDateTime(
    String? dateStr, {
    String format = 'dd MMM yyyy, HH:mm',
  }) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          _currentFindingData = data;
          final b = (data['status_temuan'] as String? ?? '').toLowerCase();
          final isNotFinished = ['belum'].any((e) => b.contains(e));
          final s = (data['status_temuan'] as String? ?? '').toLowerCase();
          final isFinished = [
            'closed',
            'selesai',
            'done',
            'completed',
          ].any((e) => s.contains(e));
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
                      _buildFindingInfoGrid(data),
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
                          padding: const EdgeInsets.only(
                            top: 8.0,
                          ), // beri jarak dari input komentar
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
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.black87,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        _texts['detail_title']!,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black87,
        ),
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
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey,
                        size: 50,
                      ),
                    )
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
    final status = (data['status_temuan'] ?? '').toString();
    final s = status.toLowerCase();
    final isFinished =
        ['closed', 'selesai', 'done', 'completed'].any((e) => s.contains(e));
    final poin = data['poin_temuan'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Poin row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isFinished
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFinished
                        ? const Color(0xFF16A34A).withOpacity(0.3)
                        : const Color(0xFFDC2626).withOpacity(0.3),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isFinished
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
                    size: 13,
                    color: isFinished
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isFinished
                        ? _texts['finish']!
                        : (_texts['err_proof_required'] != null
                            ? (widget.lang == 'ID'
                                ? 'Belum Selesai'
                                : widget.lang == 'ZH'
                                    ? '未完成'
                                    : 'Unfinished')
                            : 'Pending'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isFinished
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ]),
              ),
              const Spacer(),
              if (poin > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFFF6B3D)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '$poin Poin',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Judul
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Lokasi
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: const Color(0xFF0EA5E9), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFindingInfoGrid(Map<String, dynamic> data) {
    final creator = data['User_Creator'] as Map<String, dynamic>?;
    final creatorName = creator?['nama'] as String? ?? 'Pengguna';
    final creatorAvatarUrl = creator?['gambar_user'] as String?;
    final category =
        data['kategoritemuan']?['nama_kategoritemuan'] as String? ?? '-';
    final subCategory =
        data['subkategoritemuan']?['nama_subkategoritemuan'] as String? ??
            '-';
    final createdAt = data['created_at'] as String?;
    final deadline = data['target_waktu_selesai'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          _sectionHeader(
              Icons.info_outline_rounded, _texts['created_by']!,
              color: const Color(0xFF0EA5E9)),
          const SizedBox(height: 12),
          // Creator
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE0F2FE),
                backgroundImage: creatorAvatarUrl != null
                    ? NetworkImage(creatorAvatarUrl)
                    : null,
                child: creatorAvatarUrl == null
                    ? const Icon(Icons.person,
                        color: Color(0xFF0EA5E9))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  creatorName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          // Info rows
          _infoChip(Icons.calendar_today_outlined,
              _texts['reported_on']!, _formatDateTime(createdAt)),
          if (deadline != null) ...[
            const SizedBox(height: 12),
            _infoChip(Icons.timer_outlined,
                widget.lang == 'ID' ? 'Tenggat Waktu' : 'Deadline',
                _formatDateTime(deadline)),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _infoChip(Icons.category_outlined,
              _texts['category']!, category),
          if (subCategory != '-') ...[
            const SizedBox(height: 12),
            _infoChip(Icons.label_important_outline,
                _texts['subcategory']!, subCategory),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String label,
    {Color color = const Color(0xFF1E3A8A)}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfoSection(Map<String, dynamic> data) {
    final assignee = data['User_PIC'] as Map<String, dynamic>?;
    final deadline = data['target_waktu_selesai'] as String?;
    final poin = data['poin_temuan'] as int?;
    final eskalasi = data['eskalasi'] as String?;
    final deskripsi = data['deskripsi_temuan'] as String?;

    return Column(
      children: [
        // Deskripsi
        if (deskripsi != null && deskripsi.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(Icons.notes_rounded,
                    widget.lang == 'ID'
                        ? 'Catatan'
                        : widget.lang == 'ZH'
                            ? '备注'
                            : 'Notes'),
                const SizedBox(height: 12),
                Text(deskripsi,
                    style: const TextStyle(
                        color: Color(0xFF334155),
                        height: 1.6,
                        fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // PIC
        if (assignee != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  Icons.person_pin_rounded,
                  widget.lang == 'ID'
                      ? 'Penanggung Jawab'
                      : widget.lang == 'ZH'
                          ? '负责人'
                          : 'Person in Charge',
                  color: const Color(0xFF7C3AED),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFF5F3FF),
                      backgroundImage: (assignee['gambar_user'] != null)
                          ? NetworkImage(assignee['gambar_user'])
                          : null,
                      child: (assignee['gambar_user'] == null)
                          ? const Icon(Icons.person,
                              color: Color(0xFF7C3AED))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignee['nama'] ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.lang == 'ID'
                                ? 'Ditugaskan untuk menyelesaikan'
                                : widget.lang == 'ZH'
                                    ? '负责解决此问题'
                                    : 'Assigned to resolve',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Status & Detail lainnya
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(Icons.analytics_outlined,
                  widget.lang == 'ID'
                      ? 'Detail Temuan'
                      : widget.lang == 'ZH'
                          ? '发现详情'
                          : 'Finding Details',
                  color: const Color(0xFF0EA5E9)),
              const SizedBox(height: 16),
              _infoChip(Icons.task_alt_outlined,
                  widget.lang == 'ID' ? 'Status' : 'Status',
                  data['status_temuan'] ?? '-'),
              if (deadline != null) ...[
                const SizedBox(height: 12),
                _infoChip(
                  Icons.calendar_month_outlined,
                  widget.lang == 'ID'
                      ? 'Tenggat Waktu'
                      : widget.lang == 'ZH'
                          ? '截止日期'
                          : 'Deadline',
                  _formatDateTime(deadline, format: 'dd MMMM yyyy'),
                ),
              ],
              if (poin != null && poin > 0) ...[
                const SizedBox(height: 12),
                _infoChip(
                  Icons.star_outline_rounded,
                  widget.lang == 'ID'
                      ? 'Poin Temuan'
                      : widget.lang == 'ZH'
                          ? '发现积分'
                          : 'Finding Points',
                  '$poin Poin',
                ),
              ],
              if (eskalasi != null && eskalasi.isNotEmpty) ...[
                const SizedBox(height: 12),
                _infoChip(
                  Icons.escalator_warning_outlined,
                  widget.lang == 'ID'
                      ? 'Level Eskalasi'
                      : widget.lang == 'ZH'
                          ? '升级级别'
                          : 'Escalation Level',
                  eskalasi,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedResolutionSection(
    Map<String, dynamic> resolutionData) {
    final imageUrl = resolutionData['gambar_penyelesaian'] as String?;
    final notes = resolutionData['catatan_penyelesaian'] as String?;
    final cost = resolutionData['additional_cost'] as num?;
    final completedDate = resolutionData['tanggal_selesai'] as String?;
    final solver =
        resolutionData['User_Solver'] as Map<String, dynamic>?;
    final solverName = solver?['nama'] as String? ?? '...';
    final solverAvatarUrl = solver?['gambar_user'] as String?;

    String formattedCost = '-';
    if (cost != null && cost > 0) {
      formattedCost = NumberFormat.currency(
              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(cost);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
            Icons.verified_rounded, _texts['resolution_result']!,
            color: const Color(0xFF16A34A)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFDCFCE7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto penyelesaian
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: Image.network(imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge selesai
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _texts['resolved']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),

                    // Solver
                    if (solver != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFDCFCE7)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  const Color(0xFFDCFCE7),
                              backgroundImage: solverAvatarUrl != null
                                  ? NetworkImage(solverAvatarUrl)
                                  : null,
                              child: solverAvatarUrl == null
                                  ? const Icon(Icons.person,
                                      color: Color(0xFF16A34A),
                                      size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _texts['resolved_by']!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  solverName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Tanggal selesai
                    if (completedDate != null) ...[
                      const SizedBox(height: 12),
                      _infoChip(
                          Icons.event_available_rounded,
                          _texts['completed_on']!,
                          _formatDateTime(completedDate)),
                    ],

                    // Catatan
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _texts['notes']!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(notes,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF166534),
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ],

                    // Biaya
                    if (cost != null && cost > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFEA580C),
                                size: 18),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _texts['cost']!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  formattedCost,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEA580C)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 105, 217, 6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.build_circle_rounded, size: 16, color: Color.fromARGB(255, 76, 217, 6)),
            ),
            const SizedBox(width: 10),
            Text(
              _texts['resolution']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload Foto
              Row(
                children: [
                  Text(
                    _texts['upload_proof']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const Text(' *', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 8),
              if (_resolutionImageFile == null)
                GestureDetector(
                  onTap: _pickResolutionImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF16A34A), size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _texts['upload_proof']!,
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(
                              _resolutionImageFile!.path,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_resolutionImageFile!.path),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickResolutionImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              _texts['change_photo']!,
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Catatan
              Row(
                children: [
                  Text(
                    _texts['resolution_notes']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resolutionNotesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: _texts['resolution_notes_hint'],
                  hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 15),
                  filled: true,
                  fillColor: const Color(0xFFF0FDF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF86EFAC), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // Biaya
              Text(
                widget.lang == 'ZH'
                    ? '费用（可选）'
                    : widget.lang == 'EN'
                        ? 'Cost (Optional)'
                        : 'Biaya Penyelesaian (Opsional)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resolutionCostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.lang == 'ZH' ? '例如：50000' : widget.lang == 'EN' ? 'Example: 50000' : 'Contoh: 50000',
                  prefixText: 'Rp ',
                  hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 15),
                  filled: true,
                  fillColor: const Color(0xFFF0FDF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF86EFAC), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
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
        const Text(
          'Aktivitas & Komentar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Comment>>(
          future: _commentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            final comments = snapshot.data ?? [];
            if (comments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'Belum ada komentar.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) =>
                  _buildCommentItem(comments[index]),
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
          backgroundImage: comment.userAvatarUrl != null
              ? NetworkImage(comment.userAvatarUrl!)
              : null,
          child: comment.userAvatarUrl == null
              ? const Icon(Icons.person_outline, color: Colors.grey, size: 18)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'dd MMM, HH:mm',
                    ).format(comment.createdAt.toLocal()),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.content,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET BARU (disesuaikan untuk mention)
  Widget _buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          _isPostingComment
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _postComment,
                ),
        ],
      ),
    );
  }

  // WIDGET BARU
  Widget _buildActionButtons() {
    // Cek apakah user yang login adalah penanggung jawab
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final picId = _currentFindingData?['id_penanggung_jawab']?.toString();
    final isPIC = currentUserId != null && picId == currentUserId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tombol selesaikan
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isFinishing ? null : () => _finishFinding(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9E4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shadowColor: const Color(0xFF00C9E4).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_outlined, size: 20),
                const SizedBox(width: 8),
                Text(_texts['finish']!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol selesaikan & buat baru
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isFinishing ? null : () => _finishFinding(createNewAfter: true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00C9E4), width: 1.5),
              foregroundColor: const Color(0xFF00C9E4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 20),
                const SizedBox(width: 8),
                Text(_texts['finish_and_new']!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),

        // Tombol perpanjang — hanya muncul jika user adalah PIC
        if (isPIC) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isExtending
                  ? null
                  : () => _showExtensionBottomSheet(_currentFindingData!),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                foregroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _texts['btn_extend'] ??
                        (widget.lang == 'EN' ? 'Extend Deadline' : 'Perpanjang Deadline'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
        'resolved': 'Temuan Selesai',
        'extension': 'Perpanjangan Deadline',
        'extension_reason': 'Alasan Perpanjangan',
        'extension_reason_hint': 'Jelaskan alasan perpanjangan deadline...',
        'extension_new_date': 'Tanggal Deadline Baru',
        'extension_submit': 'Ajukan Perpanjangan',
        'extension_success': 'Perpanjangan berhasil diajukan!',
        'extension_fail': 'Gagal mengajukan perpanjangan',
        'extension_err_reason': 'Alasan perpanjangan wajib diisi!',
        'extension_err_date': 'Tanggal baru wajib dipilih!',
        'extension_err_date_past': 'Tanggal baru harus setelah deadline saat ini!',
        'btn_extend': 'Perpanjang Deadline',
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
        'resolved': 'Finding Resolved',
        'extension': 'Deadline Extension',
        'extension_reason': 'Extension Reason',
        'extension_reason_hint': 'Explain the reason for extending...',
        'extension_new_date': 'New Deadline Date',
        'extension_submit': 'Submit Extension',
        'extension_success': 'Extension submitted successfully!',
        'extension_fail': 'Failed to submit extension',
        'extension_err_reason': 'Extension reason is required!',
        'extension_err_date': 'New date is required!',
        'extension_err_date_past': 'New date must be after current deadline!',
        'btn_extend': 'Extend Deadline',
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
        'resolved': '发现已完成',
        'extension': '截止日期延期',
        'extension_reason': '延期原因',
        'extension_reason_hint': '说明延期原因...',
        'extension_new_date': '新截止日期',
        'extension_submit': '提交延期',
        'extension_success': '延期申请成功！',
        'extension_fail': '延期申请失败',
        'extension_err_reason': '延期原因为必填项！',
        'extension_err_date': '新日期为必填项！',
        'extension_err_date_past': '新日期必须晚于当前截止日期！',
        'btn_extend': '延期截止日期',
      },
    };
    _texts = translations[widget.lang] ?? translations['EN']!;
  }
}
