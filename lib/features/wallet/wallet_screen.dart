import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  double balance = 0.00;
  bool isLoading = true;
  bool _isRefreshing = false;
  List<dynamic> recentEarnings = [];

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const accentOrange = Color(0xFFFF9100);

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        final walletData = await supabase
            .from('users')
            .select('balance')
            .eq('id', user.id)
            .single();

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
            _isRefreshing = false;
          });
        }
      } catch (e) {
        debugPrint("Error loading wallet: $e");
        if (mounted) {
          setState(() {
            isLoading = false;
            _isRefreshing = false;
          });
        }
      }
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
            child: RefreshIndicator(
              onRefresh: _fetchWalletData,
              color: primaryGreen,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Bar
                    Row(
                      children: [
                        Expanded(
                          child: build3DText(
                            "My Wallet",
                            fontSize: 24,
                            mainColor: Colors.white,
                            shadowColor: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
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
                          onPressed: () {
                            setState(() => _isRefreshing = true);
                            _fetchWalletData();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- BALANCE CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          build3DText(
                            "Total Balance",
                            fontSize: 16,
                            mainColor: Colors.white.withOpacity(0.9),
                            shadowColor: Colors.black54,
                          ),
                          const SizedBox(height: 10),
                          isLoading 
                              ? const SizedBox(
                                  height: 40,
                                  width: 40,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : build3DText(
                                  "₹${balance.toStringAsFixed(2)}",
                                  fontSize: 42,
                                  mainColor: Colors.white,
                                  shadowColor: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  depth: 3,
                                ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: build3DIcon(
                                  Icons.security,
                                  size: 16,
                                  mainColor: Colors.white,
                                  shadowColor: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              build3DText(
                                "Secure Payments",
                                fontSize: 14,
                                mainColor: Colors.white.withOpacity(0.9),
                                shadowColor: Colors.black54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- WITHDRAW BUTTON ---
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WithdrawScreen()),
                          );
                        },
                        icon: build3DIcon(
                          Icons.arrow_upward,
                          size: 24,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                        label: build3DText(
                          "Withdraw Funds",
                          fontSize: 16,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentOrange,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- RECENT INCOME ---
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: build3DIcon(
                                  Icons.trending_up,
                                  size: 20,
                                  mainColor: primaryGreen,
                                  shadowColor: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 10),
                              build3DText(
                                "Recent Income",
                                fontSize: 18,
                                mainColor: Colors.black87,
                                shadowColor: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          
                          if (recentEarnings.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                children: [
                                  build3DIcon(
                                    Icons.account_balance_wallet,
                                    size: 50,
                                    mainColor: Colors.grey,
                                    shadowColor: Colors.black54,
                                  ),
                                  const SizedBox(height: 10),
                                  build3DText(
                                    "No income yet",
                                    fontSize: 16,
                                    mainColor: Colors.grey[600]!,
                                    shadowColor: Colors.black54,
                                  ),
                                  const SizedBox(height: 5),
                                  build3DText(
                                    "Start mining to earn rewards!",
                                    fontSize: 12,
                                    mainColor: Colors.grey[500]!,
                                    shadowColor: Colors.black54,
                                  ),
                                ],
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
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: primaryGreen.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: build3DIcon(
                                              Icons.check,
                                              size: 20,
                                              mainColor: primaryGreen,
                                              shadowColor: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              build3DText(
                                                "SMS Revenue",
                                                fontSize: 14,
                                                mainColor: Colors.black87,
                                                shadowColor: Colors.black54,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              build3DText(
                                                "Task ID: ${item['id'].toString().substring(0,4)}...",
                                                fontSize: 10,
                                                mainColor: Colors.grey[600]!,
                                                shadowColor: Colors.black54,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      build3DText(
                                        "+₹2.00",
                                        fontSize: 16,
                                        mainColor: primaryGreen,
                                        shadowColor: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
