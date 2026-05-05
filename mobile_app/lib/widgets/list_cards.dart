part of '../app.dart';

class DeliveryCard extends StatelessWidget {
  const DeliveryCard({super.key, required this.delivery, required this.onTap});

  final DeliveryItem delivery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final scale = _responsiveScaleForWidth(maxWidth, min: 0.76);
        final previewSize = _clampDouble(maxWidth * 0.26, 64, 88);
        final gap = _clampDouble(18 * scale, 10, 18);
        final chevronSize = _clampDouble(38 * scale, 28, 38);

        return SmartCard(
          onTap: onTap,
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            16 * scale,
            14 * scale,
            16 * scale,
          ),
          child: Row(
            children: [
              PackagePreview(
                kind: delivery.packageKind,
                size: previewSize,
                framed: true,
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Order #${delivery.orderNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 23 * scale,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        StatusBadge(label: delivery.status, scale: scale),
                      ],
                    ),
                    SizedBox(height: 12 * scale),
                    Text(
                      delivery.status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      delivery.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      'View more details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4 * scale),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.navy,
                size: chevronSize,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SecurityAlertCard extends StatelessWidget {
  const SecurityAlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  final SecurityAlertItem alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeColor = alert.severity == AlertSeverity.critical
        ? AppColors.danger
        : AppColors.muted;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final scale = _responsiveScaleForWidth(maxWidth, min: 0.78);
        final iconSize = _clampDouble(maxWidth * 0.18, 48, 64);
        final chevronSize = _clampDouble(30 * scale, 24, 30);

        return SmartCard(
          onTap: onTap,
          padding: EdgeInsets.fromLTRB(
            14 * scale,
            14 * scale,
            10 * scale,
            14 * scale,
          ),
          child: Row(
            children: [
              AlertIcon(severity: alert.severity, size: iconSize),
              SizedBox(width: 14 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.14,
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      alert.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13.5 * scale,
                        fontWeight: FontWeight.w500,
                        height: 1.26,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      alert.time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: timeColor,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: chevronSize,
              ),
            ],
          ),
        );
      },
    );
  }
}
