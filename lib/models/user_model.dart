class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final dynamic club;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.club,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      club: json['club'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'club': club,
    };
  }
}
