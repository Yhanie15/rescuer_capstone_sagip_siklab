import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';
import 'login_screen.dart';

const Map<String, List<String>> districtsAndBarangays = {
  'District 1': [
    'Alicia', 'Bagong Pagasa', 'Bahay Toro', 'Balingasa', 'Bungad', 'Damar', 'Damayan',
    'Del Monte', 'Katipunan', 'Lourdes', 'Maharlika', 'Manresa', 'Mariblo', 'Masambong',
    'N.S. Amoranto', 'Nayon Kanluran', 'Paang Bundok', 'Pag-ibig sa Nayon', 'Paltok',
    'Paraiso', 'Phil-Am', 'Project 6', 'R. Magsaysay', 'Salvacion', 'San Antonio',
    'San Isidro Labrador', 'San Jose', 'Sienna', 'St. Peter', 'Sta. Cruz', 'Sta. Teresita',
    'Sto. Cristo', 'Sto. Domingo', 'Talayan', 'Vasra', 'Veterans Village', 'West Triangle'
  ],
  'District 2': [
    'Bagong Silangan', 'Batasan Hills', 'Commonwealth', 'Holy Spirit', 'Payatas'
  ],
  'District 3': [
    'Amihan', 'Bagumbayan', 'Bagumbuhay', 'Bayanihan', 'Blue Ridge A', 'Blue Ridge B',
    'Camp Aguinaldo', 'Claro', 'Dioquino Zobel', 'Duyan-duyan', 'E. Rodriguez',
    'East Kamias', 'Escopa 1', 'Escopa 2', 'Escopa 3', 'Escopa 4', 'Libis', 'Loyola Heights',
    'Manga', 'Marilag', 'Masagana', 'Matandang Balara', 'Milagrosa', 'Pansol',
    'Quirino 2-A', 'Quirino 2-B', 'Quirino 2-C', 'Quirino 3-A', 'San Roque', 'Silangan',
    'Socorro', 'St. Ignatius', 'Tagumpay', 'Ugong Norte', 'Villa Maria Clara', 'West Kamias',
    'White Plains'
  ],
  'District 4': [
    'B.L. ng Crame', 'Botocan', 'Central', 'Damar', 'Doña Aurora', 'Doña Imelda',
    'Doña Josefa', 'Horseshoe', 'Immaculate Concepcion', 'Kalusugan', 'Kamuning',
    'Kaunlaran', 'Kristong Hari', 'Krus na Ligas', 'Laging Handa', 'Malaya', 'Mariana',
    'Obrero', 'Paligsahan', 'Pinagkaisahan', 'Pinyahan', 'Roxas', 'Sacred Heart',
    'San Isidro Galas', 'San Martin de Porres', 'San Vicente', 'Santo Niño', 'Santol',
    'Sikatuna Village', 'South Triangle', 'Tatalon', 'Teachers Village East',
    'Teachers Village West', 'UP Campus', 'Valencia'
  ],
  'District 5': [
    'Bagbag', 'Capri', 'Fairview', 'Greater Lagro', 'Gulod', 'Kaligayahan',
    'Nagkaisang Nayon', 'North Fairview', 'Novaliches', 'Pasong Putik', 'San Agustin',
    'San Bartolome', 'Sta. Lucia', 'Sta. Monica'
  ],
  'District 6': [
    'Apolonio Samson', 'Baesa', 'Balumbato', 'Culiat', 'New Era', 'Pasong Tamo',
    'Sangandaan', 'Sauyo', 'Talipapa', 'Tandang Sora', 'Unang Sigaw'
  ],
};

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController stationNameController = TextEditingController();
  final TextEditingController truckNumberController = TextEditingController();
  final TextEditingController plateNumberController = TextEditingController();
  final TextEditingController exactLocationController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  String? selectedDistrict;
  String? selectedBarangay;
  double? selectedLatitude;
  double? selectedLongitude;

  bool isLoading = false;

  Future<void> openMapPicker() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      LatLng initialPosition =
          LatLng(position.latitude, position.longitude);

      LatLng? pickedLocation = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPickerScreen(initialPosition: initialPosition),
        ),
      );

      if (pickedLocation != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pickedLocation.latitude,
          pickedLocation.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          setState(() {
            exactLocationController.text =
                '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
            selectedLatitude = pickedLocation.latitude;
            selectedLongitude = pickedLocation.longitude;
          });
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to get location: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> signUpUser() async {
    setState(() {
      isLoading = true;
    });

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Passwords do not match!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _database.ref("rescuer/${userCredential.user!.uid}").set({
        'rescuerID': userCredential.user!.uid,
        'stationName': stationNameController.text.trim(),
        'truckNumber': truckNumberController.text.trim(),
        'plateNumber': plateNumberController.text.trim(),
        'assignedDistrict': selectedDistrict,
        'assignedBarangay': selectedBarangay,
        'exactLocation': exactLocationController.text.trim(),
        'latitude': selectedLatitude,
        'longitude': selectedLongitude,
        'rescuer_status': 'pending', // Admin approval
        'createdAt': DateTime.now().toIso8601String(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset('assets/text.png', height: 100),
                    const SizedBox(height: 10),
                    const Text(
                      'Create New Rescuer Account',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              DropdownButtonFormField<String>(
                value: selectedDistrict,
                hint: const Text('Select District'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                onChanged: (newDistrict) {
                  setState(() {
                    selectedDistrict = newDistrict;
                    selectedBarangay = null;
                  });
                },
                items: districtsAndBarangays.keys.map((district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedBarangay,
                hint: const Text('Select Barangay'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                onChanged: (newBarangay) {
                  setState(() {
                    selectedBarangay = newBarangay;
                  });
                },
                items: selectedDistrict != null
                    ? districtsAndBarangays[selectedDistrict]!
                        .map((barangay) => DropdownMenuItem<String>(
                              value: barangay,
                              child: Text(barangay),
                            ))
                        .toList()
                    : [],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: exactLocationController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Exact Location',
                  prefixIcon: Icon(Icons.location_pin),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: openMapPicker,
                icon: const Icon(Icons.map),
                label: const Text('Pick Location on Map'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: stationNameController,
                decoration: const InputDecoration(
                  labelText: 'Station Name',
                  prefixIcon: Icon(Icons.fire_truck),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: truckNumberController,
                decoration: const InputDecoration(
                  labelText: 'Truck Number',
                  prefixIcon: Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: plateNumberController,
                decoration: const InputDecoration(
                  labelText: 'Plate Number',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: signUpUser,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
