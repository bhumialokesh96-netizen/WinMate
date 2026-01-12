import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

/// Enhanced Supabase Service with better error handling and performance optimizations
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Cache for user data to reduce database calls
  UserModel? _cachedUser;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Simple logging helper (replace with proper logging package in production)
  void _log(String message, {Object? error}) {
    // In production, use a proper logging framework like logger package
    // For now, using debugPrint which is stripped in release builds
    final timestamp = DateTime.now().toIso8601String();
    if (error != null) {
      debugPrint('[$timestamp] $message: $error');
    } else {
      debugPrint('[$timestamp] $message');
    }
  }

  // 1. CHECK IF INVITE CODE EXISTS (Required for Signup)
  Future<bool> validateInviteCode(String code) async {
    try {
      final response = await _client
          .from(Constants.usersTable)
          .select('id')
          .eq('invite_code', code)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      _log('Error validating invite code', error: e);
      return false;
    }
  }

  // 2. REGISTER USER (With Invite Code Logic and better error handling)
  Future<String?> registerUser({
    required String phone,
    required String password,
    required String parentInviteCode,
  }) async {
    try {
      // Input validation
      if (phone.isEmpty || password.isEmpty || parentInviteCode.isEmpty) {
        return "All fields are required";
      }
      
      if (password.length < 6) {
        return "Password must be at least 6 characters";
      }

      // A. Check if Parent Code is valid
      final bool isValid = await validateInviteCode(parentInviteCode);
      if (!isValid) {
        return "Invalid Invite Code. Ask your friend for a correct one.";
      }

      // B. Create Auth User (Email/Phone + Password)
      final AuthResponse res = await _client.auth.signUp(
        email: "$phone@SMSindia.com", 
        password: password,
      );

      if (res.user == null) {
        return "Registration failed. Try again.";
      }

      // C. Generate My Own Invite Code (Random 6 chars)
      String myInviteCode = _generateRandomCode();

      // D. Insert into Public Users Table with retry logic
      int retries = 3;
      while (retries > 0) {
        try {
          await _client.from(Constants.usersTable).insert({
            'id': res.user!.id,
            'phone': phone,
            'invite_code': myInviteCode,
            'referrer_code': parentInviteCode,
            'device_id': 'ANDROID_ID_PLACEHOLDER',
            'balance': 0.0,
            'spins_available': 1,
            // Let database handle created_at timestamp automatically
          });
          break;
        } catch (e) {
          retries--;
          if (retries == 0) {
            return "Error creating user profile: ${e.toString()}";
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      return null; // Null means Success
    } on AuthException catch (e) {
      return "Authentication error: ${e.message}";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  // 3. LOGIN USER (with better error handling)
  Future<String?> loginUser(String phone, String password) async {
    try {
      if (phone.isEmpty || password.isEmpty) {
        return "Phone and password are required";
      }

      await _client.auth.signInWithPassword(
        email: "$phone@SMSindia.com",
        password: password,
      );
      
      // Clear cache on successful login
      _cachedUser = null;
      _cacheTime = null;
      
      return null; // Success
    } on AuthException catch (e) {
      return "Login failed: ${e.message}";
    } catch (e) {
      return "Login failed. Check phone or password.";
    }
  }

  // 4. GET CURRENT USER PROFILE (with caching)
  Future<UserModel?> getCurrentUser({bool forceRefresh = false}) async {
    try {
      // Return cached data if still valid
      if (!forceRefresh && 
          _cachedUser != null && 
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedUser;
      }

      final user = _client.auth.currentUser;
      if (user == null) return null;

      final data = await _client
          .from(Constants.usersTable)
          .select()
          .eq('id', user.id)
          .single();

      _cachedUser = UserModel.fromJson(data);
      _cacheTime = DateTime.now();
      
      return _cachedUser;
    } catch (e) {
      _log('Error fetching user', error: e);
      return null;
    }
  }

  // 5. UPDATE USER BALANCE
  Future<bool> updateBalance(String userId, double newBalance) async {
    try {
      await _client
          .from(Constants.usersTable)
          .update({'balance': newBalance})
          .eq('id', userId);
      
      // Invalidate cache
      _cachedUser = null;
      _cacheTime = null;
      
      return true;
    } catch (e) {
      _log('Error updating balance', error: e);
      return false;
    }
  }

  // 6. UPDATE SPINS AVAILABLE
  Future<bool> updateSpins(String userId, int spins) async {
    try {
      await _client
          .from(Constants.usersTable)
          .update({'spins_available': spins})
          .eq('id', userId);
      
      // Invalidate cache
      _cachedUser = null;
      _cacheTime = null;
      
      return true;
    } catch (e) {
      _log('Error updating spins', error: e);
      return false;
    }
  }

  // 7. LOGOUT
  Future<void> logout() async {
    await _client.auth.signOut();
    _cachedUser = null;
    _cacheTime = null;
  }

  // 8. Clear cache manually
  void clearCache() {
    _cachedUser = null;
    _cacheTime = null;
  }

  // Helper: Generate Random Invite Code (e.g., "WM8291")
  String _generateRandomCode() {
    var r = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return 'WM' + List.generate(4, (index) => chars[r.nextInt(chars.length)]).join();
  }
}
