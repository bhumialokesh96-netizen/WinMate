import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/invite_tree_model.dart';

class TeamList extends StatefulWidget {
  const TeamList({super.key});

  @override
  State<TeamList> createState() => _TeamListState();
}

class _TeamListState extends State<TeamList> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<InviteTreeModel> team = [];
  bool isLoading = true;

  // Color constants for the green theme
  static const primaryGreen = Color(0xFF00C853);
  static const lightGreen = Color(0xFFE8F5E9);
  static const accentOrange = Color(0xFFFF9100);

  @override
  void initState() {
    super.initState();
    _fetchTeam();
  }

  Future<void> _fetchTeam() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Get my invite code
      final myProfile = await supabase.from('users').select('invite_code').eq('id', user.id).single();
      final myCode = myProfile['invite_code'];

      if (myCode != null) {
        // 2. Find users who used my code
        // CHANGED: We fetch 'phone', NOT 'full_name'
        final response = await supabase
            .from('users')
            .select('id, phone, created_at') 
            .eq('referrer_code', myCode)
            .order('created_at', ascending: false);

        if (mounted) {
          setState(() {
            team = (response as List).map((e) => InviteTreeModel.fromJson(e)).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Helper to hide part of the number: "9876543210" -> "98765*****"
  String _maskPhone(String phone) {
    if (phone.length > 5) {
      return "${phone.substring(0, 5)}*****";
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryGreen),
            const SizedBox(height: 20),
            build3DText(
              "Loading team members...",
              fontSize: 16,
              mainColor: Colors.white,
              shadowColor: Colors.black54,
            ),
          ],
        ),
      );
    }
    
    if (team.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              build3DIcon(
                Icons.person_off,
                size: 40,
                mainColor: Colors.white54,
                shadowColor: Colors.black54,
              ),
              const SizedBox(height: 10),
              build3DText(
                "No team members yet.",
                fontSize: 16,
                mainColor: Colors.white54,
                shadowColor: Colors.black54,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(),
      itemCount: team.length,
      itemBuilder: (context, index) {
        final member = team[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: build3DIcon(
                  Icons.person,
                  size: 20,
                  mainColor: primaryGreen,
                  shadowColor: Colors.black54,
                ),
              ),
              const SizedBox(width: 15),
              
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    build3DText(
                      _maskPhone(member.displayPhone),
                      fontSize: 16,
                      mainColor: const Color(0xFF333333),
                      shadowColor: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    build3DText(
                      "Joined: ${member.joinedAt.toString().split(' ')[0]}",
                      fontSize: 12,
                      mainColor: const Color(0xFF666666),
                      shadowColor: Colors.black54,
                    ),
                  ],
                ),
              ),
              
              // Verified Badge
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: build3DIcon(
                  Icons.verified,
                  size: 16,
                  mainColor: primaryGreen,
                  shadowColor: Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
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
