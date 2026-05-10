import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<void> saveTestResult({
    required String fruit,
    required int r,
    required int g,
    required int b,
    required int gas,
    required String status,
  }) async {
    await FirebaseFirestore.instance.collection("tests").add({
      "fruit": fruit,
      "r": r,
      "g": g,
      "b": b,
      "gas": gas,
      "status": status,
      "time": Timestamp.now(),
    });
  }
}
