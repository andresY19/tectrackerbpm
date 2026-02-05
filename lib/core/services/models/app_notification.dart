class AppNotification {
  final String id;
  final String title;
  final String? body;
  final DateTime createdAt;
  final bool read;

  /// Ruta a donde debe navegar, por ejemplo:
  /// '/admin-daily' o 'admin-daily'
  final String? route;

  /// Data extra del push (por si quieres leer screen, reason, etc.)
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    this.body,
    required this.createdAt,
    this.read = false,
    this.route,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? read,
    String? route,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      route: route ?? this.route,
      data: data ?? this.data,
    );
  }
}
