import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapPickerScreen({Key? key, required this.initialPosition}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng selectedPosition;
  TextEditingController searchController = TextEditingController();
  TextEditingController latController = TextEditingController();
  TextEditingController lonController = TextEditingController();
  final String mapboxAccessToken = "pk.eyJ1IjoieWhhbmllMTUiLCJhIjoiY2x5bHBrenB1MGxmczJpczYxbjRxbGxsYSJ9.DPO8TGv3Z4Q9zg08WhfoCQ"; // Replace with your actual Mapbox access token
  List<Map<String, dynamic>> searchResults = [];
  final MapController mapController = MapController(); // To control map movements

  final Map<String, LatLng> predefinedLocations = {
    "New York": LatLng(40.7128, -74.0060),
    "Los Angeles": LatLng(34.0522, -118.2437),
    "London": LatLng(51.5074, -0.1278),
    "Tokyo": LatLng(35.6895, 139.6917),
    "Sydney": LatLng(-33.8688, 151.2093),
  };

  String? selectedLocationName;

  @override
  void initState() {
    super.initState();
    selectedPosition = widget.initialPosition;
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=$mapboxAccessToken&limit=5";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          searchResults = (data['features'] as List)
              .map((feature) => {
                    'name': feature['place_name'],
                    'coordinates': feature['geometry']['coordinates'],
                  })
              .toList();
        });
      } else {
        print("Failed to fetch location: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  void searchByCoordinates() {
    final String latText = latController.text.trim();
    final String lonText = lonController.text.trim();

    if (latText.isEmpty || lonText.isEmpty) return;

    try {
      final double latitude = double.parse(latText);
      final double longitude = double.parse(lonText);
      moveToLocation(LatLng(latitude, longitude));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid coordinates! Please enter valid numbers.")),
      );
    }
  }

  void moveToLocation(LatLng location) {
    setState(() {
      selectedPosition = location;
      searchResults.clear(); // Clear search results after selecting
    });

    // Move the map to the selected location
    mapController.move(location, 16.0); // Adjust zoom level if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a Location'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController, // Attach map controller
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 16.0,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedPosition = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedPosition,
                    width: 80.0,
                    height: 80.0,
                    child: const Icon(Icons.location_pin, color: Colors.blue, size: 50),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search location...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: searchLocation,
                ),
                const SizedBox(height: 5),
                if (searchResults.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final result = searchResults[index];
                        return ListTile(
                          title: Text(result['name']),
                          onTap: () {
                            final coordinates = result['coordinates'];
                            moveToLocation(LatLng(coordinates[1], coordinates[0]));
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        decoration: InputDecoration(
                          hintText: "Latitude",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        controller: lonController,
                        decoration: InputDecoration(
                          hintText: "Longitude",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: searchByCoordinates,
                      child: const Text("Go"),
                    ),
                  ],
                ),
               
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, selectedPosition);
        },
        label: const Text('Confirm Location'),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
