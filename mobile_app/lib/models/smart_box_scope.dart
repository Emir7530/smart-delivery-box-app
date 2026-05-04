part of '../app.dart';

class SmartBoxScope extends InheritedNotifier<SmartBoxModel> {
  const SmartBoxScope({
    super.key,
    required SmartBoxModel model,
    required super.child,
  }) : super(notifier: model);

  static SmartBoxModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SmartBoxScope>();
    assert(scope != null, 'SmartBoxScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
