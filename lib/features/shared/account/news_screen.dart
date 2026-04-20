import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class NewsScreen extends StatefulWidget {
  final String lang;
  final Map<String, Map<String, String>> translations;

  const NewsScreen({
    super.key,
    required this.lang,
    required this.translations,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late String _currentLang;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _updates = [];
  List<Map<String, dynamic>> _maintenance = [];

  String getTxt(String key) => widget.translations[_currentLang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    try {
      final response = await Supabase.instance.client
          .from('latest_news')
          .select()
          .order('published_at', ascending: false);

      if (mounted) {
        // --- AWAL PERUBAHAN ---

        // 1. Casting `response` ke List<dynamic> agar lebih eksplisit.
        final List<dynamic> allNewsData = response;

        // 2. Gunakan List.from() dan casting setiap elemen menjadi Map<String, dynamic>
        //    saat memfilter dan membuat list baru. Ini adalah cara yang aman.
        final updatesList = List<Map<String, dynamic>>.from(
          allNewsData.where((item) => item['type'] == 'update')
        );
        final maintenanceList = List<Map<String, dynamic>>.from(
          allNewsData.where((item) => item['type'] == 'maintenance')
        );

        setState(() {
          _updates = updatesList;
          _maintenance = maintenanceList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load news. Please try again later.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(getTxt('news_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
          centerTitle: true,
          bottom: TabBar(
            labelColor: const Color(0xFF1E3A8A),
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: const Color(0xFF1E3A8A),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: getTxt('update_notes')),
              Tab(text: getTxt('maintenance_notices')),
            ],
          ),
        ),
        body: _isLoading
            ? _buildSkeletonLoader()
            : _error != null
                ? Center(child: Text(_error!))
                : TabBarView(
                    children: [
                      _buildNewsList(_updates, 'update'),
                      _buildNewsList(_maintenance, 'maintenance'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNewsList(List<Map<String, dynamic>> newsItems, String type) {
    if (newsItems.isEmpty) {
      return Center(
        child: Text(
          type == 'update' ? 'No update notes available.' : 'No maintenance notices.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: newsItems.length,
      itemBuilder: (context, index) {
        return _buildNewsItemCard(newsItems[index], type);
      },
    );
  }

  Widget _buildNewsItemCard(Map<String, dynamic> item, String type) {
    final String title = item['title_${_currentLang.toLowerCase()}'] ?? item['title_en'];
    final String content = item['content_${_currentLang.toLowerCase()}'] ?? item['content_en'];
    final String? imageUrl = item['image_url'];
    final DateTime publishedDate = DateTime.parse(item['published_at']);
    
    String formattedDate;
    try {
      // Format tanggal sesuai locale bahasa
      final locale = _currentLang == 'ID' ? 'id_ID' : (_currentLang == 'ZH' ? 'zh_CN' : 'en_US');
      formattedDate = DateFormat('d MMM yyyy', locale).format(publishedDate);
    } catch (e) {
      formattedDate = item['published_at']; // fallback
    }

    final String typeText = type == 'update' 
        ? (_currentLang == 'ID' ? 'Pembaruan' : (_currentLang == 'ZH' ? '更新' : 'Update'))
        : (_currentLang == 'ID' ? 'Pemberitahuan' : (_currentLang == 'ZH' ? '通知' : 'Notice'));

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      typeText,
                      style: const TextStyle(
                        color: Color(0xFFF59E0B), // Warna oranye seperti di gambar
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      '  |  ',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 15),
              Container(height: 14, width: 200, color: Colors.white),
              const SizedBox(height: 10),
              Container(height: 18, width: double.infinity, color: Colors.white),
              const SizedBox(height: 10),
              Container(height: 14, width: double.infinity, color: Colors.white),
              const SizedBox(height: 5),
              Container(height: 14, width: 250, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}