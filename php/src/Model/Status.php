<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/**
 * The `status` object of PayWay checkout responses. Codes differ per API;
 * success is `00` (`0` for purchase).
 */
final readonly class Status
{
    public function __construct(
        public string $code,
        public string $message,
        public ?string $tranId = null,
        public ?string $traceId = null,
    ) {}

    /** Whether PayWay answered `00` (or `0`). */
    public function isSuccess(): bool
    {
        return $this->code === '00' || $this->code === '0';
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        return new self(
            Json::string($json, 'code'),
            Json::string($json, 'message'),
            Json::optionalString($json, 'tran_id'),
            Json::optionalString($json, 'trace_id'),
        );
    }
}
