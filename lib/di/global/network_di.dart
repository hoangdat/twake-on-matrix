import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/network/dio_client.dart';
import 'package:fluffychat/network/interceptor/authorization_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class NetworkDI extends BaseDI {
  final BuildContext context;

  NetworkDI(this.context);

  static const acceptHeaderDefault = 'application/json';
  static const contentTypeHeaderDefault = 'application/json';

  @override
  void setUp(GetIt get) {
    _bindBaseOption(get);
    _bindDio(get);
    _bindDioClient(get);
  }

  void _bindBaseOption(GetIt get) {
    final headers = <String, dynamic>{
      HttpHeaders.acceptHeader: acceptHeaderDefault,
      HttpHeaders.contentTypeHeader: contentTypeHeaderDefault
    };

    get.registerLazySingleton<BaseOptions>(() => BaseOptions(headers: headers));
  }

  void _bindDio(GetIt get) {
    final dio = Dio(get.get<BaseOptions>());
    dio.interceptors.add(AuthorizationInterceptor(context));
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
    get.registerLazySingleton<Dio>(() => dio);
  }

  void _bindDioClient(GetIt get) {
    get.registerLazySingleton(() => DioClient(get.get<Dio>()));
  }

  @override
  String get scopeName => 'networkScope';
}