<?php

namespace AbaPaywayGateway\PhpPayway\enumeration;

enum ABATransactionCurrency
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
