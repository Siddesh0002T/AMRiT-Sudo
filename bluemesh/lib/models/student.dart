class Student {
  final int? id;
  final String rollNumber;
  final String name;
  final String classSection;
  final String email;
  final String phone;
  final bool isFingerprintRegistered;

  Student({
    this.id,
    required this.rollNumber,
    required this.name,
    required this.classSection,
    this.email = '',
    this.phone = '',
    this.isFingerprintRegistered = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'roll_number': rollNumber,
      'name': name,
      'class_section': classSection,
      'email': email,
      'phone': phone,
      'is_fingerprint_registered': isFingerprintRegistered ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'rollNumber': rollNumber,
      'name': name,
      'classSection': classSection,
      'email': email,
      'phone': phone,
      'isFingerprintRegistered': isFingerprintRegistered,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      rollNumber: (map['roll_number'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      classSection: (map['class_section'] ?? 'A').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      isFingerprintRegistered: (map['is_fingerprint_registered'] ?? 1) == 1,
    );
  }

  factory Student.fromFirebaseJson(String key, Map<dynamic, dynamic> json) {
    return Student(
      id: null,
      rollNumber: (json['rollNumber'] ?? key).toString(),
      name: (json['name'] ?? '').toString(),
      classSection: (json['classSection'] ?? 'A').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      isFingerprintRegistered: json['isFingerprintRegistered'] == true || json['isFingerprintRegistered'] == 1,
    );
  }

  Student copyWith({
    int? id,
    String? rollNumber,
    String? name,
    String? classSection,
    String? email,
    String? phone,
    bool? isFingerprintRegistered,
  }) {
    return Student(
      id: id ?? this.id,
      rollNumber: rollNumber ?? this.rollNumber,
      name: name ?? this.name,
      classSection: classSection ?? this.classSection,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isFingerprintRegistered: isFingerprintRegistered ?? this.isFingerprintRegistered,
    );
  }
}
