import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/contacts_picker.dart';
import 'package:fluffychat/pages/contacts/contacts_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';
import 'package:permission_handler/permission_handler.dart';


class ContactsView extends StatelessWidget {

  final ContactsController contactsController;

  const ContactsView(
    this.contactsController,
    {Key? key}
  ): super(key: key);

  @override
  Widget build(BuildContext context) {
    late final Widget contactView;
    if (contactsController.status == PermissionStatus.permanentlyDenied) {
      contactView = Center(
        child: TextButton(
          child: const Text("Open settings to allow permission"),
          onPressed: () async {
            await contactsController.requestPermissionInSettings();
          },
        ),);
    } else if (contactsController.status == PermissionStatus.denied) {
      contactsController.requestPermission();
      contactView = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (contactsController.status == PermissionStatus.granted) {
      if (contactsController.localContacts == null || contactsController.localContacts!.isEmpty) {
        contactView = const Center(child: Text('No contacts'));
      } else {
        contactView = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            ExpansionPanelList(
              elevation: 0,
              expansionCallback:(panelIndex, isExpanded) {
                contactsController.toggleContacts(
                  isExpanded : isExpanded,
                  index: panelIndex
                );
              },
              children: contactsController.contacts.map<ExpansionPanel>(
                (ContactsTile contacts) {
                  return ExpansionPanel(
                    isExpanded: contacts.expanded,
                    canTapOnHeader: true,
                    headerBuilder: (context, isExpanded) {
                      return Text(contacts.title, style: TextStyle(fontWeight: FontWeight.bold));
                    },
                    body: ListView.builder(
                      shrinkWrap: true,
                      itemCount: contacts.contacts.length,
                      itemBuilder: (context, index) =>  _buildListTile(contacts.contacts[index]))
                    );
                }
              ).toList(),
            ),
          ],
        );
      }
    } else {
      contactView = const Center(child: Text('Not support permission'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: SingleChildScrollView(
        child: contactView,
      ));
  }

  Widget _buildSearchBar() {
    return TextFormField(
      controller: contactsController.textEditingController,
      decoration: InputDecoration(
        hintText: 'Search'
      ),
      onEditingComplete: () => contactsController.onSearchBarChanged,
    );
  }

  Widget _buildListTile(Contact contact) {
    return CheckboxListTile(
      value: contactsController.selectedContact.contains(contact),
      title: Row(
        children: [
          RoundAvatar(
            text: contact.displayName,
          ),
          const SizedBox(width: 5.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contact.displayName),
              Text(contact.email, style: TextStyle(fontSize: 14),),
            ],
          ),
        ],
      ),
      selected: contactsController.selectedContact.contains(contact), 
      onChanged: (bool? value) {
        if (value != null) {
          if (value) {
            contactsController.pickContact(contact);
          } else {
            contactsController.removeContact(contact);
          }
        }
      },
    );
  }
}