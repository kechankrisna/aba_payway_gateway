<?php

declare(strict_types=1);

namespace PhpPayway\Http;

use PhpPayway\Exception\ErrorType;
use PhpPayway\Exception\PaywayException;

/**
 * Default {@see HttpClient}, backed by ext-curl. TLS certificates are always
 * verified.
 */
final class CurlHttpClient implements HttpClient
{
    /** @param float $timeoutSeconds whole request timeout */
    public function __construct(
        private readonly float $timeoutSeconds = 60.0,
    ) {
        if (!\extension_loaded('curl')) {
            throw new \LogicException(
                'ext-curl is required by CurlHttpClient; install it or pass a Psr18HttpClient',
            );
        }
    }

    public function post(string $url, array $headers, string $body): HttpResponse
    {
        $lines = [];
        foreach ($headers as $name => $value) {
            $lines[] = "{$name}: {$value}";
        }

        $curl = curl_init($url);
        curl_setopt_array($curl, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $body,
            CURLOPT_HTTPHEADER => $lines,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_TIMEOUT_MS => (int) ($this->timeoutSeconds * 1000),
            CURLOPT_CONNECTTIMEOUT_MS => (int) ($this->timeoutSeconds * 1000),
        ]);
        $reply = curl_exec($curl);
        $errno = curl_errno($curl);
        $status = (int) curl_getinfo($curl, CURLINFO_RESPONSE_CODE);

        if ($errno !== 0 || !\is_string($reply)) {
            $error = curl_error($curl);
            throw new PaywayException(self::errorType($errno), self::message($errno, $error));
        }

        return new HttpResponse($status, $reply);
    }

    private static function errorType(int $errno): ErrorType
    {
        return match ($errno) {
            CURLE_OPERATION_TIMEDOUT => ErrorType::Timeout,
            // CURLE_SSL_CACERT and CURLE_SSL_PEER_CERTIFICATE are both 60
            CURLE_SSL_PEER_CERTIFICATE, CURLE_SSL_CERTPROBLEM => ErrorType::BadCertificate,
            CURLE_COULDNT_RESOLVE_HOST, CURLE_COULDNT_CONNECT, CURLE_COULDNT_RESOLVE_PROXY,
            CURLE_SEND_ERROR, CURLE_RECV_ERROR, CURLE_GOT_NOTHING => ErrorType::Connection,
            default => ErrorType::Unknown,
        };
    }

    private static function message(int $errno, string $error): string
    {
        return match (self::errorType($errno)) {
            ErrorType::Timeout => 'Timeout with PayWay',
            ErrorType::BadCertificate => 'Bad certificate from PayWay',
            ErrorType::Connection => 'Could not connect to PayWay',
            default => "Request to PayWay failed: {$error}",
        } . " (curl {$errno})";
    }
}
