// lib/features/manual_productivity/data/selected_activities_api.dart
import 'dart:convert';

import 'package:tectrackerbpm/core/api/api_client.dart';
import 'models/activity_selection_dto.dart';

class SelectedActivitiesApi {
  final ApiClient _client = ApiClient();

  /// GET /api/selected-activities-admins
  /// Devuelve las actividades seleccionadas para el usuario actual (según JWT).
  Future<List<ActivitySelectionDto>> getMySelectedActivities() async {
    final res = await _client.get(
      '/api/selected-activities-admins',
      // auth por defecto es true en ApiClient, pero lo dejo explícito
      auth: true,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Error ${res.statusCode} al obtener actividades: ${res.body}',
      );
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map(
          (e) => ActivitySelectionDto.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// POST /api/selected-activities-admins
  /// Guarda la selección de actividades (solo IDs de actividades).
  Future<void> saveMySelectedActivities(List<String> activityIds) async {
    final body = <String, dynamic>{
      'activityIds': activityIds,
    };

    final res = await _client.post(
      '/api/selected-activities-admins',
      body: body,
      auth: true,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Error ${res.statusCode} al guardar actividades: ${res.body}',
      );
    }
  }

  /// DELETE /api/selected-activities-admins/{idSelectedActivitiesAdmin}
  Future<void> deleteSelectedActivity(String idSelectedActivitiesAdmin) async {
    final res = await _client.delete(
      '/api/selected-activities-admins/$idSelectedActivitiesAdmin',
      auth: true,
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Error ${res.statusCode} al eliminar actividad: ${res.body}',
      );
    }
  }
}
