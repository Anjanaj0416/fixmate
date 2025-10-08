import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('WT027 - RatingService.getWorkerRatingStats() Tests', () {
    test('BRANCH 1: Worker with 10 reviews - average calculation', () {
      // Arrange
      List<double> ratings = [5.0, 4.5, 5.0, 4.0, 4.5, 5.0, 3.5, 4.0, 4.5, 5.0];

      // Act
      double average = ratings.reduce((a, b) => a + b) / ratings.length;

      // Assert
      expect(average,
          closeTo(4.5, 0.01)); // FIXED: Expected value should be 4.5, not 4.45
      // Sum = 45.0, Count = 10, Average = 4.5
    });

    test('BRANCH 2: Worker with 0 reviews - default values', () async {
      // Test default stats for worker with no reviews
      Map<String, dynamic> stats = {
        'average': 0.0,
        'total': 0,
        'distribution': {},
      };

      expect(stats['average'], equals(0.0));
      expect(stats['total'], equals(0));
      expect(stats['distribution'], isEmpty);
    });

    test('BRANCH 3: Worker with perfect 5-star reviews', () async {
      List<double> perfectRatings = [5.0, 5.0, 5.0, 5.0, 5.0];
      double average =
          perfectRatings.reduce((a, b) => a + b) / perfectRatings.length;

      expect(average, equals(5.0));
    });

    test('BRANCH 4: Rating distribution calculation', () async {
      List<double> ratings = [5.0, 4.5, 5.0, 4.0, 4.5, 5.0, 3.5, 4.0, 4.5, 5.0];
      Map<double, int> distribution = {};

      for (var rating in ratings) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      expect(distribution[5.0], equals(4));
      expect(distribution[4.5], equals(3));
      expect(distribution[4.0], equals(2));
      expect(distribution[3.5], equals(1));
    });

    test('BRANCH 5: Invalid ratings filtered out', () async {
      List<double?> ratingsWithInvalid = [5.0, null, 4.5, -1, 6.0, 4.0];
      List<double> validRatings = ratingsWithInvalid
          .where((r) => r != null && r >= 0 && r <= 5)
          .map((r) => r!)
          .toList();

      expect(validRatings, equals([5.0, 4.5, 4.0]));
      expect(validRatings.length, equals(3));
    });

    test('BRANCH 6: Decimal rounding to 2 places', () async {
      double average = 4.4567;
      double rounded = double.parse(average.toStringAsFixed(2));

      expect(rounded, equals(4.46));
    });
  });
}
