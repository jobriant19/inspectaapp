import 'package:flutter/material.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Pindai QR Lokasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Area Kamera Placeholder (TODO: widget MobileScanner jika sudah install package)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Tombol Balik Kamera
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
              onPressed: () {},
            ),
          ),

          // Teks di bawah Scanner
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Geser untuk memperbesar pemindai",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),

          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: const Center(
              child: Text(
                "Scan QR untuk memilih lokasi dengan cepat dan akurat.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          // Tombol Gallery dan Senter
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRoundButton(Icons.photo_library, () {}),
                const SizedBox(width: 40),
                _buildRoundButton(Icons.flashlight_on, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
      ),
    );
  }
}