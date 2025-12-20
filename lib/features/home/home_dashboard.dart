import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/features/wallet/withdraw_screen.dart'; // Ensure path is correct
import 'package:winmate/features/wallet/history_screen.dart';   // Ensure path is correct

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final SupabaseClient supabase = Supabase.instance.client;
  String userPhone = "Loading...";
  double balance = 0.00;
  int totalSms = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        // 1. Get Phone / Name
        // We try to get the phone, if null we use Email or "Miner"
        final phone = user.userMetadata?['phone'] ?? user.email ?? "Miner";

        // 2. Get Wallet Balance from DB
        // CHANGE 'wallet' -> 'users' AND 'user_id' -> 'id'
final walletData = await supabase
    .from('users')
    .select('balance, total_sms_sent') // Make sure your column name is exactly total_sms_sent
    .eq('id', user.id)
    .single();


        if (mounted) {
          setState(() {
            userPhone = phone;
            balance = (walletData['balance'] as num).toDouble();
            // If total_sms_sent is null, default to 0
            totalSms = (walletData['total_sms_sent'] ?? 0) as int;
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error loading wallet: $e");
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome,", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            Text(userPhone, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadRealData, 
            icon: const Icon(Icons.refresh, color: Colors.white)
          )
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- BALANCE CARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
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
                      children: [
                        Text("Current Balance", style: GoogleFonts.poppins(color: Colors.white70)),
                        const SizedBox(height: 5),
                        Text("₹${balance.toStringAsFixed(2)}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                          child: Text("Total SMS Sent: $totalSms", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // --- ACTIONS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // DEPOSIT
                      _buildActionBtn(Icons.add, "Deposit", () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please contact Admin to Deposit funds."))
                        );
                      }),
                      
                      // WITHDRAW
                      _buildActionBtn(Icons.download, "Withdraw", () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen()));
                      }),

                      // HISTORY
                      _buildActionBtn(Icons.history, "History", () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                      }),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // UPDATED WIDGET: Now accepts an 'onTap' function
  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF16213E), 
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
              ]
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))
        ],
      ),
    );
  }
}
