import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String phone = "Loading...";
  String userId = "";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        phone = user.userMetadata?['phone'] ?? user.phone ?? "Unknown";
        userId = user.id.substring(0, 8).toUpperCase(); // Show first 8 chars of ID
      });
    }
  }

  Future<void> _logout() async {
    // 1. Sign out from Supabase
    await supabase.auth.signOut();
    
    // 2. Navigate back to Login Screen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark Navy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("My Profile", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- AVATAR & INFO ---
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFE94560),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              phone,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              "ID: $userId",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // --- MENU ITEMS ---
            _buildMenuItem(Icons.person_outline, "Edit Profile", () {}),
            _buildMenuItem(Icons.security, "Security", () {}),
            _buildMenuItem(Icons.help_outline, "Help & Support", () {}),
            _buildMenuItem(Icons.privacy_tip_outlined, "Privacy Policy", () {}),
            
            const SizedBox(height: 20),
            
            // --- LOGOUT BUTTON ---
            _buildMenuItem(Icons.logout, "Logout", _logout, isRed: true),
            
            const SizedBox(height: 30),
            Text("Version 1.0.0", style: GoogleFonts.poppins(color: Colors.white24)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isRed = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: isRed ? Colors.red : Colors.white),
        title: Text(
          title, 
          style: GoogleFonts.poppins(
            color: isRed ? Colors.red : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
