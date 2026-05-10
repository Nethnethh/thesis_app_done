import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryScreen extends StatelessWidget {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref("sensor_history");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cloud History"), backgroundColor: Colors.green[700]),
      body: StreamBuilder(
        stream: _historyRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(child: Text("No history recorded yet."));
          }
          Map data = snapshot.data!.snapshot.value as Map;
          List items = data.values.toList()..sort((a,b) => b['timestamp'].compareTo(a['timestamp']));

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 100),
            itemCount: items.length,
            itemBuilder: (context, i) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Icon(Icons.history, color: Colors.green),
                title: Text(items[i]['verdict'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${items[i]['timestamp']}\nGas: ${items[i]['gasVOC']} ohms"),
                isThreeLine: true,
              ),
            ),
          );
        },
      ),
    );
  }
}