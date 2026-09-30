# PayWay Checkout SDKs

Clients for the **ABA PayWay Ecommerce Checkout** API in several languages.
For the PayWay *partner* API (merchant onboarding), see
[payway-partner](https://github.com/kechankrisna/payway-partner).

| Folder | Package | Status |
|---|---|---|
| [`dart/`](dart/README.md) | [`dart_payway`](https://pub.dev/packages/dart_payway) (pub.dev) | 2.0.0: every checkout API, callback verification, tested against ABA's PHP samples and the sandbox |
| [`flutter/`](flutter/README.md) | [`flutter_payway`](https://pub.dev/packages/flutter_payway) (pub.dev) | 1.x widgets, built on `dart_payway` 1.x |
| [`php/`](php/README.md) | [`aba_payway_gateway/php_payway`](https://packagist.org/packages/aba_payway_gateway/php_payway) (Packagist) | 1.x: purchase and check transaction |
| [`kotlin/`](kotlin/) | not published | Kotlin Multiplatform prototype |
| `node/` | planned | — |

`spec/` holds what every SDK should agree on: request hashes and callback
signatures computed with the PHP samples from ABA's documentation
(`spec/test-vectors/`), and throwaway RSA test keys (`spec/fixtures/`).

## Where to run it

Call PayWay from **your server**: the API key is a secret, and PayWay only
accepts requests from whitelisted domains or IPs.

## Repository layout

```
spec/       shared known answers and test keys
dart/       Dart SDK        → pub.dev
flutter/    Flutter widgets → pub.dev
php/        PHP SDK         → Packagist (composer.json is at the root)
kotlin/     Kotlin SDK      (unpublished)
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for tests and releases.
