import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutInspectaScreen extends StatefulWidget {
  final String lang;
  final String? initialAppName;
  final String? initialAppVersion;
  final String? initialAppWebsite;

  const AboutInspectaScreen({
    super.key,
    required this.lang,
    this.initialAppName,
    this.initialAppVersion,
    this.initialAppWebsite,
  });

  @override
  State<AboutInspectaScreen> createState() => _AboutInspectaScreenState();
}

class _AboutInspectaScreenState extends State<AboutInspectaScreen> {
  late String _appName;
  late String _appVersion;
  late String _appWebsite;
  late String _appTagline;
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
    _appName    = widget.initialAppName    ?? 'Inspecta';
    _appVersion = widget.initialAppVersion ?? '-';
    _appWebsite = widget.initialAppWebsite ?? '';
    _appTagline = 'Make Your Discipline day!'; // default
    _appLogoUrl = null;

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
          _appTagline = response['tagline']  ?? 'Make Your Discipline day!';
          _appLogoUrl = response['logo_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error fetching app info: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
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
        shadowColor: Colors.black.withOpacity(0.08),
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
          // ── Logo ──
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
          const SizedBox(height: 14),

          _buildBuiltWithCard(),
          const SizedBox(height: 40),

          Text(
            '© ${DateTime.now().year} $_appName',
            style: GoogleFonts.poppins(
              fontSize: 13,
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
            color: const Color(0xFF1D72F3).withOpacity(0.07),
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
                    fontWeight: FontWeight.w500,
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
              color: const Color(0xFF1D72F3).withOpacity(0.07),
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
                      fontWeight: FontWeight.w500,
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

  Widget _buildBuiltWithCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D72F3).withOpacity(0.07),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.code_rounded,
                    color: Color(0xFF1D72F3), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                getTxt('built_with'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/flutter.png',
                        height: 26,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.flutter_dash,
                          color: Color(0xFF54C5F8),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Flutter',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0553B1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FAF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/supabase.png',
                        height: 26,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storage_rounded,
                          color: Color(0xFF3ECF8E),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Supabase',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A7A4A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}