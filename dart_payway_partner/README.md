Usage example:

## PaywayPartnerService is required
```dart
var service = PaywayPartnerService(
        partner: PaywayPartner(
      partnerName: dotenv.env['ABA_PARTNER_NAME'] ?? '',
      partnerID: dotenv.env['ABA_PARTNER_ID'] ?? '',
      partnerKey: dotenv.env['ABA_PARTNER_KEY'] ?? '',
      partnerPrivateKey: utf8
          .decode(base64.decode(dotenv.env['ABA_PARTNER_PRIVATE_KEY'] ?? "")),
      partnerPublicKey: utf8
          .decode(base64.decode(dotenv.env['ABA_PARTNER_PUBLIC_KEY'] ?? "")),
      baseApiUrl: dotenv.env['ABA_PARTNER_API_URL'] ?? '',
    ));
```

## by register a new merchant, the merchant field is required

```dart
final merchant = PaywayPartnerRegisterMerchant(
      pushback_url: 'https://www.mylekha.org/',
      redirect_url: 'https://www.mylekha.org/',
      type: 0,
      register_ref: referer_id,
    );
var registerResponse = await service.registerMerchant(merchant: merchant);

```

## by checking the new registered merchant, the register_ref is required
```dart
 final merchant = PaywayPartnerCheckMerchant(
      register_ref: referer_id,
    );
var checkResponse = await service.checkMerchant(merchant: merchant);
```

### to get hash string please use PaywayPartnerClientService

```dart
final clientService = PaywayPartnerClientService(partner);
final str = clientService.getStr(request_time: _requestTime, request_data: request_data);
final hash = clientService.getHash(str);
```

### to encrypt and decrypt using public key and private please use: PaywayPartnerClientFormRequestService

```dart
var service = PaywayPartnerClientFormRequestService(partner);
var encrypted = service.opensslEncrypt(requestData.toMap(), partner.partnerPublicKey);
var decrypted = service.opensslEncrypt(requestData.toMap(), partner.partnerPrivateKey);
```
# NOTE: 
`please look flutte example folder for more information` 