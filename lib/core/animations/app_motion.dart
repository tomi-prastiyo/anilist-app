import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Standardized Hero tags & lightweight 60fps animation helpers.
class HeroTags {
  HeroTags._();

  static String mediaCover(int mediaId, [String scope = 'default']) =>
      'media-cover-$mediaId-$scope';

  static String personAvatar(int personId, [String scope = 'default']) =>
      'person-avatar-$personId-$scope';
}

/// Smooth fade + subtle slide page route replacing abrupt default transitions.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRoute({required this.page, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) => page,
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
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

extension AppMotionWidgetExt on Widget {
  /// Clean, subtle staggered fade+slide entrance (capped at index 6 so scrolled lists stay snappy).
  Widget animateEntrance({int index = 0, bool horizontal = false}) {
    if (index > 6) return this;
    final delayMs = (index.clamp(0, 6)) * 35;
    final anim = animate(delay: Duration(milliseconds: delayMs)).fadeIn(
      duration: 240.ms,
      curve: Curves.easeOutCubic,
    );
    return horizontal
        ? anim.slideX(begin: 0.06, end: 0, duration: 240.ms, curve: Curves.easeOutCubic)
        : anim.slideY(begin: 0.05, end: 0, duration: 240.ms, curve: Curves.easeOutCubic);
  }
}
