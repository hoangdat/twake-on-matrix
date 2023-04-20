import 'package:fluffychat/pages/contacts/contact_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPickerView extends StatelessWidget {

  final ContactsController contactsController;

  const ContactPickerView(
    this.contactsController,
    {Key? key}
  ): super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget contactView;
    debugPrint('Contact status: ${contactsController.status}');
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
      if (contactsController.contacts == null || contactsController.contacts!.isEmpty) {
        contactView = const Center(child: Text('No contacts'));
      } else {

        contactView = Container(
          height: 400,
          child: ListView.builder(
            itemCount: contactsController.contacts!.length,
            itemBuilder: (context, index) {
              final contact = contactsController.contacts![index];
              return CheckboxListTile(
                value: contactsController.pickedContact.contains(contact),
                title: Row(
                  children: [
                    RoundAvatar(
                      text: contact.displayName,
                      imageProvider: contact.photo != null ? MemoryImage(contact.photo!) : null,
                    ),
                    Text(contact.displayName),
                  ],
                ),
                selected: contactsController.pickedContact.contains(contact), 
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
            },
          ),
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
}