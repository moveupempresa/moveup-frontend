import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A calendar day cell marked with one or more category colors, as a full
/// circle behind the number instead of a small dot/row of dots beneath it -
/// a solid fill for one color, an even pie split when more than one applies
/// the same day. Meant for a TableCalendar `defaultBuilder`.
class DayCircle extends StatelessWidget {
  final int day;
  final List<Color> colors;

  const DayCircle({super.key, required this.day, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(36, 36),
            painter: _DayCirclePainter(colors),
          ),
          Text(
            '$day',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCirclePainter extends CustomPainter {
  final List<Color> colors;

  const _DayCirclePainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (colors.length == 1) {
      canvas.drawOval(rect, Paint()..color = colors.first);
      return;
    }
    final sweep = 2 * math.pi / colors.length;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * sweep,
        sweep,
        true,
        Paint()..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DayCirclePainter oldDelegate) =>
      !listEquals(oldDelegate.colors, colors);
}
