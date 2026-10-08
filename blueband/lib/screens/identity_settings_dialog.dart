import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/student_identity_service.dart';

class IdentitySettingsDialog extends StatefulWidget {
  const IdentitySettingsDialog({super.key});

  @override
  State<IdentitySettingsDialog> createState() => _IdentitySettingsDialogState();
}

class _IdentitySettingsDialogState extends State<IdentitySettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rollController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final identity = Provider.of<StudentIdentityService>(context, listen: false);
    _rollController = TextEditingController(text: identity.rollNumber);
    _nameController = TextEditingController(text: identity.name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF162032),
      title: const Text(
        'Student Band Identity',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _rollController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Roll Number',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Student Name',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F0FF)),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final identity = Provider.of<StudentIdentityService>(context, listen: false);
            await identity.updateIdentity(
              newRollNumber: _rollController.text,
              newName: _nameController.text,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
