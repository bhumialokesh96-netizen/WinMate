import 'package:flutter/material.dart';
import 'package:winmate/features/home/home_dashboard.dart';
import 'package:winmate/features/mining/mining_dashboard.dart';
import 'package:winmate/features/invite/invite_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  // --- THIS VARIABLE WAS MISSING BEFORE ---
  int _selectedIndex = 0;

  // --- THE SCREENS LIST ---
  final List<Widget> _screens = [
    const HomeDashboard(),   // Index 0
    const MiningDashboard(), // Index 1
    const InviteScreen(),    // Index 2
    const Center(child: Text("Profile (Coming Phase 6)", style: TextStyle(color: Colors.white))), // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: _screens[_selectedIndex], // Now this will work
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF16213E),
        currentIndex: _selectedIndex, // Now this will work
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Now this will work
          });
        },
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
