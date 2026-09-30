// Lenient readers for PayWay JSON: values documented as strings are read as
// strings and numbers as numbers, whatever type PayWay actually sends.

/// Reads [value] as a string, `''` when absent or not a scalar.
String stringFromJson(Object? value) => nullableStringFromJson(value) ?? '';

/// Reads [value] as a string, `null` when absent or not a scalar.
String? nullableStringFromJson(Object? value) => switch (value) {
  final String v => v,
  final num v => v.toString(),
  final bool v => v.toString(),
  _ => null,
};

/// Reads [value] as a trimmed string, `''` when absent.
String trimmedStringFromJson(Object? value) => stringFromJson(value).trim();

/// Reads [value] as a number, `0` when absent or not numeric.
double doubleFromJson(Object? value) => nullableDoubleFromJson(value) ?? 0;

/// Reads [value] as a number, `null` when absent or not numeric.
double? nullableDoubleFromJson(Object? value) => switch (value) {
  final num v => v.toDouble(),
  final String v => double.tryParse(v.trim()),
  _ => null,
};

/// Reads [value] as an integer, `null` when absent or not numeric.
int? nullableIntFromJson(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v.trim()),
  _ => null,
};
