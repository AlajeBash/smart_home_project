import 'dart:ui';
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
    final double screenWidth = MediaQuery.of(context).size.width;

    // Constrain gauge size so it looks great on both small mobiles and wide desktops
    final double gaugeSize = (screenWidth * 0.40).clamp(130.0, 180.0);
    final double humValue = widget.humidity ?? 0.0;

    // Get color based on humidity range
    Color getHumidityColor(double hum) {
      if (hum <= 30) return const Color(0xFFFFB74D); // Dry orange
      if (hum <= 60) return const Color(0xFF81C784); // Comfort green
      return const Color(0xFF64B5F6); // High/Moist blue
    }

    final Color primaryColor = getHumidityColor(humValue);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        height: gaugeSize,
        width: gaugeSize,
        child: SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 100,
              showLabels: true,
              showTicks: true,
              startAngle: 140,
              endAngle: 40,
              radiusFactor: 0.95,
              axisLineStyle: const AxisLineStyle(
                thickness: 0.08,
                thicknessUnit: GaugeSizeUnit.factor,
                cornerStyle: CornerStyle.bothCurve,
                color: Color(0x15FFFFFF),
              ),
              majorTickStyle: const MajorTickStyle(
                length: 0.08,
                lengthUnit: GaugeSizeUnit.factor,
                thickness: 1.5,
                color: Colors.white24,
              ),
              minorTickStyle: const MinorTickStyle(
                length: 0.04,
                lengthUnit: GaugeSizeUnit.factor,
                thickness: 1.0,
                color: Colors.white10,
              ),
              labelStyle: const GaugeLabelStyle(
                color: Colors.white54,
                fontSize: 8.5,
                fontWeight: FontWeight.w400,
              ),
              pointers: <GaugePointer>[
                // Range progress indicator
                RangePointer(
                  value: humValue,
                  width: 0.08,
                  sizeUnit: GaugeSizeUnit.factor,
                  cornerStyle: CornerStyle.bothCurve,
                  gradient: SweepGradient(
                    colors: <Color>[
                      const Color(0xFF4FC3F7),
                      primaryColor,
                    ],
                  ),
                ),
                // Glowing needle
                NeedlePointer(
                  value: humValue,
                  enableAnimation: true,
                  animationDuration: 1200,
                  needleLength: 0.8,
                  needleWidth: 3.5,
                  needleColor: primaryColor,
                  knobStyle: KnobStyle(
                    knobRadius: 0.07,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: primaryColor,
                    borderColor: Colors.white24,
                    borderWidth: 1,
                  ),
                  tailStyle: TailStyle(
                    length: 0.15,
                    width: 3.5,
                    color: primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 18),
                      Text(
                        "${humValue.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: (gaugeSize * 0.12).clamp(15.0, 22.0),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: primaryColor.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "INDOOR HUMIDITY",
                        style: TextStyle(
                          fontSize: (gaugeSize * 0.05).clamp(7.0, 9.0),
                          fontWeight: FontWeight.w600,
                          color: Colors.white38,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  angle: 90,
                  positionFactor: 0.6,
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
