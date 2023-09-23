enum ABAPaymentOption { cards, abapay, abapay_deeplink, bakong, alipay, wechat }

const $ABAPaymentOptionMap = const {
  "cards": ABAPaymentOption.cards,
  "abapay": ABAPaymentOption.abapay,
  "abapay_deeplink": ABAPaymentOption.abapay_deeplink,
  "bakong": ABAPaymentOption.bakong,
  "alipay": ABAPaymentOption.alipay,
  "wechat": ABAPaymentOption.wechat,
};

/// acceptable currency
enum ABATransactionCurrency { USD, KHR }

const $ABATransactionCurrencyMap = {
  'USD': ABATransactionCurrency.USD,
  'KHR': ABATransactionCurrency.KHR,
};

/// transaction type
enum ABATransactionType { purchase, refund }

const $ABATransactionTypeMap = {
  'purchase': ABATransactionType.purchase,
  'refund': ABATransactionType.refund,
};
