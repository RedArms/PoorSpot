import '../models/user_model.dart';

class CurrentSession {
  static final CurrentSession _instance = CurrentSession._internal();
  
  factory CurrentSession() {
    return _instance;
  }
  
  CurrentSession._internal();

  User? user;

  bool get isLoggedIn => user != null;
}