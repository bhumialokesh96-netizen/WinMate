import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:SMSindia/features/auth/login_screen.dart';
import 'package:SMSindia/features/dashboard/main_nav_screen.dart';

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
  final _referralController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const accentOrange = Color(0xFFFF9100);

  // Helper: Generate Random Invite Code (e.g., "WM8291")
  String _generateRandomInviteCode() {
    var r = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return 'WM' + List.generate(4, (index) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _phoneController.text.isEmpty ||
        _referralController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: build3DText(
            "All fields including Referral Code are required!",
            fontSize: 14,
            mainColor: Colors.white,
            shadowColor: Colors.black54,
          ), 
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    
    try {
      // Generate a unique invite code for this user
      String inviteCode = _generateRandomInviteCode();
      
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'phone': _phoneController.text.trim(),
          'referred_by': _referralController.text.trim(),
          'invite_code': inviteCode,
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
          SnackBar(
            content: build3DText(
              "Error: ${e.toString().split('\n')[0]}",
              fontSize: 14,
              mainColor: Colors.white,
              shadowColor: Colors.black54,
            ), 
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOtpDialog(String email) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: build3DText(
          "Verify Email",
          fontSize: 20,
          mainColor: primaryGreen,
          shadowColor: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            build3DText(
              "Enter the 6-digit code sent to\n$email",
              fontSize: 16,
              mainColor: Colors.grey[700]!,
              shadowColor: Colors.black54,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.black87, fontSize: 24, letterSpacing: 5),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: build3DText(
              "Cancel",
              fontSize: 16,
              mainColor: Colors.grey,
              shadowColor: Colors.black54,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: build3DText(
                      "Invalid verification code",
                      fontSize: 14,
                      mainColor: Colors.white,
                      shadowColor: Colors.black54,
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: build3DText(
              "Verify",
              fontSize: 16,
              mainColor: Colors.white,
              shadowColor: Colors.black54,
            ),
          ),
        ],
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // App Icon
                    Container(
                      width: 120,
                      height: 120,
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
                        Icons.rocket_launch,
                        size: 60,
                        mainColor: primaryGreen,
                        shadowColor: Colors.black54,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    build3DText(
                      "Create Account",
                      fontSize: 28,
                      mainColor: Colors.white,
                      shadowColor: Colors.black54,
                      fontWeight: FontWeight.bold,
                      depth: 3,
                    ),
                    
                    const SizedBox(height: 5),
                    
                    build3DText(
                      "Start your journey with us!",
                      fontSize: 16,
                      mainColor: Colors.white.withOpacity(0.9),
                      shadowColor: Colors.black54,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Phone Field
                    _buildTextField(
                      _phoneController,
                      "Phone Number",
                      Icons.phone,
                      TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Email Field
                    _buildTextField(
                      _emailController,
                      "Email Address",
                      Icons.email,
                      TextInputType.emailAddress,
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Password Field
                    _buildTextField(
                      _passwordController,
                      "Password",
                      Icons.lock,
                      TextInputType.text,
                      isPassword: true,
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Referral Code Field
                    _buildTextField(
                      _referralController,
                      "Referral Code",
                      Icons.group_add,
                      TextInputType.text,
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                          shadowColor: accentOrange.withOpacity(0.5),
                        ),
                        onPressed: isLoading ? null : _signUp,
                        child: isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : build3DText(
                                "REGISTER",
                                fontSize: 16,
                                mainColor: Colors.white,
                                shadowColor: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        build3DText(
                          "Already have an account? ",
                          fontSize: 14,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context, 
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: build3DText(
                            "Login",
                            fontSize: 14,
                            mainColor: Colors.white,
                            shadowColor: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: type,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: build3DIcon(
          icon,
          size: 20,
          mainColor: Colors.grey,
          shadowColor: Colors.black54,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
