import 'dart:ui';
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
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Constrain gauge size so it looks great on both small mobiles and wide desktops
    final double gaugeSize = (screenWidth * 0.40).clamp(130.0, 180.0);
    final double tempValue = widget.temperature ?? 0.0;

    // Get color based on temperature range
    Color getTemperatureColor(double temp) {
      if (temp <= 15) return const Color(0xFF64B5F6); // Cold blue
      if (temp <= 25) return const Color(0xFF81C784); // Comfort green
      if (temp <= 35) return const Color(0xFFFFB74D); // Warm orange
      return const Color(0xFFE57373); // Hot red
    }

    final Color primaryColor = getTemperatureColor(tempValue);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        height: gaugeSize,
        width: gaugeSize,
        child: SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 50,
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
                  value: tempValue,
                  width: 0.08,
                  sizeUnit: GaugeSizeUnit.factor,
                  cornerStyle: CornerStyle.bothCurve,
                  gradient: SweepGradient(
                    colors: <Color>[
                      const Color(0xFF2196F3),
                      primaryColor,
                    ],
                  ),
                ),
                // Glowing needle
                NeedlePointer(
                  value: tempValue,
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
                        "${tempValue.toStringAsFixed(1)}°C",
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
                        "INDOOR TEMP",
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