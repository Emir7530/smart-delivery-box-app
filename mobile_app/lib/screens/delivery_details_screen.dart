part of '../app.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  const DeliveryDetailsScreen({super.key, required this.delivery});

  final DeliveryItem delivery;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            GradientHeader(title: 'Order #${delivery.orderNumber}'),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = _clampDouble(
                    constraints.maxWidth * 0.06,
                    18,
                    32,
                  );
                  final verticalPadding = _clampDouble(
                    constraints.maxHeight * 0.04,
                    20,
                    32,
                  );
                  final contentWidth = _responsiveContentWidth(
                    constraints.maxWidth - horizontalPadding * 2,
                    tabletMax: 620,
                  );
                  final scale = _responsiveScaleForWidth(contentWidth);
                  final previewSize = _clampDouble(
                    contentWidth * 0.72,
                    220,
                    300,
                  );

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding + 8,
                    ),
                    children: [
                      Center(
                        child: SizedBox(
                          width: contentWidth,
                          child: SmartCard(
                            padding: EdgeInsets.all(22 * scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: PackagePreview(
                                    kind: delivery.packageKind,
                                    size: previewSize,
                                    framed: true,
                                  ),
                                ),
                                SizedBox(height: 24 * scale),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Order #${delivery.orderNumber}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.navy,
                                          fontSize: 24 * scale,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12 * scale),
                                    StatusBadge(
                                      label: delivery.status,
                                      scale: scale,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20 * scale),
                                DetailRow(
                                  icon: Icons.event_available_outlined,
                                  label: 'Delivered',
                                  value: delivery.deliveredAtLabel,
                                ),
                                SizedBox(height: 14 * scale),
                                DetailRow(
                                  icon: Icons.scale_outlined,
                                  label: 'Weight',
                                  value: delivery.weight,
                                ),
                                SizedBox(height: 14 * scale),
                                DetailRow(
                                  icon: Icons.password_rounded,
                                  label: 'OTP used',
                                  value: delivery.otpUsed,
                                ),
                                SizedBox(height: 14 * scale),
                                const DetailRow(
                                  icon: Icons.person_pin_circle_outlined,
                                  label: 'Courier',
                                  value: 'Assigned courier',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
