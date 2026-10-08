class Student {
  final int? id;
  final String rollNumber;
  final String name;
  final String classSection;

  Student({
    this.id,
    required this.rollNumber,
    required this.name,
    required this.classSection,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'roll_number': rollNumber,
      'name': name,
      'class_section': classSection,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      rollNumber: map['roll_number'] as String,
      name: map['name'] as String,
      classSection: map['class_section'] as String? ?? 'A',
    );
  }
}
