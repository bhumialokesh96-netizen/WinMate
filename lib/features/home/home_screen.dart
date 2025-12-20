import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final SupabaseClient supabase = Supabase.instance.client;
  String userPhone = "Loading...";
  double balance = 0.00;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Get phone number from Supabase
      final phone = user.userMetadata?['phone'] ?? user.phone ?? "User";
      
      // MOCK BALANCE (We will connect real Wallet DB in Phase 6)
      // For now, let's show 0.00 or a mock number
      setState(() {
        userPhone = phone;
        balance = 125.50; // Mock balance to look good
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark Navy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE94560),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome Back,", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(userPhone, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- 1. BALANCE CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE94560), Color(0xFF0F3460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE94560).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Balance", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text("₹${balance.toStringAsFixed(2)}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(Icons.arrow_downward, "Deposit"),
                      _buildActionButton(Icons.arrow_upward, "Withdraw"),
                      _buildActionButton(Icons.history, "History"),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. LIVE MARKET (Mock) ---
            Text("Live Market", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildCoinItem("Bitcoin", "BTC", "\$43,210.50", "+2.5%", Colors.orange),
            _buildCoinItem("Ethereum", "ETH", "\$2,540.00", "+1.2%", Colors.purple),
            _buildCoinItem("WinMate", "WIN", "\$0.05", "+15.0%", const Color(0xFFE94560)), // Our Coin!
            
            const SizedBox(height: 30),

            // --- 3. NEWS BANNER ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.yellow, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Refer & Earn", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("Invite friends and get 10% bonus!", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildCoinItem(String name, String symbol, String price, String change, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(Icons.currency_bitcoin, color: iconColor), // Generic icon for now
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(symbol, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(change, style: GoogleFonts.poppins(color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
