<?php

namespace PhpPayway\Models;

class PaywayMerchant
{
    public function __construct(
        public string $merchantID,
        public string $merchantApiKey,
        public string $merchantApiName,
        public string $baseApiUrl,
        public string $refererDomain,
    )
    {

    }

    public function copyWith(
        ?string $merchantID = null,
        ?string $merchantApiKey = null,
        ?string $merchantApiName = null,
        ?string $baseApiUrl = null,
        ?string $refererDomain = null,
    )
    {
        $copy = clone($this);

        $this->merchantID = $merchantID ?? $copy->merchantID;
        $this->merchantApiKey = $merchantApiKey ?? $copy->merchantApiKey;
        $this->merchantApiName = $merchantApiName ?? $copy->merchantApiName;
        $this->baseApiUrl = $baseApiUrl ?? $copy->baseApiUrl;
        $this->refererDomain = $refererDomain ?? $copy->refererDomain;
    }

    public function toMap(): array
    {
        return [
            'merchantID' => $this->merchantID,
            'merchantApiKey' => $this->merchantApiKey,
            'merchantApiName' => $this->merchantApiName,
            'baseApiUrl' => $this->baseApiUrl,
            'refererDomain' => $this->refererDomain,
        ];
    }
}