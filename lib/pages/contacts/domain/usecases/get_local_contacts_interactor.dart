import 'package:either_dart/either.dart';
import 'package:fluffychat/pages/contacts/domain/repository/local_contact_repository.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_local_contact_failed.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_local_contact_success.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_contact_extension.dart';
import 'package:fluffychat/state/failure.dart';
import 'package:fluffychat/state/success.dart';

class GetLocalContactsInteractor {
  final LocalContactRepository localContactRepository;

  GetLocalContactsInteractor({required this.localContactRepository});

  Future<Either<Failure, Success>> execute({withThumbnail = false}) async {
    try {
      final contacts = await localContactRepository.getContacts(withThumbnail: withThumbnail);
      return Right(GetLocalContactSuccess(contacts: contacts.toPresentationContacts()));
    } catch(e) {
      return Left(GetLocalContactFailed(exception: e));
    }
  }
}