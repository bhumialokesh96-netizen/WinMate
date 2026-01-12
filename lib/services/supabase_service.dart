import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../utils/code_generator.dart';

/// Enhanced Supabase Service with better error handling and performance optimizations
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  
  // Cache for user data to reduce database calls
  UserModel? _cachedUser;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Simple logging helper for development and production
  // Uses debugPrint which is automatically stripped in release builds
  // For more advanced logging needs, consider packages like 'logger' or 'logging'
  void _log(String message, {Object? error}) {
    // Only compute timestamp in debug mode to avoid unnecessary work in production
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      if (error != null) {
        debugPrint('[$timestamp] $message: $error');
      } else {
        debugPrint('[$timestamp] $message');
      }
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
      String myInviteCode = CodeGenerator.generateInviteCode();

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

  // ============================================
  // SMS TASKS OPERATIONS
  // ============================================

  // Create a new SMS task
  Future<String?> createSmsTask({
    required String userId,
    required int simSlot,
  }) async {
    try {
      await _client.from('sms_tasks').insert({
        'user_id': userId,
        'status': 'pending',
        'amount': 2.0,
        'sim_slot': simSlot,
      });
      return null; // Success
    } catch (e) {
      _log('Error creating SMS task', error: e);
      return 'Failed to create SMS task';
    }
  }

  // Update SMS task status
  Future<bool> updateSmsTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      await _client.from('sms_tasks').update({
        'status': status,
        'completed_at': status == 'sent' ? DateTime.now().toIso8601String() : null,
      }).eq('id', taskId);
      return true;
    } catch (e) {
      _log('Error updating SMS task status', error: e);
      return false;
    }
  }

  // Get user's SMS tasks
  Future<List<Map<String, dynamic>>?> getUserSmsTasks(String userId) async {
    try {
      final data = await _client
          .from('sms_tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching SMS tasks', error: e);
      return null;
    }
  }

  // ============================================
  // WITHDRAWALS OPERATIONS
  // ============================================

  // Create withdrawal request
  Future<String?> createWithdrawal({
    required String userId,
    required double amount,
    required String upiId,
  }) async {
    try {
      await _client.from('withdrawals').insert({
        'user_id': userId,
        'amount': amount,
        'upi_id': upiId,
        'status': 'pending',
      });
      return null; // Success
    } catch (e) {
      _log('Error creating withdrawal', error: e);
      return 'Failed to create withdrawal request';
    }
  }

  // Get user's withdrawals
  Future<List<Map<String, dynamic>>?> getUserWithdrawals(String userId) async {
    try {
      final data = await _client
          .from('withdrawals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching withdrawals', error: e);
      return null;
    }
  }

  // ============================================
  // SIM SETTINGS OPERATIONS
  // ============================================

  // Get SIM settings for user
  Future<List<Map<String, dynamic>>?> getSimSettings(String userId) async {
    try {
      final data = await _client
          .from('sim_settings')
          .select()
          .eq('user_id', userId)
          .order('sim_slot', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching SIM settings', error: e);
      return null;
    }
  }

  // Update or create SIM settings (UPSERT)
  Future<bool> upsertSimSettings({
    required String userId,
    required int simSlot,
    required String simName,
    required int dailyLimit,
    required bool isActive,
  }) async {
    try {
      await _client.from('sim_settings').upsert({
        'user_id': userId,
        'sim_slot': simSlot,
        'sim_name': simName,
        'daily_limit': dailyLimit,
        'is_active': isActive,
      });
      return true;
    } catch (e) {
      _log('Error upserting SIM settings', error: e);
      return false;
    }
  }

  // Increment sent_today count
  Future<bool> incrementSmsSentToday({
    required String userId,
    required int simSlot,
  }) async {
    try {
      final settings = await _client
          .from('sim_settings')
          .select('sent_today')
          .eq('user_id', userId)
          .eq('sim_slot', simSlot)
          .maybeSingle();
      
      if (settings == null) {
        _log('SIM settings not found for user $userId slot $simSlot');
        return false;
      }
      
      final newCount = (settings['sent_today'] ?? 0) + 1;
      
      await _client
          .from('sim_settings')
          .update({'sent_today': newCount})
          .eq('user_id', userId)
          .eq('sim_slot', simSlot);
      
      return true;
    } catch (e) {
      _log('Error incrementing SMS count', error: e);
      return false;
    }
  }

  // Reset sent_today to 0 (called at midnight)
  Future<bool> resetDailySmsCount(String userId) async {
    try {
      await _client
          .from('sim_settings')
          .update({'sent_today': 0})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      _log('Error resetting daily SMS count', error: e);
      return false;
    }
  }

  // ============================================
  // INVITES OPERATIONS
  // ============================================

  // Create invite record
  Future<String?> createInvite({
    required String userId,
    required String email,
  }) async {
    try {
      await _client.from('invites').insert({
        'user_id': userId,
        'invited_email': email,
      });
      return null; // Success
    } catch (e) {
      _log('Error creating invite', error: e);
      return 'Failed to send invite';
    }
  }

  // Get user's invites
  Future<List<Map<String, dynamic>>?> getUserInvites(String userId) async {
    try {
      final data = await _client
          .from('invites')
          .select()
          .eq('user_id', userId)
          .order('invited_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching invites', error: e);
      return null;
    }
  }

  // Update invite when user joins
  Future<bool> markInviteAsJoined({
    required String inviteId,
    required String joinedUserId,
  }) async {
    try {
      await _client.from('invites').update({
        'is_joined': true,
        'joined_user_id': joinedUserId,
      }).eq('id', inviteId);
      return true;
    } catch (e) {
      _log('Error marking invite as joined', error: e);
      return false;
    }
  }

  // ============================================
  // WHEEL PRIZES QUERIES
  // ============================================

  // Get active wheel prizes
  Future<List<Map<String, dynamic>>?> getActiveWheelPrizes() async {
    try {
      final data = await _client
          .from('wheel_prizes')
          .select()
          .eq('is_active', true)
          .order('probability', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching wheel prizes', error: e);
      return null;
    }
  }

  // ============================================
  // FAQS QUERIES
  // ============================================

  // Get visible FAQs
  Future<List<Map<String, dynamic>>?> getFaqs({String? category}) async {
    try {
      var query = _client
          .from('faqs')
          .select()
          .eq('is_visible', true);
      
      if (category != null) {
        query = query.eq('category', category);
      }
      
      final data = await query.order('priority', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching FAQs', error: e);
      return null;
    }
  }

  // Get FAQ categories
  Future<List<String>?> getFaqCategories() async {
    try {
      final data = await _client
          .from('faqs')
          .select('category')
          .eq('is_visible', true);
      
      return data
          .map<String>((item) => item['category'] as String)
          .toSet()
          .toList();
    } catch (e) {
      _log('Error fetching FAQ categories', error: e);
      return null;
    }
  }

  // ============================================
  // SYSTEM NOTIFICATIONS QUERIES
  // ============================================

  // Get active system notifications
  Future<List<Map<String, dynamic>>?> getSystemNotifications() async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await _client
          .from('system_notifications')
          .select()
          .eq('is_active', true)
          .or('expires_at.is.null,expires_at.gt.$now')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching system notifications', error: e);
      return null;
    }
  }

  // ============================================
  // SUPPORT LINKS QUERIES
  // ============================================

  // Get support links (single row expected)
  Future<Map<String, dynamic>?> getSupportLinks() async {
    try {
      final data = await _client
          .from('support_links')
          .select()
          .single();
      return data;
    } catch (e) {
      _log('Error fetching support links', error: e);
      return null;
    }
  }

  // ============================================
  // LEADERBOARD QUERIES
  // ============================================

  // Get top earners for leaderboard
  Future<List<Map<String, dynamic>>?> getLeaderboard({int limit = 10}) async {
    try {
      final data = await _client
          .from(Constants.usersTable)
          .select('phone, total_earn')
          .order('total_earn', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching leaderboard', error: e);
      return null;
    }
  }

  // ============================================
  // REFERRAL TREE QUERIES
  // ============================================

  // Get user's direct referrals
  Future<List<Map<String, dynamic>>?> getUserReferrals(String inviteCode) async {
    try {
      final data = await _client
          .from(Constants.usersTable)
          .select('id, phone, created_at, total_earn')
          .eq('referrer_code', inviteCode)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _log('Error fetching user referrals', error: e);
      return null;
    }
  }
}
