import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:dart_payway/src/strings.dart';
import 'package:dart_payway/dart_payway.dart';
import 'package:flutter_payway/flutter_payway.dart';

const package = "flutter_payway";

class PaywayAcceptablePaymentColumn extends StatefulWidget {
  final PaywayPaymentOption? value;
  final Function(PaywayPaymentOption? value)? onChanged;

  const PaywayAcceptablePaymentColumn({Key? key, this.value, this.onChanged})
      : super(key: key);
  @override
  _PaywayAcceptablePaymentColumnState createState() => _PaywayAcceptablePaymentColumnState();
}

class _PaywayAcceptablePaymentColumnState extends State<PaywayAcceptablePaymentColumn> {
  PaywayPaymentOption? _value;

  @override
  void initState() {
    _value = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ListTile(
            leading: const Image(
              image:
                  AssetImage("assets/images/ic_generic.png", package: package),
              width: 55,
            ),
            title: Text(PaywayStrings.creditOrDebitCardLabel),
            subtitle: Container(
              padding: const EdgeInsets.only(top: 5),
              child: const Image(
                image:
                    AssetImage("assets/images/ic_cards.png", package: package),
                alignment: Alignment.centerLeft,
                height: 25,
              ),
            ),
            trailing: _value == PaywayPaymentOption.cards
                ? const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                  )
                : const Icon(Icons.lens_outlined),
            onTap: () => _onTap(PaywayPaymentOption.cards),
          ),
          (kIsWeb ||
                  io.Platform.isMacOS ||
                  io.Platform.isWindows ||
                  io.Platform.isLinux)
              ? ListTile(
                  leading: const Image(
                    image: AssetImage("assets/images/ic_payway.png",
                        package: package),
                    width: 55,
                  ),
                  title: Text(PaywayStrings.abaPaywayLabel),
                  subtitle: Text(PaywayStrings.scanToPayWithABAMobileLabel),
                  trailing: _value == PaywayPaymentOption.abapay
                      ? const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green,
                        )
                      : const Icon(Icons.lens_outlined),
                  onTap: () => _onTap(PaywayPaymentOption.abapay),
                )
              : ListTile(
                  leading: const Image(
                    image: AssetImage("assets/images/ic_payway.png",
                        package: package),
                    width: 55,
                  ),
                  title: Text(PaywayStrings.abaPayLabel),
                  subtitle: Text(PaywayStrings.tapToPayWithABAMobileLabel),
                  trailing: _value == PaywayPaymentOption.abapay_deeplink
                      ? const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green,
                        )
                      : Icon(Icons.lens_outlined),
                  onTap: () => _onTap(PaywayPaymentOption.abapay_deeplink),
                ),
        ],
      ),
    );
  }

  _onTap(PaywayPaymentOption value) {
    if (value != _value) {
      setState(() => _value = value);
      widget.onChanged?.call(_value);
    }
  }
}
