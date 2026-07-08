import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/jabatan_helper.dart';
import 'finding_solution_screen.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/widgets/user_picker_bottom_sheet.dart';

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
  // DATA STATE
  late Future<Map<String, dynamic>> _findingDetailFuture;
  Map<String, dynamic>? _currentFindingData;
  late Future<List<Comment>> _commentsFuture;

  // COMMENT STATE
  final _commentController = TextEditingController();
  final List<Map<String, dynamic>> _mentionedUsers = [];
  bool _isPostingComment = false;

  late Map<String, String> _texts;

  @override
  void initState() {
    super.initState();
    _setupTranslations();
    _loadData(silent: true);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadData({bool silent = false}) {
    final findingId = widget.initialData['id_temuan'].toString();
    _findingDetailFuture = _fetchFindingDetails(findingId);
    _commentsFuture = _fetchComments(findingId);
    if (!silent) setState(() {});
  }

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
          User_PIC:User!temuan_id_penanggung_jawab_fkey(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan)),
          User_Creator:User!temuan_id_user_fkey(nama, gambar_user),
          penyelesaian!temuan_id_penyelesaian_fkey( 
            *,
            User_Solver:User!id_user(nama, gambar_user, id_jabatan, is_verificator, jabatan!User_id_jabatan_fkey(nama_jabatan))
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
      _loadData();
    } catch (e) {
      _showErrorSnackbar('Gagal mengirim komentar: $e');
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  void _showUserMentionPicker() async {
    if (_currentFindingData == null) {
      _showErrorSnackbar('Data temuan belum dimuat sepenuhnya.');
      return;
    }

    final selectedUser = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserPickerBottomSheet(
        lang: widget.lang,
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

  String _formatDateTime(
    String? dateStr, {
    String format = 'dd MMM yyyy, HH:mm',
  }) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat(format, 'id_ID').format(dt);
    } catch (e) {
      try {
        final parsableDateStr = dateStr.replaceFirst(' ', 'T');
        final dt = DateTime.parse(parsableDateStr).toLocal();
        return DateFormat(format, 'id_ID').format(dt);
      } catch (e2) {
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

          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          final picId = data['id_penanggung_jawab']?.toString();
          final isPIC = currentUserId != null && picId == currentUserId;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildImageHeader(data),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(data),
                      const SizedBox(height: 16),
                      _buildInspectionBadges(data),
                      const SizedBox(height: 16),
                      _buildPICSection(data),
                      const SizedBox(height: 16),
                      _buildDeadlineSection(data),
                      const SizedBox(height: 16),
                      _buildFindingInfoGrid(data),
                      const SizedBox(height: 16),

                      FindingSolutionScreen(
                        findingData: data,
                        lang: widget.lang,
                        isPIC: isPIC,
                        onDataChanged: _loadData,
                      ),

                      const SizedBox(height: 24),
                      _buildCommentsSection(),
                      const SizedBox(height: 16),

                      _buildCommentInputBar(),

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
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1D72F3),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        _texts['detail_title']!,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFF1D72F3),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildImageHeader(Map<String, dynamic> data) {
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.5),
                child: Container(
                  color: Colors.grey.shade200,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : const Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(Map<String, dynamic> data) {
    final title = data['judul_temuan'] as String? ?? 'Tanpa Judul';
    final status = (data['status_temuan'] ?? '').toString();
    final s = status.toLowerCase();
    final isFinished =
        ['closed', 'selesai', 'done', 'completed'].any((e) => s.contains(e));
    final poin = data['poin_temuan'] as int? ?? 0;
    final deskripsi = data['deskripsi_temuan'] as String?;
    final jenis = (data['jenis_temuan'] ?? '').toString();
    final isKts = jenis == 'KTS Production';
    final jenisLabel = isKts ? 'KTS' : '5R';
    final jenisColor = isKts ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LINE 1: TITLE (LEFT) + 5R/KTS & POINTS BADGE (RIGHT)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: jenisColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: jenisColor, width: 1.2),
                ),
                child: Text(
                  jenisLabel,
                  style: GoogleFonts.inter(
                    color: jenisColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (poin > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                      const Icon(Icons.local_fire_department_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('$poin',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                      const SizedBox(width: 2),
                      Text(_poinLabelDetail(),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 9.5)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // LINE 2: SPESIFIC LOCATION BADGE (LEFT) + STATUS (RIGHT)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _buildLocationBadgeDetail(data)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isFinished
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFinished
                        ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                        : const Color(0xFFDC2626).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFinished
                          ? Icons.check_circle_rounded
                          : Icons.pending_actions_rounded,
                      size: 14,
                      color: isFinished
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isFinished
                          ? _texts['finish']!
                          : (widget.lang == 'ID'
                              ? 'Belum Selesai'
                              : widget.lang == 'ZH'
                                  ? '未完成'
                                  : 'Unfinished'),
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isFinished
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // LINE 3: NOTES
          if (deskripsi != null && deskripsi.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.description_rounded, size: 16, color: Color(0xFF1D72F3)),
                const SizedBox(width: 8),
                Text(
                  widget.lang == 'ID'
                      ? 'Catatan'
                      : widget.lang == 'ZH'
                          ? '备注'
                          : 'Notes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D72F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                deskripsi,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF334155),
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _poinLabelDetail() {
    switch (widget.lang) {
      case 'EN':
        return 'Pts';
      case 'ZH':
        return '积分';
      default:
        return 'Poin';
    }
  }

  Map<String, dynamic> _locationBadgeInfoDetail(Map<String, dynamic> item) {
    if (item['area'] != null && item['area']['nama_area'] != null) {
      return {
        'label': item['area']['nama_area'].toString(),
        'icon': Icons.place_rounded,
        'color': const Color(0xFFF472B6),
      };
    }
    if (item['subunit'] != null && item['subunit']['nama_subunit'] != null) {
      return {
        'label': item['subunit']['nama_subunit'].toString(),
        'icon': Icons.layers_rounded,
        'color': const Color(0xFFFBBF24),
      };
    }
    if (item['unit'] != null && item['unit']['nama_unit'] != null) {
      return {
        'label': item['unit']['nama_unit'].toString(),
        'icon': Icons.business_rounded,
        'color': const Color(0xFF6366F1),
      };
    }
    if (item['lokasi'] != null && item['lokasi']['nama_lokasi'] != null) {
      return {
        'label': item['lokasi']['nama_lokasi'].toString(),
        'icon': Icons.location_city_rounded,
        'color': const Color(0xFF10B981),
      };
    }
    return {
      'label': '-',
      'icon': Icons.location_off_rounded,
      'color': const Color(0xFF94A3B8),
    };
  }

  Widget _buildLocationBadgeDetail(Map<String, dynamic> data) {
    final loc = _locationBadgeInfoDetail(data);
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
              style: GoogleFonts.poppins(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

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
        color: color.withValues(alpha:0.15),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // REPORTED BY
          _sectionHeader(
              Icons.info_outline_rounded, _texts['reported_by']!,
              color: const Color(0xFF0EA5E9)),
          const SizedBox(height: 12),
          // REPORTER
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
          // INFO ROWS
          _infoChipBlue(Icons.calendar_today_outlined,
              _texts['reported_on']!, _formatDateTime(createdAt)),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _infoChipBlue(Icons.category_outlined,
              _texts['category']!, category),
          if (subCategory != '-') ...[
            const SizedBox(height: 12),
            _infoChipBlue(Icons.label_important_outline,
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
            color: color.withValues(alpha:0.1),
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

  Widget _infoChipBlue(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF1D72F3).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF1D72F3)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF1D72F3),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPICSection(Map<String, dynamic> data) {
    final assignee = data['User_PIC'] as Map<String, dynamic>?;
    if (assignee == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                    ? const Icon(Icons.person, color: Color(0xFF7C3AED))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignee['nama'] ?? '-',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPICJabatanBadge(assignee),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPICJabatanBadge(Map<String, dynamic> assignee) {
    final idJabatan = assignee['id_jabatan'] as int?;
    final isVerificator = assignee['is_verificator'] as bool?;
    final jabatanNama =
        (assignee['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'] as String?;

    final label = JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerificator,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
    if (label.isEmpty) return const SizedBox.shrink();

    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerificator, idJabatan: idJabatan);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineSection(Map<String, dynamic> data) {
    final deadline = data['target_waktu_selesai'] as String?;
    if (deadline == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.timer_outlined,
                size: 18, color: Color(0xFFDC2626)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lang == 'ID'
                      ? 'Tenggat Waktu'
                      : widget.lang == 'ZH'
                          ? '截止日期'
                          : 'Deadline',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(deadline, format: 'dd MMMM yyyy'),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _texts['comments_title']!,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D72F3),
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1D72F3),
                  ),
                ),
              );
            }
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            final comments = snapshot.data ?? [];
            if (comments.isEmpty) {
              return _buildEmptyCommentsState();
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

  Widget _buildEmptyCommentsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D72F3).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1D72F3).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/team_illustration.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            _texts['no_comments_title']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D72F3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _texts['no_comments_subtitle']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1D72F3).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
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
            color: Colors.black.withValues(alpha:0.05),
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
                    backgroundColor: const Color(0xFF1D72F3),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _postComment,
                ),
        ],
      ),
    );
  }

  void _setupTranslations() {
    const Map<String, Map<String, String>> translations = {
      'ID': {
        'detail_title': 'Detail Temuan',
        'comments_title': 'Komentar',
        'no_comments_title': 'Belum Ada Komentar',
        'no_comments_subtitle': 'Jadilah yang pertama memberikan komentar atau masukan pada temuan ini.',
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
        'created_by': 'Dibuat oleh', 
        'reported_by': 'Dilaporkan oleh',
        'resolved_by': 'Diselesaikan oleh', 
        'completed_on': 'Selesai pada', 
        'resolution_result': 'Hasil Penyelesaian', 
        'notes': 'Catatan:', 
        'cost': 'Biaya yang Dikeluarkan:', 
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
        'comments_title': 'Comments',
        'no_comments_title': 'No Comments Yet',
        'no_comments_subtitle': 'Be the first to add a comment or feedback on this finding.',
        'professional': 'Professional',
        'visitor': 'Visitor',
        'executive': 'Executive',
        'creator': 'Created by',
        'category': 'Category',
        'subcategory': 'Sub-Category',
        'reported_on': 'Reported on',
        'resolution': 'Solution',
        'upload_proof': 'Upload Proof of Solution',
        'change_photo': 'Change Photo',
        'resolution_notes': 'Solution Notes (Optional)',
        'resolution_notes_hint': 'Describe the actions taken...',
        'mention_user': 'Mention a user',
        'comment_hint': 'Write a comment...',
        'finish': 'Finish',
        'finish_and_new': 'Finish & Create New',
        'err_proof_required': 'Proof of solution is required!',
        'finish_success': 'Finding finished successfully!',
        'finish_fail': 'Failed to finish finding',
        'created_by': 'Created by', 
        'reported_by': 'Reported by',
        'resolved_by': 'Resolved by', 
        'completed_on': 'Completed on', 
        'resolution_result': 'Solution Result', 
        'notes': 'Notes:', 
        'cost': 'Cost Incurred:', 
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
        'comments_title': '评论',
        'no_comments_title': '暂无评论',
        'no_comments_subtitle': '成为第一个对此发现发表评论或反馈的人。',
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
        'created_by': '创建者', 
        'reported_by': '报告者',
        'resolved_by': '解决者', 
        'completed_on': '完成于', 
        'resolution_result': '解决方案结果', 
        'notes': '笔记：', 
        'cost': '产生的费用：', 
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