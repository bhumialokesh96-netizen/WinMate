import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/features/auth/login_screen.dart'; // Updated path
import 'package:winmate/features/dashboard/main_nav_screen.dart'; // Updated path

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // 1. Wait 2 seconds (for branding effect)
    await Future.delayed(const Duration(seconds: 2));

    // 2. Check if user is logged in
    final session = Supabase.instance.client.auth.currentSession;

    if (mounted) {
      if (session != null) {
        // Logged In -> Go to Dashboard
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const MainNavScreen())
        );
      } else {
        // Not Logged In -> Go to Login
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const LoginScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark Navy
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF16213E),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94560).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]
              ),
              child: const Icon(Icons.bolt, size: 60, color: Color(0xFFE94560)),
            ),
            const SizedBox(height: 30),
            
            // App Name
            Text(
              "WinMate",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Mining Future Wealth",
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
            ),
            
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Color(0xFFE94560)),
          ],
        ),
      ),
    );
  }
}
