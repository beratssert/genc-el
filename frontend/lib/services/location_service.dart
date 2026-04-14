import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tdp_frontend/repositories/user_repo.dart';
import 'package:tdp_frontend/services/storage_service.dart';
import 'package:tdp_frontend/models/user.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref);
});

class LocationService {
  final Ref _ref;
  StreamSubscription<Position>? _positionSubscription;

  LocationService(this._ref);

  /// Starts tracking the user's location if they are a Student or Elderly user.
  Future<void> startTrackingIfStudent() async {
    final storage = _ref.read(storageServiceProvider);
    final role = await storage.getRole();

    // Track location for both Student and Elderly users
    if (role != Role.STUDENT.name && role != Role.ELDERLY.name) {
      debugPrint(
        'LocationService: User role is $role, location tracking not applicable.',
      );
      return;
    }

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'LocationService: Location permissions are permanently denied.',
      );
      return;
    }

    // Start listening for position updates
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 50, // Update every 50 meters
          ),
        ).listen((Position position) {
          _updateBackendLocation(position);
        });

    debugPrint('LocationService: Started tracking location for role: $role');
  }

  Future<void> _updateBackendLocation(Position position) async {
    // TEST MOCK: Akdeniz Üniversitesi Camii
    // const double mockLat = 36.8920;
    // const double mockLon = 30.6558;

    try {
      final userRepo = _ref.read(userRepoProvider);
      await userRepo.updateLocation(position.latitude, position.longitude);
      debugPrint(
        // 'LocationService [MOCK]: Updated backend with Akdeniz Camii lat: $mockLat, lon: $mockLon',
        'LocationService: Updated backend with lat: ${position.latitude}, lon: ${position.longitude}',
      );
    } catch (e) {
      debugPrint('LocationService: Error updating backend location: $e');
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('LocationService: Stopped tracking.');
  }
}
