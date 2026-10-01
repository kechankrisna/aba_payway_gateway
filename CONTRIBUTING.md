# Contributing

## Layout

| Folder | Package | Tooling |
|---|---|---|
| `spec/` | shared known answers (`spec/test-vectors/`) and throwaway RSA keys (`spec/fixtures/`) | PHP to regenerate |
| `dart/` | `dart_payway` | Dart 3.9+ |
| `flutter/` | `flutter_payway` | Flutter |
| `php/` + `composer.json` | `kechankrisna/php_payway` | PHP, Composer |
| `kotlin/` | unpublished | Gradle |
| `node/` | `@kechankrisna/payway-checkout` | Node.js 22+, npm |

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

Flutter (offline widget tests; it uses `dart_payway` from pub.dev):

```sh
cd flutter
flutter pub get
dart format lib test example/lib example/test
flutter analyze --fatal-infos
flutter test
(cd example && flutter pub get && flutter test)
```

PHP (from the repository root):

```sh
composer install
composer test:unit   # offline, includes the known answers
composer analyse     # PHPStan, level max
composer cs          # coding style (composer cs:fix to apply)
composer test        # also runs the integration tests if php/.env exists
```

Node.js (offline tests; `npx vitest run test/integration.test.ts` runs the
integration tests with `node/.env`, same rules as Dart):

```sh
cd node
npm ci
npm run typecheck && npm run lint && npm run format:check
npm run test:unit
npm run build
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
| Flutter | `flutter/pubspec.yaml`, `flutter/CHANGELOG.md` | push tag `flutter-vX.Y.Z`; `.github/workflows/release-flutter.yml` publishes |
| PHP | tag `vX.Y.Z` | Packagist reads the tag (composer.json at the root) |
| Node.js | `node/package.json`, `node/src/version.ts`, `node/CHANGELOG.md` | push tag `node-vX.Y.Z`; `.github/workflows/release-node.yml` publishes |

Plain `v*` tags are PHP releases; use prefixed tags (e.g. `dart-v2.0.1`) for
the others. Packagist ignores tags that do not parse as versions.

One-time setup for Dart and Flutter: on pub.dev, the package → Admin →
Automated publishing → GitHub Actions, repository
`kechankrisna/payway-checkout`, tag pattern `dart-v{{version}}` (dart_payway)
or `flutter-v{{version}}` (flutter_payway).

One-time setup for Node.js (npm trusted publishing, no token): on
npmjs.com, `@kechankrisna/payway-checkout` → Settings → Trusted publishing →
GitHub Actions, repository `kechankrisna/payway-checkout`, workflow
`release-node.yml`.
