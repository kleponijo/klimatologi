import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:user_repository/user_repository.dart';

class FirebaseUserRepo implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  final userCollection = FirebaseFirestore.instance.collection('users');

  FirebaseUserRepo({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<MyUser?> get user {
    return _firebaseAuth.authStateChanges().flatMap((firebaseUser) async* {
      if (firebaseUser == null) {
        yield MyUser.empty;
      } else {
        try {
          final userData = await userCollection.doc(firebaseUser.uid).get();
          if (userData.exists && userData.data() != null) {
            yield MyUser.fromEntity(MyUserEntity.fromDocument(userData.data()!));
          } else {
            // User baru yang belum ada data di Firestore, tunggu sebentar
            await Future.delayed(const Duration(milliseconds: 500));
            final retryData = await userCollection.doc(firebaseUser.uid).get();
            if (retryData.exists && retryData.data() != null) {
              yield MyUser.fromEntity(MyUserEntity.fromDocument(retryData.data()!));
            } else {
              yield MyUser.empty;
            }
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
        email: email,
        password: password
      );
    } catch (e) {
     log(e.toString());
      rethrow;
    }
  }

  @override
  Future<MyUser> signUp(MyUser myUser, String password) async {
   try {
      UserCredential user = await _firebaseAuth.createUserWithEmailAndPassword(
          email: myUser.email,
          password: password
        );
       myUser.userId = user.user!.uid;
       return myUser;
    } catch (e) {
      log(e.toString());
      rethrow;
   }
  }

  @override
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> setUserData(MyUser myUser) async {
    try {
      await userCollection
      .doc(myUser.userId)
      .set(myUser.toEntity().toDocument());
      // Tunggu sebentar agar data tersimpan dengan baik sebelum stream update
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }



}