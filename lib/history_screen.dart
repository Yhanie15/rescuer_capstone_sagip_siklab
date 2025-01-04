import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref("dispatches");
  final User? _currentUser = FirebaseAuth.instance.currentUser; // Get the signed-in user
  List<Map<dynamic, dynamic>> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoryForCurrentUser();
  }

  Future<void> _fetchHistoryForCurrentUser() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user is signed in.")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await _database.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          _historyList = data.entries
              .where((entry) {
                final dispatch = entry.value as Map<dynamic, dynamic>;
                return dispatch['rescuerID'] == _currentUser!.uid; // Match rescuerID with current user's ID
              })
              .map((entry) {
                return {
                  "id": entry.key,
                  ...entry.value as Map<dynamic, dynamic>,
                };
              })
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching history: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 229, 229, 229),
        title: const Text("My Dispatch History"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? const Center(
                  child: Text(
                    "No history available",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final history = _historyList[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(
                          "Dispatch ID: ${history['id'] ?? 'N/A'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Location: ${history['location'] ?? 'N/A'}"),
                            Text("Date: ${history['dispatchTime'] ?? 'N/A'}"),
                            Text("Dispatch by: ${history['caller'] ?? 'ADMIN'}"),
                            Text("Status: ${history['status'] ?? 'N/A'}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.info, color: Colors.blue),
                          onPressed: () {
                            _showDetailsDialog(history);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDetailsDialog(Map<dynamic, dynamic> history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Details for Dispatch ID: ${history['id'] ?? 'N/A'}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: history.entries.map((entry) {
              return Text(
                "${entry.key}: ${entry.value}",
                style: const TextStyle(fontSize: 16),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
