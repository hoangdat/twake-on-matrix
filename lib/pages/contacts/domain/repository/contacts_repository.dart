import 'package:fluffychat/entity/contact/contact.dart';

abstract class ContactsRepository {
  Future<List<Contact>> findContacts(String query);

  Future<List<Contact>> getAvailableContacts();
}