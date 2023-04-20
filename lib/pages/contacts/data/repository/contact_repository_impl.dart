import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/domain/repository/contacts_repository.dart';
import 'package:get_it/get_it.dart';

class ContactRepositoryImpl implements ContactsRepository {

  ContactRepositoryImpl();

  @override
  Future<List<Contact>> findContacts(String query) {
    // TODO: implement findContacts
    throw UnimplementedError();
  }

  @override
  Future<List<Contact>> getAvailableContacts() {
    // TODO: implement findContacts
    throw UnimplementedError();
  }

}