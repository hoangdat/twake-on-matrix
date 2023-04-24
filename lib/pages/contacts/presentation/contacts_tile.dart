import 'package:equatable/equatable.dart';
import 'package:fluffychat/pages/contacts/domain/model/presentation_contact.dart';

class ContactsTile extends Equatable {

  final String title;

  final List<PresentationContact> contacts;

  final bool expanded;

  const ContactsTile({
    required this.title,
    required this.contacts,
    this.expanded = true,
  });

  @override
  List<Object?> get props => [contacts, expanded, title];

  @override
  String toString() {
    return 'contacts: $contacts, expanded: $expanded';
  }
}