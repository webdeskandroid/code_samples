import 'dart:async';

import 'ErrorGen.dart';

mixin LoginValidator {
  var emailValidator = StreamTransformer<ErrorGen, String>.fromHandlers(
      handleData: (errorGen, sink) {
    var email = errorGen.value;
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp exp = new RegExp(pattern);
    if (errorGen.isError) {
      sink.addError(errorGen.value);
    } else if (!exp.hasMatch(email)) {
      sink.addError("Invalid Email");
    } else {
      sink.add(email);
    }
  });

  var passwordValidator = StreamTransformer<ErrorGen, String>.fromHandlers(
      handleData: (errorGen, sink) {
    var password = errorGen.value;
    if (errorGen.isError) {
      sink.addError(errorGen.value);
    } else if (password.length > 5) {
      sink.add(password);
    } else {
      sink.addError("Password length > 4");
    }
  });

  var emailErrorValidator = StreamTransformer<String, String>.fromHandlers(
      handleData: (errorMessage, sink) {
    sink.addError(errorMessage);
  });
}
