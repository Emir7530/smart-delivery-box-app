part of '../app.dart';

class SecurityAlertsScreen extends StatelessWidget {
  const SecurityAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'Security Alerts',
              height: 66,
              topPadding: 5,
              bottomPadding: 7,
              iconSize: 24,
              titleFontSize: 20,
              trailing: NotificationBell(
                alertCount: model.alerts.length,
                light: true,
                iconSize: 27,
                badgeSize: 20,
                badgeFontSize: 11,
                onTap: () {},
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = _clampDouble(
                    constraints.maxWidth * 0.055,
                    16,
                    28,
                  );
                  final verticalPadding = _clampDouble(
                    constraints.maxHeight * 0.03,
                    16,
                    26,
                  );
                  final separator = _clampDouble(
                    constraints.maxWidth * 0.035,
                    10,
                    14,
                  );

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding + 4,
                    ),
                    itemBuilder: (context, index) {
                      final alert = model.alerts[index];
                      return SecurityAlertCard(
                        alert: alert,
                        onTap: () => openScreen(
                          context,
                          AlertDetailsScreen(alert: alert),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        SizedBox(height: separator),
                    itemCount: model.alerts.length,
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

class AlertDetailsScreen extends StatelessWidget {
  const AlertDetailsScreen({super.key, required this.alert});

  final SecurityAlertItem alert;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            const GradientHeader(title: 'Alert Details'),
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
                  final alertIconSize = _clampDouble(
                    contentWidth * 0.32,
                    86,
                    112,
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
                            padding: EdgeInsets.all(24 * scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: AlertIcon(
                                    severity: alert.severity,
                                    size: alertIconSize,
                                  ),
                                ),
                                SizedBox(height: 24 * scale),
                                Text(
                                  alert.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 26 * scale,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                  ),
                                ),
                                SizedBox(height: 12 * scale),
                                Text(
                                  alert.message,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 17 * scale,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                                SizedBox(height: 24 * scale),
                                DetailRow(
                                  icon: Icons.access_time_rounded,
                                  label: 'Time',
                                  value: alert.time,
                                ),
                                if (alert.attemptTimes.isNotEmpty) ...[
                                  SizedBox(height: 20 * scale),
                                  _AttemptTimesSection(
                                    times: alert.attemptTimes,
                                    scale: scale,
                                  ),
                                ],
                                SizedBox(height: 14 * scale),
                                DetailRow(
                                  icon: Icons.sensors_rounded,
                                  label: 'Device',
                                  value: 'Smart Drop-Off Box',
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

class _AttemptTimesSection extends StatelessWidget {
  const _AttemptTimesSection({required this.times, required this.scale});

  final List<String> times;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wrong OTP attempts',
          style: TextStyle(
            color: AppColors.softMuted,
            fontSize: 13 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10 * scale),
        for (final entry in times.indexed) ...[
          _AttemptTimeRow(number: entry.$1 + 1, time: entry.$2, scale: scale),
          if (entry.$1 != times.length - 1) SizedBox(height: 8 * scale),
        ],
      ],
    );
  }
}

class _AttemptTimeRow extends StatelessWidget {
  const _AttemptTimeRow({
    required this.number,
    required this.time,
    required this.scale,
  });

  final int number;
  final String time;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32 * scale,
          height: 32 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1D7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$number',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: Text(
            'Wrong OTP entered at $time',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
