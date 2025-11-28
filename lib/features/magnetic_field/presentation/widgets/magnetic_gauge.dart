import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MagneticGauge extends StatelessWidget {
  final double value;
  final double maximum;

  const MagneticGauge({super.key, required this.value, this.maximum = 200.0});

  // Helper để lấy màu dựa trên giá trị
  Color _getStrengthColor(double val) {
    if (val > 250) return Colors.purpleAccent; // > 250: Tím (Nam châm)
    if (val > 100) return Colors.red; // > 100: Đỏ (Nguy hiểm)
    if (val > 30) return Colors.orange; // > 30: Cam (Cảnh báo)
    return Colors.white; // Bình thường
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStrengthColor(value);

    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: maximum,
          showLabels: false,
          showTicks: true,
          tickOffset: -10,
          minorTicksPerInterval: 5,
          axisLineStyle: const AxisLineStyle(thickness: 0),
          pointers: <GaugePointer>[
            RangePointer(
              value: maximum,
              width: 20,
              color: Colors.grey.shade800,
              cornerStyle: CornerStyle.bothCurve,
            ),

            MarkerPointer(
              value: value, // Giá trị đã lọc
              markerHeight: 20,
              markerWidth: 20,
              markerType: MarkerType.circle,
              color: Colors.red,
              borderWidth: 2,
              borderColor: Colors.white,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: const Text(
                '0',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              angle: 180,
              positionFactor: 1.0,
            ),

            GaugeAnnotation(
              widget: Text(
                maximum.toStringAsFixed(0),
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              angle: 0,
              positionFactor: 1.0,
            ),

            GaugeAnnotation(
              widget: Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              angle: 90,
              positionFactor: 0.1,
            ),
          ],
        ),
      ],
    );
  }
}
