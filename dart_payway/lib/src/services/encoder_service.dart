// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

class EncoderService {
  static String base46_encode(Object? v) {
    if (v == null || (v is String && v.isEmpty)) return "";

    List<int> value = json.encode(v).codeUnits;
    final stringChars = String.fromCharCodes(value);
    final bytes = utf8.encode(stringChars);
    return base64Encode(bytes);
  }

  static Object? base46_decode(String? v) {
    if (v == null || v.isEmpty) return null;

    final bytes = base64Decode(v);
    final stringChars = String.fromCharCodes(bytes);
    final value = utf8.decode(stringChars.codeUnits);
    return json.decode(value);
  }
}

/// object -> codeUnits -> stringChars -> bytes -> base64Encode
/// base64Decode -> bytes -> stringChars -> codeUnits -> object