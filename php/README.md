`Payway in php`

## PaywayTransactionService is required

```php
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

$merchant = new PaywayMerchant(
     merchantID: $_ENV['ABA_PAYWAY_MERCHANT_ID'] ?? '',
     merchantApiName: $_ENV['ABA_PAYWAY_MERCHANT_NAME'] ?? '',
     merchantApiKey: $_ENV['ABA_PAYWAY_API_KEY'] ?? '',
     baseApiUrl: $_ENV['ABA_PAYWAY_API_URL'] ?? '',
     refererDomain: "http://mylekha.app",
);

$service = new PaywayTransactionService(merchant: $merchant);

```

### Create Transaction Example

```php

  $tran_id = $service->uniqueTranID();
    $items = [
        new PaywayTransactionItem(name: "ទំនិញ 1", quantity: 1, price: 1,),
        new PaywayTransactionItem(name: "ទំនិញ 2", quantity: 1, price: 2,),
        new PaywayTransactionItem(name: "ទំនិញ 3", quantity: 1, price: 3,),
    ];
  $transaction = new PaywayCreateTransaction(
    tran_id: $tran_id,
    req_time: $service->uniqueReqTime(),
    amount: 6.00,
    items: $items,
    firstname: 'Miss',
    lastname: 'My Lekha',
    phone: '010464144',
    email: 'support@mylekha.app',
    option: PaywayPaymentOption::abapay_deeplink,
    type: PaywayTransactionType::purchase,
    currency: PaywayTransactionCurrency::USD,
    return_url: "https://stage.mylekha.app",
    shipping: 0.0,
 );
$form_service = new PaywayClientFormRequestService(merchant: $merchant);
$request_options = $form_service->generateCreateTransactionFormData(transaction: $transaction);

$createResponse = $service->createTransaction(transaction: $transaction);

```

### Check Transaction Example

```php
$checkTransaction = $transaction = new PaywayCheckTransaction(tran_id: $tran_id, req_time: $service->uniqueReqTime());
$checkResponse = $service->checkTransaction(transaction: $checkTransaction);

dd($checkResponse);  

```