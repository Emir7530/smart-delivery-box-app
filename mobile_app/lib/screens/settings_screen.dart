part of '../app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            const GradientHeader(title: 'Settings'),
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
                  final illustrationSize = _clampDouble(
                    contentWidth * 0.2,
                    58,
                    76,
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
                          child: Column(
                            children: [
                              SmartCard(
                                padding: EdgeInsets.all(22 * scale),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: illustrationSize,
                                      height: illustrationSize,
                                      child: Image.asset(
                                        model.isLocked
                                            ? 'assets/images/case-locked.png'
                                            : 'assets/images/case-unlocked.png',
                                        fit: BoxFit.contain,
                                        semanticLabel: model.isLocked
                                            ? 'Locked drop-off case'
                                            : 'Unlocked drop-off case',
                                      ),
                                    ),
                                    SizedBox(width: 18 * scale),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Smart Drop-Off Box',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontSize: 20 * scale,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(height: 6 * scale),
                                          Text(
                                            model.isOnline
                                                ? 'Online - Battery ${model.batteryPercent}%'
                                                : 'Offline',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 15 * scale,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 18 * scale),
                              SettingsToggle(
                                icon: Icons.notifications_active_outlined,
                                label: 'Security notifications',
                                value: notifications,
                                onChanged: (value) =>
                                    setState(() => notifications = value),
                              ),
                            ],
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
