class WithdrawalModel {
  final String id;
  final String userId;
  final double amount;
  final String upiId;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? adminNotes;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.upiId,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.adminNotes,
  });

  // Factory: Create Withdrawal from JSON (Database Row)
  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      upiId: json['upi_id'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      adminNotes: json['admin_notes'],
    );
  }

  // Convert to JSON for database insertion
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'upi_id': upiId,
      'status': status,
    };
  }

  // Check if withdrawal is pending
  bool get isPending => status == 'pending';

  // Check if withdrawal is approved
  bool get isApproved => status == 'approved';

  // Check if withdrawal is rejected
  bool get isRejected => status == 'rejected';

  // Check if withdrawal is completed
  bool get isCompleted => status == 'completed';
}
