import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mysql_api_service.dart';
import '../services/student_identity_service.dart';
import '../widgets/server_config_dialog.dart';
import 'band_home_screen.dart';
import 'guard_patrol_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _studentInputCtrl = TextEditingController(text: '23CE001');
  final TextEditingController _guardUserCtrl = TextEditingController(text: 'guard1');
  final TextEditingController _guardPassCtrl = TextEditingController(text: 'guard123');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _studentInputCtrl.dispose();
    _guardUserCtrl.dispose();
    _guardPassCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // STUDENT SIGN IN
  // ==========================================
  Future<void> _handleStudentSignIn() async {
    final query = _studentInputCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final student = await MySqlApiService.instance.findStudentByEmailOrRoll(query);

      if (student == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Student ($query) not found in MySQL roster. Please ask Staff to register you.';
            _isLoading = false;
          });
        }
        return;
      }

      // Found student! Save identity and proceed
      if (!mounted) return;
      final identityService = Provider.of<StudentIdentityService>(context, listen: false);
      await identityService.updateIdentity(
        newRollNumber: student.rollNumber,
        newName: student.name,
        newSection: student.classSection,
        newEmail: student.email,
        newPhone: student.phone,
      );

      // Trigger presence check-in alert to MySQL (triggers parent email!)
      await MySqlApiService.instance.sendStudentPresenceAlert(
        rollNumber: student.rollNumber,
        alertType: 'STUDENT_IN',
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BandHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Quick picker from MySQL
  Future<void> _showRosterPicker() async {
    final students = await MySqlApiService.instance.fetchAllStudents();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registered Students in MySQL',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Tap any student to auto-fill their credentials:',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                itemBuilder: (c, i) {
                  final s = students[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(s.rollNumber.length > 2 ? s.rollNumber.substring(0, 2) : 'ST',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Roll: ${s.rollNumber} • Class: ${s.classSection}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    onTap: () {
                      _studentInputCtrl.text = s.rollNumber;
                      Navigator.pop(ctx);
                      _handleStudentSignIn();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GUARD SIGN IN & PATROL MODE
  // ==========================================
  void _showGuardLoginDialog() {
    final formKey = GlobalKey<FormState>();
    String? guardError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.orangeAccent, size: 26),
              SizedBox(width: 10),
              Text('Guard Patrol Login', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log into the band as a security guard to start patrolling designated campus explore zones.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (guardError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(guardError!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                TextFormField(
                  controller: _guardUserCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Guard Username (e.g. guard1)',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.person, color: Colors.orangeAccent),
                    filled: true,
                    fillColor: Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guardPassCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Guard Password',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.lock, color: Colors.orangeAccent),
                    filled: true,
                    fillColor: Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter password' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final res = await MySqlApiService.instance.guardLogin(
                    username: _guardUserCtrl.text.trim(),
                    password: _guardPassCtrl.text.trim(),
                  );

                  if (res['success'] == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GuardPatrolScreen(guardData: res['guard'] ?? {}),
                        ),
                      );
                    }
                  } else {
                    setDlgState(() => guardError = 'Invalid credentials');
                  }
                } catch (e) {
                  setDlgState(() => guardError = e.toString().replaceAll('Exception: ', ''));
                }
              },
              child: const Text('Start Patrol Shift', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Server IP / Hotspot Settings',
            icon: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF38BDF8)),
            onPressed: () => ServerConfigDialog.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wristband Glyph
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FF88), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF88).withOpacity(0.25),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.watch_rounded, size: 54, color: Color(0xFF00FF88)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'BlueBand Node',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'BLE Biometric Wristband & Security Guard Patrol',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),

                // ── STUDENT SIGN IN CARD ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Student Identity',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            icon: const Icon(Icons.list_alt, size: 16, color: Color(0xFF38BDF8)),
                            label: const Text('Roster', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                            onPressed: _showRosterPicker,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your Roll Number or registered email to activate attendance:',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _studentInputCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Roll Number (e.g. 23CE001)',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF00FF88)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _handleStudentSignIn(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleStudentSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF88),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Connect Student Band', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── GUARD PATROL MODE BUTTON ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.orangeAccent.withOpacity(0.08),
                    ),
                    icon: const Icon(Icons.shield_rounded, color: Colors.orangeAccent, size: 22),
                    label: const Text(
                      '🛡️ Switch to Guard Patrol Mode',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                    ),
                    onPressed: _showGuardLoginDialog,
                  ),
                ),
                const SizedBox(height: 28),

                // MySQL Local Network Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storage_rounded, color: Color(0xFF00FF88), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Synced with MySQL / phpMyAdmin Local API',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
