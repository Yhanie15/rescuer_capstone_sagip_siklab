import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FireResolvedScreen extends StatefulWidget {
  final String? dispatchKey;
  const FireResolvedScreen({Key? key, this.dispatchKey}) : super(key: key);

  @override
  _FireResolvedScreenState createState() => _FireResolvedScreenState();
}

class _FireResolvedScreenState extends State<FireResolvedScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Controllers for form fields
  final _districtController = TextEditingController();
  final _dateTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final _callerController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _dispatchTimeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _returnTimeController = TextEditingController();
  final _waterRefillController = TextEditingController();
  final _gasConsumedController = TextEditingController();
  final _structureDescriptionController = TextEditingController();
  final _extinguishingAgentController = TextEditingController();
  final _hoseLineController = TextEditingController();
  final _ropesController = TextEditingController();
  final _toolsController = TextEditingController();
  final _problemsController = TextEditingController();
  final _observationsController = TextEditingController();
  final _preparedByController = TextEditingController();
  final _notedByController = TextEditingController();
  final _detailsController = TextEditingController();
  final _civilianInjuredController = TextEditingController();
  final _civilianDeathController = TextEditingController();
  final _firefighterInjuredController = TextEditingController();
  final _firefighterDeathController = TextEditingController();
  final _fireStationController = TextEditingController();
  // New controller for Report Key (read-only)
  final _reportKeyController = TextEditingController();

  DateTime? _selectedDateTime;
  String? _dispatchTime, _arrivalTime, _returnTime;
  String? _fireClassification, _motive, _activeDispatchId;
  final List<String> _fireClassifications = [
    'Structural',
    'Trash/Grass Fire',
    'Electrical',
    'Chemical',
    'Vehicular',
    'Other'
  ];
  final List<String> _motives = ['Arson', 'Accidental', 'Under Investigation'];

  List<Map<String, dynamic>> firefighters = [];
  List<String> selectedFirefighters = [];
  String? _fireStationName, _alarmId;

  @override
  void initState() {
    super.initState();
    _setFireStationFromEmail();
    _loadFireStationName();
    _fetchAssignedDistrict();
    if (widget.dispatchKey != null) {
      _fetchDispatchDetails(widget.dispatchKey!);
    } else {
      _fetchActiveDispatchDetails();
    }
  }

  // Convert email to Fire Station name
  String _formatEmail(String email) {
    return email
            .split('@')
            .first
            .split(RegExp(r'[._]'))
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(' ') +
        " Fire Station";
  }

  void _setFireStationFromEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      _fireStationController.text = _formatEmail(user!.email!);
    }
  }

  Future<void> _loadFireStationName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await _db.child('rescuer/${user.uid}/stationName').get();
    if (snapshot.exists) {
      setState(() {
        _fireStationName = snapshot.value.toString();
      });
      _loadFirefighters();
    }
  }

  // Fetch the assigned district (read-only)
  Future<void> _fetchAssignedDistrict() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot =
        await _db.child('rescuer/${user.uid}/assignedDistrict').get();
    if (snapshot.exists) {
      setState(() {
        _districtController.text = snapshot.value.toString();
      });
    }
  }

  Future<void> _loadFirefighters() async {
    if (_fireStationName == null) return;
    try {
      final snapshot = await _db.child('firefighters/$_fireStationName').get();
      if (snapshot.exists) {
        setState(() {
          firefighters = (snapshot.value as Map).entries
              .map((e) => {'id': e.key, 'name': e.value['name']})
              .toList();
        });
      }
    } catch (e) {
      print('Error loading firefighters: $e');
    }
  }

  Future<void> _fetchActiveDispatchDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final event = await _db
        .child('dispatches')
        .orderByChild('rescuerID')
        .equalTo(user.uid)
        .limitToLast(1)
        .once();
    if (event.snapshot.exists) {
      final dispatch = (event.snapshot.value as Map).entries.first;
      final data = dispatch.value as Map;
      if (data['status'] == 'Dispatched') {
        setState(() {
          _activeDispatchId = dispatch.key;
          _dispatchTimeController.text = data['dispatchTime'] ?? '';
          _dispatchTime = data['dispatchTime'];
          _locationController.text = data['location'] ?? '';
          _callerController.text = data['reportedBy'] ?? '';
          _selectedDateTime = DateTime.now();
          _dateTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
          // If dispatch record has a reportKey, update the controller
          if (data.containsKey('reportKey')) {
            _reportKeyController.text = data['reportKey'];
          }
        });
      }
    }
  }

  Future<void> _fetchDispatchDetails(String key) async {
    final snapshot = await _db.child('dispatches').child(key).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        _activeDispatchId = key;
        if (data['alarmReceivedTime'] != null) {
          _selectedDateTime = DateTime.now();
          _dateTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
        }
        _locationController.text = data['location'] ?? '';
        _callerController.text = data['reportedBy'] ?? '';
        _dispatchTimeController.text = data['dispatchTime'] ?? '';
        // Update the reportKey if available
        if (data.containsKey('reportKey')) {
          _reportKeyController.text = data['reportKey'];
        }
      });
    }
  }

  // For this example, the submit logic remains unchanged
  Future<void> _submitForm() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final fireStationName = _fireStationController.text.isNotEmpty
          ? _fireStationController.text
          : "Unknown Fire Station";
      final assignedDistrict = _districtController.text;
      final incidentData = {
        "dateTime": _dateTimeController.text,
        "location": _locationController.text,
        "caller": _callerController.text,
        "officeAddress": _officeAddressController.text,
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
        "details": _detailsController.text,
        "civilianInjured": _civilianInjuredController.text,
        "civilianDeath": _civilianDeathController.text,
        "firefighterInjured": _firefighterInjuredController.text,
        "firefighterDeath": _firefighterDeathController.text,
        "fireStation": fireStationName,
        "assignedDistrict": assignedDistrict,
        "submittedBy": user?.email ?? "Anonymous",
        "status": "resolved",
        "dispatchId": _activeDispatchId,
        "respondingFirefighters": selectedFirefighters,
      };

      await _db.child("report").push().set(incidentData);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Report submitted!")));
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _clearForm() {
    _dateTimeController.clear();
    _locationController.clear();
    _callerController.clear();
    _officeAddressController.clear();
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
    _detailsController.clear();
    _civilianInjuredController.clear();
    _civilianDeathController.clear();
    _firefighterInjuredController.clear();
    _firefighterDeathController.clear();
    // Do not clear the district, fire station, and reportKey fields since they're auto-filled and read-only.
    setState(() {
      _fireClassification = null;
      _motive = null;
      selectedFirefighters.clear();
      _dispatchTime = _arrivalTime = _returnTime = null;
    });
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute);
          _dateTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
        });
      }
    }
  }

  Future<void> _selectTime(Function(String) setter, TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final time = picked.format(context);
      setState(() {
        setter(time);
        ctrl.text = time;
      });
    }
  }

  // Generic widget builder for text inputs
  Widget _buildInput(String label, TextEditingController ctrl,
      {bool readOnly = false,
      VoidCallback? onTap,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          prefixIcon: label == "District" ? const Icon(Icons.location_on) : null,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[200] : null,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) =>
                DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fire Resolved - Fill Out Form"),
        backgroundColor: Colors.grey[300],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Fill out the fire incident details below:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _buildInput("District", _districtController,
              readOnly: true, keyboardType: TextInputType.number),
          _buildInput("Fire Station Name", _fireStationController, readOnly: true),
          // New read-only text field displaying the reportKey
          _buildInput("Report Key", _reportKeyController, readOnly: true),
          _buildInput("Date and Time", _dateTimeController,
              readOnly: true, onTap: _selectDateTime),
          _buildInput("Location", _locationController),
          _buildInput("Caller/Reported By", _callerController),
          _buildInput("Office/Address", _officeAddressController),
          _buildInput("Dispatch Time", _dispatchTimeController, readOnly: true),
          _buildInput("Arrival Time", _arrivalTimeController,
              readOnly: true,
              onTap: () =>
                  _selectTime((time) => _arrivalTime = time, _arrivalTimeController)),
          _buildInput("Return Time", _returnTimeController,
              readOnly: true,
              onTap: () =>
                  _selectTime((time) => _returnTime = time, _returnTimeController)),
          _buildInput("Number of Water Refills", _waterRefillController,
              keyboardType: TextInputType.number),
          _buildInput("Gas Consumed (Liters)", _gasConsumedController,
              keyboardType: TextInputType.number),
          _buildDropdown("Fire Classification", _fireClassifications,
              _fireClassification, (v) => setState(() => _fireClassification = v)),
          _buildDropdown("Motive", _motives, _motive,
              (v) => setState(() => _motive = v)),
          _buildInput("Structure Description", _structureDescriptionController, maxLines: 3),
          _buildInput("Extinguishing Agent Used", _extinguishingAgentController),
          _buildInput("Hose Line Used", _hoseLineController),
          _buildInput("Ropes and Ladders Used", _ropesController),
          _buildInput("Other Tools Used", _toolsController),
          _buildInput("Problems Encountered", _problemsController, maxLines: 3),
          _buildInput("Observations/Recommendations", _observationsController, maxLines: 3),
          _buildInput("Prepared By", _preparedByController),
          _buildInput("Noted By", _notedByController),
          _buildInput("Details (Narrative)", _detailsController, maxLines: 5),
          const SizedBox(height: 20),
          const Text("Responding Firefighters",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: firefighters
                    .map((ff) => CheckboxListTile(
                          title: Text(ff['name'] ?? 'Unknown'),
                          value: selectedFirefighters.contains(ff['name']),
                          onChanged: (val) {
                            setState(() {
                              val == true
                                  ? selectedFirefighters.add(ff['name'])
                                  : selectedFirefighters.remove(ff['name']);
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          ),
          const Text("Casualties",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent)),
          _buildInput("Civilian Injured", _civilianInjuredController,
              keyboardType: TextInputType.number),
          _buildInput("Civilian Deaths", _civilianDeathController,
              keyboardType: TextInputType.number),
          _buildInput("Firefighter Injured", _firefighterInjuredController,
              keyboardType: TextInputType.number),
          _buildInput("Firefighter Deaths", _firefighterDeathController,
              keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            child: const Center(child: Text("Submit Report")),
          )
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _districtController.dispose();
    _dateTimeController.dispose();
    _locationController.dispose();
    _callerController.dispose();
    _officeAddressController.dispose();
    _dispatchTimeController.dispose();
    _arrivalTimeController.dispose();
    _returnTimeController.dispose();
    _waterRefillController.dispose();
    _gasConsumedController.dispose();
    _structureDescriptionController.dispose();
    _extinguishingAgentController.dispose();
    _hoseLineController.dispose();
    _ropesController.dispose();
    _toolsController.dispose();
    _problemsController.dispose();
    _observationsController.dispose();
    _preparedByController.dispose();
    _notedByController.dispose();
    _detailsController.dispose();
    _civilianInjuredController.dispose();
    _civilianDeathController.dispose();
    _firefighterInjuredController.dispose();
    _firefighterDeathController.dispose();
    _fireStationController.dispose();
    _reportKeyController.dispose();
    super.dispose();
  }
}
