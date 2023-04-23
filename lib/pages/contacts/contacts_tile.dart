import 'package:equatable/equatable.dart';
import 'package:fluffychat/entity/contact/contact.dart';

class ContactsTile extends Equatable {

  final bool expanded;

  final List<Contact> contacts;

  final String title;

  const ContactsTile({
    required this.contacts,
    this.expanded = true,
    required this.title,
  });

  @override
  List<Object?> get props => [contacts, expanded, title];

  @override
  String toString() {
    return 'contacts: $contacts, expanded: $expanded';
  }
}