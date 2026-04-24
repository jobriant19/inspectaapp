import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Screen detail KTS yang bisa dipanggil dari home maupun explore_screen.
/// Tidak memiliki tombol Edit/Delete.
class KtsDetailScreen extends StatefulWidget {
  final int ktsId;
  final String lang;
  /// Data awal (opsional) untuk mengurangi loading awal
  final Map<String, dynamic>? initialData;

  const KtsDetailScreen({
    super.key,
    required this.ktsId,
    required this.lang,
    this.initialData,
  });

  @override
  State<KtsDetailScreen> createState() => _KtsDetailScreenState();
}

class _KtsDetailScreenState extends State<KtsDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isSavingResolution = false;
  String? _currentUserId;
  bool _isDataChanged = false;

  final _tindakanCtrl = TextEditingController();
  final _biayaCtrl = TextEditingController();
  XFile? _resImageFile;

  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Detail KTS Produksi',
      'order': 'No. Order',
      'item': 'Item Produksi',
      'qty': 'Jumlah',
      'kategori': 'Kategori KTS',
      'status': 'Status',
      'reported': 'Dilaporkan',
      'desc': 'Deskripsi',
      'resolution_title': 'Penyelesaian',
      'resolution_done': 'KTS Sudah Selesai',
      'upload_photo': 'Foto Penyelesaian',
      'tindakan': 'Tindakan',
      'tindakan_hint': 'Jelaskan tindakan...',
      'biaya': 'Biaya (Opsional)',
      'biaya_hint': 'Contoh: 50000',
      'save_resolution': 'Simpan Penyelesaian',
      'err_tindakan': 'Tindakan wajib diisi!',
      'err_photo': 'Foto penyelesaian wajib diunggah!',
      'success_res': 'KTS berhasil diselesaikan! +10 poin',
      'fail_res': 'Gagal menyimpan penyelesaian',
      'resolved': 'Selesai',
      'unresolved': 'Belum Selesai',
      'resolved_by': 'Diselesaikan oleh',
      'resolved_at': 'Selesai pada',
      'cost': 'Biaya',
      'kts_badge': 'KTS PRODUKSI',
      'reported_by': 'Dilaporkan oleh',
      'no_resolution': 'Belum ada penyelesaian',
      'ambil_foto': 'Ambil Foto',
      'ganti': 'Ganti',
    },
    'EN': {
      'title': 'KTS Detail',
      'order': 'Order No.',
      'item': 'Production Item',
      'qty': 'Quantity',
      'kategori': 'Category',
      'status': 'Status',
      'reported': 'Reported',
      'desc': 'Description',
      'resolution_title': 'Resolution',
      'resolution_done': 'KTS Finished',
      'upload_photo': 'Resolution Photo',
      'tindakan': 'Action Taken',
      'tindakan_hint': 'Explain action...',
      'biaya': 'Cost (Optional)',
      'biaya_hint': 'Example: 50000',
      'save_resolution': 'Save Resolution',
      'err_tindakan': 'Action description required!',
      'err_photo': 'Resolution photo required!',
      'success_res': 'KTS resolved! +10 points',
      'fail_res': 'Failed to save',
      'resolved': 'Finished',
      'unresolved': 'Unfinished',
      'resolved_by': 'Resolved by',
      'resolved_at': 'Completed on',
      'cost': 'Cost',
      'kts_badge': 'KTS PRODUCTION',
      'reported_by': 'Reported by',
      'no_resolution': 'No resolution yet',
      'ambil_foto': 'Take Photo',
      'ganti': 'Retake',
    },
    'ZH': {
      'title': 'KTS详情',
      'order': '订单号',
      'item': '生产项目',
      'qty': '数量',
      'kategori': '类别',
      'status': '状态',
      'reported': '报告时间',
      'desc': '描述',
      'resolution_title': '解决方案',
      'resolution_done': '已完成',
      'upload_photo': '照片',
      'tindakan': '行动',
      'tindakan_hint': '说明行动...',
      'biaya': '费用（可选）',
      'biaya_hint': '例如：50000',
      'save_resolution': '保存方案',
      'err_tindakan': '行动必填！',
      'err_photo': '照片必填！',
      'success_res': '已完成！+10积分',
      'fail_res': '保存失败',
      'resolved': '已完成',
      'unresolved': '未完成',
      'resolved_by': '解决者',
      'resolved_at': '完成时间',
      'cost': '费用',
      'kts_badge': 'KTS生产',
      'reported_by': '报告人',
      'no_resolution': '尚无解决方案',
      'ambil_foto': '拍照',
      'ganti': '重拍',
    },
  };

  String _t(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    // Gunakan initialData jika tersedia agar terasa lebih cepat
    if (widget.initialData != null) {
      _data = widget.initialData;
      _isLoading = false;
    }
    _loadData();
  }

  @override
  void dispose() {
    _tindakanCtrl.dispose();
    _biayaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.initialData == null) setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('temuan')
          .select('''
            id_temuan, no_order, judul_temuan, deskripsi_temuan,
            gambar_temuan, status_temuan, poin_temuan,
            jumlah_item, nama_item_manual, jenis_temuan,
            created_at, id_user, id_penyelesaian,
            subkategoritemuan:id_subkategoritemuan_uuid(
              id_subkategoritemuan,
              nama_subkategoritemuan
            ),
            kategoritemuan:id_kategoritemuan_uuid(
              id_kategoritemuan,
              nama_kategoritemuan
            ),
            item_produksi:id_item(
              id_item, nama_item, gambar_item, kode_item
            ),
            lokasi:id_lokasi(nama_lokasi)
          ''')
          .eq('id_temuan', widget.ktsId)
          .single();

      Map<String, dynamic>? pelaporData;
      if (data['id_user'] != null) {
        try {
          pelaporData = await Supabase.instance.client
              .from('User')
              .select('nama, gambar_user')
              .eq('id_user', data['id_user'])
              .maybeSingle();
        } catch (_) {}
      }

      Map<String, dynamic>? penyelesaianData;
      final idPenyelesaian = data['id_penyelesaian'];
      if (idPenyelesaian != null) {
        try {
          penyelesaianData = await Supabase.instance.client
              .from('penyelesaian')
              .select(
                  'id_penyelesaian, gambar_penyelesaian, catatan_penyelesaian, tanggal_selesai, poin_penyelesaian, additional_cost, id_user')
              .eq('id_penyelesaian', idPenyelesaian)
              .maybeSingle();
          if (penyelesaianData != null && penyelesaianData['id_user'] != null) {
            final solverRes = await Supabase.instance.client
                .from('User')
                .select('nama, gambar_user')
                .eq('id_user', penyelesaianData['id_user'])
                .maybeSingle();
            penyelesaianData['solver'] = solverRes;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _data = {
            ...data,
            'pelapor': pelaporData,
            'penyelesaian': penyelesaianData,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading KTS detail: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickResImage() async {
    final img = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(builder: (_) => const _KtsDetailCameraScreen()),
    );
    if (img != null && mounted) setState(() => _resImageFile = img);
  }

  Future<void> _saveResolution() async {
    if (_resImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('err_photo')),
          backgroundColor: Colors.redAccent));
      return;
    }
    if (_tindakanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t('err_tindakan')),
          backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _isSavingResolution = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final bytes = await _resImageFile!.readAsBytes();
      final fileName =
          '${user.id}/kts_res_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('temuan_images').uploadBinary(
          fileName, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final imageUrl =
          supabase.storage.from('temuan_images').getPublicUrl(fileName);

      final biayaValue = _biayaCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_biayaCtrl.text.trim());

      final insertRes = await supabase
          .from('penyelesaian')
          .insert({
            'gambar_penyelesaian': imageUrl,
            'catatan_penyelesaian': _tindakanCtrl.text.trim(),
            'additional_cost': biayaValue,
            'tanggal_selesai': DateTime.now().toIso8601String(),
            'id_user': user.id,
            'poin_penyelesaian': 10,
          })
          .select('id_penyelesaian')
          .single();

      final newPenyelesaianId = insertRes['id_penyelesaian'] as int;

      await supabase.from('temuan').update({
        'status_temuan': 'Selesai',
        'id_penyelesaian': newPenyelesaianId,
      }).eq('id_temuan', widget.ktsId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_t('success_res')),
            backgroundColor: Colors.green));
        _isDataChanged = true;
        _loadData();
        setState(() => _isSavingResolution = false);
      }
    } catch (e) {
      debugPrint('Resolution error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${_t('fail_res')}: $e'),
            backgroundColor: Colors.redAccent));
        setState(() => _isSavingResolution = false);
      }
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(d).toLocal());
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _isDataChanged);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2563EB)),
            onPressed: () => Navigator.pop(context, _isDataChanged),
          ),
          title: Text(
            _t('title'),
            style: GoogleFonts.inter(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 17),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey.shade200, height: 1),
          ),
        ),
        body: _isLoading
            ? _buildShimmer()
            : _data == null
                ? Center(
                    child: Text(
                      widget.lang == 'ZH' ? '数据未找到' : widget.lang == 'EN' ? 'Data not found' : 'Data tidak ditemukan',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final status = (d['status_temuan'] ?? '').toString();
    final s = status.toLowerCase();
    final isResolved = s == 'selesai' || s == 'closed' || s == 'teratasi' || s == 'done' || s == 'completed';

    final statusColor = isResolved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg = isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6);
    final statusIcon = isResolved ? Icons.check_circle_rounded : Icons.pending_actions_rounded;
    final statusText = isResolved ? _t('resolved') : _t('unresolved');

    final itemName = d['item_produksi']?['nama_item'] ?? d['nama_item_manual'] ?? '-';
    final itemImg = d['item_produksi']?['gambar_item'];
    final itemKode = d['item_produksi']?['kode_item'] ?? '';
    final subKategori = d['subkategoritemuan']?['nama_subkategoritemuan'] ?? '-';
    final pelapor = d['pelapor'] as Map<String, dynamic>?;
    final penyelesaian = d['penyelesaian'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Header
          if (d['gambar_temuan'] != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(d['gambar_temuan'], width: double.infinity, height: 240, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E40AF), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_t('kts_badge'),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusText, style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(d['judul_temuan'] ?? '-',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 24),

          // Info Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Item header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: itemImg != null
                              ? Image.network(itemImg, width: 60, height: 60, fit: BoxFit.cover)
                              : _buildItemPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(itemName,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A))),
                            if (itemKode.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                child: Text(itemKode,
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _divider(),
                _infoRow(Icons.tag_rounded, _t('order'), d['no_order'] ?? '-'),
                _divider(),
                _infoRow(Icons.inventory_2_outlined, _t('qty'), '${d['jumlah_item'] ?? 0} pcs'),
                _divider(),
                _infoRow(Icons.folder_rounded, _t('kategori'), subKategori),
                _divider(),
                _infoRow(Icons.calendar_today_rounded, _t('reported'), _formatDate(d['created_at'])),
                if (pelapor != null) ...[
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.person_rounded, color: const Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 12),
                        Text(_t('reported_by'), style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
                        const Spacer(),
                        Row(
                          children: [
                            Text(pelapor['nama'] ?? '-',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A))),
                            const SizedBox(width: 8),
                            pelapor['gambar_user'] != null
                                ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(pelapor['gambar_user']))
                                : Container(
                                    width: 28, height: 28,
                                    decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                                    child: const Icon(Icons.person_rounded, size: 14, color: Color(0xFF2563EB)),
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
          const SizedBox(height: 20),

          // Deskripsi
          if (d['deskripsi_temuan'] != null && d['deskripsi_temuan'].toString().isNotEmpty) ...[
            _sectionTitle(Icons.description_rounded, _t('desc')),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
              ),
              child: Text(d['deskripsi_temuan'],
                  style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF334155), height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // Section Penyelesaian
          _sectionTitle(
            isResolved ? Icons.verified_rounded : Icons.build_circle_rounded,
            _t('resolution_title'),
            color: isResolved ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          ),
          const SizedBox(height: 10),

          // Tampilkan hasil penyelesaian jika sudah ada, form jika belum
          if (penyelesaian != null)
            _buildResolutionResult(penyelesaian, isResolved, statusColor, statusBg)
          else
            _buildResolutionForm(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildResolutionResult(Map<String, dynamic> p, bool isResolved, Color statusColor, Color statusBg) {
    final solver = p['solver'] as Map<String, dynamic>?;
    final biaya = p['additional_cost'] as num?;
    final biayaStr = biaya != null && biaya > 0
        ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(biaya)
        : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['gambar_penyelesaian'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(p['gambar_penyelesaian'], width: double.infinity, height: 200, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Text(_t('resolution_done'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF16A34A))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(_t('tindakan'),
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Text(p['catatan_penyelesaian'] ?? '-',
                    style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF0F172A), height: 1.5)),
                if (biaya != null && biaya > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFEA580C), size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('cost'),
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), fontWeight: FontWeight.w600)),
                            Text(biayaStr,
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (solver != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        solver['gambar_user'] != null
                            ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(solver['gambar_user']))
                            : Container(
                                width: 40, height: 40,
                                decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                                child: const Icon(Icons.person_rounded, size: 20, color: Color(0xFFD97706)),
                              ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_t('resolved_by'),
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                            Text(solver['nama'] ?? '-',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (p['tanggal_selesai'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text('${_t('resolved_at')}: ${_formatDate(p['tanggal_selesai'])}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFFD97706).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_t('upload_photo'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
              const Text(' *', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 8),
          _resImageFile == null
              ? GestureDetector(
                  onTap: _pickResImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD97706), size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(_t('ambil_foto'),
                            style: GoogleFonts.inter(color: const Color(0xFFD97706), fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(_resImageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                          : Image.file(File(_resImageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 12, bottom: 12,
                      child: GestureDetector(
                        onTap: _pickResImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(_t('ganti'), style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(_t('tindakan'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
              const Text(' *', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tindakanCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: _t('tindakan_hint'),
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFDE68A), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          Text(_t('biaya'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          TextFormField(
            controller: _biayaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: _t('biaya_hint'),
              prefixText: 'Rp ',
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFDE68A), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: _isSavingResolution
                    ? null
                    : const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFD97706)]),
                color: _isSavingResolution ? const Color(0xFFE2E8F0) : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isSavingResolution
                    ? null
                    : [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                onPressed: _isSavingResolution ? null : _saveResolution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSavingResolution
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(_t('save_resolution'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0xFFF1F5F9));

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
          const Spacer(),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, {Color color = const Color(0xFF2563EB)}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 60, height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB), size: 28),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(height: 240, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(height: 24, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Container(height: 32, width: 260, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 20),
            Container(height: 300, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }
}

// Kamera internal untuk resolution photo
class _KtsDetailCameraScreen extends StatefulWidget {
  const _KtsDetailCameraScreen();

  @override
  State<_KtsDetailCameraScreen> createState() => _KtsDetailCameraScreenState();
}

class _KtsDetailCameraScreenState extends State<_KtsDetailCameraScreen> with WidgetsBindingObserver {
  CameraController? _ctrl;
  List<CameraDescription>? _cameras;
  int _camIndex = 0;
  bool _ready = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _ctrl!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _init() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) await _setCamera(_camIndex);
  }

  Future<void> _setCamera(int i) async {
    await _ctrl?.dispose();
    _ctrl = CameraController(_cameras![i], ResolutionPreset.high, enableAudio: false);
    try {
      await _ctrl!.initialize();
      if (mounted) setState(() => _ready = true);
    } on CameraException catch (e) {
      debugPrint('Camera error: ${e.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 16)));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_ctrl!)),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (img != null && mounted) Navigator.pop(context, img);
                  },
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (_ctrl == null || _ctrl!.value.isTakingPicture) return;
                    try {
                      final pic = await _ctrl!.takePicture();
                      if (mounted) Navigator.pop(context, pic);
                    } on CameraException catch (e) {
                      debugPrint('Snap error: ${e.code}');
                    }
                  },
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    child: Padding(padding: const EdgeInsets.all(4), child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_cameras == null || _cameras!.length < 2) return;
                    setState(() { _ready = false; _camIndex = (_camIndex + 1) % _cameras!.length; });
                    _setCamera(_camIndex);
                  },
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}