//DB table
// INSTITUTION {
//         Long id PK
//         String name
//         String region
//         String contact_info
//         Boolean is_active "Soft delete"
//     }

class Institution {
  final String id;
  final String name;
  final String region;
  final String contactInfo;
  final bool isActive;

  Institution({
    required this.id,
    required this.name,
    required this.region,
    required this.contactInfo,
    required this.isActive,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'],
      name: json['name'],
      region: json['region'],
      contactInfo: json['contact_info'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'contact_info': contactInfo,
      'is_active': isActive,
    };
  }
}
