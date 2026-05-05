part of '../app.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = SmartBoxScope.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            GradientHeader(
              title: 'OTP Display',
              height: 66,
              topPadding: 5,
              bottomPadding: 7,
              iconSize: 24,
              titleFontSize: 20,
              trailing: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.verified_user_outlined),
                color: Colors.white,
                iconSize: 23,
                tooltip: 'Secure',
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = _clampDouble(
                    constraints.maxWidth * 0.06,
                    18,
                    24,
                  );
                  final verticalPadding = _clampDouble(
                    constraints.maxHeight * 0.025,
                    10,
                    20,
                  );
                  final contentWidth = math.min(
                    420.0,
                    math.max(0.0, constraints.maxWidth - horizontalPadding * 2),
                  );
                  final widthScale = _clampDouble(
                    constraints.maxWidth / 390,
                    0.82,
                    1,
                  );
                  final heightScale = _clampDouble(
                    constraints.maxHeight / 690,
                    0.68,
                    1,
                  );
                  final scale = math.min(widthScale, heightScale);
                  final cardScale = scale * 0.85;

                  final content = SizedBox(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 132 * scale,
                          height: 132 * scale,
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
                        SizedBox(height: 16 * scale),
                        SmartCard(
                          padding: EdgeInsets.fromLTRB(
                            24 * cardScale,
                            24 * cardScale,
                            24 * cardScale,
                            24 * cardScale,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52 * cardScale,
                                height: 52 * cardScale,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF3F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.navy,
                                  size: 28 * cardScale,
                                ),
                              ),
                              SizedBox(height: 16 * cardScale),
                              Text(
                                'Your OTP Code',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 19 * cardScale,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 14 * cardScale),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  model.otpCode,
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 56 * cardScale,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 6 * cardScale,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x1E001F4E),
                                        blurRadius: 12,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16 * cardScale),
                              Text(
                                'Share this code with your courier',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 15 * cardScale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 20 * cardScale),
                              const Divider(
                                color: AppColors.border,
                                thickness: 1,
                              ),
                              SizedBox(height: 18 * cardScale),
                              Text(
                                'Expires in',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 17 * cardScale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 6 * cardScale),
                              Text(
                                model.otpExpiresIn,
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 36 * cardScale,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 18 * scale),
                        PrimaryButton(
                          label: 'Copy Code',
                          icon: Icons.copy_rounded,
                          height: 54 * scale,
                          fontSize: 17 * scale,
                          iconSize: 23 * scale,
                          iconGap: 10 * scale,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: model.otpCode),
                            );
                            if (context.mounted) {
                              showSnack(context, 'OTP copied');
                            }
                          },
                        ),
                        SizedBox(height: 18 * scale),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.muted,
                                size: 23 * scale,
                              ),
                              SizedBox(width: 12 * scale),
                              Expanded(
                                child: Text(
                                  'This OTP is valid for a single use only.\nDo not share it with anyone else.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13.5 * scale,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(
                                0.0,
                                constraints.maxHeight - verticalPadding * 2,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: content,
                            ),
                          ),
                        ),
                      ),
                    ),
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
