import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_unblock_screen.dart';
import 'admin_change_password.dart';

class AdminUserNotifScreen extends StatefulWidget {
  final String lang;
  const AdminUserNotifScreen({super.key, required this.lang});

  @override
  State<AdminUserNotifScreen> createState() => _AdminUserNotifScreenState();
}

class _AdminUserNotifScreenState extends State<AdminUserNotifScreen> with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF6366F1);
  late final TabController _tabController;

  String get _lang => widget.lang;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Admin User Notifications',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: _primary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primary,
          unselectedLabelColor: Colors.black38,
          indicatorColor: _primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12.5),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5),
          tabs: [
            Tab(
              text: _lang == 'EN'
                  ? 'Unblock Request'
                  : _lang == 'ZH'
                      ? '解封请求'
                      : 'Unblock Request',
            ),
            Tab(
              text: _lang == 'EN'
                  ? 'Change Password'
                  : _lang == 'ZH'
                      ? '更改密码'
                      : 'Change Password',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminUnblockScreen(lang: _lang, embedded: true),
          AdminChangePasswordScreen(lang: _lang),
        ],
      ),
    );
  }
}