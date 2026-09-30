<?php

declare(strict_types=1);

namespace PhpPayway\Exception;

/** What went wrong in a {@see PaywayException}. */
enum ErrorType: string
{
    /** PayWay could not be reached (DNS, refused connection, offline, ...) */
    case Connection = 'connection';

    /** the request took longer than the configured timeout */
    case Timeout = 'timeout';

    /** the call was cancelled */
    case Cancelled = 'cancelled';

    /** PayWay's TLS certificate was rejected */
    case BadCertificate = 'badCertificate';

    /** PayWay answered without a PayWay `status` (e.g. an HTML page) */
    case UnexpectedResponse = 'unexpectedResponse';

    /** the refund payload could not be encrypted (missing or invalid RSA key) */
    case Encryption = 'encryption';

    /** a callback body is not the JSON object PayWay sends */
    case InvalidCallback = 'invalidCallback';

    /** any other failure; see the previous exception */
    case Unknown = 'unknown';
}
