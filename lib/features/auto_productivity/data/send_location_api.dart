import 'package:tectrackerbpm/core/api/api_client.dart';
import 'package:tectrackerbpm/features/auto_productivity/data/models/send_location_request.dart';


class SendLocationApi {
  /// Envía la ubicación actual al backend.
  /// El usuario y la compañía se obtienen desde el JWT en el backend.
  Future<void> sendLocation(SendLocationRequest request) async {
    final resp = await ApiClient().post(
      '/api/location',
      auth: true,
      body: request.toJson(),
    );

    if (resp.statusCode != 200 &&
        resp.statusCode != 201 &&
        resp.statusCode != 204) {
      throw Exception(
        'Error enviando ubicación: ${resp.statusCode} ${resp.body}',
      );
    }
  }
}
