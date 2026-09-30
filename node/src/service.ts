import { timingSafeEqual } from 'node:crypto';

import {
  NodePaywayCrypto,
  callbackSigningString,
  type PaywayCrypto,
} from './crypto.js';
import { PaymentOption } from './enums.js';
import { PaywayError, type PaywayErrorType } from './errors.js';
import type { PaywayMerchant } from './merchant.js';
import {
  callbackFromJson,
  checkTransactionResponseFromJson,
  exchangeRateResponseFromJson,
  purchaseResponseFromJson,
  refundResponseFromJson,
  statusResponseFromJson,
  transactionDetailResponseFromJson,
  transactionListResponseFromJson,
  type Callback,
  type CheckTransactionResponse,
  type ExchangeRateResponse,
  type Json,
  type Purchase,
  type PurchaseResponse,
  type RefundResponse,
  type StatusResponse,
  type TransactionDetailResponse,
  type TransactionListQuery,
  type TransactionListResponse,
} from './models.js';
import {
  PaywayRequestBuilder,
  type PaywayClock,
  type SignedBody,
} from './request-builder.js';
import { SDK_VERSION } from './version.js';

/** receives request/response log lines */
export type PaywayLogger = (message: string) => void;

/** Options of every API call. */
export interface CallOptions {
  /** aborts the call; it then throws a `cancelled` {@link PaywayError} */
  signal?: AbortSignal | undefined;
}

/** Dependencies of {@link PaywayService}; all but `merchant` are optional. */
export interface PaywayServiceOptions {
  /** merchant credentials used to sign */
  merchant: PaywayMerchant;
  /** HTTP client (default: global `fetch`) */
  fetch?: typeof globalThis.fetch | undefined;
  /** source of `req_time` (default: current time) */
  clock?: PaywayClock | undefined;
  /** hashing and RSA (default: `node:crypto`) */
  crypto?: PaywayCrypto | undefined;
  /** receives request/response logs; nothing is logged without it */
  logger?: PaywayLogger | undefined;
  /** per request timeout in milliseconds (default 60 000) */
  timeoutMs?: number | undefined;
}

/** endpoint of {@link PaywayService.purchase} and {@link PaywayService.checkoutHtml} */
export const PURCHASE_PATH = '/api/payment-gateway/v1/payments/purchase';
/** endpoint of {@link PaywayService.checkTransaction} */
export const CHECK_TRANSACTION_PATH =
  '/api/payment-gateway/v1/payments/check-transaction-2';
/** endpoint of {@link PaywayService.getTransactionDetail} */
export const TRANSACTION_DETAIL_PATH =
  '/api/payment-gateway/v1/payments/transaction-detail';
/** endpoint of {@link PaywayService.closeTransaction} */
export const CLOSE_TRANSACTION_PATH =
  '/api/payment-gateway/v1/payments/close-transaction';
/** endpoint of {@link PaywayService.getTransactionList} */
export const TRANSACTION_LIST_PATH =
  '/api/payment-gateway/v1/payments/transaction-list-2';
/** endpoint of {@link PaywayService.getExchangeRates} */
export const EXCHANGE_RATE_PATH = '/api/payment-gateway/v1/exchange-rate';
/** endpoint of {@link PaywayService.refund} */
export const REFUND_PATH =
  '/api/merchant-portal/merchant-access/online-transaction/refund';

/**
 * Header carrying the callback signature. Node lowercases incoming header
 * names: read `req.headers['x-payway-hmac-sha512']`.
 */
export const CALLBACK_SIGNATURE_HEADER = 'X-PayWay-HMAC-SHA512';

/**
 * ABA PayWay Ecommerce Checkout client.
 *
 * PayWay business errors (wrong hash, transaction not found, ...) are
 * returned in `status`. A {@link PaywayError} is thrown only when PayWay
 * could not be reached or did not answer with a status.
 *
 * Run it on your server: the API key is a secret.
 */
export class PaywayService {
  /** merchant credentials used to sign */
  readonly merchant: PaywayMerchant;
  /** builds the signed request bodies; exposed to support new endpoints */
  readonly requestBuilder: PaywayRequestBuilder;
  readonly #crypto: PaywayCrypto;
  readonly #fetch: typeof globalThis.fetch;
  readonly #logger: PaywayLogger | undefined;
  readonly #timeoutMs: number;

  constructor(options: PaywayServiceOptions) {
    this.merchant = options.merchant;
    this.#crypto = options.crypto ?? new NodePaywayCrypto();
    this.requestBuilder = new PaywayRequestBuilder(options.merchant, {
      ...(options.clock && { clock: options.clock }),
      crypto: this.#crypto,
    });
    this.#fetch = options.fetch ?? globalThis.fetch;
    this.#logger = options.logger;
    this.#timeoutMs = options.timeoutMs ?? 60_000;
  }

  /**
   * Creates a payment and returns its KHQR string and ABA Mobile deep link.
   * Only {@link PaymentOption.abapayKhqrDeeplink} answers with JSON; use
   * {@link checkoutHtml} for every other payment option.
   * @throws {TypeError} (rejects) for any other payment option
   */
  async purchase(
    purchase: Purchase,
    options: CallOptions = {},
  ): Promise<PurchaseResponse> {
    if (purchase.paymentOption !== PaymentOption.abapayKhqrDeeplink) {
      throw new TypeError(
        'only abapay_khqr_deeplink returns JSON; use checkoutHtml() for the hosted payment page',
      );
    }
    const fields = this.requestBuilder.purchase(purchase);
    const form = new FormData();
    for (const [name, value] of Object.entries(fields)) {
      form.append(name, value);
    }
    return this.#post(
      PURCHASE_PATH,
      form,
      JSON.stringify(fields),
      purchaseResponseFromJson,
      options,
    );
  }

  /**
   * An HTML page that immediately POSTs `purchase` to PayWay, opening its
   * hosted payment page. Serve it from your site or load it in a web view.
   */
  checkoutHtml(purchase: Purchase): string {
    const inputs = Object.entries(this.requestBuilder.purchase(purchase))
      .map(
        ([name, value]) =>
          `      <input type="hidden" name="${escapeHtml(name)}" value="${escapeHtml(value)}">\n`,
      )
      .join('');
    const action = escapeHtml(this.#url(PURCHASE_PATH).href);
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PayWay</title>
</head>
<body>
  <form method="POST" action="${action}" id="payway_checkout">
${inputs}  </form>
  <script>document.getElementById("payway_checkout").submit();</script>
</body>
</html>
`;
  }

  /** Status of a transaction created within the last 7 days. */
  checkTransaction(
    tranId: string,
    options: CallOptions = {},
  ): Promise<CheckTransactionResponse> {
    return this.#postJson(
      CHECK_TRANSACTION_PATH,
      this.requestBuilder.checkTransaction(tranId),
      checkTransactionResponseFromJson,
      options,
    );
  }

  /** Details of a transaction, including its payment and refund operations. */
  getTransactionDetail(
    tranId: string,
    options: CallOptions = {},
  ): Promise<TransactionDetailResponse> {
    return this.#postJson(
      TRANSACTION_DETAIL_PATH,
      this.requestBuilder.transactionDetail(tranId),
      transactionDetailResponseFromJson,
      options,
    );
  }

  /** Cancels an unpaid transaction: later payments are rejected or reversed. */
  closeTransaction(
    tranId: string,
    options: CallOptions = {},
  ): Promise<StatusResponse> {
    return this.#postJson(
      CLOSE_TRANSACTION_PATH,
      this.requestBuilder.closeTransaction(tranId),
      statusResponseFromJson,
      options,
    );
  }

  /** Transactions matching `query`, one page at a time. */
  getTransactionList(
    query: TransactionListQuery = {},
    options: CallOptions = {},
  ): Promise<TransactionListResponse> {
    return this.#postJson(
      TRANSACTION_LIST_PATH,
      this.requestBuilder.transactionList(query),
      transactionListResponseFromJson,
      options,
    );
  }

  /**
   * Refunds `amount` (full or partial) within 30 days of the transaction.
   * Needs the merchant RSA public key.
   * @throws {PaywayError} `encryption` (rejects) without a valid RSA public key
   */
  async refund(
    tranId: string,
    amount: number,
    options: CallOptions = {},
  ): Promise<RefundResponse> {
    let body: SignedBody;
    try {
      body = this.requestBuilder.refund(tranId, amount);
    } catch (error) {
      throw new PaywayError(
        'encryption',
        'Refunds need a valid merchant RSA public key',
        { cause: error },
      );
    }
    return this.#postJson(REFUND_PATH, body, refundResponseFromJson, options);
  }

  /** ABA Bank's latest exchange rates, in riel per unit of each currency. */
  getExchangeRates(options: CallOptions = {}): Promise<ExchangeRateResponse> {
    return this.#postJson(
      EXCHANGE_RATE_PATH,
      this.requestBuilder.exchangeRate(),
      exchangeRateResponseFromJson,
      options,
    );
  }

  /**
   * Whether `body`, the raw JSON PayWay POSTed to your `return_url`, is
   * signed with `signature` (the `X-PayWay-HMAC-SHA512` header). `key`
   * defaults to the merchant API key.
   *
   * ```ts
   * app.post('/payway/callback', express.text({ type: '*\/*' }), (req, res) => {
   *   const ok = payway.verifyCallback(req.body, req.get('x-payway-hmac-sha512'));
   * });
   * ```
   */
  verifyCallback(
    body: string,
    signature: string | null | undefined,
    key?: string,
  ): boolean {
    if (typeof signature !== 'string') return false;
    let decoded: unknown;
    try {
      decoded = JSON.parse(body);
    } catch {
      return false;
    }
    if (!isObject(decoded)) return false;
    const expected = Buffer.from(
      this.#crypto.hmacSha512Base64(
        callbackSigningString(decoded),
        key ?? this.merchant.apiKey,
      ),
    );
    const actual = Buffer.from(signature.trim());
    return (
      expected.length === actual.length && timingSafeEqual(expected, actual)
    );
  }

  /**
   * Parses a callback body; call {@link verifyCallback} first.
   * @throws {PaywayError} `invalidCallback` when it is not a JSON object
   */
  parseCallback(body: string): Callback {
    let decoded: unknown;
    try {
      decoded = JSON.parse(body);
    } catch (error) {
      throw new PaywayError('invalidCallback', 'Callback body is not JSON', {
        cause: error,
      });
    }
    if (!isObject(decoded)) {
      throw new PaywayError(
        'invalidCallback',
        'Callback body is not a JSON object',
      );
    }
    return callbackFromJson(decoded);
  }

  #postJson<T>(
    path: string,
    body: SignedBody,
    parse: (json: Json) => T,
    options: CallOptions,
  ): Promise<T> {
    const payload = JSON.stringify(body);
    return this.#post(path, payload, payload, parse, options);
  }

  /**
   * POSTs and parses PayWay's reply. PayWay answers errors with a JSON body
   * carrying the real status, possibly with a non-2xx HTTP status, which is
   * parsed like a success; a status nested in `data` is lifted.
   */
  async #post<T>(
    path: string,
    body: string | FormData,
    logBody: string,
    parse: (json: Json) => T,
    options: CallOptions,
  ): Promise<T> {
    const url = this.#url(path);
    this.#logger?.(`[PayWay] POST ${url.href} ${logBody}`);

    const timeout = AbortSignal.timeout(this.#timeoutMs);
    const signal = options.signal
      ? AbortSignal.any([options.signal, timeout])
      : timeout;

    const headers: Record<string, string> = {
      Accept: 'application/json',
      'User-Agent': `node-payway/${SDK_VERSION}`,
    };
    // fetch sets the multipart boundary itself
    if (typeof body === 'string') headers['Content-Type'] = 'application/json';
    if (this.merchant.referer !== '')
      headers['Referer'] = this.merchant.referer;

    let status: number;
    let text: string;
    try {
      const response = await this.#fetch(url, {
        method: 'POST',
        headers,
        body,
        signal,
      });
      status = response.status;
      text = await response.text();
    } catch (error) {
      this.#logger?.(`[PayWay] failed ${String(error)}`);
      const [type, message] = describe(error, options.signal, timeout);
      throw new PaywayError(type, message, { cause: error });
    }

    this.#logger?.(`[PayWay] ${String(status)} ${text}`);
    const json = statusBody(text);
    if (json !== undefined) return parse(json);
    throw new PaywayError(
      'unexpectedResponse',
      'Unexpected response from PayWay',
      { statusCode: status },
    );
  }

  #url(path: string): URL {
    return new URL(this.merchant.baseUrl.replace(/\/+$/, '') + path);
  }
}

const isObject = (value: unknown): value is Json =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

/**
 * decode `text` when it holds a PayWay `status`, at the top level or inside
 * `data`, which is lifted to the top
 */
function statusBody(text: string): Json | undefined {
  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    return undefined;
  }
  if (!isObject(json)) return undefined;
  if (isObject(json['status'])) return json;
  const data = json['data'];
  if (isObject(data) && isObject(data['status'])) {
    return { ...json, status: data['status'] };
  }
  return undefined;
}

const CERTIFICATE_ERRORS = new Set([
  'CERT_HAS_EXPIRED',
  'DEPTH_ZERO_SELF_SIGNED_CERT',
  'SELF_SIGNED_CERT_IN_CHAIN',
  'UNABLE_TO_VERIFY_LEAF_SIGNATURE',
  'UNABLE_TO_GET_ISSUER_CERT_LOCALLY',
  'ERR_TLS_CERT_ALTNAME_INVALID',
]);

function describe(
  error: unknown,
  userSignal: AbortSignal | undefined,
  timeout: AbortSignal,
): [PaywayErrorType, string] {
  if (userSignal?.aborted) {
    return ['cancelled', 'Request to PayWay was cancelled'];
  }
  if (timeout.aborted) return ['timeout', 'Timeout with PayWay'];
  const cause = (error as { cause?: { code?: unknown } } | null)?.cause;
  const code = typeof cause?.code === 'string' ? cause.code : undefined;
  if (code !== undefined && CERTIFICATE_ERRORS.has(code)) {
    return ['badCertificate', 'Bad certificate from PayWay'];
  }
  if (error instanceof TypeError) {
    return ['connection', 'Could not connect to PayWay'];
  }
  return ['unknown', `Request to PayWay failed: ${String(error)}`];
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}
