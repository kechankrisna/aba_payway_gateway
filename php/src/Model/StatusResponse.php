<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** Response of `close-transaction`: a status only. */
final readonly class StatusResponse
{
    public function __construct(public Status $status) {}

    public function isSuccess(): bool
    {
        return $this->status->isSuccess();
    }

    /** @param array<array-key, mixed> $json */
    public static function fromArray(array $json): self
    {
        return new self(Status::fromArray(Json::object($json, 'status')));
    }
}
