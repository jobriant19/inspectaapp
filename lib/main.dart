import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/in/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INITIALIZE SUPABASE
  await Supabase.initialize(
    url: 'https://kbxlyirihypzexblygzp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtieGx5aXJpaHlwemV4Ymx5Z3pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzgyMjYsImV4cCI6MjA5MDU1NDIyNn0.fIML1z3tAT1ws5FyAPDXp7BFwGxRC_GuRtFyCJouYiA',
  );

  // FIREBASE & NOTIFICATION
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.instance.initialize();
    await PushNotificationService.instance.init();
  }

  await initializeDateFormatting('id_ID', null);
  try {
    await Future.wait([
      GoogleFonts.pendingFonts([
        GoogleFonts.poppins(fontWeight: FontWeight.w400),
        GoogleFonts.poppins(fontWeight: FontWeight.w500),
        GoogleFonts.poppins(fontWeight: FontWeight.w600),
        GoogleFonts.poppins(fontWeight: FontWeight.w700),
        GoogleFonts.poppins(fontWeight: FontWeight.w800),
        GoogleFonts.poppins(fontWeight: FontWeight.w900),
        GoogleFonts.inter(fontWeight: FontWeight.w400),
        GoogleFonts.inter(fontWeight: FontWeight.w700),
        GoogleFonts.inter(fontWeight: FontWeight.w800),
        GoogleFonts.inter(fontWeight: FontWeight.w900),
        GoogleFonts.sourceCodePro(),
        GoogleFonts.notoSansSc(fontWeight: FontWeight.w400),
        GoogleFonts.notoSansSc(fontWeight: FontWeight.w500),
        GoogleFonts.notoSansSc(fontWeight: FontWeight.w600),
        GoogleFonts.notoSansSc(fontWeight: FontWeight.w700),
        GoogleFonts.notoSansSc(fontWeight: FontWeight.w800),
      ]),
    ]).timeout(const Duration(seconds: 5));
  } catch (_) {}

  runApp(const InspectaApp());
}

class InspectaApp extends StatelessWidget {
  const InspectaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspecta App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00B5E4),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
    );
  }
}