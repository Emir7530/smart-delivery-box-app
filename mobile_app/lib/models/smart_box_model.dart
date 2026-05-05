part of '../app.dart';

class SmartBoxModel extends ChangeNotifier {
  static const int defaultBatteryPercent = 10;

  String userName = 'Emir';
  bool isLocked = true;
  bool hasPackage = false;
  bool isOnline = true;
  int batteryPercent = defaultBatteryPercent;
  String otpCode = '482 759';
  String otpExpiresIn = '04:32';

  final List<DeliveryItem> deliveries = const [
    DeliveryItem(
      orderNumber: 3,
      status: 'Delivered',
      date: 'May 24, 2026',
      time: '10:30 AM',
      note: 'View photo, OTP used, and details',
      packageKind: PackageKind.cardboard,
      otpUsed: '482 759',
      weight: '2.4 kg',
    ),
    DeliveryItem(
      orderNumber: 2,
      status: 'Delivered',
      date: 'May 22, 2026',
      time: '01:45 PM',
      note: 'View photo, OTP used, and details',
      packageKind: PackageKind.mailer,
      otpUsed: '174 908',
      weight: '0.7 kg',
    ),
    DeliveryItem(
      orderNumber: 1,
      status: 'Delivered',
      date: 'May 20, 2026',
      time: '11:05 AM',
      note: 'View photo, OTP used, and details',
      packageKind: PackageKind.cardboardAlt,
      otpUsed: '690 221',
      weight: '1.8 kg',
    ),
  ];

  static const SecurityAlertItem _lowBatteryAlert = SecurityAlertItem(
    title: 'Low battery warning',
    message: 'Battery level is below 15%. Please recharge soon.',
    time: 'Yesterday, 11:32 PM',
    severity: AlertSeverity.battery,
  );

  final List<SecurityAlertItem> _alerts = const [
    SecurityAlertItem(
      title: 'Unauthorized access attempt',
      message: 'Someone tried to access the box without authorization.',
      time: '02:14 AM',
      severity: AlertSeverity.critical,
    ),
    SecurityAlertItem(
      title: 'Wrong OTP entered',
      message: '3 failed attempts',
      time: '02:02 AM',
      severity: AlertSeverity.warning,
      attemptTimes: ['02:02 AM', '02:01 AM', '01:59 AM'],
    ),
  ];

  List<SecurityAlertItem> get alerts {
    if (batteryPercent < 15) {
      return [_lowBatteryAlert, ..._alerts];
    }

    return _alerts;
  }

  void setUserName(String name) {
    final cleanName = name.trim();
    final firstName = cleanName.split(RegExp(r'\s+')).first;
    userName = firstName.isEmpty ? 'User' : firstName;
    notifyListeners();
  }

  void unlock() {
    isLocked = false;
    notifyListeners();
  }

  void lock() {
    isLocked = true;
    notifyListeners();
  }

  void reset() {
    isLocked = true;
    hasPackage = false;
    isOnline = true;
    batteryPercent = defaultBatteryPercent;
    otpCode = '482 759';
    otpExpiresIn = '04:32';
    notifyListeners();
  }
}

enum PackageKind { cardboard, cardboardAlt, mailer }

class DeliveryItem {
  const DeliveryItem({
    required this.orderNumber,
    required this.status,
    required this.date,
    required this.time,
    required this.note,
    required this.packageKind,
    required this.otpUsed,
    required this.weight,
  });

  final int orderNumber;
  final String status;
  final String date;
  final String time;
  final String note;
  final PackageKind packageKind;
  final String otpUsed;
  final String weight;

  String get deliveredAtLabel => '$date - $time';
}

enum AlertSeverity { critical, warning, success, battery }

class SecurityAlertItem {
  const SecurityAlertItem({
    required this.title,
    required this.message,
    required this.time,
    required this.severity,
    this.attemptTimes = const [],
  });

  final String title;
  final String message;
  final String time;
  final AlertSeverity severity;
  final List<String> attemptTimes;
}
