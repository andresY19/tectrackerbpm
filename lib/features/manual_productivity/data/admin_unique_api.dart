import 'dart:convert';
import 'package:tectrackerbpm/core/api/api_client.dart';

class AdminUniqueApi {
  final ApiClient _client = ApiClient();

  Future<AdminUniqueInitResponse> init() async {
    final res = await _client.get('/api/admin-unique/init', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return AdminUniqueInitResponse.fromJson(map);
    }

    throw Exception(_extractError(res.body, res.statusCode));
  }

  Future<AdminUniqueSaveResult> save(AdminUniqueSaveRequest req) async {
    print(req.toJson().toString());
    final res = await _client.post(
      '/api/admin-unique/save',
      auth: true,
      body: req.toJson(),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return AdminUniqueSaveResult.fromJson(map);
    }

    throw Exception(_extractError(res.body, res.statusCode));
  }

  Future<void> delete(String idAnswersAdmin) async {
    final res = await _client.delete('/api/admin-unique/$idAnswersAdmin', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(_extractError(res.body, res.statusCode));
  }

  String _extractError(String body, int status) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        // tu backend a veces devuelve { message, maxHours, ... }
        if (decoded['message'] != null) return '${decoded['message']} (HTTP $status)';
        if (decoded['error'] != null) return '${decoded['error']} (HTTP $status)';
      }
    } catch (_) {}
    return 'Error HTTP $status: $body';
  }
}

/* ===================== MODELOS (simple y directos) ===================== */

class AdminUniqueInitResponse {
  final List<AdminUniqueActivityDto> activities;
  final List<AdminUniqueOptionDto> timeUnits;
  final List<AdminUniqueOptionDto> frequencyUnits;
  final List<AdminUniqueEntryDto> entries;

  final double totalCalculation;
  final double maxHoursPerDay;

  AdminUniqueInitResponse({
    required this.activities,
    required this.timeUnits,
    required this.frequencyUnits,
    required this.entries,
    required this.totalCalculation,
    required this.maxHoursPerDay,
  });

  factory AdminUniqueInitResponse.fromJson(Map<String, dynamic> json) {
    return AdminUniqueInitResponse(
      activities: (json['Activities'] as List? ?? [])
          .map((e) => AdminUniqueActivityDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeUnits: (json['TimeUnits'] as List? ?? [])
          .map((e) => AdminUniqueOptionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      frequencyUnits: (json['FrequencyUnits'] as List? ?? [])
          .map((e) => AdminUniqueOptionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      entries: (json['Entries'] as List? ?? [])
          .map((e) => AdminUniqueEntryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCalculation: (json['TotalCalculation'] as num? ?? 0).toDouble(),
      maxHoursPerDay: (json['MaxHoursPerDay'] as num? ?? 0).toDouble(),
    );
  }
}

class AdminUniqueActivityDto {
  final String activityId;
  final String code;
  final String name;
  final String? parentId;

  AdminUniqueActivityDto({
    required this.activityId,
    required this.code,
    required this.name,
    this.parentId,
  });

  factory AdminUniqueActivityDto.fromJson(Map<String, dynamic> json) {
    return AdminUniqueActivityDto(
      activityId: (json['ActivityId'] ?? '').toString(),
      code: (json['Code'] ?? '').toString(),
      name: (json['Name'] ?? '').toString(),
      parentId: json['ParentId']?.toString(),
    );
  }
}

class AdminUniqueOptionDto {
  final String id;
  final String name;
  final double valueKey;

  AdminUniqueOptionDto({required this.id, required this.name, required this.valueKey});

  factory AdminUniqueOptionDto.fromJson(Map<String, dynamic> json) {
    return AdminUniqueOptionDto(
      id: (json['Id'] ?? '').toString(),
      name: (json['Name'] ?? '').toString(),
      valueKey: (json['ValueKey'] as num? ?? 0).toDouble(),
    );
  }
}

class AdminUniqueEntryDto {
  final String idAnswersAdmin;
  final String activityId;
  final String activityCode;
  final String activityName;

  double amount; // editable localmente
  int numberTransactions;

  String idTimeUnit;
  String timeUnitName;

  String idFrequencyUnit;
  String frequencyUnitName;

  double calculation;

  AdminUniqueEntryDto({
    required this.idAnswersAdmin,
    required this.activityId,
    required this.activityCode,
    required this.activityName,
    required this.amount,
    required this.numberTransactions,
    required this.idTimeUnit,
    required this.timeUnitName,
    required this.idFrequencyUnit,
    required this.frequencyUnitName,
    required this.calculation,
  });

  factory AdminUniqueEntryDto.fromJson(Map<String, dynamic> json) {
    return AdminUniqueEntryDto(
      idAnswersAdmin: (json['IdAnswersAdmin'] ?? '').toString(),
      activityId: (json['ActivityId'] ?? '').toString(),
      activityCode: (json['ActivityCode'] ?? '').toString(),
      activityName: (json['ActivityName'] ?? '').toString(),
      amount: (json['Amount'] as num? ?? 0).toDouble(),
      numberTransactions: (json['NumberTransactions'] as num? ?? 1).toInt(),
      idTimeUnit: (json['IdTimeUnit'] ?? '').toString(),
      timeUnitName: (json['TimeUnitName'] ?? '').toString(),
      idFrequencyUnit: (json['IdFrequencyUnit'] ?? '').toString(),
      frequencyUnitName: (json['FrequencyUnitName'] ?? '').toString(),
      calculation: (json['Calculation'] as num? ?? 0).toDouble(),
    );
  }
}

class AdminUniqueSaveRequest {
  final String? idAnswersAdmin; // null = crear, con valor = editar
  final String activityId;
  final double amount;
  final int numberTransactions;
  final String idTimeUnit;
  final String idFrequencyUnit;

  AdminUniqueSaveRequest({
    this.idAnswersAdmin,
    required this.activityId,
    required this.amount,
    required this.numberTransactions,
    required this.idTimeUnit,
    required this.idFrequencyUnit,
  });

  Map<String, dynamic> toJson() => {
        'IdAnswersAdmin': (idAnswersAdmin == null || idAnswersAdmin!.isEmpty) ? null : idAnswersAdmin,
        'ActivityId': activityId,
        'Amount': amount,
        'NumberTransactions': numberTransactions,
        'IdTimeUnit': idTimeUnit,
        'IdFrequencyUnit': idFrequencyUnit,
      };
}

class AdminUniqueSaveResult {
  final String idAnswersAdmin;
  final String activityId;
  final double amount;
  final int numberTransactions;
  final String idTimeUnit;
  final String idFrequencyUnit;
  final double calculation;

  final double totalCalculation;
  final double maxHoursPerDay;

  AdminUniqueSaveResult({
    required this.idAnswersAdmin,
    required this.activityId,
    required this.amount,
    required this.numberTransactions,
    required this.idTimeUnit,
    required this.idFrequencyUnit,
    required this.calculation,
    required this.totalCalculation,
    required this.maxHoursPerDay,
  });

  factory AdminUniqueSaveResult.fromJson(Map<String, dynamic> json) {
    return AdminUniqueSaveResult(
      idAnswersAdmin: (json['IdAnswersAdmin'] ?? '').toString(),
      activityId: (json['ActivityId'] ?? '').toString(),
      amount: (json['Amount'] as num? ?? 0).toDouble(),
      numberTransactions: (json['NumberTransactions'] as num? ?? 1).toInt(),
      idTimeUnit: (json['IdTimeUnit'] ?? '').toString(),
      idFrequencyUnit: (json['IdFrequencyUnit'] ?? '').toString(),
      calculation: (json['Calculation'] as num? ?? 0).toDouble(),
      totalCalculation: (json['TotalCalculation'] as num? ?? 0).toDouble(),
      maxHoursPerDay: (json['MaxHoursPerDay'] as num? ?? 0).toDouble(),
    );
  }
}
