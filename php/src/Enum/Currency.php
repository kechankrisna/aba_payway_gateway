<?php

declare(strict_types=1);

namespace PhpPayway\Enum;

/** Currency of a purchase. */
enum Currency: string
{
    case USD = 'USD';
    case KHR = 'KHR';
}
