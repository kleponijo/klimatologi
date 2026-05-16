import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:user_repository/user_repository.dart';
// Google Sign-In import di-disable sementara karena error analisis:
// "Target of URI doesn't exist: package:google_sign_in/google_sign_in.dart".
// Implementasi Google Sign-In (kecuali untuk web auth) akan dilewatkan.
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseUserRepo implements UserRepository {

  final FirebaseAuth _firebaseAuth;
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
            yield MyUser.empty;
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
      UserCredential user = await _firebaseAuth.createUserWithEmailAndPassword(
          email: myUser.email, password: password);
      myUser.userId = user.user!.uid;
      return myUser;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // NOTE: Google Sign-In disabled because dependency import fails on this workspace.
  // After google_sign_in issue resolved, restore the implementation.

  @override

  Future<void> logOut() async {
    // GoogleSignIn sementara di-skip karena error analisis import.
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
    // Google Sign-In sementara dimatikan agar build tidak gagal.
    // Setelah dependency google_sign_in benar-benar resolvable, bagian ini bisa dikembalikan.
    throw UnimplementedError('Google Sign-In disabled (analysis fix)');
  }

}
