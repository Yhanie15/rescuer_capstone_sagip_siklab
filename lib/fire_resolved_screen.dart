import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FireResolvedScreen extends StatefulWidget {
  const FireResolvedScreen({Key? key}) : super(key: key);

  @override
  _FireResolvedScreenState createState() => _FireResolvedScreenState();
}

class _FireResolvedScreenState extends State<FireResolvedScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Form controllers
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _alarmReceivedController = TextEditingController();
  final TextEditingController _callerController = TextEditingController();
  final TextEditingController _officeAddressController = TextEditingController();
  final TextEditingController _firemanController = TextEditingController();
  final TextEditingController _dispatchTimeController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  final TextEditingController _returnTimeController = TextEditingController();
  final TextEditingController _waterRefillController = TextEditingController();
  final TextEditingController _gasConsumedController = TextEditingController();
  final TextEditingController _structureDescriptionController = TextEditingController();
  final TextEditingController _extinguishingAgentController = TextEditingController();
  final TextEditingController _hoseLineController = TextEditingController();
  final TextEditingController _ropesController = TextEditingController();
  final TextEditingController _toolsController = TextEditingController();
  final TextEditingController _problemsController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _preparedByController = TextEditingController();
  final TextEditingController _notedByController = TextEditingController();
  final TextEditingController _personnelOnDutyController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _civilianInjuredController = TextEditingController();
  final TextEditingController _civilianDeathController = TextEditingController();
  final TextEditingController _firefighterInjuredController = TextEditingController();
  final TextEditingController _firefighterDeathController = TextEditingController();
  final TextEditingController _fireStationController = TextEditingController(); // New field

  // Dropdown and checkbox values
  String? _fireClassification;
  String? _motive;
  final List<String> _fireClassifications = [
    'Structural',
    'Trash/Grass Fire',
    'Electrical',
    'Chemical',
    'Vehicular',
    'Other'
  ];
  final List<String> _motives = ['Arson', 'Accidental', 'Under Investigation'];

  Future<void> _submitForm() async {
    try {
      // Add user authentication to link the fire station
      User? user = FirebaseAuth.instance.currentUser;

      // Include Fire Station name (can be retrieved based on user)
      final fireStationName = _fireStationController.text.isNotEmpty
          ? _fireStationController.text
          : "Unknown Fire Station";

      final incidentData = {
        "dateTime": _dateTimeController.text,
        "location": _locationController.text,
        "alarmReceived": _alarmReceivedController.text,
        "caller": _callerController.text,
        "officeAddress": _officeAddressController.text,
        "fireman": _firemanController.text,
        "dispatchTime": _dispatchTimeController.text,
        "arrivalTime": _arrivalTimeController.text,
        "returnTime": _returnTimeController.text,
        "waterRefill": _waterRefillController.text,
        "gasConsumed": _gasConsumedController.text,
        "fireClassification": _fireClassification,
        "motive": _motive,
        "structureDescription": _structureDescriptionController.text,
        "extinguishingAgent": _extinguishingAgentController.text,
        "hoseLine": _hoseLineController.text,
        "ropes": _ropesController.text,
        "tools": _toolsController.text,
        "problems": _problemsController.text,
        "observations": _observationsController.text,
        "preparedBy": _preparedByController.text,
        "notedBy": _notedByController.text,
        "personnelOnDuty": _personnelOnDutyController.text,
        "details": _detailsController.text,
        "civilianInjured": _civilianInjuredController.text,
        "civilianDeath": _civilianDeathController.text,
        "firefighterInjured": _firefighterInjuredController.text,
        "firefighterDeath": _firefighterDeathController.text,
        "fireStation": fireStationName, // Include fire station name
        "submittedBy": user?.email ?? "Anonymous", // Optional user info
        "status": "resolved"
      };

      await _database.child("report").push().set(incidentData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fire incident report submitted successfully!")),
      );

      // Clear all fields after submission
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting report: $e")),
      );
    }
  }

  void _clearForm() {
    _dateTimeController.clear();
    _locationController.clear();
    _alarmReceivedController.clear();
    _callerController.clear();
    _officeAddressController.clear();
    _firemanController.clear();
    _dispatchTimeController.clear();
    _arrivalTimeController.clear();
    _returnTimeController.clear();
    _waterRefillController.clear();
    _gasConsumedController.clear();
    _structureDescriptionController.clear();
    _extinguishingAgentController.clear();
    _hoseLineController.clear();
    _ropesController.clear();
    _toolsController.clear();
    _problemsController.clear();
    _observationsController.clear();
    _preparedByController.clear();
    _notedByController.clear();
    _personnelOnDutyController.clear();
    _detailsController.clear();
    _civilianInjuredController.clear();
    _civilianDeathController.clear();
    _firefighterInjuredController.clear();
    _firefighterDeathController.clear();
    _fireStationController.clear();
    setState(() {
      _fireClassification = null;
      _motive = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("Fire Resolved - Fill Out Form"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fill out the fire incident details below:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Input fields
            _buildTextField("Fire Station Name", _fireStationController), // New field
            _buildTextField("Date and Time", _dateTimeController),
            _buildTextField("Location", _locationController),
            _buildTextField("Alarm Received Time", _alarmReceivedController),
            _buildTextField("Caller/Reported By", _callerController),
            _buildTextField("Office/Address", _officeAddressController),
            _buildTextField("Fireman on Duty", _firemanController),
            _buildTextField("Dispatch Time", _dispatchTimeController),
            _buildTextField("Arrival Time", _arrivalTimeController),
            _buildTextField("Return Time", _returnTimeController),
            _buildTextField("Number of Water Refills", _waterRefillController),
            _buildTextField("Gas Consumed (Liters)", _gasConsumedController),

            const SizedBox(height: 10),

            // Dropdown for fire classification
            _buildDropdown("Fire Classification", _fireClassifications, _fireClassification,
                (value) {
              setState(() {
                _fireClassification = value;
              });
            }),

            // Dropdown for motive
            _buildDropdown("Motive", _motives, _motive, (value) {
              setState(() {
                _motive = value;
              });
            }),

            _buildTextField("Structure Description", _structureDescriptionController),
            _buildTextField("Extinguishing Agent Used", _extinguishingAgentController),
            _buildTextField("Hose Line Used", _hoseLineController),
            _buildTextField("Ropes and Ladders Used", _ropesController),
            _buildTextField("Other Tools Used", _toolsController),
            _buildTextField("Problems Encountered", _problemsController),
            _buildTextField("Observations/Recommendations", _observationsController),
            _buildTextField("Prepared By", _preparedByController),
            _buildTextField("Noted By", _notedByController),
            _buildTextField("Personnel on Duty Who Received the Alarm", _personnelOnDutyController),
            _buildTextField("Details (Narrative)", _detailsController, maxLines: 5),

            const SizedBox(height: 20),

            const Text(
              "Casualties",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            _buildTextField("Civilian Injured", _civilianInjuredController),
            _buildTextField("Civilian Deaths", _civilianDeathController),
            _buildTextField("Firefighter Injured", _firefighterInjuredController),
            _buildTextField("Firefighter Deaths", _firefighterDeathController),

            const SizedBox(height: 20),

            // Submit button
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Center(child: Text("Submit Report")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
