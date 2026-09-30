<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** ABA Bank's buy and sell rate of one currency, in riel per unit. */
final readonly class ExchangeRate
{
    public function __construct(
        public float $sell,
        public float $buy,
    ) {}
}
