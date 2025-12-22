import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/leaderboard_model.dart';

class LeaderboardDialog extends StatefulWidget {
  const LeaderboardDialog({super.key});

  @override
  State<LeaderboardDialog> createState() => _LeaderboardDialogState();
}

class _LeaderboardDialogState extends State<LeaderboardDialog> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<LeaderboardModel> leaders = [];
  bool isLoading = true;

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const accentOrange = Color(0xFFFF9100);

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      // Fetch Top 10 Users by 'total_earn'
      final response = await supabase
          .from('users')
          .select('phone, total_earn')
          .order('total_earn', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          leaders = (response as List)
              .map((e) => LeaderboardModel.fromJson(e))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          build3DIcon(
            Icons.emoji_events,
            size: 28,
            mainColor: accentOrange,
            shadowColor: Colors.black54,
          ),
          const SizedBox(width: 10),
          build3DText(
            "Top Earners",
            fontSize: 20,
            mainColor: const Color(0xFF333333),
            shadowColor: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Fixed height for scrolling
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: primaryGreen),
                    const SizedBox(height: 20),
                    build3DText(
                      "Loading leaderboard...",
                      fontSize: 16,
                      mainColor: const Color(0xFF666666),
                      shadowColor: Colors.black54,
                    ),
                  ],
                ),
              )
            : leaders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        build3DIcon(
                          Icons.emoji_events_outlined,
                          size: 50,
                          mainColor: const Color(0xFF666666),
                          shadowColor: Colors.black54,
                        ),
                        const SizedBox(height: 20),
                        build3DText(
                          "No data yet.",
                          fontSize: 16,
                          mainColor: const Color(0xFF666666),
                          shadowColor: Colors.black54,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: leaders.length,
                    itemBuilder: (context, index) {
                      final user = leaders[index];
                      final rank = index + 1;
                      
                      // Special Colors for Top 3
                      Color rankColor = const Color(0xFF666666);
                      if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
                      if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
                      if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: rank <= 3 
                              ? Border.all(color: rankColor.withOpacity(0.5), width: 2) 
                              : Border.all(color: Colors.grey[100]!),
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
                            // Rank Number
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: rank <= 3 ? rankColor.withOpacity(0.1) : Colors.grey[100],
                                border: rank <= 3 ? Border.all(color: rankColor, width: 2) : null,
                              ),
                              alignment: Alignment.center,
                              child: build3DText(
                                "#$rank",
                                fontSize: 14,
                                mainColor: rankColor,
                                shadowColor: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 15),
                            
                            // User Phone (Masked)
                            Expanded(
                              child: build3DText(
                                user.maskedPhone,
                                fontSize: 14,
                                mainColor: const Color(0xFF333333),
                                shadowColor: Colors.black54,
                              ),
                            ),

                            // Amount Earned
                            build3DText(
                              "₹${user.totalEarned.toStringAsFixed(0)}",
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: build3DText(
            "Close",
            fontSize: 16,
            mainColor: const Color(0xFF666666),
            shadowColor: Colors.black54,
          ),
        )
      ],
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
