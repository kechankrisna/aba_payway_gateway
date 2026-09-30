<?php

declare(strict_types=1);

namespace PhpPayway\Model;

use PhpPayway\Enum\PaymentStatusCode;

/**
 * A transaction, from transaction details and the transaction list.
 * `transactionOperations` is only filled by transaction details.
 */
final readonly class Transaction
{
    /** @param list<TransactionOperation> $transactionOperations */
    public function __construct(
        public string $transactionId,
        public ?int $paymentStatusCode,
        public string $paymentStatus,
        public float $originalAmount,
        public string $originalCurrency,
        public float $paymentAmount,
        public string $paymentCurrency,
        public float $totalAmount,
        public float $refundAmount,
        public float $discountAmount,
        public string $apv,
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
        public array $transactionOperations = [],
    ) {}

    /** Whether the payment is approved (or pre-authorized). */
    public function isApproved(): bool
    {
        return $this->paymentStatusCode === PaymentStatusCode::APPROVED;
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        $operations = [];
        foreach (Json::object($json, 'transaction_operations') as $operation) {
            if (\is_array($operation)) {
                $operations[] = TransactionOperation::fromArray($operation);
            }
        }

        return new self(
            Json::string($json, 'transaction_id'),
            Json::optionalInt($json, 'payment_status_code'),
            Json::string($json, 'payment_status'),
            Json::float($json, 'original_amount'),
            Json::string($json, 'original_currency'),
            Json::float($json, 'payment_amount'),
            Json::string($json, 'payment_currency'),
            Json::float($json, 'total_amount'),
            Json::float($json, 'refund_amount'),
            Json::float($json, 'discount_amount'),
            Json::string($json, 'apv'),
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
            $operations,
        );
    }
}
