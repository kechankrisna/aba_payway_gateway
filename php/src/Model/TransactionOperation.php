<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** One operation (payment, refund, ...) of a transaction. */
final readonly class TransactionOperation
{
    public function __construct(
        public string $status,
        public float $amount,
        public string $transactionDate,
        public string $bankRef,
    ) {}

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        return new self(
            Json::string($json, 'status'),
            Json::float($json, 'amount'),
            Json::string($json, 'transaction_date'),
            Json::string($json, 'bank_ref'),
        );
    }
}
