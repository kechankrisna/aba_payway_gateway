<?php

declare(strict_types=1);

namespace PhpPayway\Model;

use PhpPayway\Enum\Currency;
use PhpPayway\Enum\PaymentOption;
use PhpPayway\Enum\TransactionType;
use PhpPayway\Enum\ViewType;

/**
 * Request of `purchase`. Only `tranId` and `amount` are required; other
 * fields are sent only when set. Values PayWay wants Base64-encoded (items,
 * return URL, deep link, custom fields, payout, additional params) are
 * given as plain PHP values: the SDK encodes them.
 */
final readonly class Purchase
{
    /**
     * @param string $tranId your unique transaction id, max 20 characters
     * @param list<Item> $items item descriptions (up to 50)
     * @param ?array<string, mixed> $customFields shown in transaction list, details and reports
     * @param ?list<Payout> $payout split of the amount to ABA accounts
     * @param ?int $lifetime payment lifetime in minutes (3 minutes to 30 days)
     * @param ?array<string, mixed> $additionalParams e.g. `wechat_sub_appid`, `wechat_sub_openid`
     * @param ?int $paymentGate set 0 when your profile also has the QR Payment API
     */
    public function __construct(
        public string $tranId,
        public int|float $amount,
        public array $items = [],
        public int|float|null $shipping = null,
        public ?string $firstName = null,
        public ?string $lastName = null,
        public ?string $email = null,
        public ?string $phone = null,
        public ?TransactionType $type = null,
        public ?PaymentOption $paymentOption = null,
        public ?string $returnUrl = null,
        public ?string $cancelUrl = null,
        public ?string $continueSuccessUrl = null,
        public ?ReturnDeeplink $returnDeeplink = null,
        public ?Currency $currency = null,
        public ?array $customFields = null,
        public ?string $returnParams = null,
        public ?array $payout = null,
        public ?int $lifetime = null,
        public ?array $additionalParams = null,
        public ?string $googlePayToken = null,
        public ?bool $skipSuccessPage = null,
        public ?ViewType $viewType = null,
        public ?int $paymentGate = null,
    ) {}
}
