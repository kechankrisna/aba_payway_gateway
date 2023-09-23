<?php

namespace AbaPaywayGateway\PhpPayway\services;

use AbaPaywayGateway\PhpPayway\models\ABAMerchant;
use AbaPaywayGateway\PhpPayway\models\requests\PaywayCreateTransaction;
use AbaPaywayGateway\PhpPayway\models\responses\PaywayCreateTransactionResponse;
use GuzzleHttp;
use JsonMapper;
use mysql_xdevapi\Exception;

class PaywayTransactionService
{

    static function uniqueTranID(): string
    {
        return (string)microtime();
    }

    static function uniqueReqTime(): string
    {
        return (string)date('yMddHms', time());
    }

    public function __construct(public ABAMerchant $merchant)
    {

    }

    public function createTransaction(PaywayCreateTransaction $transaction): PaywayCreateTransactionResponse|null
    {
        try {
            $service = new ABAClientService(merchant: $this->merchant);
            $request = $service->client->post(uri: "/purchase", options: $transaction->toMap());
            $response = GuzzleHttp\Utils::jsonDecode($request->getBody());
            $mapper = new JsonMapper();
            return $mapper->map(json: $response->data, object: new PaywayCreateTransactionResponse());
            return null;
        } catch (Exception) {
//
        } catch (GuzzleHttp\Exception\GuzzleException $e) {
            //
        }
        return null;
    }
}