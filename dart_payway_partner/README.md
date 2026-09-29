# dart_payway_partner has moved

This package continues as **[`payway_partner`](https://pub.dev/packages/payway_partner)**
in its own repository, next to the Node.js and PHP SDKs:

**https://github.com/kechankrisna/payway-partner**

## Migrate

```yaml
dependencies:
  payway_partner: ^2.0.0
```

```dart
// before
import 'package:dart_payway_partner/dart_payway_partner.dart';
// after
import 'package:payway_partner/payway_partner.dart';
```

Version 2.0.0 has breaking changes (camelCase fields, typed errors, required
`currency`, TLS verification); see the
[CHANGELOG](https://github.com/kechankrisna/payway-partner/blob/main/dart/CHANGELOG.md)
for the full list.

The 1.x source remains in this repository's git history.
