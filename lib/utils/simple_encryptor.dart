import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;

class SimpleEncryptor {
  final encrypt.Key key;
  final encrypt.IV iv;

  SimpleEncryptor(String password)
      : key = _deriveKey(password),
        iv = _deriveIV(password);

  static encrypt.Key _deriveKey(String password) {
    // Use a cryptographic hash function like SHA-256
    var keyHash =
        crypto.sha256.convert(utf8.encode(password + 'key_salt')).bytes;
    return encrypt.Key(Uint8List.fromList(keyHash.sublist(0, 32)));
  }

  static encrypt.IV _deriveIV(String password) {
    var ivHash = crypto.sha256.convert(utf8.encode(password + 'iv_salt')).bytes;
    return encrypt.IV(Uint8List.fromList(ivHash.sublist(0, 16)));
  }

  String encryptText(String text) {
    final paddedText = _padText(text, 4); // Pad before encryption
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(paddedText, iv: iv).base64;
  }

  String decryptText(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decryptedText =
        encrypter.decrypt(encrypt.Encrypted.from64(encryptedText), iv: iv);
    return _removePadding(decryptedText); // Remove padding after decryption
  }

  String _padText(String text, int divisor) {
    final remainder = text.length % divisor;
    if (remainder == 0) {
      return text; // Already divisible, no need to pad
    } else {
      final paddingLength = divisor - remainder;
      return text.padRight(text.length + paddingLength, ' '); // Pad with spaces
    }
  }

  String _removePadding(String text) {
    return text.trim(); // Trim spaces to remove padding
  }
}
