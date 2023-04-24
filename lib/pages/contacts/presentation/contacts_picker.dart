import 'package:after_layout/after_layout.dart';
import 'package:fluffychat/pages/contacts/domain/model/presentation_contact.dart';
import 'package:fluffychat/pages/contacts/di/contact_di.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_local_contact_success.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_network_contact_success.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_local_contacts_interactor.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_network_contacts_interactor.dart';
import 'package:fluffychat/pages/contacts/presentation/contacts_tile.dart';
import 'package:fluffychat/pages/contacts/presentation/contacts_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
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

  List<PresentationContact>? _localContacts;
  List<PresentationContact>? _networkContacts;
  List<ContactsTile>? _contacts;
  final List<PresentationContact> _seletecContacts = [];

  final Permission _permission = Permission.contacts;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  PermissionStatus get  status => _permissionStatus;

  List<PresentationContact>? get localContacts => _localContacts;
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

  List<PresentationContact> get selectedContact => _seletecContacts;

  void pickContact(PresentationContact contact) {
    setState(() {
      _seletecContacts.add(contact);
    });
  }

  void removeContact(PresentationContact contact) {
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

  void _fetchLocalContacts() async {
    if (await Permission.contacts.isGranted) {
      _localContacts = await getLocalContacts();
      setState(() {});

      _localContacts = await getLocalContacts(withPhotos: true);
      setState(() {});
    }
  }

  void _fetchNetworkContacts() async {
    _networkContacts = await getNetworkContacts();
    setState(() {});

    _networkContacts = await getNetworkContacts(withPhotos: true);
    setState(() {});
  }

  Future<List<PresentationContact>> getLocalContacts({bool withPhotos = false}) async {
    debugPrint('ContactsController: getLocalContacts()');
    return await _getLocalContactsInteractor
      .execute(withThumbnail: withPhotos)
      .then((result) => result.fold(
        (failure) => <PresentationContact>[], 
        (success) => success is GetLocalContactSuccess
          ? success.contacts
          : <PresentationContact>[]
      ));
  }

  Future<List<PresentationContact>> getNetworkContacts({bool withPhotos = false}) async {
    debugPrint('ContactsController: getNetworkContacts()');
    return await _getNetworkContactsInteractor
      .execute(withThumbnail: withPhotos)
      .then((result) => result.fold(
        (failure) => <PresentationContact>[],
        (success) => success is GetNetworkContactSuccess
          ? success.contacts
          : <PresentationContact>[]
      ));
  }

  void onSearchBarChanged(String searchKeyword) async {
    if (searchKeyword != '') {
      final searchKeywordLower = searchKeyword.toLowerCase();
      setState(() {
        _contacts = allContacts!.map<ContactsTile>((contactsTile) {
          return ContactsTile(
            contacts: contactsTile.contacts
              .where((contact) 
                => contact.email.toLowerCase().contains(searchKeywordLower)
                || contact.displayName.toLowerCase().contains(searchKeywordLower))
              .toList(),
            title: contactsTile.title,
            expanded: true,
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
  void afterFirstLayout(BuildContext context) {
    _fetchLocalContacts();
    _fetchNetworkContacts();
    _contacts = [
      ContactsTile(contacts: _localContacts ?? [], title: 'Local Contacts', expanded: true),
      ContactsTile(contacts: _networkContacts ?? [], title: 'Server Contacts', expanded: true),
    ];
  }
  
  @override
  Widget build(BuildContext context) => ContactsView(this);

  @override
  void dispose() async {
    super.dispose();
    await contactDI.unbind();
  }
}