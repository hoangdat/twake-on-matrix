import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/data/datasource/contact_data_source.dart';

class TomClientDataSource extends ContactDataSource {
  @override
  Future<List<Contact>> getContacts({withThumbnail = false}) {
    return Future.value([
      Contact(email: 'qkdo@linagora.com', displayName: 'Quang Khai'),
      Contact(email: 'quangkhai@gmail.com', displayName: 'Quang Khai'),
      Contact(email: 'qk123@gmail.com', displayName: 'Quang Khai'),
      Contact(email: 'superman@linagora.com', displayName: 'bro whatup'),
      Contact(email: 'supersonic@gmail.com', displayName: 'sonic'),
    ]);
  }
}