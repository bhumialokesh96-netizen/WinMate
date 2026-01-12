class SystemNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'urgent', 'promo'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  SystemNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
  });

  // Factory: Create SystemNotification from JSON (Database Row)
  factory SystemNotificationModel.fromJson(Map<String, dynamic> json) {
    return SystemNotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'info',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  // Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Check if notification is valid (active and not expired)
  bool get isValid => isActive && !isExpired;

  // Get notification type color
  String get typeColor {
    switch (type) {
      case 'warning':
        return '#FF9800'; // Orange
      case 'urgent':
        return '#F44336'; // Red
      case 'promo':
        return '#9C27B0'; // Purple
      case 'info':
      default:
        return '#2196F3'; // Blue
    }
  }
}
