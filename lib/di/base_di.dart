import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';

typedef OnFinishedBind = void Function();

abstract class BaseDI {
  void bind({OnFinishedBind? onFinishedBind}) {
    GetIt.instance.pushNewScope(
      init: setUp,
      scopeName: scopeName,
    );
    onFinishedBind?.call();
  }

  String get scopeName;

  void setUp(GetIt get);

  Future<void> unbind() async {
    debugPrint("Unbinding $scopeName");
    await GetIt.instance.popScope();
    debugPrint("finished unbinding $scopeName");
  }
}