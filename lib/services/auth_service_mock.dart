import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

class MockUser extends Mock implements User {
  @override
  String get uid => 'mock_uid';
  @override
  String? get email => 'mock@example.com';
  @override
  String? get displayName => 'Mock User';
  @override
  String? get photoURL => 'https://example.com/mock_photo.jpg';
}

class MockUserCredential extends Mock implements UserCredential {
  @override
  User get user => MockUser();
}

class AuthServiceMock {
  Future<UserCredential?> signInWithGoogle() async {
    return MockUserCredential();
  }

  Future<void> signOut() async {
    // Do nothing
  }
}
