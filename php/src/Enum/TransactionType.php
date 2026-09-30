<?php

declare(strict_types=1);

namespace PhpPayway\Enum;

/** Type of a purchase (`type`). */
enum TransactionType: string
{
    /** full purchase (PayWay's default) */
    case Purchase = 'purchase';

    /** pre-authorization hold, captured later; ABA PAY, KHQR and cards only */
    case PreAuth = 'pre-auth';
}
