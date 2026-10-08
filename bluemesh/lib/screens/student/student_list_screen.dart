import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/mysql_api_service.dart';
import '../../services/student_service.dart';
import '../parent/parent_portal_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentService _studentService = StudentService();
  final MySqlApiService _apiService = MySqlApiService.instance;
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
    final localList = _searchQuery.isEmpty
        ? await _studentService.getAllStudents()
        : await _studentService.searchStudents(_searchQuery);

    // Merge with MySQL list
    try {
      final remoteList = await _apiService.fetchStudents();
      final Map<String, Student> map = {};
      for (final s in localList) {
        map[s.rollNumber.toUpperCase()] = s;
      }
      for (final s in remoteList) {
        if (!map.containsKey(s.rollNumber.toUpperCase())) {
          map[s.rollNumber.toUpperCase()] = s;
        }
      }
      if (mounted) {
        setState(() {
          _students = map.values.toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _students = localList;
          _isLoading = false;
        });
      }
    }
  }

  void _showStudentDialog({Student? student}) {
    final rollController = TextEditingController(text: student?.rollNumber ?? '');
    final nameController = TextEditingController(text: student?.name ?? '');
    final classController = TextEditingController(text: student?.classSection ?? 'CS-A');
    final emailController = TextEditingController(text: student?.email ?? '');
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final parentNameController = TextEditingController();
    final parentEmailController = TextEditingController();
    final parentPhoneController = TextEditingController();
    bool isFingerprintReg = student?.isFingerprintRegistered ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            student == null ? 'Add Student (MySQL)' : 'Edit Student',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: rollController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Roll Number * (e.g. 23CE001)',
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
                      labelText: 'Student Full Name *',
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Student Email (For Sign-in)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'student@example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Student Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Parent Details (For In/Out & Early Quit Alerts)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: parentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Parent Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: parentEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Parent Email (Dispatches Live Alert)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mark_email_read_outlined),
                      hintText: 'parent@example.com',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: parentPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Parent Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_in_talk_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Biometric Fingerprint Active', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Allow proxy-proof BLE attendance verification', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: isFingerprintReg,
                    activeColor: const Color(0xFF00FF88),
                    onChanged: (val) => setDialogState(() => isFingerprintReg = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
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
                  final s = Student(
                    id: student?.id,
                    rollNumber: rollController.text.trim().toUpperCase(),
                    name: nameController.text.trim(),
                    classSection: classController.text.trim(),
                    email: emailController.text.trim().toLowerCase(),
                    phone: phoneController.text.trim(),
                    isFingerprintRegistered: isFingerprintReg,
                  );

                  if (student == null) {
                    await _studentService.addStudent(s);
                  } else {
                    await _studentService.updateStudent(s);
                  }

                  // Sync to MySQL
                  await _apiService.saveStudent(
                    s,
                    parentName: parentNameController.text.trim(),
                    parentEmail: parentEmailController.text.trim(),
                    parentPhone: parentPhoneController.text.trim(),
                  );

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
              'Enter one student per line in format:\nRollNumber, Full Name, Section, Email, ParentEmail',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: batchController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '23CE001, John Doe, CS-A, john@gmail.com, parent.john@gmail.com',
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
              final text = batchController.text.trim();
              if (text.isEmpty) return;

              final lines = text.split('\n');
              final List<Student> studentsToAdd = [];

              for (var line in lines) {
                final parts = line.split(',');
                if (parts.length >= 2) {
                  final roll = parts[0].trim();
                  final name = parts[1].trim();
                  final section = parts.length > 2 ? parts[2].trim() : 'CS-A';
                  final email = parts.length > 3 ? parts[3].trim().toLowerCase() : '';
                  final pEmail = parts.length > 4 ? parts[4].trim().toLowerCase() : '';
                  if (roll.isNotEmpty && name.isNotEmpty) {
                    final s = Student(
                      rollNumber: roll,
                      name: name,
                      classSection: section,
                      email: email,
                      isFingerprintRegistered: true,
                    );
                    studentsToAdd.add(s);
                    try {
                      await _apiService.saveStudent(s, parentEmail: pEmail);
                    } catch (_) {}
                  }
                }
              }

              if (studentsToAdd.isNotEmpty) {
                await _studentService.addStudentsBatch(studentsToAdd);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully imported ${studentsToAdd.length} students to MySQL!')),
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

    if (confirmed == true) {
      if (student.id != null) {
        await _studentService.deleteStudent(student.id!);
      }
      await _apiService.deleteStudent(student.rollNumber);
      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Roster (MySQL)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Parent Live View',
            icon: const Icon(Icons.family_restroom_rounded, color: Color(0xFF10B981)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentPortalScreen())),
          ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Name or Roll Number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _loadStudents();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('No students registered yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                child: Text(
                                  student.rollNumber.length > 2 ? student.rollNumber.substring(0, 2) : 'ST',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${student.rollNumber} • ${student.classSection}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Parent Live View',
                                    icon: const Icon(Icons.family_restroom, color: Color(0xFF10B981), size: 20),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => ParentPortalScreen(initialRollNumber: student.rollNumber)),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showStudentDialog(student: student),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                    onPressed: () => _deleteStudent(student),
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
    );
  }
}
