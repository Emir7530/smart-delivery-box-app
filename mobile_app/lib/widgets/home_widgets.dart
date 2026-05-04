part of '../app.dart';

class DeviceHeroCard extends StatelessWidget {
  const DeviceHeroCard({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);
    final paddingX = 18 * cardScale;
    final paddingY = 18 * cardScale;
    final illustrationSize = _clampDouble(178 * cardScale, 140, 198);
    final statusSize = 64 * cardScale;

    return Container(
      padding: EdgeInsets.fromLTRB(paddingX, paddingY, paddingX, paddingY),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(18 * cardScale),
        border: Border.all(color: const Color(0xFFD8E6F5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 18 * cardScale,
            offset: Offset(0, 9 * cardScale),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;
          return Row(
            children: [
              Expanded(
                flex: compact ? 7 : 6,
                child: Center(
                  child: SizedBox(
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
                ),
              ),
              SizedBox(width: 12 * cardScale),
              Expanded(
                flex: compact ? 5 : 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: statusSize,
                      height: statusSize,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: model.isLocked
                          ? Transform.scale(
                              scale: 1.1,
                              child: Image.asset(
                                'assets/images/locked-icon.png',
                                fit: BoxFit.cover,
                                semanticLabel: 'Box locked',
                              ),
                            )
                          : Image.asset(
                              'assets/images/unlocked-icon.png',
                              fit: BoxFit.cover,
                              semanticLabel: 'Box unlocked',
                            ),
                    ),
                    SizedBox(height: 14 * cardScale),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        model.isLocked ? 'LOCKED' : 'OPEN',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 27 * cardScale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * cardScale),
                    Text(
                      model.isLocked ? 'Box is secured' : 'Ready for delivery',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16 * cardScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PackageStatusCard extends StatelessWidget {
  const PackageStatusCard({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);
    final packageLabel = model.hasPackage
        ? 'Package\nInside'
        : 'No Package\nInside';
    final packageAsset = model.hasPackage
        ? 'assets/images/package-icon.png'
        : 'assets/images/package-unlocked-icon.png';

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 108 * cardScale),
      child: SmartCard(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * cardScale,
          vertical: 16 * cardScale,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 58 * cardScale,
              height: 64 * cardScale,
              child: ClipRect(
                child: Transform.scale(
                  scale: model.hasPackage ? 1.85 : 1.0,
                  child: Transform.translate(
                    offset: Offset(model.hasPackage ? 4 * cardScale : 0, 0),
                    child: PackageIcon(
                      size: 64 * cardScale,
                      asset: packageAsset,
                      semanticLabel: packageLabel.replaceAll('\n', ' '),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10 * cardScale),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      packageLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18 * cardScale,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6 * cardScale),
                    Text(
                      'Just now',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14 * cardScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BatteryStatusCard extends StatelessWidget {
  const BatteryStatusCard({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final cardScale = _clampDouble(scale, 0.72, 1);
    final batteryPercent = model.batteryPercent;
    final batteryColor = batteryLevelColor(batteryPercent);
    final batteryLabel = batteryLevelLabel(batteryPercent);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 108 * cardScale),
      child: SmartCard(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * cardScale,
          vertical: 16 * cardScale,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 62 * cardScale,
              child: Center(
                child: BatteryIcon(
                  percentage: batteryPercent,
                  width: 72 * cardScale,
                  height: 38 * cardScale,
                  quarterTurns: 3,
                ),
              ),
            ),
            SizedBox(width: 8 * cardScale),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Battery',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 18 * cardScale,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      '$batteryPercent%',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 28 * cardScale,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    Text(
                      batteryLabel,
                      style: TextStyle(
                        color: batteryColor,
                        fontSize: 15 * cardScale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.onTap,
    this.scale = 1,
  }) : assert(icon != null || iconAsset != null);

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 180.0;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 120.0;
        final widthScale = _clampDouble(maxWidth / 170, 0.68, 1);
        final heightScale = _clampDouble(maxHeight / 112, 0.68, 1);
        final tileScale = math.min(
          _clampDouble(scale, 0.72, 1),
          math.min(widthScale, heightScale),
        );
        final horizontalPadding = _clampDouble(14 * tileScale, 8, 14);
        final verticalPadding = _clampDouble(10 * tileScale, 6, 10);
        final innerWidth = math.max(0.0, maxWidth - horizontalPadding * 2);
        final innerHeight = math.max(0.0, maxHeight - verticalPadding * 2);
        final gap = _clampDouble(3 * tileScale, 2, 3);
        final labelLines = innerHeight < 74 ? 1 : 2;
        final labelFontSize = _clampDouble(17 * tileScale, 11, 17);
        final labelReserve = labelFontSize * 1.12 * labelLines;
        final iconSize = _clampDouble(
          math.min(
            72 * tileScale,
            math.min(innerWidth * 0.66, innerHeight - gap - labelReserve),
          ),
          24,
          72 * tileScale,
        );

        return SmartCard(
          onTap: onTap,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                flex: 5,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _buildIcon(iconSize),
                  ),
                ),
              ),
              SizedBox(height: gap),
              Flexible(
                flex: 3,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: labelLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon(double size) {
    if (iconAsset != null) {
      return Image.asset(
        iconAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticLabel: label,
      );
    }

    return Icon(icon, size: size, color: AppColors.navy, semanticLabel: label);
  }
}
