import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../utils/app_logger.dart';

/// Tipos de notificaciones que puede recibir la aplicación.
enum NotificationType { recogidaAsignada, cambioEstado, recordatorio, general }

/// Datos de una notificación recibida.
class NotificationData {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;

  NotificationData({
    required this.title,
    required this.body,
    required this.type,
    required this.data,
  });
}

/// Servicio para integración con Firebase Cloud Messaging.
/// Maneja notificaciones push, tokens FCM y manejo de mensajes.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  static bool _isInitialized = false;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  /// Inicializa Firebase y configura FCM.
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Inicializa Firebase
      await Firebase.initializeApp();

      _messaging = FirebaseMessaging.instance;
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Solicita permisos de notificación
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Configura notificaciones locales
      await _setupLocalNotifications();

      // Maneja mensajes en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Maneja mensajes en background (cuando la app está abierta pero en background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Obtiene y envía el token FCM al backend
      await updateFCMToken();

      // Escucha cambios de token FCM
      _messaging!.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });

      _isInitialized = true;
      AppLogger.info('Firebase inicializado correctamente');
      return true;
    } catch (e) {
      AppLogger.error('Error inicializando Firebase: $e', error: e);
      return false;
    }
  }

  /// Configura las notificaciones locales.
  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSInitSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iOSInitSettings,
    );

    await _flutterLocalNotificationsPlugin!.initialize(settings: initSettings);
  }

  /// Obtiene el token FCM actual del dispositivo.
  static Future<String?> getFCMToken() async {
    try {
      if (_messaging == null) return null;
      return await _messaging!.getToken();
    } catch (e) {
      AppLogger.warn('Error obteniendo token FCM: $e', error: e);
      return null;
    }
  }

  /// Actualiza el token FCM en el backend.
  static Future<void> updateFCMToken() async {
    try {
      final token = await getFCMToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      AppLogger.warn('Error actualizando token FCM: $e', error: e);
    }
  }

  /// Envía el token FCM al backend.
  static Future<bool> _sendTokenToBackend(String token) async {
    try {
      if (ApiService.token == null) return false;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/notificaciones/token'),
        headers: ApiService.jsonHeaders,
        body: jsonEncode({'fcmToken': token}),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.warn('Error enviando token al backend: $e', error: e);
      return false;
    }
  }

  /// Maneja mensajes que llegan cuando la app está en foreground.
  static void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.debug(
      'Mensaje recibido en foreground: ${message.notification?.title}',
    );

    final notifData = NotificationData(
      title: message.notification?.title ?? 'Loginova',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['tipo']),
      data: message.data,
    );

    _showLocalNotification(notifData);
    _onNotificationReceived?.call(notifData);
  }

  /// Maneja cuando el usuario toca una notificación.
  static void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.debug('Notificación tocada: ${message.notification?.title}');

    final notifData = NotificationData(
      title: message.notification?.title ?? 'Loginova',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['tipo']),
      data: message.data,
    );

    _onNotificationTapped?.call(notifData);
  }

  /// Muestra una notificación local.
  static Future<void> _showLocalNotification(NotificationData data) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'loginova_channel',
            'Notificaciones Loginova',
            channelDescription:
                'Notificaciones de recogidas y cambios de estado',
            importance: Importance.max,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _flutterLocalNotificationsPlugin!.show(
        id: data.hashCode,
        title: data.title,
        body: data.body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(data.data),
      );
    } catch (e) {
      AppLogger.warn('Error mostrando notificación local: $e', error: e);
    }
  }

  /// Parsea el tipo de notificación desde el dato recibido.
  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'recogida_asignada':
        return NotificationType.recogidaAsignada;
      case 'cambio_estado':
        return NotificationType.cambioEstado;
      case 'recordatorio':
        return NotificationType.recordatorio;
      default:
        return NotificationType.general;
    }
  }

  /// Callback cuando se recibe una notificación en foreground.
  static Function(NotificationData)? _onNotificationReceived;

  /// Callback cuando el usuario toca una notificación.
  static Function(NotificationData)? _onNotificationTapped;

  /// Registra un callback para cuando se recibe una notificación.
  static void onNotificationReceived(Function(NotificationData) callback) {
    _onNotificationReceived = callback;
  }

  /// Registra un callback para cuando se toca una notificación.
  static void onNotificationTapped(Function(NotificationData) callback) {
    _onNotificationTapped = callback;
  }

  /// Envía una notificación de prueba (solo para desarrollo).
  static Future<bool> sendTestNotification() async {
    try {
      if (ApiService.token == null) return false;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/notificaciones/test'),
        headers: ApiService.jsonHeaders,
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.warn('Error enviando notificación de prueba: $e', error: e);
      return false;
    }
  }

  /// Limpia recursos de Firebase.
  static void dispose() {
    _messaging = null;
    _flutterLocalNotificationsPlugin = null;
    _isInitialized = false;
  }
}
