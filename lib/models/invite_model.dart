class InviteModel {
  final String id;
  final String userId;
  final String invitedEmail;
  final DateTime invitedAt;
  final bool isJoined;
  final String? joinedUserId;

  InviteModel({
    required this.id,
    required this.userId,
    required this.invitedEmail,
    required this.invitedAt,
    required this.isJoined,
    this.joinedUserId,
  });

  // Factory: Create Invite from JSON (Database Row)
  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['id'],
      userId: json['user_id'],
      invitedEmail: json['invited_email'],
      invitedAt: DateTime.parse(json['invited_at']),
      isJoined: json['is_joined'] ?? false,
      joinedUserId: json['joined_user_id'],
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'invited_email': invitedEmail,
      'invited_at': invitedAt.toIso8601String(),
      'is_joined': isJoined,
      'joined_user_id': joinedUserId,
    };
  }

  // Check if invite is pending
  bool get isPending => !isJoined;
}
