<?php

namespace AbaPaywayGateway\PhpPayway\services;

use AbaPaywayGateway\PhpPayway\models\ABAMerchant;
use AbaPaywayGateway\PhpPayway\models\requests\PaywayCreateTransaction;

class ABAClientFormRequestService
{
    public function __construct(public ABAMerchant $merchant)
    {

    }

    public function generateCreateTransactionFormData(PaywayCreateTransaction $transaction): array
    {
        $encodedItem = EncoderService::base64_encode($transaction->items);
        $encoded_return_url = EncoderService::base64_encode($transaction->return_url);
        $hash = (new ABAClientService($this->merchant))->getHash(
            req_time: $transaction->req_time,
            tran_id: $transaction->tran_id,
            amount: $transaction->amount,
            items: $encodedItem,
            shipping: $transaction->shipping,
            firstname: $transaction->firstname,
            lastname: $transaction->lastname,
            email: $transaction->email,
            phone: $transaction->phone,
            type: $transaction->type->name,
            payment_option: $transaction->option->name,
            currency: $transaction->currency->name,
            return_url: $encoded_return_url,
        );

        return [
            "merchant_id" => $this->merchant->merchantID,
            "req_time" => $transaction->req_time,
            "tran_id" => $transaction->tran_id,
            "amount" => $transaction->amount,
            "items" => $encodedItem,
            "hash" => $hash,
            "firstname" => $transaction->firstname,
            "lastname" => $transaction->lastname,
            "phone" => $transaction->phone,
            "email" => $transaction->email,
            "return_url" => $encoded_return_url,
            "continue_success_url" => $transaction->continue_success_url ?? "",
            "return_params" => $transaction->return_params ?? "",
            "shipping" => $transaction->shipping,
            "type" => $transaction->type->name,
            "payment_option" => $transaction->option->name,
            "currency" => $transaction->currency->name,
        ];
    }
}