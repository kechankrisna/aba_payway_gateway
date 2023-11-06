<?php

namespace PhpPayway\Services;

use PhpPayway\Models\PaywayMerchant;
use PhpPayway\Models\Requests\PaywayCreateTransaction;
use PhpPayway\Models\Requests\PaywayCheckTransaction;


class PaywayClientFormRequestService
{
    public function __construct(public PaywayMerchant $merchant)
    {

    }

    public function generateCreateTransactionFormData(PaywayCreateTransaction $transaction): array
    {
        $encoded_return_url = EncoderService::base64_encode($transaction->return_url);
        $encodedItem = EncoderService::base64_encode($transaction->items);
        $service = (new PaywayClientService($this->merchant));
        $str = $service->getStr(
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
        $hash = $service->getHash($str);

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

    public function generateCheckTransactionFormData(PaywayCheckTransaction $transaction): array
    {
        $service = (new PaywayClientService($this->merchant));
        $str = $service->getStr(
            req_time: $transaction->req_time,
            tran_id: $transaction->tran_id,
            amount: "",
            items: "",
            shipping: "",
            firstname: "",
            lastname: "",
            email: "",
            phone: "",
            type: "",
            payment_option: "",
            currency: "",
            return_url: "",
        );

        $hash = $service->getHash($str);

        return [
            "merchant_id" => $this->merchant->merchantID,
            "req_time" => $transaction -> req_time,
            "tran_id" => $transaction -> tran_id,
            "hash" => $hash,
        ];

  }
}