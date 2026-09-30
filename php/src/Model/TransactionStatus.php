<?php

declare(strict_types=1);

namespace PhpPayway\Model;

use PhpPayway\Enum\PaymentStatusCode;

/** Status of a transaction, from `check-transaction-2`. */
final readonly class TransactionStatus
{
    public function __construct(
        public ?int $paymentStatusCode,
        public string $paymentStatus,
        public float $totalAmount,
        public float $originalAmount,
        public float $refundAmount,
        public float $discountAmount,
        public float $paymentAmount,
        public string $paymentCurrency,
        public string $apv,
        public string $transactionDate,
    ) {}

    /** Whether the payment is approved (or pre-authorized). */
    public function isApproved(): bool
    {
        return $this->paymentStatusCode === PaymentStatusCode::APPROVED;
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        return new self(
            Json::optionalInt($json, 'payment_status_code'),
            Json::string($json, 'payment_status'),
            Json::float($json, 'total_amount'),
            Json::float($json, 'original_amount'),
            Json::float($json, 'refund_amount'),
            Json::float($json, 'discount_amount'),
            Json::float($json, 'payment_amount'),
            Json::string($json, 'payment_currency'),
            Json::string($json, 'apv'),
            Json::string($json, 'transaction_date'),
        );
    }
}
