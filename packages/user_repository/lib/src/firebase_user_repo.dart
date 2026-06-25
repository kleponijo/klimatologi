import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:user_repository/user_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  @override
  Future<void> logOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
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
<<<<<<< Updated upstream
  Future<void> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('cancelled');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      // FIX: Cek apakah user sudah punya data Firestore
      // Jika belum (user baru), buat dokumen sekarang juga
      final firebaseUser = userCredential.user!;
      final doc = await userCollection.doc(firebaseUser.uid).get();

      if (!doc.exists) {
        final newUser = MyUser(
          userId: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          hasActiveCart: false,
        );
        await setUserData(newUser);
      }
    } catch (e) {
      log('Google sign-in error: $e');
=======
  Future<bool> signInWithGoogle() async {
    print("GOOGLE FUNCTION CALLED");
    try {
      print("STEP 1");

      final googleUser = await _googleSignIn.signIn();

      print("STEP 2");
      print(googleUser);
      print("GOOGLE USER = $googleUser");

      if (googleUser == null) {
        print("USER CANCEL");
        return false;
      }

      print("STEP 3");

      final googleAuth = await googleUser.authentication;

      print("STEP 4");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("STEP 5");

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      print("STEP 6");

      print(userCredential.user?.email);
      return true;
    } catch (e, stack) {
      print("ERROR = $e");
      print("STACK = $stack");
>>>>>>> Stashed changes
      rethrow;
    }
  }
}
