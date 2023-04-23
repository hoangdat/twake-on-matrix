import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/state/success.dart';

class GetLocalContactSuccess extends Success {

  final List<Contact> contacts;

  const GetLocalContactSuccess({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}