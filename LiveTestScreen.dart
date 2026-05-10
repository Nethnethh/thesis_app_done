import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref("color_logs").limitToLast(1);
    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        Map data = snapshot.data!.snapshot.value as Map;
        var lastEntry = data.values.first;
        Color sensorColor = Color.fromARGB(255, lastEntry['red'] ?? 0, lastEntry['green'] ?? 0, lastEntry['blue'] ?? 0);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 150, height: 150,
                  decoration: BoxDecoration(color: sensorColor, shape: BoxShape.circle, border: Border.all(width: 4, color: Colors.grey))
              ),
              const SizedBox(height: 30),
              Text("RED: ${lastEntry['red']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text("GREEN: ${lastEntry['green']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text("BLUE: ${lastEntry['blue']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}