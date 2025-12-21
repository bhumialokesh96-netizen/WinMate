import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/features/auth/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();

  // 0 = Enter Email, 1 = Enter OTP, 2 = Enter New Password
  int _currentStep = 0; 
  bool _isLoading = false;

  // --- STEP 1: SEND CODE ---
  Future<void> _sendCode() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
      setState(() {
        _isLoading = false;
        _currentStep = 1; // Move to Next Step
      });
      _showMessage("Code sent! Check your email.", Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Error: ${e.toString().split('\n')[0]}", Colors.red);
    }
  }

  // --- STEP 2: VERIFY CODE ---
  Future<void> _verifyCode() async {
    if (_otpController.text.length != 6) return;
    setState(() => _isLoading = true);

    try {
      // 'recovery' type is specific for Password Reset
      final res = await supabase.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
        type: OtpType.recovery, 
      );

      if (res.session != null) {
        setState(() {
          _isLoading = false;
          _currentStep = 2; // Move to Final Step
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Invalid Code", Colors.red);
    }
  }

  // --- STEP 3: SAVE NEW PASSWORD ---
  Future<void> _updatePassword() async {
    if (_newPassController.text.length < 6) {
      _showMessage("Password must be at least 6 characters", Colors.red);
      return;
    }
    setState(() => _isLoading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _newPassController.text.trim()),
      );
      
      if (mounted) {
        _showMessage("Password Updated! Please Login.", Colors.green);
        // Go back to Login Screen
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Update Failed: ${e.toString()}", Colors.red);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, color: Color(0xFFE94560), size: 60),
            const SizedBox(height: 20),
            
            // Dynamic Title
            Text(
              _currentStep == 0 ? "Reset Password" : (_currentStep == 1 ? "Enter Code" : "New Password"),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // --- UI CHANGES BASED ON STEP ---
            if (_currentStep == 0) ...[
              _buildTextField(_emailController, "Enter your Email", Icons.email, false),
              const SizedBox(height: 20),
              _buildButton("SEND CODE", _sendCode),
            ],

            if (_currentStep == 1) ...[
              Text("Sent to ${_emailController.text}", style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 20),
              _buildTextField(_otpController, "6-Digit Code", Icons.numbers, false, isNumber: true),
              const SizedBox(height: 20),
              _buildButton("VERIFY CODE", _verifyCode),
            ],

            if (_currentStep == 2) ...[
              _buildTextField(_newPassController, "Enter New Password", Icons.lock, true),
              const SizedBox(height: 20),
              _buildButton("SAVE PASSWORD", _updatePassword),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPass, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: isNumber ? 6 : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        counterText: "",
        prefixIcon: Icon(icon, color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF16213E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
