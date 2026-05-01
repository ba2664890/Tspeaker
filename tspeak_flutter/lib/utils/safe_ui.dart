import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Utility to handle UI updates that might conflict with Flutter's internal
/// lifecycle, especially on Desktop (Linux/Windows) where mouse tracker
/// updates can trigger assertion failures during state changes.
class SafeUI {
  static Future<void> _schedule(VoidCallback callback, {bool extended = false}) async {
    // Basic microtask delay
    await Future.delayed(Duration.zero);
    
    // On Desktop, for major changes (extended=true), add a small stability buffer
    if (extended && (Platform.isLinux || Platform.isWindows)) {
      await Future.delayed(const Duration(milliseconds: 16)); // ~1 frame at 60fps
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle ||
        SchedulerBinding.instance.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      callback();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        callback();
      });
    }
  }

  /// Runs a callback after the current event loop cycle and then after the
  /// current frame if needed.
  static void run(VoidCallback callback, {bool extended = false}) {
    _schedule(callback, extended: extended);
  }

  /// Safe navigation that ensures the context is still valid and runs after
  /// the current event/frame work is complete.
  static void navigate(BuildContext context, void Function(BuildContext) navAction, {bool extended = false}) {
    if (!context.mounted) return;
    _schedule(() {
      if (context.mounted) {
        navAction(context);
      }
    });
  }

  /// Utility for reassemble (Hot Reload) to safely pause and resume animations.
  /// This prevents the MouseTracker assertion error on Desktop.
  static void handleAnimationReassemble(AnimationController controller, {State? state}) {
    if (controller.isAnimating) {
      controller.stop();
      // Resume only after the build cycle is fully completed and stable
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait a small extra buffer to ensure mouse tracker has settled
        Future.delayed(const Duration(milliseconds: 100), () {
          if (state == null || state.mounted) {
            controller.repeat();
          }
        });
      });
    }
  }

  /// Runs a state update safely after the current work is done.
  static void setState(State state, VoidCallback fn, {bool extended = false}) {
    if (!state.mounted) return;
    _schedule(() {
      if (state.mounted) {
        // ignore: invalid_use_of_protected_member
        state.setState(fn);
      }
    });
  }
}
