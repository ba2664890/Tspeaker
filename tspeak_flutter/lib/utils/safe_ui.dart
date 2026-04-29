import 'package:flutter/material.dart';

/// Utility to handle UI updates that might conflict with Flutter's internal
/// lifecycle, especially on Desktop (Linux/Windows) where mouse tracker
/// updates can trigger assertion failures during state changes.
class SafeUI {
  /// Runs a callback after the current frame is drawn.
  /// Use this for setState or Navigator calls that occur after an 'await'.
  static void run(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// Safe navigation that ensures the context is still valid and
  /// runs after the current frame.
  static void navigate(BuildContext context, void Function(BuildContext) navAction) {
    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        navAction(context);
      }
    });
  }

  /// Runs a state update safely on the next frame.
  static void setState(State state, VoidCallback fn) {
    if (!state.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) {
        // ignore: invalid_use_of_protected_member
        state.setState(fn);
      }
    });
  }
}
