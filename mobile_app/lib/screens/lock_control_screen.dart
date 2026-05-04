part of '../app.dart';

class LockControlScreen extends StatelessWidget {
  const LockControlScreen({super.key});

  static const _navy = Color(0xFF062B5F);

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    final actionText = model.isLocked ? 'TAP TO\nUNLOCK' : 'TAP TO\nLOCK';
    final iconAsset = model.isLocked
        ? 'assets/images/unlocked-padlock-icon.png'
        : 'assets/images/locked-padlock-icon.png';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const _Header(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = _clampDouble(
                      constraints.maxWidth * 0.06,
                      18,
                      24,
                    );
                    final bodyWidth = math.max(
                      0.0,
                      constraints.maxWidth - horizontalPadding * 2,
                    );
                    final reservedStatusHeight = constraints.maxHeight < 560
                        ? 76.0
                        : 96.0;
                    final circleLimitByHeight =
                        math.max(
                          0.0,
                          constraints.maxHeight - 24 - reservedStatusHeight,
                        ) /
                        1.12 *
                        0.82;
                    final circleSize = _clampDouble(
                      math.min(bodyWidth * 0.84, circleLimitByHeight),
                      170,
                      330,
                    );
                    final ringHeight = circleSize * 1.12;
                    final remainingHeight = math.max(
                      0.0,
                      constraints.maxHeight -
                          24 -
                          ringHeight -
                          reservedStatusHeight,
                    );
                    final topGap = _clampDouble(remainingHeight * 0.45, 12, 74);
                    final statusGap = _clampDouble(
                      remainingHeight * 0.3,
                      10,
                      60,
                    );
                    final statusScale = _clampDouble(circleSize / 290, 0.78, 1);

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        24,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: topGap),
                          Center(
                            child: _UnlockCircleButton(
                              diameter: circleSize,
                              iconAsset: iconAsset,
                              label: actionText,
                              onTap: () =>
                                  showLockCommandDialog(context, model),
                            ),
                          ),
                          SizedBox(height: statusGap),
                          _StatusSection(
                            isLocked: model.isLocked,
                            scale: statusScale,
                          ),
                          const Spacer(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _responsiveScaleForWidth(constraints.maxWidth, min: 0.78);
        final height = _clampDouble(80 * scale, 66, 80);
        final iconSize = _clampDouble(38 * scale, 28, 38);
        final infoIconSize = _clampDouble(36 * scale, 27, 36);
        final slotWidth = _clampDouble(52 * scale, 42, 52);
        final titleSize = _clampDouble(28 * scale, 21, 28);

        return SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _clampDouble(constraints.maxWidth * 0.06, 18, 24),
              14 * scale,
              _clampDouble(constraints.maxWidth * 0.06, 18, 24),
              10 * scale,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: slotWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: LockControlScreen._navy,
                      iconSize: iconSize,
                      tooltip: 'Back',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Lock Control',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: LockControlScreen._navy,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(
                  width: slotWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.info_outline_rounded),
                      color: LockControlScreen._navy,
                      iconSize: infoIconSize,
                      tooltip: 'Info',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UnlockCircleButton extends StatelessWidget {
  const _UnlockCircleButton({
    required this.diameter,
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final double diameter;
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ringSize = diameter * 1.12;
    final iconSize = _clampDouble(diameter * 0.4, 54, 88);
    final textSize = _clampDouble(diameter * 0.07, 18, 28);
    final isUnlockedPadlock =
        iconAsset == 'assets/images/unlocked-padlock-icon.png';

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _OuterRing(size: diameter * 1.2, opacity: 0.45),
          _OuterRing(size: diameter * 1.06, opacity: 0.65),
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.42, -0.52),
                radius: 1.08,
                colors: [
                  Color(0xFF0A4E97),
                  Color(0xFF043E7B),
                  Color(0xFF011F49),
                ],
                stops: [0, 0.48, 1],
              ),
              border: Border.all(color: const Color(0xFF021F47), width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33001F4E),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
                BoxShadow(
                  color: Color(0x2E4EA8F5),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Stack(
                  children: [
                    Align(
                      alignment: const Alignment(-0.45, -0.62),
                      child: Container(
                        width: diameter * 0.56,
                        height: diameter * 0.56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scaleX: isUnlockedPadlock ? 1.05 : 1,
                            scaleY: isUnlockedPadlock ? 0.99 : 1,
                            child: Image.asset(
                              iconAsset,
                              width: iconSize,
                              height: iconSize,
                              fit: BoxFit.contain,
                              semanticLabel: label.replaceAll('\n', ' '),
                            ),
                          ),
                          SizedBox(height: diameter * 0.09),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: textSize,
                              fontWeight: FontWeight.w900,
                              height: 1.14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OuterRing extends StatelessWidget {
  const _OuterRing({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFBBDCF8).withValues(alpha: opacity),
          width: 1.2,
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.isLocked, required this.scale});

  final bool isLocked;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final statusScale = _clampDouble(scale, 0.78, 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2 * statusScale),
          child: Icon(
            isLocked ? Icons.verified_user_rounded : Icons.lock_open_rounded,
            color: const Color(0xFF19B96B),
            size: 36 * statusScale,
          ),
        ),
        SizedBox(width: 14 * statusScale),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLocked ? 'Box is secured' : 'Box is open',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: LockControlScreen._navy,
                  fontSize: 26 * statusScale,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              SizedBox(height: 9 * statusScale),
              Text(
                'Last updated just now',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF8B93A1),
                  fontSize: 18 * statusScale,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
