import { NodePaywayCrypto, type PaywayCrypto } from './crypto.js';
import type { PaywayMerchant } from './merchant.js';
import type { Purchase, TransactionListQuery } from './models.js';

/** returns the current time; injectable so `req_time` can be tested */
export type PaywayClock = () => Date;

/** A signed request body: field name to value, `hash` last. */
export type SignedBody = Record<string, string>;

/**
 * Builds the signed request bodies of the PayWay checkout APIs. Every hash
 * is `base64(HMAC-SHA512(values..., api_key))` over the values in the order
 * the docs list them; absent optional values count as empty.
 */
export class PaywayRequestBuilder {
  readonly #merchant: PaywayMerchant;
  readonly #clock: PaywayClock;
  readonly #crypto: PaywayCrypto;

  constructor(
    merchant: PaywayMerchant,
    options: { clock?: PaywayClock; crypto?: PaywayCrypto } = {},
  ) {
    this.#merchant = merchant;
    this.#clock = options.clock ?? (() => new Date());
    this.#crypto = options.crypto ?? new NodePaywayCrypto();
  }

  /** form fields of `purchase`, in PayWay's order, with `hash` */
  purchase(p: Purchase, requestTime?: string): SignedBody {
    const time = this.#requestTime(requestTime);
    const b64Json = (value: unknown): string | undefined =>
      value === undefined ? undefined : base64(JSON.stringify(value));

    // hashed, in the documented order
    const hashed: Record<string, string | undefined> = {
      req_time: time,
      merchant_id: this.#merchant.merchantId,
      tran_id: p.tranId,
      amount: formatAmount(p.amount),
      items:
        p.items === undefined || p.items.length === 0
          ? undefined
          : b64Json(
              p.items.map((i) => ({
                name: i.name,
                quantity: i.quantity,
                price: i.price,
              })),
            ),
      shipping: p.shipping === undefined ? undefined : formatAmount(p.shipping),
      firstname: p.firstName,
      lastname: p.lastName,
      email: p.email,
      phone: p.phone,
      type: p.type,
      payment_option: p.paymentOption,
      return_url: p.returnUrl === undefined ? undefined : base64(p.returnUrl),
      cancel_url: p.cancelUrl,
      continue_success_url: p.continueSuccessUrl,
      return_deeplink:
        p.returnDeeplink === undefined
          ? undefined
          : b64Json({
              ios_scheme: p.returnDeeplink.iosScheme,
              android_scheme: p.returnDeeplink.androidScheme,
            }),
      currency: p.currency,
      custom_fields: b64Json(p.customFields),
      return_params: p.returnParams,
      payout:
        p.payout === undefined
          ? undefined
          : b64Json(p.payout.map((x) => ({ acc: x.account, amt: x.amount }))),
      lifetime: p.lifetime === undefined ? undefined : String(p.lifetime),
      additional_params: b64Json(p.additionalParams),
      google_pay_token: p.googlePayToken,
      skip_success_page:
        p.skipSuccessPage === undefined
          ? undefined
          : p.skipSuccessPage
            ? '1'
            : '0',
    };
    // sent but not part of the hash
    const unhashed: Record<string, string | undefined> = {
      view_type: p.viewType,
      payment_gate:
        p.paymentGate === undefined ? undefined : String(p.paymentGate),
    };
    return {
      ...defined(hashed),
      ...defined(unhashed),
      hash: this.sign(Object.values(hashed)),
    };
  }

  /** body of `check-transaction-2` */
  checkTransaction(tranId: string, requestTime?: string): SignedBody {
    return this.#tranIdBody(tranId, requestTime);
  }

  /** body of `transaction-detail` */
  transactionDetail(tranId: string, requestTime?: string): SignedBody {
    return this.#tranIdBody(tranId, requestTime);
  }

  /** body of `close-transaction` */
  closeTransaction(tranId: string, requestTime?: string): SignedBody {
    return this.#tranIdBody(tranId, requestTime);
  }

  /** body of `transaction-list-2` */
  transactionList(q: TransactionListQuery, requestTime?: string): SignedBody {
    const time = this.#requestTime(requestTime);
    const hashed: Record<string, string | undefined> = {
      req_time: time,
      merchant_id: this.#merchant.merchantId,
      from_date: q.fromDate === undefined ? undefined : formatDate(q.fromDate),
      to_date: q.toDate === undefined ? undefined : formatDate(q.toDate),
      from_amount:
        q.fromAmount === undefined ? undefined : formatAmount(q.fromAmount),
      to_amount:
        q.toAmount === undefined ? undefined : formatAmount(q.toAmount),
      status:
        q.statuses === undefined || q.statuses.length === 0
          ? undefined
          : q.statuses.join(','),
      page: q.page === undefined ? undefined : String(q.page),
      pagination: q.pagination === undefined ? undefined : String(q.pagination),
    };
    return { ...defined(hashed), hash: this.sign(Object.values(hashed)) };
  }

  /** body of `exchange-rate` */
  exchangeRate(requestTime?: string): SignedBody {
    const time = this.#requestTime(requestTime);
    const merchantId = this.#merchant.merchantId;
    return {
      req_time: time,
      merchant_id: merchantId,
      hash: this.sign([time, merchantId]),
    };
  }

  /**
   * Body of `refund`: `merchant_auth` is the RSA-encrypted
   * `{"mc_id", "tran_id", "refund_amount"}`, which needs the merchant RSA
   * public key.
   * @throws {TypeError} without the RSA public key
   */
  refund(
    tranId: string,
    refundAmount: number,
    requestTime?: string,
  ): SignedBody {
    const rsaKey = this.#merchant.rsaPublicKey;
    if (rsaKey === undefined || rsaKey === '') {
      throw new TypeError('refunds need the RSA public key provided by ABA');
    }
    const time = this.#requestTime(requestTime);
    const merchantId = this.#merchant.merchantId;
    const merchantAuth = this.#crypto.rsaEncrypt(
      JSON.stringify({
        mc_id: merchantId,
        tran_id: tranId,
        refund_amount: refundAmount,
      }),
      rsaKey,
    );
    return {
      request_time: time,
      merchant_id: merchantId,
      merchant_auth: merchantAuth,
      hash: this.sign([time, merchantId, merchantAuth]),
    };
  }

  /** `base64(HMAC-SHA512(concatenated values, api_key))`; undefined counts as empty */
  sign(values: Iterable<string | undefined>): string {
    return this.#crypto.hmacSha512Base64(
      Array.from(values, (v) => v ?? '').join(''),
      this.#merchant.apiKey,
    );
  }

  #tranIdBody(tranId: string, requestTime: string | undefined): SignedBody {
    const time = this.#requestTime(requestTime);
    const merchantId = this.#merchant.merchantId;
    return {
      req_time: time,
      merchant_id: merchantId,
      tran_id: tranId,
      hash: this.sign([time, merchantId, tranId]),
    };
  }

  #requestTime(requestTime: string | undefined): string {
    const time = requestTime ?? formatRequestTime(this.#clock());
    if (!/^\d{14}$/.test(time)) {
      throw new RangeError(
        `requestTime must be 14 digits YYYYMMDDHHmmss, got "${time}"`,
      );
    }
    return time;
  }
}

const two = (value: number) => String(value).padStart(2, '0');

/** `YYYYMMDDHHmmss` in UTC, as PayWay requires */
export function formatRequestTime(time: Date): string {
  return (
    String(time.getUTCFullYear()).padStart(4, '0') +
    two(time.getUTCMonth() + 1) +
    two(time.getUTCDate()) +
    two(time.getUTCHours()) +
    two(time.getUTCMinutes()) +
    two(time.getUTCSeconds())
  );
}

/** `YYYY-MM-DD HH:mm:ss` in local time, as given (no time zone conversion) */
export function formatDate(time: Date): string {
  return (
    `${String(time.getFullYear()).padStart(4, '0')}-${two(time.getMonth() + 1)}-${two(time.getDate())} ` +
    `${two(time.getHours())}:${two(time.getMinutes())}:${two(time.getSeconds())}`
  );
}

/** amounts without a trailing `.0`: `6` stays `6`, `6.5` stays `6.5` */
export function formatAmount(amount: number): string {
  return String(amount);
}

const base64 = (value: string) => Buffer.from(value, 'utf8').toString('base64');

function defined(fields: Record<string, string | undefined>): SignedBody {
  const out: SignedBody = {};
  for (const [key, value] of Object.entries(fields)) {
    if (value !== undefined) out[key] = value;
  }
  return out;
}
