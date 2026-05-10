import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ColorMonitorApp());
}

class ColorMonitorApp extends StatelessWidget {
  const ColorMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const SensorDataScreen(),
    );
  }
}

class SensorDataScreen extends StatefulWidget {
  const SensorDataScreen({super.key});

  @override
  State<SensorDataScreen> createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends State<SensorDataScreen> {
  // Reference to your Firebase folder
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("color_logs");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thesis Color Monitor")),
      body: StreamBuilder(
        stream: _dbRef.limitToLast(10).onValue, // Get last 10 readings
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            // Convert Firebase data to a Map
            Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            // Sort keys so the newest data is at the top
            List<dynamic> sortedKeys = data.keys.toList()..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                var entry = data[sortedKeys[index]];

                // Format the timestamp from Firebase
                var timestamp = entry['timestamp'];
                String formattedTime = "No Time";
                if (timestamp != null) {
                  var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                  formattedTime = DateFormat('HH:mm:ss').format(date);
                }

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color.fromARGB(255, entry['red'] ?? 0, entry['green'] ?? 0, entry['blue'] ?? 0),
                      child: const Icon(Icons.palette, color: Colors.white),
                    ),
                    title: Text("Time: $formattedTime"),
                    subtitle: Text("R: ${entry['red']} | G: ${entry['green']} | B: ${entry['blue']}"),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}