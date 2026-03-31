class InspectionRecordModel {
  final String id;
  final String officialName;
  final String title;
  final String type;
  final String time;
  final String date;
  final String reason;
  final String managerOnDuty;

  InspectionRecordModel({
    required this.id,
    required this.officialName,
    required this.title,
    required this.type,
    required this.time,
    required this.date,
    required this.reason,
    required this.managerOnDuty,
  });
}
