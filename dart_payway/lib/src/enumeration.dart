enum PaywayPaymentOption {
  cards,
  abapay,
  abapay_deeplink,
  abapay_khqr_deeplink,
  bakong,
  alipay,
  wechat
}

const $PaywayPaymentOptionMap = {
  "cards": PaywayPaymentOption.cards,
  "abapay": PaywayPaymentOption.abapay,
  "abapay_deeplink": PaywayPaymentOption.abapay_deeplink,
  "abapay_khqr_deeplink": PaywayPaymentOption.abapay_khqr_deeplink,
  "bakong": PaywayPaymentOption.bakong,
  "alipay": PaywayPaymentOption.alipay,
  "wechat": PaywayPaymentOption.wechat,
};

/// acceptable currency
enum PaywayTransactionCurrency { USD, KHR }

const $PaywayTransactionCurrencyMap = {
  'USD': PaywayTransactionCurrency.USD,
  'KHR': PaywayTransactionCurrency.KHR,
};

/// transaction type
enum PaywayTransactionType { purchase, refund }

const $PaywayTransactionTypeMap = {
  'purchase': PaywayTransactionType.purchase,
  'refund': PaywayTransactionType.refund,
};
