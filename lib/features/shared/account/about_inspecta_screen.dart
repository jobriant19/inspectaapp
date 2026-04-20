import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutInspectaScreen extends StatefulWidget {
  final String lang;
  const AboutInspectaScreen({super.key, required this.lang});

  @override
  State<AboutInspectaScreen> createState() => _AboutInspectaScreenState();
}

class _AboutInspectaScreenState extends State<AboutInspectaScreen> {
  bool _isLoading = true;
  String _appName = 'Inspecta';
  String _appVersion = '...';
  String _appWebsite = '...';

  // Kamus terjemahan mini untuk halaman ini
  final Map<String, Map<String, String>> _txt = {
    'EN': {
      'title': 'About Inspecta',
      'version': 'Version',
      'website': 'Website',
      'error': 'Failed to load app info. Please try again later.',
    },
    'ID': {
      'title': 'Tentang Inspecta',
      'version': 'Versi',
      'website': 'Website',
      'error': 'Gagal memuat info aplikasi. Silakan coba lagi nanti.',
    },
    'ZH': {
      'title': '关于 Inspecta',
      'version': '版本',
      'website': '网站',
      'error': '加载应用程序信息失败。请稍后再试。',
    },
  };

  String getTxt(String key) => _txt[widget.lang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _fetchAppInfo();
  }

  Future<void> _fetchAppInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('app_info')
          .select()
          .single(); // Mengambil satu baris data saja

      if (mounted) {
        setState(() {
          _appName = response['app_name'];
          _appVersion = response['version'];
          _appWebsite = response['website'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching app info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Tampilkan pesan error jika gagal
          _appVersion = getTxt('error');
          _appWebsite = '';
        });
      }
    }
  }

  // Helper untuk membuka URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Tampilkan snackbar jika gagal membuka URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(getTxt('title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Bagian Versi ---
                  Text(
                    _appName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${getTxt('version')} $_appVersion',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 30),

                  // --- Bagian Website ---
                  Text(
                    getTxt('website'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchURL(_appWebsite),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        _appWebsite,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}