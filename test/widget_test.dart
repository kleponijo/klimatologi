// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import 'package:user_repository/user_repository.dart';
import '../lib/app.dart';

// import 'package:klimatologiot/main.dart';

class FakeUserRepository implements UserRepository {
  @override
  Stream<MyUser?> get user => const Stream.empty();

  @override
  Future<void> logOut() async {}

  @override
  Future<void> setUserData(MyUser user) {
    // TODO: implement setUserData
    throw UnimplementedError();
  }

  @override
  Future<void> signIn(String email, String password) {
    // TODO: implement signIn
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithGoogle() {
    // TODO: implement signInWithGoogle
    throw UnimplementedError();
  }

  @override
  Future<MyUser> signUp(MyUser myUser, String password) {
    // TODO: implement signUp
    throw UnimplementedError();
  }

  // tambahin kalau ada method lain
}

class FakeMonitoringRepository implements MonitoringRepository {
  get _db => null;

  // Satu fungsi untuk semua jenis sensor
  // Kamu cukup masukkan "path" database-nya saja

  @override
  // Jika ingin mengambil data sekali saja (bukan stream)
  Future<DataSnapshot> getSensorSnapshot(String path) async {
    return await _db.ref(path).get();
  }

  @override
  Stream<DatabaseEvent> getSensorStream(String path) {
    // TODO: implement getSensorStream
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    final fakeRepo = FakeUserRepository();
    final fakeMonitoring = FakeUserRepository();
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(fakeRepo, fakeMonitoring as MonitoringRepository),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
