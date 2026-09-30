import 'package:json_annotation/json_annotation.dart';

part 'payway_return_deeplink.g.dart';

/// Deep links back to your app after paying in ABA Mobile
/// (`return_deeplink`); mandatory for mobile integrations.
@JsonSerializable(fieldRename: FieldRename.snake)
class PaywayReturnDeeplink {
  /// deep link opening your iOS app
  final String iosScheme;

  /// deep link opening your Android app
  final String androidScheme;

  /// Creates a [PaywayReturnDeeplink].
  const PaywayReturnDeeplink({
    required this.iosScheme,
    required this.androidScheme,
  });

  /// Parses PayWay JSON.
  factory PaywayReturnDeeplink.fromJson(Map<String, dynamic> json) =>
      _$PaywayReturnDeeplinkFromJson(json);

  /// PayWay's JSON form: `{"ios_scheme": ..., "android_scheme": ...}`.
  Map<String, dynamic> toJson() => _$PaywayReturnDeeplinkToJson(this);

  @override
  String toString() =>
      'PaywayReturnDeeplink(iosScheme: $iosScheme, androidScheme: $androidScheme)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaywayReturnDeeplink &&
          other.iosScheme == iosScheme &&
          other.androidScheme == androidScheme;

  @override
  int get hashCode => Object.hash(iosScheme, androidScheme);
}
