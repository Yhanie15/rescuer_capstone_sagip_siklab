import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'navigation_service.dart';
import 'package:url_launcher/url_launcher.dart';  


class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _fireLocationController = TextEditingController();

  LatLng? _currentLocation;
  LatLng? fireLocation;
  List<LatLng> routePoints = [];
  List<dynamic> routeSteps = [];
  StreamSubscription<Position>? _positionStream;

  String distance = "";
  String duration = "";
  String currentInstruction = "";
  bool isNavigating = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _fireLocationController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    final locationOptions = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationOptions).listen(
      (Position position) {
        final LatLng newLocation = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = newLocation;
          if (isNavigating) {
            _mapController.move(newLocation, 16.0);
          }
        });

        _checkNextTurn(position);
      },
      onError: (e) {
        print("Error fetching location: $e");
      },
    );
  }

  void _recenterMap() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location not available")),
      );
    }
  }

  Future<void> _fetchCoordinates(String address) async {
    final accessToken = "your-mapbox-access-token";
    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/$address.json?access_token=pk.eyJ1IjoieWhhbmllMTUiLCJhIjoiY2x5bHBrenB1MGxmczJpczYxbjRxbGxsYSJ9.DPO8TGv3Z4Q9zg08WhfoCQ";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'];
        setState(() {
          fireLocation = LatLng(coordinates[1], coordinates[0]);
          _mapController.move(fireLocation!, 16.0);
        });
        await _fetchRouteToFire();
      } else {
        print("Failed to fetch coordinates: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching coordinates: $e");
    }
  }

  Future<void> _fetchRouteToFire() async {
    if (_currentLocation == null || fireLocation == null) {
      print("Current or fire location not available.");
      return;
    }

    final accessToken = "your-mapbox-access-token";
    final url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${fireLocation!.longitude},${fireLocation!.latitude}?geometries=geojson&steps=true&access_token=pk.eyJ1IjoieWhhbmllMTUiLCJhIjoiY2x5bHBrenB1MGxmczJpczYxbjRxbGxsYSJ9.DPO8TGv3Z4Q9zg08WhfoCQ";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'] as List;
        final steps = data['routes'][0]['legs'][0]['steps'];
        final routeDistance = data['routes'][0]['distance'] / 1000;
        final routeDuration = data['routes'][0]['duration'] / 60;

        setState(() {
          routePoints = geometry
              .map((point) => LatLng(point[1], point[0]))
              .toList();
          routeSteps = steps;
          distance = "${routeDistance.toStringAsFixed(1)} km";
          duration = "${routeDuration.toStringAsFixed(1)} mins";
          isNavigating = true;
        });
      } else {
        print("Failed to fetch route: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  void _checkNextTurn(Position position) {
    if (routeSteps.isNotEmpty) {
      final nextStep = routeSteps[0];
      final nextLatLng = LatLng(
        nextStep['maneuver']['location'][1],
        nextStep['maneuver']['location'][0],
      );
      final distanceToNextTurn = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        nextLatLng.latitude,
        nextLatLng.longitude,
      );

      setState(() {
        currentInstruction = nextStep['maneuver']['instruction'];
      });

      if (distanceToNextTurn < 30.0) {
        _tts.speak(currentInstruction);
        routeSteps.removeAt(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 224, 51, 39),
        title: const Text("Real-Time Navigation"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _recenterMap,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: const Text("Navigation Menu", style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Map"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text("Report"),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(14.676041, 121.043700),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoieWhhbmllMTUiLCJhIjoiY2x5bHBrenB1MGxmczJpczYxbjRxbGxsYSJ9.DPO8TGv3Z4Q9zg08WhfoCQ",
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.location_pin, color: Colors.blue, size: 50),
                    ),
                    if (fireLocation != null)
                      Marker(
                        point: fireLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.local_fire_department, color: Colors.red, size: 50),
                      ),
                  ],
                ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: routePoints, color: Colors.blue, strokeWidth: 5.0),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _fireLocationController,
                      decoration: const InputDecoration(
                        hintText: "Enter fire location (e.g., address)",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) => _fetchCoordinates(value),
                    ),
                    Row(
                      children: [
                    ElevatedButton(
  onPressed: () async {
    if (_currentLocation != null && fireLocation != null) {
      final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
        '&destination=${fireLocation!.latitude},${fireLocation!.longitude}'
        '&travelmode=driving'
        '&dir_action=navigate'
      );

      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location information is incomplete')),
      );
    }
  },
  child: const Text("Get Direction"),
),


                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isNavigating)
            Positioned(
              top: 100,
              left: 10,
              right: 10,
              child: Card(
                color: Colors.white,
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        "Next Instruction: $currentInstruction",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Distance: $distance"),
                          Text("Duration: $duration"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
