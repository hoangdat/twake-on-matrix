import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/domain/repository/contacts_repository.dart';
import 'package:flutter/material.dart';

class FindContactsInteractor {
  // final ContactsRepository _repository;
  var dat = 32;
  FindContactsInteractor();

  Future<List<Contact>> call(String query) async {
    debugPrint("FindContactsInteractor: $query = $dat");
    dat+=10;
    debugPrint("FindContactsInteractor: AFTER $query = $dat");
    throw UnimplementedError();
  }
}