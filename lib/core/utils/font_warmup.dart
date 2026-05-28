import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> warmupAdminFonts(BuildContext context) async {
  try {
    await Future.wait([
      GoogleFonts.pendingFonts([
        GoogleFonts.poppins(),
        GoogleFonts.sourceCodePro(),
        GoogleFonts.inter(),
      ]),
    ]).timeout(const Duration(seconds: 5));
  } catch (_) {}

  if (!context.mounted) return;

  final completer = Completer<void>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -9999,
      top: -9999,
      child: Opacity(
        opacity: 0.0,
        child: Material(
          color: Colors.transparent,
          child: _FontWarmupContent(
            onRendered: () {
              if (!completer.isCompleted) completer.complete();
            },
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(entry);

  try {
    await completer.future.timeout(const Duration(milliseconds: 500));
  } catch (_) {}

  for (int i = 0; i < 3; i++) {
    await WidgetsBinding.instance.endOfFrame;
  }

  entry.remove();
  await WidgetsBinding.instance.endOfFrame;
}

class _FontWarmupContent extends StatefulWidget {
  final VoidCallback onRendered;
  const _FontWarmupContent({required this.onRendered});

  @override
  State<_FontWarmupContent> createState() => _FontWarmupContentState();
}

class _FontWarmupContentState extends State<_FontWarmupContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onRendered());
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(children: [
      Text('w', style: GoogleFonts.poppins(fontSize: 8,  fontWeight: FontWeight.w400)),
      Text('w', style: GoogleFonts.poppins(fontSize: 8,  fontWeight: FontWeight.w500)),
      Text('w', style: GoogleFonts.poppins(fontSize: 8,  fontWeight: FontWeight.w600)),
      Text('w', style: GoogleFonts.poppins(fontSize: 8,  fontWeight: FontWeight.w700)),
      Text('w', style: GoogleFonts.poppins(fontSize: 8,  fontWeight: FontWeight.w800)),
      Text('w', style: GoogleFonts.poppins(fontSize: 8,  fontWeight: FontWeight.w900)),
      Text('w', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
      Text('w', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800)),
      Text('w', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
      Text('w', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700)),
      Text('w', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500)),
      Text('00:00', style: GoogleFonts.sourceCodePro(fontSize: 20, fontWeight: FontWeight.w800)),
      Text('00',    style: GoogleFonts.sourceCodePro(fontSize: 15, fontWeight: FontWeight.w800)),
      Text('00',    style: GoogleFonts.sourceCodePro(fontSize: 8,  fontWeight: FontWeight.w700)),
    ]);
  }
}