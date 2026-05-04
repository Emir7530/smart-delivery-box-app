part of '../app.dart';

class SmartDrawer extends StatelessWidget {
  const SmartDrawer({super.key, required this.onSignOut});

  static const _navy = Color(0xFF07152F);
  static const _headerStart = Color(0xFF061B3D);
  static const _headerEnd = Color(0xFF082B5E);
  static const _muted = Color(0xFF66758F);
  static const _danger = Color(0xFFD94663);

  final VoidCallback onSignOut;

  void _closeAndOpen(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (context.mounted) {
        openScreen(context, screen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = math.min(screenWidth * 0.82, 380.0);

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: const Color(0xFFFEFEFF),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final safePadding = MediaQuery.paddingOf(context);
            final height = constraints.maxHeight;

            final tiny = height < 640;
            final tight = height < 730;
            final compact = height < 850;

            final sidePadding = tiny ? 18.0 : (compact ? 24.0 : 26.0);

            final headerContentHeight = tiny
                ? 112.0
                : (tight ? 126.0 : (compact ? 142.0 : 154.0));

            final headerHeight = headerContentHeight + safePadding.top;
            final bodyHeight = math.max(0.0, height - headerHeight);

            final bodyTop = tiny ? 8.0 : (compact ? 16.0 : 24.0);

            final bodyBottom =
                safePadding.bottom + (tiny ? 8.0 : (tight ? 12.0 : 18.0));

            final statusTop = tiny ? 10.0 : (tight ? 16.0 : 28.0);
            final statusMinHeight = tiny ? 104.0 : (tight ? 124.0 : 140.0);
            final signOutHeight = tiny ? 46.0 : (tight ? 56.0 : 72.0);

            final menuCount = 4;
            final dividerHeight = 3.0;
            final dividerCount = menuCount - 1;
            final dividerTotalHeight = dividerCount * dividerHeight;

            final minSpacer = tiny ? 4.0 : 8.0;

            final menuRoom =
                bodyHeight -
                bodyTop -
                bodyBottom -
                statusTop -
                statusMinHeight -
                signOutHeight -
                minSpacer -
                dividerTotalHeight;

            final itemHeight = _clampDouble(
              menuRoom / menuCount,
              tiny ? 36 : 42,
              86,
            );

            final iconSize = _clampDouble(itemHeight * 0.42, 24, 36);
            final fontSize = _clampDouble(itemHeight * 0.3, 16, 23);
            final iconGap = tiny ? 20.0 : (compact ? 28.0 : 31.0);

            final fixedBodyHeight =
                menuCount * itemHeight +
                dividerTotalHeight +
                statusTop +
                statusMinHeight +
                signOutHeight;

            final bottomGap = math.max(
              minSpacer,
              bodyHeight - bodyTop - bodyBottom - fixedBodyHeight,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Column(
                  children: [
                    _DrawerHeader(
                      height: headerHeight,
                      topPadding: safePadding.top,
                      sidePadding: sidePadding,
                      compact: compact,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        sidePadding,
                        bodyTop,
                        sidePadding,
                        bodyBottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DrawerItem(
                            icon: Icons.home_outlined,
                            label: 'Home',
                            height: itemHeight,
                            iconSize: iconSize,
                            fontSize: fontSize,
                            iconGap: iconGap,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const DrawerDivider(),
                          DrawerItem(
                            icon: Icons.lock_outline_rounded,
                            label: 'Lock Control',
                            height: itemHeight,
                            iconSize: iconSize,
                            fontSize: fontSize,
                            iconGap: iconGap,
                            onTap: () => _closeAndOpen(
                              context,
                              const LockControlScreen(),
                            ),
                          ),
                          const DrawerDivider(),
                          DrawerItem(
                            icon: Icons.assignment_outlined,
                            label: 'Delivery History',
                            height: itemHeight,
                            iconSize: iconSize,
                            fontSize: fontSize,
                            iconGap: iconGap,
                            onTap: () => _closeAndOpen(
                              context,
                              const DeliveryHistoryScreen(),
                            ),
                          ),
                          const DrawerDivider(),
                          DrawerItem(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            height: itemHeight,
                            iconSize: iconSize,
                            fontSize: fontSize,
                            iconGap: iconGap,
                            onTap: () =>
                                _closeAndOpen(context, const SettingsScreen()),
                          ),
                          SizedBox(height: statusTop),
                          _DeviceStatusCard(
                            minHeight: statusMinHeight,
                            model: model,
                            compact: compact,
                            tiny: tiny,
                          ),
                          SizedBox(height: bottomGap),
                          DrawerItem(
                            icon: Icons.logout_rounded,
                            label: 'Sign Out',
                            color: _danger,
                            height: signOutHeight,
                            iconSize: iconSize,
                            fontSize: _clampDouble(fontSize, 18, 22),
                            iconGap: iconGap,
                            onTap: onSignOut,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.height,
    required this.topPadding,
    required this.sidePadding,
    required this.compact,
  });

  final double height;
  final double topPadding;
  final double sidePadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 68.0 : 72.0;

    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(sidePadding, topPadding, sidePadding, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [SmartDrawer._headerStart, SmartDrawer._headerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: logoSize,
            height: logoSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppLogoMark(size: logoSize * 0.72, compact: true),
            ),
          ),
          SizedBox(width: compact ? 18 : 22),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Drop-Off Box',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 21 : 23,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Secure. Simple. Smart.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard({
    required this.minHeight,
    required this.model,
    required this.compact,
    required this.tiny,
  });

  final double minHeight;
  final SmartBoxModel model;
  final bool compact;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    final illustrationSize = tiny ? 56.0 : (compact ? 74.0 : 88.0);

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 13 : 15,
        tiny ? 10 : (compact ? 13 : 18),
        compact ? 9 : 11,
        tiny ? 10 : (compact ? 13 : 18),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14071D3A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Device Status',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SmartDrawer._muted,
                    fontSize: tiny ? 14.5 : (compact ? 16 : 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: tiny ? 8 : (compact ? 11 : 18)),
                _DrawerStatusLine(
                  icon: Icons.circle,
                  iconColor: AppColors.green,
                  label: model.isOnline ? 'Online' : 'Offline',
                  compact: compact,
                  tiny: tiny,
                ),
                SizedBox(height: tiny ? 6 : (compact ? 8 : 13)),
                _DrawerBatteryStatusLine(
                  percentage: model.batteryPercent,
                  compact: compact,
                  tiny: tiny,
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          SizedBox(
            width: illustrationSize,
            height: illustrationSize,
            child: Image.asset(
              'assets/images/case-locked.png',
              fit: BoxFit.contain,
              semanticLabel: 'Locked drop-off case',
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerBatteryStatusLine extends StatelessWidget {
  const _DrawerBatteryStatusLine({
    required this.percentage,
    required this.compact,
    required this.tiny,
  });

  final int percentage;
  final bool compact;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    final iconWidth = tiny ? 24.0 : (compact ? 27.0 : 30.0);
    final iconHeight = tiny ? 13.0 : (compact ? 14.5 : 16.0);

    return Row(
      children: [
        SizedBox(
          width: tiny ? 24 : (compact ? 27 : 30),
          child: Center(
            child: BatteryIcon(
              percentage: percentage,
              width: iconWidth,
              height: iconHeight,
            ),
          ),
        ),
        SizedBox(width: tiny ? 7 : (compact ? 9 : 11)),
        Expanded(
          child: Text(
            'Battery: $percentage%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: batteryLevelColor(percentage),
              fontSize: tiny ? 10 : (compact ? 11.5 : 12),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerStatusLine extends StatelessWidget {
  const _DrawerStatusLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.compact,
    required this.tiny,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool compact;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: tiny ? 13 : (compact ? 15 : 17)),
        SizedBox(width: tiny ? 7 : (compact ? 9 : 11)),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: SmartDrawer._navy,
              fontSize: tiny ? 10 : (compact ? 11.5 : 12),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
