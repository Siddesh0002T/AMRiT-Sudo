import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/band_home_screen.dart';
import 'services/biometric_service.dart';
import 'services/ble_client_service.dart';
import 'services/student_identity_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentIdentityService()),
        ChangeNotifierProvider(create: (_) => BiometricService()),
        ChangeNotifierProvider(create: (_) => BleClientService()),
      ],
      child: const BlueBandApp(),
    ),
  );
}

class BlueBandApp extends StatelessWidget {
  const BlueBandApp({super.key});

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
      home: const BandHomeScreen(),
    );
  }
}
