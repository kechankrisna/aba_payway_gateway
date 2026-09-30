<?php

declare(strict_types=1);

namespace PhpPayway;

/** Version of this package, sent in the `User-Agent` header. */
final class Version
{
    /** Kept in sync with the release tag by CI. */
    public const string SDK_VERSION = '2.0.0';

    private function __construct() {}
}
