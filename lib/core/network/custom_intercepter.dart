
import 'package:dio/dio.dart';
import 'logger.dart';

class CustomInterceptor extends Interceptor {
  const CustomInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    info('''
------------------------------------------------------------
        === Request (${options.method}) ===
        === Url: ${options.uri} ===
        === Headers: ${options.headers} ===
        === Data: ${options.data}
------------------------------------------------------------''');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    info('''
------------------------------------------------------------
=== Response (${response.statusCode}) ===
=== Url: ${response.realUri} ===
=== Method (${response.requestOptions.method}) ===
=== Data: ${response.data}
------------------------------------------------------------''');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    final req = err.requestOptions;
    final uri = res?.realUri ?? req.uri;
    final status = res?.statusCode?.toString() ?? err.type.name;
    info('''
------------------------------------------------------------
=== Error ($status) ===
=== Url: $uri ===
=== Method (${req.method}) ===
=== Message: ${err.message} ===
=== Data: ${res?.data ?? err.error}
------------------------------------------------------------''');
    super.onError(err, handler);
  }
}
