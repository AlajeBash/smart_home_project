import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ClimateTrendsChart extends StatelessWidget {
  const ClimateTrendsChart({
    super.key,
    required this.dataPoints,
    required this.lineColor,
    required this.label,
    required this.suffix,
  });

  final List<double> dataPoints;
  final Color lineColor;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: lineColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: lineColor.withOpacity(0.3), width: 0.8),
              ),
              child: Text(
                "Live Analytics",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: lineColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _TrendPainter(
              data: dataPoints,
              color: lineColor,
              suffix: suffix,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final String suffix;

  _TrendPainter({required this.data, required this.color, required this.suffix});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    // Boundary margins
    const double paddingLeft = 30.0;
    const double paddingRight = 10.0;
    const double paddingTop = 15.0;
    const double paddingBottom = 20.0;

    final double chartWidth = width - paddingLeft - paddingRight;
    final double chartHeight = height - paddingTop - paddingBottom;

    // Find min and max
    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    
    // Add small buffer to range to avoid dividing by zero and provide nice ceiling
    if (maxVal == minVal) {
      maxVal += 5.0;
      minVal -= 5.0;
    } else {
      final double buffer = (maxVal - minVal) * 0.15;
      maxVal += buffer;
      minVal -= buffer;
    }

    final double valRange = maxVal - minVal;

    // Draw grid horizontal lines
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const int gridLinesCount = 3;
    for (int i = 0; i <= gridLinesCount; i++) {
      final double y = paddingTop + (chartHeight / gridLinesCount) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(width - paddingRight, y), gridPaint);

      // Value Label
      final double gridVal = maxVal - (valRange / gridLinesCount) * i;
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: "${gridVal.toStringAsFixed(0)}$suffix",
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height / 2),
      );
    }

    // Prepare coordinates of data points
    final List<Offset> points = [];
    final double stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final double x = paddingLeft + i * stepX;
      final double y = paddingTop + chartHeight - ((data[i] - minVal) / valRange) * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw Underline Gradient Area
    final Path pathArea = Path();
    pathArea.moveTo(points.first.dx, paddingTop + chartHeight);
    for (int i = 0; i < points.length; i++) {
      pathArea.lineTo(points[i].dx, points[i].dy);
    }
    pathArea.lineTo(points.last.dx, paddingTop + chartHeight);
    pathArea.close();

    final Paint fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(width / 2, paddingTop),
        Offset(width / 2, paddingTop + chartHeight),
        [
          color.withOpacity(0.24),
          color.withOpacity(0.00),
        ],
      )
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(pathArea, fillPaint);

    // Draw Line (Smooth Path)
    final Path linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = points[i];
      final Offset p1 = points[i + 1];
      
      // Control points for cubic bezier curve to make lines smooth
      final double controlX1 = p0.dx + stepX / 2;
      final double controlY1 = p0.dy;
      final double controlX2 = p1.dx - stepX / 2;
      final double controlY2 = p1.dy;

      linePath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw glowing node points (outer circles)
    final Paint nodeOutPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw main points (inner solid circle)
    final Paint nodeInPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint nodeBorderPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Only draw nodes for endpoints and critical nodes to keep clean
    for (int i = 0; i < points.length; i++) {
      final bool isEndpoint = (i == 0 || i == points.length - 1);
      final bool isHigh = (data[i] == maxVal);
      final bool isLow = (data[i] == minVal);

      if (isEndpoint || isHigh || isLow) {
        // Outer glowing halo
        canvas.drawCircle(points[i], 7.0, nodeOutPaint);
        // Core border
        canvas.drawCircle(points[i], 3.5, nodeInPaint);
        canvas.drawCircle(points[i], 3.5, nodeBorderPaint);
      }
    }

    // X-axis Time Labels
    const List<String> timeLabels = ["12 PM", "04 PM", "08 PM", "12 AM", "04 AM", "08 AM"];
    final double stepLabelX = chartWidth / (timeLabels.length - 1);
    for (int i = 0; i < timeLabels.length; i++) {
      final double lx = paddingLeft + i * stepLabelX;
      final TextPainter timePainter = TextPainter(
        text: TextSpan(
          text: timeLabels[i],
          style: TextStyle(
            fontSize: 8.0,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.25),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      timePainter.paint(
        canvas,
        Offset(lx - timePainter.width / 2, height - timePainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
