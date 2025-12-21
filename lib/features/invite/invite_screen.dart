import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'widgets/team_list.dart'; 
import 'widgets/leaderboard_dialog.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  // --- LOGIC STARTS HERE (UNCHANGED) ---
  final SupabaseClient supabase = Supabase.instance.client;
  String myInviteCode = "Loading...";
  String shareUrl = "http://api.winmate.cfd";

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
  }

  Future<void> _loadInviteCode() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await supabase.from('users').select('invite_code').eq('id', user.id).single();
        if (mounted) {
          setState(() {
            myInviteCode = data['invite_code'] ?? "ERROR";
          });
        }
      } catch (e) {
        setState(() => myInviteCode = "ERROR");
      }
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: myInviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Code Copied!"), backgroundColor: Colors.green),
    );
  }

  void _copyLink() {
    String fullLink = "$shareUrl?ref=$myInviteCode";
    Clipboard.setData(ClipboardData(text: fullLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Link Copied!"), backgroundColor: Colors.green),
    );
  }

  void _shareInvite() {
    if (myInviteCode == "Loading..." || myInviteCode == "ERROR") return;
    String message = "🔥 *Earn ₹500 Daily with WinMate!*\n\n"
        "Download the app and use my code: *$myInviteCode*\n"
        "Click here: $shareUrl?ref=$myInviteCode";
    Share.share(message);
  }
  // --- LOGIC ENDS HERE ---

  // --- NEW GREEN UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No background color here because we use a container below
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: _build3DTitle("Refer & Earn"), // Custom 3D Text
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.yellow, size: 30),
            onPressed: () => showDialog(context: context, builder: (_) => const LeaderboardDialog()),
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

          // 2. PATTERN OVERLAY (Optional - Hexagons)
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
                        colors: [Color(0xFFFF9100), Color(0xFFFF3D00)], // Orange Gradient
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFE082), width: 2), // Yellow Border
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.stars, size: 50, color: Colors.white),
                        const SizedBox(height: 10),
                        Text("Invite Friends & Earn", 
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, shadows: [const Shadow(color: Colors.black26, blurRadius: 4)])
                        ),
                        Text("Get ₹30 + 10% Commission", 
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)
                        ),
                      ],
                    ),
                  ),

                  // --- QR CODE & CODE BOX (White Background like screenshot) ---
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95), // Slightly transparent white
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
                        Text("Your Referral Code", style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _copyCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9), // Very light green
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF00C853)), // Green Border
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  myInviteCode, 
                                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF00C853), letterSpacing: 3)
                                ),
                                const SizedBox(width: 15),
                                const Icon(Icons.copy, color: Color(0xFF00C853)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- BIG ACTION BUTTONS (3D Style) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        // Copy Link Button
                        Expanded(
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
                              icon: const Icon(Icons.link, color: Colors.black87),
                              label: const Text("Copy Link", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Invite Button (Orange 3D)
                        Expanded(
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFF3D00)]),
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
                              icon: const Icon(Icons.share, color: Colors.white),
                              label: const Text("INVITE NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.group_add, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        // Using the 3D Text Helper
                        _build3DTitle("My Team"),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                          child: Text("10% Comm.", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF00C853))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- TEAM LIST (Pass a color parameter if your TeamList supports it, otherwise it will just sit on green) ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TeamList(),
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

  // --- HELPER: 3D TEXT STYLE ---
  Widget _build3DTitle(String text) {
    return Stack(
      children: [
        // Shadow
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF004D40), // Dark Green Shadow
          ),
        ),
        // Main Text
        Transform.translate(
          offset: const Offset(0, -2),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFEB3B), // Yellow
              shadows: [const Shadow(color: Colors.black12, blurRadius: 2)]
            ),
          ),
        ),
      ],
    );
  }
}
