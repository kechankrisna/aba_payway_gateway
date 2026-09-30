<?php

declare(strict_types=1);

namespace PhpPayway\Enum;

/** Payment method of a purchase (`payment_option`). */
enum PaymentOption: string
{
    /** card payment */
    case Cards = 'cards';

    /** QR code payable with ABA PAY and other KHQR member banks */
    case AbapayKhqr = 'abapay_khqr';

    /** ABA PAY / KHQR for apps: purchase answers with JSON (QR string, deep link) */
    case AbapayKhqrDeeplink = 'abapay_khqr_deeplink';

    /** Alipay wallet */
    case Alipay = 'alipay';

    /** WeChat Pay wallet */
    case Wechat = 'wechat';

    /** Google Pay wallet */
    case GooglePay = 'google_pay';
}
