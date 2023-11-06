export "http_client_adapter_none.dart"
    if (dart.library.io) "http_client_adapter_io.dart"
    if (dart.library.html) "http_client_adapter_web.dart";

