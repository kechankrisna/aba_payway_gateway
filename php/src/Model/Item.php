<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/**
 * A purchased item. Items are a description only: PayWay does not use their
 * price or quantity for calculation. Up to 50 items.
 */
final readonly class Item
{
    public function __construct(
        public string $name,
        public int|float $quantity,
        public int|float $price,
    ) {}

    /** @return array{name: string, quantity: int|float, price: int|float} */
    public function toArray(): array
    {
        return ['name' => $this->name, 'quantity' => $this->quantity, 'price' => $this->price];
    }
}
