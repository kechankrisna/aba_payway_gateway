<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** Response of `refund`; status codes are `PTL…` for this API. */
final readonly class RefundResponse
{
    public function __construct(
        public Status $status,
        public ?float $grandTotal = null,
        public ?float $totalRefunded = null,
        public ?string $currency = null,
        public ?string $transactionStatus = null,
    ) {}

    public function isSuccess(): bool
    {
        return $this->status->isSuccess();
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        return new self(
            Status::fromArray(Json::object($json, 'status')),
            Json::optionalFloat($json, 'grand_total'),
            Json::optionalFloat($json, 'total_refunded'),
            Json::optionalString($json, 'currency'),
            Json::optionalString($json, 'transaction_status'),
        );
    }
}
