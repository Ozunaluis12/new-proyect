import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logger centralizado para evitar prints directos en la app. Usa
/// `dart:developer.log` (visible en DevTools) con niveles de severidad
/// crecientes y siempre etiqueta los mensajes con el nombre 'loginova'.
class AppLogger {
  /// Log de depuración: solo se emite en modo debug (kDebugMode), para
  /// no filtrar información de diagnóstico en builds de producción.
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

  /// Log informativo general, visible también en producción.
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'loginova',
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de advertencia, para situaciones anómalas que no impiden
  /// continuar (p. ej. un valor inesperado del backend con fallback).
  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'loginova',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de error, para fallos reales (excepciones, respuestas de error
  /// del backend, etc.).
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
