import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> allTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchAllHistory();
  }

  Future<void> _fetchAllHistory() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch Income (SMS Tasks)
      final incomeData = await supabase
          .from('sms_tasks')
          .select('created_at, status') // In real app, store amount in DB. Here we assume ₹2.00
          .eq('user_id', user.id)
          .eq('status', 'sent');

      // 2. Fetch Withdrawals
      final withdrawData = await supabase
          .from('withdrawals')
          .select('created_at, amount, status')
          .eq('user_id', user.id);

      // 3. Merge Lists
      List<Map<String, dynamic>> merged = [];

      // Process Income
      for (var item in incomeData) {
        merged.add({
          'type': 'income',
          'title': 'SMS Revenue',
          'amount': 2.00, // Fixed rate per SMS
          'date': DateTime.parse(item['created_at']),
          'status': 'success',
        });
      }

      // Process Withdrawals
      for (var item in withdrawData) {
        merged.add({
          'type': 'withdraw',
          'title': 'Withdrawal',
          'amount': (item['amount'] as num).toDouble(),
          'date': DateTime.parse(item['created_at']),
          'status': item['status'],
        });
      }

      // 4. Sort by Date (Newest First)
      merged.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          allTransactions = merged;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Transaction History", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
          : allTransactions.isEmpty
              ? Center(child: Text("No transactions yet.", style: GoogleFonts.poppins(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: allTransactions.length,
                  itemBuilder: (context, index) {
                    final item = allTransactions[index];
                    final isIncome = item['type'] == 'income';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Icon Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 15),
                          
                          // Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(
                                  item['date'].toString().substring(0, 16), // Simple date format
                                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11)
                                ),
                              ],
                            ),
                          ),

                          // Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isIncome ? '+' : '-'}₹${item['amount'].toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  color: isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                item['status'].toString().toUpperCase(),
                                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
