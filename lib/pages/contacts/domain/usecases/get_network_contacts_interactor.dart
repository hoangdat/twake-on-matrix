import 'package:either_dart/either.dart';
import 'package:fluffychat/pages/contacts/domain/repository/network_contact_repository.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_network_contact_failed.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_network_contact_success.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_contact_extension.dart';
import 'package:fluffychat/state/failure.dart';
import 'package:fluffychat/state/success.dart';

class GetNetworkContactsInteractor {
  final NetworkContactRepository networkContactRepository;

  GetNetworkContactsInteractor({required this.networkContactRepository});

  Future<Either<Failure, Success>> execute({withThumbnail = false}) async {
    try {
      final contacts = await networkContactRepository.getContacts(withThumbnail: withThumbnail);
      return Right(GetNetworkContactSuccess(contacts: contacts.toPresentationContacts()));
    } catch (e) {
      return Left(GetNetworkContactFailed(exception: e));
    }
  }
}