class StaffEmail {
  final String key;
  final String email;
  final String name;
  final DateTime addedAt;
  final String addedBy;

  StaffEmail({
    required this.key,
    required this.email,
    this.name = 'Faculty Member',
    required this.addedAt,
    this.addedBy = 'Admin',
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
    'addedAt': addedAt.toIso8601String(),
    'addedBy': addedBy,
  };

  factory StaffEmail.fromJson(String key, Map<dynamic, dynamic> json) {
    return StaffEmail(
      key: key,
      email: (json['email'] ?? '').toString().trim().toLowerCase(),
      name: (json['name'] ?? 'Faculty Member').toString(),
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      addedBy: (json['addedBy'] ?? 'Admin').toString(),
    );
  }
}
