<?php

declare(strict_types=1);

namespace PhpPayway\Model;

use PhpPayway\Enum\PaymentStatus;

/** Filters of `transaction-list`; every field is optional. */
final readonly class TransactionListQuery
{
    /**
     * @param ?\DateTimeInterface $fromDate sent as `Y-m-d H:i:s`, as given (no time zone conversion)
     * @param list<PaymentStatus> $statuses statuses to include
     * @param ?int $pagination records per page; PayWay's default 40, maximum 1000
     */
    public function __construct(
        public ?\DateTimeInterface $fromDate = null,
        public ?\DateTimeInterface $toDate = null,
        public int|float|null $fromAmount = null,
        public int|float|null $toAmount = null,
        public array $statuses = [],
        public ?int $page = null,
        public ?int $pagination = null,
    ) {}
}
