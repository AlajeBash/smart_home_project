import 'package:firebase_database/firebase_database.dart';

class NetworkService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  /// Listen for sensor data (temperature and humidity).
  Stream<Map<String, dynamic>> listenToSensorData() {
    return _databaseRef.child("sensors").onValue.map((event) {
      final data = event.snapshot.value as Map?;
      return {
        "temperature": data?["temperature"] ?? 0.0,
        "humidity": data?["humidity"] ?? 0.0,
      };
    });
  }

  /// Listen for relay state changes.
  Stream<bool> listenToRelayState() {
    return _databaseRef.child("home/light/").onValue.map((event) {
      final state = event.snapshot.value as bool?;
      return state ?? false; // Default to false if null
    });
  }

  /// Toggle the relay state (write a Boolean value to the database).
  Future<void> toggleRelayState(bool value) async {
    await _databaseRef.child("home/light/").set(value);
  }
}
