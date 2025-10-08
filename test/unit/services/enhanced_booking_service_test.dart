import 'package:flutter_test/flutter_test.dart';
import 'package:fixmate/services/enhanced_booking_service.dart';

void main() {
  group('EnhancedBookingService White Box Tests - WT009', () {
    group('generateBookingId() - ID Generation Logic Branches', () {
      test('BRANCH 1: Uniqueness validation - 100 iterations', () async {
        // Arrange
        final generatedIds = <String>{};

        // Act - Generate 100 IDs
        for (int i = 0; i < 100; i++) {
          final id = await EnhancedBookingService.generateBookingId();
          generatedIds.add(id);

          // Assert format: BK_XXXXXX#### (6 digit timestamp + 4 digit random)
          expect(id, matches(RegExp(r'^BK_\d{10}$')));
        }

        // Assert - All IDs should be unique
        expect(generatedIds.length, equals(100),
            reason: 'All 100 IDs must be unique (no collisions)');
      });

      test('BRANCH 2: Timestamp extraction logic - last 6 digits', () async {
        // Act
        final id = await EnhancedBookingService.generateBookingId();

        // Assert - Verify format and timestamp logic
        expect(id.startsWith('BK_'), isTrue);
        final parts = id.substring(3); // Remove "BK_"
        expect(parts.length, equals(10)); // 6 timestamp + 4 random

        // Verify timestamp portion (first 6 chars of parts)
        final timestampPart = parts.substring(0, 6);
        expect(int.tryParse(timestampPart), isNotNull);
      });

      test('BRANCH 3: Random suffix range validation - 1000 to 9999', () async {
        // Arrange
        final randomSuffixes = <int>{};

        // Act - Generate 50 IDs and extract random suffixes
        for (int i = 0; i < 50; i++) {
          final id = await EnhancedBookingService.generateBookingId();
          final suffix = id.substring(id.length - 4); // Last 4 digits
          final suffixInt = int.parse(suffix);
          randomSuffixes.add(suffixInt);

          // Assert - Each suffix in valid range
          expect(suffixInt, greaterThanOrEqualTo(1000));
          expect(suffixInt, lessThanOrEqualTo(9999));
        }

        // Assert - Randomness check (should have variety)
        expect(randomSuffixes.length, greaterThan(40),
            reason: 'Random suffixes should have variety (not all same)');
      });

      test('BRANCH 4: Concurrent generation - no race conditions', () async {
        // Arrange
        final generatedIds = <String>{};

        // Act - Generate 10 IDs concurrently
        final futures = List<Future<String>>.generate(
          10,
          (_) => EnhancedBookingService.generateBookingId(),
        );
        final ids = await Future.wait(futures);

        generatedIds.addAll(ids);

        // Assert - All concurrent IDs must be unique
        expect(generatedIds.length, equals(10),
            reason: 'No collisions even with concurrent generation');
      });

      test('BRANCH 5: Timestamp arithmetic - milliseconds extraction',
          () async {
        // Arrange - Capture timestamp before generation
        final beforeTimestamp = DateTime.now().millisecondsSinceEpoch;

        // Act
        final id = await EnhancedBookingService.generateBookingId();

        // Capture after
        final afterTimestamp = DateTime.now().millisecondsSinceEpoch;

        // Assert - Extract timestamp from ID and verify it's within range
        final idTimestampPart = id.substring(3, 9); // BK_[XXXXXX]####
        final beforeLastSix = beforeTimestamp
            .toString()
            .substring(beforeTimestamp.toString().length - 6);
        final afterLastSix = afterTimestamp
            .toString()
            .substring(afterTimestamp.toString().length - 6);

        // Verify timestamp logic is correct
        final beforeInt = int.parse(beforeLastSix);
        final afterInt = int.parse(afterLastSix);
        final idInt = int.parse(idTimestampPart);

        // ID timestamp should be between before and after timestamps
        expect(idInt, greaterThanOrEqualTo(beforeInt));
        expect(idInt, lessThanOrEqualTo(afterInt));
      });

      test('BRANCH 6: Format consistency - multiple generations', () async {
        // Arrange
        final ids = <String>[];

        // Act - Generate multiple IDs
        for (int i = 0; i < 20; i++) {
          ids.add(await EnhancedBookingService.generateBookingId());
        }

        // Assert - All IDs follow the same format
        for (final id in ids) {
          expect(id.length, equals(13)); // BK_ + 10 digits
          expect(id.startsWith('BK_'), isTrue);
          expect(RegExp(r'^BK_\d{10}$').hasMatch(id), isTrue);
        }
      });

      test('BRANCH 7: Random distribution - statistical test', () async {
        // Arrange
        final firstDigits = <int>[];

        // Act - Generate 100 IDs and collect first digit of random suffix
        for (int i = 0; i < 100; i++) {
          final id = await EnhancedBookingService.generateBookingId();
          final randomPart = id.substring(id.length - 4);
          final firstDigit = int.parse(randomPart[0]);
          firstDigits.add(firstDigit);
        }

        // Assert - Should have some variety in first digits (1-9)
        final uniqueDigits = firstDigits.toSet();
        expect(uniqueDigits.length, greaterThanOrEqualTo(4),
            reason: 'Random generation should produce varied first digits');
      });

      test('BRANCH 8: Boundary condition - rapid sequential generation',
          () async {
        // Arrange & Act - Generate IDs as fast as possible
        final id1 = await EnhancedBookingService.generateBookingId();
        final id2 = await EnhancedBookingService.generateBookingId();
        final id3 = await EnhancedBookingService.generateBookingId();

        // Assert - All should be unique even when generated rapidly
        expect(id1, isNot(equals(id2)));
        expect(id2, isNot(equals(id3)));
        expect(id1, isNot(equals(id3)));
      });
    });

    group('Edge Cases and Additional Coverage', () {
      test('BRANCH 9: ID parsing - extracting components', () async {
        // Act
        final id = await EnhancedBookingService.generateBookingId();

        // Assert - Can extract all components correctly
        expect(id.substring(0, 3), equals('BK_'));
        expect(id.substring(3, 9).length, equals(6)); // Timestamp part
        expect(id.substring(9, 13).length, equals(4)); // Random part

        // Verify all parts are numeric
        expect(int.tryParse(id.substring(3, 9)), isNotNull);
        expect(int.tryParse(id.substring(9, 13)), isNotNull);
      });

      test('BRANCH 10: Collision probability - stress test', () async {
        // Arrange
        final ids = <String>{};
        const iterations = 500;

        // Act - Generate many IDs to test collision probability
        for (int i = 0; i < iterations; i++) {
          final id = await EnhancedBookingService.generateBookingId();
          ids.add(id);
        }

        // Assert - No collisions even with high volume
        expect(ids.length, equals(iterations),
            reason:
                'All $iterations IDs must be unique - no collisions allowed');
      });
    });
  });
}
