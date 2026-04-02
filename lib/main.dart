import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Database Supabase
  await Supabase.initialize(
    url: 'https://kbxlyirihypzexblygzp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtieGx5aXJpaHlwemV4Ymx5Z3pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NzgyMjYsImV4cCI6MjA5MDU1NDIyNn0.fIML1z3tAT1ws5FyAPDXp7BFwGxRC_GuRtFyCJouYiA',
  );

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
      home: const LoginScreen(),
    );
  }
}