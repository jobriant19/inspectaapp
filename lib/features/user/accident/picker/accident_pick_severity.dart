import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AccidentSeverityData {
  final String key;
  final IconData icon;
  final Color color;
  final Map<String, String> label;
  final Map<String, String> desc;

  const AccidentSeverityData({
    required this.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
  });

  static const List<AccidentSeverityData> severities = [
    AccidentSeverityData(
      key: 'Ringan',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF16A34A),
      label: {'ID': 'Ringan', 'EN': 'Minor', 'ZH': '轻微'},
      desc: {
        'ID': 'Cedera Tanpa Kehilangan Waktu Kerja',
        'EN': 'Injury Without Lost Work Time',
        'ZH': '受伤但未损失工作时间',
      },
    ),
    AccidentSeverityData(
      key: 'Menengah',
      icon: Icons.error_rounded,
      color: Color(0xFFF97316),
      label: {'ID': 'Menengah', 'EN': 'Moderate', 'ZH': '中度'},
      desc: {
        'ID': 'Cedera Kehilangan Waktu Kerja',
        'EN': 'Injury With Lost Work Time',
        'ZH': '受伤并损失工作时间',
      },
    ),
    AccidentSeverityData(
      key: 'Berat',
      icon: Icons.dangerous_rounded,
      color: Color(0xFFDC2626),
      label: {'ID': 'Berat', 'EN': 'Severe', 'ZH': '严重'},
      desc: {
        'ID': 'Cedera Berat atau Fatality',
        'EN': 'Severe Injury or Fatality',
        'ZH': '重伤或死亡',
      },
    ),
  ];

  static AccidentSeverityData? byKey(String? key) {
    if (key == null) return null;
    try {
      return severities.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  static IconData iconOf(String? key) =>
      byKey(key)?.icon ?? Icons.health_and_safety_outlined;

  static Color colorOf(String? key) =>
      byKey(key)?.color ?? const Color(0xFF2563EB);

  static String labelOf(String? key, String lang) {
    final c = byKey(key);
    if (c == null) return key ?? '';
    return c.label[lang] ?? c.label['ID']!;
  }
}

class AccidentPickSeverityScreen extends StatefulWidget {
  final String lang;
  final String? selectedSeverity;

  const AccidentPickSeverityScreen({
    super.key,
    required this.lang,
    this.selectedSeverity,
  });

  @override
  State<AccidentPickSeverityScreen> createState() =>
      _AccidentPickSeverityScreenState();
}

class _AccidentPickSeverityScreenState
    extends State<AccidentPickSeverityScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  Map<String, String> get _txt => _dialogTxt[widget.lang] ?? _dialogTxt['ID']!;

  static const Map<String, Map<String, String>> _dialogTxt = {
    'ID': {
      'title': 'Pilih Tingkat Keparahan',
      'search_hint': 'Cari tingkat keparahan...',
      'empty': 'Tingkat keparahan tidak ditemukan',
      'count': 'tingkat ditemukan',
    },
    'EN': {
      'title': 'Select Accident Severity',
      'search_hint': 'Search severity level...',
      'empty': 'No severity found',
      'count': 'levels found',
    },
    'ZH': {
      'title': '选择事故严重程度',
      'search_hint': '搜索严重程度...',
      'empty': '未找到相关严重程度',
      'count': '个等级',
    },
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AccidentSeverityData> get _filtered {
    if (_query.trim().isEmpty) return AccidentSeverityData.severities;
    final q = _query.toLowerCase();
    return AccidentSeverityData.severities.where((c) {
      final label = (c.label[widget.lang] ?? c.label['ID']!).toLowerCase();
      final desc = (c.desc[widget.lang] ?? c.desc['ID']!).toLowerCase();
      return label.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 14, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.health_and_safety_outlined,
                        color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _txt['title']!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.xmark,
                          size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: TextFormField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _txt['search_hint']!,
                  hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFFCBD5E1), fontSize: 14),
                  prefixIcon: const Icon(CupertinoIcons.search,
                      color: Color(0xFF2563EB), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: Color(0xFFCBD5E1),
                            size: 18,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFF),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE0E7FF))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filtered.length} ${_txt['count']!}',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: const Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // SEVERITY LEVEL LIST
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.search,
                              size: 40, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),
                          Text(
                            _txt['empty']!,
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final isSelected = widget.selectedSeverity == c.key;
                        final label = c.label[widget.lang] ?? c.label['ID']!;
                        final desc = c.desc[widget.lang] ?? c.desc['ID']!;
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, c.key),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? c.color.withValues(alpha: 0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? c.color
                                    : const Color(0xFFE0E7FF),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: c.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(c.icon, color: c.color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isSelected
                                              ? c.color
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        desc,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(CupertinoIcons.check_mark_circled_solid,
                                      color: c.color, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}