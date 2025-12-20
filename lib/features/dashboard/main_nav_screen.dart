import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/auth/login_screen.dart';
import 'package:winmate/features/mining/mining_dashboard.dart';
import 'package:winmate/features/invite/invite_screen.dart';
import 'package:winmate/features/home/home_dashboard.dart'; // <--- NEW IMPORT

// ... inside _MainNavScreenState ...

  final List<Widget> _screens = [
    const HomeDashboard(),   // <--- Tab 0: Real Home Dashboard
    const MiningDashboard(), // Tab 1: Mining Engine
    const InviteScreen(),    // Tab 2: Invite System
    const Center(child: Text("Profile (Coming Phase 6)")), // Tab 3: Profile
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Switch screens
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: "Mining"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Invite"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
