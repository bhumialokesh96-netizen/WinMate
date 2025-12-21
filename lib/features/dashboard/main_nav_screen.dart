import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/features/auth/login_screen.dart';
import 'package:winmate/features/home/home_dashboard.dart';
import 'package:winmate/features/mining/mining_dashboard.dart';
import 'package:winmate/features/invite/invite_screen.dart';
import 'package:winmate/services/notification_screen.dart';
// NOTE: No import for profile_screen here because we define it below!

// ---------------------------------------------------------
// 1. MAIN NAVIGATION
// ---------------------------------------------------------
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  // The screens list uses the class defined at the bottom
  final List<Widget> _screens = [
    const HomeDashboard(),   
    const MiningDashboard(), 
    const InviteScreen(),    
    const ProfileScreen(), // This now refers to the class below
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF16213E),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE94560),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Mining"),
          BottomNavigationBarItem(icon: Icon(Icons.rocket_launch), label: "Invite"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. PROFILE SCREEN (Embedded to fix Build Error)
// ---------------------------------------------------------

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
      if (mounted) {
        setState(() {
          phone = user.userMetadata?['phone'] ?? user.phone ?? "Unknown";
          // Just taking first 8 chars for display
          userId = user.id.substring(0, 8).toUpperCase();
        });
      }
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      // Navigate back to Login (Make sure LoginScreen is imported)
      // Navigator.of(context).pushAndRemoveUntil(...) 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("My Profile", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFE94560),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            Text(phone, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("ID: $userId", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 30),
            
            // --- NEW: SYSTEM NOTIFICATION BUTTON ---
            _buildMenuItem(Icons.notifications_active, "System Notifications", () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
            }),

            _buildMenuItem(Icons.security, "Security", () {}),
            _buildMenuItem(Icons.help_outline, "Help & Support", () {}),
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
        title: Text(title, style: GoogleFonts.poppins(color: isRed ? Colors.red : Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
