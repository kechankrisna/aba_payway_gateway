import 'package:dart_payway/dart_payway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'payway_payment_labels.dart';

const _package = 'flutter_payway';

/// A column of payment methods with their logos, one selectable at a time.
///
/// By default it offers cards plus ABA PAY: [PaywayPaymentOption.abapayKhqr]
/// (a QR code to scan) on web and desktop, where ABA Mobile cannot be opened,
/// and [PaywayPaymentOption.abapayKhqrDeeplink] (open ABA Mobile) on phones.
///
/// ```dart
/// PaywayAcceptablePaymentColumn(
///   value: option,
///   onChanged: (value) => setState(() => option = value),
/// )
/// ```
class PaywayAcceptablePaymentColumn extends StatefulWidget {
  /// Creates the column.
  const PaywayAcceptablePaymentColumn({
    super.key,
    this.value,
    this.onChanged,
    this.options,
    this.labels = const PaywayPaymentLabels(),
  });

  /// the selected option
  final PaywayPaymentOption? value;

  /// called with the option the payer taps
  final ValueChanged<PaywayPaymentOption>? onChanged;

  /// the options to offer, in order; defaults to [defaultOptions]
  final List<PaywayPaymentOption>? options;

  /// texts of the options
  final PaywayPaymentLabels labels;

  /// Cards, then ABA PAY as a QR code on web and desktop or as a deep link
  /// into ABA Mobile on Android and iOS.
  static List<PaywayPaymentOption> get defaultOptions => [
    PaywayPaymentOption.cards,
    _canOpenAbaMobile
        ? PaywayPaymentOption.abapayKhqrDeeplink
        : PaywayPaymentOption.abapayKhqr,
  ];

  static bool get _canOpenAbaMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  State<PaywayAcceptablePaymentColumn> createState() =>
      _PaywayAcceptablePaymentColumnState();
}

class _PaywayAcceptablePaymentColumnState
    extends State<PaywayAcceptablePaymentColumn> {
  PaywayPaymentOption? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(PaywayAcceptablePaymentColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final options =
        widget.options ?? PaywayAcceptablePaymentColumn.defaultOptions;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final option in options) _tile(option)],
      ),
    );
  }

  Widget _tile(PaywayPaymentOption option) {
    final labels = widget.labels;
    final (String title, Widget? subtitle, String logo) = switch (option) {
      PaywayPaymentOption.cards => (
        labels.cards,
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: const Image(
            image: AssetImage('assets/images/ic_cards.png', package: _package),
            alignment: Alignment.centerLeft,
            height: 25,
          ),
        ),
        'ic_generic.png',
      ),
      PaywayPaymentOption.abapayKhqr => (
        labels.abapayKhqr,
        Text(labels.abapayKhqrSubtitle),
        'ic_payway.png',
      ),
      PaywayPaymentOption.abapayKhqrDeeplink => (
        labels.abapayKhqrDeeplink,
        Text(labels.abapayKhqrDeeplinkSubtitle),
        'ic_payway.png',
      ),
      PaywayPaymentOption.alipay => (labels.alipay, null, 'ic_generic.png'),
      PaywayPaymentOption.wechat => (labels.wechat, null, 'ic_generic.png'),
      PaywayPaymentOption.googlePay => (
        labels.googlePay,
        null,
        'ic_generic.png',
      ),
    };
    final selected = option == _value;
    return ListTile(
      key: ValueKey(option),
      leading: Image(
        image: AssetImage('assets/images/$logo', package: _package),
        width: 55,
      ),
      title: Text(title),
      subtitle: subtitle,
      selected: selected,
      trailing: selected
          ? const Icon(Icons.check_circle_outline_rounded, color: Colors.green)
          : const Icon(Icons.lens_outlined),
      onTap: () => _onTap(option),
    );
  }

  void _onTap(PaywayPaymentOption option) {
    if (option == _value) return;
    setState(() => _value = option);
    widget.onChanged?.call(option);
  }
}
