class Teacher {
  final int? id;
  final String username;
  final String passwordHash;
  final String salt;
  final String name;

  Teacher({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'name': name,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      name: map['name'] as String? ?? 'Teacher',
    );
  }
}
