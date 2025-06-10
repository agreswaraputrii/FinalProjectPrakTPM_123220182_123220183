import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaranKesanPage extends StatelessWidget {
  const SaranKesanPage({super.key});

  final Color primaryColor = const Color(0xFF2E7D32); // Green
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35); // Orange accent
  final Color backgroundColor = const Color(0xFFF1F8E9);
  final Color cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            Colors.white,
            backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Saran dan Kesan Mata Kuliah Teknologi Pemrograman Mobile",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Saran:",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Mata kuliah ini sangat menyenangkan dan membuka wawasan saya tentang bagaimana aplikasi mobile dibuat dari awal. Penjelasan dosen mudah dipahami dan praktiknya cukup menantang namun seru. Semoga ke depannya materi terus disesuaikan dengan perkembangan Flutter yang cepat agar makin relevan dengan dunia kerja.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Kesan:",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Saya merasa sangat terbantu dengan penjelasan yang diberikan, terutama terkait konsep-konsep dasar Flutter dan Provider. Praktikum yang diberikan juga sangat membantu dalam memahami implementasi teori. Meskipun terkadang menantang, proses belajarnya menyenangkan dan memberikan fondasi yang kuat untuk pengembangan aplikasi mobile di masa depan. Terima kasih banyak!",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
