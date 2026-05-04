part of '../app.dart';

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final scale = _responsiveScaleForWidth(maxWidth, min: 0.78);
        final tileSize = _clampDouble(42 * scale, 34, 42);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FA),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Icon(
                icon,
                color: AppColors.navy,
                size: _clampDouble(24 * scale, 19, 24),
              ),
            ),
            SizedBox(width: 14 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.softMuted,
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class AlertIcon extends StatelessWidget {
  const AlertIcon({super.key, required this.severity, this.size = 84});

  final AlertSeverity severity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final Color background;

    switch (severity) {
      case AlertSeverity.critical:
        icon = Icons.shield_rounded;
        color = AppColors.danger;
        background = AppColors.roseSoft;
        break;
      case AlertSeverity.warning:
        icon = Icons.lock_outline_rounded;
        color = AppColors.warning;
        background = const Color(0xFFFFF1D7);
        break;
      case AlertSeverity.success:
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.green;
        background = const Color(0xFFE2F8EA);
        break;
      case AlertSeverity.battery:
        icon = Icons.battery_alert_outlined;
        color = const Color(0xFFFF8500);
        background = const Color(0xFFFFF0D6);
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Container(
        margin: EdgeInsets.all(size * 0.17),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.42),
      ),
    );
  }
}
