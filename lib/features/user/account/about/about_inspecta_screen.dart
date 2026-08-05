import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutInspectaScreen extends StatefulWidget {
  final String lang;
  final String? initialAppName;
  final String? initialAppVersion;
  final String? initialAppWebsite;
  final String? initialAppTagline;
  final String? initialAppLogoUrl;
  final String? initialAppCopyright;

  const AboutInspectaScreen({
    super.key,
    required this.lang,
    this.initialAppName,
    this.initialAppVersion,
    this.initialAppWebsite,
    this.initialAppTagline,
    this.initialAppLogoUrl,
    this.initialAppCopyright,
  });

  @override
  State<AboutInspectaScreen> createState() => _AboutInspectaScreenState();
}

class _AboutInspectaScreenState extends State<AboutInspectaScreen> {
  late String _appName;
  late String _appVersion;
  late String _appWebsite;
  late String _appTagline;
  late String _appCopyright;
  String? _appLogoUrl;

  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'About Inspecta',
      'version': 'App Version',
      'website': 'Official Website',
      'built_with': 'Built with',
      'tagline': 'Make Your Discipline day!',
    },
    'ID': {
      'title': 'Tentang Inspecta',
      'version': 'Versi Aplikasi',
      'website': 'Website Resmi',
      'built_with': 'Dibangun dengan',
      'tagline': 'Jadikan Harimu Disiplin!',
    },
    'ZH': {
      'title': '关于 Inspecta',
      'version': '应用版本',
      'website': '官方网站',
      'built_with': '由 构建',
      'tagline': '让您的纪律日!',
    },
  };

  String getTxt(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _appName      = widget.initialAppName    ?? 'Inspecta';
    _appVersion   = widget.initialAppVersion ?? '-';
    _appWebsite   = widget.initialAppWebsite ?? '';
    _appTagline   = widget.initialAppTagline ?? 'Make Your Discipline day!';
    _appLogoUrl   = widget.initialAppLogoUrl;
    _appCopyright = widget.initialAppCopyright ?? '© ${DateTime.now().year} $_appName';

    if (widget.initialAppVersion == null) {
      _fetchAppInfo();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/logo1.PNG'), context)
          .catchError((_) {});
      precacheImage(const AssetImage('assets/images/flutter.png'), context)
          .catchError((_) {});
      precacheImage(const AssetImage('assets/images/supabase.png'), context)
          .catchError((_) {});
    });
  }

  Future<void> _fetchAppInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('app_info')
          .select()
          .single();
      if (mounted) {
        setState(() {
          _appName    = response['app_name'] ?? 'Inspecta';
          _appVersion = response['version']  ?? '-';
          _appWebsite = response['website']  ?? '';
          _appTagline   = _localizedTagline(response);
          _appLogoUrl   = response['logo_url'] as String?;
          _appCopyright = _localizedCopyright(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching app info: $e');
    }
  }

  String _localizedTagline(Map<String, dynamic> row) {
    switch (widget.lang) {
      case 'EN':
        return (row['tagline_en'] ?? row['tagline'] ?? 'Make Your Discipline day!').toString();
      case 'ZH':
        return (row['tagline_zh'] ?? row['tagline'] ?? 'Make Your Discipline day!').toString();
      default:
        return (row['tagline'] ?? 'Make Your Discipline day!').toString();
    }
  }

  String _localizedCopyright(Map<String, dynamic> row) {
    final fallback = '© ${DateTime.now().year} $_appName';
    String? val;
    switch (widget.lang) {
      case 'EN':
        val = row['copyright_en'] as String?;
        break;
      case 'ZH':
        val = row['copyright_zh'] as String?;
        break;
      default:
        val = row['copyright'] as String?;
    }
    return (val != null && val.trim().isNotEmpty) ? val : fallback;
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showErrorPopup('Could not launch $url');
      }
    }
  }

  void _showErrorPopup(String message) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'error',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                          width: 2),
                    ),
                    child: const Icon(Icons.error_rounded,
                        color: Color(0xFFDC2626), size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Gagal',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: const Duration(milliseconds: 2500),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D72F3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          getTxt('title'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D72F3),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1D72F3)),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 120,
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _appLogoUrl != null
                  ? Image.network(
                      _appLogoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/logo1.PNG',
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      'assets/images/logo1.PNG',
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _appName,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D72F3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _appTagline,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: const Color.fromARGB(255, 19, 19, 19),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 36),

          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            label: getTxt('version'),
            value: _appVersion,
          ),
          const SizedBox(height: 14),

          if (_appWebsite.isNotEmpty) _buildWebsiteCard(),
          const SizedBox(height: 26),

          Text(
            _appCopyright,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 114, 114, 114),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D72F3).withValues(alpha:0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1D72F3), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteCard() {
    return GestureDetector(
      onTap: () => _launchURL(_appWebsite),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D72F3).withValues(alpha:0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.language_rounded,
                  color: Color(0xFF1D72F3), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTxt('website'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _appWebsite,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D72F3),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF1D72F3),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                color: Color(0xFF1D72F3), size: 18),
          ],
        ),
      ),
    );
  }
}