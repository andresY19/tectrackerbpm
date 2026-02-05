// lib/features/manual_productivity/data/admin_daily_api.dart
import 'dart:convert';

import 'package:tectrackerbpm/core/api/api_client.dart';
import 'models/admin_daily_models.dart';

class AdminDailyApi {
  final ApiClient _client = ApiClient();

  /// GET /api/admin-daily/init?focusIso=yyyy-MM-dd
  /// Carga la información inicial para pintar la pantalla (columns, rows, units, holidays, focusIso, etc.)
  Future<AdminDailyInitResponse> init({String? focusIso}) async {
    final query = <String, String>{};
    if (focusIso != null && focusIso.trim().isNotEmpty) {
      query['focusIso'] = focusIso.trim();
    }

    final res = await _client.get(
      '/api/admin-daily/init',
      query: query.isEmpty ? null : query,
      auth: true,
    );

    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al inicializar AdminDaily: ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return AdminDailyInitResponse.fromJson(map);
  }

  /// POST /api/admin-daily
  /// Guarda los registros del día seleccionado (submitDate) con sus filas (rows)
  Future<void> save(AdminDailyClientPayload payload) async {
    final res = await _client.post(
      '/api/admin-daily',
      body: payload.toJson(),
      auth: true,
    );

    // Tu backend responde 200 OK (según tu controller)
    if (res.statusCode != 200) {
      throw Exception('Error ${res.statusCode} al guardar AdminDaily: ${res.body}');
    }
  }
}
