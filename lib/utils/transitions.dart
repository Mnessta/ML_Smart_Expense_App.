import 'package:flutter/material.dart';

class AppTransitions {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOutCubic;

  static PageRouteBuilder<T> fadeRoute<T extends Object?>(
    Widget page, {
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> slideRoute<T extends Object?>(
    Widget page, {
    Duration duration = defaultDuration,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        final Animation<Offset> offset = Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: defaultCurve),
        );
        return SlideTransition(
          position: offset,
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> scaleRoute<T extends Object?>(
    Widget page, {
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        final Animation<double> scale = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: defaultCurve),
        );
        return ScaleTransition(
          scale: scale,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

