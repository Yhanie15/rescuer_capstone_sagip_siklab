import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirefighterListScreen extends StatefulWidget {
  const FirefighterListScreen({super.key});

  @override
  State<FirefighterListScreen> createState() => _FirefighterListScreenState();
}

class _FirefighterListScreenState extends State<FirefighterListScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  String? _fireStationName;
  List<Map<String, dynamic>> firefighters = [];

  @override
  void initState() {
    super.initState();
    _loadFireStationName();
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
        _loadFirefighters();
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
                    'age': e.value['age'],
                    'rank': e.value['rank'],
                    'position': e.value['position'],
                  })
              .toList();
        });
      } else {
        setState(() {
          firefighters = []; // Clear list if no data exists
        });
      }
    } catch (e) {
      print('Error loading firefighters: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading firefighters: $e')),
      );
    }
  }

  Future<void> _addFirefighter() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Firefighter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter full name',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter age',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rankController,
                decoration: const InputDecoration(
                  labelText: 'Rank',
                  hintText: 'Enter rank (e.g., Captain, Lieutenant)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'Enter position/role',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty && _fireStationName != null) {
                await _database
                    .child('firefighters/$_fireStationName')
                    .push()
                    .set({
                  'name': _nameController.text,
                  'age': _ageController.text,
                  'rank': _rankController.text,
                  'position': _positionController.text,
                  'addedAt': DateTime.now().toIso8601String(),
                });
                _clearControllers();
                Navigator.pop(context);
                _loadFirefighters();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _ageController.clear();
    _rankController.clear();
    _positionController.clear();
  }

  Future<void> _deleteFirefighter(String id) async {
    if (_fireStationName == null) return;

    try {
      await _database.child('firefighters/$_fireStationName/$id').remove();
      _loadFirefighters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting firefighter: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_fireStationName ?? 'Firefighters List'),
        backgroundColor: const Color.fromARGB(255, 224, 51, 39),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFirefighter,
        backgroundColor: const Color.fromARGB(255, 224, 51, 39),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Fire Station Personnel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color.fromARGB(255, 224, 51, 39)
                              .withOpacity(0.1),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Age',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Rank',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Position',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: firefighters.map((firefighter) {
                          return DataRow(
                            cells: [
                              DataCell(Text(firefighter['name'] ?? 'N/A')),
                              DataCell(Text(
                                  firefighter['age']?.toString() ?? 'N/A')),
                              DataCell(Text(firefighter['rank'] ?? 'N/A')),
                              DataCell(Text(firefighter['position'] ?? 'N/A')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      color: Colors.blue,
                                      onPressed: () =>
                                          _editFirefighter(firefighter),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      color: Colors.red,
                                      onPressed: () => _showDeleteConfirmation(
                                          context, firefighter['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAllConfirmation(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Firefighters'),
        content: const Text(
          'Are you sure you want to delete all firefighters from this station? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAllFirefighters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllFirefighters() async {
    if (_fireStationName == null) return;

    try {
      await _database.child('firefighters/$_fireStationName').remove();
      setState(() {
        firefighters.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All firefighters deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting firefighters: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, String id) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this firefighter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFirefighter(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _editFirefighter(Map<String, dynamic> firefighter) async {
    _nameController.text = firefighter['name'];
    _ageController.text = firefighter['age']?.toString() ?? '';
    _rankController.text = firefighter['rank'] ?? '';
    _positionController.text = firefighter['position'] ?? '';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Firefighter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              TextField(
                controller: _rankController,
                decoration: const InputDecoration(labelText: 'Rank'),
              ),
              TextField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearControllers();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await _database
                    .child(
                        'firefighters/$_fireStationName/${firefighter['id']}')
                    .update({
                  'name': _nameController.text,
                  'age': _ageController.text,
                  'rank': _rankController.text,
                  'position': _positionController.text,
                  'updatedAt': DateTime.now().toIso8601String(),
                });
                _clearControllers();
                Navigator.pop(context);
                _loadFirefighters();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _rankController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}
