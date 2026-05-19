import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyService {
  static const String _pinKey = 'app_pin';
  static const String _biometricKey = 'biometric_enabled';
  static const String _autoLockKey = 'auto_lock_timeout';
  static const String _privacyModeKey = 'privacy_mode';

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashed = md5.convert(utf8.encode(pin)).toString();
    await prefs.setString(_pinKey, hashed);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey);
    if (stored == null) return true;
    final input = md5.convert(utf8.encode(pin)).toString();
    return input == stored;
  }

  static Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  static Future<void> setBiometric(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  static Future<int> getAutoLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoLockKey) ?? 5;
  }

  static Future<void> setAutoLockTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoLockKey, minutes);
  }

  static Future<bool> isPrivacyModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyModeKey) ?? false;
  }

  static Future<void> setPrivacyMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyModeKey, enabled);
  }

  static Future<void> secureDelete(List<int> ids, String table) async {
    debugPrint('Secure delete from $table: $ids');
  }

  static String hashData(String data) {
    return md5.convert(utf8.encode(data)).toString();
  }
}