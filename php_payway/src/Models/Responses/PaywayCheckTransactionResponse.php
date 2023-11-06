<?php

namespace PhpPayway\Models\Responses;

use DateTime;

class PaywayCheckTransactionResponse
{

    public int $status;
    public string $description;
    public float $amount;
    public string $apv;
    public string $payment_status;
    public ?float $total_amount = null;
    public ?DateTime $datetime = null;


    public function copyWith(
        ?int      $status = null,
        ?string   $description = null,
        ?float    $amount = null,
        ?string   $apv = null,
        ?string   $payment_status = null,
        ?float    $total_amount = null,
        ?DateTime $datetime = null,
    )
    {
        $copy = clone($this);
        $this->status = $status ?? $copy->status;
        $this->description = $description ?? $copy->description;
        $this->amount = $amount ?? $copy->amount;
        $this->apv = $apv ?? $copy->apv;
        $this->payment_status = $payment_status ?? $copy->payment_status;
        $this->total_amount = $total_amount ?? $copy->total_amount;
        $this->datetime = $datetime ?? $copy->datetime;

    }

    public function toMap(): array
    {
        return [
            'status' => $this->status,
            'description' => $this->description,
            'amount' => $this->amount,
            'apv' => $this->apv,
            'payment_status' => $this->payment_status,
            'total_amount' => $this->total_amount,
            'datetime' => $this->datetime,
        ];
    }
}