import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

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
    _fetchProfileDetails();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color.fromARGB(255, 241, 51, 37),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profile Details",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileDetailRow("Email", email ?? 'Loading...'),
            _buildProfileDetailRow("Station Name", stationName ?? 'Loading...'),
            _buildProfileDetailRow("Truck Number", truckNumber ?? 'Loading...'),
            _buildProfileDetailRow("Plate Number", plateNumber ?? 'Loading...'),
            _buildProfileDetailRow("Exact Location", exactLocation ?? 'Loading...'),
            _buildProfileDetailRow("Rescuer ID", rescuerId ?? 'Loading...'),
            _buildProfileDetailRow("District", assignedDistrict ?? 'Loading...'),
            _buildProfileDetailRow("Barangay", assignedBarangay ?? 'Loading...'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _auth.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 241, 51, 37),
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
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
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
