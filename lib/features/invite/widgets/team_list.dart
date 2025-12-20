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
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)));
    
    if (team.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.person_off, color: Colors.grey, size: 40),
              const SizedBox(height: 10),
              Text("No team members yet.", style: GoogleFonts.poppins(color: Colors.white54)),
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
        return Card(
          color: const Color(0xFF16213E),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE94560),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              _maskPhone(member.displayPhone), 
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            subtitle: Text(
              "Joined: ${member.joinedAt.toString().split(' ')[0]}", 
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)
            ),
            trailing: const Icon(Icons.verified, color: Colors.green, size: 16),
          ),
        );
      },
    );
  }
}
