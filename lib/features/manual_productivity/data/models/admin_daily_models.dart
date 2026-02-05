// features/manual_productivity/data/models/admin_daily_models.dart

class AdminDailyInitResponse {
  final String referenceDate; // yyyy-MM-dd
  final String quincenaStart; // yyyy-MM-dd
  final String quincenaEnd; // yyyy-MM-dd
  final List<String> columns; // ["yyyy-MM-dd", ...] L-S
  final List<String> holidays; // ["yyyy-MM-dd", ...]
  final double minHoursPerDay;
  final double maxHoursPerDay;
  final String focusIso;
  final List<AdminDailyTimeUnitDto> timeUnits;
  final List<AdminDailyInitRowDto> rows;

  AdminDailyInitResponse({
    required this.referenceDate,
    required this.quincenaStart,
    required this.quincenaEnd,
    required this.columns,
    required this.holidays,
    required this.minHoursPerDay,
    required this.maxHoursPerDay,
    required this.focusIso,
    required this.timeUnits,
    required this.rows,
  });

  factory AdminDailyInitResponse.fromJson(Map<String, dynamic> json) {
    return AdminDailyInitResponse(
      referenceDate: (json['ReferenceDate'] ?? '').toString(),
      quincenaStart: (json['QuincenaStart'] ?? '').toString(),
      quincenaEnd: (json['QuincenaEnd'] ?? '').toString(),
      columns: (json['Columns'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      holidays: (json['Holidays'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      minHoursPerDay: (json['MinHoursPerDay'] as num? ?? 0).toDouble(),
      maxHoursPerDay: (json['MaxHoursPerDay'] as num? ?? 0).toDouble(),
      focusIso: (json['FocusIso'] ?? '').toString(),
      timeUnits: (json['TimeUnits'] as List<dynamic>? ?? [])
          .map((e) => AdminDailyTimeUnitDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      rows: (json['Rows'] as List<dynamic>? ?? [])
          .map((e) => AdminDailyInitRowDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminDailyTimeUnitDto {
  final String idTimeUnit; // GUID
  final String name;
  final double valueKey;

  AdminDailyTimeUnitDto({
    required this.idTimeUnit,
    required this.name,
    required this.valueKey,
  });

  factory AdminDailyTimeUnitDto.fromJson(Map<String, dynamic> json) {
    return AdminDailyTimeUnitDto(
      idTimeUnit: (json['IdTimeUnit'] ?? '').toString(),
      name: (json['Name'] ?? '').toString(),
      valueKey: (json['ValueKey'] as num? ?? 0).toDouble(),
    );
  }
}

class AdminDailyInitRowDto {
  final String activityId; // GUID
  final String activityCode;
  final String activityName;
  String? idTimeUnit; // GUID (editable en UI)
  final List<AdminDailyInitDayDto> days;

  AdminDailyInitRowDto({
    required this.activityId,
    required this.activityCode,
    required this.activityName,
    required this.idTimeUnit,
    required this.days,
  });

  factory AdminDailyInitRowDto.fromJson(Map<String, dynamic> json) {
    return AdminDailyInitRowDto(
      activityId: (json['ActivityId'] ?? '').toString(),
      activityCode: (json['ActivityCode'] ?? '').toString(),
      activityName: (json['ActivityName'] ?? '').toString(),
      idTimeUnit: json['IdTimeUnit']?.toString(),
      days: (json['Days'] as List<dynamic>? ?? [])
          .map((e) => AdminDailyInitDayDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminDailyInitDayDto {
  final String date; // yyyy-MM-dd
  double? amountHours; // en horas

  AdminDailyInitDayDto({
    required this.date,
    required this.amountHours,
  });

  factory AdminDailyInitDayDto.fromJson(Map<String, dynamic> json) {
    return AdminDailyInitDayDto(
      date: (json['Date'] ?? '').toString(),
      amountHours: (json['AmountHours'] == null) ? null : (json['AmountHours'] as num).toDouble(),
    );
  }
}

// Payload para POST /api/admin-daily :contentReference[oaicite:7]{index=7}
class AdminDailyClientPayload {
  final String submitDate; // yyyy-MM-dd
  final List<AdminDailyClientRow> rows;

  AdminDailyClientPayload({
    required this.submitDate,
    required this.rows,
  });

  Map<String, dynamic> toJson() => {
        'submitDate': submitDate,
        'rows': rows.map((r) => r.toJson()).toList(),
      };
}

class AdminDailyClientRow {
  final String activityId; // GUID string
  final String idTimeUnit; // GUID string
  final String date; // yyyy-MM-dd
  final String amount; // string num (como en tu MVC)

  AdminDailyClientRow({
    required this.activityId,
    required this.idTimeUnit,
    required this.date,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'idTimeUnit': idTimeUnit,
        'date': date,
        'amount': amount,
      };
}
