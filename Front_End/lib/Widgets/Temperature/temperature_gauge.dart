import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TemperatureGauge extends StatefulWidget {
  const TemperatureGauge({
    super.key,
    required this.temperature,
  });

  final double? temperature;

  @override
  State<TemperatureGauge> createState() => _TemperatureGaugeState();
}

class _TemperatureGaugeState extends State<TemperatureGauge> {
  @override
  Widget build(BuildContext context) {
    // Calculate dynamic sizes using MediaQuery
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double gaugeSize = screenWidth * 0.43; // Gauge size relative to width
    final double fontSizeTitle = screenWidth * 0.03; // Title font size
    final double fontSizeAnnotation =
        screenWidth * 0.03; // Annotation font size

    return Center(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        height: gaugeSize,
        width: gaugeSize,
        child: SfRadialGauge(
          title: GaugeTitle(
            text: "Temperature",
            textStyle: TextStyle(
              fontSize: fontSizeTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 50,
              ranges: <GaugeRange>[
                GaugeRange(
                  startValue: 0,
                  endValue: 10,
                  color: Colors.blue,
                ),
                GaugeRange(
                  startValue: 10,
                  endValue: 20,
                  color: Colors.green,
                ),
                GaugeRange(
                  startValue: 20,
                  endValue: 30,
                  color: Colors.orange,
                ),
                GaugeRange(
                  startValue: 30,
                  endValue: 40,
                  color: Colors.red,
                ),
                GaugeRange(
                  startValue: 40,
                  endValue: 50,
                  color: Colors.purple,
                ),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(
                  value: widget.temperature ?? 0,
                  enableAnimation: true,
                  animationDuration: 1000,
                  needleLength: fontSizeAnnotation * 0.03,
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Text(
                    widget.temperature != null
                        ? "${widget.temperature!.toStringAsFixed(1)} °C"
                        : "Loading...",
                    style: TextStyle(
                      fontSize: fontSizeAnnotation,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  angle: 90,
                  positionFactor: 0.7,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}






// import 'package:smart_home_front_end/exports.dart';
// import 'package:syncfusion_flutter_gauges/gauges.dart';

// class TemperatureGauge extends StatefulWidget {
//   const TemperatureGauge({
//     super.key,
//     required this.temperature,
//   });

//   final double? temperature;

//   @override
//   State<TemperatureGauge> createState() => _TemperatureGaugeState();
// }

// class _TemperatureGaugeState extends State<TemperatureGauge> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         height: MediaQuery.of(context).size.height * 0.5,
//         width: MediaQuery.of(context).size.width * 0.5,
//         child: SfRadialGauge(
//           title: GaugeTitle(
//             text: "Temperature",
//             textStyle: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           axes: <RadialAxis>[
//             RadialAxis(
//               minimum: 0,
//               maximum: 51,
//               ranges: <GaugeRange>[
//                 GaugeRange(
//                   startValue: 0,
//                   endValue: 10,
//                   color: Colors.blue,
//                 ),
//                 GaugeRange(
//                   startValue: 10,
//                   endValue: 20,
//                   color: Colors.green,
//                 ),
//                 GaugeRange(
//                   startValue: 20,
//                   endValue: 30,
//                   color: Colors.orange,
//                 ),
//                 GaugeRange(
//                   startValue: 30,
//                   endValue: 40,
//                   color: Colors.red,
//                 ),
//                 GaugeRange(
//                   startValue: 40,
//                   endValue: 50,
//                   color: Colors.purple,
//                 ),
//               ],
//               pointers: <GaugePointer>[
//                 NeedlePointer(
//                   value: widget.temperature ?? 0,
//                   enableAnimation: true,
//                 ),
//               ],
//               annotations: <GaugeAnnotation>[
//                 GaugeAnnotation(
//                   widget: Container(
//                     child: Text(
//                       widget.temperature != null
//                           ? "${widget.temperature} °C"
//                           : "Loading...",
//                       style: TextStyle(
//                         fontSize: 25,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   angle: 90,
//                   positionFactor: 0.5,
//                 ),
//               ],
//             ),
//           ],
//         ));
//   }
// }


// // Card(
// //       elevation: 4,
// //       child: ListTile(
// //         leading: Icon(Icons.thermostat, color: Colors.blue),
// //         title: Text(
// //           "Temperature",
// //           style: TextStyle(fontWeight: FontWeight.bold),
// //         ),
// //         trailing: Text(
// //           widget.temperature != null ? "${widget.temperature} °C" : "Loading...",
// //           style: TextStyle(fontSize: 16),
// //         ),
// //       ),
// //     );