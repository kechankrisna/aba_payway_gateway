<?php

test('http client', function () {
    $dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
    $dotenv->load();
    $url = $_ENV['ABA_PAYWAY_API_URL'];
    dd($url);

    $client = new GuzzleHttp\Client();
    $res = $client->request('GET', 'https://mylekha.org', [
        'auth' => ['user', 'pass']
    ]);
    dd($res);
});