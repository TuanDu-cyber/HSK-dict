import 'package:firebase_auth/firebase_auth.dart';

class UserStorageKeyHelper {
  UserStorageKeyHelper._();

  static String get _prefix {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();

    if (uid != null && uid.isNotEmpty) {
      return uid;
    }

    return 'guest';
  }

  static String key(String suffix) {
    return '${_prefix}_$suffix';
  }
}
