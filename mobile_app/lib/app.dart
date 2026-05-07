import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'theme/app_colors.dart';
part 'utils/layout.dart';
part 'models/smart_box_scope.dart';
part 'models/smart_box_model.dart';
part 'screens/login_screen.dart';
part 'screens/register_screen.dart';
part 'screens/home_screen.dart';
part 'screens/lock_control_screen.dart';
part 'screens/delivery_history_screen.dart';
part 'screens/delivery_details_screen.dart';
part 'screens/security_alerts_screen.dart';
part 'screens/otp_screen.dart';
part 'screens/settings_screen.dart';
part 'widgets/drawer.dart';
part 'widgets/drawer_items.dart';
part 'widgets/headers.dart';
part 'widgets/controls.dart';
part 'widgets/smart_card.dart';
part 'widgets/home_widgets.dart';
part 'widgets/list_cards.dart';
part 'widgets/settings_toggle.dart';
part 'widgets/status_widgets.dart';
part 'widgets/lock_widgets.dart';
part 'widgets/detail_widgets.dart';
part 'widgets/app_logo_mark.dart';
part 'widgets/locker_illustrations.dart';
part 'widgets/package_widgets.dart';
part 'widgets/battery_widgets.dart';
part 'utils/navigation.dart';
part 'utils/api_client.dart';

typedef SignInHandler =
    Future<String?> Function({required String email, required String password});

typedef RegisterHandler =
    Future<String?> Function({
      required String fullName,
      required String email,
      required String phone,
      required String password,
      required String confirmPassword,
    });

class SmartDropOffApp extends StatefulWidget {
  const SmartDropOffApp({super.key, this.apiClient});

  final SmartBoxApiClient? apiClient;

  @override
  State<SmartDropOffApp> createState() => _SmartDropOffAppState();
}

class _SmartDropOffAppState extends State<SmartDropOffApp> {
  static const _authTokenKey = 'smart_box_auth_token';

  final SmartBoxModel _model = SmartBoxModel();
  late final SmartBoxApiClient _apiClient;
  late final bool _ownsApiClient;
  bool _signedIn = false;
  bool _bootstrappingSession = true;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? SmartBoxApiClient();
    _ownsApiClient = widget.apiClient == null;
    _restoreSession();
  }

  @override
  void dispose() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
    _model.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString(_authTokenKey);
      if (token == null || token.isEmpty) {
        return;
      }

      final user = await _apiClient.me(token);
      _model.setUserName(user.fullName);
      if (mounted) {
        setState(() => _signedIn = true);
      }
    } catch (_) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_authTokenKey);
    } finally {
      if (mounted) {
        setState(() => _bootstrappingSession = false);
      }
    }
  }

  Future<String?> _signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final cleanPassword = password.trim();

    if (normalizedEmail.isEmpty || cleanPassword.isEmpty) {
      return 'Enter your email and password.';
    }

    try {
      final session = await _apiClient.login(
        email: normalizedEmail,
        password: cleanPassword,
      );
      await _completeSignIn(session);
      return null;
    } on SmartBoxApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Could not reach the backend. Check that the server is running.';
    }
  }

  Future<String?> _register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = fullName.trim();
    final normalizedEmail = _normalizeEmail(email);
    final cleanPhone = phone.trim();
    final cleanPassword = password.trim();
    final cleanConfirmPassword = confirmPassword.trim();

    if (cleanName.isEmpty ||
        normalizedEmail.isEmpty ||
        cleanPhone.isEmpty ||
        cleanPassword.isEmpty ||
        cleanConfirmPassword.isEmpty) {
      return 'Fill in every field to create your account.';
    }

    if (!_isValidEmail(normalizedEmail)) {
      return 'Enter a valid email address.';
    }

    if (!_isValidPhone(cleanPhone)) {
      return 'Phone number must start with 0 and be 11 digits.';
    }

    if (cleanPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    if (cleanPassword != cleanConfirmPassword) {
      return 'Passwords do not match.';
    }

    try {
      final session = await _apiClient.register(
        fullName: cleanName,
        email: normalizedEmail,
        phone: cleanPhone,
        password: cleanPassword,
        confirmPassword: cleanConfirmPassword,
      );
      await _completeSignIn(session);
      return null;
    } on SmartBoxApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Could not reach the backend. Check that the server is running.';
    }
  }

  Future<void> _completeSignIn(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_authTokenKey, session.token);
    _model.setUserName(session.user.fullName);
    if (mounted) {
      setState(() => _signedIn = true);
    }
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^0\d{10}$').hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    return SmartBoxScope(
      model: _model,
      child: MaterialApp(
        key: ValueKey(_signedIn),
        title: 'Smart Drop-Off Box',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.navy,
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              height: 1.05,
            ),
            headlineMedium: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
            titleMedium: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
              height: 1.35,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
              height: 1.35,
            ),
          ),
        ),
        home: _bootstrappingSession
            ? const _SessionLoadingScreen()
            : _signedIn
            ? HomeScreen(
                onSignOut: () async {
                  final preferences = await SharedPreferences.getInstance();
                  await preferences.remove(_authTokenKey);
                  _model.reset();
                  setState(() => _signedIn = false);
                },
              )
            : LoginScreen(onSignIn: _signIn, onRegister: _register),
      ),
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
    );
  }
}
