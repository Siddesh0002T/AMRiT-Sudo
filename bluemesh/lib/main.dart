import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'services/attendance_service.dart';
import 'services/auth_service.dart';
import 'services/ble_host_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  final hasSession = await authService.checkSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => BleHostService()),
        ChangeNotifierProvider(create: (_) => AttendanceService()),
      ],
      child: BlueMeshApp(hasSession: hasSession),
    ),
  );
}

class BlueMeshApp extends StatelessWidget {
  final bool hasSession;

  const BlueMeshApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'BlueMesh Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: hasSession ? const HomeDashboardScreen() : const LoginScreen(),
    );
  }
}
