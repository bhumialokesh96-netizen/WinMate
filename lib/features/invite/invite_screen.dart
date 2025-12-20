import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String myReferralCode = "Loading...";
  List<Map<String, dynamic>> myTeam = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // 1. Get my phone number to use as referral code
      final String phone = user.userMetadata?['phone'] ?? user.phone ?? "Unknown";
      
      // 2. Mock Data for now (Real DB connection in next step)
      // In real app: await supabase.from('profiles').select().eq('referred_by', user.id);
      final List<Map<String, dynamic>> mockTeam = [
        {'phone': '+91 9876543210', 'date': 'Today', 'status': 'Active'},
        {'phone': '+91 8888888888', 'date': 'Yesterday', 'status': 'Inactive'},
      ];

      setState(() {
        myReferralCode = phone.replaceAll('+', ''); // Remove + for cleaner code
        myTeam = mockTeam;
        isLoading = false;
      });
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: myReferralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral Code Copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark Navy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Invite Friends", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- HEADER CARD ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE94560), Color(0xFF0F3460)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rocket_launch, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    "Invite & Earn ₹50",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Get 10% of their mining forever!",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- CODE BOX ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("YOUR CODE", style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
                            Text(
                              myReferralCode,
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _copyCode,
                          icon: const Icon(Icons.copy, color: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // --- MY TEAM TITLE ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text("My Team (${myTeam.length})", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),

            // --- TEAM LIST ---
            Expanded(
              child: ListView.builder(
                itemCount: myTeam.length,
                itemBuilder: (context, index) {
                  final member = myTeam[index];
                  return Card(
                    color: const Color(0xFF16213E),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE94560),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(member['phone'], style: GoogleFonts.poppins(color: Colors.white)),
                      subtitle: Text("Joined: ${member['date']}", style: GoogleFonts.poppins(color: Colors.grey)),
                      trailing: Text(
                        member['status'],
                        style: GoogleFonts.poppins(
                          color: member['status'] == 'Active' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
