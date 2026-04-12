/// Backend UserRole enum (camelCase uyumlu)
enum Role {
  ELDERLY,
  STUDENT,
  INSTITUTION_ADMIN,
  SYSTEM_ADMIN;

  static Role fromString(String role) {
    return Role.values.firstWhere(
      (e) => e.name == role,
      orElse: () => Role.ELDERLY,
    );
  }
}

/// Backend `UserResponse` DTO ile birebir uyumlu model.
class User {
  final String id;
  final String? institutionId;
  final Role role;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final String? iban;
  final DateTime? createdAt;

  User({
    required this.id,
    this.institutionId,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.iban,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  /// Backend JSON camelCase formatına uygun parser.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      institutionId: json['institutionId']?.toString(),
      role: Role.fromString(json['role'] ?? 'ELDERLY'),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isActive: json['isActive'] ?? true,
      iban: json['iban'],
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is List && value.length >= 3) {
      // Handle Spring Boot [year, month, day, ...] format
      try {
        return DateTime(
          value[0] as int,
          value[1] as int,
          value[2] as int,
          value.length > 3 ? value[3] as int : 0,
          value.length > 4 ? value[4] as int : 0,
          value.length > 5 ? (value[5] as num).toInt() : 0,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionId': institutionId,
      'role': role.name,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'iban': iban,
    };
  }
}
