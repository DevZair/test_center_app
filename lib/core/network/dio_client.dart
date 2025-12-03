import 'package:dio/dio.dart';

import 'custom_intercepter.dart';

class DioClient {
  DioClient({String baseUrl = 'https://kazutb.jahongir.asia'})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          responseType: ResponseType.json,
        ),
      ) {
    dio.interceptors.clear();
    dio.interceptors.add(const CustomInterceptor());
  }

  final Dio dio;
}
