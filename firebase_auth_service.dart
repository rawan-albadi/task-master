import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  static User? get currentUser => FirebaseAuth.instance.currentUser;
}
