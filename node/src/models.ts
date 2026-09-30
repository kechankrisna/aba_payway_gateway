import {
  PaymentStatusCode,
  type Currency,
  type PaymentOption,
  type PaymentStatus,
  type TransactionType,
  type ViewType,
} from './enums.js';

// ---- requests -------------------------------------------------------------

/**
 * A purchased item. Items are a description only: PayWay does not use their
 * price or quantity for calculation. Up to 50 items.
 */
export interface Item {
  name: string;
  quantity: number;
  price: number;
}

/** A split of the purchase amount to an ABA account (`payout`). */
export interface Payout {
  /** ABA account number (`acc`) */
  account: string;
  /** amount paid to it (`amt`) */
  amount: number;
}

/** Deep links back to your app after paying in ABA Mobile (`return_deeplink`). */
export interface ReturnDeeplink {
  iosScheme: string;
  androidScheme: string;
}

/**
 * Request of `purchase`. Only `tranId` and `amount` are required; other
 * fields are sent only when set. Values PayWay wants Base64-encoded (items,
 * return URL, deep link, custom fields, payout, additional params) are given
 * as plain values: the SDK encodes them.
 */
export interface Purchase {
  /** your unique transaction id, max 20 characters */
  tranId: string;
  /** amount to pay, in `currency` */
  amount: number;
  /** item descriptions (up to 50) */
  items?: readonly Item[] | undefined;
  /** shipping fee */
  shipping?: number | undefined;
  firstName?: string | undefined;
  lastName?: string | undefined;
  email?: string | undefined;
  phone?: string | undefined;
  /** `purchase` (default) or `pre-auth` */
  type?: TransactionType | undefined;
  /** payment method; {@link PaymentOption.abapayKhqrDeeplink} for `purchase()` */
  paymentOption?: PaymentOption | undefined;
  /** URL PayWay POSTs the payment result (callback) to; sent Base64-encoded */
  returnUrl?: string | undefined;
  /** where the payer goes after cancelling */
  cancelUrl?: string | undefined;
  /** where the payer goes after a successful payment */
  continueSuccessUrl?: string | undefined;
  /** deep links back to your app after paying in ABA Mobile */
  returnDeeplink?: ReturnDeeplink | undefined;
  /** `USD` (PayWay's default) or `KHR` */
  currency?: Currency | undefined;
  /** shown in transaction list, details and reports */
  customFields?: Record<string, unknown> | undefined;
  /** returned as is in the callback */
  returnParams?: string | undefined;
  /** split of the amount to ABA accounts */
  payout?: readonly Payout[] | undefined;
  /** payment lifetime in minutes (3 minutes to 30 days) */
  lifetime?: number | undefined;
  /** e.g. `wechat_sub_appid`, `wechat_sub_openid` */
  additionalParams?: Record<string, unknown> | undefined;
  /** Google Pay token, when you handle the Google Pay selection */
  googlePayToken?: string | undefined;
  /** skip PayWay's success page */
  skipSuccessPage?: boolean | undefined;
  /** how the hosted page is shown; sent, not hashed */
  viewType?: ViewType | undefined;
  /** set 0 when your profile also has the QR Payment API; sent, not hashed */
  paymentGate?: number | undefined;
}

/** Filters of `transaction-list-2`; every field is optional. */
export interface TransactionListQuery {
  /** sent as `YYYY-MM-DD HH:mm:ss` in local time, as given (no time zone conversion) */
  fromDate?: Date | undefined;
  /** sent as `YYYY-MM-DD HH:mm:ss` in local time, as given (no time zone conversion) */
  toDate?: Date | undefined;
  fromAmount?: number | undefined;
  toAmount?: number | undefined;
  /** statuses to include */
  statuses?: readonly PaymentStatus[] | undefined;
  /** page number */
  page?: number | undefined;
  /** records per page; PayWay's default 40, maximum 1000 */
  pagination?: number | undefined;
}

// ---- responses ------------------------------------------------------------

/**
 * The `status` object of PayWay checkout responses. Codes differ per API;
 * success is `00` (`0` for purchase).
 */
export interface PaywayStatus {
  /** status code, read as a string even when PayWay sends a number */
  code: string;
  /** human readable status message */
  message: string;
  /** transaction id, when PayWay sends one */
  tranId?: string;
  /** PayWay log id for debugging, when PayWay sends one */
  traceId?: string;
}

/** Response of `close-transaction`: a status only. */
export interface StatusResponse {
  status: PaywayStatus;
  /** whether PayWay answered `00` (or `0`) */
  isSuccess: boolean;
}

/**
 * JSON response of `purchase` with `abapay_khqr_deeplink`. Production sends
 * `qrString`, `qrImage`, `app_store`, `play_store`; the sandbox (and the
 * docs) send `qr_string` and `checkout_qr_url`. Both are read.
 */
export interface PurchaseResponse extends StatusResponse {
  /** KHQR string, to render as a QR code */
  qrString?: string;
  /** QR code image, as a data URI */
  qrImage?: string;
  /** opens ABA Mobile to pay */
  abapayDeeplink?: string;
  /** PayWay's hosted QR page */
  checkoutQrUrl?: string;
  /** ABA Mobile in the App Store */
  appStore?: string;
  /** ABA Mobile in Google Play */
  playStore?: string;
}

/** Status of a transaction, from `check-transaction-2`. */
export interface TransactionStatus {
  /** see {@link PaymentStatusCode} */
  paymentStatusCode: number | undefined;
  paymentStatus: string;
  totalAmount: number;
  originalAmount: number;
  refundAmount: number;
  discountAmount: number;
  paymentAmount: number;
  paymentCurrency: string;
  apv: string;
  transactionDate: string;
  /** whether the payment is approved (or pre-authorized) */
  isApproved: boolean;
}

/** Response of `check-transaction-2`. */
export interface CheckTransactionResponse extends StatusResponse {
  data: TransactionStatus | undefined;
  /** whether the call succeeded and the payment is approved (or pre-authorized) */
  isPaid: boolean;
}

/** One operation (payment, refund, ...) of a transaction. */
export interface TransactionOperation {
  status: string;
  amount: number;
  transactionDate: string;
  bankRef: string;
}

/**
 * A transaction, from transaction details and the transaction list.
 * `transactionOperations` is only filled by transaction details.
 */
export interface Transaction {
  transactionId: string;
  /** see {@link PaymentStatusCode} */
  paymentStatusCode: number | undefined;
  paymentStatus: string;
  originalAmount: number;
  originalCurrency: string;
  paymentAmount: number;
  paymentCurrency: string;
  totalAmount: number;
  refundAmount: number;
  discountAmount: number;
  apv: string;
  transactionDate: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  bankRef: string;
  paymentType: string;
  payerAccount: string;
  bankName: string;
  cardSource: string;
  transactionOperations: TransactionOperation[];
  /** whether the payment is approved (or pre-authorized) */
  isApproved: boolean;
}

/** Response of `transaction-detail`. */
export interface TransactionDetailResponse extends StatusResponse {
  data: Transaction | undefined;
}

/** Response of `transaction-list-2`. */
export interface TransactionListResponse extends StatusResponse {
  data: Transaction[];
  page: number | undefined;
  pagination: number | undefined;
}

/** ABA Bank's buy and sell rate of one currency, in riel per unit. */
export interface ExchangeRate {
  sell: number;
  buy: number;
}

/** Response of `exchange-rate`: ABA Bank's latest rates in riel. */
export interface ExchangeRateResponse extends StatusResponse {
  /** by lowercase currency code, e.g. `usd` */
  rates: Record<string, ExchangeRate>;
}

/** Response of `refund`; status codes are `PTL…` for this API. */
export interface RefundResponse extends StatusResponse {
  grandTotal?: number;
  totalRefunded?: number;
  currency?: string;
  transactionStatus?: string;
}

/**
 * The payment result PayWay POSTs (JSON) to your `return_url`. Verify it
 * with `PaywayService.verifyCallback()` before trusting it.
 */
export interface Callback {
  tranId: string;
  apv: string;
  /** `0` on success */
  status: string;
  returnParams: string;
  originalAmount: number;
  originalCurrency: string;
  paymentAmount: number;
  paymentCurrency: string;
  totalAmount: number;
  discountAmount: number;
  transactionDate: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  bankRef: string;
  paymentType: string;
  payerAccount: string;
  bankName: string;
  cardSource: string;
  /** whether the payment succeeded (`status` `0`) */
  isSuccess: boolean;
}

// ---- JSON mapping (PayWay uses snake_case) --------------------------------

/** A decoded JSON object. */
export type Json = Record<string, unknown>;

const isObject = (value: unknown): value is Json =>
  value !== null && typeof value === 'object' && !Array.isArray(value);

/** strings and numbers are read as strings; first present key wins */
const optionalStr = (json: Json, ...keys: string[]): string | undefined => {
  for (const key of keys) {
    const value = json[key];
    if (typeof value === 'string') return value;
    if (typeof value === 'number') return String(value);
  }
  return undefined;
};

const str = (json: Json, key: string): string => optionalStr(json, key) ?? '';

/** numbers and numeric strings, like PHP's `is_numeric` */
const optionalNum = (json: Json, key: string): number | undefined => {
  const value = json[key];
  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : undefined;
  }
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value.trim());
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
};

const num = (json: Json, key: string): number => optionalNum(json, key) ?? 0;

const optionalInt = (json: Json, key: string): number | undefined => {
  const value = optionalNum(json, key);
  return value === undefined ? undefined : Math.trunc(value);
};

const obj = (json: Json, key: string): Json => {
  const value = json[key];
  return isObject(value) ? value : {};
};

const list = (json: Json, key: string): Json[] => {
  const value = json[key];
  const items = Array.isArray(value)
    ? (value as unknown[])
    : isObject(value)
      ? Object.values(value)
      : [];
  return items.filter(isObject);
};

const isSuccessCode = (code: string) => code === '00' || code === '0';

/** @internal */
export function statusFromJson(json: Json): PaywayStatus {
  const status: PaywayStatus = {
    code: str(json, 'code'),
    message: str(json, 'message'),
  };
  const tranId = optionalStr(json, 'tran_id');
  const traceId = optionalStr(json, 'trace_id');
  if (tranId !== undefined) status.tranId = tranId;
  if (traceId !== undefined) status.traceId = traceId;
  return status;
}

/** @internal */
export function statusResponseFromJson(json: Json): StatusResponse {
  const status = statusFromJson(obj(json, 'status'));
  return { status, isSuccess: isSuccessCode(status.code) };
}

/** @internal */
export function purchaseResponseFromJson(json: Json): PurchaseResponse {
  const response: PurchaseResponse = statusResponseFromJson(json);
  const fields = {
    qrString: optionalStr(json, 'qr_string', 'qrString'),
    qrImage: optionalStr(json, 'qr_image', 'qrImage'),
    abapayDeeplink: optionalStr(json, 'abapay_deeplink', 'abapayDeeplink'),
    checkoutQrUrl: optionalStr(json, 'checkout_qr_url', 'checkoutQrUrl'),
    appStore: optionalStr(json, 'app_store', 'appStore'),
    playStore: optionalStr(json, 'play_store', 'playStore'),
  };
  for (const [key, value] of Object.entries(fields)) {
    if (value !== undefined) response[key as keyof typeof fields] = value;
  }
  return response;
}

/** @internal */
export function transactionStatusFromJson(json: Json): TransactionStatus {
  const paymentStatusCode = optionalInt(json, 'payment_status_code');
  return {
    paymentStatusCode,
    paymentStatus: str(json, 'payment_status'),
    totalAmount: num(json, 'total_amount'),
    originalAmount: num(json, 'original_amount'),
    refundAmount: num(json, 'refund_amount'),
    discountAmount: num(json, 'discount_amount'),
    paymentAmount: num(json, 'payment_amount'),
    paymentCurrency: str(json, 'payment_currency'),
    apv: str(json, 'apv'),
    transactionDate: str(json, 'transaction_date'),
    isApproved: paymentStatusCode === PaymentStatusCode.approved,
  };
}

/** @internal */
export function checkTransactionResponseFromJson(
  json: Json,
): CheckTransactionResponse {
  const base = statusResponseFromJson(json);
  const data = isObject(json['data'])
    ? transactionStatusFromJson(json['data'])
    : undefined;
  return {
    ...base,
    data,
    isPaid: base.isSuccess && (data?.isApproved ?? false),
  };
}

/** @internal */
export function transactionFromJson(json: Json): Transaction {
  const paymentStatusCode = optionalInt(json, 'payment_status_code');
  return {
    transactionId: str(json, 'transaction_id'),
    paymentStatusCode,
    paymentStatus: str(json, 'payment_status'),
    originalAmount: num(json, 'original_amount'),
    originalCurrency: str(json, 'original_currency'),
    paymentAmount: num(json, 'payment_amount'),
    paymentCurrency: str(json, 'payment_currency'),
    totalAmount: num(json, 'total_amount'),
    refundAmount: num(json, 'refund_amount'),
    discountAmount: num(json, 'discount_amount'),
    apv: str(json, 'apv'),
    transactionDate: str(json, 'transaction_date'),
    firstName: str(json, 'first_name'),
    lastName: str(json, 'last_name'),
    email: str(json, 'email'),
    phone: str(json, 'phone'),
    bankRef: str(json, 'bank_ref'),
    paymentType: str(json, 'payment_type'),
    payerAccount: str(json, 'payer_account'),
    bankName: str(json, 'bank_name'),
    cardSource: str(json, 'card_source'),
    transactionOperations: list(json, 'transaction_operations').map((op) => ({
      status: str(op, 'status'),
      amount: num(op, 'amount'),
      transactionDate: str(op, 'transaction_date'),
      bankRef: str(op, 'bank_ref'),
    })),
    isApproved: paymentStatusCode === PaymentStatusCode.approved,
  };
}

/** @internal */
export function transactionDetailResponseFromJson(
  json: Json,
): TransactionDetailResponse {
  return {
    ...statusResponseFromJson(json),
    data: isObject(json['data'])
      ? transactionFromJson(json['data'])
      : undefined,
  };
}

/** @internal */
export function transactionListResponseFromJson(
  json: Json,
): TransactionListResponse {
  return {
    ...statusResponseFromJson(json),
    data: list(json, 'data').map(transactionFromJson),
    page: optionalInt(json, 'page'),
    pagination: optionalInt(json, 'pagination'),
  };
}

/**
 * Rates are read from `exchange_rates` and from top-level currency keys, as
 * the documented schema shows both.
 * @internal
 */
export function exchangeRateResponseFromJson(json: Json): ExchangeRateResponse {
  const rates: Record<string, ExchangeRate> = {};
  for (const source of [json, obj(json, 'exchange_rates')]) {
    for (const [key, value] of Object.entries(source)) {
      if (isObject(value) && value['sell'] != null && value['buy'] != null) {
        rates[key.toLowerCase()] = {
          sell: num(value, 'sell'),
          buy: num(value, 'buy'),
        };
      }
    }
  }
  return { ...statusResponseFromJson(json), rates };
}

/** @internal */
export function refundResponseFromJson(json: Json): RefundResponse {
  const response: RefundResponse = statusResponseFromJson(json);
  const grandTotal = optionalNum(json, 'grand_total');
  const totalRefunded = optionalNum(json, 'total_refunded');
  const currency = optionalStr(json, 'currency');
  const transactionStatus = optionalStr(json, 'transaction_status');
  if (grandTotal !== undefined) response.grandTotal = grandTotal;
  if (totalRefunded !== undefined) response.totalRefunded = totalRefunded;
  if (currency !== undefined) response.currency = currency;
  if (transactionStatus !== undefined) {
    response.transactionStatus = transactionStatus;
  }
  return response;
}

/** Maps a decoded callback body (snake_case) to a {@link Callback}. */
export function callbackFromJson(json: Json): Callback {
  const status = str(json, 'status');
  return {
    tranId: str(json, 'tran_id'),
    apv: str(json, 'apv'),
    status,
    returnParams: str(json, 'return_params'),
    originalAmount: num(json, 'original_amount'),
    originalCurrency: str(json, 'original_currency'),
    paymentAmount: num(json, 'payment_amount'),
    paymentCurrency: str(json, 'payment_currency'),
    totalAmount: num(json, 'total_amount'),
    discountAmount: num(json, 'discount_amount'),
    transactionDate: str(json, 'transaction_date'),
    firstName: str(json, 'first_name'),
    lastName: str(json, 'last_name'),
    email: str(json, 'email'),
    phone: str(json, 'phone'),
    bankRef: str(json, 'bank_ref'),
    paymentType: str(json, 'payment_type'),
    payerAccount: str(json, 'payer_account'),
    bankName: str(json, 'bank_name'),
    cardSource: str(json, 'card_source'),
    isSuccess: isSuccessCode(status),
  };
}
