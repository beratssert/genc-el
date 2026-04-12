/// Backend `InstitutionResponse` DTO ile birebir uyumlu model.
class Institution {
  final String id;
  final String name;
  final String? region;
  final String? contactInfo;
  final bool isActive;
  final DateTime? createdAt;

  Institution({
    required this.id,
    required this.name,
    this.region,
    this.contactInfo,
    this.isActive = true,
    this.createdAt,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      region: json['region'],
      contactInfo: json['contactInfo'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'region': region,
      'contactInfo': contactInfo,
    };
  }
}
