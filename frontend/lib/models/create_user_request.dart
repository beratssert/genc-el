import 'package:tdp_frontend/models/user.dart';

class CreateUserRequest {
  final Role role;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String password;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? iban;

  CreateUserRequest({
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.address,
    this.latitude,
    this.longitude,
    this.iban,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'password': password,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (iban != null) 'iban': iban,
    };
  }
}
