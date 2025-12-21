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
  final SupabaseClient supabase = Supabase.instance.client;
  String myInviteCode = "Loading...";
  String shareUrl = "http://api.smsindia.cfd";

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
      const SnackBar(content: Text("Code Copied! Paste it to friends."), backgroundColor: Colors.green),
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
    
    // The Professional Share Message
    String message = "🔥 *Earn ₹500 Daily with WinMate!*\n\n"
        "Download the app and use my code: *$myInviteCode*\n"
        "Click here: $shareUrl?ref=$myInviteCode";
        
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Refer & Earn", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.orange),
            onPressed: () => showDialog(context: context, builder: (_) => const LeaderboardDialog()),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. GAMIFIED HEADER CARD ---
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFF3D00)], // Orange Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  Text("Invite Friends & Earn", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("Get ₹30 + 10% Commission", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),

            // --- 2. QR CODE & CODE BOX ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE94560), width: 1),
              ),
              child: Column(
                children: [
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: QrImageView(
                      data: "$shareUrl?ref=$myInviteCode",
                      version: QrVersions.auto,
                      size: 140.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Code Display
                  Text("Your Referral Code", style: GoogleFonts.poppins(color: Colors.grey)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            myInviteCode, 
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)
                          ),
                          const SizedBox(width: 15),
                          const Icon(Icons.copy, color: Color(0xFFE94560)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- 3. BIG ACTION BUTTONS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _copyLink,
                      icon: const Icon(Icons.link, color: Colors.white),
                      label: const Text("Copy Link", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // WhatsApp style
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _shareInvite,
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text("INVITE NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 4. TEAM LIST HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                children: [
                  const Icon(Icons.group_add, color: Color(0xFFE94560)),
                  const SizedBox(width: 10),
                  Text("My Team", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  Text("10% Commission", style: GoogleFonts.poppins(fontSize: 12, color: Colors.greenAccent)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- 5. YOUR TEAM LIST WIDGET ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TeamList(),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
