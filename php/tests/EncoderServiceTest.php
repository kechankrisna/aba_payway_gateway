<?php

use PhpPayway\Services\EncoderService;

uses()->group('EncoderService');

test("EncoderService.base64_encode and base64_decode map", function() {
    $input = [
      ["name" => "ទំនិញសាកល្បង", "quantity" => 1, "price" => 6]
    ];
    $encoded = EncoderService::base64_encode($input);
    dd("\n". "encoded $encoded");

    $decoded = EncoderService::base64_decode($encoded);
//    print_r("\n". "decoded $decoded");

//    PHPUnit\Framework\assertEquals(json_encode($input), json_encode($decoded));
    PHPUnit\Framework\assertEquals((array) ($input), (array) $decoded);

  })->group('EncoderService');

test("EncoderService.base64_encode and base64_decode String", function() {
    $input = "ទំនិញសាកល្បង";
    $encoded = EncoderService::base64_encode($input);
    dd("encoded $encoded");
    $decoded = EncoderService::base64_decode($encoded);
    dd("decoded $decoded");

    PHPUnit\Framework\assertEquals(($input), $decoded);
  })->group('EncoderService');

test("EncoderService.base64_encode and base64_decode null", function() {
    $input = null;
    $encoded = EncoderService::base64_encode($input);
    dd("encoded $encoded");
    $decoded = EncoderService::base64_decode($encoded);
    dd("decoded $decoded");

    PHPUnit\Framework\assertEquals(($input), $decoded);
  })->group('EncoderService');

