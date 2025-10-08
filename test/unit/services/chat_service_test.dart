// test/unit/services/chat_service_test.dart
// WT020 - Chat Service White Box Test

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fixmate/services/chat_service.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseStorage,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  Reference,
  UploadTask,
  TaskSnapshot,
  XFile,
])
import 'chat_service_test.mocks.dart';

void main() {
  group('WT020 - ChatService.sendMessage() Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseStorage mockStorage;
    late MockCollectionReference mockChatCollection;
    late MockCollectionReference mockMessagesCollection;
    late MockDocumentReference mockChatDoc;
    late MockDocumentReference mockMessageDoc;
    late MockDocumentSnapshot mockChatSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      mockChatCollection = MockCollectionReference();
      mockMessagesCollection = MockCollectionReference();
      mockChatDoc = MockDocumentReference();
      mockMessageDoc = MockDocumentReference();
      mockChatSnapshot = MockDocumentSnapshot();

      // Setup basic mock chain
      when(mockFirestore.collection('chats')).thenReturn(mockChatCollection);
      when(mockChatCollection.doc(any)).thenReturn(mockChatDoc);
      when(mockChatDoc.get()).thenAnswer((_) async => mockChatSnapshot);
      when(mockChatDoc.collection('messages'))
          .thenReturn(mockMessagesCollection);
      when(mockMessagesCollection.doc()).thenReturn(mockMessageDoc);
      when(mockMessageDoc.set(any)).thenAnswer((_) async => Future.value());
      when(mockChatDoc.update(any)).thenAnswer((_) async => Future.value());
    });

    group('Text Message Tests', () {
      test('BRANCH 1: Text-only message path', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);
        Map<String, dynamic> capturedMessageData = {};
        when(mockMessageDoc.set(any)).thenAnswer((invocation) {
          capturedMessageData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await ChatService.sendMessage(
          firestore: mockFirestore,
          chatId: 'CH_789',
          senderId: 'USER_001',
          text: 'Hello, when can you start?',
          type: 'text',
        );

        // Assert
        expect(
            capturedMessageData['text'], equals('Hello, when can you start?'));
        expect(capturedMessageData['senderId'], equals('USER_001'));
        expect(capturedMessageData['type'], equals('text'));
        expect(capturedMessageData['read'], equals(false));
        expect(capturedMessageData['timestamp'], isNotNull);
        verify(mockMessageDoc.set(any)).called(1);
      });

      test('BRANCH 2: Empty text validation path', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);

        // Act & Assert
        expect(
          () async => await ChatService.sendMessage(
            firestore: mockFirestore,
            chatId: 'CH_789',
            senderId: 'USER_001',
            text: '', // EMPTY TEXT
            type: 'text',
          ),
          throwsA(predicate((e) =>
              e is ArgumentError &&
              e.message.contains('Message text cannot be empty'))),
        );
      });
    });

    group('Image Message Tests', () {
      test('BRANCH 3: Image message with upload path', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);

        MockXFile mockImageFile = MockXFile();
        MockReference mockStorageRef = MockReference();
        MockUploadTask mockUploadTask = MockUploadTask();
        MockTaskSnapshot mockTaskSnapshot = MockTaskSnapshot();

        when(mockImageFile.path).thenReturn('/test/image.jpg');
        when(mockImageFile.readAsBytes())
            .thenAnswer((_) async => [1, 2, 3, 4, 5]);

        when(mockStorage.ref()).thenReturn(mockStorageRef);
        when(mockStorageRef.child(any)).thenReturn(mockStorageRef);
        when(mockStorageRef.putData(any)).thenReturn(mockUploadTask);
        when(mockUploadTask.snapshot).thenReturn(mockTaskSnapshot);
        when(mockUploadTask.then(any))
            .thenAnswer((_) async => mockTaskSnapshot);
        when(mockStorageRef.getDownloadURL())
            .thenAnswer((_) async => 'https://storage.example.com/image.jpg');

        Map<String, dynamic> capturedMessageData = {};
        when(mockMessageDoc.set(any)).thenAnswer((invocation) {
          capturedMessageData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await ChatService.sendMessage(
          firestore: mockFirestore,
          storage: mockStorage,
          chatId: 'CH_789',
          senderId: 'USER_001',
          text: 'Check this issue',
          type: 'image',
          imageFile: mockImageFile,
        );

        // Assert
        expect(capturedMessageData['type'], equals('image'));
        expect(capturedMessageData['text'], equals('Check this issue'));
        expect(capturedMessageData['imageUrl'], isNotNull);
        verify(mockStorageRef.putData(any)).called(1);
        verify(mockStorageRef.getDownloadURL()).called(1);
      });

      test('BRANCH 4: Image message without file error path', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);

        // Act & Assert
        expect(
          () async => await ChatService.sendMessage(
            firestore: mockFirestore,
            chatId: 'CH_789',
            senderId: 'USER_001',
            text: 'Image message',
            type: 'image',
            imageFile: null, // NO IMAGE FILE
          ),
          throwsA(predicate((e) =>
              e is ArgumentError &&
              e.message.contains('Image file required for image messages'))),
        );
      });
    });

    group('Chat Existence Tests', () {
      test('BRANCH 5: Chat exists path', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);
        when(mockMessageDoc.set(any)).thenAnswer((_) async => Future.value());

        // Act
        await ChatService.sendMessage(
          firestore: mockFirestore,
          chatId: 'CH_EXISTING',
          senderId: 'USER_001',
          text: 'Test message',
          type: 'text',
        );

        // Assert
        verify(mockChatDoc.get()).called(1);
        verify(mockMessageDoc.set(any)).called(1);
        // Should NOT create new chat
        verifyNever(mockChatDoc.set(any));
      });

      test('BRANCH 6: Chat does not exist - create new chat path', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(false);
        when(mockChatDoc.set(any)).thenAnswer((_) async => Future.value());
        when(mockMessageDoc.set(any)).thenAnswer((_) async => Future.value());

        Map<String, dynamic> capturedChatData = {};
        when(mockChatDoc.set(any)).thenAnswer((invocation) {
          capturedChatData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await ChatService.sendMessage(
          firestore: mockFirestore,
          chatId: 'CH_NEW',
          senderId: 'USER_001',
          text: 'First message',
          type: 'text',
          participants: ['USER_001', 'USER_002'],
        );

        // Assert
        verify(mockChatDoc.get()).called(1);
        verify(mockChatDoc.set(any)).called(1); // Chat created
        verify(mockMessageDoc.set(any)).called(1); // Message created
        expect(
            capturedChatData['participants'], equals(['USER_001', 'USER_002']));
        expect(capturedChatData['createdAt'], isNotNull);
      });
    });

    group('Read Receipt Tests', () {
      test('BRANCH 7: Read receipt initialization path', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);

        Map<String, dynamic> capturedMessageData = {};
        when(mockMessageDoc.set(any)).thenAnswer((invocation) {
          capturedMessageData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await ChatService.sendMessage(
          firestore: mockFirestore,
          chatId: 'CH_789',
          senderId: 'USER_001',
          text: 'Test read receipt',
          type: 'text',
        );

        // Assert
        expect(capturedMessageData['read'], equals(false)); // Unread by default
        expect(capturedMessageData['senderId'], equals('USER_001'));
      });
    });

    group('Chat Update Tests', () {
      test('BRANCH 8: Last message update path', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);

        Map<String, dynamic> capturedChatUpdate = {};
        when(mockChatDoc.update(any)).thenAnswer((invocation) {
          capturedChatUpdate =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Future.value();
        });

        // Act
        await ChatService.sendMessage(
          firestore: mockFirestore,
          chatId: 'CH_789',
          senderId: 'USER_001',
          text: 'Latest message',
          type: 'text',
        );

        // Assert
        verify(mockChatDoc.update(any)).called(1);
        expect(capturedChatUpdate['lastMessage'], equals('Latest message'));
        expect(capturedChatUpdate['lastMessageTime'], isNotNull);
        expect(capturedChatUpdate['lastMessageSenderId'], equals('USER_001'));
      });
    });

    group('Error Handling Tests', () {
      test('BRANCH 9: Firestore exception during message send', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);
        when(mockMessageDoc.set(any)).thenThrow(
          FirebaseException(plugin: 'firestore', message: 'Network error'),
        );

        // Act & Assert
        expect(
          () async => await ChatService.sendMessage(
            firestore: mockFirestore,
            chatId: 'CH_789',
            senderId: 'USER_001',
            text: 'Test message',
            type: 'text',
          ),
          throwsA(isA<FirebaseException>()),
        );
      });

      test('BRANCH 10: Storage exception during image upload', () async {
        // Arrange
        when(mockChatSnapshot.exists).thenReturn(true);

        MockXFile mockImageFile = MockXFile();
        MockReference mockStorageRef = MockReference();

        when(mockImageFile.path).thenReturn('/test/image.jpg');
        when(mockImageFile.readAsBytes()).thenAnswer((_) async => [1, 2, 3]);

        when(mockStorage.ref()).thenReturn(mockStorageRef);
        when(mockStorageRef.child(any)).thenReturn(mockStorageRef);
        when(mockStorageRef.putData(any)).thenThrow(
          FirebaseException(plugin: 'storage', message: 'Upload failed'),
        );

        // Act & Assert
        expect(
          () async => await ChatService.sendMessage(
            firestore: mockFirestore,
            storage: mockStorage,
            chatId: 'CH_789',
            senderId: 'USER_001',
            text: 'Image message',
            type: 'image',
            imageFile: mockImageFile,
          ),
          throwsA(isA<FirebaseException>()),
        );
      });
    });
  });
}
