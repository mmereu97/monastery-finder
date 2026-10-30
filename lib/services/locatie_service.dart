// lib/services/locatie_service.dart

import 'package:geolocator/geolocator.dart';

class LocatieService {
  static Future<Position?> getPozitie() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permisiune = await Geolocator.checkPermission();
    if (permisiune == LocationPermission.denied) {
      permisiune = await Geolocator.requestPermission();
      if (permisiune == LocationPermission.denied) return null;
    }
    if (permisiune == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}
