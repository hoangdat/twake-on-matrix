import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/state/success.dart';

class GetNetworkContactSuccess extends Success {

  final List<Contact> contacts;

  const GetNetworkContactSuccess({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}