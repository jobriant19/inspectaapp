import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AccidentCauseData {
  final String key;
  final IconData icon;
  final Color color;
  final Map<String, String> label;
  final Map<String, String> desc;

  const AccidentCauseData({
    required this.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
  });

  static const List<AccidentCauseData> causes = [
    AccidentCauseData(
      key: 'Mesin',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFF2563EB),
      label: {'ID': 'Mesin', 'EN': 'Machine', 'ZH': '机械'},
      desc: {
        'ID': 'Kecelakaan karena terjebak di alat',
        'EN': 'Accident due to being caught in machinery',
        'ZH': '因被设备夹住导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Benda Berat',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFFF97316),
      label: {'ID': 'Benda Berat', 'EN': 'Heavy Object', 'ZH': '重物'},
      desc: {
        'ID': 'Kecelakaan karena terbentur objek berat',
        'EN': 'Accident due to being struck by a heavy object',
        'ZH': '因被重物砸中导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Kendaraan / Alat Angkut',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF6366F1),
      label: {
        'ID': 'Kendaraan / Alat Angkut',
        'EN': 'Vehicle / Transport Equipment',
        'ZH': '车辆/运输设备',
      },
      desc: {
        'ID': 'Kecelakaan karena alat transportasi',
        'EN': 'Accident due to transportation equipment',
        'ZH': '因运输设备导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Jatuh',
      icon: Icons.arrow_downward_rounded,
      color: Color(0xFFDC2626),
      label: {'ID': 'Jatuh', 'EN': 'Fall', 'ZH': '跌落'},
      desc: {
        'ID': 'Kecelakaan karena jatuh dari ketinggian',
        'EN': 'Accident due to falling from a height',
        'ZH': '因从高处跌落导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Listrik',
      icon: Icons.bolt_rounded,
      color: Color(0xFFEAB308),
      label: {'ID': 'Listrik', 'EN': 'Electrical', 'ZH': '电击'},
      desc: {
        'ID': 'Kecelakaan karena kejutan listrik',
        'EN': 'Accident due to electric shock',
        'ZH': '因触电导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Panas / Api',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEA580C),
      label: {'ID': 'Panas / Api', 'EN': 'Heat / Fire', 'ZH': '高温/火'},
      desc: {
        'ID': 'Kecelakaan karena objek panas',
        'EN': 'Accident due to hot objects',
        'ZH': '因高温物体导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Perkakas',
      icon: Icons.build_rounded,
      color: Color(0xFF0D9488),
      label: {'ID': 'Perkakas', 'EN': 'Tools', 'ZH': '工具'},
      desc: {
        'ID': 'Kecelakaan karena peralatan kerja',
        'EN': 'Accident due to work tools',
        'ZH': '因工作设备导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Benda Tajam',
      icon: Icons.content_cut_rounded,
      color: Color(0xFFDB2777),
      label: {'ID': 'Benda Tajam', 'EN': 'Sharp Object', 'ZH': '锐器'},
      desc: {
        'ID': 'Kecelakaan karena tergores benda tajam',
        'EN': 'Accident due to being cut by a sharp object',
        'ZH': '因被锐器划伤导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Bahan Kimia',
      icon: Icons.science_rounded,
      color: Color(0xFF9333EA),
      label: {'ID': 'Bahan Kimia', 'EN': 'Chemical', 'ZH': '化学品'},
      desc: {
        'ID': 'Kecelakaan karena bahan kimia berbahaya',
        'EN': 'Accident due to hazardous chemicals',
        'ZH': '因危险化学品导致的事故',
      },
    ),
    AccidentCauseData(
      key: 'Lainnya',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF64748B),
      label: {'ID': 'Lainnya', 'EN': 'Other', 'ZH': '其他'},
      desc: {
        'ID': 'Penyebab kecelakaan lainnya',
        'EN': 'Other accident causes',
        'ZH': '其他事故原因',
      },
    ),
  ];

  static AccidentCauseData? byKey(String? key) {
    if (key == null) return null;
    try {
      return causes.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  static IconData iconOf(String? key) =>
      byKey(key)?.icon ?? Icons.warning_amber_rounded;

  static Color colorOf(String? key) =>
      byKey(key)?.color ?? const Color(0xFF2563EB);

  static String labelOf(String? key, String lang) {
    final c = byKey(key);
    if (c == null) return key ?? '';
    return c.label[lang] ?? c.label['ID']!;
  }
}

class AccidentPickCauseScreen extends StatefulWidget {
  final String lang;
  final String? selectedCause;

  const AccidentPickCauseScreen({
    super.key,
    required this.lang,
    this.selectedCause,
  });

  @override
  State<AccidentPickCauseScreen> createState() =>
      _AccidentPickCauseScreenState();
}

class _AccidentPickCauseScreenState extends State<AccidentPickCauseScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  Map<String, String> get _txt => _dialogTxt[widget.lang] ?? _dialogTxt['ID']!;

  static const Map<String, Map<String, String>> _dialogTxt = {
    'ID': {
      'title': 'Pilih Penyebab Kecelakaan',
      'search_hint': 'Cari penyebab kecelakaan...',
      'empty': 'Penyebab tidak ditemukan',
      'count': 'penyebab ditemukan',
    },
    'EN': {
      'title': 'Select Accident Cause',
      'search_hint': 'Search accident cause...',
      'empty': 'No cause found',
      'count': 'causes found',
    },
    'ZH': {
      'title': '选择事故原因',
      'search_hint': '搜索事故原因...',
      'empty': '未找到相关原因',
      'count': '个原因',
    },
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AccidentCauseData> get _filtered {
    if (_query.trim().isEmpty) return AccidentCauseData.causes;
    final q = _query.toLowerCase();
    return AccidentCauseData.causes.where((c) {
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
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
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
                    child: const Icon(Icons.warning_amber_rounded,
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
            // CAUSE LIST
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
                        final isSelected = widget.selectedCause == c.key;
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