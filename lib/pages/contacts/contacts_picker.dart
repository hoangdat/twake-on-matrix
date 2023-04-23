import 'package:after_layout/after_layout.dart';
import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/contacts_tile.dart';
import 'package:fluffychat/pages/contacts/contacts_view.dart';
import 'package:fluffychat/pages/contacts/di/contact_di.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_local_contact_success.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_network_contact_success.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_local_contacts_interactor.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_network_contacts_interactor.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPicker extends StatefulWidget {
  const ContactsPicker({Key? key}) : super(key: key);

  @override
  State<ContactsPicker> createState() => ContactsController();
}

class ContactsController extends State<ContactsPicker> with AfterLayoutMixin<ContactsPicker> {
  final contactDI = ContactDI();
  late final GetLocalContactsInteractor _getLocalContactsInteractor;
  late final GetNetworkContactsInteractor _getNetworkContactsInteractor;

  late TextEditingController textEditingController;
  List<Contact>? _localContacts;
  List<Contact>? _networkContacts;
  List<ContactsTile>? _contacts;
  final List<Contact> _seletecContacts = [];

  final Permission _permission = Permission.contacts;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  PermissionStatus get  status => _permissionStatus;

  List<Contact>? get localContacts => _localContacts;
  List<ContactsTile>? get allContacts => [
    ContactsTile(contacts: _localContacts ?? [], title: 'Local Contacts', expanded: true),
    ContactsTile(contacts: _networkContacts ?? [], title: 'Server Contacts', expanded: true),
  ];
  List<ContactsTile> get contacts => _contacts!;


  void toggleContacts({required bool isExpanded, required int index}) {
    setState((){
      _contacts![index] = ContactsTile(
        contacts: contacts[index].contacts, 
        title: contacts[index].title, 
        expanded: !isExpanded);
    });
  }

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
    contactDI.bind(onFinishedBind: () {
      _getLocalContactsInteractor = GetIt.instance.get<GetLocalContactsInteractor>();
      _getNetworkContactsInteractor = GetIt.instance.get<GetNetworkContactsInteractor>();
    });

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
      _permissionStatus = status;
    });
  }

  Future<void> requestPermission() async {
    final status = await _permission.request();

    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> requestPermissionInSettings() async {
    if (await _permission.isPermanentlyDenied) {
      final isOpen = await openAppSettings();
      if (isOpen) {
        setState(() {
          _permissionStatus = status;
          _permissionStatus = PermissionStatus.denied;
        });
      }
    }
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _fetchContacts();
  }

  Future _fetchContacts() async {
    if (await Permission.contacts.isGranted) {
      // First load all contacts without photo
      _localContacts = await getLocalContacts();
      _networkContacts = await getNetworkContacts();
      _contacts = [
        ContactsTile(contacts: _localContacts ?? [], title: 'Local Contacts', expanded: true),
        ContactsTile(contacts: _networkContacts ?? [], title: 'Server Contacts', expanded: true),
      ];
      setState(() {});
      
      // Next with photo
      _localContacts = await getLocalContacts(withPhotos: true);
      _networkContacts = await getNetworkContacts(withPhotos: true);
      setState(() {});
    }
  }

  Future<List<Contact>> getLocalContacts({bool withPhotos = false}) async {
    debugPrint('ContactsController: getLocalContacts()');
    return await _getLocalContactsInteractor
      .execute(withThumbnail: withPhotos)
      .then((result) => result.fold(
        (failure) => <Contact>[], 
        (success) => success is GetLocalContactSuccess
          ? success.contacts
          : <Contact>[]
      ));
  }

  Future<List<Contact>> getNetworkContacts({bool withPhotos = false}) async {
    debugPrint('ContactsController: getNetworkContacts()');
    return await _getNetworkContactsInteractor
      .execute(withThumbnail: withPhotos)
      .then((result) => result.fold(
        (failure) => <Contact>[],
        (success) => success is GetNetworkContactSuccess
          ? success.contacts
          : <Contact>[]
      ));
  }

  void onSearchBarChanged() async {
    if (textEditingController.text != '') {
      final searchKeyword = textEditingController.text.toLowerCase();
      setState(() {
        _contacts = allContacts!.map<ContactsTile>((contactsTile) {
          return ContactsTile(
            contacts: contactsTile.contacts.where(
              (contact) => contact.email.toLowerCase().contains(searchKeyword)
                || contact.displayName.toLowerCase().contains(searchKeyword))
              .toList(),
            title: contactsTile.title,
          );
        }).toList();
      });
    } else {
      setState(() {
        _contacts = allContacts;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) => ContactsView(this);

  @override
  void dispose() async {
    super.dispose();
    textEditingController.dispose();
    await contactDI.unbind();
  }
}