import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user_model.dart';

// Repository xử lý Firebase Auth/Firestore để UI không gọi Firebase trực tiếp.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  );
});

class AuthRepository {
  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  CollectionReference<Map<String, dynamic>> get _usersRef {
    return _firestore.collection('users');
  }

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  bool get canChangePassword {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    return user.providerData.any((info) => info.providerId == 'password');
  }

  Future<AppUserModel?> getCurrentUserProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    final profile = await getUserProfileByUid(firebaseUser.uid);
    if (profile != null) return profile;

    return _createDefaultProfile(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Learner',
      email: firebaseUser.email ?? '',
      avatarUrl: firebaseUser.photoURL,
    );
  }

  Future<AppUserModel?> getUserProfileByUid(String uid) async {
    final doc = await _usersRef.doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return AppUserModel.fromFirestore(doc);
  }

  Future<AppUserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Không tạo được tài khoản.');
      }

      await firebaseUser.updateDisplayName(name.trim());

      final appUser = await _createDefaultProfile(
        uid: firebaseUser.uid,
        name: name.trim(),
        email: email.trim(),
        avatarUrl: firebaseUser.photoURL,
      );

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (_) {
      throw Exception('Có lỗi xảy ra, vui lòng thử lại.');
    }
  }

  Future<AppUserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Không đăng nhập được.');
      }

      final profile = await getUserProfileByUid(firebaseUser.uid);

      if (profile != null) {
        return profile;
      }

      final fallbackProfile = await _createDefaultProfile(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Learner',
        email: firebaseUser.email ?? email.trim(),
        avatarUrl: firebaseUser.photoURL,
      );

      return fallbackProfile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (_) {
      throw Exception('Có lỗi xảy ra, vui lòng thử lại.');
    }
  }

  Future<AppUserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Bạn đã hủy đăng nhập Google.');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Không đăng nhập Google được.');
      }

      final oldProfile = await getUserProfileByUid(firebaseUser.uid);

      if (oldProfile != null) {
        return oldProfile;
      }

      final appUser = await _createDefaultProfile(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? googleUser.displayName ?? 'Learner',
        email: firebaseUser.email ?? googleUser.email,
        avatarUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
      );

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.setLanguageCode('vi');
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return;
      }

      throw Exception(_mapPasswordResetError(e));
    } catch (_) {
      throw Exception('Có lỗi xảy ra, vui lòng thử lại.');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;

    if (user == null || email == null || email.trim().isEmpty) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (!canChangePassword) {
      throw Exception(
        'Tài khoản Google không đổi mật khẩu trong app. Vui lòng quản lý mật khẩu bằng Google.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapChangePasswordError(e));
    } catch (_) {
      throw Exception('Không thể đổi mật khẩu, vui lòng thử lại.');
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

      if (name != null) {
        data['name'] = name.trim();
      }

      if (avatarUrl != null) {
        data['avatarUrl'] = avatarUrl.trim().isEmpty ? null : avatarUrl.trim();
      }

      await _usersRef.doc(uid).set(data, SetOptions(merge: true));

      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser != null && firebaseUser.uid == uid) {
        if (name != null) {
          await firebaseUser.updateDisplayName(name.trim());
        }

        if (avatarUrl != null) {
          await firebaseUser.updatePhotoURL(
            avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } catch (_) {
      throw Exception('Không thể cập nhật hồ sơ.');
    }
  }

  Future<AppUserModel> _createDefaultProfile({
    required String uid,
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final now = DateTime.now();
    final profile = AppUserModel(
      uid: uid,
      name: name.trim().isEmpty ? 'Learner' : name.trim(),
      email: email.trim(),
      avatarUrl: avatarUrl,
      createdAt: now,
      updatedAt: now,
      streak: 0,
      onlineMinutesToday: 0,
      lastActiveDate: now.toIso8601String().substring(0, 10),
    );

    await _usersRef
        .doc(uid)
        .set(profile.toFirestore(), SetOptions(merge: true));

    return profile;
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email hoặc mật khẩu không đúng.';
      case 'network-request-failed':
        return 'Không có kết nối mạng.';
      case 'too-many-requests':
        return 'Bạn thử quá nhiều lần, vui lòng thử lại sau.';
      default:
        return 'Có lỗi xảy ra, vui lòng thử lại.';
    }
  }

  String _mapPasswordResetError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'network-request-failed':
        return 'Không có kết nối mạng';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều, vui lòng thử lại sau';
      default:
        return 'Không thể gửi email đặt lại mật khẩu, vui lòng thử lại.';
    }
  }

  String _mapChangePasswordError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mật khẩu hiện tại không đúng';
      case 'weak-password':
        return 'Mật khẩu mới quá yếu';
      case 'requires-recent-login':
        return 'Vui lòng nhập lại mật khẩu hiện tại';
      case 'network-request-failed':
        return 'Không có kết nối mạng';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều, vui lòng thử lại sau';
      default:
        return 'Không thể đổi mật khẩu, vui lòng thử lại.';
    }
  }
}
