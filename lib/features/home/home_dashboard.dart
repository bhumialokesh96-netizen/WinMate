import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:SMSindia/features/wallet/withdraw_screen.dart';
import 'package:SMSindia/features/wallet/history_screen.dart';
import 'package:SMSindia/features/home/lucky_wheel_page.dart'; // Updated import

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
  int spinsAvailable = 0;
  bool isLoading = true;
  bool _isRefreshing = false;

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const darkGreen = Color(0xFF00796B);
  static const accentOrange = Color(0xFFFF9100);

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    setState(() => isLoading = true);
    
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final phone = user.userMetadata?['phone'] ?? user.email ?? "Miner";
        
        final walletData = await supabase
            .from('users')
            .select('balance, total_sms_sent, spins_available')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            userPhone = phone;
            balance = (walletData['balance'] as num).toDouble();
            totalSms = (walletData['total_sms_sent'] ?? 0) as int;
            spinsAvailable = (walletData['spins_available'] ?? 0) as int;
            isLoading = false;
            _isRefreshing = false;
          });
        }
      } catch (e) {
        print("Error loading wallet: $e");
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
                  Color(0xFF00E676), // Bright Green Top
                  Color(0xFF00C853), // Medium Green
                  Color(0xFF00BFA5), // Teal Bottom
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

          // Main Content
          SafeArea(
            child: isLoading 
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRealData,
                    color: primaryGreen,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // AppBar with User Info
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    build3DText(
                                      "Welcome,",
                                      fontSize: 18,
                                      mainColor: Colors.yellow,
                                      shadowColor: const Color(0xFF004D40),
                                      depth: 2,
                                    ),
                                    const SizedBox(height: 4),
                                    build3DText(
                                      userPhone,
                                      fontSize: 16,
                                      mainColor: Colors.white,
                                      shadowColor: Colors.black54,
                                      depth: 1.5,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() => _isRefreshing = true);
                                  _loadRealData();
                                },
                                icon: _isRefreshing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
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
                                  color: primaryGreen.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                build3DText(
                                  "Current Balance",
                                  fontSize: 14,
                                  mainColor: Colors.white.withOpacity(0.9),
                                  shadowColor: Colors.black54,
                                  depth: 1.5,
                                ),
                                const SizedBox(height: 10),
                                build3DText(
                                  "₹${balance.toStringAsFixed(2)}",
                                  fontSize: 42,
                                  mainColor: Colors.white,
                                  shadowColor: Colors.black,
                                  depth: 3,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 15),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      build3DIcon(
                                        Icons.send,
                                        size: 16,
                                        mainColor: Colors.white,
                                        shadowColor: Colors.black54,
                                      ),
                                      const SizedBox(width: 5),
                                      build3DText(
                                        "Total SMS Sent: $totalSms",
                                        fontSize: 13,
                                        mainColor: Colors.white,
                                        shadowColor: Colors.black54,
                                        depth: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // --- LUCKY WHEEL CARD ---
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LuckyWheelPage()),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF3ED598),
                                    Color(0xFF00C853),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Wheel Icon
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.casino,
                                      color: primaryGreen,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  
                                  // Text Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        build3DText(
                                          "Lucky Wheel",
                                          fontSize: 18,
                                          mainColor: Colors.white,
                                          shadowColor: Colors.black54,
                                          fontWeight: FontWeight.bold,
                                          depth: 1.5,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Spin to win iPhone 16 & cash prizes!",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: spinsAvailable > 0 ? Colors.green : Colors.orange,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              spinsAvailable > 0 
                                                ? "$spinsAvailable spin${spinsAvailable > 1 ? 's' : ''} available" 
                                                : "No spins left",
                                              style: GoogleFonts.poppins(
                                                color: spinsAvailable > 0 ? Colors.white : Colors.yellow,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Arrow Icon
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // --- QUICK ACTIONS ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                build3DText(
                                  "Quick Actions",
                                  fontSize: 18,
                                  mainColor: Colors.white,
                                  shadowColor: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 20),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // DEPOSIT
                                    _buildActionBtn(
                                      Icons.add,
                                      "Deposit",
                                      () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: build3DText(
                                              "Please contact Admin to Deposit funds.",
                                              fontSize: 14,
                                              mainColor: Colors.white,
                                              shadowColor: Colors.black54,
                                            ),
                                            backgroundColor: primaryGreen,
                                          ),
                                        );
                                      },
                                    ),

                                    // WITHDRAW
                                    _buildActionBtn(
                                      Icons.download,
                                      "Withdraw",
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const WithdrawScreen()),
                                        );
                                      },
                                    ),

                                    // HISTORY
                                    _buildActionBtn(
                                      Icons.history,
                                      "History",
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const HistoryScreen()),
                                        );
                                      },
                                    ),

                                    // NOTIFICATIONS
                                    _buildActionBtn(
                                      Icons.notifications,
                                      "Alerts",
                                      () {
                                        // Add notification screen navigation here
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: build3DText(
                                              "Notifications feature coming soon!",
                                              fontSize: 14,
                                              mainColor: Colors.white,
                                              shadowColor: Colors.black54,
                                            ),
                                            backgroundColor: accentOrange,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // --- STATISTICS ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  Icons.account_balance_wallet,
                                  "Balance",
                                  "₹${balance.toStringAsFixed(2)}",
                                  Colors.green,
                                ),
                                _buildStatItem(
                                  Icons.send,
                                  "SMS Sent",
                                  totalSms.toString(),
                                  Colors.blue,
                                ),
                                _buildStatItem(
                                  Icons.casino,
                                  "Spins",
                                  spinsAvailable.toString(),
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget build3DText(
    String text, {
    double fontSize = 18,
    Color mainColor = Colors.white,
    Color shadowColor = const Color(0xFF004D40),
    double depth = 2,
    FontWeight fontWeight = FontWeight.w900,
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

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
