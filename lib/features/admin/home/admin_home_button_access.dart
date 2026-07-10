import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

class AdminHomeButtonAccess extends StatelessWidget {
  final String lang;

  const AdminHomeButtonAccess({
    super.key,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProModeToggleCard(lang: lang),
        const SizedBox(height: 10),
        _PreventiveMaintenanceToggleCard(lang: lang),
      ],
    );
  }
}

// MODE PROFESSIONAL TOGGLE
class _ProModeToggleCard extends StatefulWidget {
  final String lang;

  const _ProModeToggleCard({
    required this.lang,
  });

  @override
  State<_ProModeToggleCard> createState() => _ProModeToggleCardState();
}

class _ProModeToggleCardState extends State<_ProModeToggleCard> {
  static const String _kKey = 'pro_mode_button_visible';
  static const Color _primary = Color(0xFF059669);
  static const LinearGradient _iconGradient = LinearGradient(
    colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
  );

  bool _isVisible = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    try {
      final row = await _sb
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', _kKey)
          .maybeSingle();
      final value = row?['setting_value'] as bool? ?? true;
      if (mounted && value != _isVisible) {
        setState(() => _isVisible = value);
      }
    } catch (e) {
      debugPrint('Error loading $_kKey: $e');
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _isVisible = value;
      _isSaving = true;
    });
    try {
      await _sb.from('app_settings').upsert({
        'setting_key': _kKey,
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving $_kKey: $e');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  String _t(String key) {
    final Map<String, Map<String, String>> txt = {
      'EN': {
        'label': 'Pro Mode Button',
        'on': 'Visible to users',
        'off': 'Hidden from users',
      },
      'ID': {
        'label': 'Tombol Mode Pro',
        'on': 'Terlihat oleh pengguna',
        'off': 'Disembunyikan dari pengguna',
      },
      'ZH': {
        'label': '专业模式按钮',
        'on': '用户可见',
        'off': '对用户隐藏',
      },
    };
    return txt[widget.lang]?[key] ?? txt['EN']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isVisible ? _primary.withValues(alpha:0.3) : Colors.grey.shade200,
          width: _isVisible ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha:0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: _isVisible ? _iconGradient : null,
              color: _isVisible ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isVisible
                  ? [
                      BoxShadow(
                        color: _primary.withValues(alpha:0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: _isVisible ? Colors.white : Colors.grey.shade400,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('label'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isVisible ? _primary : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isVisible
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isVisible ? _t('on') : _t('off'),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _isVisible
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: _primary,
                    strokeWidth: 2,
                  ),
                )
              : Switch(
                  value: _isVisible,
                  onChanged: _toggle,
                  activeColor: _primary,
                  activeTrackColor: _primary.withValues(alpha:0.25),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade200,
                ),
        ],
      ),
    );
  }
}

// PREVENTIF MAINTENANCE TOGGLE
class _PreventiveMaintenanceToggleCard extends StatefulWidget {
  final String lang;

  const _PreventiveMaintenanceToggleCard({
    required this.lang,
  });

  @override
  State<_PreventiveMaintenanceToggleCard> createState() =>
      _PreventiveMaintenanceToggleCardState();
}

class _PreventiveMaintenanceToggleCardState
    extends State<_PreventiveMaintenanceToggleCard> {
  static const String _kKey = 'preventive_maintenance_visible';
  static const Color _primary = Color(0xFF1D4ED8);
  static const LinearGradient _iconGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
  );

  bool _isVisible = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    try {
      final row = await _sb
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', _kKey)
          .maybeSingle();
      final value = row?['setting_value'] as bool? ?? true;
      if (mounted && value != _isVisible) {
        setState(() => _isVisible = value);
      }
    } catch (e) {
      debugPrint('Error loading $_kKey: $e');
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _isVisible = value;
      _isSaving = true;
    });
    try {
      await _sb.from('app_settings').upsert({
        'setting_key': _kKey,
        'setting_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving $_kKey: $e');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  String _t(String key) {
    final Map<String, Map<String, String>> txt = {
      'EN': {
        'label': 'Preventive Maintenance Button',
        'on': 'Visible to users',
        'off': 'Hidden from users',
      },
      'ID': {
        'label': 'Tombol Pemeliharaan Preventif',
        'on': 'Terlihat oleh pengguna',
        'off': 'Disembunyikan dari pengguna',
      },
      'ZH': {
        'label': '预防性维护按钮',
        'on': '用户可见',
        'off': '对用户隐藏',
      },
    };
    return txt[widget.lang]?[key] ?? txt['EN']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isVisible ? _primary.withValues(alpha:0.3) : Colors.grey.shade200,
          width: _isVisible ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha:0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: _isVisible ? _iconGradient : null,
              color: _isVisible ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isVisible
                  ? [
                      BoxShadow(
                        color: _primary.withValues(alpha:0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              Icons.build_circle_rounded,
              color: _isVisible ? Colors.white : Colors.grey.shade400,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('label'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isVisible ? _primary : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isVisible
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isVisible ? _t('on') : _t('off'),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: _isVisible
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: _primary,
                    strokeWidth: 2,
                  ),
                )
              : Switch(
                  value: _isVisible,
                  onChanged: _toggle,
                  activeColor: _primary,
                  activeTrackColor: _primary.withValues(alpha:0.25),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade200,
                ),
        ],
      ),
    );
  }
}