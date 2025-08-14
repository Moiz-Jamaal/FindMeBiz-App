import 'package:flutter/widgets.dart';

// Inherited marker to opt out of global web centering when true
class FullWidthLayout extends InheritedWidget {
  final bool enabled;

  const FullWidthLayout({
    super.key,
    this.enabled = true,
    required super.child,
  });

  static bool isEnabled(BuildContext context) {
    final marker = context.dependOnInheritedWidgetOfExactType<FullWidthLayout>();
    return marker?.enabled ?? false;
  }

  @override
  bool updateShouldNotify(covariant FullWidthLayout oldWidget) => enabled != oldWidget.enabled;
}
