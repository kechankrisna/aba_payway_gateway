<?php

declare(strict_types=1);

namespace PhpPayway\Exception;

/**
 * Thrown when PayWay could not be reached or did not answer with a PayWay
 * status, and for invalid local input such as a missing RSA key. Branch on
 * {@see $type}.
 *
 * PayWay business errors (wrong hash, transaction not found, ...) are not
 * thrown: they are returned in the response `status`.
 */
final class PaywayException extends \RuntimeException
{
    /**
     * @param ErrorType $type what went wrong
     * @param ?int $statusCode HTTP status code, when a response was received
     */
    public function __construct(
        public readonly ErrorType $type,
        string $message,
        public readonly ?int $statusCode = null,
        ?\Throwable $previous = null,
    ) {
        parent::__construct($message, 0, $previous);
    }

    /** Whether retrying the same call later may succeed. */
    public function isRetryable(): bool
    {
        return match ($this->type) {
            ErrorType::Connection, ErrorType::Timeout => true,
            ErrorType::UnexpectedResponse => ($this->statusCode ?? 0) >= 500,
            default => false,
        };
    }
}
