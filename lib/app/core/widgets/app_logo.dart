import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double radius;
  final EdgeInsets padding;

  const AppLogo({super.key, this.size = 24, this.radius = 6, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    // Use a circular avatar and contain the image to avoid cropping.
    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white,
        child: Padding(
          padding: padding,
          child: Image.asset(
            'assets/appicon.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
