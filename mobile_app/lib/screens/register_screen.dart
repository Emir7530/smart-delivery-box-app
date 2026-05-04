part of '../app.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onRegister});

  final RegisterHandler onRegister;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.onRegister(
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (error != null && mounted) {
      setState(() => _errorText = error);
    }
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
                constraints.maxHeight * 0.018,
                8,
                16,
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
                constraints.maxHeight / 820,
                0.68,
                1,
              );
              final scale = math.min(widthScale, heightScale);

              final content = SizedBox(
                width: contentWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.navy,
                        iconSize: 32 * scale,
                        tooltip: 'Back',
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Center(child: AppLogoMark(size: 112 * scale)),
                    SizedBox(height: 14 * scale),
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 30 * scale,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 7 * scale),
                    Text(
                      'Set up your smart drop-off box access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 28 * scale),
                    AppTextField(
                      controller: _nameController,
                      hintText: 'Full name',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      fontSize: 15 * scale,
                      iconSize: 22 * scale,
                      verticalPadding: 17 * scale,
                      horizontalPadding: 18 * scale,
                    ),
                    SizedBox(height: 13 * scale),
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
                      verticalPadding: 17 * scale,
                      horizontalPadding: 18 * scale,
                    ),
                    SizedBox(height: 13 * scale),
                    AppTextField(
                      controller: _phoneController,
                      hintText: 'Phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      fontSize: 15 * scale,
                      iconSize: 22 * scale,
                      verticalPadding: 17 * scale,
                      horizontalPadding: 18 * scale,
                    ),
                    SizedBox(height: 13 * scale),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      suffixIcon: Icons.visibility_outlined,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      fontSize: 15 * scale,
                      iconSize: 22 * scale,
                      verticalPadding: 17 * scale,
                      horizontalPadding: 18 * scale,
                    ),
                    SizedBox(height: 13 * scale),
                    AppTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm password',
                      icon: Icons.lock_reset_rounded,
                      obscureText: true,
                      suffixIcon: Icons.visibility_outlined,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => _submit(),
                      fontSize: 15 * scale,
                      iconSize: 22 * scale,
                      verticalPadding: 17 * scale,
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
                    SizedBox(height: 22 * scale),
                    PrimaryButton(
                      label: 'Create Account',
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: _submit,
                      height: 58 * scale,
                      fontSize: 18 * scale,
                      iconSize: 22 * scale,
                      iconGap: 10 * scale,
                    ),
                    SizedBox(height: 18 * scale),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                            ),
                            minimumSize: Size(58 * scale, 32 * scale),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13 * scale,
                            ),
                          ),
                        ),
                      ],
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
