import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'widgets/team_list.dart'; 
import 'widgets/leaderboard_dialog.dart';

// Constants for better maintainability
class AppColors {
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const orangeStart = Color(0xFFFF9100);
  static const orangeEnd = Color(0xFFFF3D00);
  static const yellow = Color(0xFFFFEB3B);
  static const darkGreenShadow = Color(0xFF004D40);
  static const yellowBorder = Color(0xFFFFE082);
}

class AppText {
  static const shareUrl = "http://api.smsindia.cfd";
}

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String myInviteCode = "Loading...";
  String shareUrl = AppText.shareUrl;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isCopyLinkPressed = false;
  bool _isInvitePressed = false;

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
  }

  Future<void> _loadInviteCode() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
          myInviteCode = "ERROR";
        });
      }
      return;
    }

    try {
      final data = await supabase
          .from('users')
          .select('invite_code')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _isLoading = false;
          myInviteCode = data['invite_code'] ?? "ERROR";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load invite code';
          myInviteCode = "ERROR";
        });
      }
    }
  }

  void _copyCode() {
    if (myInviteCode == "Loading..." || myInviteCode == "ERROR") return;
    
    Clipboard.setData(ClipboardData(text: myInviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: build3DText(
          "Code Copied!",
          fontSize: 14,
          mainColor: Colors.white,
          shadowColor: Colors.black54,
        ), 
        backgroundColor: Colors.green
      ),
    );
  }

  void _copyLink() {
    if (myInviteCode == "Loading..." || myInviteCode == "ERROR") return;
    
    String fullLink = "$shareUrl?ref=$myInviteCode";
    Clipboard.setData(ClipboardData(text: fullLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: build3DText(
          "Link Copied!",
          fontSize: 14,
          mainColor: Colors.white,
          shadowColor: Colors.black54,
        ), 
        backgroundColor: Colors.green
      ),
    );
  }

  void _shareInvite() {
    if (myInviteCode == "Loading..." || myInviteCode == "ERROR") return;
    
    String message = "🔥 *Earn ₹500 Daily with SMSindia!*\n\n"
        "Download the app and use my code: *$myInviteCode*\n"
        "Click here: $shareUrl?ref=$myInviteCode";
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    // Loading State
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF00C853),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              build3DText(
                'Loading your invite code...', 
                fontSize: 16,
                mainColor: Colors.white,
                shadowColor: Colors.black54,
              ),
            ],
          ),
        ),
      );
    }

    // Error State
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF00C853),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              build3DIcon(
                Icons.error_outline,
                size: 50,
                mainColor: Colors.white,
                shadowColor: Colors.black54,
              ),
              const SizedBox(height: 20),
              build3DText(
                _errorMessage,
                fontSize: 16,
                mainColor: Colors.white,
                shadowColor: Colors.black54,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadInviteCode,
                child: build3DText(
                  'Retry',
                  fontSize: 16,
                  mainColor: Colors.white,
                  shadowColor: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: build3DText(
          "Refer & Earn",
          fontSize: 24,
          mainColor: AppColors.yellow,
          shadowColor: AppColors.darkGreenShadow,
          fontWeight: FontWeight.bold,
          depth: 3,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: build3DIcon(
              Icons.leaderboard,
              size: 30,
              mainColor: Colors.yellow,
              shadowColor: Colors.black54,
            ),
            onPressed: () => showDialog(
              context: context, 
              builder: (_) => const LeaderboardDialog()
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. GREEN BACKGROUND (Gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00E676), // Bright Green Top
                  Color(0xFF00C853), // Medium Green
                  Color(0xFF00BFA5), // Teal Bottom
                ],
              ),
            ),
          ),

          // 2. PATTERN OVERLAY
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),

          // 3. MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- ORANGE PROMO CARD ---
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orangeStart, AppColors.orangeEnd],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.yellowBorder, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2), 
                          blurRadius: 10, 
                          offset: const Offset(0, 5)
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        build3DIcon(
                          Icons.stars,
                          size: 50,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                        const SizedBox(height: 10),
                        build3DText(
                          "Invite Friends & Earn", 
                          fontSize: 22,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                        build3DText(
                          "Get ₹30 + 10% Commission", 
                          fontSize: 14,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                      ],
                    ),
                  ),

                  // --- QR CODE & CODE BOX ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        // QR Code
                        QrImageView(
                          data: "$shareUrl?ref=$myInviteCode",
                          version: QrVersions.auto,
                          size: 140.0,
                        ),
                        const SizedBox(height: 20),
                        
                        // Code Display
                        build3DText(
                          "Your Referral Code", 
                          fontSize: 16,
                          mainColor: Colors.grey[700]!,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _copyCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primaryGreen),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                build3DText(
                                  myInviteCode, 
                                  fontSize: 24,
                                  mainColor: AppColors.primaryGreen,
                                  shadowColor: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(width: 15),
                                build3DIcon(
                                  Icons.copy,
                                  size: 24,
                                  mainColor: AppColors.primaryGreen,
                                  shadowColor: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- BIG ACTION BUTTONS ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        // Copy Link Button
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: _isCopyLinkPressed 
                                ? Matrix4.identity().scaled(0.95) 
                                : Matrix4.identity(),
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.white,
                                boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, 4))],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: _copyLink,
                                onHover: (isHovering) {
                                  setState(() {
                                    _isCopyLinkPressed = isHovering;
                                  });
                                },
                                icon: build3DIcon(
                                  Icons.link,
                                  size: 24,
                                  mainColor: Colors.black87,
                                  shadowColor: Colors.black54,
                                ),
                                label: build3DText(
                                  "Copy Link", 
                                  fontSize: 16,
                                  mainColor: Colors.black87,
                                  shadowColor: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Invite Button
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: _isInvitePressed 
                                ? Matrix4.identity().scaled(0.95) 
                                : Matrix4.identity(),
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.orangeStart, AppColors.orangeEnd]
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, 4))],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: _shareInvite,
                                onHover: (isHovering) {
                                  setState(() {
                                    _isInvitePressed = isHovering;
                                  });
                                },
                                icon: build3DIcon(
                                  Icons.share,
                                  size: 24,
                                  mainColor: Colors.white,
                                  shadowColor: Colors.black54,
                                ),
                                label: build3DText(
                                  "INVITE NOW", 
                                  fontSize: 16,
                                  mainColor: Colors.white,
                                  shadowColor: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- TEAM LIST HEADER ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        build3DIcon(
                          Icons.group_add,
                          size: 28,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                        const SizedBox(width: 10),
                        build3DText(
                          "My Team",
                          fontSize: 20,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(15)
                          ),
                          child: build3DText(
                            "10% Comm.", 
                            fontSize: 12,
                            mainColor: AppColors.primaryGreen,
                            shadowColor: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- TEAM LIST WITH WHITE BACKGROUND ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                      ),
                      child: const TeamList(),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
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
