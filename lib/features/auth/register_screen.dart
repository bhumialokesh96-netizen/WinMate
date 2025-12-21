import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/features/dashboard/main_nav_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _phoneController = TextEditingController(); // Only Phone needed
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  bool isLoading = false;

  Future<void> _signUp() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final referral = _referralController.text.trim();

    // TRICK: Create a fake email using the phone number
    final fakeEmail = "$phone@winmate.com"; 

    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: fakeEmail,
        password: password,
        data: {
          'phone': phone, // This goes to the SQL Trigger
          'referred_by': referral.isNotEmpty ? referral : null,
        },
      );

      if (res.user != null) {
        if (mounted) {
           Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const MainNavScreen())
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString().split('\n')[0]}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch, color: Color(0xFFE94560), size: 60),
              const SizedBox(height: 20),
              Text("Create Account", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // PHONE (User sees this)
              _buildTextField(_phoneController, "Phone Number", Icons.phone, TextInputType.phone),
              const SizedBox(height: 15),

              // PASSWORD
              _buildTextField(_passwordController, "Password", Icons.lock, TextInputType.text, isPassword: true),
              const SizedBox(height: 15),

              // REFERRAL
              _buildTextField(_referralController, "Referral Code (Optional)", Icons.group_add, TextInputType.text),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
                  onPressed: isLoading ? null : _signUp,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("REGISTER", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, TextInputType type, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
