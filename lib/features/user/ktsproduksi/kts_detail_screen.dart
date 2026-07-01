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

import '../../../core/services/location_service.dart';

/// Screen detail KTS yang bisa dipanggil dari home maupun explore_screen.
/// Tidak memiliki tombol Edit/Delete.
class KtsDetailScreen extends StatefulWidget {
  final String ktsId;
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
  bool _isLoading = false;
  bool _isSavingResolution = false;
  bool _isDataChanged = false;

  final _tindakanCtrl = TextEditingController();
  final _biayaCtrl = TextEditingController();
  final _penyebabCtrl = TextEditingController();
  XFile? _resImageFile;
  List<Map<String, dynamic>> _subKategoriList = [];
  Map<String, dynamic>? _selectedSubKategori;
  String? _selectedBagian;

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
      'pic_label': 'Penanggung Jawab',
      'bagian': 'Bagian',
      'pick_bagian': 'Pilih Bagian',
      'cause': 'Penyebab',
      'cause_hint': 'Jelaskan penyebab...',
      'cause_factor': 'Faktor Penyebab',
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
      'resolution_title': 'Solution',
      'resolution_done': 'KTS Finished',
      'upload_photo': 'Solution Photo',
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
      'pic_label': 'Person in Charge',
      'bagian': 'Section',
      'pick_bagian': 'Select Section',
      'cause': 'Cause',
      'cause_hint': 'Describe the cause...',
      'cause_factor': 'Cause Factor',
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
      'pic_label': '负责人',
      'bagian': '部门',
      'pick_bagian': '选择部门',
      'cause': '原因',
      'cause_hint': '说明原因...',
      'cause_factor': '原因因素',
    },
  };

  String _t(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _loadSubKategoriKtsProduksi();
    if (widget.initialData != null) {
      _data = widget.initialData;
      _isLoading = false;
      // Load data di background tanpa menampilkan shimmer
      _loadDataSilently();
    } else {
      _loadData();
    }
  }

  Future<void> _loadSubKategoriKtsProduksi() async {
    try {
      // Ambil id kategoritemuan dengan nama_kategoritemuan = 'KTS Produksi'
      final katData = await Supabase.instance.client
          .from('kategoritemuan')
          .select('id_kategoritemuan')
          .eq('nama_kategoritemuan', 'KTS Produksi')
          .maybeSingle();
      if (katData == null) return;
      final String katId = katData['id_kategoritemuan'].toString();

      final data = await Supabase.instance.client
          .from('subkategoritemuan')
          .select('id_subkategoritemuan, nama_subkategoritemuan')
          .eq('id_kategoritemuan', katId)
          .order('nama_subkategoritemuan');
      if (mounted) {
        setState(() => _subKategoriList = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint('Error load subkategori KTS Produksi: $e');
    }
  }

  Future<void> _loadDataSilently() async {
    try {
      final data = await Supabase.instance.client
          .from('temuan')
          .select('''
            id_temuan, no_order, judul_temuan, deskripsi_temuan,
            gambar_temuan, status_temuan, poin_temuan,
            jumlah_item, nama_item_manual, jenis_temuan,
            created_at, id_user, id_penyelesaian,
            id_penanggung_jawab,
            subkategoritemuan:id_subkategoritemuan_uuid(
              id_subkategoritemuan, nama_subkategoritemuan
            ),
            item_produksi:id_item(id_item, nama_item, gambar_item, kode_item),
            lokasi:id_lokasi(nama_lokasi),
            penanggung_jawab:id_penanggung_jawab(id_user, nama, gambar_user)
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
                'id_penyelesaian, gambar_penyelesaian, catatan_penyelesaian, '
                'tanggal_selesai, poin_penyelesaian, additional_cost, id_user, '
                'penyebab, bagian, id_subkategoritemuan_penyebab, '
                'faktor_penyebab_kts:id_subkategoritemuan_penyebab(id_subkategoritemuan, nama_subkategoritemuan)',
              )
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
        });
      }
    } catch (e) {
      debugPrint('Error loading KTS detail silently: $e');
    }
  }

  @override
  void dispose() {
    _tindakanCtrl.dispose();
    _biayaCtrl.dispose();
    _penyebabCtrl.dispose();
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
            id_penanggung_jawab,
            subkategoritemuan:id_subkategoritemuan_uuid(
              id_subkategoritemuan, nama_subkategoritemuan
            ),
            item_produksi:id_item(id_item, nama_item, gambar_item, kode_item),
            lokasi:id_lokasi(nama_lokasi),
            penanggung_jawab:id_penanggung_jawab(id_user, nama, gambar_user)
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
                'id_penyelesaian, gambar_penyelesaian, catatan_penyelesaian, '
                'tanggal_selesai, poin_penyelesaian, additional_cost, id_user, '
                'penyebab, bagian, id_subkategoritemuan_penyebab, '
                'faktor_penyebab_kts:id_subkategoritemuan_penyebab(id_subkategoritemuan, nama_subkategoritemuan)',
              )
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
          if (penyelesaianData != null) {
            if (penyelesaianData['penyebab'] != null) {
              _penyebabCtrl.text = penyelesaianData['penyebab'];
            }
            if (penyelesaianData['bagian'] != null) {
              _selectedBagian = penyelesaianData['bagian'];
            }
            if (penyelesaianData['faktor_penyebab_kts'] != null) {
              _selectedSubKategori = Map<String, dynamic>.from(
                penyelesaianData['faktor_penyebab_kts'],
              );
            }
          }
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

  Future<void> _showSectionPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _KtsDetailSectionPickerSheet(lang: widget.lang),
    );
    if (result != null) {
      final name = widget.lang == 'EN'
          ? (result['nama_section_en']?.toString() ?? result['nama_section_id']?.toString())
          : widget.lang == 'ZH'
              ? (result['nama_section_zh']?.toString() ?? result['nama_section_id']?.toString())
              : result['nama_section_id']?.toString();
      setState(() => _selectedBagian = name);
    }
  }

  Future<void> _saveResolution() async {
    // ── Cek lokasi sebelum simpan penyelesaian ──
    final locResult = await LocationService.instance.checkUserAtAtmi(
      forceRefresh: true,
    );
    if (!locResult.isAtAtmi) {
      if (!mounted) return;
      final msg = widget.lang == 'EN'
          ? 'Resolution can only be submitted within PT ATMI Solo area.'
          : widget.lang == 'ZH'
              ? '解决方案只能在PT ATMI Solo区域内提交。'
              : 'Penyelesaian hanya dapat dilakukan di area PT ATMI Solo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.location_off_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ]),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

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

      // MASUKKAN PENYEBAB & ID FAKTOR KE TABEL PENYELESAIAN DI SINI
      final insertRes = await supabase
        .from('penyelesaian')
        .insert({
          'gambar_penyelesaian': imageUrl,
          'catatan_penyelesaian': _tindakanCtrl.text.trim(),
          'additional_cost': biayaValue,
          'tanggal_selesai': DateTime.now().toIso8601String(),
          'id_user': user.id,
          'poin_penyelesaian': 10,
          'penyebab': _penyebabCtrl.text.trim().isEmpty
              ? (_selectedSubKategori != null ? _selectedSubKategori!['nama_subkategoritemuan'] : null)
              : _penyebabCtrl.text.trim(),
          'bagian': _selectedBagian,
          'id_subkategoritemuan_penyebab': _selectedSubKategori?['id_subkategoritemuan'],
        })
        .select('id_penyelesaian')
        .single();

      final String newPenyelesaianId = insertRes['id_penyelesaian'].toString();

      // HAPUS UPDATE PENYEBAB DARI TABEL TEMUAN
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
    final isResolved =
        s == 'selesai' || s == 'closed' || s == 'teratasi' || s == 'done' || s == 'completed';

    final statusColor = isResolved ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8);
    final statusBg    = isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF);
    final statusIcon  = isResolved ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.clock_solid;
    final statusText  = isResolved ? _t('resolved') : _t('unresolved');

    final itemName   = d['item_produksi']?['nama_item'] ?? d['nama_item_manual'] ?? '-';
    final itemImg    = d['item_produksi']?['gambar_item'];
    final itemKode   = d['item_produksi']?['kode_item'] ?? '';
    // ignore: unused_local_variable
    final subKategori = d['subkategoritemuan']?['nama_subkategoritemuan'] ?? '-';
    final pelapor    = d['pelapor'] as Map<String, dynamic>?;
    final picData    = d['penanggung_jawab'] as Map<String, dynamic>?;
    final penyelesaian = d['penyelesaian'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header image
          if (d['gambar_temuan'] != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(d['gambar_temuan'], width: double.infinity, height: 240, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Badges
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
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
                border: Border.all(color: statusColor.withValues(alpha:0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(statusText, style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(d['judul_temuan'] ?? '-',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
          const SizedBox(height: 24),

          // Info Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF1D4ED8).withValues(alpha:0.06), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              // Item header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: itemImg != null
                          ? Image.network(itemImg, width: 60, height: 60, fit: BoxFit.cover)
                          : _buildItemPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A))),
                      if (itemKode.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                          child: Text(itemKode,
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  )),
                ]),
              ),
              _divider(),
              _infoRow(CupertinoIcons.tag,         _t('order'),    d['no_order'] ?? '-'),
              _divider(),
              _infoRow(CupertinoIcons.cube_box,    _t('qty'),      '${d['jumlah_item'] ?? 0} pcs'),
              _divider(),
              _infoRow(CupertinoIcons.calendar,    _t('reported'), _formatDate(d['created_at'])),

              // PIC
              if (picData != null) ...[
                _divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    const Icon(CupertinoIcons.person_fill, color: Color(0xFF1D4ED8), size: 18),
                    const SizedBox(width: 12),
                    Text(_t('pic_label'), style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
                    const Spacer(),
                    Row(children: [
                      Text(picData['nama'] ?? '-',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A))),
                      const SizedBox(width: 8),
                      picData['gambar_user'] != null
                          ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(picData['gambar_user']))
                          : Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                              child: const Icon(CupertinoIcons.person_fill, size: 14, color: Color(0xFF1D4ED8)),
                            ),
                    ]),
                  ]),
                ),
              ],

              // Reported by
              if (pelapor != null) ...[
                _divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    const Icon(CupertinoIcons.person_2_fill, color: Color(0xFF1D4ED8), size: 18),
                    const SizedBox(width: 12),
                    Text(_t('reported_by'), style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
                    const Spacer(),
                    Row(children: [
                      Text(pelapor['nama'] ?? '-',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A))),
                      const SizedBox(width: 8),
                      pelapor['gambar_user'] != null
                          ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(pelapor['gambar_user']))
                          : Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                              child: const Icon(CupertinoIcons.person_fill, size: 14, color: Color(0xFF1D4ED8)),
                            ),
                    ]),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 20),

          // Deskripsi
          if (d['deskripsi_temuan'] != null && d['deskripsi_temuan'].toString().isNotEmpty) ...[
            _sectionTitle(CupertinoIcons.doc_text, _t('desc')),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              ),
              child: Text(d['deskripsi_temuan'],
                  style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF334155), height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // Solution section
          _sectionTitle(
            isResolved ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.wrench_fill,
            _t('resolution_title'),
            color: isResolved ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8),
          ),
          const SizedBox(height: 10),
          if (penyelesaian != null)
            _buildResolutionResult(penyelesaian, isResolved, statusColor, statusBg)
          else
            _buildResolutionForm(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildResolutionResult(
    Map<String, dynamic> p,
    bool isResolved,
    Color statusColor,
    Color statusBg,
  ) {
    final solver    = p['solver'] as Map<String, dynamic>?;
    final biaya     = p['additional_cost'] as num?;
    final biayaStr  = biaya != null && biaya > 0
        ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(biaya)
        : '-';
    final String? penyebab  = p['penyebab']?.toString();
    final String? bagian    = p['bagian']?.toString();
    final String? faktorNama = p['penyebab']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha:0.07), blurRadius: 16, offset: const Offset(0, 4))],
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
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(CupertinoIcons.checkmark_seal_fill, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    Text(_t('resolution_done'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF16A34A))),
                  ]),
                ),
                const SizedBox(height: 16),

                // Bagian
                if (bagian != null && bagian.isNotEmpty) ...[
                  _resultRow(CupertinoIcons.square_grid_2x2_fill, _t('bagian'), bagian),
                  const SizedBox(height: 12),
                ],

                // Penyebab
                if (penyebab != null && penyebab.isNotEmpty) ...[
                  Text(_t('cause'),
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  Text(penyebab,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A), height: 1.5)),
                  const SizedBox(height: 12),
                ],

                // Faktor penyebab
                if (faktorNama != null && faktorNama.isNotEmpty) ...[
                  _resultRow(CupertinoIcons.tag_fill, _t('cause_factor'), faktorNama),
                  const SizedBox(height: 12),
                ],

                // Tindakan
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
                    child: Row(children: [
                      const Icon(CupertinoIcons.money_dollar_circle, color: Color(0xFFEA580C), size: 18),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_t('cost'),
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), fontWeight: FontWeight.w600)),
                        Text(biayaStr,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
                      ]),
                    ]),
                  ),
                ],

                if (solver != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(children: [
                      solver['gambar_user'] != null
                          ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(solver['gambar_user']))
                          : Container(
                              width: 40, height: 40,
                              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                              child: const Icon(CupertinoIcons.person_fill, size: 20, color: Color(0xFF1D4ED8)),
                            ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_t('resolved_by'),
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                        Text(solver['nama'] ?? '-',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A))),
                      ]),
                    ]),
                  ),
                ],

                if (p['tanggal_selesai'] != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(CupertinoIcons.clock_fill, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text('${_t('resolved_at')}: ${_formatDate(p['tanggal_selesai'])}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 14, color: const Color(0xFF1D4ED8)),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
        Expanded(child: Text(value,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildResolutionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF1D4ED8).withValues(alpha:0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto
          Row(children: [
            Text(_t('upload_photo'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
            const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed)),
          ]),
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
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                        child: const Icon(CupertinoIcons.camera, color: Color(0xFF1D4ED8), size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(_t('ambil_foto'),
                          style: GoogleFonts.inter(color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600, fontSize: 14)),
                    ]),
                  ),
                )
              : Stack(children: [
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
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.6), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(CupertinoIcons.camera_rotate, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(_t('ganti'), style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ),
                  ),
                ]),
          const SizedBox(height: 16),

          // Bagian (dari tabel section)
          Text(
            _t('bagian'),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showSectionPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedBagian != null ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE),
                  width: _selectedBagian != null ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.square_grid_2x2_fill,
                    size: 18,
                    color: _selectedBagian != null ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedBagian ?? _t('pick_bagian'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: _selectedBagian != null ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedBagian != null ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 15,
                    color: _selectedBagian != null ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Penyebab
          Text(_t('cause'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
          TextFormField(
            controller: _penyebabCtrl,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: _t('cause_hint'),
              hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 15),
              filled: true, fillColor: const Color(0xFFF8FAFF),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBFDBFE), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          // Faktor Penyebab
          Text(
            _t('cause_factor'),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          _subKategoriList.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: Row(children: [
                    const CupertinoActivityIndicator(radius: 8),
                    const SizedBox(width: 10),
                    Text(
                      widget.lang == 'EN'
                          ? 'Loading factors...'
                          : widget.lang == 'ZH'
                              ? '加载中...'
                              : 'Memuat faktor...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ]),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedSubKategori != null
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFFBFDBFE),
                      width: _selectedSubKategori != null ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        value: _selectedSubKategori,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        menuMaxHeight: 320,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(children: [
                            const Icon(
                              CupertinoIcons.tag,
                              size: 16,
                              color: Color(0xFFBFDBFE),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.lang == 'ZH'
                                  ? '选择原因因素（可选）'
                                  : widget.lang == 'EN'
                                      ? 'Select cause factor (optional)'
                                      : 'Pilih faktor penyebab (opsional)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                          ]),
                        ),
                        icon: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            _selectedSubKategori != null
                                ? CupertinoIcons.chevron_up_chevron_down
                                : CupertinoIcons.chevron_down,
                            size: 15,
                            color: _selectedSubKategori != null
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFFBFDBFE),
                          ),
                        ),
                        selectedItemBuilder: (context) =>
                            _subKategoriList.map((f) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(children: [
                                const Icon(
                                  CupertinoIcons.tag_fill,
                                  size: 16,
                                  color: Color(0xFF1D4ED8),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    f['nama_subkategoritemuan'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                            )).toList(),
                        items: _subKategoriList.map((f) {
                          final isSelected = _selectedSubKategori?['id_subkategoritemuan'] ==
                              f['id_subkategoritemuan'];
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: f,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.tag_fill,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    f['nama_subkategoritemuan'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    size: 18,
                                    color: Color(0xFF1D4ED8),
                                  ),
                              ]),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSubKategori = val),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 16),

          // Tindakan
          Row(children: [
            Text(_t('tindakan'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
            const Text(' *', style: TextStyle(color: CupertinoColors.destructiveRed)),
          ]),
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
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBFDBFE), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          // Biaya
          Text(_t('biaya'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569))),
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
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBFDBFE), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          // Tombol simpan
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: _isSavingResolution
                    ? null
                    : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                color: _isSavingResolution ? const Color(0xFFE2E8F0) : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isSavingResolution
                    ? null
                    : [BoxShadow(color: const Color(0xFF1D4ED8).withValues(alpha:0.35), blurRadius: 12, offset: const Offset(0, 4))],
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
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(_t('save_resolution'),
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
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
      child: Row(children: [
        Icon(icon, color: const Color(0xFF1D4ED8), size: 18),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569))),
        const Spacer(),
        Expanded(child: Text(value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF0F172A)))),
      ]),
    );
  }

  Widget _sectionTitle(IconData icon, String title, {Color color = const Color(0xFF1D4ED8)}) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
    ]);
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 60, height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFBFDBFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(CupertinoIcons.cube_box, color: Color(0xFF1D4ED8), size: 28),
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
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle),
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
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle),
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

class _KtsDetailSectionPickerSheet extends StatefulWidget {
  final String lang;
  const _KtsDetailSectionPickerSheet({required this.lang});

  @override
  State<_KtsDetailSectionPickerSheet> createState() => _KtsDetailSectionPickerSheetState();
}

class _KtsDetailSectionPickerSheetState extends State<_KtsDetailSectionPickerSheet> {
  static const Color _kPrimary      = Color(0xFF1D4ED8);
  static const Color _kPrimaryLight = Color(0xFFEFF6FF);
  static const Color _kBorder       = Color(0xFFBFDBFE);

  List<Map<String, dynamic>> _lokasiList = [];
  List<Map<String, dynamic>> _unitList = [];
  List<Map<String, dynamic>> _subunitList = [];
  List<Map<String, dynamic>> _areaList = [];

  String? _selLokasiId;
  String? _selUnitId;
  String? _selSubunitId;
  String? _selAreaId;
  String? _selLokasiName;
  String? _selUnitName;
  String? _selSubunitName;
  String? _selAreaName;

  List<Map<String, dynamic>> _allSections = [];
  List<Map<String, dynamic>> _filteredSections = [];
  bool _isLoadingLocations = true;
  bool _isLoadingSections = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadLocations();
    _loadSections();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _nameOf(Map<String, dynamic> s) {
    if (widget.lang == 'EN') return s['nama_section_en']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    if (widget.lang == 'ZH') return s['nama_section_zh']?.toString() ?? s['nama_section_id']?.toString() ?? '-';
    return s['nama_section_id']?.toString() ?? '-';
  }

  String _locationBadge(Map<String, dynamic> s) {
    final parts = <String>[];
    if (s['lokasi']?['nama_lokasi'] != null) parts.add(s['lokasi']['nama_lokasi']);
    if (s['unit']?['nama_unit'] != null) parts.add(s['unit']['nama_unit']);
    if (s['subunit']?['nama_subunit'] != null) parts.add(s['subunit']['nama_subunit']);
    if (s['area']?['nama_area'] != null) parts.add(s['area']['nama_area']);
    return parts.isEmpty ? '' : parts.join(' • ');
  }

  Future<void> _loadLocations() async {
    try {
      final data = await Supabase.instance.client.from('lokasi').select('id_lokasi, nama_lokasi').order('nama_lokasi');
      if (mounted) setState(() { _lokasiList = List<Map<String, dynamic>>.from(data); _isLoadingLocations = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUnit(String lokasiId) async {
    final res = await Supabase.instance.client.from('unit').select('id_unit, nama_unit').eq('id_lokasi', lokasiId).order('nama_unit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchSubunit(String unitId) async {
    final res = await Supabase.instance.client.from('subunit').select('id_subunit, nama_subunit').eq('id_unit', unitId).order('nama_subunit');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchArea(String subunitId) async {
    final res = await Supabase.instance.client.from('area').select('id_area, nama_area').eq('id_subunit', subunitId).order('nama_area');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _loadSections({String? lokasiId, String? unitId, String? subunitId, String? areaId}) async {
    setState(() => _isLoadingSections = true);
    try {
      dynamic query = Supabase.instance.client
          .from('section')
          .select('*, lokasi(nama_lokasi), unit(nama_unit), subunit(nama_subunit), area(nama_area)');
      if (areaId != null) {
        query = query.eq('id_area', areaId);
      } else if (subunitId != null) {
        query = query.eq('id_subunit', subunitId);
      } else if (unitId != null) {
        query = query.eq('id_unit', unitId);
      } else if (lokasiId != null) {
        query = query.eq('id_lokasi', lokasiId);
      }

      final data = await query.order('urutan', ascending: true);
      final sections = List<Map<String, dynamic>>.from(data);
      if (mounted) {
        setState(() {
          _allSections = sections;
          _filteredSections = _applySearch(sections);
          _isLoadingSections = false;
        });
      }
    } catch (e) {
      debugPrint('Error load section: $e');
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> src) {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return src;
    return src.where((s) => _nameOf(s).toLowerCase().contains(q)).toList();
  }

  void _onSearch() => setState(() => _filteredSections = _applySearch(_allSections));

  void _applyFilter() => _loadSections(lokasiId: _selLokasiId, unitId: _selUnitId, subunitId: _selSubunitId, areaId: _selAreaId);

  int get _activeFilterCount {
    int c = 0;
    if (_selLokasiId != null) c++;
    if (_selUnitId != null) c++;
    if (_selSubunitId != null) c++;
    if (_selAreaId != null) c++;
    return c;
  }

  Widget _activeFilterChip({required IconData icon, required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kPrimary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(CupertinoIcons.xmark_circle_fill, size: 15, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  void _removeLokasiFilter() {
    setState(() {
      _selLokasiId = null; _selLokasiName = null;
      _selUnitId = null; _selUnitName = null;
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _unitList = []; _subunitList = []; _areaList = [];
    });
    _loadSections();
  }

  void _removeUnitFilter() {
    setState(() {
      _selUnitId = null; _selUnitName = null;
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _subunitList = []; _areaList = [];
    });
    _applyFilter();
  }

  void _removeSubunitFilter() {
    setState(() {
      _selSubunitId = null; _selSubunitName = null;
      _selAreaId = null; _selAreaName = null;
      _areaList = [];
    });
    _applyFilter();
  }

  void _removeAreaFilter() {
    setState(() {
      _selAreaId = null; _selAreaName = null;
    });
    _applyFilter();
  }

  Future<void> _openFilterDialog() async {
    String? tLokasiId = _selLokasiId;
    String? tLokasiName = _selLokasiName;
    String? tUnitId = _selUnitId;
    String? tUnitName = _selUnitName;
    String? tSubunitId = _selSubunitId;
    String? tSubunitName = _selSubunitName;
    String? tAreaId = _selAreaId;
    String? tAreaName = _selAreaName;
    List<Map<String, dynamic>> tUnitList = List.from(_unitList);
    List<Map<String, dynamic>> tSubunitList = List.from(_subunitList);
    List<Map<String, dynamic>> tAreaList = List.from(_areaList);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: _kPrimaryLight.withValues(alpha:0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.slider_horizontal_3, color: _kPrimary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.lang == 'EN' ? 'Filter Location' : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(CupertinoIcons.xmark, size: 15, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isLoadingLocations
                            ? const Center(child: CupertinoActivityIndicator())
                            : _buildFilterChips(
                                label: widget.lang == 'EN' ? 'Location' : widget.lang == 'ZH' ? '位置' : 'Lokasi',
                                icon: CupertinoIcons.building_2_fill,
                                items: _lokasiList,
                                idKey: 'id_lokasi', nameKey: 'nama_lokasi',
                                selectedId: tLokasiId,
                                onSelect: (id) async {
                                  final selected = _lokasiList.firstWhere((e) => e['id_lokasi'].toString() == id);
                                  final units = await _fetchUnit(id);
                                  setDlg(() {
                                    tLokasiId = id;
                                    tLokasiName = selected['nama_lokasi']?.toString();
                                    tUnitId = null; tUnitName = null;
                                    tSubunitId = null; tSubunitName = null;
                                    tAreaId = null; tAreaName = null;
                                    tUnitList = units; tSubunitList = []; tAreaList = [];
                                  });
                                },
                              ),
                        if (tLokasiId != null && tUnitList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Unit', icon: CupertinoIcons.squares_below_rectangle,
                            items: tUnitList, idKey: 'id_unit', nameKey: 'nama_unit',
                            selectedId: tUnitId,
                            onSelect: (id) async {
                              final selected = tUnitList.firstWhere((e) => e['id_unit'].toString() == id);
                              final subs = await _fetchSubunit(id);
                              setDlg(() {
                                tUnitId = id;
                                tUnitName = selected['nama_unit']?.toString();
                                tSubunitId = null; tSubunitName = null;
                                tAreaId = null; tAreaName = null;
                                tSubunitList = subs; tAreaList = [];
                              });
                            },
                          ),
                        ],
                        if (tUnitId != null && tSubunitList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Sub-Unit', icon: CupertinoIcons.layers_alt_fill,
                            items: tSubunitList, idKey: 'id_subunit', nameKey: 'nama_subunit',
                            selectedId: tSubunitId,
                            onSelect: (id) async {
                              final selected = tSubunitList.firstWhere((e) => e['id_subunit'].toString() == id);
                              final areas = await _fetchArea(id);
                              setDlg(() {
                                tSubunitId = id;
                                tSubunitName = selected['nama_subunit']?.toString();
                                tAreaId = null; tAreaName = null;
                                tAreaList = areas;
                              });
                            },
                          ),
                        ],
                        if (tSubunitId != null && tAreaList.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildFilterChips(
                            label: 'Area', icon: CupertinoIcons.location_fill,
                            items: tAreaList, idKey: 'id_area', nameKey: 'nama_area',
                            selectedId: tAreaId,
                            onSelect: (id) {
                              final selected = tAreaList.firstWhere((e) => e['id_area'].toString() == id);
                              setDlg(() {
                                tAreaId = id;
                                tAreaName = selected['nama_area']?.toString();
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 6, offset: const Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setDlg(() {
                              tLokasiId = null; tLokasiName = null;
                              tUnitId = null; tUnitName = null;
                              tSubunitId = null; tSubunitName = null;
                              tAreaId = null; tAreaName = null;
                              tUnitList = []; tSubunitList = []; tAreaList = [];
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kBorder),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            widget.lang == 'EN' ? 'Reset' : widget.lang == 'ZH' ? '重置' : 'Reset',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selLokasiId = tLokasiId; _selLokasiName = tLokasiName;
                              _selUnitId = tUnitId; _selUnitName = tUnitName;
                              _selSubunitId = tSubunitId; _selSubunitName = tSubunitName;
                              _selAreaId = tAreaId; _selAreaName = tAreaName;
                              _unitList = tUnitList; _subunitList = tSubunitList; _areaList = tAreaList;
                            });
                            Navigator.pop(dialogCtx);
                            _applyFilter();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            widget.lang == 'EN' ? 'Apply' : widget.lang == 'ZH' ? '应用' : 'Terapkan',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips({
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required String? selectedId,
    required Function(String id) onSelect,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 13, color: _kPrimary), const SizedBox(width: 6), Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((item) {
            final id = item[idKey].toString();
            final name = item[nameKey] as String;
            final isSelected = selectedId == id;
            return GestureDetector(
              onTap: () => onSelect(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? _kPrimary : _kBorder),
                  boxShadow: isSelected ? [BoxShadow(color: _kPrimary.withValues(alpha:0.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF1E293B))),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kPrimary, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.lang == 'ZH' ? '选择部门' : widget.lang == 'EN' ? 'Select Section' : 'Pilih Bagian', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)))),
              IconButton(icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF94A3B8), size: 20), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Container(
            color: const Color(0xFFF8FAFF),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(
                    onTap: _openFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _activeFilterCount > 0 ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _activeFilterCount > 0 ? _kPrimary : _kBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.slider_horizontal_3, size: 15, color: _activeFilterCount > 0 ? Colors.white : _kPrimary),
                          const SizedBox(width: 6),
                          Text(
                            widget.lang == 'EN' ? 'Filter Location' : widget.lang == 'ZH' ? '筛选位置' : 'Filter Lokasi',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _activeFilterCount > 0 ? Colors.white : _kPrimary),
                          ),
                          if (_activeFilterCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Text('$_activeFilterCount', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: _kPrimary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_activeFilterCount > 0)
                    GestureDetector(
                      onTap: _removeLokasiFilter,
                      child: Text(
                        widget.lang == 'EN' ? 'Reset all' : widget.lang == 'ZH' ? '全部重置' : 'Reset Semua',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), decoration: TextDecoration.underline),
                      ),
                    ),
                ]),
                if (_activeFilterCount > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      if (_selLokasiId != null)
                        _activeFilterChip(icon: CupertinoIcons.building_2_fill, label: _selLokasiName ?? '-', onRemove: _removeLokasiFilter),
                      if (_selUnitId != null)
                        _activeFilterChip(icon: CupertinoIcons.squares_below_rectangle, label: _selUnitName ?? '-', onRemove: _removeUnitFilter),
                      if (_selSubunitId != null)
                        _activeFilterChip(icon: CupertinoIcons.layers_alt_fill, label: _selSubunitName ?? '-', onRemove: _removeSubunitFilter),
                      if (_selAreaId != null)
                        _activeFilterChip(icon: CupertinoIcons.location_fill, label: _selAreaName ?? '-', onRemove: _removeAreaFilter),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Color(0xFFE0E7FF), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextFormField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.lang == 'ZH' ? '搜索部门...' : widget.lang == 'EN' ? 'Search section...' : 'Cari bagian...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 14),
                prefixIcon: const Icon(CupertinoIcons.search, color: _kPrimary, size: 18),
                filled: true, fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder, width: 1)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(children: [
              const Icon(CupertinoIcons.square_grid_2x2, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text('${_filteredSections.length} ${widget.lang == 'EN' ? 'sections' : widget.lang == 'ZH' ? '个部门' : 'bagian'}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
            ]),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 12),
          Expanded(
            child: _isLoadingSections
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredSections.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(CupertinoIcons.square_grid_2x2, size: 48, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        Text(widget.lang == 'EN' ? 'No sections found' : widget.lang == 'ZH' ? '未找到部门' : 'Tidak ada bagian', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                        itemCount: _filteredSections.length,
                        itemBuilder: (_, i) {
                          final s = _filteredSections[i];
                          final name = _nameOf(s);
                          final badge = _locationBadge(s);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(context, s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(CupertinoIcons.square_grid_2x2_fill, color: _kPrimary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                                        if (badge.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(badge, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
                                ]),
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