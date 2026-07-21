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

  Color get _bgLight => const Color(0xFFF8FAFC);

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
      return DateFormat('d MMMM yyyy', locale).format(date);
    } catch (_) {
      return item['published_at']?.toString() ?? '';
    }
  }

  int get _durationDays {
    final raw = item['display_duration_days'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 7;
  }

  String get _durationLabel {
    if (lang == 'EN') return '$_durationDays days popup';
    if (lang == 'ZH') return '弹窗 $_durationDays 天';
    return '$_durationDays hari popup';
  }

  String get _infoSectionLabel {
    if (lang == 'EN') return 'Information';
    if (lang == 'ZH') return '信息';
    return 'Informasi';
  }

  String get _titleLabel {
    if (lang == 'EN') return 'Title';
    if (lang == 'ZH') return '标题';
    return 'Judul';
  }

  String get _contentLabel {
    if (lang == 'EN') return 'Content';
    if (lang == 'ZH') return '内容';
    return 'Konten';
  }

  String get _dateInfoLabel {
    if (lang == 'EN') return 'Published Date';
    if (lang == 'ZH') return '发布日期';
    return 'Tanggal Tayang';
  }

  String get _durationInfoLabel {
    if (lang == 'EN') return 'Popup Duration';
    if (lang == 'ZH') return '弹窗时长';
    return 'Durasi Popup';
  }

  void _openFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _NewsImageViewer(imageUrl: imageUrl),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _primary, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      color: Colors.black45,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: _primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = item['image_url'];

    return Scaffold(
      backgroundColor: _bgLight,
      // ── APP BAR — tidak berubah warna saat scroll ──
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 1,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new, color: _primary),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── GAMBAR — tetap persegi panjang, tap untuk lihat ukuran asli ──
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GestureDetector(
                  onTap: () => _openFullImage(context, imageUrl),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => Container(
                              color: _primary.withValues(alpha: 0.12),
                              child: Center(
                                child: Icon(
                                  _typeIcon,
                                  color: _primary.withValues(alpha: 0.3),
                                  size: 60,
                                ),
                              ),
                            ),
                            loadingBuilder: (_, child, prog) {
                              if (prog == null) return child;
                              return Container(
                                color: _primary.withValues(alpha: 0.08),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: _primary, strokeWidth: 2),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.zoom_out_map_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── KARTU JUDUL & KONTEN — tepat di bawah gambar ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _primary.withValues(alpha: 0.14), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: _primary.withValues(alpha: 0.09),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Label Judul ──
                        _sectionLabel(Icons.edit_note_rounded, _titleLabel),
                        const SizedBox(height: 8),
                        Text(
                          _title,
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A8A),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Divider ──
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primary.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Label Konten ──
                        _sectionLabel(Icons.sticky_note_2_outlined, _contentLabel),
                        const SizedBox(height: 8),
                        Text(
                          _content,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

            // ── KARTU INFORMASI — di bawah Judul & Konten, tanpa baris Type ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primary.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _sectionLabel(Icons.info_outline_rounded, _infoSectionLabel),
                      const Spacer(),
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
                            Icon(_typeIcon, size: 12, color: _primary),
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 6),
                  _infoRow(Icons.calendar_today_rounded, _dateInfoLabel, _formattedDate),
                  _infoRow(Icons.timer_rounded, _durationInfoLabel, _durationLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsImageViewer extends StatelessWidget {
  final String imageUrl;

  const _NewsImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withValues(alpha: 0.001)),
            ),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 60),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}