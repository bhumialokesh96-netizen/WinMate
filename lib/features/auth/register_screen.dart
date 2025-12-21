import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/features/auth/login_screen.dart';
import 'package:winmate/features/dashboard/main_nav_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  // 1. Set Default Company Code here
  final _referralController = TextEditingController(text: "666666"); 
  
  bool isLoading = false;

  Future<void> _signUp() async {
    // 2. Added check for Referral Controller and Phone
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _phoneController.text.isEmpty ||
        _referralController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields including Referral Code are required!"), 
          backgroundColor: Colors.red
        )
      );
      return;
    }

    setState(() => isLoading = true);
    
    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'phone': _phoneController.text.trim(),
          'referred_by': _referralController.text.trim(), // Sends 666666 or user code
        },
      );

      if (mounted) {
        setState(() => isLoading = false);
        _showOtpDialog(_emailController.text.trim());
      }

    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString().split('\n')[0]}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- OTP DIALOG ---
  void _showOtpDialog(String email) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text("Verify Email", style: GoogleFonts.poppins(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter the 6-digit code sent to\n$email", style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 5),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            onPressed: () async {
              try {
                final res = await supabase.auth.verifyOTP(
                  type: OtpType.signup,
                  token: otpController.text.trim(),
                  email: email,
                );
                
                if (res.session != null && context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));
                }
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Code"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Verify", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

              _buildTextField(_phoneController, "Phone Number", Icons.phone, TextInputType.phone),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email Address", Icons.email, TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Password", Icons.lock, TextInputType.text, isPassword: true),
              const SizedBox(height: 15),
              // 3. Updated Label (Removed 'Optional')
              _buildTextField(_referralController, "Referral Code", Icons.group_add, TextInputType.text),
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => const LoginScreen())
                  );
                },
                child: Text("Already have an account? Login", style: GoogleFonts.poppins(color: Colors.white70)),
              )
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
