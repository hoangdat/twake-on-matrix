import 'package:fluffychat/entity/contact/contact.dart';

abstract class ContactRepository {
  Future<List<Contact>> getContacts({withThumbnail = false});
}