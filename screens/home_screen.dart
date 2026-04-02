import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/services/checkin_service.dart';
import 'package:flutter_application_1/screens/history_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String locationText = 'Fetching location...';
  double? currentLatitude;
  double? currentLongitude;
  
  int totalPoints = 0; 
  bool isAtFair = false; 

  
  Map<String, dynamic>? selectedFair;
 
  double? distanceToSelected;

  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> fairLocations = [
    {'name': 'Southern UC Career Fair', 'lat': 1.533161, 'lng': 103.679852, 'points': 50},
    {'name': 'Paradigm Mall Fair', 'lat': 1.5152, 'lng': 103.6817, 'points': 60},
    {'name': 'Lotus Setia Tropika Fair', 'lat': 1.5435, 'lng': 103.7064, 'points': 40},
    {'name': 'Sutera Mall Fair', 'lat': 1.5178, 'lng': 103.6681, 'points': 70},
  ];

  static const double allowedRadius = 500;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      final address = await locationService.getAddressFromCoordinates(position);

      double minDistance = double.infinity;
      Map<String, dynamic>? closestFair;

  
      for (var fair in fairLocations) {
        final distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, fair['lat'], fair['lng'],
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestFair = fair;
        }
      }

      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
        locationText = address; 
        selectedFair = closestFair; 
        distanceToSelected = minDistance; 
        isAtFair = minDistance <= allowedRadius; 
      });

      _mapController.move(LatLng(position.latitude, position.longitude), 14.0);

    } catch (e) {
      setState(() {
        locationText = "Error getting location. Ensure services are enabled.";
        isAtFair = false;
      });
    }
  }

  void _selectFair(Map<String, dynamic> fair) {
    if (currentLatitude == null || currentLongitude == null) return;
    
   
    final distance = Geolocator.distanceBetween(
      currentLatitude!, currentLongitude!, fair['lat'], fair['lng'],
    );
    
    setState(() {
      selectedFair = fair;
      distanceToSelected = distance;
      isAtFair = distance <= allowedRadius;
    });

    _mapController.move(LatLng(fair['lat'], fair['lng']), 15.0);
  }

 
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.toStringAsFixed(0)} m";
    } else {
      return "${(meters / 1000).toStringAsFixed(2)} km";
    }
  }

  Future<void> checkIn() async {
    if (currentLatitude == null || currentLongitude == null || selectedFair == null) return;

    if (isAtFair) {
      await CheckInService.addCheckIn(selectedFair!['name'], selectedFair!['points']); 
      setState(() {
        totalPoints += selectedFair!['points'] as int; 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text("Successfully joined ${selectedFair!['name']}!"))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text("Check-In Unsuccessful: Outside Allowed Area"))),
      );
    }
  }

  Widget _buildCustomButton({required String text, required VoidCallback? onPressed, Color color = Colors.blue}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        minimumSize: const Size(200, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Career Fair Tracker"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text("Points: $totalPoints", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 上半部分：地图
          Expanded(
            flex: 5,
            child: currentLatitude == null || currentLongitude == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(currentLatitude!, currentLongitude!),
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.example.internship_prog2033',
                      ),
                    
                      if (selectedFair != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(selectedFair!['lat'], selectedFair!['lng']),
                              radius: allowedRadius,
                              color: Colors.blue.withOpacity(0.2),
                              borderStrokeWidth: 2,
                              borderColor: Colors.blue,
                              useRadiusInMeter: true,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                         
                          ...fairLocations.map((fair) {
                            bool isSelected = selectedFair != null && selectedFair!['name'] == fair['name'];
                            return Marker(
                              point: LatLng(fair['lat'], fair['lng']),
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () => _selectFair(fair), 
                                child: Icon(
                                  Icons.store,
                                  
                                  color: isSelected ? Colors.orange : Colors.blue, 
                                  size: isSelected ? 45 : 30, 
                                ),
                              ),
                            );
                          }).toList(),
                          
                         
                          Marker(
                            point: LatLng(currentLatitude!, currentLongitude!),
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

         
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(locationText, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                  const Divider(),
                  
                
                  Text(
                    selectedFair?['name'] ?? 'Please select a fair', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  
               
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Reward: ${selectedFair?['points'] ?? 0} pts", 
                        style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(width: 20),
                      if (distanceToSelected != null)
                        Text(
                          "Distance: ${_formatDistance(distanceToSelected!)}", 
                          style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w600)
                        ),
                    ],
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isAtFair ? Icons.check_circle : Icons.cancel, color: isAtFair ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        isAtFair ? "Status: At Fair" : "Status: Not At Fair",
                        style: TextStyle(color: isAtFair ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCustomButton(
                        text: 'Join Fair', 
                        onPressed: isAtFair ? checkIn : null,
                        color: isAtFair ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _getLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh Location"),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                        icon: const Icon(Icons.history),
                        label: const Text("View History"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
