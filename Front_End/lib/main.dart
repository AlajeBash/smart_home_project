import 'package:smart_home_front_end/exports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Homepage());
}

// import 'package:smart_home_front_end/exports.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false, // Optional: Remove the debug banner
//       title: 'Smart Home Automation',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: Homepage(), // Your main widget
//     );
//   }
// }

// import 'package:smart_home_front_end/homepage.dart';

// import 'exports.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(Homepage());
//   // runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Homepage(),
//     );
//   }
// }

// class SmartHomeScreen extends StatefulWidget {
//   @override
//   _SmartHomeScreenState createState() => _SmartHomeScreenState();
// }

// class _SmartHomeScreenState extends State<SmartHomeScreen> {
//   final databaseRef = FirebaseDatabase.instance.ref();
//   double? temperature;
//   double? humidity;
//   bool relayState = true;

//   @override
//   void initState() {
//     super.initState();
//     _listenToSensorData();
//     _listenToRelayState();
//   }

//   void _listenToSensorData() {
//     databaseRef.child("sensors").onValue.listen((event) {
//       final data = event.snapshot.value as Map?;
//       if (data != null) {
//         setState(() {
//           temperature = data["temperature"];
//           humidity = data["humidity"];
//         });
//       }
//     });
//   }

//   void _listenToRelayState() {
//     // Listen for changes in the relay state from the database
//     databaseRef.child("home/light/").onValue.listen((event) {
//       final state = event.snapshot.value as bool?;
//       setState(() {
//         relayState = state ?? false; // Default to false if the value is null
//       });
//     });
//   }

//   void _toggleRelayState(bool value) {
//     // Write a Boolean value to the database
//     databaseRef.child("home/light/").set(value);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Smart Home Automation"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TemperatureGauge(temperature: temperature),
//             HumidityGauge(humidity: humidity),
//             Card(
//               elevation: 4,
//               child: ListTile(
//                 leading: Icon(Icons.lightbulb,
//                     color: relayState ? Colors.green : Colors.grey),
//                 title: Text(
//                   "Light Relay",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 trailing: Switch(
//                   value: relayState,
//                   onChanged: (value) {
//                     _toggleRelayState(value);
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
