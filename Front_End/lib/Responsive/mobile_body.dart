import 'package:smart_home_front_end/exports.dart';

class MobileBody extends StatefulWidget {
  const MobileBody({super.key});

  @override
  State<MobileBody> createState() => _MobileBodyState();
}

class _MobileBodyState extends State<MobileBody> {
  final NetworkService _networkService = NetworkService();

  double? temperature;
  double? humidity;
  bool relayState = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Listen for sensor data
    _networkService.listenToSensorData().listen((data) {
      setState(() {
        temperature = data["temperature"];
        humidity = data["humidity"];
      });
    });

    // Listen for relay state
    _networkService.listenToRelayState().listen((state) {
      setState(() {
        relayState = state;
      });
    });
  }

  void _toggleRelayState(bool value) {
    _networkService.toggleRelayState(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home - Mobile'),
        centerTitle: true,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black26,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                //Living Room
                Container(
                  child: Card(
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(Icons.home, color: Colors.green),
                      title: const Text(
                        "Living Room",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Temperature
                    Expanded(
                      child: Card(
                        elevation: 4,
                        child: ListTile(
                          leading:
                              const Icon(Icons.thermostat, color: Colors.red),
                          title: const Text(
                            "Temperature",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "$temperature°C",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Humidity
                    Expanded(
                      child: Card(
                        elevation: 4,
                        child: ListTile(
                          leading:
                              const Icon(Icons.water_drop, color: Colors.blue),
                          title: const Text(
                            "Humidity",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "$humidity%",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Temperature and Humidity Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Card(
                          elevation: 4,
                          child: TemperatureGauge(
                            temperature: temperature ?? 0.0,
                          ),
                        ),
                        Card(
                          elevation: 4,
                          child: HumidityGauge(
                            humidity: humidity ?? 0.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 5,
                      height: 10,
                    ),
                    // Temperature
                  ],
                ),
                const SizedBox(height: 20),
                // Light Relay
                Card(
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(
                      Icons.lightbulb,
                      color: relayState ? Colors.green : Colors.grey,
                    ),
                    title: const Text(
                      "Light Relay",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Switch(
                      value: relayState,
                      onChanged: (value) {
                        _toggleRelayState(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:smart_home_front_end/exports.dart';

// class MobileBody extends StatefulWidget {
//   const MobileBody({super.key});

//   @override
//   State<MobileBody> createState() => _MobileBodyState();
// }

// class _MobileBodyState extends State<MobileBody> {
//   String? temperature = "Loading..."; // Replace with dynamic data fetching
//   String? humidity = "Loading..."; // Replace with dynamic data fetching

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Smart Home'),
//         ),
//         backgroundColor: Colors.black26,
    //     body: SingleChildScrollView(
    //       child: Padding(
    //         padding: const EdgeInsets.all(16.0),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             const SizedBox(height: 10),
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //               children: [
    //                 // Temperature
    //                 Expanded(
    //                   child: Card(
    //                     elevation: 4,
    //                     child: ListTile(
    //                       leading:
    //                           const Icon(Icons.thermostat, color: Colors.red),
    //                       title: const Text(
    //                         "Temperature",
    //                         style: TextStyle(fontWeight: FontWeight.bold),
    //                       ),
    //                       subtitle: Text(
    //                         "$temperature°C",
    //                         style: const TextStyle(fontSize: 16),
    //                       ),
    //                     ),
    //                   ),
    //                 ),
    //                 const SizedBox(width: 10),
    //                 // Humidity
    //                 Expanded(
    //                   child: Card(
    //                     elevation: 4,
    //                     child: ListTile(
    //                       leading:
    //                           const Icon(Icons.water_drop, color: Colors.blue),
    //                       title: const Text(
    //                         "Humidity",
    //                         style: TextStyle(fontWeight: FontWeight.bold),
    //                       ),
    //                       subtitle: Text(
    //                         "$humidity%",
    //                         style: const TextStyle(fontSize: 16),
    //                       ),
    //                     ),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             const SizedBox(height: 10),
    //             // Temperature and Humidity Row
    //             Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //               children: [
    //                 Row(
    //                   children: [
    //                     Padding(
    //                       padding: const EdgeInsets.all(8.0),
    //                       child: Card(
    //                         elevation: 4,
    //                         child: TemperatureGauge(
    //                           temperature: 26,
    //                         ),
    //                       ),
    //                     ),
    //                     Padding(
    //                       padding: const EdgeInsets.all(8.0),
    //                       child: Card(

    //                         elevation: 4,
    //                         child: HumidityGauge(
    //                           humidity: 70,
    //                         ),
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //                 SizedBox(
    //                   width: 5,
    //                   height: 10,
    //                 ),
    //                 // Temperature
    //               ],
    //             ),
    //             const SizedBox(height: 20),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
//   }
// }




// Expanded(
//                       child: Card(
//                         elevation: 4,
//                         child: ListTile(
//                           leading:
//                               const Icon(Icons.thermostat, color: Colors.red),
//                           title: const Text(
//                             "Temperature",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "$temperature°C",
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     // Humidity
//                     Expanded(
//                       child: Card(
//                         elevation: 4,
//                         child: ListTile(
//                           leading:
//                               const Icon(Icons.water_drop, color: Colors.blue),
//                           title: const Text(
//                             "Humidity",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "$humidity%",
//                             style: const TextStyle(fontSize: 16),
//                           ),
//                         ),
//                       ),
//                     ),







// //  Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Row(
//               children: [
//                 TemperatureGauge(temperature: temperature),
//                 const SizedBox(height: 20),
//                 HumidityGauge(humidity: humidity),
//                 const SizedBox(height: 20),
//               ],
            //     Card(
            //       elevation: 4,
            //       child: ListTile(
            //         leading: Icon(
            //           Icons.lightbulb,
            //           color: relayState ? Colors.green : Colors.grey,
            //         ),
            //         title: const Text(
            //           "Light Relay",
            //           style: TextStyle(fontWeight: FontWeight.bold),
            //         ),
            //         trailing: Switch(
            //           value: relayState,
            //           onChanged: (value) {
            //             _toggleRelayState(value);
            //           },
            //         ),
            //       ),
            //     ),
          
            // ),
//           ],
//         ),
//       ),