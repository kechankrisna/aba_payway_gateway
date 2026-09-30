<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/**
 * JSON response of `purchase` with `abapay_khqr_deeplink`. Production sends
 * `qrString`, `qrImage`, `app_store`, `play_store`; the sandbox (and the
 * docs) send `qr_string` and `checkout_qr_url`. Both are read.
 */
final readonly class PurchaseResponse
{
    public function __construct(
        public Status $status,
        public ?string $qrString = null,
        public ?string $qrImage = null,
        public ?string $abapayDeeplink = null,
        public ?string $checkoutQrUrl = null,
        public ?string $appStore = null,
        public ?string $playStore = null,
    ) {}

    public function isSuccess(): bool
    {
        return $this->status->isSuccess();
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        return new self(
            Status::fromArray(Json::object($json, 'status')),
            Json::optionalString($json, 'qr_string', 'qrString'),
            Json::optionalString($json, 'qr_image', 'qrImage'),
            Json::optionalString($json, 'abapay_deeplink', 'abapayDeeplink'),
            Json::optionalString($json, 'checkout_qr_url', 'checkoutQrUrl'),
            Json::optionalString($json, 'app_store', 'appStore'),
            Json::optionalString($json, 'play_store', 'playStore'),
        );
    }
}
