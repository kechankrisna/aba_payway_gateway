<?php

namespace PhpPayway\Enumeration;

enum PaywayTransactionType
{
    case purchase;
    case refund;

    case UNKNOWN;

    public static function fromString(string $v): self
    {
        return match ($v) {
            "purchase" => self::purchase,
            "refund" => self::refund,
            default => self::UNKNOWN
        };
    }
}
