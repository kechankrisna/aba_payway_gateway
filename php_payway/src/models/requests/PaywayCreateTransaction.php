<?php
declare(strict_types=1);

namespace PhpPayway\Models\Requests;

use PhpPayway\Enumeration\PaywayTransactionCurrency;
use PhpPayway\Enumeration\PaywayPaymentOption;
use PhpPayway\Enumeration\PaywayTransactionType;

class PaywayCreateTransaction
{
    public function __construct(
        public string                 $tran_id,
        public string                 $req_time,
        public float                  $amount,
        /**
         * @var PaywayTransactionItem[] $items
         */
        public array                     $items,
        public string                    $firstname,
        public string                    $lastname,
        public string                    $phone,
        public string                    $email,
        public PaywayPaymentOption       $option,
        public PaywayTransactionType     $type,
        public PaywayTransactionCurrency $currency,
        public ?string                   $return_url = null,
        public ?string                   $continue_success_url = null,
        public ?string                   $return_params = null,
        public ?float                    $shipping = null,
    )
    {

    }

    public function copyWith(
        ?string                 $tran_id,
        ?string                 $req_time,
        ?float                  $amount,
        /**
         * @var PaywayTransactionItem[] $items
         */
        ?array                     $items,
        ?string                    $firstname,
        ?string                    $lastname,
        ?string                    $phone,
        ?string                    $email,
        ?PaywayPaymentOption       $option,
        ?PaywayTransactionType     $type,
        ?PaywayTransactionCurrency $currency,
        ?string                    $return_url = null,
        ?string                    $continue_success_url = null,
        ?string                    $return_params = null,
        ?float                     $shipping = null,
    )
    {
        $copy = clone($this);
        $this->tran_id = $tran_id ?? $copy->tran_id;
        $this->req_time = $req_time ?? $copy->req_time;
        $this->amount = $amount ?? $copy->amount;
        $this->items = $items ?? $copy->items;
        $this->firstname = $firstname ?? $copy->firstname;
        $this->lastname = $lastname ?? $copy->lastname;
        $this->phone = $phone ?? $copy->phone;
        $this->email = $email ?? $copy->email;
        $this->option = $option ?? $copy->option;
        $this->type = $type ?? $copy->type;
        $this->currency = $currency ?? $copy->currency;
        $this->return_url = $return_url ?? $copy->return_url;
        $this->continue_success_url = $continue_success_url ?? $copy->continue_success_url;
        $this->return_params = $return_params ?? $copy->return_params;
        $this->shipping = $shipping ?? $copy->shipping;
    }

    public function toMap() :  array
    {
        return [
            'tran_id' => $this->tran_id,
            'req_time' => $this->req_time,
            'amount' => $this->amount,
            'items' => $this->items,
            'firstname' => $this->firstname,
            'lastname' => $this->lastname,
            'phone' => $this->phone,
            'email' => $this->email,
            'option' => $this->option,
            'type' => $this->type,
            'currency' => $this->currency,
            'return_url' => $this->return_url,
            'continue_success_url' => $this->continue_success_url,
            'return_params' => $this->return_params,
            'shipping' => $this->shipping,
        ];
    }

}