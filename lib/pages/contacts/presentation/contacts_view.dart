import 'package:fluffychat/pages/contacts/domain/model/presentation_contact.dart';
import 'package:fluffychat/pages/contacts/presentation/contacts_picker.dart';
import 'package:fluffychat/pages/contacts/presentation/widget/search_bar.dart';
import 'package:flutter/material.dart';
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
        contactView = CustomScrollView(
          shrinkWrap: true,
          slivers: [
            SliverAppBar(
              leading: const SizedBox.shrink(),
              leadingWidth: 0,
              centerTitle: true,
              pinned: true,
              title: SearchBar(onSearchBarChanged: (String searchKeyword) {
                return contactsController.onSearchBarChanged(searchKeyword);
              },),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final contactsList = contactsController.contacts[index];
                return ExpansionTile(
                  title: Text(contactsList.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  children: contactsList.contacts
                    .map<Widget>((contact) => _buildListTile(contact))
                    .toList(),
                );
              },
              childCount: 2,),
            )
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

  Widget _buildListTile(PresentationContact contact) {
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