import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class MyPersonalProfilePage extends StatelessWidget {
  const MyPersonalProfilePage({super.key});

  final Color primaryColor = const Color(0xFF2E7D32);
  final Color secondaryColor = const Color(0xFF388E3C);
  final Color accentColor = const Color(0xFFFF6B35);
  final Color backgroundColor = const Color(0xFFF1F8E9);
  final Color cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Add this to make container take full height
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.3),    // Green
            backgroundColor,                   // Light green
            Colors.white,                     // White
            accentColor.withOpacity(0.2),     // Light orange
            accentColor.withOpacity(0.3),     // Orange
          ],
          // Adjust stops for smoother color transition
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        // Add bottom: false to extend beyond safe area
        bottom: false,
        child: SingleChildScrollView(
          // Remove padding bottom to allow content to extend
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            children: [
              // Title Section
              Text(
                "Our Team",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Grid of Profiles with Animation
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16, // Reduced spacing
                crossAxisSpacing: 16, // Reduced spacing
                childAspectRatio: 0.55, // Adjusted to accommodate all content
                children: [
                  _buildEnhancedProfileCard(
                    name: "Agreswara Putri Wijaya",
                    nim: "123220182",
                    kelas: "Praktikum Mobile IF - G",
                    imagePath: 'assets/putrii.jpg',
                    role: "Developer",
                    hobby: "Coding",
                    birthInfo: "Born in Solo, 28 Juni 2004",
                  ),
                  _buildEnhancedProfileCard(
                    name: "Qur'ana Aulia Harlianty",
                    nim: "123220182",
                    kelas: "Praktikum Mobile IF - G",
                    imagePath: 'assets/nanaa.jpg',
                    role: "Developer",
                    hobby: "Travelling",
                    birthInfo: "Born in Bandung, 31 Des 2004",
                  ),
                ],
              ),

              // Add extra padding at bottom to ensure content doesn't get cut off
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedProfileCard({
    required String name,
    required String nim,
    required String kelas,
    required String imagePath,
    required String role,
    String hobby = "",
    String birthInfo = "",
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced padding
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Add this
            children: [
              // Profile Picture
              Container(
                padding: const EdgeInsets.all(3), // Reduced padding
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 35, // Reduced radius
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: AssetImage(imagePath),
                ),
              ),
              const SizedBox(height: 8), // Reduced spacing

              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  role,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Name
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // NIM
              Text(
                nim,
                style: GoogleFonts.poppins(
                  fontSize: 12, // Reduced font size
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              // Kelas
              Text(
                kelas,
                style: GoogleFonts.poppins(
                  fontSize: 10, // Reduced font size
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Hobby
              if (hobby.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoBadge(
                  text: "Hobby: $hobby",
                  color: secondaryColor,
                ),
              ],

              // Birth Info
              if (birthInfo.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoBadge(
                  text: birthInfo,
                  color: primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Add this helper method for badges
  Widget _buildInfoBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
