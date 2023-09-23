class PaywayCreateTransactionResponse {
  final int status;
  final String description;
  final String? qrString;
  final String? qrImage;
  final String? abapayDeeplink;
  final String? appStore;
  final String? playStore;

  PaywayCreateTransactionResponse({
    this.status = -1,
    this.description = 'Unknown Error',
    this.qrString,
    this.qrImage,
    this.abapayDeeplink,
    this.appStore,
    this.playStore,
  });

  factory PaywayCreateTransactionResponse.fromMap(Map<String, dynamic> map) {
    int _statusCode = -1;
    if (map["status"] is int) {
      _statusCode = map["status"];
    }
    if (map["status"] is Map) {
      _statusCode = int.tryParse("${map["status"]["code"]}")!;
    }
    return PaywayCreateTransactionResponse(
      status: _statusCode,
      description: map["description"],
      qrString: map["qrString"],
      qrImage: map["qrImage"],
      abapayDeeplink: map["abapay_deeplink"],
      appStore: map["app_store"],
      playStore: map["play_store"],
    );
  }
  Map<String, dynamic> toMap() => {
        "status": status,
        "description": description,
        "qrString": qrString,
        "qrImage": qrImage,
        "abapay_deeplink": abapayDeeplink,
        "app_store": appStore,
        "play_store": playStore,
      };

  String get message =>
      PaywayCreateTransactionResponseMessage.of(status).message;

  PaywayCreateTransactionResponse copyWith({
    int? status,
    String? description,
    String? qrString,
    String? qrImage,
    String? abapayDeeplink,
    String? appStore,
    String? playStore,
  }) {
    return PaywayCreateTransactionResponse(
      status: status ?? this.status,
      description: description ?? this.description,
      qrString: qrString ?? this.qrString,
      qrImage: qrImage ?? this.qrImage,
      abapayDeeplink: abapayDeeplink ?? this.abapayDeeplink,
      appStore: appStore ?? this.appStore,
      playStore: playStore ?? this.playStore,
    );
  }

  @override
  String toString() {
    return 'PaywayCreateTransactionResponse(status: $status, description: $description, qrString: $qrString, qrImage: $qrImage, abapayDeeplink: $abapayDeeplink, appStore: $appStore, playStore: $playStore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaywayCreateTransactionResponse &&
        other.status == status &&
        other.description == description &&
        other.qrString == qrString &&
        other.qrImage == qrImage &&
        other.abapayDeeplink == abapayDeeplink &&
        other.appStore == appStore &&
        other.playStore == playStore;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        description.hashCode ^
        qrString.hashCode ^
        qrImage.hashCode ^
        abapayDeeplink.hashCode ^
        appStore.hashCode ^
        playStore.hashCode;
  }
}

class PaywayCreateTransactionResponseMessage {
  int value;

  PaywayCreateTransactionResponseMessage._(this.value);

  factory PaywayCreateTransactionResponseMessage.of(int value) =>
      PaywayCreateTransactionResponseMessage._(value);

  String get message {
    switch (value) {
      case 0:
        return "Success!";
      case 1:
        return "Invalid Hash, Hash generated is incorrect and not following the guideline to generate the Hash.";
      case 2:
        return "Invalid Transaction ID, unsupported characters included in Transaction ID";
      case 3:
        return "Invalid Amount format need not include decimal point for KHR transaction. example for USD 100.00 for KHR 100";
      case 4:
        return "Duplicate Transaction ID, the transaction ID already exists in PayWay, generate new transaction.";
      case 5:
        return "Invalid Continue Success URL, (Domain must be registered in PayWay backend to use success URL)";
      case 6:
        return "Invalid Domain Name (Request originated from non-whitelisted domain need to register domain in PayWay backend)";
      case 7:
        return "Invalid Return Param (String must be lesser than 500 chars)";
      case 8:
        return "-";
      case 9:
        return "Invalid Limit Amount (The amount must be smaller than value that allowed in PayWay backend)";
      case 10:
        return "Invalid Shipping Amount";
      case 11:
        return "PayWay Server Side Error";
      case 12:
        return "Invalid Currency Type (Merchant is allowed only one currency - USD or KHR)";
      case 13:
        return "Invalid Item, value for items parameters not following the guideline to generate the base64 encoded array of item list.";
      case 14:
        return "-";
      case 15:
        return "Invalid Channel Values for parameter topup_channel";
      case 16:
        return "Invalid First Name - unsupported special characters included in value";
      case 17:
        return "Invalid Last Name";
      case 18:
        return "Invalid Phone Number";
      case 19:
        return "Invalid Email Address";
      case 20:
        return "Required purchase details when checkout";
      case 21:
        return "Expired production key";
      default:
    }
    return "Unknown Error!";
  }
}
