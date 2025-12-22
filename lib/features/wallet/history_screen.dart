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
  bool _isRefreshing = false;
  List<Map<String, dynamic>> allTransactions = [];

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const accentOrange = Color(0xFFFF9100);

  @override
  void initState() {
    super.initState();
    _fetchAllHistory();
  }

  Future<void> _fetchAllHistory() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // 1. Fetch Income (SMS Tasks)
      final incomeData = await supabase
          .from('sms_tasks')
          .select('created_at, status')
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
          'icon': Icons.arrow_downward,
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
          'icon': Icons.arrow_upward,
        });
      }

      // 4. Sort by Date (Newest First)
      merged.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          allTransactions = merged;
          isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
      case 'approved':
        return primaryGreen;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
            child: Column(
              children: [
                // App Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
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
                          "Transaction History",
                          fontSize: 20,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _isRefreshing = true);
                          _fetchAllHistory();
                        },
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : build3DIcon(
                                Icons.refresh,
                                size: 28,
                                mainColor: Colors.white,
                                shadowColor: Colors.black54,
                              ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: Colors.white),
                              const SizedBox(height: 20),
                              build3DText(
                                "Loading transactions...",
                                fontSize: 16,
                                mainColor: Colors.white,
                                shadowColor: Colors.black54,
                              ),
                            ],
                          ),
                        )
                      : allTransactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  build3DIcon(
                                    Icons.history,
                                    size: 64,
                                    mainColor: Colors.white54,
                                    shadowColor: Colors.black54,
                                  ),
                                  const SizedBox(height: 20),
                                  build3DText(
                                    "No transactions yet",
                                    fontSize: 18,
                                    mainColor: Colors.white54,
                                    shadowColor: Colors.black54,
                                  ),
                                  const SizedBox(height: 10),
                                  build3DText(
                                    "Your transaction history will appear here",
                                    fontSize: 14,
                                    mainColor: Colors.white38,
                                    shadowColor: Colors.black54,
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(20),
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: allTransactions.length,
                                  itemBuilder: (context, index) {
                                    final item = allTransactions[index];
                                    final isIncome = item['type'] == 'income';
                                    final statusColor = _getStatusColor(item['status']);
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.grey[100]!,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Icon Box
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isIncome 
                                                  ? primaryGreen.withOpacity(0.1)
                                                  : Colors.orange.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: build3DIcon(
                                              item['icon'],
                                              size: 22,
                                              mainColor: isIncome ? primaryGreen : Colors.orange,
                                              shadowColor: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          
                                          // Text Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                build3DText(
                                                  item['title'],
                                                  fontSize: 16,
                                                  mainColor: Colors.black87,
                                                  shadowColor: Colors.black54,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                const SizedBox(height: 4),
                                                build3DText(
                                                  _formatDate(item['date']),
                                                  fontSize: 12,
                                                  mainColor: Colors.grey[600]!,
                                                  shadowColor: Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Amount and Status
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              build3DText(
                                                "${isIncome ? '+' : '-'}₹${item['amount'].toStringAsFixed(2)}",
                                                fontSize: 16,
                                                mainColor: isIncome ? primaryGreen : Colors.orange,
                                                shadowColor: Colors.black54,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: build3DText(
                                                  item['status'].toString().toUpperCase(),
                                                  fontSize: 10,
                                                  mainColor: statusColor,
                                                  shadowColor: Colors.black54,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
