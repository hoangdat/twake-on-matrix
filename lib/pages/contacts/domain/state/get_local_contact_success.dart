import 'package:fluffychat/pages/contacts/domain/model/presentation_contact.dart';
import 'package:fluffychat/state/success.dart';

class GetLocalContactSuccess extends Success {

  final List<PresentationContact> contacts;

  const GetLocalContactSuccess({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}