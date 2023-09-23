import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

class PlatformHttpClientAdapter {
  HttpClientAdapter clientAdapter() {
    return BrowserHttpClientAdapter();
  }
}
