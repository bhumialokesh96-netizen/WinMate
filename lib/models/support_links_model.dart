class SupportLinksModel {
  final String id;
  final String? whatsappLink;
  final String? telegramLink;
  final String? email;
  final String? phone;
  final String? website;
  final DateTime updatedAt;

  SupportLinksModel({
    required this.id,
    this.whatsappLink,
    this.telegramLink,
    this.email,
    this.phone,
    this.website,
    required this.updatedAt,
  });

  // Factory: Create SupportLinks from JSON (Database Row)
  factory SupportLinksModel.fromJson(Map<String, dynamic> json) {
    return SupportLinksModel(
      id: json['id'],
      whatsappLink: json['whatsapp_link'],
      telegramLink: json['telegram_link'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  // Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'whatsapp_link': whatsappLink,
      'telegram_link': telegramLink,
      'email': email,
      'phone': phone,
      'website': website,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Check if WhatsApp is available
  bool get hasWhatsApp => whatsappLink != null && whatsappLink!.isNotEmpty;

  // Check if Telegram is available
  bool get hasTelegram => telegramLink != null && telegramLink!.isNotEmpty;

  // Check if email is available
  bool get hasEmail => email != null && email!.isNotEmpty;

  // Check if phone is available
  bool get hasPhone => phone != null && phone!.isNotEmpty;

  // Check if website is available
  bool get hasWebsite => website != null && website!.isNotEmpty;
}
