// import 'package:flutter/services.dart';
import 'package:dart_payway/dart_payway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // const MethodChannel channel = MethodChannel('aba_payment');

  TestWidgetsFlutterBinding.ensureInitialized();

  test("EncoderService.base64_encode and base64_decode map", () {
    List<Map<String, dynamic>> input = [
      {"name": "ទំនិញសាកល្បង", "quantity": 1, "price": 6}
    ];
    var encoded = EncoderService.base64_encode(input);
    print("encoded $encoded");
    var decoded = EncoderService.base64_decode(encoded);
    print("decoded $decoded");

    expect(input, decoded);
  });

  test("EncoderService.base64_encode and base64_decode String", () {
    final input = "ទំនិញសាកល្បង";
    var encoded = EncoderService.base64_encode(input);
    print("encoded $encoded");
    var decoded = EncoderService.base64_decode(encoded);
    print("decoded $decoded");

    expect(input, decoded);
  });

  test("EncoderService.base64_encode and base64_decode null", () {
    final input = null;
    var encoded = EncoderService.base64_encode(input);
    print("encoded $encoded");
    var decoded = EncoderService.base64_decode(encoded);
    print("decoded $decoded");

    expect(input, decoded);
  });
}
