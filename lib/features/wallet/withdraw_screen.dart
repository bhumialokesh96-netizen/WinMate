import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  bool isLoading = false;
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('withdrawals')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      setState(() {
        history = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _submitWithdrawal() async {
    final amount = double.tryParse(_amountController.text);
    final upi = _upiController.text.trim();

    if (amount == null || amount < 100) { // Minimum limit ₹100
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimum withdrawal is ₹100")));
      return;
    }
    if (upi.isEmpty || !upi.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid UPI ID")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('withdrawals').insert({
          'user_id': user.id,
          'amount': amount,
          'upi_id': upi,
          'status': 'pending'
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Withdrawal Requested!")));
        _amountController.clear();
        _upiController.clear();
        _loadHistory(); // Refresh list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Error: ${e.toString().contains('Insufficient') ? 'Insufficient Funds' : 'Request Failed'}")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Withdraw Funds", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INPUT FORM ---
            Text("UPI ID", style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 5),
            TextField(
              controller: _upiController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco("e.g. user@okicici"),
            ),
            const SizedBox(height: 15),
            
            Text("Amount (₹)", style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 5),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco("Min ₹100"),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLoading ? null : _submitWithdrawal,
                child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text("WITHDRAW NOW", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 40),
            Text("Transaction History", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // --- HISTORY LIST ---
            ...history.map((item) => Card(
              color: const Color(0xFF16213E),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  item['status'] == 'pending' ? Icons.access_time : (item['status'] == 'approved' ? Icons.check_circle : Icons.cancel),
                  color: item['status'] == 'pending' ? Colors.orange : (item['status'] == 'approved' ? Colors.green : Colors.red),
                ),
                title: Text("₹${item['amount']}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(item['upi_id'], style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                trailing: Text(
                  item['status'].toString().toUpperCase(), 
                  style: GoogleFonts.poppins(
                    color: item['status'] == 'pending' ? Colors.orange : (item['status'] == 'approved' ? Colors.green : Colors.red), 
                    fontSize: 10, fontWeight: FontWeight.bold
                  )
                ),
              ),
            )).toList()
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF16213E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}
