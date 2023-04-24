import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';

class AuthorizationInterceptor extends InterceptorsWrapper {
  final BuildContext buildContext;

  AuthorizationInterceptor(this.buildContext);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[HttpHeaders.authorizationHeader] = Matrix.of(buildContext).client.accessToken;
    debugPrint('accessToken: ${Matrix.of(buildContext).client.accessToken}');
    super.onRequest(options, handler);
  }
}