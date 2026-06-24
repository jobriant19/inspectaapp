import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '5r findings/analytics_5r_tab.dart';
import 'analytics_kts_tab.dart';
import 'analytics_accident_tab.dart';

// MAIN SCREEN
class AnalyticsScreen extends StatefulWidget {
  final String lang;
  const AnalyticsScreen({super.key, required this.lang});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // FINDING TYPE SELECTOR
  String _selectedFindingType = '5R';

  // BUILD METHOD
  @override
  Widget build(BuildContext context) {
    // KTS PRODUCTION
    if (_selectedFindingType == 'KTS Production') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          _buildFindingTypeSelector(),
          Expanded(
            child: KTSAnalyticsTab(
              lang: widget.lang,
              userId: _supabase.auth.currentUser?.id ?? '',
              onTabChanged: () {},
            ),
          ),
        ]),
      );
    }

    // ACCIDENT REPORT
    if (_selectedFindingType == 'Accident') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          _buildFindingTypeSelector(),
          Expanded(
            child: AnalyticsAccidentTab(lang: widget.lang),
          ),
        ]),
      );
    }

    // 5R Finding (DEFAULT)
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        _buildFindingTypeSelector(),
        Expanded(
          child: Analytics5RTab(lang: widget.lang),
        ),
      ]),
    );
  }

  // FINDING TYPE SELECTOR BUILD
  Widget _buildFindingTypeSelector() {
    const types = [
      {'key': '5R', 'label': '5R Finding', 'icon': Icons.search_rounded},
      {'key': 'KTS Production', 'label': 'KTS Production', 'icon': Icons.precision_manufacturing_rounded},
      {'key': 'Accident', 'label': 'Accident Report', 'icon': Icons.warning_amber_rounded},
    ];
    const activeColors = {
      '5R': Color(0xFF0EA5E9),
      'KTS Production': Color(0xFFF59E0B),
      'Accident': Color(0xFFEF4444),
    };
    const borderColors = {
      '5R': Color(0xFF7DD3FC),
      'KTS Production': Color(0xFFFCD34D),
      'Accident': Color(0xFFFCA5A5),
    };

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: types.map((t) {
          final key = t['key'] as String;
          final isSelected = _selectedFindingType == key;
          final activeColor = activeColors[key]!;
          final borderColor = isSelected ? activeColor : borderColors[key]!;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: key != 'Accident' ? 6 : 0),
              child: GestureDetector(
                onTap: () {
                  if (_selectedFindingType != key) {
                    setState(() => _selectedFindingType = key);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isSelected ? [BoxShadow(
                      color: activeColor.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3),
                    )] : [],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t['icon'] as IconData, size: 12,
                            color: isSelected ? Colors.white : activeColor),
                        const SizedBox(width: 4),
                        Flexible(child: Text(
                          t['label'] as String,
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : activeColor,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}