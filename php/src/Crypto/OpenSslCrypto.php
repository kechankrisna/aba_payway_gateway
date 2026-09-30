<?php

declare(strict_types=1);

namespace PhpPayway\Crypto;

/** Default {@see PaywayCrypto}, backed by ext-openssl. */
final class OpenSslCrypto implements PaywayCrypto
{
    /** PKCS#1 v1.5 padding takes 11 bytes of every block */
    private const int PKCS1_PADDING_LENGTH = 11;

    public function hmacSha512Base64(string $message, #[\SensitiveParameter] string $key): string
    {
        return base64_encode(hash_hmac('sha512', $message, $key, true));
    }

    public function rsaEncrypt(string $data, string $publicKey): string
    {
        $key = self::parsePublicKey($publicKey);
        $details = openssl_pkey_get_details($key);
        if ($details === false || !\is_int($details['bits'] ?? null)) {
            throw new \InvalidArgumentException('not an RSA key');
        }
        $chunkSize = max(1, intdiv($details['bits'] + 7, 8) - self::PKCS1_PADDING_LENGTH);

        $output = '';
        foreach ($data === '' ? [] : str_split($data, $chunkSize) as $chunk) {
            if (!openssl_public_encrypt($chunk, $encrypted, $key, OPENSSL_PKCS1_PADDING) || !\is_string($encrypted)) {
                throw new \RuntimeException('RSA encryption failed: ' . (openssl_error_string() ?: 'unknown error'));
            }
            $output .= $encrypted;
        }

        return base64_encode($output);
    }

    /**
     * The string PayWay signs a callback with, as in ABA's PHP sample:
     * values sorted by key and concatenated, arrays JSON-encoded.
     *
     * @param array<array-key, mixed> $body the decoded callback JSON
     */
    public static function callbackSigningString(array $body): string
    {
        ksort($body);
        $b4hash = '';
        foreach ($body as $value) {
            if (\is_array($value)) {
                $value = json_encode($value);
            }
            $b4hash .= \is_scalar($value) || $value === null ? (string) $value : '';
        }

        return $b4hash;
    }

    /** Parses a PEM public key (`PUBLIC KEY` / `RSA PUBLIC KEY`) or a bare base64 one. */
    public static function parsePublicKey(string $key): \OpenSSLAsymmetricKey
    {
        $pem = trim($key);
        if (!str_contains($pem, '-----BEGIN')) {
            $body = preg_replace('/\s+/', '', $pem) ?? '';
            $pem = "-----BEGIN PUBLIC KEY-----\n" . chunk_split($body, 64, "\n") . '-----END PUBLIC KEY-----';
        }
        $parsed = openssl_pkey_get_public($pem);
        if ($parsed === false) {
            throw new \InvalidArgumentException('Invalid RSA public key');
        }

        return $parsed;
    }
}
