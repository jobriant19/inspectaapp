import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kts_solution_screen.dart';

class KtsDetailScreen extends StatefulWidget {
  final String ktsId;
  final String lang;
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
  bool _isDataChanged = false;
  String? _currentUserId;

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
      'ambil_foto': 'Tambah Foto Solusi',
      'ganti': 'Ganti',
      'pic_label': 'Penanggung Jawab',
      'bagian': 'Bagian',
      'pick_bagian': 'Pilih Bagian',
      'cause': 'Penyebab',
      'cause_hint': 'Jelaskan penyebab...',
      'cause_factor': 'Faktor Penyebab',
    },
    'EN': {
      'title': 'KTS Production Detail',
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
      'ambil_foto': 'Add Solution Photo',
      'ganti': 'Retake',
      'pic_label': 'Person in Charge',
      'bagian': 'Section',
      'pick_bagian': 'Select Section',
      'cause': 'Cause',
      'cause_hint': 'Describe the cause...',
      'cause_factor': 'Cause Factor',
    },
    'ZH': {
      'title': 'KTS生产详情',
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
      'ambil_foto': '添加解决方案照片',
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
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (widget.initialData != null) {
      _data = widget.initialData;
      _isLoading = false;
      _loadDataSilently();
    } else {
      _loadData();
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
        });
      }
    } catch (e) {
      debugPrint('Error loading KTS detail: $e');
      if (mounted) setState(() => _isLoading = false);
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
            style: GoogleFonts.poppins(
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
    final bool isPic = picData != null && picData['id_user']?.toString() == _currentUserId;

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

          // SOLUTION
          KtsSolutionScreen(
            ktsId: widget.ktsId,
            lang: widget.lang,
            penyelesaian: penyelesaian,
            isResolved: isResolved,
            isPic: isPic,
            onSaved: () {
              _isDataChanged = true;
              _loadData();
            },
          ),

          const SizedBox(height: 40),
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