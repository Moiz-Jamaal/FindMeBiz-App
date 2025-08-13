import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double radius;
  final EdgeInsets padding;

  const AppLogo({super.key, this.size = 24, this.radius = 6, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/appicon.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
