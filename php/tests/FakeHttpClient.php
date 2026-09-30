<?php

declare(strict_types=1);

namespace PhpPayway\Tests;

use PhpPayway\Http\HttpClient;
use PhpPayway\Http\HttpResponse;

/** Records requests and answers with a closure. */
final class FakeHttpClient implements HttpClient
{
    /** @var list<array{url: string, headers: array<string, string>, body: string}> */
    public array $requests = [];

    /** @param \Closure(string, array<string, string>, string): HttpResponse $reply */
    public function __construct(private readonly \Closure $reply) {}

    public function post(string $url, array $headers, string $body): HttpResponse
    {
        $this->requests[] = ['url' => $url, 'headers' => $headers, 'body' => $body];

        return ($this->reply)($url, $headers, $body);
    }

    /** @param array<array-key, mixed> $json */
    public static function json(array $json, int $status = 200): self
    {
        return new self(static fn(): HttpResponse => new HttpResponse($status, json_encode($json, JSON_THROW_ON_ERROR)));
    }
}
