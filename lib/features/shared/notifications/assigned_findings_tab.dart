import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../user/finding/finding_detail_screen.dart';
import '../../user/home/finding_card.dart';
import '../../user/home/kts_finding_card.dart';
import '../../user/ktsproduksi/kts_detail_screen.dart';

class AssignedFindingsTab extends StatefulWidget {
  final String lang;
  final List<Map<String, dynamic>>? initialData;
  final String Function(String) t;

  const AssignedFindingsTab({
    super.key,
    required this.lang,
    required this.t,
    this.initialData,
  });

  @override
  State<AssignedFindingsTab> createState() => _AssignedFindingsTabState();
}

class _AssignedFindingsTabState extends State<AssignedFindingsTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _items = widget.initialData!;
    } else {
      _fetchFindings();
    }
  }

  Future<void> _fetchFindings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('temuan')
          .select(
            'id_temuan, judul_temuan, gambar_temuan, created_at, '
            'status_temuan, poin_temuan, target_waktu_selesai, '
            'jenis_temuan, id_lokasi, id_unit, id_subunit, id_area, '
            'id_penanggung_jawab, is_pro, is_visitor, is_eksekutif, '
            'lokasi(nama_lokasi), unit(nama_unit), '
            'subunit(nama_subunit), area(nama_area)',
          )
          .eq('id_penanggung_jawab', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching findings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return _buildShimmer();

    final unfinishedItems = _items.where((e) {
      final s = (e['status_temuan'] ?? '').toString();
      return !['Selesai', 'done', 'completed', 'closed'].any((x) => s.contains(x));
    }).toList();

    if (unfinishedItems.isEmpty) {
      return _buildEmpty(
        widget.t('empty_findings'),
        widget.t('empty_findings_sub'),
        Icons.assignment_ind_outlined,
      );
    }

    final pendingCount = unfinishedItems.length;

    return Column(
      children: [
        if (pendingCount > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFFDC2626).withValues(alpha:0.08),
                const Color(0xFFEF4444).withValues(alpha:0.05),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha:0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.pending_actions_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.lang == 'ID'
                      ? '$pendingCount temuan masih menunggu penyelesaian Anda'
                      : '$pendingCount findings are waiting for your action',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626)),
                ),
              ),
            ]),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: unfinishedItems.length,
            itemBuilder: (context, index) {
              final item = unfinishedItems[index];
              final jenis = (item['jenis_temuan'] ?? '').toString().toLowerCase();
              final isKts = jenis.contains('kts');

              if (isKts) {
                return KtsFindingCard(
                  data: item,
                  lang: widget.lang,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KtsDetailScreen(
                          ktsId: item['id_temuan'].toString(),
                          lang: widget.lang,
                          initialData: item,
                        ),
                      ),
                    );
                  },
                );
              }

              return FindingCard(
                data: item,
                lang: widget.lang,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FindingDetailScreen(initialData: item, lang: widget.lang),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C9E4).withValues(alpha:0.08),
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF00C9E4).withValues(alpha:0.5)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}