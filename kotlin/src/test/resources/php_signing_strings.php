<?php
// Callback signing strings ($b4hash of the PHP sample in ABA's docs) for
// edge-case bodies: PHP float formatting, json_encode escaping, lists.
// Regenerate from kotlin/ with:
//   php src/test/resources/php_signing_strings.php > src/test/resources/php_signing_strings.jsonl
$bodies = [
  '{"b":1e2,"a":0.1,"c":1e15,"d":1e14,"e":0.00001,"f":-2.50,"g":12345678901234567890,"h":false,"i":true,"j":null,"k":"x/y"}',
  '{"n":{"f":[10.0,1e15,1e17,0.1,1.5e-7,-0.0,100000.0],"s":"a/b \"q\" \\\\ \n\t\u0001 é 😀 <&>\u007f","o":{"0":"a","1":"b"},"p":{"1":"a","0":"b"},"e":{},"l":[]}}',
  '{"amount":0.30000000000000004,"big":123456789.123456789,"neg":-0.000123}',
];
foreach ($bodies as $raw) {
  $response = json_decode($raw, true);
  ksort($response);
  $b4hash = '';
  foreach ($response as $value) { if (is_array($value)) { $value = json_encode($value); } $b4hash .= $value; }
  echo json_encode(['body' => $raw, 'b4hash' => $b4hash], JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE), "\n";
}
