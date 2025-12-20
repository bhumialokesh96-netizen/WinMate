class InviteTreeModel {
  final String userId;
  final String displayPhone; // We will show phone instead of name
  final DateTime joinedAt;

  InviteTreeModel({
    required this.userId,
    required this.displayPhone,
    required this.joinedAt,
  });

  factory InviteTreeModel.fromJson(Map<String, dynamic> json) {
    return InviteTreeModel(
      userId: json['id'],
      // Fallback to 'User' if phone is null
      displayPhone: json['phone'] ?? 'User', 
      joinedAt: DateTime.parse(json['created_at']),
    );
  }
}
