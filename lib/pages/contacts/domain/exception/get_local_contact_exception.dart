import 'package:equatable/equatable.dart';

class GetLocalContactException extends Equatable implements Exception {

  final String message;

  const GetLocalContactException({required this.message});

  @override
  List<Object?> get props => [message];

}