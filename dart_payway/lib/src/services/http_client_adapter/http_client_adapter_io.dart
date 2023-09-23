import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class PlatformHttpClientAdapter {
  HttpClientAdapter clientAdapter() {
    return IOHttpClientAdapter(
      createHttpClient: () {
        // Don't trust any certificate just because their root cert is trusted.
        final client =
            HttpClient(context: SecurityContext(withTrustedRoots: false));
        // You can test the intermediate / root cert here. We just ignore it.
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
      validateCertificate: (cert, host, port) {
        // Check that the cert fingerprint matches the one we expect.
        // We definitely require _some_ certificate.
        if (cert == null) {
          return false;
        }

        /// by pass the cert if not null
        return true;
      },
    );
  }
}
