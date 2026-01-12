import 'dart:math';

/// Utility class for generating random codes used in the application
class CodeGenerator {
  /// Generates a random invite code with format "WM" + 4 random alphanumeric characters
  /// 
  /// Example output: "WM8291", "WMAB3X", "WM9K2L"
  /// 
  /// This code is used for:
  /// - User invite codes stored in the database
  /// - Referral tracking
  /// - User identification in the referral system
  static String generateInviteCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final randomPart = List.generate(4, (index) => chars[random.nextInt(chars.length)]).join();
    return 'WM$randomPart';
  }
}
