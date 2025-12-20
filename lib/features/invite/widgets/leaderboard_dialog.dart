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
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.orange),
          const SizedBox(width: 10),
          Text("Top Earners", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Fixed height for scrolling
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
            : leaders.isEmpty
                ? Center(child: Text("No data yet.", style: GoogleFonts.poppins(color: Colors.white54)))
                : ListView.builder(
                    itemCount: leaders.length,
                    itemBuilder: (context, index) {
                      final user = leaders[index];
                      final rank = index + 1;
                      
                      // Special Colors for Top 3
                      Color rankColor = Colors.white;
                      if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
                      if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
                      if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                          border: rank <= 3 ? Border.all(color: rankColor.withOpacity(0.5)) : null,
                        ),
                        child: Row(
                          children: [
                            // Rank Number
                            Text(
                              "#$rank",
                              style: GoogleFonts.poppins(
                                color: rankColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              ),
                            ),
                            const SizedBox(width: 15),
                            
                            // User Phone (Masked)
                            Expanded(
                              child: Text(
                                user.maskedPhone, // Uses the helper from your model
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ),

                            // Amount Earned
                            Text(
                              "₹${user.totalEarned.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold
                              ),
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
          child: Text("Close", style: GoogleFonts.poppins(color: Colors.white54)),
        )
      ],
    );
  }
}
