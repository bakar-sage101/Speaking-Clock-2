part of '../main.dart';

enum SpeakingClockIcon {
  droplet,
  bell,
  speaker,
  stretch,
  pill,
  calendar,
  target,
  shield,
}

class CustomReminderIcon extends StatelessWidget {
  const CustomReminderIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.strokeWidth = 2.2,
  });

  final SpeakingClockIcon icon;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SpeakingClockIconPainter(
          icon: icon,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SpeakingClockIconPainter extends CustomPainter {
  const _SpeakingClockIconPainter({
    required this.icon,
    required this.color,
    required this.strokeWidth,
  });

  final SpeakingClockIcon icon;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    switch (icon) {
      case SpeakingClockIcon.droplet:
        final path = Path()
          ..moveTo(w * .50, h * .10)
          ..cubicTo(w * .30, h * .34, w * .20, h * .48, w * .20, h * .64)
          ..cubicTo(w * .20, h * .84, w * .34, h * .94, w * .50, h * .94)
          ..cubicTo(w * .66, h * .94, w * .80, h * .84, w * .80, h * .64)
          ..cubicTo(w * .80, h * .48, w * .70, h * .34, w * .50, h * .10)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, paint);
        break;
      case SpeakingClockIcon.bell:
        final body = Path()
          ..moveTo(w * .26, h * .72)
          ..quadraticBezierTo(w * .31, h * .62, w * .31, h * .42)
          ..cubicTo(w * .31, h * .24, w * .42, h * .16, w * .50, h * .16)
          ..cubicTo(w * .58, h * .16, w * .69, h * .24, w * .69, h * .42)
          ..quadraticBezierTo(w * .69, h * .62, w * .74, h * .72)
          ..lineTo(w * .26, h * .72);
        canvas.drawPath(body, paint);
        canvas.drawLine(
          Offset(w * .38, h * .82),
          Offset(w * .62, h * .82),
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * .50, h * .81),
            width: w * .16,
            height: h * .16,
          ),
          0,
          3.14,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(w * .50, h * .08),
          Offset(w * .50, h * .16),
          paint,
        );
        break;
      case SpeakingClockIcon.speaker:
        final body = Path()
          ..moveTo(w * .18, h * .42)
          ..lineTo(w * .34, h * .42)
          ..lineTo(w * .54, h * .25)
          ..lineTo(w * .54, h * .75)
          ..lineTo(w * .34, h * .58)
          ..lineTo(w * .18, h * .58)
          ..close();
        canvas.drawPath(body, paint);
        canvas.drawArc(
          Rect.fromLTWH(w * .58, h * .34, w * .22, h * .32),
          -0.9,
          1.8,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromLTWH(w * .58, h * .22, w * .34, h * .56),
          -0.9,
          1.8,
          false,
          paint,
        );
        break;
      case SpeakingClockIcon.stretch:
        canvas.drawCircle(Offset(w * .50, h * .20), w * .07, paint);
        canvas.drawLine(
          Offset(w * .50, h * .30),
          Offset(w * .50, h * .58),
          paint,
        );
        canvas.drawLine(
          Offset(w * .24, h * .42),
          Offset(w * .76, h * .42),
          paint,
        );
        canvas.drawLine(
          Offset(w * .50, h * .58),
          Offset(w * .30, h * .84),
          paint,
        );
        canvas.drawLine(
          Offset(w * .50, h * .58),
          Offset(w * .70, h * .84),
          paint,
        );
        break;
      case SpeakingClockIcon.pill:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .18, h * .30, w * .64, h * .40),
          Radius.circular(w * .20),
        );
        canvas.save();
        canvas.translate(w * .50, h * .50);
        canvas.rotate(-0.72);
        canvas.translate(-w * .50, -h * .50);
        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, paint);
        canvas.drawLine(
          Offset(w * .50, h * .30),
          Offset(w * .50, h * .70),
          paint,
        );
        canvas.restore();
        break;
      case SpeakingClockIcon.calendar:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .18, h * .22, w * .64, h * .62),
          Radius.circular(w * .08),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawLine(
          Offset(w * .18, h * .40),
          Offset(w * .82, h * .40),
          paint,
        );
        canvas.drawLine(
          Offset(w * .34, h * .14),
          Offset(w * .34, h * .28),
          paint,
        );
        canvas.drawLine(
          Offset(w * .66, h * .14),
          Offset(w * .66, h * .28),
          paint,
        );
        break;
      case SpeakingClockIcon.target:
        canvas.drawCircle(Offset(w * .50, h * .50), w * .34, paint);
        canvas.drawCircle(Offset(w * .50, h * .50), w * .18, paint);
        canvas.drawCircle(Offset(w * .50, h * .50), w * .04, paint);
        break;
      case SpeakingClockIcon.shield:
        final path = Path()
          ..moveTo(w * .50, h * .12)
          ..lineTo(w * .78, h * .24)
          ..lineTo(w * .73, h * .58)
          ..quadraticBezierTo(w * .68, h * .78, w * .50, h * .90)
          ..quadraticBezierTo(w * .32, h * .78, w * .27, h * .58)
          ..lineTo(w * .22, h * .24)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, paint);
        canvas.drawLine(
          Offset(w * .38, h * .52),
          Offset(w * .47, h * .61),
          paint,
        );
        canvas.drawLine(
          Offset(w * .47, h * .61),
          Offset(w * .64, h * .42),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SpeakingClockIconPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
