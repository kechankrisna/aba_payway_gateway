# Contributing

## Layout

| Folder | Package | Tooling |
|---|---|---|
| `spec/` | shared known answers (`spec/test-vectors/`) and throwaway RSA keys (`spec/fixtures/`) | PHP to regenerate |
| `dart/` | `dart_payway` | Dart 3.9+ |
| `flutter/` | `flutter_payway` | Flutter |
| `php/` + `composer.json` | `aba_payway_gateway/php_payway` | PHP, Composer |
| `kotlin/` | unpublished | Gradle |

## Secrets

Sandbox credentials go in `.env` files next to each SDK (copy its
`.env.example`). **Never commit a `.env` file.** The root `.gitignore`
ignores every `.env` and `.env.*` except the templates. Keep ABA's
documentation in `.aba-docs/` (ignored): it is not ours to publish.

## Tests

Dart: formatting, analysis, offline tests, then integration tests. The
integration tests use `dart/.env`, or the file named by `PAYWAY_ENV_FILE`
(e.g. `PAYWAY_ENV_FILE=.env.production`). They create and close a 0.10 USD
transaction, so production is refused unless `PAYWAY_ALLOW_PRODUCTION=true`.

```sh
cd dart
dart pub get
dart format lib test
dart analyze --fatal-infos
dart test -x integration
dart test
```

PHP (from the repository root; its tests call the sandbox):

```sh
composer install
composer test
```

## Known answers

`spec/test-vectors/php_known_answers.php` runs the PHP samples from ABA's
documentation on fixed inputs. Regenerate the JSON when inputs change:

```sh
php spec/test-vectors/php_known_answers.php > spec/test-vectors/php_known_answers.json
```

Every SDK should reproduce these hashes and callback signatures.

## Releasing

| SDK | Bump | Publish |
|---|---|---|
| Dart | `dart/pubspec.yaml`, `dart/lib/src/version.dart`, `dart/CHANGELOG.md` | push tag `dart-vX.Y.Z`; `.github/workflows/release-dart.yml` publishes |
| Flutter | `flutter/pubspec.yaml` | `cd flutter && flutter pub publish` |
| PHP | tag `vX.Y.Z` | Packagist reads the tag (composer.json at the root) |

Plain `v*` tags are PHP releases; use prefixed tags (e.g. `dart-v2.0.1`) for
the others. Packagist ignores tags that do not parse as versions.

One-time setup for Dart: on pub.dev, dart_payway → Admin → Automated
publishing → GitHub Actions, repository `kechankrisna/payway-checkout`, tag
pattern `dart-v{{version}}`.
