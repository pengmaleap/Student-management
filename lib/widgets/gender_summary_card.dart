import 'dart:math' as math;

import 'package:flutter/material.dart';

class GenderSummaryCard extends StatelessWidget {
  const GenderSummaryCard({
    super.key,
    required this.total,
    required this.female,
    required this.male,
    this.showTitleIcon = false,
    this.onTap,
  });

  static const femaleColor = Color(0xFF0D83FF);
  static const maleColor = Color(0xFF6937F4);

  final int total;
  final int female;
  final int male;
  final bool showTitleIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showTitleIcon) ...[
                const Icon(Icons.person, color: Color(0xFF159DA8), size: 28),
                const SizedBox(width: 10),
              ],
              const Text(
                'Student Gender',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Students:',
                  style: TextStyle(fontSize: 16, color: Color(0xFF738095)),
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(126),
                      painter: _GenderRingPainter(female: female, male: male),
                    ),
                    Container(
                      width: 78,
                      height: 78,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _GenderLegend(
                      color: femaleColor,
                      label: 'Female',
                      value: female,
                    ),
                    const SizedBox(height: 22),
                    _GenderLegend(color: maleColor, label: 'Male', value: male),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _GenderLegend extends StatelessWidget {
  const _GenderLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Color(0xFF444444)),
        ),
      ),
      Text(
        '$value',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF444444),
        ),
      ),
    ],
  );
}

class _GenderRingPainter extends CustomPainter {
  const _GenderRingPainter({required this.female, required this.male});

  final int female;
  final int male;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 18.0;
    const gap = 0.10;
    final total = female + male;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = const Color(0xFFE9EDF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, basePaint);

    if (total == 0) return;

    final femaleSweep = math.pi * 2 * female / total;
    final femalePaint = Paint()
      ..color = GenderSummaryCard.femaleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final malePaint = Paint()
      ..color = GenderSummaryCard.maleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (female > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + gap,
        math.max(0, femaleSweep - gap * 2),
        false,
        femalePaint,
      );
    }
    if (male > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + femaleSweep + gap,
        math.max(0, math.pi * 2 - femaleSweep - gap * 2),
        false,
        malePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GenderRingPainter oldDelegate) =>
      oldDelegate.female != female || oldDelegate.male != male;
}
