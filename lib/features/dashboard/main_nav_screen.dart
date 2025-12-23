import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:winmate/features/auth/login_screen.dart';
import 'package:winmate/features/home/home_dashboard.dart';
import 'package:winmate/features/mining/mining_dashboard.dart';
import 'package:winmate/features/invite/invite_screen.dart';
import 'package:winmate/features/system/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'faq_page.dart';
import 'accumulative_rewards.dart';// Add this at the top



// Color constants for the green theme
const primaryGreen = Color(0xFF00C853);
const lightGreen = Color(0xFFE8F5E9);
const accentOrange = Color(0xFFFF9100);

// ---------------------------------------------------------
// 1. MAIN NAVIGATION
// ---------------------------------------------------------
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  // The screens list uses the class defined at the bottom
  final List<Widget> _screens = [
  const HomeDashboard(),        // 0
  const MiningDashboard(),      // 1
  const InviteScreen(),         // 2
  const AccumulativeRewards(),  // 3 ✅
  const ProfileScreen(),        // 4 ✅
];

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

          // Content
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white.withOpacity(0.95),
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryGreen,
            unselectedItemColor: Colors.grey[600],
            showUnselectedLabels: true,
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home,
                    color: _selectedIndex == 0 ? primaryGreen : Colors.grey[600],
                    size: 24,
                  ),
                ),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bolt,
                    color: _selectedIndex == 1 ? primaryGreen : Colors.grey[600],
                    size: 24,
                  ),
                ),
                label: "Mining",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.rocket_launch,
                    color: _selectedIndex == 2 ? primaryGreen : Colors.grey[600],
                    size: 24,
                  ),
                ),
                label: "Invite",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 3 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
  Icons.card_giftcard,
  color: _selectedIndex == 3 ? primaryGreen : Colors.grey[600],
  size: 24,
),
                ),
                label: "Reward",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 4 ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: _selectedIndex == 4 ? primaryGreen : Colors.grey[600],
                    size: 24,
                  ),
                ),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ---------------------------------------------------------
// PROFILE SCREEN (Embedded to fix Build Error)
// ---------------------------------------------------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String phone = "Loading...";
  String userId = "";
  bool _isLoading = true;
  Map<String, dynamic>? supportLinks;

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const darkGreen = Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSupportLinks();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          phone = user.userMetadata?['phone'] ?? user.phone ?? user.email ?? "User";
          userId = user.id.substring(0, 8).toUpperCase();
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSupportLinks() async {
    try {
      final data = await supabase
          .from('support_links')
          .select()
          .single();
      setState(() {
        supportLinks = data;
      });
    } catch (e) {
      print("Error loading support links: $e");
      // Set default links if not found in database
      setState(() {
        supportLinks = {
          'whatsapp_link': 'https://chat.whatsapp.com/YOUR_GROUP_LINK',
          'telegram_link': 'https://t.me/YOUR_GROUP_LINK',
          'email': 'support@winmate.com',
          'phone': '+91-XXXXXXXXXX',
        };
      });
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: build3DText(
          "Logout",
          fontSize: 20,
          mainColor: primaryGreen,
          shadowColor: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
        content: build3DText(
          "Are you sure you want to logout?",
          fontSize: 16,
          mainColor: Colors.black87,
          shadowColor: Colors.black54,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: build3DText(
              "Cancel",
              fontSize: 16,
              mainColor: Colors.grey,
              shadowColor: Colors.black54,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: build3DText(
              "Logout",
              fontSize: 16,
              mainColor: Colors.white,
              shadowColor: Colors.black54,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await supabase.auth.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()), 
          (route) => false,
        );
      }
    }
  }

  void _showSupportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              build3DText(
                "Contact Support",
                fontSize: 20,
                mainColor: primaryGreen,
                shadowColor: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 20),
              
              // WhatsApp Option
              _buildSupportOption(
                icon: FontAwesomeIcons.whatsapp,
                title: "WhatsApp Group",
                subtitle: "Join our community",
                color: const Color(0xFF25D366),
                onTap: () {
                  Navigator.pop(context);
                  _launchWhatsApp();
                },
              ),
              
              const SizedBox(height: 15),
              
              // Telegram Option
              _buildSupportOption(
                icon: FontAwesomeIcons.telegram,
                title: "Telegram Group",
                subtitle: "Get instant updates",
                color: const Color(0xFF0088CC),
                onTap: () {
                  Navigator.pop(context);
                  _launchTelegram();
                },
              ),
              
              const SizedBox(height: 15),
              
              // Email Option
              _buildSupportOption(
                icon: Icons.email,
                title: "Email Support",
                subtitle: supportLinks?['email'] ?? 'support@winmate.com',
                color: Colors.grey,
                onTap: () {
                  Navigator.pop(context);
                  _launchEmail();
                },
              ),
              
              const SizedBox(height: 15),
              
              // Phone Option
              _buildSupportOption(
                icon: Icons.phone,
                title: "Call Support",
                subtitle: supportLinks?['phone'] ?? '+91-XXXXXXXXXX',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _launchPhone();
                },
              ),
              
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: build3DText(
                  "Cancel",
                  fontSize: 16,
                  mainColor: Colors.grey,
                  shadowColor: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final url = supportLinks?['whatsapp_link'] ?? 'https://chat.whatsapp.com/YOUR_GROUP_LINK';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: build3DText(
            "Could not open WhatsApp",
            fontSize: 14,
            mainColor: Colors.white,
            shadowColor: Colors.black54,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchTelegram() async {
    final url = supportLinks?['telegram_link'] ?? 'https://t.me/YOUR_GROUP_LINK';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: build3DText(
            "Could not open Telegram",
            fontSize: 14,
            mainColor: Colors.white,
            shadowColor: Colors.black54,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchEmail() async {
    final email = supportLinks?['email'] ?? 'support@winmate.com';
    final url = 'mailto:$email?subject=Support Request&body=Hello Support Team,';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: build3DText(
            "Could not open email",
            fontSize: 14,
            mainColor: Colors.white,
            shadowColor: Colors.black54,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchPhone() async {
    final phone = supportLinks?['phone'] ?? '+91-XXXXXXXXXX';
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: build3DText(
            "Could not make a call",
            fontSize: 14,
            mainColor: Colors.white,
            shadowColor: Colors.black54,
          ),
          backgroundColor: Colors.red,
        ),
      );
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
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        build3DText(
                          "Loading profile...",
                          fontSize: 16,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // AppBar
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
                                "My Profile",
                                fontSize: 24,
                                mainColor: Colors.white,
                                shadowColor: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 48), // For balance with back button
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Profile Avatar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: build3DIcon(
                              Icons.person,
                              size: 60,
                              mainColor: primaryGreen,
                              shadowColor: Colors.black54,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // User Info
                        build3DText(
                          phone,
                          fontSize: 24,
                          mainColor: Colors.white,
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: build3DText(
                            "ID: $userId",
                            fontSize: 14,
                            mainColor: Colors.white.withOpacity(0.9),
                            shadowColor: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Menu Items
                        Container(
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
                              // System Notifications
                              _buildMenuItem(
                                Icons.notifications_active,
                                "System Notifications",
                                Colors.orange,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationScreen(),
                                    ),
                                  );
                                },
                              ),

                              // Security
                              _buildMenuItem(
                                Icons.security,
                                "Security",
                                Colors.blue,
                                () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: build3DText(
                                        "Security features coming soon!",
                                        fontSize: 14,
                                        mainColor: Colors.white,
                                        shadowColor: Colors.black54,
                                      ),
                                      backgroundColor: primaryGreen,
                                    ),
                                  );
                                },
                              ),

                              // Help & Support
                              _buildMenuItem(
                                Icons.help_outline,
                                "Help & Support",
                                Colors.purple,
                                _showSupportOptions,
                              ),

                              // FAQ
                              _buildMenuItem(
                                Icons.question_answer,
                                "FAQs",
                                Colors.teal,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FAQPage(),
                                    ),
                                  );
                                },
                              ),

                              // Logout (Special Styling)
                              Container(
                                margin: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: build3DIcon(
                                      Icons.logout,
                                      size: 24,
                                      mainColor: Colors.red,
                                      shadowColor: Colors.black54,
                                    ),
                                  ),
                                  title: build3DText(
                                    "Logout",
                                    fontSize: 16,
                                    mainColor: Colors.red,
                                    shadowColor: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: build3DIcon(
                                      Icons.chevron_right,
                                      size: 20,
                                      mainColor: Colors.red,
                                      shadowColor: Colors.black54,
                                    ),
                                  ),
                                  onTap: _logout,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Version Info
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: build3DText(
                            "Version 1.0.0",
                            fontSize: 12,
                            mainColor: Colors.white.withOpacity(0.8),
                            shadowColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color iconColor, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
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
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: build3DIcon(
            icon,
            size: 24,
            mainColor: iconColor,
            shadowColor: Colors.black54,
          ),
        ),
        title: build3DText(
          title,
          fontSize: 16,
          mainColor: Colors.black87,
          shadowColor: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: build3DIcon(
            Icons.chevron_right,
            size: 20,
            mainColor: primaryGreen,
            shadowColor: Colors.black54,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: primaryGreen,
        ),
      ),
      onTap: onTap,
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
