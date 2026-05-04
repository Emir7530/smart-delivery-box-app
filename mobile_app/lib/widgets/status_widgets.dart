part of '../app.dart';

class StatusLine extends StatelessWidget {
  const StatusLine({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.scale = 1});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final labelScale = _clampDouble(scale, 0.72, 1);

    return Text(
      label,
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 15 * labelScale,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.scale = 1});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final badgeScale = _clampDouble(scale, 0.78, 1);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * badgeScale,
        vertical: 7 * badgeScale,
      ),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFF0BA536),
          fontSize: 14 * badgeScale,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.alertCount,
    required this.onTap,
    this.light = false,
    this.showBadge = true,
    this.iconSize = 33,
    this.badgeSize,
    this.badgeFontSize,
  });

  final int alertCount;
  final VoidCallback onTap;
  final bool light;
  final bool showBadge;
  final double iconSize;
  final double? badgeSize;
  final double? badgeFontSize;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.navy;
    final effectiveBadgeSize = badgeSize ?? (light ? 24 : 9);
    final badgeOffset = _clampDouble(iconSize * 0.16, 4, 6);
    return IconButton(
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded, color: color, size: iconSize),
          if (showBadge && alertCount > 0)
            Positioned(
              right: -badgeOffset,
              top: -badgeOffset,
              child: Container(
                width: effectiveBadgeSize,
                height: effectiveBadgeSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: light ? AppColors.danger : AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: light
                    ? Text(
                        '$alertCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: badgeFontSize ?? 13,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
      tooltip: 'Notifications',
    );
  }
}
