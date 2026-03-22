import 'package:flutter/material.dart';

/// Shared page transitions for a slightly more polished feel than the default.
abstract final class AppPageRoutes {
  static Route<T> fadeSlide<T extends Object?>(Widget page, {String? name}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name ?? page.runtimeType.toString()),
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
