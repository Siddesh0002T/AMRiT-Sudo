import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/env_config.dart';
import 'screens/band_home_screen.dart';
import 'screens/student_login_screen.dart';
import 'services/biometric_service.dart';
import 'services/ble_client_service.dart';
import 'services/student_identity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.instance.init();

  final identityService = StudentIdentityService();
  await identityService.loadIdentity();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: identityService),
        ChangeNotifierProvider(create: (_) => BiometricService()),
        ChangeNotifierProvider(create: (_) => BleClientService()),
      ],
      child: BlueBandApp(isLoggedIn: identityService.isLoggedIn),
    ),
  );
}

class BlueBandApp extends StatelessWidget {
  final bool isLoggedIn;

  const BlueBandApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlueBand Student',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00F0FF),
        scaffoldBackgroundColor: const Color(0xFF070A0F),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const BandHomeScreen() : const StudentLoginScreen(),
    );
  }
}
