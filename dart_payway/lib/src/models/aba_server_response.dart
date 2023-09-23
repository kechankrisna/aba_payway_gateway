class ABAServerResponse {
  int? status;
  String? description;
  String? qrString;
  String? qrImage;
  String? abapayDeeplink;
  String? appStore;
  String? playStore;
  String? rawcontent;

  ABAServerResponse({
    this.status,
    this.description,
    this.qrString,
    this.qrImage,
    this.abapayDeeplink,
    this.appStore,
    this.playStore,
    this.rawcontent,
  });

  factory ABAServerResponse.fromMap(Map<String, dynamic> map) {
    int _statusCode = -1;
    if (map["status"] is int) {
      _statusCode = map["status"];
    }
    if (map["status"] is Map) {
      _statusCode = int.tryParse("${map["status"]["code"]}")!;
    }
    return ABAServerResponse(
      status: _statusCode,
      description: map["description"],
      qrString: map["qrString"],
      qrImage: map["qrImage"],
      abapayDeeplink: map["abapay_deeplink"],
      appStore: map["app_store"],
      playStore: map["play_store"],
      rawcontent: null,
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
        "rawcontent": rawcontent,
      };
}
