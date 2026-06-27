import 'package:flutter/services.dart';

/// Centralized haptics. Respects a global enable flag (wired to settings).
class Haptics {
  Haptics._();

  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
