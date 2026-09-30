<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/**
 * Lenient readers for PayWay JSON: strings and numbers are read whatever
 * type PayWay actually sends.
 *
 * @internal
 */
final class Json
{
    /** @param array<array-key, mixed> $json */
    public static function string(array $json, string ...$keys): string
    {
        return self::optionalString($json, ...$keys) ?? '';
    }

    /** @param array<array-key, mixed> $json first present key wins */
    public static function optionalString(array $json, string ...$keys): ?string
    {
        foreach ($keys as $key) {
            $value = $json[$key] ?? null;
            if (\is_string($value)) {
                return $value;
            }
            if (\is_int($value) || \is_float($value)) {
                return (string) $value;
            }
        }

        return null;
    }

    /** @param array<array-key, mixed> $json */
    public static function float(array $json, string $key): float
    {
        return self::optionalFloat($json, $key) ?? 0.0;
    }

    /** @param array<array-key, mixed> $json */
    public static function optionalFloat(array $json, string $key): ?float
    {
        $value = $json[$key] ?? null;

        return is_numeric($value) ? (float) $value : null;
    }

    /** @param array<array-key, mixed> $json */
    public static function optionalInt(array $json, string $key): ?int
    {
        $value = $json[$key] ?? null;

        return is_numeric($value) ? (int) $value : null;
    }

    /**
     * @param array<array-key, mixed> $json
     * @return array<array-key, mixed>
     */
    public static function object(array $json, string $key): array
    {
        $value = $json[$key] ?? null;

        return \is_array($value) ? $value : [];
    }

    private function __construct() {}
}
