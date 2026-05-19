import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static String encrypt(String plainText, String password) {
    final key = md5.convert(utf8.encode(password)).toString();
    final encoded = base64Encode(utf8.encode(plainText));
    final encrypted = StringBuffer();
    for (int i = 0; i < encoded.length; i++) {
      encrypted.writeCharCode(
        encoded.codeUnitAt(i) ^ key.codeUnitAt(i % key.length),
      );
    }
    return base64Encode(utf8.encode(encrypted.toString()));
  }

  static String decrypt(String encryptedText, String password) {
    try {
      final key = md5.convert(utf8.encode(password)).toString();
      final decoded = utf8.decode(base64Decode(encryptedText));
      final decrypted = StringBuffer();
      for (int i = 0; i < decoded.length; i++) {
        decrypted.writeCharCode(
          decoded.codeUnitAt(i) ^ key.codeUnitAt(i % key.length),
        );
      }
      return utf8.decode(base64Decode(decrypted.toString()));
    } catch (e) {
      return '';
    }
  }

  static bool verifyPassword(String? storedPassword, String inputPassword) {
    if (storedPassword == null || storedPassword.isEmpty) return true;
    return storedPassword == md5.convert(utf8.encode(inputPassword)).toString();
  }

  static String hashPassword(String password) {
    return md5.convert(utf8.encode(password)).toString();
  }
}