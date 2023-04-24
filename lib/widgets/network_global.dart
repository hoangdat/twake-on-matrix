import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';

class NetworkGlobal extends StatefulWidget {

  final Widget child;

  const NetworkGlobal({
    Key? key,
    required this.child
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NetworkGlobalState();

}

class _NetworkGlobalState extends State<NetworkGlobal> {

  @override
  void initState() {
    super.initState();
    if (mounted) {
      NetworkDI(context).bind();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('accessToken: ${Matrix.of(context).client.accessToken}');
    return widget.child;
  }

  @override
  void dispose() async {
    super.dispose();
    await NetworkDI(context).unbind();
  }

}