<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** Response of `check-transaction-2`. */
final readonly class CheckTransactionResponse
{
    public function __construct(
        public Status $status,
        public ?TransactionStatus $data = null,
    ) {}

    public function isSuccess(): bool
    {
        return $this->status->isSuccess();
    }

    /** Whether the payment is approved (or pre-authorized). */
    public function isPaid(): bool
    {
        return $this->isSuccess() && ($this->data?->isApproved() ?? false);
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        $data = $json['data'] ?? null;

        return new self(
            Status::fromArray(Json::object($json, 'status')),
            \is_array($data) ? TransactionStatus::fromArray($data) : null,
        );
    }
}
