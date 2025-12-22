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
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> history = [];
  double userBalance = 0.0;

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const accentOrange = Color(0xFFFF9100);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserBalance();
    await _loadHistory();
  }

  Future<void> _loadUserBalance() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await supabase
            .from('users')
            .select('balance')
            .eq('id', user.id)
            .single();
        
        if (mounted) {
          setState(() {
            userBalance = (data['balance'] as num).toDouble();
          });
        }
      } catch (e) {
        print("Error loading balance: $e");
      }
    }
  }

  Future<void> _loadHistory() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await supabase
            .from('withdrawals')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        
        if (mounted) {
          setState(() {
            history = List<Map<String, dynamic>>.from(response);
            _isLoadingHistory = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingHistory = false);
        }
      }
    }
  }

  Future<void> _submitWithdrawal() async {
  final amount = double.tryParse(_amountController.text);
  final upi = _upiController.text.trim();
  final user = supabase.auth.currentUser;

  // Validations (keep existing validation code)
  if (amount == null || amount < 100) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: build3DText("Minimum withdrawal is ₹100"),
        backgroundColor: Colors.orange,
      )
    );
    return;
  }

  if (amount > userBalance) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: build3DText("Insufficient funds. Your balance is ₹${userBalance.toStringAsFixed(2)}"),
      )
    );
    return;
  }

  if (upi.isEmpty || !upi.contains('@')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: build3DText("Invalid UPI ID"),
        backgroundColor: Colors.orange,
      )
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    if (user != null) {
      // 1. First update the user's balance
      final newBalance = userBalance - amount;
      await supabase
          .from('users')
          .update({'balance': newBalance})
          .eq('id', user.id);

      // 2. Then create the withdrawal record
      await supabase.from('withdrawals').insert({
        'user_id': user.id,
        'amount': amount,
        'upi_id': upi,
        'status': 'pending'
      });

      // 3. Update local state
      setState(() {
        userBalance = newBalance;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryGreen,
          content: build3DText("Withdrawal Requested Successfully!"),
        )
      );
      
      _amountController.clear();
      _upiController.clear();
      await _loadHistory(); // Refresh list only (balance already updated)
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: build3DText(
          "Error: ${e.toString().contains('Insufficient') ? 'Transaction Failed' : 'Request Failed'}",
        ),
      )
    );
    // Reload balance in case update failed
    await _loadUserBalance();
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryGreen,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00E676),
                  Color(0xFF00C853),
                  Color(0xFF00BFA5),
                ],
              ),
            ),
          ),
          
          // Pattern Overlay
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: build3DIcon(
                          Icons.arrow_back,
                          size: 28,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                      ),
                      Expanded(
                        child: build3DText(
                          "Withdraw Funds",
                          fontSize: 20,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        build3DText(
                          "Available Balance",
                          fontSize: 16,
                          mainColor: Colors.grey[700]!,
                          shadowColor: Colors.black54,
                        ),
                        const SizedBox(height: 10),
                        build3DText(
                          "₹${userBalance.toStringAsFixed(2)}",
                          fontSize: 32,
                          mainColor: primaryGreen,
                          shadowColor: Colors.black,
                          fontWeight: FontWeight.bold,
                          depth: 3,
                        ),
                        const SizedBox(height: 10),
                        build3DText(
                          "Minimum withdrawal: ₹100",
                          fontSize: 12,
                          mainColor: Colors.grey[600]!,
                          shadowColor: Colors.black54,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Input Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        build3DText(
                          "UPI ID",
                          fontSize: 14,
                          mainColor: Colors.grey[700]!,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _upiController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _inputDeco("e.g. user@okicici"),
                        ),
                        const SizedBox(height: 20),
                        
                        build3DText(
                          "Amount (₹)",
                          fontSize: 14,
                          mainColor: Colors.grey[700]!,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _inputDeco("Enter amount (min ₹100)"),
                        ),
                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            onPressed: isLoading ? null : _submitWithdrawal,
                            child: isLoading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : build3DText(
                                    "WITHDRAW NOW",
                                    fontSize: 16,
                                    mainColor: Colors.white,
                                    shadowColor: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Transaction History
                  build3DText(
                    "Transaction History",
                    fontSize: 18,
                    mainColor: Colors.white,
                    shadowColor: Colors.black54,
                    fontWeight: FontWeight.bold,
                    depth: 2,
                  ),
                  const SizedBox(height: 15),

                  _isLoadingHistory
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : history.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                children: [
                                  build3DIcon(
                                    Icons.history,
                                    size: 50,
                                    mainColor: Colors.white54,
                                    shadowColor: Colors.black54,
                                  ),
                                  const SizedBox(height: 10),
                                  build3DText(
                                    "No withdrawal history",
                                    fontSize: 14,
                                    mainColor: Colors.white54,
                                    shadowColor: Colors.black54,
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: history.map((item) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(item['status']).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: build3DIcon(
                                      _getStatusIcon(item['status']),
                                      size: 20,
                                      mainColor: _getStatusColor(item['status']),
                                      shadowColor: Colors.black54,
                                    ),
                                  ),
                                  title: build3DText(
                                    "₹${item['amount']}",
                                    fontSize: 16,
                                    mainColor: Colors.black87,
                                    shadowColor: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  subtitle: build3DText(
                                    item['upi_id'],
                                    fontSize: 12,
                                    mainColor: Colors.grey[600]!,
                                    shadowColor: Colors.black54,
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(item['status']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: build3DText(
                                      item['status'].toString().toUpperCase(),
                                      fontSize: 10,
                                      mainColor: _getStatusColor(item['status']),
                                      shadowColor: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return primaryGreen;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.access_time;
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.help_outline;
    }
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
