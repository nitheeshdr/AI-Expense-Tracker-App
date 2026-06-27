import 'package:flutter/material.dart';

/// Thin Material 3 scaffold wrapper. Kept as a named widget so existing screens
/// compile unchanged; [ambientGlow] is now a no-op (Material surfaces handle
/// depth via tonal elevation).
class AppScaffold extends StatelessWidget {
  final Widget child;
  final bool ambientGlow;
  final bool safeBottom;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const AppScaffold({
    super.key,
    required this.child,
    this.ambientGlow = true,
    this.safeBottom = false,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(bottom: safeBottom, child: child),
    );
  }
}
