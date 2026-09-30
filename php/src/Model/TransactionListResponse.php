<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** Response of `transaction-list-2`. */
final readonly class TransactionListResponse
{
    /** @param list<Transaction> $data */
    public function __construct(
        public Status $status,
        public array $data = [],
        public ?int $page = null,
        public ?int $pagination = null,
    ) {}

    public function isSuccess(): bool
    {
        return $this->status->isSuccess();
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        $transactions = [];
        foreach (Json::object($json, 'data') as $item) {
            if (\is_array($item)) {
                $transactions[] = Transaction::fromArray($item);
            }
        }

        return new self(
            Status::fromArray(Json::object($json, 'status')),
            $transactions,
            Json::optionalInt($json, 'page'),
            Json::optionalInt($json, 'pagination'),
        );
    }
}
