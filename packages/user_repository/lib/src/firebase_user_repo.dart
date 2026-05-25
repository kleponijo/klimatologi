import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:user_repository/user_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseUserRepo implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  final _googleSignIn = GoogleSignIn();
  final userCollection = FirebaseFirestore.instance.collection('users');

  FirebaseUserRepo({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<MyUser?> get user {
    return _firebaseAuth.authStateChanges().flatMap((firebaseUser) async* {
      if (firebaseUser == null) {
        yield MyUser.empty;
      } else {
        try {
          final userData = await userCollection.doc(firebaseUser.uid).get();
          if (userData.exists && userData.data() != null) {
            yield MyUser.fromEntity(
                MyUserEntity.fromDocument(userData.data()!));
          } else {
            // Data Firestore belum ada (seharusnya tidak terjadi dengan flow yang sudah diperbaiki)
            yield MyUser(
              userId: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: firebaseUser.displayName ?? '',
              hasActiveCart: false,
            );
          }
        } catch (e) {
          log('Error fetching user data: $e');
          yield MyUser.empty;
        }
      }
    });
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<MyUser> signUp(MyUser myUser, String password) async {
    try {
      UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
              email: myUser.email, password: password);
      final newUser = MyUser(
        userId: credential.user!.uid,
        email: myUser.email,
        name: myUser.name,
        hasActiveCart: false,
      );
      await setUserData(newUser);
      return newUser;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> logOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> setUserData(MyUser myUser) async {
    try {
      await userCollection
          .doc(myUser.userId)
          .set(myUser.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // user cancel

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final doc = await userCollection.doc(firebaseUser.uid).get();
      if (!doc.exists) {
        // User baru via Google — buat doc Firestore
        final myUser = MyUser(
          userId: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          hasActiveCart: false,
        );
        await setUserData(myUser);
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
