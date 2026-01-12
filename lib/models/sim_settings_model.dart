class SimSettingsModel {
  final String id;
  final String userId;
  final int simSlot; // 0 or 1
  final String simName;
  final int dailyLimit;
  final int sentToday;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SimSettingsModel({
    required this.id,
    required this.userId,
    required this.simSlot,
    required this.simName,
    required this.dailyLimit,
    required this.sentToday,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory: Create SimSettings from JSON (Database Row)
  factory SimSettingsModel.fromJson(Map<String, dynamic> json) {
    return SimSettingsModel(
      id: json['id'],
      userId: json['user_id'],
      simSlot: json['sim_slot'],
      simName: json['sim_name'] ?? 'SIM ${(json['sim_slot'] ?? 0) + 1}',
      dailyLimit: json['daily_limit'] ?? 100,
      sentToday: json['sent_today'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sim_slot': simSlot,
      'sim_name': simName,
      'daily_limit': dailyLimit,
      'sent_today': sentToday,
      'is_active': isActive,
    };
  }

  // Check if SIM can send more messages today
  bool get canSendMore => isActive && sentToday < dailyLimit;

  // Get remaining SMS count for the day
  int get remainingToday => dailyLimit - sentToday;

  // Get progress percentage
  double get progressPercentage {
    if (dailyLimit == 0) return 0.0;
    return (sentToday / dailyLimit).clamp(0.0, 1.0);
  }
}
