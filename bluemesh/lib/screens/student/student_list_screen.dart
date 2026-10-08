import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentService _studentService = StudentService();
  List<Student> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final list = _searchQuery.isEmpty
        ? await _studentService.getAllStudents()
        : await _studentService.searchStudents(_searchQuery);
    if (mounted) {
      setState(() {
        _students = list;
        _isLoading = false;
      });
    }
  }

  void _showStudentDialog({Student? student}) {
    final rollController = TextEditingController(text: student?.rollNumber ?? '');
    final nameController = TextEditingController(text: student?.name ?? '');
    final classController = TextEditingController(text: student?.classSection ?? 'CS-A');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          student == null ? 'Add Student' : 'Edit Student',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: rollController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Roll Number (e.g. 23CE045)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter roll number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Student Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter student name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: classController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Class / Section / Department',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                if (student == null) {
                  await _studentService.addStudent(Student(
                    rollNumber: rollController.text.trim().toUpperCase(),
                    name: nameController.text.trim(),
                    classSection: classController.text.trim(),
                  ));
                } else {
                  await _studentService.updateStudent(Student(
                    id: student.id,
                    rollNumber: rollController.text.trim().toUpperCase(),
                    name: nameController.text.trim(),
                    classSection: classController.text.trim(),
                  ));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadStudents();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: Text(student == null ? 'Add to Roster' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showBatchAddDialog() {
    final batchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batch Import Students', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter one student per line in format:\nRollNumber, Full Name, Section',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: batchController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '23CE001, John Doe, CS-A\n23CE002, Alice Smith, CS-A',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final lines = batchController.text.split('\n');
              final List<Student> studentsToAdd = [];
              for (var line in lines) {
                final parts = line.split(',');
                if (parts.length >= 2) {
                  final roll = parts[0].trim().toUpperCase();
                  final name = parts[1].trim();
                  final section = parts.length >= 3 ? parts[2].trim() : 'CS-A';
                  if (roll.isNotEmpty && name.isNotEmpty) {
                    studentsToAdd.add(Student(rollNumber: roll, name: name, classSection: section));
                  }
                }
              }

              if (studentsToAdd.isNotEmpty) {
                final added = await _studentService.addStudentsBatch(studentsToAdd);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully imported $added students!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
                _loadStudents();
              }
            },
            child: const Text('Import Students'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Remove Student?'),
        content: Text('Are you sure you want to remove "${student.name}" (${student.rollNumber})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && student.id != null) {
      await _studentService.deleteStudent(student.id!);
      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Roster', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Batch Import CSV/Text',
            icon: const Icon(Icons.playlist_add_rounded),
            onPressed: _showBatchAddDialog,
          ),
          IconButton(
            tooltip: 'Add Student',
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showStudentDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (v) {
                  _searchQuery = v;
                  _loadStudents();
                },
                decoration: InputDecoration(
                  hintText: 'Search by name, roll number, or section...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Student List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              const Text('No students registered yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('Add your real students manually or via batch import.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => _showStudentDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Student'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _students.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final s = _students[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Roll: ${s.rollNumber} • ${s.classSection}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _showStudentDialog(student: s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                      onPressed: () => _deleteStudent(s),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStudentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
    );
  }
}
