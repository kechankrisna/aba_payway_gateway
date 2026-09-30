<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** Response of `exchange-rate`: ABA Bank's latest rates in riel. */
final readonly class ExchangeRateResponse
{
    /** @param array<string, ExchangeRate> $rates by lowercase currency code, e.g. `usd` */
    public function __construct(
        public Status $status,
        public array $rates = [],
    ) {}

    public function isSuccess(): bool
    {
        return $this->status->isSuccess();
    }

    /**
     * Rates are read from `exchange_rates` and from top-level currency keys,
     * as the documented schema shows both.
     *
     * @param array<array-key, mixed> $json
     */
    public static function fromArray(array $json): self
    {
        $rates = [];
        foreach ([$json, Json::object($json, 'exchange_rates')] as $source) {
            foreach ($source as $key => $value) {
                if (\is_array($value) && isset($value['sell'], $value['buy'])) {
                    $rates[strtolower((string) $key)] = new ExchangeRate(
                        Json::float($value, 'sell'),
                        Json::float($value, 'buy'),
                    );
                }
            }
        }

        return new self(Status::fromArray(Json::object($json, 'status')), $rates);
    }
}
