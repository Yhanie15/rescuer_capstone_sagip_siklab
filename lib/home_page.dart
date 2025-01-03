
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rescuer_capstone_sagip_siklab/login_screen.dart';
import 'package:rescuer_capstone_sagip_siklab/profile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'animated_siren.dart';
import 'package:slidable_button/slidable_button.dart';
import 'fire_resolved_screen.dart';
import 'history_screen.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer(); // For sound alert

  bool _isSirenVisible = false; // Toggles the siren visibility
  Timer? _sirenTimer; // Timer for siren animation
  bool isAlerting = false; // Indicates if dispatch alert is active
  bool _isRedBackground = false; // For blinking background
  Timer? _blinkTimer; // Timer for background blinking

  LatLng? _currentLocation;
  LatLng? fireLocation;
  List<LatLng> routePoints = [];
  List<dynamic> routeSteps = [];
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DatabaseEvent>? _firebaseDispatchListener;

  String? rescuerId; // Dynamically fetched rescuerId
  String distance = "";
  String duration = "";
  String currentInstruction = "";
  bool isNavigating = false;
  bool showSlidableButton = false;
  bool showRoute = false;

  @override
  void initState() {
    super.initState();
    _fetchRescuerId(); // Fetch rescuerId dynamically
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _firebaseDispatchListener?.cancel(); // Cancel Firebase listener
    _fireLocationController.dispose();
    _stopSoundAlert(); // Ensure sound is stopped
    _stopBlinkingBackground(); // Ensure blinking is stopped
    super.dispose();
  }

  Future<void> _playSoundAlert() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('alert.mp3')); // Add alert.mp3 to assets
  }

  Future<void> _stopSoundAlert() async {
    await _audioPlayer.stop();
  }

  void _startBlinkingBackground() {
    setState(() {
      isAlerting = true;
    });

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _isRedBackground = !_isRedBackground;
      });
    });
  }

  void _stopBlinkingBackground() {
    _blinkTimer?.cancel();
    setState(() {
      isAlerting = false;
      _isRedBackground = false;
    });
  }

  void _startSirenAnimation() {
    setState(() {
      _isSirenVisible = true; // Make the siren visible
    });
  }

  void _stopSirenAnimation() {
    setState(() {
      _isSirenVisible = false; // Hide the siren
    });
  }

  void _triggerDispatchAlert() {
    if (!isAlerting) { // Check if not already alerting
      _playSoundAlert();
      _startBlinkingBackground();
      _startSirenAnimation();
      setState(() {
        isAlerting = true; // Set to true when alert starts
      });
    }
  }

  Future<void> _fetchRescuerId() async {
    final User? user = FirebaseAuth.instance.currentUser; // Get signed-in user

    if (user != null) {
      setState(() {
        rescuerId = user.uid; // Use Firebase UID as rescuerId
      });
      print("Rescuer ID Fetched: $rescuerId");
      _listenForDispatchUpdates(); // Start listening for updates after fetching rescuerId
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is signed in.')),
      );
    }
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

       
      },
      onError: (e) {
        print("Error fetching location: $e");
      },
    );
  }

  void _listenForDispatchUpdates() {
    if (rescuerId == null) {
      print("Rescuer ID is not available.");
      return;
    }

    final DatabaseReference dispatchRef =
        FirebaseDatabase.instance.ref('dispatches'); // Firebase path

    _firebaseDispatchListener = dispatchRef.onValue.listen((DatabaseEvent event) {
      print("Firebase Listener Triggered");

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        data.forEach((key, dispatch) {
          print("Dispatch Data: $dispatch");
          if (dispatch['rescuerID'] == rescuerId && dispatch['status'] == "Dispatching") {
            print("Dispatch Matched for Rescuer: $key");
            _showDispatchNotification(dispatch, key);
          } else {
            print("No match for rescuerID or status.");
          }
        });
      } else {
        print("No data in dispatches node.");
      }
    });
  }

  void _showDispatchNotification(Map<dynamic, dynamic> dispatch, String dispatchKey) {
  if (!mounted) return;
  final String location = dispatch['location'] ?? "Unknown location";
  final String dispatchTime = dispatch['dispatchTime'] ?? "Unknown time";

  _triggerDispatchAlert(); // Start sound and blinking when dispatch received

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent the dialog from being dismissed by tapping outside
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: const Color.fromRGBO(255, 234, 234, 1),
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 10),
          Text(
            'Dispatch Notification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You have been dispatched to:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 10),
          Text(
            location,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dispatch Time:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 10),
          Text(
            dispatchTime,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            _stopSirenAnimation();
            _stopSoundAlert(); // Stop sound
            _stopBlinkingBackground(); // Stop blinking background
            await _updateDispatchStatus(dispatchKey, "Dispatched"); // Update dispatch status

            Navigator.of(context).pop(); // Close the dialog

            // Show route and slidable button
            setState(() {
              isNavigating = true; // Show the route
              showSlidableButton = true; // Show the slidable button
            });

            // Fetch and display the route
            await _setFireLocation(location);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Accept',
            style: TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            _stopSirenAnimation();
            _stopSoundAlert(); // Stop sound
            _stopBlinkingBackground(); // Stop blinking background
            await _updateDispatchStatus(dispatchKey, "Rejected"); // Update dispatch status
            Navigator.of(context).pop(); // Close the dialog
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Reject',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}


  /// Updates the status of a dispatch in the 'dispatches' table and
  /// ensures that the corresponding 'reports_image' entries inherit the same status.
  Future<void> _updateDispatchStatus(String dispatchKey, String status) async {
  try {
    // Update the status in the 'dispatches' table
    final DatabaseReference dispatchRef =
        FirebaseDatabase.instance.ref('dispatches/$dispatchKey');
    await dispatchRef.update({"status": status});
    print("Dispatch $dispatchKey status updated to $status.");

    // Now, update the 'reports_image' table
    final DatabaseReference reportsImageRef =
        FirebaseDatabase.instance.ref('reports_image');

    // Query 'reports_image' entries where 'dispatchID' equals 'dispatchKey'
    final Query query = reportsImageRef.orderByChild('dispatchID').equalTo(dispatchKey);
    final DatabaseEvent snapshot = await query.once();

    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      for (var key in data.keys) {
        await reportsImageRef.child(key).update({"status": status});
        print("reports_image entry $key status updated to $status.");
      }
    } else {
      print("No reports_image entries found for dispatchID: $dispatchKey.");
      // Optionally, notify the user or take alternative actions
    }
  } catch (e) {
    print("Error updating dispatch and reports_image status: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error updating status: $e")),
    );
  }
}



  Future<void> _setFireLocation(String location) async {
    final accessToken = "your-mapbox-access-token"; // Replace with your Mapbox access token
    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(location)}.json?access_token=pk.eyJ1IjoieWhhbmllMTUiLCJhIjoiY2x5bHBrenB1MGxmczJpczYxbjRxbGxsYSJ9.DPO8TGv3Z4Q9zg08WhfoCQ";

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
        print("Failed to fetch fire location: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching fire location: $e");
    }
  }

  Future<void> _fetchRouteToFire() async {
    if (_currentLocation == null || fireLocation == null) {
      print("Current or fire location not available.");
      return;
    }

    final accessToken = "pk.eyJ1IjoieWhhbmllMTUiLCJhIjoiY2x5bHBrenB1MGxmczJpczYxbjRxbGxsYSJ9.DPO8TGv3Z4Q9zg08WhfoCQ"; // Replace with your Mapbox access token
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

  void _recenterMap() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0); // Re-centers the map on the current location
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location not available")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isAlerting && _isRedBackground
          ? Colors.red.withAlpha(128)
          : const Color.fromARGB(255, 30, 21, 21),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 224, 51, 39),
        title: const Text("SAGIP : SIKLAB"),
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
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)], // Gradient for a sleek design
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: FutureBuilder(
    future: FirebaseDatabase.instance
        .ref('rescuer/${FirebaseAuth.instance.currentUser?.uid}')
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      } else if (snapshot.hasError) {
        return const Center(
          child: Text(
            "Error fetching data",
            style: TextStyle(color: Colors.white),
          ),
        );
      } else if (snapshot.hasData && snapshot.data!.exists) {
        final data = snapshot.data?.value as Map<dynamic, dynamic>;
        final fireStationName = data['stationName'] ?? "Unknown Station";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/logo.png', // Replace with your "logo.png" path
                  height: 60,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),
                Image.asset(
                  'assets/text.png', // Replace with your "text.png" path
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              fireStationName, // Display dynamic fire station name
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      } else {
        return const Center(
          child: Text(
            "No data available",
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    },
  ),
),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("History"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(), // Navigate to the history screen
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text("Report"),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FireResolvedScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Logout failed: $e")),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ??
                  const LatLng(14.676041, 121.043700),
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
                      child: const Icon(Icons.location_pin,
                          color: Colors.blue, size: 50),
                    ),
                    if (fireLocation != null)
                      Marker(
                        point: fireLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.local_fire_department,
                            color: Colors.red, size: 50),
                      ),
                  ],
                ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                        points: routePoints,
                        color: Colors.blue,
                        strokeWidth: 5.0),
                  ],
                ),
            ],
          ),
          // Animated Siren Positioned
          if (_isSirenVisible)
            const Positioned(
              top: 10, // Adjust position as needed
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSiren(), // Replace with your AnimatedSiren widget
              ),
            ),
          // Slidable Button displayed at the top when showSlidableButton is true
          if (showSlidableButton)
            Positioned(
              top: 10, // Adjust position to be at the top of the screen
              left: 10,
              right: 10,
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: HorizontalSlidableButton(
                    width: MediaQuery.of(context).size.width * 0.75,
                    buttonWidth: 60,
                    color: Colors.grey.shade300,
                    buttonColor: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                    label: const Center(
                      child: Text(
                        "Slide to Resolve Fire",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ),
                    onChanged: (position) async {
                      if (position == SlidableButtonPosition.end) {
                        setState(() {
                          // Reset all variables to the initial state
                          fireLocation = null;
                          routePoints.clear();
                          isNavigating = false;
                          showSlidableButton = false;
                          showRoute = false;
                          distance = "";
                          duration = "";
                          currentInstruction = "";
                        });

                        try {
                          // Update the dispatch status to "resolved" using the centralized method
                          final DatabaseReference dispatchRef =
                              FirebaseDatabase.instance.ref('dispatches');
                          final Query query = dispatchRef
                              .orderByChild('rescuerID')
                              .equalTo(rescuerId);

                          final DataSnapshot snapshot = await query.get();
                          if (snapshot.exists) {
                            Map<dynamic, dynamic>? dispatches =
                                snapshot.value as Map?;
                            if (dispatches != null) {
                              for (var entry in dispatches.entries) {
                                if (entry.value['status'] == "Dispatched") {
                                  // Use the centralized method to update status
                                  await _updateDispatchStatus(
                                      entry.key, 'Resolved');
                                  break; // Update only the first matching dispatch
                                }
                              }
                            }
                          }
                        } catch (e) {
                          // Handle any errors during the database update
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error updating status: $e")),
                          );
                        }

                        // Navigate to the Fire Resolved screen
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const FireResolvedScreen(), // Navigate to the fire resolved screen
                          ),
                        )
                            .then((_) {
                          // Ensure the app returns to the initial state after coming back
                          setState(() {
                            fireLocation = null;
                            routePoints.clear();
                            isNavigating = false;
                            showSlidableButton = false;
                            showRoute = false;
                          });
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          // Get Directions button
          Positioned(
            bottom: 20, // Positioned near the bottom of the screen
            left: 20,
            right: 20,
            child: Card(
              elevation: 8.0, // Shadow for the card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Padding for spacing
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_currentLocation != null && fireLocation != null) {
                      final Uri googleMapsUri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1'
                        '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
                        '&destination=${fireLocation!.latitude},${fireLocation!.longitude}'
                        '&travelmode=driving'
                        '&dir_action=navigate',
                      );

                      if (await canLaunchUrl(googleMapsUri)) {
                        await launchUrl(
                          googleMapsUri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not launch Google Maps')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Location information is incomplete')),
                      );
                    }
                  },
                  icon: const Icon(Icons.directions), // Add a navigation icon
                  label: const Text(
                    "Get Directions",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 241, 51, 37), // Consistent theme color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Rounded corners for the button
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0), // Increased button height
                  ),
                ),
              ),
            ),
          ),
          // Navigation instructions (if navigating)
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