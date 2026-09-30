import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Hashing and encryption matching the PHP samples in the PayWay checkout
/// docs: `base64_encode(hash_hmac('sha512', ..., true))` for request hashes
/// and callback signatures, and `openssl_public_encrypt` (PKCS#1 v1.5) in
/// chunks for the refund `merchant_auth`.
///
/// Implement this class to plug in another crypto backend.
class PaywayCrypto {
  /// Creates the default implementation.
  const PaywayCrypto();

  /// Base64 of the raw HMAC-SHA512 of [message] keyed with [key].
  String hmacSha512Base64(String message, String key) => base64.encode(
    crypto.Hmac(
      crypto.sha512,
      utf8.encode(key),
    ).convert(utf8.encode(message)).bytes,
  );

  /// RSA-encrypt [data] in key-size chunks with [publicKey] (PEM or bare
  /// base64) and base64 the joined result.
  String rsaEncrypt(String data, String publicKey) {
    final cipher = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(parsePublicKey(publicKey)));
    final chunkSize = cipher.inputBlockSize;
    final source = utf8.encode(data);
    final output = BytesBuilder(copy: false);
    for (var i = 0; i < source.length; i += chunkSize) {
      output.add(
        cipher.process(
          Uint8List.sublistView(source, i, min(i + chunkSize, source.length)),
        ),
      );
    }
    return base64.encode(output.toBytes());
  }

  /// The string PayWay signs a callback with: the body's values sorted by
  /// key and concatenated as PHP converts them to strings (arrays are
  /// JSON-encoded the way PHP's `json_encode` does).
  static String callbackSigningString(Map<String, dynamic> body) {
    final keys = body.keys.toList()..sort();
    return keys.map((key) => _phpString(body[key])).join();
  }

  /// Parses an RSA public key: PEM `PUBLIC KEY` (X.509 SubjectPublicKeyInfo),
  /// PEM `RSA PUBLIC KEY` (PKCS#1), or either as bare base64.
  static RSAPublicKey parsePublicKey(String key) {
    try {
      var sequence = _sequence(_derBytes(key));
      if (sequence.elements!.first is! ASN1Integer) {
        final bits = sequence.elements![1] as ASN1BitString;
        sequence = _sequence(Uint8List.fromList(bits.stringValues!));
      }
      final values = [
        for (final element in sequence.elements!)
          (element as ASN1Integer).integer!,
      ];
      return RSAPublicKey(values[0], values[1]);
    } catch (error) {
      throw FormatException('Invalid RSA public key: $error');
    }
  }

  static Uint8List _derBytes(String key) => base64.decode(
    key
        .split('\n')
        .where((line) => !line.trim().startsWith('-----'))
        .join()
        .replaceAll(RegExp(r'\s'), ''),
  );

  static ASN1Sequence _sequence(Uint8List bytes) =>
      ASN1Parser(bytes).nextObject() as ASN1Sequence;

  /// PHP's implicit string conversion of a `json_decode(..., true)` value.
  static String _phpString(Object? value) => switch (value) {
    null => '',
    true => '1',
    false => '',
    final int v => v.toString(),
    final double v => _phpFloat(v),
    final String v => v,
    _ => _phpJsonEncode(value),
  };

  static String _phpFloat(double v) =>
      v.isFinite && v == v.truncateToDouble() && v.abs() < 1e15
      ? v.toInt().toString()
      : v.toString();

  /// `json_encode` with PHP's defaults: `/` escaped, non-ASCII as `\uXXXX`,
  /// and an empty object as `[]` (json_decode turns `{}` into an array).
  static String _phpJsonEncode(Object? value) {
    Object? normalize(Object? v) => switch (v) {
      final Map<dynamic, dynamic> m when m.isEmpty => const <Object?>[],
      final Map<dynamic, dynamic> m => m.map(
        (k, e) => MapEntry(k.toString(), normalize(e)),
      ),
      final List<dynamic> l => l.map(normalize).toList(),
      _ => v,
    };
    final encoded = json.encode(normalize(value));
    final out = StringBuffer();
    for (final unit in encoded.codeUnits) {
      if (unit == 0x2f) {
        out.write(r'\/');
      } else if (unit > 0x7f) {
        out.write('\\u${unit.toRadixString(16).padLeft(4, '0')}');
      } else {
        out.writeCharCode(unit);
      }
    }
    return out.toString();
  }
}
