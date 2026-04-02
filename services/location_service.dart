import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart' as geocoding;



class LocationService {
  
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return geolocator.Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// STEP 1: Check and request permission
  Future<void> _checkPermission() async {
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();

    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }
  }

  /// STEP 2: Get current position
  Future<geolocator.Position> getCurrentLocation() async {
    await _checkPermission();

    return await geolocator.Geolocator.getCurrentPosition(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
      ),
    );
  }

  /// STEP 3: Convert coordinates → readable address
  Future<String> getAddressFromCoordinates(geolocator.Position position) async {
    try {
      // Validate coordinates
      if (position.latitude == 0 && position.longitude == 0) {
        return "Invalid coordinates";
      }

      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return "Unknown location";
      }

      final place = placemarks.first;

      // Build readable address
      return _formatAddress(place);

    } catch (e) {
      return "Address unavailable";
    }
  }

  /// STEP 4: Format address (clean output)
  String _formatAddress(geocoding.Placemark place) {
    return [
      place.name,
      place.locality,
      place.administrativeArea,
      place.country
    ]
      .whereType<String>() 
        .where((element) => element.isNotEmpty)
        .join(", ");
  }

  /// STEP 5: Combined method (optional helper)
  Future<Map<String, dynamic>> getFullLocationData() async {
    final position = await getCurrentLocation();

    final address = await getAddressFromCoordinates(position);

    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "address": address,
    };
  }
}
