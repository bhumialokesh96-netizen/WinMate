import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // 1. CHECK IF INVITE CODE EXISTS (Required for Signup)
  Future<bool> validateInviteCode(String code) async {
    final response = await _client
        .from(Constants.usersTable)
        .select('id')
        .eq('invite_code', code)
        .maybeSingle();
    
    return response != null; // Returns true if code exists
  }

  // 2. REGISTER USER (With Invite Code Logic)
  Future<String?> registerUser({
    required String phone,
    required String password,
    required String parentInviteCode,
  }) async {
    try {
      // A. Check if Parent Code is valid
      final bool isValid = await validateInviteCode(parentInviteCode);
      if (!isValid) return "Invalid Invite Code. Ask your friend for a correct one.";

      // B. Create Auth User (Email/Phone + Password)
      // Note: We use phone@SMSindia.com as a fake email because Supabase needs email by default
      final AuthResponse res = await _client.auth.signUp(
        email: "$phone@SMSindia.com", 
        password: password,
      );

      if (res.user == null) return "Registration failed. Try again.";

      // C. Generate My Own Invite Code (Random 6 chars)
      String myInviteCode = _generateRandomCode();

      // D. Insert into Public Users Table
      await _client.from(Constants.usersTable).insert({
        'id': res.user!.id,
        'phone': phone,
        'invite_code': myInviteCode,
        'referrer_code': parentInviteCode,
        'device_id': 'ANDROID_ID_PLACEHOLDER', // We will fix this in Phase 3
        'balance': 0.0,
        'spins_available': 1 // Free spin bonus
      });

      return null; // Null means Success
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // 3. LOGIN USER
  Future<String?> loginUser(String phone, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: "$phone@SMSindia.com",
        password: password,
      );
      return null; // Success
    } catch (e) {
      return "Login failed. Check phone or password.";
    }
  }

  // 4. GET CURRENT USER PROFILE
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from(Constants.usersTable)
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromJson(data);
  }

  // Helper: Generate Random Invite Code (e.g., "WM8291")
  String _generateRandomCode() {
    var r = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return 'WM' + List.generate(4, (index) => chars[r.nextInt(chars.length)]).join();
  }
}
