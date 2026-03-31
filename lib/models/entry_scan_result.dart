class EntryScanResult {
  final String name;
  final String dob;
  final String address;
  final String idNo;
  final String idExpiry;
  String faceMatchScore;
  final String entryTime;
  final String verificationStatus;
  final int? scanId;
  final String? personIdNumber;
  final String? banStatus;
  final String? banReason;
  final String? bannedBy;
  final String? banExpiry;

  EntryScanResult({
    required this.name,
    required this.dob,
    required this.address,
    required this.idNo,
    required this.idExpiry,
    required this.faceMatchScore,
    required this.entryTime,
    required this.verificationStatus,
    this.scanId,
    this.personIdNumber,
    this.banStatus,
    this.banReason,
    this.bannedBy,
    this.banExpiry,
  });
}

