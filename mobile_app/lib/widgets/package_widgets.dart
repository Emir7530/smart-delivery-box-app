part of '../app.dart';

class PackageIcon extends StatelessWidget {
  const PackageIcon({
    super.key,
    required this.size,
    this.asset = 'assets/images/package-icon.png',
    this.semanticLabel = 'Package inside',
  });

  final double size;
  final String asset;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

class PackagePreview extends StatelessWidget {
  const PackagePreview({
    super.key,
    required this.kind,
    required this.size,
    this.framed = false,
  });

  final PackageKind kind;
  final double size;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final package = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: PackagePainter(kind: kind)),
    );

    if (!framed) {
      return package;
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: const Color(0xFF10151D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: package,
    );
  }
}

class PackagePainter extends CustomPainter {
  PackagePainter({required this.kind});

  final PackageKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (kind == PackageKind.mailer) {
      final bag = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.34, w * 0.72, h * 0.38),
        Radius.circular(w * 0.06),
      );
      canvas.drawRRect(
        bag,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFE9EEF4), Color(0xFFBFC8D5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bag.outerRect),
      );
      canvas.drawRRect(
        bag,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012
          ..color = Colors.white70,
      );
      final label = Rect.fromLTWH(w * 0.34, h * 0.41, w * 0.32, h * 0.15);
      canvas.drawRect(label, Paint()..color = Colors.white);
      canvas.drawLine(
        Offset(w * 0.38, h * 0.46),
        Offset(w * 0.6, h * 0.46),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = w * 0.01,
      );
      canvas.drawLine(
        Offset(w * 0.38, h * 0.5),
        Offset(w * 0.56, h * 0.5),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = w * 0.01,
      );
      return;
    }

    final boxColor = kind == PackageKind.cardboard
        ? const Color(0xFFC68B44)
        : const Color(0xFFD7A45B);
    final front = Path()
      ..moveTo(w * 0.22, h * 0.36)
      ..lineTo(w * 0.58, h * 0.5)
      ..lineTo(w * 0.58, h * 0.82)
      ..lineTo(w * 0.22, h * 0.66)
      ..close();
    final side = Path()
      ..moveTo(w * 0.58, h * 0.5)
      ..lineTo(w * 0.8, h * 0.34)
      ..lineTo(w * 0.8, h * 0.66)
      ..lineTo(w * 0.58, h * 0.82)
      ..close();
    final top = Path()
      ..moveTo(w * 0.22, h * 0.36)
      ..lineTo(w * 0.48, h * 0.2)
      ..lineTo(w * 0.8, h * 0.34)
      ..lineTo(w * 0.58, h * 0.5)
      ..close();

    canvas.drawPath(front, Paint()..color = boxColor);
    canvas.drawPath(side, Paint()..color = const Color(0xFFB87936));
    canvas.drawPath(top, Paint()..color = const Color(0xFFE0AD65));
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..color = Colors.white.withValues(alpha: 0.45),
    );

    final tape = Paint()
      ..color = const Color(0xFFEBD4B2)
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(w * 0.49, h * 0.22),
      Offset(w * 0.62, h * 0.42),
      tape,
    );
    canvas.drawLine(
      Offset(w * 0.41, h * 0.45),
      Offset(w * 0.41, h * 0.72),
      tape,
    );

    final label = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.5, h * 0.28, w * 0.22, h * 0.11),
      Radius.circular(w * 0.01),
    );
    canvas.drawRRect(
      label,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawLine(
      Offset(w * 0.53, h * 0.32),
      Offset(w * 0.68, h * 0.32),
      Paint()
        ..color = AppColors.navy.withValues(alpha: 0.5)
        ..strokeWidth = w * 0.009,
    );
  }

  @override
  bool shouldRepaint(covariant PackagePainter oldDelegate) {
    return oldDelegate.kind != kind;
  }
}
