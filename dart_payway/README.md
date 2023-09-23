`ABA Payway in Dart`

### Create Transaction Example
```dart
Map env = {};
  PaywayTransactionService.ensureInitialized(ABAMerchant(
    merchantID: env['ABA_PAYWAY_MERCHANT_ID'] ?? '',
    merchantApiName: env['ABA_PAYWAY_MERCHANT_NAME'] ?? '',
    merchantApiKey: env['ABA_PAYWAY_API_KEY'] ?? '',
    baseApiUrl: env['ABA_PAYWAY_API_URL'] ?? '',
    refererDomain: "http://mylekha.app",
  ));

  /// create transaction
  final service = PaywayTransactionService.instance!;
  final tranID = service.uniqueTranID();

  var _transaction = PaywayCreateTransaction(
      amount: 6.00,
      items: [
        PaywayTransactionItem(name: "ទំនិញ 1", price: 1, quantity: 1),
        PaywayTransactionItem(name: "ទំនិញ 2", price: 2, quantity: 1),
        PaywayTransactionItem(name: "ទំនិញ 3", price: 3, quantity: 1),
      ],
      reqTime: service.uniqueReqTime(),
      tranId: tranID,
      email: 'support@mylekha.app',
      firstname: 'Miss',
      lastname: 'My Lekha',
      phone: '010464144',
      option: ABAPaymentOption.abapay_deeplink,
      shipping: 0.0,
      returnUrl: "https://mylekha.app");

  var createResponse =
      await service.createTransaction(transaction: _transaction);

  print(_transaction.amount);
  print(createResponse.status);

```

### Generate checkout uri for backend
```dart
final service = PaywayTransactionService.instance!;
      final tranID = service.uniqueTranID();

      var _transaction = PaywayCreateTransaction(
          amount: 6.00,
          items: [
            PaywayTransactionItem(name: "ទំនិញ 1", price: 1, quantity: 1),
            PaywayTransactionItem(name: "ទំនិញ 2", price: 2, quantity: 1),
            PaywayTransactionItem(name: "ទំនិញ 3", price: 3, quantity: 1),
          ],
          reqTime: service.uniqueReqTime(),
          tranId: tranID,
          email: 'support@mylekha.app',
          firstname: 'Miss',
          lastname: 'My Lekha',
          phone: '010464144',
          option: ABAPaymentOption.abapay_deeplink,
          shipping: 0.0,
          returnUrl: "https://mylekha.app");
      String checkoutApiUrl =
          "http://localhost/api/v1/integrate/payway/checkout_page";
      var webURI = await service.generateTransactionCheckoutURI(
          transaction: _transaction, checkoutApiUrl: checkoutApiUrl);

```