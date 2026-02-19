//DB table
// USER {
//         Long id PK
//         Long institution_id FK
//         String role "ELDERLY, STUDENT, ADMIN"
//         String first_name
//         String last_name
//         String phone_number
//         String address
//         Double latitude
//         Double longitude
//         Boolean is_active "Soft delete"
//         String iban "For Students"
//     }

enum Role {
  elderly,
  student,
  institutionAdmin;

  static Role fromString(String role) {
    return Role.values.firstWhere((e) => e.name == role);
  }
}

class User {
  final String id;
  final String institutionId;
  final Role role;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String address;
  final double latitude;
  final double longitude;
  final bool isActive;
  final String iban;

  User({
    required this.id,
    required this.institutionId,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.iban,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      institutionId: json['institution_id'],
      role: Role.fromString(json['role']),
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isActive: json['is_active'],
      iban: json['iban'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institution_id': institutionId,
      'role': role.name,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'iban': iban,
    };
  }
}
