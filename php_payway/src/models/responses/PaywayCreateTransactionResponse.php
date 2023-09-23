<?php

namespace AbaPaywayGateway\PhpPayway\models\responses;

class PaywayCreateTransactionResponse
{

    public function __construct(
        public int     $status,
        public string  $description,
        public ?string $qrString = null,
        public ?string $qrImage = null,
        public ?string $abapay_deeplink = null,
        public ?string $app_store = null,
        public ?string $play_store = null,
    )
    {

    }


    public function copyWith(
        ?int     $status = null,
        ?string  $description = null,
        ?string $qrString = null,
        ?string $qrImage = null,
        ?string $abapay_deeplink = null,
        ?string $app_store = null,
        ?string $play_store = null,
    )
    {
        $copy = clone($this);
        $this->status = $status ?? $copy->status;
        $this->description = $description ?? $copy->description;
        $this->qrString = $qrString ?? $copy->qrString;
        $this->qrImage = $qrImage ?? $copy->qrImage;
        $this->abapay_deeplink = $abapay_deeplink ?? $copy->abapay_deeplink;
        $this->app_store = $app_store ?? $copy->app_store;
        $this->play_store = $play_store ?? $copy->play_store;
    }

    public function toMap() : array
    {
        return [
            'status' => $this->status,
            'description' => $this->description,
            'qrString' => $this->qrString,
            'qrImage' => $this->qrImage,
            'abapay_deeplink' => $this->abapay_deeplink,
            'app_store' => $this->app_store,
            'play_store' => $this->play_store,
        ];
    }
}