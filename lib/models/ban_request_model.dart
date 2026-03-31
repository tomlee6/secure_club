class BanRequestModel {
  final String id;
  final String name;
  final String banDuration;
  final String requestedOn;

  // New fields for detail page
  final String personName;
  final String idNumber;
  final String banType;
  final String status;
  final String? reason;
  final String reasonCategory;
  final String requestedBy;
  final String? requestedAt;
  final int evidenceCount;
  final String? faceImageUrl;
  final String? description;
  final String? banExpiryDate;

  BanRequestModel({
    required this.id,
    required this.name,
    required this.banDuration,
    required this.requestedOn,
    this.personName = '',
    this.idNumber = '',
    this.banType = '',
    this.status = '',
    this.reason,
    this.reasonCategory = '',
    this.requestedBy = '',
    this.requestedAt,
    this.evidenceCount = 0,
    this.faceImageUrl,
    this.description,
    this.banExpiryDate,
  });
}

class WarningModel {
  final String id;
  final String name;
  final String warningReason;
  final String date;

  // New fields for detail page
  final String idNumber;
  final String guardName;
  final String? createdAt;
  final int warningCount;

  WarningModel({
    required this.id,
    required this.name,
    required this.warningReason,
    required this.date,
    this.idNumber = '',
    this.guardName = '',
    this.createdAt,
    this.warningCount = 0,
  });
}

class ActiveBanModel {
  final int id;
  final String personName;
  final String idNumber;
  final String banType;
  final String status;
  final String? reason;
  final String? approvedBy;
  final String? requestedAt;
  final String? expiresAt;
  final String banScope;
  final String? faceImageUrl;

  ActiveBanModel({
    required this.id,
    required this.personName,
    required this.idNumber,
    required this.banType,
    required this.status,
    this.reason,
    this.approvedBy,
    this.requestedAt,
    this.expiresAt,
    this.banScope = '',
    this.faceImageUrl,
  });
}
