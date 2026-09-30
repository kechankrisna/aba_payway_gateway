<?php

declare(strict_types=1);

namespace PhpPayway\Enum;

/** `payment_status_code` values of transaction status, details and list. */
final class PaymentStatusCode
{
    /** `0` APPROVED or PRE-AUTH */
    public const int APPROVED = 0;

    /** `2` PENDING */
    public const int PENDING = 2;

    /** `3` DECLINED */
    public const int DECLINED = 3;

    /** `4` REFUNDED */
    public const int REFUNDED = 4;

    /** `7` CANCELLED */
    public const int CANCELLED = 7;

    private function __construct() {}
}
