import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';

final _sb = Supabase.instance.client;

const Map<String, Map<String, String>> _blockTexts = {
  'EN': {
    'title': 'Account Blocked!',
    'desc': 'You have not logged in for 5 days or more. Your account is temporarily blocked.',
    'request_btn': 'Request Unblock',
    'pending': 'Your unblock request is being reviewed by Admin.',
    'close': 'Close',
  },
  'ID': {
    'title': 'Akun Diblokir!',
    'desc': 'Anda tidak login selama 5 hari atau lebih. Akun Anda diblokir sementara.',
    'request_btn': 'Ajukan Pembukaan Blokir',
    'pending': 'Permintaan pembukaan blokir Anda sedang ditinjau oleh Admin.',
    'close': 'Tutup',
  },
  'ZH': {
    'title': '账户已封锁！',
    'desc': '您已5天或更长时间未登录。您的账户已被暂时封锁。',
    'request_btn': '申请解封',
    'pending': '您的解封请求正在由管理员审核中。',
    'close': '关闭',
  },
};

/// Tampilkan pop up blokir. Dipanggil setelah pop up penalti selesai.
Future<void> showLoginBlockedDialog(
  BuildContext context, {
  required String lang,
  required String userId,
  required bool alreadyRequested,
  required VoidCallback onRequested,
}) async {
  if (!context.mounted) return;
  if (ModalRoute.of(context)?.isCurrent != true) return;

  final completer = Completer<void>();

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _LoginBlockedDialog(
      lang: lang,
      userId: userId,
      alreadyRequested: alreadyRequested,
      onRequested: onRequested,
      onDismiss: () {
        if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  ).then((_) {
    if (!completer.isCompleted) completer.complete();
  });

  await completer.future;
}

class _LoginBlockedDialog extends StatefulWidget {
  final String lang;
  final String userId;
  final bool alreadyRequested;
  final VoidCallback onRequested;
  final VoidCallback onDismiss;

  const _LoginBlockedDialog({
    required this.lang,
    required this.userId,
    required this.alreadyRequested,
    required this.onRequested,
    required this.onDismiss,
  });

  @override
  State<_LoginBlockedDialog> createState() => _LoginBlockedDialogState();
}

class _LoginBlockedDialogState extends State<_LoginBlockedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim, _fadeAnim, _slideAnim;
  bool _isRequesting = false;
  bool _hasRequested = false;

  Map<String, String> get t => _blockTexts[widget.lang] ?? _blockTexts['ID']!;

  @override
  void initState() {
    super.initState();
    _hasRequested = widget.alreadyRequested;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submitRequest() async {
    if (_isRequesting || _hasRequested) return;
    setState(() => _isRequesting = true);
    try {
      await _sb.from('User').update({
        'unblock_requested': true,
        'unblock_requested_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id_user', widget.userId);

      await _notifyAdmins();

      if (mounted) {
        setState(() { _hasRequested = true; _isRequesting = false; });
        widget.onRequested();
      }
    } catch (e) {
      debugPrint('Error requesting unblock: $e');
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _notifyAdmins() async {
    try {
      final userRow = await _sb
          .from('User')
          .select('nama')
          .eq('id_user', widget.userId)
          .maybeSingle();
      final String namaUser = userRow?['nama']?.toString() ?? '-';

      final admins = await _sb
          .from('User')
          .select('fcm_token')
          .eq('id_jabatan', 6);

      debugPrint('📤 [FCM-UNBLOCK] Mengirim notifikasi pengajuan blokir ke ${admins.length} admin...');

      final title = widget.lang == 'EN'
          ? '🔒 Unblock Request'
          : widget.lang == 'ZH'
              ? '🔒 解封请求'
              : '🔒 Pengajuan Pembukaan Blokir';
      final body = widget.lang == 'EN'
          ? '$namaUser requested an account unblock.'
          : widget.lang == 'ZH'
              ? '$namaUser 申请解封账户。'
              : '$namaUser mengajukan pembukaan blokir akun.';

      int sent = 0, skipped = 0;
      for (final admin in admins) {
        final token = admin['fcm_token']?.toString();
        if (token != null && token.isNotEmpty) {
          final ok = await NotificationService.sendFcmToToken(
            fcmToken: token,
            title: title,
            body: body,
            route: 'admin_unblock',
          );
          if (ok) {
            sent++;
          } else {
            debugPrint('❌ [FCM-UNBLOCK] Gagal kirim ke salah satu admin (token ada, tapi FCM gagal)');
          }
        } else {
          skipped++;
        }
      }
      debugPrint('✅ [FCM-UNBLOCK] Selesai — terkirim: $sent, dilewati (tanpa token): $skipped');
    } catch (e) {
      debugPrint('❌ [FCM-UNBLOCK] Error notifying admins: $e');
    }
  }

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
              border: Border.all(color: red.withValues(alpha: 0.18), width: 1.5),
              boxShadow: [
                BoxShadow(color: red.withValues(alpha: 0.18), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
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
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.12), shape: BoxShape.circle,
                        border: Border.all(color: red.withValues(alpha: 0.35), width: 2),
                      ),
                      child: const Icon(Icons.lock_rounded, color: red, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(t['title']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: red)),
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
                        border: Border.all(color: red.withValues(alpha: 0.12)),
                      ),
                      child: Text(t['desc']!, textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500,
                              color: const Color(0xFF7F1D1D), height: 1.6)),
                    ),
                    const SizedBox(height: 20),
                    if (_hasRequested)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(t['pending']!, textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF92400E))),
                          ),
                        ]),
                      )
                    else
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _isRequesting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: red, foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isRequesting
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                              : Text(t['request_btn']!,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.onDismiss,
                      child: Text(
                        t['close']!,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600),
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