<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** Response of `transaction-detail`. */
final readonly class TransactionDetailResponse
{
    public function __construct(
        public Status $status,
        public ?Transaction $data = null,
    ) {}

    public function isSuccess(): bool
    {
        return $this->status->isSuccess();
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        $data = $json['data'] ?? null;

        return new self(
            Status::fromArray(Json::object($json, 'status')),
            \is_array($data) ? Transaction::fromArray($data) : null,
        );
    }
}
