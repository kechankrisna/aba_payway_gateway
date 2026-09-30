<?php

namespace PhpPayway\Enumeration;

enum PaywayPaymentOption
{
    case cards;
    case abapay;
    case abapay_deeplink;
    case bakong;
    case alipay;
    case wechat;
    case UNKNOWN;

    public static function fromString(string $v): self
    {
        return match ($v) {
            "cards" => self::cards,
            "abapay" => self::abapay,
            "abapay_deeplink" => self::abapay_deeplink,
            "bakong" => self::bakong,
            "alipay" => self::alipay,
            "wechat" => self::wechat,
            default => self::UNKNOWN
        };
    }
}