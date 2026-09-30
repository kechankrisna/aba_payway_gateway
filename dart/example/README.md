# dart_payway example

A Flutter demo of [`dart_payway`](https://pub.dev/packages/dart_payway)
against the ABA PayWay checkout **sandbox**: create a KHQR purchase, check
its status, and read exchange rates.

> Demo only. This app embeds the merchant API key to call PayWay directly.
> In production, call PayWay from your server and never ship the API key
> inside an app.

```sh
flutter run --dart-define-from-file=../.env
```

The `.env` is the package's sandbox file (copy `../.env.example`).

```sh
flutter test
```
