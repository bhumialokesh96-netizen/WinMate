class WheelPrizeModel {
  final String id;
  final String name;
  final String type; // 'cash', 'spin', 'bonus'
  final double value;
  final double probability; // 0-100
  final String color; // Hex color code
  final String? icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WheelPrizeModel({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.probability,
    required this.color,
    this.icon,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory: Create WheelPrize from JSON (Database Row)
  factory WheelPrizeModel.fromJson(Map<String, dynamic> json) {
    return WheelPrizeModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      value: (json['value'] ?? 0.0).toDouble(),
      probability: (json['probability'] ?? 0.0).toDouble(),
      color: json['color'] ?? '#00C853',
      icon: json['icon'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'probability': probability,
      'color': color,
      'icon': icon,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Check if prize type is cash
  bool get isCash => type == 'cash';

  // Check if prize type is spin
  bool get isSpin => type == 'spin';

  // Check if prize type is bonus
  bool get isBonus => type == 'bonus';

  // Get display text for the prize
  String get displayText {
    if (isCash) {
      return '₹${value.toStringAsFixed(0)}';
    } else if (isSpin) {
      return '${value.toInt()} Spins';
    } else {
      return '${value.toInt()}x Bonus';
    }
  }
}
