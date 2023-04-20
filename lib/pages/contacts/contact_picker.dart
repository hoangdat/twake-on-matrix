import 'package:after_layout/after_layout.dart';
import 'package:fluffychat/pages/contacts/contact_picker_view.dart';
import 'package:fluffychat/pages/contacts/di/contact_di.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/find_contacts_interactor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPicker extends StatefulWidget {
  const ContactPicker({Key? key}) : super(key: key);

  @override
  State<ContactPicker> createState() => ContactsController();
}

class ContactsController extends State<ContactPicker> with AfterLayoutMixin<ContactPicker> {
  final contactDI = ContactsDI();
  List<Contact>? _contacts;
  final List<Contact> _pickedContacts = [];
  final Permission _permission = Permission.contacts;
  PermissionStatus _permissioStatus = PermissionStatus.denied;
  late FindContactsInteractor _findContactsInteractor;

  PermissionStatus get status => _permissioStatus;

  List<Contact>? get contacts => _contacts;

  List<Contact> get pickedContact => _pickedContacts;

  void pickContact(Contact contact) {
    setState(() {
      _pickedContacts.add(contact);
    });
  }

  void removeContact(Contact contact) {
    if (_pickedContacts.contains(contact)) {
      setState(() {
        _pickedContacts.remove(contact);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    contactDI.bind(onFinishedBind: () {
      _findContactsInteractor = GetIt.instance.get<FindContactsInteractor>();
    },);
    _listenForPermissionStatus();
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
    debugPrint("requestPermissionInSettings(): requesting...");
    if (await _permission.isPermanentlyDenied) {
      final isOpen = await openAppSettings();
      if (isOpen) {
        setState(() {
          _permissioStatus = status;
          _permissioStatus = PermissionStatus.denied;
        });
      }
    }
    debugPrint("requestPermissionInSettings(): requestes done.");
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _fetchContacts();
    _findContactsInteractor.call("hello dat");
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
  }

  Future _refetchContacts() async {
    // First load all contacts without photo
    await _loadContacts(false);
    // Next with photo
    await _loadContacts(true);

  }

  Future _loadContacts(bool withPhotos) async {
    final contacts = withPhotos
        ? (await FlutterContacts.getContacts(withThumbnail: true)).toList()
        : (await FlutterContacts.getContacts()).toList();
    setState(() {
      _contacts = contacts;
    });
    debugPrint('$contacts');
  }
  
  @override
  Widget build(BuildContext context) => ContactPickerView(this);

  @override
  void dispose() async {
    debugPrint("dispose");
    await contactDI.unbind();
    debugPrint("dispose:: unbind done");
    super.dispose();
  }
}