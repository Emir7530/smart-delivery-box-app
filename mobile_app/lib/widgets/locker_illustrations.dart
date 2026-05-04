part of '../app.dart';

class LockerLargeIllustration extends StatelessWidget {
  const LockerLargeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: CustomPaint(painter: LockerPainter()),
    );
  }
}

class LockerMiniIllustration extends StatelessWidget {
  const LockerMiniIllustration({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: LockerPainter(showLock: true)),
    );
  }
}

class LockerHeroIllustration extends StatelessWidget {
  const LockerHeroIllustration({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * 0.08,
            child: Container(
              width: size * 1.15,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF6),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          CustomPaint(size: Size.square(size * 0.82), painter: LockerPainter()),
          Positioned(
            left: size * 0.08,
            bottom: size * 0.2,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: size * 0.24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LockerPainter extends CustomPainter {
  LockerPainter({this.showLock = false});

  final bool showLock;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.18, w * 0.68, h * 0.66),
      Radius.circular(w * 0.045),
    );

    final shadowPaint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(body.shift(Offset(w * 0.03, h * 0.05)), shadowPaint);

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF164D8E), AppColors.navyDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(body.outerRect);
    canvas.drawRRect(body, bodyPaint);

    final sidePath = Path()
      ..moveTo(w * 0.84, h * 0.25)
      ..lineTo(w * 0.92, h * 0.34)
      ..lineTo(w * 0.92, h * 0.87)
      ..lineTo(w * 0.84, h * 0.84)
      ..close();
    canvas.drawPath(sidePath, Paint()..color = const Color(0xFF0A2A5A));

    final topPath = Path()
      ..moveTo(w * 0.16, h * 0.18)
      ..lineTo(w * 0.74, h * 0.1)
      ..lineTo(w * 0.92, h * 0.34)
      ..lineTo(w * 0.84, h * 0.25)
      ..close();
    canvas.drawPath(topPath, Paint()..color = const Color(0xFF2C65A6));

    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.31, w * 0.46, h * 0.43),
      Radius.circular(w * 0.025),
    );
    canvas.drawRRect(
      door,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..color = const Color(0xFF061B44),
    );

    final handle = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.36, h * 0.47, w * 0.28, h * 0.19),
      Radius.circular(w * 0.035),
    );
    canvas.drawRRect(handle, Paint()..color = const Color(0xFF0C356D));
    canvas.drawCircle(
      Offset(w * 0.42, h * 0.54),
      w * 0.018,
      Paint()..color = Colors.white70,
    );

    if (showLock) {
      final lockPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = w * 0.045
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final lockRect = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.57),
        width: w * 0.22,
        height: h * 0.25,
      );
      canvas.drawArc(lockRect, 3.14, 3.14, false, lockPaint);
      final lockBody = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.57, w * 0.24, h * 0.18),
        Radius.circular(w * 0.025),
      );
      canvas.drawRRect(lockBody, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.65),
        w * 0.022,
        Paint()..color = AppColors.navy,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LockerPainter oldDelegate) {
    return oldDelegate.showLock != showLock;
  }
}
