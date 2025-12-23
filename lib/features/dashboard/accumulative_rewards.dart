import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:SMSindia/features/home/lucky_wheel_page.dart';
import 'package:SMSindia/features/invite/invite_screen.dart';

class AccumulativeRewards extends StatefulWidget {
  const AccumulativeRewards({super.key});

  @override
  State<AccumulativeRewards> createState() => _AccumulativeRewardsState();
}

class _AccumulativeRewardsState extends State<AccumulativeRewards> {
  final SupabaseClient supabase = Supabase.instance.client;
  int totalSmsSent = 0;
  int spinsAvailable = 0;
  int totalInvites = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  double balance = 0.00;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await supabase
          .from('users')
          .select('total_sms_sent, spins_available, total_invites, balance')
          .eq('id', user.id)
          .single();

      setState(() {
        totalSmsSent = data['total_sms_sent'] ?? 0;
        spinsAvailable = data['spins_available'] ?? 0;
        totalInvites = data['total_invites'] ?? 0;
        balance = (data['balance'] ?? 0.0).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data';
        _isLoading = false;
      });
    }
  }

  Future<void> _useSpin() async {
    if (spinsAvailable <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("No spins available!"),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Deduct spin
      await supabase
          .from('users')
          .update({'spins_available': spinsAvailable - 1})
          .eq('id', user.id);

      // Add reward (5 SMS credits = ₹0.75 at ₹0.15 per SMS)
      final rewardAmount = 0.75;
      await supabase.rpc('increment_balance', params: {'amount': rewardAmount});

      setState(() {
        spinsAvailable--;
        balance += rewardAmount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🎉 You won ₹${rewardAmount.toStringAsFixed(2)}!"),
          backgroundColor: const Color(0xFF00C853),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _processInvite(String email) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Record invite
      await supabase.from('invites').upsert({
        'user_id': user.id,
        'invited_email': email,
        'invited_at': DateTime.now().toIso8601String(),
      });

      // Update user stats
      await supabase
          .from('users')
          .update({
            'total_invites': totalInvites + 1,
            'spins_available': spinsAvailable + 1,
          })
          .eq('id', user.id);

      setState(() {
        totalInvites++;
        spinsAvailable++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Invite sent! +1 spin earned"),
          backgroundColor: const Color(0xFF00C853),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to send invite"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _shareInviteLink() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final inviteCode = user.id.substring(0, 8); // Short invite code
    final inviteLink = "https://api.smsindia.cfd/invite?ref=$inviteCode";
    
    await Clipboard.setData(ClipboardData(text: inviteLink));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Invite link copied to clipboard!"),
        backgroundColor: const Color(0xFF00C853),
      ),
    );
  }

  void _showInviteDialog() {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: build3DText(
          "Invite Friend",
          fontSize: 20,
          mainColor: const Color(0xFF00C853),
          shadowColor: Colors.black54,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Friend's Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            build3DText(
              "Earn 1 spin when friend joins!",
              fontSize: 12,
              mainColor: const Color(0xFF666666),
              shadowColor: Colors.black54,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                _processInvite(email);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text("Send Invite"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF00C853),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              build3DText(
                'Loading rewards...',
                fontSize: 16,
                mainColor: Colors.white,
                shadowColor: Colors.black54,
              ),
            ],
          ),
        ),
      );
    }

    final progressToNextSpin = totalSmsSent % 100;
    final nextSpinAt = 100 - progressToNextSpin;

    return Scaffold(
      backgroundColor: const Color(0xFF00C853),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: build3DText(
          "Rewards Hub",
          fontSize: 24,
          mainColor: Colors.white,
          shadowColor: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: build3DIcon(
              Icons.refresh,
              size: 24,
              mainColor: Colors.white,
              shadowColor: Colors.black54,
            ),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: Stack(
        children: [
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

          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // BALANCE CARD
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      build3DText(
                        "Wallet Balance",
                        fontSize: 16,
                        mainColor: const Color(0xFF666666),
                        shadowColor: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 10),
                      build3DText(
                        "₹${balance.toStringAsFixed(2)}",
                        fontSize: 48,
                        mainColor: const Color(0xFF00C853),
                        shadowColor: Colors.black,
                        fontWeight: FontWeight.bold,
                        depth: 3,
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: build3DText(
                            _errorMessage,
                            fontSize: 12,
                            mainColor: Colors.red,
                            shadowColor: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // SPINS CARD
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          build3DIcon(
                            Icons.celebration,
                            size: 30,
                            mainColor: Colors.orange,
                            shadowColor: Colors.black54,
                          ),
                          const SizedBox(width: 10),
                          build3DText(
                            "Available Spins",
                            fontSize: 20,
                            mainColor: Colors.orange,
                            shadowColor: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      build3DText(
                        "$spinsAvailable",
                        fontSize: 48,
                        mainColor: Colors.orange,
                        shadowColor: Colors.black,
                        fontWeight: FontWeight.bold,
                        depth: 3,
                      ),
                      const SizedBox(height: 10),
                      build3DText(
                        "Spin to win SMS credits!",
                        fontSize: 14,
                        mainColor: const Color(0xFF666666),
                        shadowColor: Colors.black54,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // STATS ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "SMS Sent",
                        value: "$totalSmsSent",
                        icon: Icons.sms,
                        color: const Color(0xFF00C853),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        title: "Invites",
                        value: "$totalInvites",
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // PROGRESS TO NEXT SPIN
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      build3DText(
                        "Progress to Next Spin",
                        fontSize: 16,
                        mainColor: const Color(0xFF666666),
                        shadowColor: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 15),
                      LinearProgressIndicator(
                        value: progressToNextSpin / 100,
                        backgroundColor: Colors.grey[300],
                        color: const Color(0xFF00C853),
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          build3DText(
                            "$progressToNextSpin/100 SMS",
                            fontSize: 14,
                            mainColor: const Color(0xFF00C853),
                            shadowColor: Colors.black54,
                          ),
                          build3DText(
                            "$nextSpinAt more needed",
                            fontSize: 12,
                            mainColor: const Color(0xFF666666),
                            shadowColor: Colors.black54,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // SPIN BUTTON
                // SPIN BUTTON  
if (spinsAvailable > 0)  
  SizedBox(  
    width: double.infinity,  
    height: 60,  
    child: ElevatedButton(  
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LuckyWheelPage(),
          ),
        );
      },  
      style: ElevatedButton.styleFrom(  
        backgroundColor: Colors.orange,  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(15),  
        ),  
        elevation: 8,  
        shadowColor: Colors.orange.withOpacity(0.5),  
      ),  
      child: Row(  
        mainAxisAlignment: MainAxisAlignment.center,  
        children: [  
          build3DIcon(  
            Icons.celebration,  
            size: 24,  
            mainColor: Colors.white,  
            shadowColor: Colors.black54,  
          ),  
          const SizedBox(width: 10),  
          build3DText(  
            "SPIN WHEEL ($spinsAvailable left)",  
            fontSize: 18,  
            mainColor: Colors.white,  
            shadowColor: Colors.black54,  
            fontWeight: FontWeight.bold,  
          ),  
        ],  
      ),  
    ),  
  ),  

const SizedBox(height: 20),

                // INVITE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _showInviteDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF00C853).withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        build3DIcon(
                          Icons.person_add,
                          size: 24,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                        const SizedBox(width: 10),
                        build3DText(
                          "INVITE FRIENDS",
                          fontSize: 18,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // QUICK SHARE BUTTON
               // QUICK SHARE BUTTON
SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InviteScreen(),
        ),
      );
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
    child: const Text("Copy Invite Link"),
  ),
),

const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          build3DIcon(
            icon,
            size: 30,
            mainColor: color,
            shadowColor: Colors.black54,
          ),
          const SizedBox(height: 10),
          build3DText(
            value,
            fontSize: 24,
            mainColor: color,
            shadowColor: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 5),
          build3DText(
            title,
            fontSize: 12,
            mainColor: const Color(0xFF666666),
            shadowColor: Colors.black54,
          ),
        ],
      ),
    );
  }

  // --- 3D Text Widget ---
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
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: shadowColor,
          ),
        ),
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

  // --- 3D Icon Widget ---
  Widget build3DIcon(
    IconData icon, {
    double size = 24,
    Color mainColor = Colors.white,
    Color shadowColor = Colors.black54,
    double depth = 1,
  }) {
    return Stack(
      children: [
        Icon(icon, size: size, color: shadowColor),
        Transform.translate(
          offset: Offset(0, -depth),
          child: Icon(icon, size: size, color: mainColor),
        ),
      ],
    );
  }
}
