class TaskModel {
  final String id;
  final String userId;
  final String status; // 'pending', 'sent', 'failed'
  final double amount;
  final int? simSlot; // 0 or 1 for dual SIM support
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.amount,
    this.simSlot,
    required this.createdAt,
    this.completedAt,
  });

  // Factory: Create Task from JSON (Database Row)
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 2.0).toDouble(),
      simSlot: json['sim_slot'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  // Convert to JSON for database insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'amount': amount,
      'sim_slot': simSlot,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // Check if task is completed
  bool get isCompleted => status == 'sent';

  // Check if task is pending
  bool get isPending => status == 'pending';

  // Check if task failed
  bool get isFailed => status == 'failed';
}
