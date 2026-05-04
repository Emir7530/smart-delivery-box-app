part of '../app.dart';

class DrawerItem extends StatelessWidget {
  const DrawerItem({
    super.key,
    this.icon,
    this.iconAsset,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF07152F),
    this.height = 84,
    this.iconSize = 34,
    this.fontSize = 22,
    this.iconGap = 30,
    this.fontWeight = FontWeight.w600,
  }) : assert(icon != null || iconAsset != null);

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double height;
  final double iconSize;
  final double fontSize;
  final double iconGap;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final iconSlotSize = iconSize;

    return SizedBox(
      height: height,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            SizedBox(
              width: iconSlotSize,
              height: iconSlotSize,
              child: Center(
                child: SizedBox.square(
                  dimension: iconSize,
                  child: iconAsset == null
                      ? Icon(icon, color: color, size: iconSize)
                      : Image.asset(
                          iconAsset!,
                          fit: BoxFit.contain,
                          semanticLabel: label,
                        ),
                ),
              ),
            ),
            SizedBox(width: iconGap),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerDivider extends StatelessWidget {
  const DrawerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF1));
  }
}
