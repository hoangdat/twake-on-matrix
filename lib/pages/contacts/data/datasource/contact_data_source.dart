import 'package:fluffychat/entity/contact/contact.dart';

abstract class ContactDataSource {
  Future<List<Contact>> getContacts({withThumbnail = false});
}

enum LocalDataSourceType {
  device,
}

enum NetworkDataSourceType {
  tomclient,
}