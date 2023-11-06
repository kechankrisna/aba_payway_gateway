<?php

namespace PhpPayway\Enumeration;

enum PaywayTransactionCurrency
{
    case USD;
    case KHR;

    case UNKNOWN;

    public static function fromString(string $v): self
    {
        return match ($v) {
            "USD" => self::USD,
            "KHR" => self::KHR,
            default => self::UNKNOWN
        };
    }
}
