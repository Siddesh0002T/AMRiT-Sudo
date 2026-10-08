import '../core/db/database_helper.dart';
import '../models/student.dart';

class StudentService {
  Future<List<Student>> getAllStudents() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('students', orderBy: 'roll_number ASC');
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<Student?> getStudentByRoll(String rollNumber) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'students',
      where: 'roll_number = ?',
      whereArgs: [rollNumber.trim()],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Student>> searchStudents(String query) async {
    final db = await DatabaseHelper.instance.database;
    final q = '%${query.trim()}%';
    final maps = await db.query(
      'students',
      where: 'roll_number LIKE ? OR name LIKE ? OR class_section LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'roll_number ASC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<int> addStudent(Student student) async {
    final db = await DatabaseHelper.instance.database;
    final cleanRoll = student.rollNumber.trim().toUpperCase();
    final cleanName = student.name.trim();

    final existing = await db.query(
      'students',
      where: 'roll_number = ?',
      whereArgs: [cleanRoll],
    );
    if (existing.isNotEmpty) {
      throw Exception('Student with Roll Number "$cleanRoll" already exists!');
    }

    final newStudent = Student(
      rollNumber: cleanRoll,
      name: cleanName,
      classSection: student.classSection.trim(),
    );

    return await db.insert('students', newStudent.toMap());
  }

  Future<int> updateStudent(Student student) async {
    if (student.id == null) throw Exception('Student ID cannot be null');
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'students',
      {
        'roll_number': student.rollNumber.trim().toUpperCase(),
        'name': student.name.trim(),
        'class_section': student.classSection.trim(),
      },
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> addStudentsBatch(List<Student> students) async {
    final db = await DatabaseHelper.instance.database;
    int count = 0;
    await db.transaction((txn) async {
      for (final s in students) {
        final cleanRoll = s.rollNumber.trim().toUpperCase();
        if (cleanRoll.isEmpty) continue;

        final existing = await txn.query(
          'students',
          where: 'roll_number = ?',
          whereArgs: [cleanRoll],
        );
        if (existing.isEmpty) {
          await txn.insert('students', {
            'roll_number': cleanRoll,
            'name': s.name.trim(),
            'class_section': s.classSection.trim(),
          });
          count++;
        }
      }
    });
    return count;
  }
}
