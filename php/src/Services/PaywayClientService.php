<?php

namespace PhpPayway\Services;

use PhpPayway\Models\PaywayMerchant;
use GuzzleHttp;
use GuzzleHttp\Client;

class PaywayClientService
{
    public Client $client;

    public function __construct(public PaywayMerchant $merchant)
    {
        $this->client = new GuzzleHttp\Client([
            'base_uri' => $this->merchant->baseApiUrl,
            'headers' => [
                'Referer' => $this->merchant->refererDomain,
                'Accept' => 'application/json',
            ],
            'request.options' => [
                'timeout' => 60,
                'connect_timeout' => 60
            ]
        ]);
    }

    function getStr(
        string $req_time,
        string $tran_id,
        string $amount = "",
        string $items = "",
        string $shipping = "",
        string $ctid = "",
        string $pwt = "",
        string $firstname = "",
        string $lastname = "",
        string $email = "",
        string $phone = "",
        string $type = "",
        string $payment_option = "",
        string $return_url = "",
        string $cancel_url = "",
        string $continue_success_url = "",
        string $return_deeplink = "",
        string $currency = "",
        string $custom_fields = "",
        string $return_params = "",
    ): string
    {
        // String =
        // req_time + merchant_id +
        // tran_id + amount + items +
        // shipping + ctid + pwt +
        // firstname + lastname +
        // email + phone + type +
        // payment_option + return_url +
        // cancel_url + continue_success_url +
        // return_deeplink + currency + custom_fields + return_params with public_key.
        // assert(tranID != null);
        // assert(amount != null);
        $str = $req_time . $this->merchant->merchantID . $tran_id . $amount . $items . $shipping . $ctid . $pwt . $firstname . $lastname . $email . $phone . $type . $payment_option . $return_url . $cancel_url . $continue_success_url . $return_deeplink . $currency . $custom_fields . $return_params;
        return $str;
    }

    function getHash(String $str): string
    {
        $hash = base64_encode(hash_hmac('sha512', $str, $this->merchant->merchantApiKey, true));
        return $hash;
    }

    /// [handleTransactionResponse]
    ///
    /// `This will be describe response from each transaction based on status code`
    static function handleTransactionResponse(int $status): string
    {
        return match ($status) {
            1 => "Invalid Hash, Hash generated is incorrect and not following the guideline to generate the Hash.",
            2 => "Invalid Transaction ID, unsupported characters included in Transaction ID",
            3 => "Invalid Amount format need not include decimal point for KHR transaction. example for USD 100.00 for KHR 100",
            4 => "Duplicate Transaction ID, the transaction ID already exists in PayWay, generate new transaction.",
            5 => "Invalid Continue Success URL, (Main domain must be registered in PayWay backend to use success URL)",
            6 => "Invalid Domain Name (Request originated from non-whitelisted domain need to register domain in PayWay backend)",
            7 => "Invalid Return Param (String must be lesser than 500 chars)",
            9 => "Invalid Limit Amount (The amount must be smaller than value that allowed in PayWay backend)",
            10 => "Invalid Shipping Amount",
            11 => "PayWay Server Side Error",
            12 => "Invalid Currency Type (Merchant is allowed only one currency - USD or KHR)",
            13 => "Invalid Item, value for items parameters not following the guideline to generate the base 64 encoded array of item list.",
            15 => "Invalid Channel Values for parameter topup_channel",
            16 => "Invalid First Name - unsupported special characters included in value",
            17 => "Invalid Last Name",
            18 => "Invalid Phone Number",
            19 => "Invalid Email Address",
            20 => "Required purchase details when checkout",
            21 => "Expired production key",
            default => "other - server-side error",
        };
    }
}