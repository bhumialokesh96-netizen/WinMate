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
  bool _obscurePassword = true;

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const accentOrange = Color(0xFFFF9100);

  // --- STEP 1: SEND CODE ---
  Future<void> _sendCode() async {
    if (_emailController.text.isEmpty) {
      _showMessage("Please enter your email address", Colors.orange);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await supabase.auth.resetPasswordForEmail(_emailController.text.trim());
      setState(() {
        _isLoading = false;
        _currentStep = 1; // Move to Next Step
      });
      _showMessage("Verification code sent! Check your email.", primaryGreen);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Error: ${e.toString().split('\n')[0]}", Colors.red);
    }
  }

  // --- STEP 2: VERIFY CODE ---
  Future<void> _verifyCode() async {
    if (_otpController.text.length != 6) {
      _showMessage("Please enter the 6-digit code", Colors.orange);
      return;
    }
    
    setState(() => _isLoading = true);

    try {
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
      _showMessage("Invalid verification code", Colors.red);
    }
  }

  // --- STEP 3: SAVE NEW PASSWORD ---
  Future<void> _updatePassword() async {
    if (_newPassController.text.length < 6) {
      _showMessage("Password must be at least 6 characters", Colors.orange);
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _newPassController.text.trim()),
      );
      
      if (mounted) {
        _showMessage("Password updated successfully!", primaryGreen);
        // Go back to Login Screen
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Update failed: ${e.toString().split('\n')[0]}", Colors.red);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: build3DText(
          msg,
          fontSize: 14,
          mainColor: Colors.white,
          shadowColor: Colors.black54,
        ), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryGreen,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00E676),
                  Color(0xFF00C853),
                  Color(0xFF00BFA5),
                ],
              ),
            ),
          ),
          
          // Pattern Overlay
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // App Bar with Back Button
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: build3DIcon(
                          Icons.arrow_back,
                          size: 28,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                      ),
                      Expanded(
                        child: build3DText(
                          "Reset Password",
                          fontSize: 20,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button space
                    ],
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: build3DIcon(
                              Icons.lock_reset,
                              size: 50,
                              mainColor: primaryGreen,
                              shadowColor: Colors.black54,
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Dynamic Title
                          build3DText(
                            _currentStep == 0 
                                ? "Reset Password" 
                                : _currentStep == 1 
                                    ? "Enter Verification Code" 
                                    : "Create New Password",
                            fontSize: 24,
                            mainColor: Colors.white,
                            shadowColor: Colors.black54,
                            fontWeight: FontWeight.bold,
                            depth: 3,
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Subtitle
                          build3DText(
                            _currentStep == 0 
                                ? "Enter your email to receive a verification code"
                                : _currentStep == 1 
                                    ? "Enter the 6-digit code sent to your email"
                                    : "Create a strong new password for your account",
                            fontSize: 14,
                            mainColor: Colors.white.withOpacity(0.9),
                            shadowColor: Colors.black54,
                          ),
                          
                          const SizedBox(height: 40),

                          // --- STEP 0: EMAIL INPUT ---
                          if (_currentStep == 0) ...[
                            _buildTextField(
                              _emailController, 
                              "Email Address", 
                              Icons.email, 
                              TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 30),
                            _buildButton("SEND VERIFICATION CODE", _sendCode),
                          ],

                          // --- STEP 1: OTP INPUT ---
                          if (_currentStep == 1) ...[
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: build3DText(
                                "Sent to: ${_emailController.text}",
                                fontSize: 14,
                                mainColor: Colors.white,
                                shadowColor: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              _otpController, 
                              "6-Digit Code", 
                              Icons.numbers, 
                              TextInputType.number,
                              isOtp: true,
                            ),
                            const SizedBox(height: 30),
                            _buildButton("VERIFY CODE", _verifyCode),
                          ],

                          // --- STEP 2: NEW PASSWORD ---
                          if (_currentStep == 2) ...[
                            _buildTextField(
                              _newPassController, 
                              "New Password", 
                              Icons.lock, 
                              TextInputType.text,
                              isPassword: true,
                            ),
                            const SizedBox(height: 30),
                            _buildButton("SAVE NEW PASSWORD", _updatePassword),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // Progress Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: index <= _currentStep 
                                      ? Colors.white 
                                      : Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, 
    IconData icon, 
    TextInputType type, {
    bool isPassword = false,
    bool isOtp = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: type,
      maxLength: isOtp ? 6 : null,
      style: const TextStyle(color: Colors.black87),
      textAlign: isOtp ? TextAlign.center : TextAlign.left,
      decoration: InputDecoration(
        prefixIcon: isOtp ? null : build3DIcon(
          icon,
          size: 20,
          mainColor: Colors.grey,
          shadowColor: Colors.black54,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: build3DIcon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  mainColor: Colors.grey,
                  shadowColor: Colors.black54,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              )
            : null,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        counterText: isOtp ? "" : null,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          shadowColor: accentOrange.withOpacity(0.5),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : build3DText(
                text,
                fontSize: 16,
                mainColor: Colors.white,
                shadowColor: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
      ),
    );
  }

  // 3D Text Widget
  Widget build3DText(
    String text, {
    double fontSize = 18,
    Color mainColor = Colors.white,
    Color shadowColor = const Color(0xFF004D40),
    double depth = 2,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return Stack(
      children: [
        // Shadow text
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: shadowColor,
          ),
        ),

        // Front text
        Transform.translate(
          offset: Offset(0, -depth),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: mainColor,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3D Icon Widget
  Widget build3DIcon(
    IconData icon, {
    double size = 24,
    Color mainColor = Colors.white,
    Color shadowColor = Colors.black54,
    double depth = 1,
  }) {
    return Stack(
      children: [
        // Shadow icon
        Icon(
          icon,
          size: size,
          color: shadowColor,
        ),
        
        // Front icon
        Transform.translate(
          offset: Offset(0, -depth),
          child: Icon(
            icon,
            size: size,
            color: mainColor,
          ),
        ),
      ],
    );
  }
}
