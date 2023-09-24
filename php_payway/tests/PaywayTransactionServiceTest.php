<?php

use AbaPaywayGateway\PhpPayway\enumeration\ABAPaymentOption;
use AbaPaywayGateway\PhpPayway\enumeration\ABATransactionType;
use AbaPaywayGateway\PhpPayway\enumeration\ABATransactionCurrency;
use \AbaPaywayGateway\PhpPayway\services;
use \AbaPaywayGateway\PhpPayway\models;
use \AbaPaywayGateway\PhpPayway\services\ABAClientFormRequestService;

uses()->group('PaywayTransactionService');

test('', function () {

    $merchant = new models\ABAMerchant(

    );

    $service = new services\PaywayTransactionService(merchant: $merchant);

    $tran_id = $service->uniqueTranID();
    $items = [
        new models\requests\PaywayTransactionItem(name: "ទំនិញ 1", quantity: 1, price: 1,),
        new models\requests\PaywayTransactionItem(name: "ទំនិញ 2", quantity: 1, price: 2,),
        new models\requests\PaywayTransactionItem(name: "ទំនិញ 3", quantity: 1, price: 3,),
    ];
    $transaction = new models\requests\PaywayCreateTransaction(
        tran_id: $tran_id,
        req_time: $service->uniqueReqTime(),
        amount: 6.00,
        items: $items,
        firstname: 'Miss',
        lastname: 'My Lekha',
        phone: '010464144',
        email: 'support@mylekha.app',
        option: ABAPaymentOption::abapay_deeplink,
        type: ABATransactionType::purchase,
        currency: ABATransactionCurrency::USD,
        return_url: "https://stage.mylekha.app",
        shipping: 0.0,

    );
    $form_service = new ABAClientFormRequestService(merchant: $merchant);
    $request_options = $form_service->generateCreateTransactionFormData(transaction: $transaction);

    echo '<pre>'; print_r($request_options); echo '</pre>';

//    $createResponse =
//        $service->createTransaction(transaction: $transaction);


})->group("PaywayTransactionService");
