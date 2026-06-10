import 'dart:io';

class CustomHttpOverrides extends HttpOverrides {
  static init() {
    HttpOverrides.global = CustomHttpOverrides();
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
