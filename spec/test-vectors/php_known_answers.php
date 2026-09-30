<?php
// Regenerate spec/test-vectors/php_known_answers.json with:
//   php spec/test-vectors/php_known_answers.php > spec/test-vectors/php_known_answers.json
// Known answers computed with the PHP samples from the PayWay checkout docs.
$api_key = 'test-api-key';
$merchant_id = 'ec000002';
$req_time = '20260102030405';
$h = fn($s) => base64_encode(hash_hmac('sha512', $s, $api_key, true));
$j = fn($v) => json_encode($v, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

// purchase: minimal
$tran_id = 'order-1001'; $amount = '6.5';
$out['purchase_minimal'] = $h($req_time . $merchant_id . $tran_id . $amount);

// purchase: full
$items = base64_encode($j([["name"=>"product 1","quantity"=>1,"price"=>1.5],["name"=>"product 2","quantity"=>2,"price"=>2.5]]));
$shipping = '1'; $firstname='Sok'; $lastname='Dara'; $email='sok@example.com'; $phone='012345678';
$type='pre-auth'; $payment_option='abapay_khqr_deeplink';
$return_url = base64_encode('https://shop.test/payway/callback');
$cancel_url = 'https://shop.test/cancel'; $continue_success_url = 'https://shop.test/done';
$return_deeplink = base64_encode($j(["ios_scheme"=>"shop://done","android_scheme"=>"shop://done"]));
$currency='USD';
$custom_fields = base64_encode($j(["order"=>"1001"]));
$return_params = 'order=1001';
$payout = base64_encode($j([["acc"=>"000133879","amt"=>1],["acc"=>"000133880","amt"=>1.5]]));
$lifetime = '30';
$additional_params = base64_encode($j(["wechat_sub_appid"=>"wx1"]));
$google_pay_token = '';
$skip_success_page = '1';
$b4hash = $req_time . $merchant_id . $tran_id . $amount . $items . $shipping . $firstname . $lastname . $email . $phone . $type . $payment_option . $return_url . $cancel_url . $continue_success_url . $return_deeplink . $currency . $custom_fields . $return_params . $payout . $lifetime . $additional_params . $google_pay_token .$skip_success_page;
$out['purchase_full'] = $h($b4hash);
$out['purchase_full_items'] = $items;
$out['purchase_full_return_url'] = $return_url;
$out['purchase_full_return_deeplink'] = $return_deeplink;
$out['purchase_full_payout'] = $payout;

// check / detail / close
$out['tran_id_hash'] = $h($req_time . $merchant_id . $tran_id);
// list
$out['list_hash'] = $h($req_time . $merchant_id . '2026-01-01 00:00:00' . '2026-01-31 23:59:59' . '1' . '100' . 'APPROVED,REFUNDED' . '2' . '50');
// exchange rate
$out['exchange_hash'] = $h($req_time . $merchant_id);

// callback signature (doc sample body, verbatim algorithm)
$sig = function($raw) use ($api_key) {
  $response = json_decode($raw, true);
  ksort($response);
  $b4hash = '';
  foreach ($response as $value) { if (is_array($value)) { $value = json_encode($value); } $b4hash .= $value; }
  return base64_encode(hash_hmac('sha512', $b4hash, $api_key, true));
};
$cb = '{"tran_id":"9065703303","apv":"544415","status":"0","return_params":"{\"order_id\":\"123\",\"amount\":100,\"client_id\":\"1234567890\"}","original_amount":0.01,"original_currency":"USD","payment_amount":0.01,"payment_currency":"USD","total_amount":0.01,"discount_amount":0,"transaction_date":"2026-08-03 13:57:20","first_name":"","last_name":"","email":"","phone":"","bank_ref":"100FT40074059022","payment_type":"ABA Pay","payer_account":"003471222","bank_name":"","card_source":""}';
$out['callback_body'] = $cb;
$out['callback_signature'] = $sig($cb);
$cb2 = '{"tran_id":"1","status":"0","total_amount":10.0,"paid":true,"meta":{"url":"https://a/b","name":"ហាង"},"tags":["x","y"],"empty":{},"note":null}';
$out['callback2_body'] = $cb2;
$out['callback2_signature'] = $sig($cb2);
echo json_encode($out, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES), "\n";
