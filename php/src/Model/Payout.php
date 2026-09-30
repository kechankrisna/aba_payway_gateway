<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** A split of the purchase amount to an ABA account (`payout`). */
final readonly class Payout
{
    public function __construct(
        public string $account,
        public int|float $amount,
    ) {}

    /** @return array{acc: string, amt: int|float} */
    public function toArray(): array
    {
        return ['acc' => $this->account, 'amt' => $this->amount];
    }
}
