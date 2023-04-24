import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/data/datasource/contact_data_source.dart';

class TomClientDataSource extends ContactDataSource {
  @override
  Future<List<Contact>> getContacts({withThumbnail = false}) {
    return Future.value([
      Contact(emails: ['qkdo@linagora.com', 'quangkhai@gmail.com', 'qk123@gmail.com'], displayName: 'Quang Khai'),
      Contact(emails: ['superman@linagora.com'], displayName: 'bro whatup'),
      Contact(emails: ['supersonic@gmail.com'], displayName: 'sonic'),
    ]);
  }
}