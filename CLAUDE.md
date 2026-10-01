# CLAUDE.md

ABA PayWay **Ecommerce Checkout** SDKs: Dart (`dart/`), Flutter widgets
(`flutter/`), PHP (`php/` + root `composer.json`), Kotlin (`kotlin/`) and
Node.js (`node/`), with shared known answers in `spec/`. Commands and releases are in
[CONTRIBUTING.md](CONTRIBUTING.md); this file lists what is easy to get
wrong.

## Never commit or expose

- `.env` / `.env.*` files hold merchant API keys. Never commit, print or
  log them; check `git diff --cached` for key values before committing.
  Past commits leaked an API key through `.env.example`: templates must
  only contain placeholders.
- `.aba-docs/` holds ABA's documentation. Read it; never commit it or copy
  its text into the repository. This repository is public.
- `spec/fixtures/*.pem` are throwaway test keys, not ABA keys.

## Rules

- Hashes are `base64(HMAC-SHA512(values, api_key))` over the values in the
  exact order ABA documents; absent optional values count as empty.
  `req_time` is UTC `YYYYMMDDHHmmss`.
- Check behaviour against `spec/test-vectors/php_known_answers.json`
  (computed with ABA's PHP samples) instead of trusting the docs' prose.
- PayWay business errors are returned in `status`; only transport and
  local failures throw.
- `flutter/` depends on `dart_payway` ^2.0.0 from pub.dev, not on `dart/`
  by path: a `dart/` change reaches it only after a Dart release.
- `composer.json` must stay at the repository root for Packagist;
  `.gitattributes` keeps the other SDKs out of the Composer archive.
- Kotlin (`kotlin/`) is JVM-only and server-side. Keep `VERSION_NAME` in
  `kotlin/gradle.properties` and `PaywayService.SDK_VERSION` equal (a test
  checks); publishing credentials come only from environment variables.
- Dart: after editing an annotated model, run
  `dart run build_runner build --delete-conflicting-outputs` and commit the
  `*.g.dart` files. CI resolves with `dart pub get --no-example`.
