<?php
declare(strict_types=1);

namespace PhpPayway\Models\Requests;

class PaywayTransactionItem
{
    public function __construct(
        public string $name,
        public float  $quantity,
        public float  $price,
    )
    {
    }

    public function copyWith(
        ?string $name = null,
        ?float  $quantity = null,
        ?float  $price = null,
    )
    {
        $copy = clone($this);
        $this->name = $name ?? $copy->name;
        $this->quantity = $quantity ?? $copy->quantity;
        $this->price = $price ?? $copy->price;
    }

    public function toMap() : array
    {
        return [
            'name' => $this->name,
            'quantity' => $this->quantity,
            'price' => $this->price,
        ];
    }
}