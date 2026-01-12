class FaqModel {
  final String id;
  final String category;
  final String question;
  final String answer;
  final int priority;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FaqModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.priority,
    required this.isVisible,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory: Create FAQ from JSON (Database Row)
  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'],
      category: json['category'],
      question: json['question'],
      answer: json['answer'],
      priority: json['priority'] ?? 100,
      isVisible: json['is_visible'] ?? true,
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
      'category': category,
      'question': question,
      'answer': answer,
      'priority': priority,
      'is_visible': isVisible,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
