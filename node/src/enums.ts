// PayWay's enumerated values, as `const` objects with a union type of the
// same name: `PaymentOption.cards` and the string `'cards'` are both valid.

/** Payment method of a purchase (`payment_option`). */
export const PaymentOption = {
  /** card payment */
  cards: 'cards',
  /** QR code payable with ABA PAY and other KHQR member banks */
  abapayKhqr: 'abapay_khqr',
  /** ABA PAY / KHQR for apps: purchase answers with JSON (QR string, deep link) */
  abapayKhqrDeeplink: 'abapay_khqr_deeplink',
  /** Alipay wallet */
  alipay: 'alipay',
  /** WeChat Pay wallet */
  wechat: 'wechat',
  /** Google Pay wallet; needs a `googlePayToken` when you handle the selection */
  googlePay: 'google_pay',
} as const;
/** Payment method of a purchase (`payment_option`). */
export type PaymentOption = (typeof PaymentOption)[keyof typeof PaymentOption];

/** Currency of a purchase. */
export const Currency = {
  /** US dollar */
  usd: 'USD',
  /** Cambodian riel */
  khr: 'KHR',
} as const;
/** Currency of a purchase. */
export type Currency = (typeof Currency)[keyof typeof Currency];

/** Type of a purchase (`type`). */
export const TransactionType = {
  /** full purchase (PayWay's default) */
  purchase: 'purchase',
  /** pre-authorization hold, captured later; ABA PAY, KHQR and cards only */
  preAuth: 'pre-auth',
} as const;
/** Type of a purchase (`type`). */
export type TransactionType =
  (typeof TransactionType)[keyof typeof TransactionType];

/** How the hosted payment page is shown (`view_type`). */
export const ViewType = {
  /** redirect the payer to a new tab */
  hostedView: 'hosted_view',
  /** bottom sheet on mobile browsers, modal popup on desktop browsers */
  popup: 'popup',
} as const;
/** How the hosted payment page is shown (`view_type`). */
export type ViewType = (typeof ViewType)[keyof typeof ViewType];

/** Transaction status filter of the transaction list (`status`). */
export const PaymentStatus = {
  /** paid with the full purchase amount */
  approved: 'APPROVED',
  /** funds held by a pre-authorization, pending capture */
  preAuth: 'PRE-AUTH',
  /** fully or partially refunded */
  refunded: 'REFUNDED',
  /** awaiting payment by the payer */
  pending: 'PENDING',
  /** declined (spelled as in PayWay's API) */
  declined: 'DECLINDED',
  /** cancelled */
  cancelled: 'CANCELLED',
} as const;
/** Transaction status filter of the transaction list (`status`). */
export type PaymentStatus = (typeof PaymentStatus)[keyof typeof PaymentStatus];

/** `payment_status_code` values of transaction status, details and list. */
export const PaymentStatusCode = {
  /** `0` APPROVED or PRE-AUTH */
  approved: 0,
  /** `2` PENDING */
  pending: 2,
  /** `3` DECLINED */
  declined: 3,
  /** `4` REFUNDED */
  refunded: 4,
  /** `7` CANCELLED */
  cancelled: 7,
} as const;
/** `payment_status_code` values of transaction status, details and list. */
export type PaymentStatusCode =
  (typeof PaymentStatusCode)[keyof typeof PaymentStatusCode];

/**
 * Success codes of the response `status`: `00` for most APIs, `0` for
 * purchase. Other codes are business errors and differ per API (refunds
 * use `PTL…` codes).
 */
export const PaywayStatusCode = {
  /** `00` success */
  success: '00',
  /** `0` success of purchase */
  purchaseSuccess: '0',
} as const;
