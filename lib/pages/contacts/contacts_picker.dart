import 'package:after_layout/after_layout.dart';
import 'package:fluffychat/pages/contacts/contacts_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:contacts_service/contacts_service.dart' as contacts_service;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPicker extends StatefulWidget {
  const ContactsPicker({Key? key}) : super(key: key);

  @override
  State<ContactsPicker> createState() => ContactsController();
}

class ContactsController extends State<ContactsPicker> with AfterLayoutMixin<ContactsPicker> {
  late TextEditingController textEditingController;
  List<Contact>? _contacts;
  final List<Contact> _seletecContacts = [];
  late List<Contact>? _allContacts;

  final Permission _permission = Permission.contacts;
  PermissionStatus _permissioStatus = PermissionStatus.denied;

  PermissionStatus get status => _permissioStatus;

  List<Contact>? get contacts => _contacts;

  List<Contact> get selectedContact => _seletecContacts;

  void pickContact(Contact contact) {
    setState(() {
      _seletecContacts.add(contact);
    });
  }

  void removeContact(Contact contact) {
    if (_seletecContacts.contains(contact)) {
      setState(() {
        _seletecContacts.remove(contact);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _listenForPermissionStatus();
    textEditingController = TextEditingController();
    textEditingController.addListener(() {
      final String text = textEditingController.text;
      onSearchBarChanged();
    });
  }

  void _listenForPermissionStatus() async {
    final status = await _permission.status;
    setState(() {
      _permissioStatus = status;
    });
  }

  Future<void> requestPermission() async {
    final status = await _permission.request();

    setState(() {
      _permissioStatus = status;
    });
  }

  Future<void> requestPermissionInSettings() async {
    if (await _permission.isPermanentlyDenied) {
      final isOpen = await openAppSettings();
      if (isOpen) {
        setState(() {
          _permissioStatus = status;
          _permissioStatus = PermissionStatus.denied;
        });
      }
    }
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _fetchContacts();
  }

  Future _fetchContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      setState(() {
        _contacts = null;
      });
      return;
    }

    await _refetchContacts();
    // Listen to DB changes
    FlutterContacts.addListener(() async {
      await _refetchContacts();
    });
    _allContacts = contacts;
  }

  Future _refetchContacts() async {
    // First load all contacts without photo
    await _loadContacts(withPhotos: false);
    // Next with photo
    await _loadContacts(withPhotos: true);

  }

  Future _loadContacts({bool withPhotos = false}) async {
    final contacts = withPhotos
        ? (await FlutterContacts.getContacts(withThumbnail: true)).toList()
        : (await FlutterContacts.getContacts()).toList();
    setState(() {
      _contacts = contacts;
    });
  }

  void onSearchBarChanged() async {
    if (textEditingController.text != '') {
      final contacts = await contacts_service.ContactsService.getContacts(query: textEditingController.text);
      setState(() {
        _contacts = contacts
          .map<Contact>((contact) => Contact(
            id: contact.identifier ?? '',
            displayName: contact.displayName ?? '',
            phones: contact.phones
              ?.map<Phone>((item) => Phone(item.value ?? ''))
              .toList(),
            emails: contact.emails
              ?.map<Email>((item) => Email(item.label ?? ''))
              .toList()
          ))
          .toList();
      });
    } else {
      setState(() {
        _contacts = _allContacts;  
      });
    }
  }
  
  @override
  Widget build(BuildContext context) => ContactsView(this);
}