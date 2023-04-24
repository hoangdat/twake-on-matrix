import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/domain/model/presentation_contact.dart';

extension ListContactException on List<Contact> {
  List<PresentationContact> toPresentationContacts() {
    final List<PresentationContact> results = [];
    for (final contact in this) {
      for (final email in contact.emails) {
        results.add(PresentationContact(displayName: contact.displayName, email: email));
      }
    }
    return results;
  }
}