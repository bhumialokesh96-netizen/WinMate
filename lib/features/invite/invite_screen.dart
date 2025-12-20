import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
  }

  Future<void> _loadInviteCode() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Fetch invite code from 'users' table
      final data = await supabase.from('users').select('invite_code').eq('id', user.id).single();
      if (mounted) {
        setState(() {
          myInviteCode = data['invite_code'] ?? "ERROR";
        });
      }
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: myInviteCode));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code Copied!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Invite Friends", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.orange),
            onPressed: () {
               showDialog(context: context, builder: (_) => const LeaderboardDialog());
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- INVITE CODE CARD ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE94560), width: 1),
              ),
              child: Column(
                children: [
                  Text("Your Invite Code", style: GoogleFonts.poppins(color: Colors.grey)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94560).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        // FIXED: Changed dashed to solid to fix build error
                        border: Border.all(color: const Color(0xFFE94560), style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            myInviteCode, 
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)
                          ),
                          const SizedBox(width: 15),
                          const Icon(Icons.copy, color: Color(0xFFE94560)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Share this code to earn 10% commission!", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // --- TEAM HEADER ---
            Row(
              children: [
                const Icon(Icons.group, color: Colors.white),
                const SizedBox(width: 10),
                Text("My Team", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            
            // --- TEAM LIST WIDGET ---
            const TeamList(), 
          ],
        ),
      ),
    );
  }
}
