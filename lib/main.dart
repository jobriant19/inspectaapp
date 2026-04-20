import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/in/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

// Firebase & Notification — hanya di-import saat bukan web
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase & Notification: hanya aktif di Android/iOS ──
  // Saat flutter run -d chrome, blok ini dilewati agar tidak crash
  if (!kIsWeb) {
    await Firebase.initializeApp();

    // Set background handler SEBELUM runApp
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Inisialisasi NotificationService
    await NotificationService.instance.initialize();
  }

  // ── Inisialisasi Supabase ──
  await Supabase.initialize(
    url: 'https://kbxlyirihypzexblygzp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtieGx5aXJpaHlwemV4Ymx5Z3pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzgyMjYsImV4cCI6MjA5MDU1NDIyNn0.fIML1z3tAT1ws5FyAPDXp7BFwGxRC_GuRtFyCJouYiA',
  );

  await initializeDateFormatting('id_ID', null);
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