import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logger centralizado para evitar prints directos en la app.
class AppLogger {
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }

    developer.log(
      message,
      name: 'loginova',
      level: 500,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'loginova',
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'loginova',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'loginova',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
