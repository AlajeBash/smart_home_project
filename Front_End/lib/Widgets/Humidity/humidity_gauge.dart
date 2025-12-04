import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HumidityGauge extends StatefulWidget {
  const HumidityGauge({
    super.key,
    required this.humidity,
  });

  final double? humidity;

  @override
  State<HumidityGauge> createState() => _HumidityGaugeState();
}

class _HumidityGaugeState extends State<HumidityGauge> {
  @override
  Widget build(BuildContext context) {
    // Calculate dynamic sizes using MediaQuery
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double gaugeSize =
        screenWidth * 0.43; // Adjust gauge size based on width
    final double fontSizeTitle =
        screenWidth * 0.03; // Font size relative to screen width
    final double fontSizeAnnotation = screenWidth * 0.03;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        height: gaugeSize,
        width: gaugeSize,
        child: SfRadialGauge(
          title: GaugeTitle(
            text: "Humidity",
            textStyle: TextStyle(
              fontSize: fontSizeTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 100,
              ranges: <GaugeRange>[
                GaugeRange(
                  startValue: 0,
                  endValue: 20,
                  color: Colors.blue,
                ),
                GaugeRange(
                  startValue: 20,
                  endValue: 40,
                  color: Colors.green,
                ),
                GaugeRange(
                  startValue: 40,
                  endValue: 60,
                  color: Colors.orange,
                ),
                GaugeRange(
                  startValue: 60,
                  endValue: 80,
                  color: Colors.red,
                ),
                GaugeRange(
                  startValue: 80,
                  endValue: 100,
                  color: Colors.purple,
                ),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(
                  value: widget.humidity ?? 0,
                  enableAnimation: true,
                  animationDuration: 1000,
                  needleLength: fontSizeAnnotation * 0.03,
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Text(
                    widget.humidity != null
                        ? "${widget.humidity!.toStringAsFixed(1)} %"
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

// class HumidityGauge extends StatefulWidget {
//   const HumidityGauge({
//     super.key,
//     required this.humidity,
//   });

//   final double? humidity;

//   @override
//   State<HumidityGauge> createState() => _HumidityGaugeState();
// }

// class _HumidityGaugeState extends State<HumidityGauge> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(8.0),
//       height: MediaQuery.of(context).size.height * 0.3,
//       width: MediaQuery.of(context).size.width * 0.3,
//       child: SfRadialGauge(
//         title: GaugeTitle(
//           text: "Humidity",
//           textStyle: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         axes: <RadialAxis>[
//           RadialAxis(
//             minimum: 0,
//             maximum: 101,
//             ranges: <GaugeRange>[
//               GaugeRange(
//                 startValue: 0,
//                 endValue: 20,
//                 color: Colors.blue,
//               ),
//               GaugeRange(
//                 startValue: 20,
//                 endValue: 40,
//                 color: Colors.green,
//               ),
//               GaugeRange(
//                 startValue: 40,
//                 endValue: 60,
//                 color: Colors.orange,
//               ),
//               GaugeRange(
//                 startValue: 60,
//                 endValue: 80,
//                 color: Colors.red,
//               ),
//               GaugeRange(
//                 startValue: 80,
//                 endValue: 100,
//                 color: Colors.purple,
//               ),
//             ],
//             pointers: <GaugePointer>[
//               NeedlePointer(
//                 value: widget.humidity ?? 0,
//                 enableAnimation: true,
//                 animationDuration: 1000,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Card(
// //       elevation: 4,
// //       child: ListTile(
// //         leading: Icon(Icons.water_drop, color: Colors.blue),
// //         title: Text(
// //           "Humidity",
// //           style: TextStyle(fontWeight: FontWeight.bold),
// //         ),
// //         trailing: Text(
// //           widget.humidity != null ? "${widget.humidity} %" : "Loading...",
// //           style: TextStyle(fontSize: 16),
// //         ),
// //       ),
// //     );
