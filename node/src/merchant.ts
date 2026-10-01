/** Options of {@link PaywayMerchant}. */
export interface PaywayMerchantOptions {
  /** merchant id provided by ABA (`merchant_id`) */
  merchantId: string;
  /** API key provided by ABA, keys every request hash (secret) */
  apiKey: string;
  /** domain whitelisted by ABA, sent as the `Referer` header */
  referer: string;
  /** RSA public key provided by ABA, PEM or bare base64; needed for refunds */
  rsaPublicKey?: string | undefined;
  /** {@link PaywayMerchant.SANDBOX_URL} (default) or {@link PaywayMerchant.PRODUCTION_URL} */
  baseUrl?: string | undefined;
}

const inspectCustom = Symbol.for('nodejs.util.inspect.custom');

/**
 * Merchant credentials provided by ABA Bank.
 *
 * The API key is a secret: it is readable as `apiKey` but kept out of
 * `toString()`, `util.inspect()` / `console.log()` and `JSON.stringify()`.
 */
export class PaywayMerchant {
  /** PayWay checkout sandbox (testing) environment */
  static readonly SANDBOX_URL = 'https://checkout-sandbox.payway.com.kh';

  /** PayWay checkout production (live) environment */
  static readonly PRODUCTION_URL = 'https://checkout.payway.com.kh';

  /** merchant id provided by ABA (`merchant_id`) */
  readonly merchantId: string;
  /** domain whitelisted by ABA, sent as the `Referer` header */
  readonly referer: string;
  /** RSA public key provided by ABA, PEM or bare base64; needed for refunds */
  readonly rsaPublicKey: string | undefined;
  /** {@link SANDBOX_URL} or {@link PRODUCTION_URL} */
  readonly baseUrl: string;
  readonly #apiKey: string;

  constructor(options: PaywayMerchantOptions) {
    this.merchantId = options.merchantId;
    this.#apiKey = options.apiKey;
    this.referer = options.referer;
    this.rsaPublicKey = options.rsaPublicKey;
    this.baseUrl = options.baseUrl ?? PaywayMerchant.SANDBOX_URL;
  }

  /** API key provided by ABA (secret) */
  get apiKey(): string {
    return this.#apiKey;
  }

  /** a copy with the given fields replaced */
  with(changes: Partial<PaywayMerchantOptions>): PaywayMerchant {
    return new PaywayMerchant({
      merchantId: this.merchantId,
      apiKey: this.#apiKey,
      referer: this.referer,
      rsaPublicKey: this.rsaPublicKey,
      baseUrl: this.baseUrl,
      ...changes,
    });
  }

  /** the fields without the API key, for logs */
  toJSON(): Record<string, string | undefined> {
    return {
      merchantId: this.merchantId,
      apiKey: '***',
      referer: this.referer,
      baseUrl: this.baseUrl,
    };
  }

  toString(): string {
    return `PaywayMerchant(merchantId: ${this.merchantId}, apiKey: ***, referer: ${this.referer}, baseUrl: ${this.baseUrl})`;
  }

  [inspectCustom](): string {
    return this.toString();
  }
}
