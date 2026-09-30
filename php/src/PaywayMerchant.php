<?php

declare(strict_types=1);

namespace PhpPayway;

/**
 * Merchant credentials provided by ABA Bank. The API key is a secret: keep
 * it on your server.
 */
final readonly class PaywayMerchant
{
    /** PayWay checkout sandbox (testing) environment */
    public const string SANDBOX_URL = 'https://checkout-sandbox.payway.com.kh';

    /** PayWay checkout production (live) environment */
    public const string PRODUCTION_URL = 'https://checkout.payway.com.kh';

    /**
     * @param string $merchantId merchant id provided by ABA (`merchant_id`)
     * @param string $apiKey API key provided by ABA, keys every request hash
     * @param string $referer domain whitelisted by ABA, sent as `Referer`
     * @param ?string $rsaPublicKey RSA public key provided by ABA, PEM or bare base64; needed for refunds
     * @param string $baseApiUrl {@see SANDBOX_URL} or {@see PRODUCTION_URL}
     */
    public function __construct(
        public string $merchantId,
        #[\SensitiveParameter]
        public string $apiKey,
        public string $referer,
        public ?string $rsaPublicKey = null,
        public string $baseApiUrl = self::SANDBOX_URL,
    ) {}

    /**
     * Keeps the API key out of var_dump() and print_r().
     *
     * @return array<string, string|null>
     */
    public function __debugInfo(): array
    {
        return [
            'merchantId' => $this->merchantId,
            'apiKey' => '***',
            'referer' => $this->referer,
            'baseApiUrl' => $this->baseApiUrl,
        ];
    }
}
