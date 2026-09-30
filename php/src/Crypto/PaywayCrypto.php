<?php

declare(strict_types=1);

namespace PhpPayway\Crypto;

/**
 * Hashing and encryption matching the PHP samples in ABA's checkout docs.
 * Implement this interface to plug in another backend.
 */
interface PaywayCrypto
{
    /** `base64_encode(hash_hmac('sha512', $message, $key, true))` */
    public function hmacSha512Base64(string $message, string $key): string;

    /** RSA-encrypt `$data` (PKCS#1 v1.5, key-size chunks) and base64 the result. */
    public function rsaEncrypt(string $data, string $publicKey): string;
}
