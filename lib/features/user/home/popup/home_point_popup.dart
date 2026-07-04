import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/jabatan_helper.dart';

final _sb = Supabase.instance.client;

const Map<String, Map<String, String>> _penaltyTexts = {
  'EN': {'title': 'Points Deducted!', 'sub': 'You missed some login days.', 'ok': 'Got It'},
  'ID': {'title': 'Poin Dikurangi!', 'sub': 'Kamu melewatkan beberapa hari login.', 'ok': 'Mengerti'},
  'ZH': {'title': '积分已扣除！', 'sub': '您错过了一些登录天数。', 'ok': '明白'},
};

Future<void> warmupPointPopupFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
      GoogleFonts.poppins(fontWeight: FontWeight.w500),
      GoogleFonts.poppins(fontWeight: FontWeight.w600),
      GoogleFonts.poppins(fontWeight: FontWeight.w700),
      GoogleFonts.poppins(fontWeight: FontWeight.w800),
      GoogleFonts.poppins(fontWeight: FontWeight.w900),
    ]);
  } catch (_) {}
}

Future<void> showLoginPointDialog(
  BuildContext context, {
  required int points,
  required String description,
  required String lang,
  required String userId,
  String? userLokasiId,
  required VoidCallback onClaimed,
  required Future<void> Function(Map<String, dynamic>) onClaimedAndShared,
}) async {
  if (!context.mounted) return;
  if (ModalRoute.of(context)?.isCurrent != true) return;

  final completer = Completer<void>();

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _LoginPointDialog(
      points: points,
      description: description,
      lang: lang,
      userId: userId,
      userLokasiId: userLokasiId,
      onClaimed: () {
        Navigator.of(ctx).pop();
        onClaimed();
        if (!completer.isCompleted) completer.complete();
      },
      onClaimedAndShared: (receiverUser) async {
        Navigator.of(ctx).pop();
        await onClaimedAndShared(receiverUser);
        if (!completer.isCompleted) completer.complete();
      },
    ),
  ).then((_) {
    if (!completer.isCompleted) completer.complete();
  });

  await Future.any([
    completer.future,
    Future.delayed(const Duration(seconds: 10)),
  ]);
  if (!completer.isCompleted) completer.complete();
}

Future<void> showPenaltyDialog(
  BuildContext context, {
  required int points,
  required String description,
  required String lang,
  bool waitForDismiss = false,
}) async {
  if (!context.mounted) return;
  if (ModalRoute.of(context)?.isCurrent != true) return;

  final t = _penaltyTexts[lang] ?? _penaltyTexts['ID']!;
  final completer = Completer<void>();

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _PenaltyDialog(
      absPoints: points.abs(),
      description: description,
      title: t['title']!,
      okLabel: t['ok']!,
      onDismiss: () {
        if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  ).then((_) {
    if (!completer.isCompleted) completer.complete();
  });

  if (waitForDismiss) await completer.future;
}

Future<void> handleSharePoints(
  BuildContext context, {
  required Map<String, dynamic> receiverUser,
  required String lang,
}) async {
  try {
    await _sb.rpc('share_login_points', params: {
      'p_sharer_id': _sb.auth.currentUser?.id,
      'p_receiver_id': receiverUser['id_user'],
      'p_share_amount': 5,
    });
    if (!context.mounted) return;

    int sharedAmt = 5, bonusAmt = 1;
    try {
      final cfg = await _sb
          .from('konfigurasi_poin')
          .select('kode, poin')
          .inFilter('kode', ['berbagi_poin', 'bonus_berbagi'])
          .eq('is_aktif', true);
      for (final row in cfg) {
        if (row['kode'] == 'berbagi_poin') { sharedAmt = (row['poin'] as num).toInt().abs(); }
        else if (row['kode'] == 'bonus_berbagi') { bonusAmt = (row['poin'] as num).toInt().abs(); }
      }
    } catch (_) {}

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lang == 'ID'
                ? '${receiverUser['nama']} mendapat +$sharedAmt poin! Bonus +$bonusAmt poin untukmu.'
                : '${receiverUser['nama']} gets +$sharedAmt points! Bonus +$bonusAmt points for you.',
          ),
        ),
      ]),
      backgroundColor: const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  } catch (e) {
    debugPrint('Error sharing points: $e');
  }
}

class _LoginPointDialog extends StatefulWidget {
  final int points;
  final String description;
  final String lang;
  final String userId;
  final String? userLokasiId;
  final VoidCallback onClaimed;
  final Function(Map<String, dynamic>) onClaimedAndShared;

  const _LoginPointDialog({
    required this.points,
    required this.description,
    required this.lang,
    required this.userId,
    required this.onClaimed,
    required this.onClaimedAndShared,
    this.userLokasiId,
  });

  @override
  State<_LoginPointDialog> createState() => _LoginPointDialogState();
}

class _LoginPointDialogState extends State<_LoginPointDialog>
    with SingleTickerProviderStateMixin {
  static const Color _brightBlue = Color(0xFF00E0FF);
  bool _showUserPicker = false;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const Map<String, Map<String, String>> _txt = {
    'ID': {
      'title': 'Poin Login Diterima!', 'claim': 'Ambil Poin', 'share': 'Ambil & Bagikan',
      'share_title': 'Pilih teman untuk berbagi 5 poin',
      'share_info': 'Kamu akan berbagi 5 poin dan mendapat bonus +1 poin!',
      'search': 'Cari teman...',
    },
    'EN': {
      'title': 'Login Points Received!', 'claim': 'Claim Points', 'share': 'Claim & Share',
      'share_title': 'Pick a friend to share 5 points',
      'share_info': 'You share 5 points and earn +1 bonus point!',
      'search': 'Search friend...',
    },
    'ZH': {
      'title': '登录积分已获得！', 'claim': '领取积分', 'share': '领取并分享',
      'share_title': '选择朋友分享5积分',
      'share_info': '您分享5积分并获得+1奖励积分！',
      'search': '搜索朋友...',
    },
  };

  Map<String, String> get t => _txt[widget.lang] ?? _txt['ID']!;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (_users.isNotEmpty) return;
    setState(() => _isLoadingUsers = true);
    try {
      var query = _sb
          .from('User')
          .select('id_user, nama, id_jabatan, is_verificator, jabatan(nama_jabatan)')
          .neq('id_user', widget.userId);
      if (widget.userLokasiId != null) query = query.eq('id_lokasi', widget.userLokasiId!);
      final data = await query.order('nama').limit(50);
      if (mounted) setState(() { _users = List<Map<String, dynamic>>.from(data); _isLoadingUsers = false; });
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<int> _getShareAmount() async {
    try {
      final data = await _sb
          .from('konfigurasi_poin')
          .select('poin')
          .eq('kode', 'berbagi_poin')
          .eq('is_aktif', true)
          .maybeSingle();
      return (data?['poin'] as num?)?.toInt().abs() ?? 5;
    } catch (_) { return 5; }
  }

  Widget _buildShareUserBadge(Map<String, dynamic> u) {
    final bool? isVerif = u['is_verificator'] as bool?;
    final int? idJabatan = u['id_jabatan'] as int?;
    final String? jabatanNama =
        (u['jabatan'] as Map<String, dynamic>?)?['nama_jabatan'];

    final label = JabatanHelper.getDisplayRole(
      isVerificatorFlag: isVerif,
      idJabatan: idJabatan,
      jabatanFromDb: jabatanNama,
      lang: widget.lang,
    );
    if (label.isEmpty) return const SizedBox.shrink();

    final color = JabatanHelper.getPrimaryColor(
        isVerificatorFlag: isVerif, idJabatan: idJabatan);
    final icon = JabatanHelper.getRoleIcon(
        isVerificatorFlag: isVerif, idJabatan: idJabatan);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9E4).withValues(alpha:0.3),
                blurRadius: 40, spreadRadius: 5, offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _showUserPicker ? _buildUserPickerView() : _buildMainView(),
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C9E4), Color(0xFF0891B2)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00C9E4).withValues(alpha:0.4), blurRadius: 20, spreadRadius: 3),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 20),
          Text(t['title']!, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFB8F0FF), Color(0xFFE0F7FF)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('+${widget.points} Points',
                style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0891B2))),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Text(widget.description, textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, height: 1.5)),
          ),
          const SizedBox(height: 24),
          _ActionButton(
            onTap: widget.onClaimed,
            color: const Color(0xFF00C9E4),
            icon: Icons.local_fire_department_rounded,
            label: t['claim']!,
            isOutlined: false,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            onTap: () async { await _loadUsers(); setState(() => _showUserPicker = true); },
            color: const Color(0xFF00C9E4),
            icon: Icons.local_fire_department_rounded,
            label: t['share']!,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUserPickerView() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(_users);

    return StatefulBuilder(
      builder: (context, setInner) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER 
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => setState(() => _showUserPicker = false),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    t['share_title']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),

          // INFO BOX 
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _brightBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brightBlue.withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: _brightBlue, size: 16),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(t['share_info']!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF0891B2)))),
            ]),
          ),
          const SizedBox(height: 12),

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: _brightBlue.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: _brightBlue.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: searchCtrl,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E3A8A)),
                onChanged: (q) {
                  setInner(() {
                    filtered = _users
                        .where((u) => u['nama']
                            .toString()
                            .toLowerCase()
                            .contains(q.toLowerCase()))
                        .toList();
                  });
                },
                decoration: InputDecoration(
                  hintText: t['search']!,
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _brightBlue, size: 22),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchCtrl.clear();
                            setInner(() => filtered = List.from(_users));
                          },
                          child: Icon(Icons.close_rounded,
                              color: Colors.grey.shade400, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // USER LIST
          SizedBox(
            height: 260,
            child: _isLoadingUsers
                ? const Center(
                    child: CircularProgressIndicator(color: _brightBlue))
                : filtered.isEmpty
                    ? const Center(
                        child: Text('Tidak ada teman',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final u = filtered[i];
                          return GestureDetector(
                            onTap: () => widget.onClaimedAndShared(u),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: _brightBlue.withValues(alpha: 0.18)),
                                boxShadow: [
                                  BoxShadow(
                                      color: _brightBlue.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // AVATAR 
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [_brightBlue, Color(0xFF0891B2)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 19,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 17,
                                        backgroundColor:
                                            _brightBlue.withValues(alpha: 0.12),
                                        child: Text(
                                          u['nama'][0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Color(0xFF1E3A8A),
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // NAME + BADGE ROLE
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(u['nama'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                                color:
                                                    const Color(0xFF1E3A8A))),
                                        const SizedBox(height: 5),
                                        _buildShareUserBadge(u),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // BADGE POIN
                                  FutureBuilder<int>(
                                    future: _getShareAmount(),
                                    builder: (_, snap) {
                                      final amt = snap.data ?? 5;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A)
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: const Color(0xFF16A34A)
                                                  .withValues(alpha: 0.35)),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Dapat',
                                                style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.add_rounded,
                                                    size: 12,
                                                    color: Color(0xFF16A34A)),
                                                Text('$amt poin',
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFF16A34A),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 12.5)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String label;
  final bool isOutlined;

  const _ActionButton({
    required this.onTap, required this.color, required this.icon,
    required this.label, required this.isOutlined,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: isOutlined ? color : Colors.white),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );

    return SizedBox(
      width: double.infinity, height: 52,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                foregroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: child,
            ),
    );
  }
}

class _PenaltyDialog extends StatefulWidget {
  final int absPoints;
  final String description;
  final String title;
  final String okLabel;
  final VoidCallback onDismiss;

  const _PenaltyDialog({
    required this.absPoints, required this.description,
    required this.title, required this.okLabel, required this.onDismiss,
  });

  @override
  State<_PenaltyDialog> createState() => _PenaltyDialogState();
}

class _PenaltyDialogState extends State<_PenaltyDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim, _fadeAnim, _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const Color red = Color(0xFFDC2626);
    const Color redLight = Color(0xFFFEF2F2);
    const Color redMid = Color(0xFFFFE4E6);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Transform.scale(scale: _scaleAnim.value, child: child),
        ),
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: red.withValues(alpha:0.18), width: 1.5),
              boxShadow: [
                BoxShadow(color: red.withValues(alpha:0.18), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: const BoxDecoration(
                    color: redMid,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(children: [
                    _PulsingRing(
                      color: red,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: red.withValues(alpha:0.12), shape: BoxShape.circle,
                          border: Border.all(color: red.withValues(alpha:0.35), width: 2),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: red, size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.title,
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: red)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(50)),
                      child: Text('-${widget.absPoints} Poin',
                          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: redLight, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: red.withValues(alpha:0.12)),
                      ),
                      child: Text(widget.description, textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500,
                              color: const Color(0xFF7F1D1D), height: 1.6)),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 0.0),
                        duration: const Duration(milliseconds: 6000),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v, minHeight: 3,
                          backgroundColor: red.withValues(alpha:0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(red.withValues(alpha:0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red, foregroundColor: Colors.white, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(widget.okLabel,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  final Color color;
  final Widget child;
  const _PulsingRing({required this.color, required this.child});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _anim.value,
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha:0.08 * (2.0 - _anim.value)),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}