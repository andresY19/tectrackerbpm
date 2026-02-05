// lib/features/notifications/presentation/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:tectrackerbpm/core/services/models/app_notification.dart';
import 'package:tectrackerbpm/core/services/notification_service.dart';
import 'package:tectrackerbpm/core/widgets/bpm_scaffold.dart';
import 'package:tectrackerbpm/core/widgets/bpm_side_menu.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();

    // 🔹 Importante: marcar leídas DESPUÉS del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.markAllRead();
      // Si quisieras solo resetear el número:
      // NotificationService.instance.resetCounter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BpmScaffold(
      companyName: 'TEC-BPM',
      userName: 'Usuario',
      drawer: const BpmSideMenu(),
      body: Container(
        color: const Color(0xFFF4F5F7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Aquí verás los avisos que te llegan desde BPM.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Lista reactiva de notificaciones
            Expanded(
              child: ValueListenableBuilder<List<AppNotification>>(
                valueListenable: NotificationService.instance.notifications,
                builder: (context, list, _) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tienes notificaciones pendientes.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  // Ordenamos de más reciente a más antigua
                  final sorted = [...list]
                    ..sort(
                      (a, b) =>
                          b.createdAt.compareTo(a.createdAt),
                    );

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final n = sorted[index];
                      return _NotificationTile(notification: n);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final isRead = notification.read;
    final bgColor =
        isRead ? Colors.grey.shade200 : Colors.blue.shade50;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.notifications_active_outlined,
          color: isRead ? Colors.grey : Colors.blue,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: notification.body != null &&
                notification.body!.trim().isNotEmpty
            ? Text(
                notification.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: notification.read
            ? const Icon(Icons.done_all,
                size: 18, color: Colors.grey)
            : const Icon(Icons.fiber_new,
                size: 18, color: Colors.blue),
        onTap: () {
          // 1️⃣ Determinar la ruta de navegación
          final routeFromModel = notification.route;
          final routeFromData =
              notification.data?['screen']?.toString();

          String? route = routeFromModel ?? routeFromData;
          if (route != null && route.isNotEmpty) {
            if (!route.startsWith('/')) {
              route = '/$route';
            }
          }

          // 2️⃣ Eliminar del listado
          NotificationService.instance
              .removeNotification(notification.id);

          // 3️⃣ Navegar si hay ruta
          if (route != null && route.isNotEmpty) {
            Navigator.of(context).pushNamed(route);
          }
        },
      ),
    );
  }
}
