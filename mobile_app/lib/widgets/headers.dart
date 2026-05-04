part of '../app.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.trailing,
    this.height = 98,
    this.topPadding = 12,
    this.bottomPadding = 14,
    this.iconSize = 32,
    this.titleFontSize = 24,
  });

  final String title;
  final Widget? trailing;
  final double height;
  final double topPadding;
  final double bottomPadding;
  final double iconSize;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _responsiveScaleForWidth(constraints.maxWidth, min: 0.78);
        final resolvedHeight = _clampDouble(height * scale, 56, height);
        final resolvedIconSize = _clampDouble(iconSize * scale, 20, iconSize);
        final buttonExtent = _clampDouble(resolvedIconSize * 1.75, 40, 48);
        final titleSize = _clampDouble(
          titleFontSize * scale,
          16,
          titleFontSize,
        );
        final horizontalPadding = _clampDouble(
          constraints.maxWidth * 0.045,
          12,
          16,
        );

        return Container(
          height: top + resolvedHeight,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            top + topPadding * scale,
            horizontalPadding,
            bottomPadding * scale,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navy, AppColors.navyDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x22001F4E),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: buttonExtent,
                height: buttonExtent,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                  iconSize: resolvedIconSize,
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: buttonExtent,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: trailing ?? SizedBox.square(dimension: buttonExtent),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PlainHeader extends StatelessWidget {
  const PlainHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _responsiveScaleForWidth(constraints.maxWidth, min: 0.78);
        final iconSize = _clampDouble(32 * scale, 24, 32);
        final buttonExtent = _clampDouble(iconSize * 1.65, 40, 48);
        final titleSize = _clampDouble(24 * scale, 18, 24);
        final horizontalPadding = _clampDouble(
          constraints.maxWidth * 0.04,
          12,
          14,
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10 * scale,
            horizontalPadding,
            8 * scale,
          ),
          child: Row(
            children: [
              SizedBox(
                width: buttonExtent,
                height: buttonExtent,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.navy,
                  iconSize: iconSize,
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: buttonExtent,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: trailing ?? SizedBox.square(dimension: buttonExtent),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
