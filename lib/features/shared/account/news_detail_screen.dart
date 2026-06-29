import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final String lang;

  const NewsDetailScreen({
    super.key,
    required this.item,
    required this.lang,
  });

  static const _updatePrimary = Color(0xFF1D72F3);
  static const _maintPrimary  = Color(0xFFF59E0B);

  Color get _primary =>
      (item['type'] ?? '') == 'update' ? _updatePrimary : _maintPrimary;

  Color get _bgLight =>
      (item['type'] ?? '') == 'update'
          ? const Color(0xFFEFF6FF)
          : const Color(0xFFFFFBEB);

  Color get _badgeBg =>
      (item['type'] ?? '') == 'update'
          ? const Color(0xFFDBEAFE)
          : const Color(0xFFFEF3C7);

  IconData get _typeIcon =>
      (item['type'] ?? '') == 'update'
          ? Icons.update_rounded
          : Icons.build_rounded;

  String get _typeLabel {
    final isUpdate = (item['type'] ?? '') == 'update';
    if (lang == 'ID') return isUpdate ? 'Pembaruan' : 'Pemberitahuan';
    if (lang == 'ZH') return isUpdate ? '更新' : '通知';
    return isUpdate ? 'Update' : 'Notice';
  }

  String get _appBarTitle {
    if (lang == 'ID') return 'Detail Berita';
    if (lang == 'ZH') return '新闻详情';
    return 'News Detail';
  }

  String get _title =>
      item['title_${lang.toLowerCase()}'] ??
      item['title_en'] ??
      '';

  String get _content =>
      item['content_${lang.toLowerCase()}'] ??
      item['content_en'] ??
      '';

  String get _formattedDate {
    try {
      final rawDate = item['published_at'];
      DateTime date;
      if (rawDate is DateTime) {
        date = rawDate;
      } else {
        final dateStr = rawDate.toString().split('T').first;
        date = DateTime.parse(dateStr);
      }
      final locale =
          lang == 'ID' ? 'id_ID' : (lang == 'ZH' ? 'zh_CN' : 'en_US');
      return DateFormat('d MMM yyyy', locale).format(date);
    } catch (_) {
      return item['published_at']?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = item['image_url'];

    return Scaffold(
      backgroundColor: _bgLight,
      // ── APP BAR ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 1,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: _updatePrimary),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _appBarTitle,
          style: GoogleFonts.poppins(
            color: _primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        // Strip bawah AppBar sesuai warna tipe
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.25),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── GAMBAR (jika ada) ──────────────────────────
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          _typeIcon,
                          color: _primary.withValues(alpha:0.3),
                          size: 60,
                        ),
                      ),
                    ),
                    loadingBuilder: (_, child, prog) {
                      if (prog == null) return child;
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha:0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: _primary, strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ── KARTU KONTEN ──────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _primary.withValues(alpha:0.14), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: _primary.withValues(alpha:0.09),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Strip warna atas
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19)),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Badge tipe + tanggal ──
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: _badgeBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_typeIcon,
                                      size: 12, color: _primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    _typeLabel,
                                    style: GoogleFonts.poppins(
                                        color: _primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.calendar_today_rounded,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              _formattedDate,
                              style: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 11.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Judul ──
                        Text(
                          _title,
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A8A),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Divider ──
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primary.withValues(alpha:0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Konten penuh ──
                        Text(
                          _content,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF374151),
                            height: 1.75,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}