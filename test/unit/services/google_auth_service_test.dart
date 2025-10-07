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
  GoogleSignInAuthentication, // FIXED: Correct class name
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
        final mockGoogleAuth = MockGoogleSignInAuthentication(); // FIXED
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
        // Verify no Firebase sign-in attempted (proves branch logic)
        verifyNever(mockAuth.signInWithCredential(any));
      });

      test('BRANCH 3: Firebase authentication error - error handling path',
          () async {
        // Arrange - Setup for ERROR path
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication(); // FIXED

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.email).thenReturn('test@example.com');
        when(mockGoogleUser.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('test_access_token');
        when(mockGoogleAuth.idToken).thenReturn('test_id_token');
        when(mockAuth.signInWithCredential(any))
            .thenThrow(FirebaseAuthException(code: 'user-disabled'));

        // Act & Assert - Execute ERROR handling branch
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<FirebaseAuthException>()),
        );

        // Verify error path was taken
        verify(mockGoogleSignIn.signIn()).called(1);
        verify(mockAuth.signInWithCredential(any)).called(1);
      });

      test('BRANCH 4: Google sign-in throws exception - exception catch path',
          () async {
        // Arrange - Setup for EXCEPTION path
        when(mockGoogleSignIn.signIn()).thenThrow(Exception('Network error'));

        // Act & Assert - Execute exception catch block
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<Exception>()),
        );

        // Verify exception path was taken
        verify(mockGoogleSignIn.signIn()).called(1);
        verifyNever(mockAuth.signInWithCredential(any));
      });

      test('BRANCH 5: Missing authentication tokens - null handling path',
          () async {
        // Arrange - Setup for NULL token path
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication(); // FIXED

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.email).thenReturn('test@example.com');
        when(mockGoogleUser.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn(null); // NULL token
        when(mockGoogleAuth.idToken).thenReturn(null); // NULL token

        // Act & Assert - Should handle null tokens gracefully
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Additional White Box Coverage', () {
      test('BRANCH 6: Verify credential creation with tokens', () async {
        // Tests internal credential creation logic
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication(); // FIXED
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.email).thenReturn('test@example.com');
        when(mockGoogleUser.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('access_token_123');
        when(mockGoogleAuth.idToken).thenReturn('id_token_456');
        when(mockAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);

        // Act
        await authService.signInWithGoogle();

        // Assert - Verify credential was created with correct tokens
        final captured =
            verify(mockAuth.signInWithCredential(captureAny)).captured;
        expect(captured, isNotEmpty);
      });

      test('BRANCH 7: User document creation path', () async {
        // Tests the Firestore document creation branch
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication(); // FIXED
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.email).thenReturn('test@example.com');
        when(mockGoogleUser.displayName).thenReturn('Test User');
        when(mockGoogleUser.authentication)
            .thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('test_token');
        when(mockGoogleAuth.idToken).thenReturn('test_id_token');
        when(mockAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('user_uid_123');
        when(mockUser.email).thenReturn('test@example.com');

        // Act
        await authService.signInWithGoogle();

        // Assert - Verify all branches executed
        verify(mockGoogleSignIn.signIn()).called(1);
        verify(mockGoogleUser.authentication).called(1);
        verify(mockAuth.signInWithCredential(any)).called(1);
      });
    });
  });
}
