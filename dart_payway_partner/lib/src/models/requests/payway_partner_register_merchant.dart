// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

class PaywayPartnerRegisterMerchant {
  final String pushback_url;
  final String redirect_url;
  final int type;
  final String register_ref;

  ///
  /// `pushback_url`:  the url that we will push back in the background to partner after
  /// register completed. 
  /// ### Example: https://demo-payway-pred.ababank.com
  ///
  /// `redirect_url`: redirect to specific page after register completed:
  /// 1). If field “type” below equal 1, the format must be {"ios_scheme":"link_to_your_page"
  /// ,"android_scheme":"link_to_your_page"}
  /// 2). If field “type” below equal 0, the format must be https://xxxxxxxxxxxxxxxxxxxxxx
  ///
  /// `type`: the value that identifies you request from native app or desktop. Native app
  /// equal 1, desktop equal 0, if keep blank it will 0.
  ///
  /// `register_ref`:  partner generated register reference or tracking string. It is recommended that you send a unique value
  /// for each merchant registration with character and can include underscore or minus. 
  /// ### Example:
  /// merchant, merchant_xxxx, merchant-xxxx, xxxxxxx, xxxxx_aaa
  PaywayPartnerRegisterMerchant({
    required this.pushback_url,
    required this.redirect_url,
    required this.type,
    required this.register_ref,
  });

  PaywayPartnerRegisterMerchant copyWith({
    String? pushback_url,
    String? redirect_url,
    int? type,
    String? register_ref,
  }) {
    return PaywayPartnerRegisterMerchant(
      pushback_url: pushback_url ?? this.pushback_url,
      redirect_url: redirect_url ?? this.redirect_url,
      type: type ?? this.type,
      register_ref: register_ref ?? this.register_ref,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pushback_url': pushback_url,
      'redirect_url': redirect_url,
      'type': type,
      'register_ref': register_ref,
    };
  }

  factory PaywayPartnerRegisterMerchant.fromMap(Map<String, dynamic> map) {
    return PaywayPartnerRegisterMerchant(
      pushback_url: map['pushback_url'] as String,
      redirect_url: map['redirect_url'] as String,
      type: map['type'] as int,
      register_ref: map['register_ref'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PaywayPartnerRegisterMerchant.fromJson(String source) =>
      PaywayPartnerRegisterMerchant.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaywayPartnerRegisterMerchant(pushback_url: $pushback_url, redirect_url: $redirect_url, type: $type, register_ref: $register_ref)';
  }

  @override
  bool operator ==(covariant PaywayPartnerRegisterMerchant other) {
    if (identical(this, other)) return true;

    return other.pushback_url == pushback_url &&
        other.redirect_url == redirect_url &&
        other.type == type &&
        other.register_ref == register_ref;
  }

  @override
  int get hashCode {
    return pushback_url.hashCode ^
        redirect_url.hashCode ^
        type.hashCode ^
        register_ref.hashCode;
  }
}
