import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixmate/services/google_auth_service.dart';

@GenerateMocks([
  FirebaseAuth,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  UserCredential,
  User,
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import 'google_auth_service_test.mocks.dart';

void main() {
  group('GoogleAuthService White Box Tests - WT002', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockFirebaseFirestore mockFirestore;
    late GoogleAuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockFirestore = MockFirebaseFirestore();
      authService = GoogleAuthService();
    });

    group('signInWithGoogle() - All Execution Paths', () {
      test('BRANCH 1: Successful sign-in path - complete flow', () async {
        // Arrange - Setup mocks for SUCCESS path
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.email).thenReturn('test@example.com');
        when(mockGoogleUser.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('test_access_token');
        when(mockGoogleAuth.idToken).thenReturn('test_id_token');
        when(mockAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test_uid');
        when(mockUser.email).thenReturn('test@example.com');

        // Act - Execute SUCCESS branch
        final result = await authService.signInWithGoogle();

        // Assert - Verify complete success flow
        expect(result, isNotNull);
        expect(result, isA<UserCredential>());
        verify(mockGoogleSignIn.signIn()).called(1);
        verify(mockGoogleUser.authentication).called(1);
        verify(mockAuth.signInWithCredential(any)).called(1);
      });

      test('BRANCH 2: User cancels sign-in - null return path', () async {
        // Arrange - Setup for CANCELLATION path
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // Act - Execute CANCELLATION branch
        final result = await authService.signInWithGoogle();

        // Assert - Verify null return path executed
        expect(result, isNull);
        verify(mockGoogleSignIn.signIn()).called(1);
        // Verify no Firebase sign-in was attempted (proves branch logic)
        verifyNever(mockAuth.signInWithCredential(any));
      });

      test('BRANCH 3: FirebaseAuthException - error handling path', () async {
        // Arrange - Setup for ERROR path
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleInAuthentication();

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.email).thenReturn('test@example.com');
        when(mockGoogleUser.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('token');
        when(mockGoogleAuth.idToken).thenReturn('token');
        when(mockAuth.signInWithCredential(any))
            .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        // Act & Assert - Execute ERROR handling branch
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<FirebaseAuthException>()),
        );
        verify(mockGoogleSignIn.signIn()).called(1);
      });

      test('BRANCH 4: Generic exception - catch-all error path', () async {
        // Arrange - Setup for GENERIC ERROR path
        when(mockGoogleSignIn.signIn()).thenThrow(Exception('Network error'));

        // Act & Assert - Execute generic catch block
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
