import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

bool kIsWeb = true;

class PlatformHttpClientAdapter {
  HttpClientAdapter clientAdapter() {
    return BrowserHttpClientAdapter();
  }
}
