part of '../app.dart';

Color batteryLevelColor(int percentage) {
  final clampedPercentage = percentage.clamp(0, 100).toInt();
  if (clampedPercentage <= 20) {
    return const Color(0xFFF10F0F);
  }
  if (clampedPercentage < 50) {
    return const Color(0xFFFFB000);
  }
  return const Color(0xFF10C864);
}

String batteryLevelLabel(int percentage) {
  final clampedPercentage = percentage.clamp(0, 100).toInt();
  if (clampedPercentage <= 20) {
    return 'Low';
  }
  if (clampedPercentage < 50) {
    return 'Medium';
  }
  return 'Good';
}

class BatteryIcon extends StatelessWidget {
  const BatteryIcon({
    super.key,
    required this.percentage,
    this.width = 96,
    this.height = 48,
    this.quarterTurns = 0,
  });

  /// Example usage:
  /// BatteryIcon(percentage: 50)
  /// BatteryIcon(percentage: 20)
  /// BatteryIcon(percentage: 85)
  final int percentage;
  final double width;
  final double height;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: BatteryPainter(percentage: percentage)),
    );

    if (quarterTurns == 0) {
      return icon;
    }

    return RotatedBox(quarterTurns: quarterTurns, child: icon);
  }
}

class BatteryPainter extends CustomPainter {
  BatteryPainter({required this.percentage});

  final int percentage;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final clampedPercentage = percentage.clamp(0, 100).toInt();
    final strokeWidth = math.max(1.8, h * 0.08);
    final tipWidth = w * 0.08;
    final tipHeight = h * 0.36;
    final fillColor = batteryLevelColor(percentage);
    final bodyRect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      w - tipWidth - strokeWidth * 1.5,
      h - strokeWidth,
    );
    final body = RRect.fromRectAndRadius(bodyRect, Radius.circular(h * 0.16));
    final innerRect = bodyRect.deflate(strokeWidth * 1.7);
    final fillWidth = innerRect.width * (clampedPercentage / 100);
    final fillRect = Rect.fromLTWH(
      innerRect.left,
      innerRect.top,
      fillWidth,
      innerRect.height,
    );
    final fill = RRect.fromRectAndRadius(fillRect, Radius.circular(h * 0.1));
    final tip = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyRect.right, (h - tipHeight) / 2, tipWidth, tipHeight),
      Radius.circular(h * 0.05),
    );

    canvas.drawShadow(
      Path()..addRRect(body),
      Colors.black.withValues(alpha: 0.12),
      2,
      true,
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFF9FBFD));
    canvas.drawRRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [fillColor.withValues(alpha: 0.86), fillColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(fill.outerRect),
    );
    canvas.drawRRect(tip, Paint()..color = AppColors.navy);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = const Color(0xFFC9D3DE),
    );
  }

  @override
  bool shouldRepaint(covariant BatteryPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
