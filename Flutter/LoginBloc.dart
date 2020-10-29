import 'dart:async';

import 'LoginValidator.dart';
import 'package:rxdart/rxdart.dart';

import 'ErrorGen.dart';

class LoginBloc extends Object with LoginValidator implements BaseLoginBloc {
  final _emailController = BehaviorSubject<ErrorGen>();
  final _passwordController = BehaviorSubject<ErrorGen>();

  Stream<String> get email => _emailController.stream.transform(emailValidator);
  Stream<String> get password =>
      _passwordController.stream.transform(passwordValidator);

  Stream<bool> get submitCheck =>
      Rx.combineLatest2(email, password, (e, p) => true);

  Function(ErrorGen) get emailChanged => _emailController.sink.add;

  Function(ErrorGen) get passwordChanged => _passwordController.sink.add;

  @override
  void dispose() {
    _emailController?.close();
    _passwordController?.close();
  }
}

abstract class BaseLoginBloc {
  void dispose();
}
