part of '../app.dart';

double _clampDouble(num value, double min, double max) {
  return value.clamp(min, max).toDouble();
}

double _responsiveScaleForWidth(
  double width, {
  double base = 390,
  double min = 0.82,
  double max = 1,
}) {
  return _clampDouble(width / base, min, max);
}

double _responsiveContentWidth(
  double width, {
  double phoneMax = 420,
  double tabletMax = 680,
  double tabletBreakpoint = 700,
}) {
  final maxWidth = width >= tabletBreakpoint ? tabletMax : phoneMax;
  return math.min(maxWidth, math.max(0.0, width));
}
