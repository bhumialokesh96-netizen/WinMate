import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/auth/login_screen.dart';
import 'package:winmate/features/mining/mining_dashboard.dart';
import 'package:winmate/features/invite/invite_screen.dart'; // <--- NEW IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- 1. DEFINE THE PAGES HERE ---
  final List<Widget> _pages = [
    const MiningDashboard(), // Tab 0: Mining
    const InviteScreen(),    // Tab 1: Invite & Earn (NEW)
    const Center(            // Tab 2: Wallet (Placeholder)
      child: Text(
        "Wallet Coming Soon", 
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark Navy Background
      
      // The body changes based on the selected tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // --- 2. BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF16213E), // Slightly lighter navy
          selectedItemColor: const Color(0xFFE94560), // Pink/Red accent
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          labelStyle: GoogleFonts.poppins(fontSize: 12),
          
          items: const [
            // Tab 0
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt),
              label: 'Mining',
            ),
            
            // Tab 1 (UPDATED)
            BottomNavigationBarItem(
              icon: Icon(Icons.rocket_launch), // Rocket icon for Invites
              label: 'Invite',
            ),
            
            // Tab 2
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
          ],
        ),
      ),
    );
  }
}
