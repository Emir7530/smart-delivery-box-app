part of '../app.dart';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, required this.size, this.compact = false});

  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/smart-box-logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'Smart drop-off box logo',
      ),
    );
  }
}
