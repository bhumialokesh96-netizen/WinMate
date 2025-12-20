import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'withdraw_screen.dart'; // <--- Links to your existing file

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  double balance = 0.00;
  bool isLoading = true;
  List<dynamic> recentEarnings = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  // Fetch Balance & Recent SMS Income
  Future<void> _fetchWalletData() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        // 1. Get Balance
        // CHANGE 'wallet' -> 'users' AND 'user_id' -> 'id'
final walletData = await supabase
    .from('users')
    .select('balance')
    .eq('id', user.id)
    .single();

            
        // 2. Get Recent Successful SMS Earnings
        // We fetch the last 5 sent SMS tasks to show as "Income"
        final taskData = await supabase
            .from('sms_tasks')
            .select()
            .eq('user_id', user.id)
            .eq('status', 'sent')
            .order('created_at', ascending: false)
            .limit(5);

        if (mounted) {
          setState(() {
            balance = (walletData['balance'] as num).toDouble();
            recentEarnings = taskData;
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error loading wallet: $e");
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("My Wallet", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchWalletData,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        color: const Color(0xFFE94560),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BALANCE CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE94560), Color(0xFFC0394D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE94560).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Balance", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 5),
                    isLoading 
                      ? const SizedBox(height: 30, width: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          "₹${balance.toStringAsFixed(2)}", 
                          style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        Text("Secure Payments", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- BUTTONS ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      // LINK TO YOUR WITHDRAW SCREEN
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen()));
                      },
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      label: Text("Withdraw", style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16213E),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- INCOME HISTORY ---
              Text("Recent Income", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              if (recentEarnings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text("No income yet. Start Mining!", style: GoogleFonts.poppins(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentEarnings.length,
                  itemBuilder: (context, index) {
                    final item = recentEarnings[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("SMS Revenue", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text("Task ID: ${item['id'].toString().substring(0,4)}...", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          Text("+₹2.00", style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
