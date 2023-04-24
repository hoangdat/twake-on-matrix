import 'package:fluffychat/pages/contacts/domain/model/presentation_contact.dart';
import 'package:fluffychat/state/success.dart';

class GetNetworkContactSuccess extends Success {

  final List<PresentationContact> contacts;

  const GetNetworkContactSuccess({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}