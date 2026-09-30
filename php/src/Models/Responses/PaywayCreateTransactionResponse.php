<?php

namespace PhpPayway\Models\Responses;


class PaywayCreateTransactionResponseStatus
{
    public ?string $code = null;
    public ?string $message = null;
    public ?string $tran_id = null;

    public function toMap(): array
    {
        return [
            'code' => $this->code,
            'message' => $this->message,
            'tran_id' => $this->tran_id,
        ];
    }
}

class PaywayCreateTransactionResponse
{
    public PaywayCreateTransactionResponseStatus $status;
    public string $description;
    public ?string $qrString = null;
    public ?string $qrImage = null;
    public ?string $abapay_deeplink = null;
    public ?string $app_store = null;
    public ?string $play_store = null;

    public function copyWith(
        ?PaywayCreateTransactionResponseStatus $status = null,
        ?string                                $description = null,
        ?string                                $qrString = null,
        ?string                                $qrImage = null,
        ?string                                $abapay_deeplink = null,
        ?string                                $app_store = null,
        ?string                                $play_store = null,
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

    public function toMap(): array
    {
        return [
            'status' => $this->status?->toMap(),
            'description' => $this->description,
            'qrString' => $this->qrString,
            'qrImage' => $this->qrImage,
            'abapay_deeplink' => $this->abapay_deeplink,
            'app_store' => $this->app_store,
            'play_store' => $this->play_store,
        ];
    }
}