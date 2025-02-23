import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FireResolvedScreen extends StatefulWidget {
  final String? dispatchKey;

  const FireResolvedScreen({
    super.key,
    this.dispatchKey,
  });

  @override
  _FireResolvedScreenState createState() => _FireResolvedScreenState();
}

class _FireResolvedScreenState extends State<FireResolvedScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Form controllers
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _callerController = TextEditingController();
  final TextEditingController _officeAddressController =
      TextEditingController();
  final TextEditingController _dispatchTimeController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  final TextEditingController _returnTimeController = TextEditingController();
  final TextEditingController _waterRefillController = TextEditingController();
  final TextEditingController _gasConsumedController = TextEditingController();
  final TextEditingController _structureDescriptionController =
      TextEditingController();
  final TextEditingController _extinguishingAgentController =
      TextEditingController();
  final TextEditingController _hoseLineController = TextEditingController();
  final TextEditingController _ropesController = TextEditingController();
  final TextEditingController _toolsController = TextEditingController();
  final TextEditingController _problemsController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _preparedByController = TextEditingController();
  final TextEditingController _notedByController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _civilianInjuredController =
      TextEditingController();
  final TextEditingController _civilianDeathController =
      TextEditingController();
  final TextEditingController _firefighterInjuredController =
      TextEditingController();
  final TextEditingController _firefighterDeathController =
      TextEditingController();
  final TextEditingController _fireStationController =
      TextEditingController(); // New field

  DateTime? _selectedDateTime;

  // Update these to be String instead of TimeOfDay
  String? _dispatchTime;
  String? _arrivalTime;
  String? _returnTime;

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

  String? _alarmId; // Add this to store the reference to the alarm
  String? _activeDispatchId;

  // Add new variables
  List<Map<String, dynamic>> firefighters = [];
  List<String> selectedFirefighters = [];
  String? _fireStationName;

  @override
  void initState() {
    super.initState();
    _setFireStationFromEmail();
    _loadFireStationName(); // Add this line
    if (widget.dispatchKey != null) {
      _fetchDispatchDetails(widget.dispatchKey!);
    } else {
      _fetchActiveDispatchDetails();
    }
  }

  String _formatEmailToFireStationName(String email) {
    // Extract the part before @gmail.com
    String name = email.split('@').first;

    // Split by dots or underscores if present
    List<String> parts = name.split(RegExp(r'[._]'));

    // Capitalize each word and join with spaces
    String stationName = parts
        .map((part) => part.substring(0, 1).toUpperCase() + part.substring(1))
        .join(' ');

    return "$stationName Fire Station";
  }

  void _setFireStationFromEmail() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _fireStationController.text =
            _formatEmailToFireStationName(user.email!);
      });
    }
  }

  Future<void> _loadFireStationName() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await _database.child('rescuer/${user.uid}/stationName').get();
      if (snapshot.exists) {
        setState(() {
          _fireStationName = snapshot.value.toString();
        });
        _loadFirefighters(); // Load firefighters after getting station name
      }
    }
  }

  Future<void> _loadFirefighters() async {
    if (_fireStationName == null) return;

    try {
      final snapshot =
          await _database.child('firefighters/$_fireStationName').get();
      if (snapshot.exists) {
        setState(() {
          firefighters = (snapshot.value as Map<dynamic, dynamic>)
              .entries
              .map((e) => {
                    'id': e.key,
                    'name': e.value['name'],
                  })
              .toList();
        });
      }
    } catch (e) {
      print('Error loading firefighters: $e');
    }
  }

  Future<void> _fetchActiveDispatchDetails() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final DatabaseEvent event = await _database
          .child('dispatches')
          .orderByChild('rescuerID')
          .equalTo(user.uid)
          .limitToLast(1)
          .once();

      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> dispatches =
            event.snapshot.value as Map<dynamic, dynamic>;

        final dispatch = dispatches.entries.first;
        final dispatchData = dispatch.value as Map<dynamic, dynamic>;

        if (dispatchData['status'] == 'Dispatched') {
          setState(() {
            _activeDispatchId = dispatch.key;

            // Set dispatch time from the dispatch notification
            if (dispatchData['dispatchTime'] != null) {
              _dispatchTimeController.text = dispatchData['dispatchTime'];
              _dispatchTime = dispatchData['dispatchTime'];
            }

            _locationController.text = dispatchData['location'] ?? '';
            _callerController.text = dispatchData['reportedBy'] ?? '';

            // Set the initial date/time to now
            _selectedDateTime = DateTime.now();
            _dateTimeController.text =
                DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
          });
        }
      }
    } catch (e) {
      print('Error fetching dispatch details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dispatch details: $e')),
      );
    }
  }

  Future<void> _fetchDispatchDetails(String dispatchKey) async {
    try {
      final DataSnapshot snapshot =
          await _database.child('dispatches').child(dispatchKey).get();

      if (snapshot.exists) {
        final dispatchData = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _activeDispatchId = dispatchKey;

          // Set alarm received time with proper formatting
          if (dispatchData['alarmReceivedTime'] != null) {
            _selectedDateTime = DateTime.now();
            _dateTimeController.text =
                DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
          }

          // Auto-fill other fields
          _locationController.text = dispatchData['location'] ?? '';
          _callerController.text = dispatchData['reportedBy'] ?? '';
          _dispatchTimeController.text = dispatchData['dispatchTime'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching dispatch details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dispatch details: $e')),
      );
    }
  }

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
        "fireStation": fireStationName, // Include fire station name
        "submittedBy": user?.email ?? "Anonymous", // Optional user info
        "status": "resolved",
        "dispatchId": _activeDispatchId,
        "respondingFirefighters": selectedFirefighters, // Add this line
      };

      await _database.child("report").push().set(incidentData);

      // Update the alarm status in the database
      if (_alarmId != null) {
        await _database.child('alarms').child(_alarmId!).update({
          'status': 'resolved',
          'resolvedTime': DateTime.now().toIso8601String(),
        });
      }

      // Update dispatch status
      if (_activeDispatchId != null) {
        await _database.child('dispatches').child(_activeDispatchId!).update({
          'status': 'resolved',
          'resolvedTime': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Fire incident report submitted successfully!")),
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
    _fireStationController.clear();
    setState(() {
      _fireClassification = null;
      _motive = null;
      selectedFirefighters.clear(); // Add this line
      _dispatchTime = null;
      _arrivalTime = null;
      _returnTime = null;
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
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
            pickedTime.minute,
          );
          _dateTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!);
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay? currentTime,
      Function(TimeOfDay) onSelect) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      onSelect(pickedTime);
    }
  }

  // Add these methods to handle time selection
  Future<void> _selectDispatchTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dispatchTime = picked.format(context);
        _dispatchTimeController.text = _dispatchTime!;
      });
    }
  }

  Future<void> _selectArrivalTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _arrivalTime = picked.format(context);
        _arrivalTimeController.text = _arrivalTime!;
      });
    }
  }

  Future<void> _selectReturnTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _returnTime = picked.format(context);
        _returnTimeController.text = _returnTime!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 229, 229, 229),
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
            _buildInputField(
                "Fire Station Name", _fireStationController), // New field
            _buildInputField("Date and Time", _dateTimeController,
                type: InputType.datetime),
            _buildInputField("Location", _locationController),
            _buildInputField("Caller/Reported By", _callerController),
            _buildInputField("Office/Address", _officeAddressController),
            _buildTimeField("Dispatch Time", _dispatchTimeController,
                _selectDispatchTime), // Modified this line
            _buildTimeField(
                "Arrival Time", _arrivalTimeController, _selectArrivalTime),
            _buildTimeField(
                "Return Time", _returnTimeController, _selectReturnTime),
            _buildInputField("Number of Water Refills", _waterRefillController,
                type: InputType.number),
            _buildInputField("Gas Consumed (Liters)", _gasConsumedController,
                type: InputType.number),

            const SizedBox(height: 10),

            // Dropdown for fire classification
            _buildDropdown("Fire Classification", _fireClassifications,
                _fireClassification, (value) {
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

            _buildInputField(
                "Structure Description", _structureDescriptionController,
                type: InputType.multiline, maxLines: 3),
            _buildInputField(
                "Extinguishing Agent Used", _extinguishingAgentController),
            _buildInputField("Hose Line Used", _hoseLineController),
            _buildInputField("Ropes and Ladders Used", _ropesController),
            _buildInputField("Other Tools Used", _toolsController),
            _buildInputField("Problems Encountered", _problemsController,
                type: InputType.multiline, maxLines: 3),
            _buildInputField(
                "Observations/Recommendations", _observationsController,
                type: InputType.multiline, maxLines: 3),
            _buildInputField("Prepared By", _preparedByController),
            _buildInputField("Noted By", _notedByController),
            _buildInputField("Details (Narrative)", _detailsController,
                type: InputType.multiline, maxLines: 5),

            const SizedBox(height: 20),

            // Add this section before the Casualties section
            const SizedBox(height: 20),
            const Text(
              "Responding Firefighters",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: firefighters.map((firefighter) {
                    return CheckboxListTile(
                      title: Text(firefighter['name'] ?? 'Unknown'),
                      value: selectedFirefighters.contains(firefighter['name']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedFirefighters.add(firefighter['name']);
                          } else {
                            selectedFirefighters.remove(firefighter['name']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            const Text(
              "Casualties",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent),
            ),
            _buildInputField("Civilian Injured", _civilianInjuredController,
                type: InputType.number),
            _buildInputField("Civilian Deaths", _civilianDeathController,
                type: InputType.number),
            _buildInputField(
                "Firefighter Injured", _firefighterInjuredController,
                type: InputType.number),
            _buildInputField("Firefighter Deaths", _firefighterDeathController,
                type: InputType.number),

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

  Widget _buildInputField(String label, dynamic controller,
      {InputType type = InputType.text, int maxLines = 1}) {
    // Special case for fire station field
    if (label == "Fire Station Name") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextField(
          controller: controller,
          readOnly: true,
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            filled: true,
            fillColor: Colors.grey[200],
            prefixIcon: const Icon(Icons.location_city),
          ),
        ),
      );
    }

    // Add special case for quantity fields
    if (label == "Extinguishing Agent Used" ||
        label == "Hose Line Used" ||
        label == "Ropes and Ladders Used") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    int currentValue = int.tryParse(controller.text) ?? 0;
                    if (currentValue > 0) {
                      controller.text = (currentValue - 1).toString();
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    int currentValue = int.tryParse(controller.text) ?? 0;
                    controller.text = (currentValue + 1).toString();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    switch (type) {
      case InputType.datetime:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () => _selectDateTime(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDateTime != null
                    ? DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime!)
                    : 'Select Date and Time',
              ),
            ),
          ),
        );

      case InputType.time:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () => _selectTime(
              context,
              controller as TimeOfDay?,
              (time) => setState(() => controller = time),
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                suffixIcon: const Icon(Icons.access_time),
              ),
              child: Text(controller?.format(context) ?? 'Select Time'),
            ),
          ),
        );

      case InputType.number:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),
        );

      case InputType.multiline:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              alignLabelWithHint: true,
            ),
          ),
        );

      default:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        );
    }
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      Function(String?) onChanged) {
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

  // Update the _buildTimeField method to make dispatch time read-only
  Widget _buildTimeField(
      String label, TextEditingController controller, VoidCallback onTap) {
    bool isDispatchTime = label == "Dispatch Time";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: isDispatchTime ? null : onTap, // Disable tap for dispatch time
        enabled: !isDispatchTime, // Disable editing for dispatch time
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          suffixIcon: isDispatchTime ? null : const Icon(Icons.access_time),
          hintText: isDispatchTime ? null : 'Select time',
          filled: isDispatchTime,
          fillColor: isDispatchTime ? Colors.grey[200] : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
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
    super.dispose();
  }
}

enum InputType {
  text,
  datetime,
  time,
  number,
  multiline,
}
