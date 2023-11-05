// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dart_payway/dart_payway.dart';

class PaywayClientFormRequestService {
  late PaywayMerchant merchant;
  PaywayClientFormRequestService({
    required this.merchant,
  });

  /// [generateCreateTransactionFormData]
  ///
  /// allow to pre generate the correct data for form submit when send create request transaction
  ///
  generateCreateTransactionFormData(PaywayCreateTransaction transaction) {
    var encodedReturnUrl = EncoderService.base64_encode(transaction.returnUrl);

    var encodedItem = EncoderService.base64_encode(
        transaction.items.map((e) => e.toMap()).toList());

    var service = PaywayClientService(merchant);
    final str = service.getStr(
      reqTime: transaction.reqTime.toString(),
      tranId: transaction.tranId.toString(),
      amount: transaction.amount.toString(),
      items: encodedItem.toString(),
      shipping: transaction.shipping.toString(),
      firstName: transaction.firstname.toString(),
      lastName: transaction.lastname.toString(),
      email: transaction.email.toString(),
      phone: transaction.phone.toString(),
      type: transaction.type.name.toString(),
      paymentOption: transaction.option.name.toString(),
      currency: transaction.currency.name.toString(),
      returnUrl: encodedReturnUrl.toString(),
    );
    var hash = service.getHash(str);

    var map = {
      "merchant_id": merchant.merchantID.toString(),
      "req_time": transaction.reqTime.toString(),
      "tran_id": transaction.tranId.toString(),
      "amount": transaction.amount.toString(),
      "items": encodedItem.toString(),
      "hash": hash.toString(),
      "firstname": transaction.firstname.toString(),
      "lastname": transaction.lastname.toString(),
      "phone": transaction.phone.toString(),
      "email": transaction.email.toString(),
      "return_url": encodedReturnUrl.toString(),
      "continue_success_url": transaction.continueSuccessUrl ?? "",
      "return_params": transaction.returnParams ?? "",
      "shipping": transaction.shipping.toString(),
      "type": transaction.type.name,
      "payment_option": transaction.option.name,
      "currency": transaction.currency.name,
    };
    return map;
  }

  /// [generateCheckTransactionFormData]
  ///
  /// allow to pre generate the correct data for form submit when send check request transaction
  ///
  generateCheckTransactionFormData(PaywayCheckTransaction transaction) {
    final service = PaywayClientService(merchant);
    final str = service.getStr(
      reqTime: transaction.reqTime.toString(),
      tranId: transaction.tranId.toString(),
      amount: "",
      items: "",
      shipping: "",
      firstName: "",
      lastName: "",
      email: "",
      phone: "",
      type: "",
      paymentOption: "",
      currency: "",
      returnUrl: "",
    );
    final hash = service.getHash(str);
    
    var map = {
      "merchant_id": "${merchant.merchantID}",
      "req_time": transaction.reqTime,
      "tran_id": transaction.tranId,
      "hash": hash,
    };
    return map;
  }
}
