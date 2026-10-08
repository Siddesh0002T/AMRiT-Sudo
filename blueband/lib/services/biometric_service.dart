import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _isVerified = false;
  bool get isVerified => _isVerified;

  bool _isHardwareSupported = false;
  bool get isHardwareSupported => _isHardwareSupported;

  BiometricService() {
    _checkHardwareSupport();
  }

  Future<void> _checkHardwareSupport() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      _isHardwareSupported = canAuthenticateWithBiometrics || isDeviceSupported;
    } catch (e) {
      _isHardwareSupported = false;
    }
    notifyListeners();
  }

  Future<bool> authenticateBiometric() async {
    try {
      if (_isHardwareSupported) {
        // local_auth 3.x uses authenticate() without options parameter
        final authenticated = await _auth.authenticate(
          localizedReason: 'Scan fingerprint to verify attendance on BlueBand',
        );
        if (authenticated) {
          _isVerified = true;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Hardware biometric failed/unavailable: $e');
    }

    return false;
  }

  void setVerifiedSimulated(bool verified) {
    _isVerified = verified;
    notifyListeners();
  }

  void reset() {
    _isVerified = false;
    notifyListeners();
  }
}
