// lib/features/manual_productivity/data/models/admin_unique_models.dart
class TimeUnitDto {
  final String id;
  final String name;

  TimeUnitDto({
    required this.id,
    required this.name,
  });

  factory TimeUnitDto.fromJson(Map<String, dynamic> json) {
    return TimeUnitDto(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class AdminUniqueRowDto {
  final String activityId;
  final String code;
  final String name;
  final String? timeUnitId;
  final double? amount;

  AdminUniqueRowDto({
    required this.activityId,
    required this.code,
    required this.name,
    this.timeUnitId,
    this.amount,
  });

  factory AdminUniqueRowDto.fromJson(Map<String, dynamic> json) {
    return AdminUniqueRowDto(
      activityId: json['activityId'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      timeUnitId: json['timeUnitId'] as String?,
      amount: json['amount'] == null
          ? null
          : (json['amount'] as num).toDouble(),
    );
  }

  AdminUniqueRowDto copyWith({
    String? activityId,
    String? code,
    String? name,
    String? timeUnitId,
    double? amount,
  }) {
    return AdminUniqueRowDto(
      activityId: activityId ?? this.activityId,
      code: code ?? this.code,
      name: name ?? this.name,
      timeUnitId: timeUnitId ?? this.timeUnitId,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJsonForSave() {
    return {
      'activityId': activityId,
      'idTimeUnit': timeUnitId,
      'amount': amount,
    };
  }
}

class AdminUniqueVmDto {
  final List<TimeUnitDto> timeUnits;
  final List<AdminUniqueRowDto> rows;

  AdminUniqueVmDto({
    required this.timeUnits,
    required this.rows,
  });

  factory AdminUniqueVmDto.fromJson(Map<String, dynamic> json) {
    final tus = (json['timeUnits'] as List<dynamic>? ?? [])
        .map((e) => TimeUnitDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final rs = (json['rows'] as List<dynamic>? ?? [])
        .map((e) => AdminUniqueRowDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdminUniqueVmDto(
      timeUnits: tus,
      rows: rs,
    );
  }
}
