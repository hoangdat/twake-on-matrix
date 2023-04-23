import 'package:equatable/equatable.dart';

class Contact extends Equatable {

  final String email;

  final String displayName;

  const Contact({
    required this.email,
    required this.displayName
  });
  
  @override
  List<Object?> get props => [email, displayName];
}