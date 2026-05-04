part of '../app.dart';

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360.0;
        final scale = _responsiveScaleForWidth(maxWidth, min: 0.78);

        return SmartCard(
          padding: EdgeInsets.symmetric(
            horizontal: 18 * scale,
            vertical: 14 * scale,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.navy, size: 28 * scale),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Transform.scale(
                scale: _clampDouble(scale, 0.82, 1),
                alignment: Alignment.centerRight,
                child: Switch.adaptive(
                  value: value,
                  activeThumbColor: AppColors.green,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
