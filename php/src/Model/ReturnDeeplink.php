<?php

declare(strict_types=1);

namespace PhpPayway\Model;

/** Deep links back to your app after paying in ABA Mobile (`return_deeplink`). */
final readonly class ReturnDeeplink
{
    public function __construct(
        public string $iosScheme,
        public string $androidScheme,
    ) {}

    /** @return array{ios_scheme: string, android_scheme: string} */
    public function toArray(): array
    {
        return ['ios_scheme' => $this->iosScheme, 'android_scheme' => $this->androidScheme];
    }
}
