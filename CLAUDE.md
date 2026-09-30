# CLAUDE.md

ABA PayWay **Ecommerce Checkout** SDKs: Dart (`dart/`), Flutter widgets
(`flutter/`), PHP (`php/` + root `composer.json`) and Kotlin (`kotlin/`),
with shared known answers in `spec/`. Commands and releases are in
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
- `flutter/` depends on `dart_payway` 1.x from pub.dev; `dart/` is 2.x.
- `composer.json` must stay at the repository root for Packagist;
  `.gitattributes` keeps the other SDKs out of the Composer archive.
- Dart: after editing an annotated model, run
  `dart run build_runner build --delete-conflicting-outputs` and commit the
  `*.g.dart` files. CI resolves with `dart pub get --no-example`.
