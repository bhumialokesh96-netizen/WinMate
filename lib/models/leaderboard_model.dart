class LeaderboardModel {
  final String phone;
  final double totalEarned;

  LeaderboardModel({
    required this.phone, 
    required this.totalEarned
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      // Maps to your DB column 'phone'
      phone: json['phone'] ?? 'Unknown',
      // Maps to your DB column 'total_earn'
      totalEarned: (json['total_earn'] ?? 0).toDouble(),
    );
  }

  // Helper: Hides the last digits for privacy (e.g., "98765*****")
  String get maskedPhone {
    if (phone.length > 5) {
      return "${phone.substring(0, 5)}*****";
    }
    return phone;
  }
}
