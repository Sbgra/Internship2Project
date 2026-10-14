import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// ChaCha20-Poly1305 algoritması ile mesaj şifreleme ve çözme servisi.
/// FastAPI'den alınan 32-byte anahtarı kullanarak şifreleme yapar.
class ChatEncryptionService {
  static final _algorithm = Chacha20.poly1305Aead();

  /// Base64 formatındaki 32-byte anahtardan [SecretKey] üretir.
  static SecretKey createSecretKeyFromBase64(String base64Key) {
    final keyBytes = base64Decode(base64Key);
    return SecretKey(keyBytes);
  }

  /// Verilen düz metni [SecretKey] kullanarak ChaCha20-Poly1305 ile şifreler.
  /// Sonuç formatı:
  /// `ENC:[base64(nonce)]:[base64(mac)]:[base64(ciphertext)]`
  static Future<String> encrypt({
    required String plainText,
    required SecretKey secretKey,
  }) async {
    try {
      final clearTextBytes = utf8.encode(plainText);
      final secretBox = await _algorithm.encrypt(
        clearTextBytes,
        secretKey: secretKey,
      );

      final nonceB64 = base64Encode(secretBox.nonce);
      final macB64 = base64Encode(secretBox.mac.bytes);
      final cipherB64 = base64Encode(secretBox.cipherText);

      return 'ENC:$nonceB64:$macB64:$cipherB64';
    } catch (e) {
      // Şifreleme başarısız olursa orijinal metni döndür (fallback)
      return plainText;
    }
  }

  /// Şifrelenmiş metni çözer.
  /// Eğer metin şifreli değilse (eski düz metin mesajlar) olduğu gibi döndürür.
  static Future<String> decrypt({
    required String cipherTextFormatted,
    required SecretKey secretKey,
  }) async {
    if (!cipherTextFormatted.startsWith('ENC:')) {
      // Şifreli olmayan eski mesajları bozmadan göster
      return cipherTextFormatted;
    }

    try {
      final parts = cipherTextFormatted.split(':');
      if (parts.length != 4) {
        return cipherTextFormatted;
      }

      final nonce = base64Decode(parts[1]);
      final macBytes = base64Decode(parts[2]);
      final cipherBytes = base64Decode(parts[3]);

      final secretBox = SecretBox(
        cipherBytes,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final clearTextBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(clearTextBytes);
    } catch (e) {
      // Anahtar uyuşmazlığı veya bozulma durumunda
      return '[Şifreli Mesaj - Çözülemedi]';
    }
  }
}
