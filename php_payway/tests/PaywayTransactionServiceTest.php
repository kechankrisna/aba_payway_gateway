<?php

use PhpPayway\Enumeration\PaywayPaymentOption;
use PhpPayway\Enumeration\PaywayTransactionType;
use PhpPayway\enumeration\PaywayTransactionCurrency;
use PhpPayway\Models\PaywayMerchant;
use PhpPayway\Models\Requests\PaywayCheckTransaction;
use PhpPayway\Models\requests\PaywayCreateTransaction;
use PhpPayway\Models\Requests\PaywayTransactionItem;
use PhpPayway\Services\PaywayClientFormRequestService;
use PhpPayway\Services\PaywayTransactionService;

uses()->group('PaywayTransactionService');

test('', function () {
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

//    dd($request_options);

    $createResponse = $service->createTransaction(transaction: $transaction);


    \PHPUnit\Framework\assertEquals($createResponse->abapay_deeplink != null, true,
        message: "the deeplink should be a string according to docs");

    $checkTransaction = $transaction = new PaywayCheckTransaction(
        tran_id: $tran_id,
        req_time: $service->uniqueReqTime());
    $checkResponse = $service->checkTransaction(transaction: $checkTransaction);

//    dd($checkResponse);
    \PHPUnit\Framework\assertEquals($checkResponse->status == 2, true,
        message: "the new transaction created should be pending or status 2");

    $isValidate = $service->isTransactionCompleted(transaction: $checkTransaction);
//    dd($isValidate);

    \PHPUnit\Framework\assertEquals($isValidate, false,
        message: "the new transaction created should be pending");

})->group("PaywayTransactionService");
