<?php

enum ABAPaymentOption
{
    case cards;
    case abapay;
    case abapay_deeplink;
    case bakong;
    case alipay;
    case wechat;
}

 $ABAPaymentOptionMap = [
    "cards" => ABAPaymentOption::cards,
    "abapay" => ABAPaymentOption::abapay,
    "abapay_deeplink" => ABAPaymentOption::abapay_deeplink,
    "bakong" => ABAPaymentOption::bakong,
    "alipay" => ABAPaymentOption::alipay,
    "wechat" => ABAPaymentOption::wechat,
];

/// acceptable currency
enum ABATransactionCurrency
{
    case USD;
    case KHR;
}

$ABATransactionCurrencyMap = [
    'USD' => ABATransactionCurrency::USD,
    'KHR' => ABATransactionCurrency::KHR,
];

/// transaction type
enum ABATransactionType
{
    case purchase;
    case refund;
}

$ABATransactionTypeMap = [
    'purchase' => ABATransactionType::purchase,
    'refund' => ABATransactionType::refund,
];
