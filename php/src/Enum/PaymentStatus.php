<?php

declare(strict_types=1);

namespace PhpPayway\Enum;

/** Transaction status filter of the transaction list (`status`). */
enum PaymentStatus: string
{
    case Approved = 'APPROVED';
    case PreAuth = 'PRE-AUTH';
    case Refunded = 'REFUNDED';
    case Pending = 'PENDING';
    /** spelled as in PayWay's API */
    case Declined = 'DECLINDED';
    case Cancelled = 'CANCELLED';
}
