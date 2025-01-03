import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool isDarkTheme = false; // Toggle for theme
  late AnimationController _animationController;

  String? email;
  String? stationName;
  String? truckNumber;
  String? plateNumber;
  String? exactLocation;
  String? rescuerId;
  String? assignedDistrict;
  String? assignedBarangay;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fetchProfileDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileDetails() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _database.child('rescuer/${user.uid}').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          email = user.email;
          stationName = data['stationName'] ?? 'Unknown';
          truckNumber = data['truckNumber'] ?? 'Unknown';
          plateNumber = data['plateNumber'] ?? 'Unknown';
          exactLocation = data['exactLocation'] ?? 'Unknown';
          rescuerId = data['rescuerID'] ?? 'Unknown';
          assignedDistrict = data['assignedDistrict'] ?? 'Unknown';
          assignedBarangay = data['assignedBarangay'] ?? 'Unknown';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.light,
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark,
        cardColor: Colors.grey.shade800,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
          elevation: 4,
          backgroundColor: isDarkTheme
              ? Colors.grey.shade900
              : const Color.fromARGB(255, 255, 255, 255),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Switch(
                  value: isDarkTheme,
                  onChanged: (value) {
                    setState(() {
                      isDarkTheme = value;
                      value
                          ? _animationController.forward()
                          : _animationController.reverse();
                    });
                  },
                  activeColor: Colors.white,
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDarkTheme
                      ? Colors.grey.shade900
                      : const Color.fromARGB(255, 114, 9, 4),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          isDarkTheme ? Colors.grey.shade800 : const Color.fromARGB(255, 243, 243, 243),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: isDarkTheme
                            ? Colors.grey.shade400
                            : const Color.fromARGB(255, 105, 13, 7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      email ?? 'Loading...',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.grey.shade300 : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Rescuer ID: ${rescuerId ?? 'Loading...'}",
                      style: TextStyle(
                        color: isDarkTheme ? Colors.grey.shade300 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profile Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildProfileCard("Station Name", stationName ?? 'Loading...'),
                    _buildProfileCard("Truck Number", truckNumber ?? 'Loading...'),
                    _buildProfileCard("Plate Number", plateNumber ?? 'Loading...'),
                    _buildProfileCard(
                        "Exact Location", exactLocation ?? 'Loading...'),
                    _buildProfileCard("District", assignedDistrict ?? 'Loading...'),
                    _buildProfileCard("Barangay", assignedBarangay ?? 'Loading...'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 235, 61, 42),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.grey.shade300 : Colors.black54,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isDarkTheme ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
