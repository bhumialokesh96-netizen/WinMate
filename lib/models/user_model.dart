class UserModel {
  final String id;
  final String phone;
  final String inviteCode;
  final String? referrerCode; // Nullable (Root users might not have one)
  final double balance;
  final int spinsAvailable;
  final int totalSms;
  final int totalInvites;

  UserModel({
    required this.id,
    required this.phone,
    required this.inviteCode,
    this.referrerCode,
    required this.balance,
    required this.spinsAvailable,
    required this.totalSms,
    required this.totalInvites,
  });

  // Factory: Create User from JSON (Database Row)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phone: json['phone'] ?? '',
      inviteCode: json['invite_code'] ?? '',
      referrerCode: json['referrer_code'],
      balance: (json['balance'] ?? 0).toDouble(),
      spinsAvailable: json['spins_available'] ?? 0,
      totalSms: json['total_sms_sent'] ?? 0,
      totalInvites: json['total_invites'] ?? 0,
    );
  }
}
