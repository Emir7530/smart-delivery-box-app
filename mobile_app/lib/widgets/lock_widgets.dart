part of '../app.dart';

Future<void> showLockCommandDialog(
  BuildContext context,
  SmartBoxModel model,
) async {
  final isUnlock = model.isLocked;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (dialogContext) {
      return Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: _clampDouble(
            MediaQuery.sizeOf(dialogContext).width * 0.08,
            18,
            30,
          ),
        ),
        backgroundColor: Colors.transparent,
        child: CommandConfirmCard(
          isUnlock: isUnlock,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            if (isUnlock) {
              model.unlock();
            } else {
              model.lock();
            }
            Navigator.of(dialogContext).pop();
            showSnack(context, isUnlock ? 'Box unlocked' : 'Box locked');
          },
        ),
      );
    },
  );
}

class CommandConfirmCard extends StatelessWidget {
  const CommandConfirmCard({
    super.key,
    required this.isUnlock,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool isUnlock;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final title = isUnlock ? 'Unlock Box?' : 'Lock Box?';
    final description = isUnlock
        ? 'This will send a secure command to open the drop-off box for delivery.'
        : 'This will send a secure command to lock the drop-off box.';
    final action = isUnlock ? 'Unlock' : 'Lock';
    final iconAsset = isUnlock
        ? 'assets/images/unlocked-padlock-icon.png'
        : 'assets/images/locked-padlock-icon.png';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 60;
        final scale = _responsiveScaleForWidth(maxWidth, min: 0.78);
        final iconCircleSize = _clampDouble(82 * scale, 64, 82);
        final buttonHeight = _clampDouble(58 * scale, 48, 58);

        return SmartCard(
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            34 * scale,
            24 * scale,
            24 * scale,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconCircleSize,
                height: iconCircleSize,
                decoration: const BoxDecoration(
                  color: Color(0xFF062B5F),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    iconAsset,
                    width: iconCircleSize * 0.56,
                    height: iconCircleSize * 0.56,
                    fit: BoxFit.contain,
                    semanticLabel: action,
                  ),
                ),
              ),
              SizedBox(height: 24 * scale),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 30 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 16 * scale),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 30 * scale),
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: buttonHeight),
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          minimumSize: Size.fromHeight(buttonHeight),
                          side: const BorderSide(color: Color(0xFFCED8E7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * scale),
                  Expanded(
                    child: PrimaryButton(
                      label: action,
                      onPressed: onConfirm,
                      height: buttonHeight,
                      fontSize: 18 * scale,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
