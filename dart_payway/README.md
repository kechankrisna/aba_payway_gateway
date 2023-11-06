`Payway in Dart`

## PaywayTransactionService is required
```dart
var service = PaywayTransactionService(
          merchant: PaywayMerchant(
        merchantID: env['ABA_PAYWAY_MERCHANT_ID'] ?? '',
        merchantApiName: env['ABA_PAYWAY_MERCHANT_NAME'] ?? '',
        merchantApiKey: env['ABA_PAYWAY_API_KEY'] ?? '',
        baseApiUrl: env['ABA_PAYWAY_API_URL'] ?? '',
        refererDomain: "http://mylekha.app",
      ));

```

### Create Transaction Example
```dart
  /// create transaction
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
      option: PaywayPaymentOption.abapay_deeplink,
      shipping: 0.0,
      returnUrl: "https://mylekha.app");

  var createResponse =
      await service.createTransaction(transaction: _transaction);

  print(_transaction.amount);
  print(createResponse.status);

```

### Generate checkout uri for backend
```dart
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
          option: PaywayPaymentOption.abapay_deeplink,
          shipping: 0.0,
          returnUrl: "https://mylekha.app");
      var webURI = await service.generateTransactionCheckoutURI(
          transaction: _transaction);

```