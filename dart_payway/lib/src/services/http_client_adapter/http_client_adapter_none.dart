import 'package:dio/dio.dart';

bool kIsWeb = false;

class PlatformHttpClientAdapter {
  HttpClientAdapter clientAdapter() {
    return HttpClientAdapter();
  }
}