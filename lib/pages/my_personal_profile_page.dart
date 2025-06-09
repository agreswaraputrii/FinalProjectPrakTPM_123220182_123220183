// lib/pages/my_personal_profile_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyPersonalProfilePage extends StatelessWidget {
  // Removed onSwitchToSaranKesan as it's now a direct tab in HomePage
  const MyPersonalProfilePage({super.key});

  // Color scheme (matching RegisterPage and new HomePage style)
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
              // Personal Profile Picture (using your provided image)
              CircleAvatar(
                radius: 60,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage: const AssetImage('assets/foto_saya.jpg'),
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint(
                    'Error loading personal profile image: $exception',
                  );
                },
                child: const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              Text(
                "Agreswara Putri Wijaya",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '123220182',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Personal Data Card
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
                      "Data Diri Pribadi:",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildProfileInfoRow(
                      icon: Icons.account_circle_rounded,
                      label: "Nama",
                      value: "Agreswara Putri Wijaya",
                    ),
                    _buildProfileInfoRow(
                      icon: Icons.numbers_rounded,
                      label: "NIM",
                      value: "123220182",
                    ),
                    _buildProfileInfoRow(
                      icon: Icons.school_rounded,
                      label: "Kelas",
                      value: "Teknologi Pemrograman Mobile IF - C",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Removed Saran & Kesan section from here
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
