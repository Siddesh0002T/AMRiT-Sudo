import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/mysql_api_service.dart';
import '../../widgets/server_config_dialog.dart';
import '../admin/admin_dashboard_screen.dart';
import '../home_dashboard_screen.dart';
import '../parent/parent_portal_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _staffUserCtrl = TextEditingController();
  final TextEditingController _staffPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _staffUserCtrl.dispose();
    _staffPassCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // STAFF LOGIN (Username & Password created by Admin)
  // ==========================================
  Future<void> _handleStaffLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _staffUserCtrl.text.trim();
      final password = _staffPassCtrl.text.trim();

      // Check MySQL API
      final res = await MySqlApiService.instance.staffLogin(
        username: username,
        password: password,
      );

      if (!mounted) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      final staffName = res['user']?['name'] ?? username;
      final staffEmail = res['user']?['email'] ?? '$username@institution.edu';

      await authService.loginOrRegisterOAuth(
        email: staffEmail,
        name: staffName,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
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

  // ==========================================
  // ADMIN LOGIN (Username: admin, Password: admin)
  // ==========================================
  void _showAdminLoginDialog() {
    final userCtrl = TextEditingController(text: 'admin');
    final passCtrl = TextEditingController(text: 'admin');
    final formKey = GlobalKey<FormState>();
    String? adminError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.purpleAccent, size: 28),
              SizedBox(width: 10),
              Text('Admin Portal Login', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Default Admin Credentials:\nUsername: "admin" | Password: "admin"',
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (adminError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(adminError!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                TextFormField(
                  controller: userCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Admin Username',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person, color: Colors.purpleAccent),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock, color: Colors.purpleAccent),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final u = userCtrl.text.trim();
                final p = passCtrl.text.trim();

                try {
                  final authRes = await MySqlApiService.instance.adminLogin(
                    username: u,
                    password: p,
                  );

                  if (authRes['success'] == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    }
                  } else {
                    setDialogState(() {
                      adminError = authRes['error'] ?? 'Invalid credentials. Required: admin / admin';
                    });
                  }
                } catch (e) {
                  setDialogState(() {
                    adminError = 'Invalid credentials. Use admin / admin';
                  });
                }
              },
              child: const Text('Login as Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                // App Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.hub_rounded, size: 54, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                    'BlueMesh Staff & Admin',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Institutional Portal • MySQL & phpMyAdmin Sync',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
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

                // ── STAFF LOGIN FORM ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staff / Faculty Sign In',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter the username & password created by Admin:',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _staffUserCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Staff Username or Email',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                            hintText: 'e.g. dev or dev@gmail.com',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF38BDF8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter username or email' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _staffPassCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Staff Password',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                            hintText: 'Enter staff password',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF38BDF8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter password' : null,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleStaffLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Login as Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── BUTTON 2: ADMIN LOGIN (admin / admin) ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _showAdminLoginDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.purpleAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.purpleAccent.withOpacity(0.08),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_rounded, color: Colors.purpleAccent, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Admin Login (admin / admin)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── BUTTON 3: PARENT LIVE PORTAL ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentPortalScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.08),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom_rounded, color: Color(0xFF10B981), size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Open Parent Live Portal',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Local MySQL Connection Status Badge
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
                      Flexible(
                        child: Text(
                          'Database: MySQL / phpMyAdmin Local Network',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
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
