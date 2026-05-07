import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_delivery_box_mobile/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('low battery alert is conditional and pinned first', () {
    final model = SmartBoxModel();
    addTearDown(model.dispose);

    model.batteryPercent = 10;

    expect(model.alerts.first.title, 'Low battery warning');
    expect(
      model.alerts.map((alert) => alert.title),
      isNot(contains('Box opened by courier')),
    );

    model.batteryPercent = 16;

    expect(
      model.alerts.map((alert) => alert.title),
      isNot(contains('Low battery warning')),
    );
  });

  test('wrong otp alert includes attempt times', () {
    final model = SmartBoxModel();
    addTearDown(model.dispose);

    final wrongOtpAlert = model.alerts.firstWhere(
      (alert) => alert.title == 'Wrong OTP entered',
    );

    expect(wrongOtpAlert.attemptTimes, ['02:02 AM', '02:01 AM', '01:59 AM']);
  });

  test('reset restores the shared default battery percentage', () {
    final model = SmartBoxModel();
    addTearDown(model.dispose);

    model.batteryPercent = 80;
    model.reset();

    expect(model.batteryPercent, SmartBoxModel.defaultBatteryPercent);
  });

  test('delivery metadata has clean date label and weight', () {
    final model = SmartBoxModel();
    addTearDown(model.dispose);
    final delivery = model.deliveries.first;

    expect(delivery.deliveredAtLabel, 'May 24, 2026 - 10:30 AM');
    expect(delivery.weight, '2.4 kg');
  });

  testWidgets('shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartDropOffApp());
    await tester.pumpAndSettle();

    expect(find.text('SMART'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('quick actions fit on narrow phone widths', (
    WidgetTester tester,
  ) async {
    final model = SmartBoxModel();
    addTearDown(model.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final width in <double>[320, 360]) {
      tester.view.physicalSize = Size(width, 800);

      await tester.pumpWidget(
        SmartBoxScope(
          model: model,
          child: MaterialApp(home: HomeScreen(onSignOut: () {})),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Quick actions should not overflow at ${width}px width.',
      );
    }
  });

  testWidgets('home lock quick actions confirm and warn without navigation', (
    WidgetTester tester,
  ) async {
    final model = SmartBoxModel();
    addTearDown(model.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      SmartBoxScope(
        model: model,
        child: MaterialApp(home: HomeScreen(onSignOut: () {})),
      ),
    );

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Lock Control'), findsNothing);
    expect(find.text('Unlock Box?'), findsOneWidget);
    expect(model.isLocked, isTrue);

    await tester.tap(find.text('Unlock').last);
    await tester.pumpAndSettle();

    expect(model.isLocked, isFalse);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unlock'));
    await tester.pump();

    expect(find.text('Box is already unlocked'), findsOneWidget);
    expect(find.text('Unlock Box?'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lock'));
    await tester.pumpAndSettle();

    expect(find.text('Lock Box?'), findsOneWidget);
    expect(model.isLocked, isFalse);

    await tester.tap(find.text('Lock').last);
    await tester.pumpAndSettle();

    expect(model.isLocked, isTrue);
  });

  testWidgets(
    'primary screens avoid layout overflow at phone and tablet sizes',
    (WidgetTester tester) async {
      final model = SmartBoxModel();
      addTearDown(model.dispose);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final sizes = <Size>[
        const Size(320, 568),
        const Size(360, 640),
        const Size(390, 844),
        const Size(430, 932),
        const Size(768, 1024),
      ];
      final screens = <MapEntry<String, Widget Function(SmartBoxModel)>>[
        MapEntry(
          'LoginScreen',
          (model) => LoginScreen(
            onSignIn: ({required String email, required String password}) =>
                Future<String?>.value(),
            onRegister:
                ({
                  required String fullName,
                  required String email,
                  required String phone,
                  required String password,
                  required String confirmPassword,
                }) => Future<String?>.value(),
          ),
        ),
        MapEntry(
          'RegisterScreen',
          (model) => RegisterScreen(
            onRegister:
                ({
                  required String fullName,
                  required String email,
                  required String phone,
                  required String password,
                  required String confirmPassword,
                }) => Future<String?>.value(),
          ),
        ),
        MapEntry('HomeScreen', (model) => HomeScreen(onSignOut: () {})),
        MapEntry('LockControlScreen', (model) => const LockControlScreen()),
        MapEntry('OtpScreen', (model) => const OtpScreen()),
        MapEntry(
          'DeliveryHistoryScreen',
          (model) => const DeliveryHistoryScreen(),
        ),
        MapEntry(
          'DeliveryDetailsScreen',
          (model) => DeliveryDetailsScreen(delivery: model.deliveries.first),
        ),
        MapEntry(
          'SecurityAlertsScreen',
          (model) => const SecurityAlertsScreen(),
        ),
        MapEntry(
          'AlertDetailsScreen',
          (model) => AlertDetailsScreen(alert: model.alerts.first),
        ),
        MapEntry('SettingsScreen', (model) => const SettingsScreen()),
      ];

      for (final size in sizes) {
        tester.view.physicalSize = size;

        for (final screen in screens) {
          await tester.pumpWidget(
            SmartBoxScope(
              model: model,
              child: MaterialApp(home: screen.value(model)),
            ),
          );
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason:
                '${screen.key} should not overflow at '
                '${size.width}x${size.height}.',
          );
        }
      }
    },
  );

  testWidgets('drawer and lock dialog avoid layout overflow on narrow phones', (
    WidgetTester tester,
  ) async {
    final model = SmartBoxModel();
    addTearDown(model.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      SmartBoxScope(
        model: model,
        child: MaterialApp(
          home: Scaffold(
            key: scaffoldKey,
            drawer: SmartDrawer(onSignOut: () {}),
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    child: const Text('Open drawer'),
                  ),
                  TextButton(
                    onPressed: () => showLockCommandDialog(context, model),
                    child: const Text('Show dialog'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open drawer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    scaffoldKey.currentState?.closeDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show dialog'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens delivery details from delivery history', (
    WidgetTester tester,
  ) async {
    final model = SmartBoxModel();
    addTearDown(model.dispose);

    await tester.pumpWidget(
      SmartBoxScope(
        model: model,
        child: const MaterialApp(home: DeliveryHistoryScreen()),
      ),
    );

    await tester.tap(find.text('Order #3'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('2.4 kg'), findsOneWidget);
  });

  testWidgets('delivery history cards show concise delivery summary', (
    WidgetTester tester,
  ) async {
    final model = SmartBoxModel();
    addTearDown(model.dispose);

    await tester.pumpWidget(
      SmartBoxScope(
        model: model,
        child: const MaterialApp(home: DeliveryHistoryScreen()),
      ),
    );

    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('May 24, 2026'), findsOneWidget);
    expect(find.text('View more details'), findsNWidgets(3));
    expect(find.byTooltip('Filter'), findsNothing);
    expect(find.textContaining('kg'), findsNothing);
    expect(find.textContaining('OTP used'), findsNothing);
  });

  testWidgets('settings uses home lock art and only notification toggle', (
    WidgetTester tester,
  ) async {
    final model = SmartBoxModel();
    addTearDown(model.dispose);

    await tester.pumpWidget(
      SmartBoxScope(
        model: model,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.bySemanticsLabel('Locked drop-off case'), findsOneWidget);
    expect(find.text('Security notifications'), findsOneWidget);
    expect(find.text('Auto-lock after delivery'), findsNothing);
    expect(find.text('Require OTP'), findsNothing);
  });

  testWidgets('otp display uses shared case image', (
    WidgetTester tester,
  ) async {
    final model = SmartBoxModel();
    addTearDown(model.dispose);

    await tester.pumpWidget(
      SmartBoxScope(
        model: model,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );

    expect(find.bySemanticsLabel('Locked drop-off case'), findsOneWidget);
    expect(find.text('Your OTP Code'), findsOneWidget);
  });

  testWidgets('does not sign in with empty credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartDropOffApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter your email and password.'), findsOneWidget);
    expect(find.text('Welcome back!'), findsNothing);
  });

  testWidgets('registers a user and greets them on the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SmartDropOffApp(apiClient: _FakeAuthApiClient()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Ada Lovelace Byron');
    await tester.enterText(fields.at(1), 'ada@example.com');
    await tester.enterText(fields.at(2), '05550102030');
    await tester.enterText(fields.at(3), 'secure123');
    await tester.enterText(fields.at(4), 'secure123');

    await tester.tap(find.text('Create Account').last);
    await tester.pumpAndSettle();

    expect(find.text('Hello, Ada'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('rejects phone numbers that are not 11 digits starting with 0', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartDropOffApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Invalid Phone');
    await tester.enterText(fields.at(1), 'invalid@example.com');
    await tester.enterText(fields.at(2), '5550102030');
    await tester.enterText(fields.at(3), 'secure123');
    await tester.enterText(fields.at(4), 'secure123');

    await tester.tap(find.text('Create Account').last);
    await tester.pump();

    expect(
      find.text('Phone number must start with 0 and be 11 digits.'),
      findsOneWidget,
    );
    expect(find.text('Welcome back!'), findsNothing);
  });

  testWidgets('signs in with registered credentials after sign out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SmartDropOffApp(apiClient: _FakeAuthApiClient()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final registerFields = find.byType(EditableText);
    await tester.enterText(registerFields.at(0), 'Grace Hopper Murray');
    await tester.enterText(registerFields.at(1), 'grace@example.com');
    await tester.enterText(registerFields.at(2), '05550102040');
    await tester.enterText(registerFields.at(3), 'secure456');
    await tester.enterText(registerFields.at(4), 'secure456');

    await tester.tap(find.text('Create Account').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    final loginFields = find.byType(EditableText);
    await tester.enterText(loginFields.at(0), 'grace@example.com');
    await tester.enterText(loginFields.at(1), 'secure456');

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Grace'), findsOneWidget);
  });
}

class _FakeAuthApiClient extends SmartBoxApiClient {
  final Map<String, ({String fullName, String password})> _accounts = {};

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    _accounts[normalizedEmail] = (fullName: fullName, password: password);
    return _session(fullName, normalizedEmail, phone);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null || account.password != password) {
      throw const SmartBoxApiException('No account matches those credentials.');
    }
    return _session(account.fullName, normalizedEmail, '05550102030');
  }

  @override
  Future<UserProfile> me(String token) async {
    throw const SmartBoxApiException('No saved test session.');
  }

  AuthSession _session(String fullName, String email, String phone) {
    return AuthSession(
      token: 'test-token-$email',
      user: UserProfile(
        id: 'test-user-$email',
        fullName: fullName,
        email: email,
        phone: phone,
      ),
    );
  }
}
