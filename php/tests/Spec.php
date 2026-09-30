<?php

declare(strict_types=1);

namespace PhpPayway\Tests;

/** Access to the shared spec/ folder. */
final class Spec
{
    /** @return array<string, string> known answers computed with ABA's PHP samples */
    public static function knownAnswers(): array
    {
        /** @var array<string, string> $json */
        $json = json_decode((string) file_get_contents(__DIR__ . '/../../spec/test-vectors/php_known_answers.json'), true, 512, JSON_THROW_ON_ERROR);

        return $json;
    }

    public static function fixture(string $name): string
    {
        return (string) file_get_contents(__DIR__ . "/../../spec/fixtures/{$name}");
    }

    public static function rsaDecrypt(string $data, string $privateKeyPem): string
    {
        $key = openssl_pkey_get_private($privateKeyPem);
        \assert($key !== false);
        $details = openssl_pkey_get_details($key);
        \assert(\is_array($details) && \is_int($details['bits']));
        $blockSize = intdiv($details['bits'], 8);
        if ($blockSize < 1) {
            throw new \RuntimeException('invalid RSA key');
        }
        $out = '';
        foreach (str_split((string) base64_decode($data, true), $blockSize) as $block) {
            openssl_private_decrypt($block, $plain, $key, OPENSSL_PKCS1_PADDING);
            $out .= \is_string($plain) ? $plain : '';
        }

        return $out;
    }

    private function __construct() {}
}
