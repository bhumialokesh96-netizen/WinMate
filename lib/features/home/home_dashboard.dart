import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final SupabaseClient supabase = Supabase.instance.client;
  String userPhone = "Loading...";
  double balance = 125.50; // Mock balance

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final phone = user.userMetadata?['phone'] ?? user.phone ?? "User";
      if (mounted) {
        setState(() {
          userPhone = phone;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome Back,", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            Text(userPhone, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Total Balance", style: GoogleFonts.poppins(color: Colors.white70)),
            Text("₹${balance.toStringAsFixed(2)}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: [
                   Column(children: [Icon(Icons.arrow_downward, color: Colors.green), Text("Deposit", style: TextStyle(color: Colors.white))]),
                   Column(children: [Icon(Icons.arrow_upward, color: Colors.red), Text("Withdraw", style: TextStyle(color: Colors.white))]),
                 ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
