import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/pages/contacts/data/datasource/contact_data_source.dart';
import 'package:fluffychat/pages/contacts/data/datasource/device_contact_data_source.dart';
import 'package:fluffychat/pages/contacts/data/datasource/tomclient_data_source.dart';
import 'package:fluffychat/pages/contacts/data/repository/local_contact_repository_impl.dart';
import 'package:fluffychat/pages/contacts/data/repository/network_contact_repository_impl.dart';
import 'package:fluffychat/pages/contacts/domain/repository/local_contact_repository.dart';
import 'package:fluffychat/pages/contacts/domain/repository/network_contact_repository.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_local_contacts_interactor.dart';
import 'package:fluffychat/pages/contacts/domain/usecases/get_network_contacts_interactor.dart';
import 'package:get_it/get_it.dart';

class ContactDI extends BaseDI {

  @override
  String get scopeName => 'Contacts';

  @override
  void setUp(GetIt get) {
    get.registerSingleton<DeviceContactDataSource>(DeviceContactDataSource());
    get.registerSingleton<TomClientDataSource>(TomClientDataSource());
    
    get.registerSingleton<LocalContactRepository>(
      LocalContactRepositoryImpl(datasources: {
        LocalDataSourceType.device: GetIt.instance.get<DeviceContactDataSource>()
      }));
    get.registerSingleton<NetworkContactRepository>(
      NetworkContactRepositoryImpl(datasources: {
        NetworkDataSourceType.tomclient: GetIt.instance.get<TomClientDataSource>()
      }));
    
    get.registerFactory(() => GetLocalContactsInteractor(
      localContactRepository: GetIt.instance.get<LocalContactRepository>()));
    get.registerFactory(() => GetNetworkContactsInteractor(
      networkContactRepository: GetIt.instance.get<NetworkContactRepository>()));
  }

}