<?php

namespace PhpPayway\Services;

use PhpPayway\Models\PaywayMerchant;
use PhpPayway\Models\Requests\PaywayCheckTransaction;
use PhpPayway\Models\Requests\PaywayCreateTransaction;
use PhpPayway\Models\Responses\PaywayCheckTransactionResponse;
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

    /**
     * create a new trasaction
     *
     *
     * @param PaywayCreateTransaction $transaction
     * @return PaywayCreateTransactionResponse|null
     * @throws \JsonMapper_Exception
     */
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

    }

    /**
     * check the current status of this transaction vai its id
     *
     * @param PaywayCheckTransaction $transaction
     * @return PaywayCheckTransactionResponse|null
     * @throws \JsonMapper_Exception
     */
    public function checkTransaction(PaywayCheckTransaction $transaction): PaywayCheckTransactionResponse|null
    {
        try {
            $service = new PaywayClientService(merchant: $this->merchant);
            $form_service = new PaywayClientFormRequestService( merchant: $this->merchant);
            $request_options = $form_service->generateCheckTransactionFormData(transaction: $transaction);
            $response = $service->client->request( "POST", uri: "/api/payment-gateway/v1/payments/check-transaction", options: [
                'form_params' =>  $request_options
            ]);

            $data =json_decode( $response->getBody()->getContents());

            $mapper = new JsonMapper();

            return $mapper->map(json: $data, object: new PaywayCheckTransactionResponse());
        } catch (Exception $exception) {
            dd("exc $exception");
        } catch (GuzzleHttp\Exception\GuzzleException $e) {
            dd("guz $e");
        }
        return null;
    }

    /**
     * will return true if transaction completed
     * otherwise false
     *
     * @param PaywayCheckTransaction $transaction
     * @return bool
     */
    public function isTransactionCompleted(PaywayCheckTransaction $transaction): bool
    {
       $result =  $this->checkTransaction($transaction);
       return $result->status == 0;
    }
}