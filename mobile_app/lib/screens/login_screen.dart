part of '../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSignIn,
    required this.onRegister,
  });

  final SignInHandler onSignIn;
  final RegisterHandler onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(onRegister: widget.onRegister),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    final error = await widget.onSignIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _errorText = error;
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = _clampDouble(
                constraints.maxWidth * 0.07,
                18,
                28,
              );
              final verticalPadding = _clampDouble(
                constraints.maxHeight * 0.02,
                8,
                18,
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
                constraints.maxHeight / 760,
                0.76,
                1,
              );
              final scale = math.min(widthScale, heightScale);

              final content = SizedBox(
                width: contentWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppLogoMark(size: 146 * scale),
                    SizedBox(height: 10 * scale),
                    Text(
                      'SMART',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 31 * scale,
                        height: 0.95,
                      ),
                    ),
                    Text(
                      'DROP-OFF BOX',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 21 * scale,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      'Secure. Smart. Simplified.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 34 * scale),
                    AppTextField(
                      controller: _emailController,
                      hintText: 'Email address',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      fontSize: 15 * scale,
                      iconSize: 22 * scale,
                      verticalPadding: 18 * scale,
                      horizontalPadding: 18 * scale,
                    ),
                    SizedBox(height: 14 * scale),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      suffixIcon: Icons.visibility_outlined,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      fontSize: 15 * scale,
                      iconSize: 22 * scale,
                      verticalPadding: 18 * scale,
                      horizontalPadding: 18 * scale,
                    ),
                    if (_errorText != null) ...[
                      SizedBox(height: 10 * scale),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    SizedBox(height: 8 * scale),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.navy,
                          padding: EdgeInsets.zero,
                          minimumSize: Size(120 * scale, 32 * scale),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12 * scale,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    PrimaryButton(
                      label: 'Sign In',
                      onPressed: _isSubmitting ? null : _submit,
                      height: 58 * scale,
                      fontSize: 18 * scale,
                    ),
                    SizedBox(height: 24 * scale),
                    DividerWithText(label: 'or', scale: scale),
                    SizedBox(height: 18 * scale),
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: _openRegister,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                        minimumSize: Size(120 * scale, 32 * scale),
                      ),
                      child: Text(
                        'Create account',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13 * scale,
                        ),
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
                        child: Center(child: content),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
