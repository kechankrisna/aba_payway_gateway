<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/**
 * The payment result PayWay POSTs (JSON) to your `return_url`. Verify it
 * with `PaywayService::verifyCallback()` before trusting it.
 */
final readonly class Callback
{
    public function __construct(
        public string $tranId,
        public string $apv,
        public string $status,
        public string $returnParams,
        public float $originalAmount,
        public string $originalCurrency,
        public float $paymentAmount,
        public string $paymentCurrency,
        public float $totalAmount,
        public float $discountAmount,
        public string $transactionDate,
        public string $firstName,
        public string $lastName,
        public string $email,
        public string $phone,
        public string $bankRef,
        public string $paymentType,
        public string $payerAccount,
        public string $bankName,
        public string $cardSource,
    ) {}

    /** Whether the payment succeeded (`status` `0`). */
    public function isSuccess(): bool
    {
        return $this->status === '0' || $this->status === '00';
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        return new self(
            Json::string($json, 'tran_id'),
            Json::string($json, 'apv'),
            Json::string($json, 'status'),
            Json::string($json, 'return_params'),
            Json::float($json, 'original_amount'),
            Json::string($json, 'original_currency'),
            Json::float($json, 'payment_amount'),
            Json::string($json, 'payment_currency'),
            Json::float($json, 'total_amount'),
            Json::float($json, 'discount_amount'),
            Json::string($json, 'transaction_date'),
            Json::string($json, 'first_name'),
            Json::string($json, 'last_name'),
            Json::string($json, 'email'),
            Json::string($json, 'phone'),
            Json::string($json, 'bank_ref'),
            Json::string($json, 'payment_type'),
            Json::string($json, 'payer_account'),
            Json::string($json, 'bank_name'),
            Json::string($json, 'card_source'),
        );
    }
}
