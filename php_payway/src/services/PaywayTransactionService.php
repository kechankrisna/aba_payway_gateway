<?php

namespace PhpPayway\Services;

use PhpPayway\Models\PaywayMerchant;
use PhpPayway\Models\Requests\PaywayCheckTransaction;
use PhpPayway\Models\Requests\PaywayCreateTransaction;
use PhpPayway\Models\Responses\PaywayCreateTransactionResponse;
use GuzzleHttp;
use JsonMapper;
use mysql_xdevapi\Exception;

class PaywayTransactionService
{

    static function uniqueTranID(): string
    {
        $mt = explode(' ', microtime());
        return intval( $mt[1] * 1E3 ) + intval( round( $mt[0] * 1E3 ) );
    }

    static function uniqueReqTime(): string
    {
        return (string)date('Ymdhis', time());
    }

    public function __construct(public PaywayMerchant $merchant)
    {

    }

    public function createTransaction(PaywayCreateTransaction $transaction): PaywayCreateTransactionResponse|null
    {
        try {
            $service = new PaywayClientService(merchant: $this->merchant);
            $form_service = new PaywayClientFormRequestService( merchant: $this->merchant);
            $request_options = $form_service->generateCreateTransactionFormData(transaction: $transaction);
            $response = $service->client->request( "POST", uri: "/api/payment-gateway/v1/payments/purchase", options: [
                'form_params' =>  $request_options
            ]);

            $data =json_decode( $response->getBody()->getContents());

            $mapper = new JsonMapper();

            return $mapper->map(json: $data, object: new PaywayCreateTransactionResponse());
        } catch (Exception $exception) {
            dd("exc $exception");
        } catch (GuzzleHttp\Exception\GuzzleException $e) {
            dd("guz $e");
        }
        return null;
    }
}