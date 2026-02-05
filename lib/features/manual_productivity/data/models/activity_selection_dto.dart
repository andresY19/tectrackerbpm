class ActivitySelectionDto {
  final String idSelectedActivitiesAdmin;
  final String activityId;
  final String code;
  final String name;
  final bool selected;

  ActivitySelectionDto({
    required this.idSelectedActivitiesAdmin,
    required this.activityId,
    required this.code,
    required this.name,
    required this.selected,
  });

  factory ActivitySelectionDto.fromJson(Map<String, dynamic> json) {
    return ActivitySelectionDto(
      idSelectedActivitiesAdmin: json['idSelectedActivitiesAdmin'] as String,
      activityId: json['activityId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      selected: json['selected'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idSelectedActivitiesAdmin': idSelectedActivitiesAdmin,
      'activityId': activityId,
      'code': code,
      'name': name,
      'selected': selected,
    };
  }
}
