// lib/core/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:tectrackerbpm/core/services/models/app_notification.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Contador para el badge de la campana
  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  /// Lista de notificaciones que verá la NotificationsScreen
  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>(<AppNotification>[]);

  /// Agrega una notificación al listado y recalcula el contador
  void addNotification({
    required String title,
    String? body,
    String? route,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();

    final notif = AppNotification(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: now,
      read: false,
      route: route,
      data: data ?? const {},
    );

    notifications.value = [...notifications.value, notif];
    _recalcCounter();
  }

  void _recalcCounter() {
    final unread = notifications.value.where((n) => !n.read).length;
    counter.value = unread;
  }

  void markAllRead() {
    final current = notifications.value;
    if (current.isEmpty) {
      counter.value = 0;
      return;
    }

    final updated = current
        .map((n) => n.copyWith(read: true))
        .toList(growable: false);

    notifications.value = updated;
    _recalcCounter();
  }

  void markAsRead(String id) {
    final current = notifications.value;
    bool changed = false;

    final updated = current.map((n) {
      if (n.id == id && !n.read) {
        changed = true;
        return n.copyWith(read: true);
      }
      return n;
    }).toList(growable: false);

    if (changed) {
      notifications.value = updated;
      _recalcCounter();
    }
  }

  void removeNotification(String id) {
    final current = notifications.value;
    final updated =
        current.where((n) => n.id != id).toList(growable: false);

    notifications.value = updated;
    _recalcCounter();
  }

  void clearAll() {
    notifications.value = const [];
    _recalcCounter();
  }

  /// Solo resetea el contador (sin tocar read / lista)
  void resetCounter() {
    counter.value = 0;
  }
}
