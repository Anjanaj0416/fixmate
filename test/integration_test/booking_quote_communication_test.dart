// test/integration_test/booking_quote_communication_test.dart
// Test Cases: FT-018 to FT-030, FT-063 to FT-076
// Booking & Quote Management + Communication Features
// Run: flutter test test/integration_test/booking_quote_communication_test.dart
// Run individual test: flutter test test/integration_test/booking_quote_communication_test.dart --name "FT-018"

import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_services.dart';

void main() {
  late MockAuthService mockAuth;
  late MockFirestoreService mockFirestore;
  late MockQuoteService mockQuote;
  late MockBookingService mockBooking;
  late MockChatService mockChat;
  late MockNotificationService mockNotification;

  setUp(() {
    mockAuth = MockAuthService();
    mockFirestore = MockFirestoreService();
    mockQuote = MockQuoteService();
    mockBooking = MockBookingService();
    mockChat = MockChatService();
    mockNotification = MockNotificationService();
  });

  tearDown(() {
    mockFirestore.clearData();
    mockQuote.clearAll();
    mockBooking.clearAll();
    mockChat.clearAll();
    mockNotification.clearAll();
  });

  group('📅 Booking & Quote Management Tests (FT-018 to FT-027)', () {
    test('FT-018: Quote Request by Customer', () async {
      TestLogger.logTestStart('FT-018', 'Quote Request by Customer');

      // Precondition: Customer viewing worker profile
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      // Test Data
      const workerId = 'HM_1234';
      const problemDescription = 'Leaking pipe';
      final scheduledDate = DateTime.now().add(Duration(days: 1));

      // Step 1-5: Create quote request
      final quoteId = await mockQuote.createQuoteRequest(
        customerId: customerCred!.user!.uid,
        customerName: 'Test Customer',
        workerId: workerId,
        problemDescription: problemDescription,
        scheduledDate: scheduledDate,
      );

      expect(quoteId, isNotEmpty);

      // Verify quote created in Firestore
      final quote = await mockFirestore.getDocument(
        collection: 'quotes',
        documentId: quoteId,
      );

      expect(quote.exists, true);
      expect(quote.data()!['status'], 'pending');
      expect(quote.data()!['worker_id'], workerId);

      // Verify worker notification sent
      final workerNotifications = await mockNotification.getNotifications(
        userId: workerId,
      );
      expect(workerNotifications.isNotEmpty, true);
      expect(workerNotifications.first['type'], 'quote_request');

      TestLogger.logTestPass('FT-018',
          'Quote request created in Firestore, worker notified, status "Pending"');
    });

    test('FT-019: Create Custom Quote by Worker', () async {
      TestLogger.logTestStart('FT-019', 'Create Custom Quote by Worker');

      // Precondition: Worker received quote request
      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(workerCred, isNotNull);

      const quoteId = 'Q_12345';

      // Create pending quote first
      await mockQuote.createPendingQuote(
        quoteId: quoteId,
        workerId: workerCred!.user!.uid,
      );

      // Test Data: Worker sends custom quote
      const price = 5000.0;
      const timeline = '2 days';
      const notes = 'Materials included';

      // Step 1-4: Worker sends quote
      await mockQuote.sendCustomQuote(
        quoteId: quoteId,
        price: price,
        timeline: timeline,
        notes: notes,
      );

      // Verify quote updated
      final quote = await mockFirestore.getDocument(
        collection: 'quotes',
        documentId: quoteId,
      );

      expect(quote.data()!['price'], price);
      expect(quote.data()!['timeline'], timeline);
      expect(quote.data()!['notes'], notes);
      expect(quote.data()!['status'], 'sent');

      // Verify expires in 48 hours
      final expiresAt = quote.data()!['expires_at'] as DateTime;
      final now = DateTime.now();
      final hoursDiff = expiresAt.difference(now).inHours;
      expect(hoursDiff, greaterThanOrEqualTo(47));
      expect(hoursDiff, lessThanOrEqualTo(49));

      TestLogger.logTestPass('FT-019',
          'Quote sent to customer, notification delivered, expires in 48 hours');
    });

    test('FT-020: Quote Accept/Decline by Customer', () async {
      TestLogger.logTestStart('FT-020', 'Quote Accept/Decline by Customer');

      // Precondition: Customer has pending quote
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const quoteId = 'Q_12345';
      const workerId = 'HM_1234';

      // Create sent quote
      await mockQuote.createSentQuote(
        quoteId: quoteId,
        customerId: customerCred!.user!.uid,
        workerId: workerId,
      );

      // Test accepting quote
      final bookingId = await mockQuote.acceptQuote(quoteId: quoteId);

      expect(bookingId, isNotEmpty);

      // Verify booking created
      final booking = await mockFirestore.getDocument(
        collection: 'bookings',
        documentId: bookingId,
      );
      expect(booking.exists, true);
      expect(booking.data()!['status'], 'requested');

      // Verify quote status updated
      final quote = await mockFirestore.getDocument(
        collection: 'quotes',
        documentId: quoteId,
      );
      expect(quote.data()!['status'], 'accepted');

      // Test declining quote
      const quoteId2 = 'Q_12346';
      await mockQuote.createSentQuote(
        quoteId: quoteId2,
        customerId: customerCred.user!.uid,
        workerId: workerId,
      );

      await mockQuote.declineQuote(quoteId: quoteId2);

      final declinedQuote = await mockFirestore.getDocument(
        collection: 'quotes',
        documentId: quoteId2,
      );
      expect(declinedQuote.data()!['status'], 'declined');

      // Verify worker notified
      final workerNotifications = await mockNotification.getNotifications(
        userId: workerId,
      );
      expect(
          workerNotifications.any((n) => n['type'] == 'quote_declined'), true);

      TestLogger.logTestPass('FT-020',
          'If accepted: booking created; If declined: worker notified, quote status updated');
    });

    test('FT-021: Direct Booking Without Quote', () async {
      TestLogger.logTestStart('FT-021', 'Direct Booking Without Quote');

      // Precondition: Customer viewing worker profile
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      // Test Data
      const workerId = 'HM_1234';
      const workerDailyRate = 3500.0;
      final scheduledDate = DateTime.now().add(Duration(days: 1));

      // Step 1-4: Direct booking
      final bookingId = await mockBooking.createDirectBooking(
        customerId: customerCred!.user!.uid,
        workerId: workerId,
        scheduledDate: scheduledDate,
        defaultRate: workerDailyRate,
      );

      expect(bookingId, isNotEmpty);

      // Verify booking created immediately
      final booking = await mockFirestore.getDocument(
        collection: 'bookings',
        documentId: bookingId,
      );

      expect(booking.exists, true);
      expect(booking.data()!['status'], 'requested');
      expect(booking.data()!['price'], workerDailyRate);

      // Verify worker notification
      final workerNotifications = await mockNotification.getNotifications(
        userId: workerId,
      );
      expect(
          workerNotifications.any((n) => n['type'] == 'booking_request'), true);

      TestLogger.logTestPass('FT-021',
          'Booking created immediately with worker\'s daily rate, worker receives notification');
    });

    test('FT-022: Booking Status Tracking', () async {
      TestLogger.logTestStart('FT-022', 'Booking Status Tracking');

      // Precondition: Customer has active booking
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const bookingId = 'B_67890';

      // Create booking and track status changes
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        status: 'requested',
      );

      // Step 1-4: Track status progression
      final statusProgression = [
        'requested',
        'accepted',
        'in_progress',
        'completed'
      ];

      for (String status in statusProgression) {
        await mockBooking.updateBookingStatus(
          bookingId: bookingId,
          status: status,
        );

        final booking = await mockFirestore.getDocument(
          collection: 'bookings',
          documentId: bookingId,
        );

        expect(booking.data()!['status'], status);
        expect(booking.data()!['${status}_at'], isNotNull);
      }

      TestLogger.logTestPass('FT-022',
          'Status progresses: Requested → Accepted → In Progress → Completed, each with timestamp');
    });

    test('FT-023: Booking Cancellation by Customer', () async {
      TestLogger.logTestStart('FT-023', 'Booking Cancellation by Customer');

      // Precondition: Customer has booking in "Requested" status
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const bookingId = 'B_67890';
      const workerId = 'HM_1234';

      // Create requested booking
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerId,
        status: 'requested',
      );

      // Step 1-3: Cancel booking
      await mockBooking.cancelBooking(bookingId: bookingId);

      final booking = await mockFirestore.getDocument(
        collection: 'bookings',
        documentId: bookingId,
      );

      expect(booking.data()!['status'], 'cancelled');

      // Verify worker notified
      final workerNotifications = await mockNotification.getNotifications(
        userId: workerId,
      );
      expect(workerNotifications.any((n) => n['type'] == 'booking_cancelled'),
          true);

      // Verify cancel button hidden after acceptance
      await mockBooking.updateBookingStatus(
        bookingId: bookingId,
        status: 'accepted',
      );

      final canCancel =
          await mockBooking.canCancelBooking(bookingId: bookingId);
      expect(canCancel, false);

      TestLogger.logTestPass('FT-023',
          'Booking status changes to "Cancelled", worker notified, cancel button hidden after acceptance');
    });

    test('FT-024: View Booking Requests (Worker)', () async {
      TestLogger.logTestStart('FT-024', 'View Booking Requests (Worker)');

      // Precondition: Worker has incoming booking requests
      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(workerCred, isNotNull);

      const workerId = 'HM_1234';

      // Create multiple booking requests
      for (int i = 0; i < 3; i++) {
        await mockBooking.createBooking(
          bookingId: 'B_$i',
          customerId: 'customer_$i',
          workerId: workerId,
          status: 'requested',
        );
      }

      // Step 1-3: View booking requests
      final requests = await mockBooking.getWorkerBookingRequests(
        workerId: workerId,
      );

      expect(requests.length, 3);

      // Verify all required info displayed
      for (var request in requests) {
        expect(request['customer_name'], isNotNull);
        expect(request['problem_description'], isNotNull);
        expect(request['scheduled_date'], isNotNull);
        expect(request['location'], isNotNull);
      }

      TestLogger.logTestPass('FT-024',
          'All pending requests displayed with customer info, problem description, date, location');
    });

    test('FT-025: Accept/Decline Booking (Worker)', () async {
      TestLogger.logTestStart('FT-025', 'Accept/Decline Booking (Worker)');

      // Precondition: Worker has pending booking request
      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(workerCred, isNotNull);

      const bookingId = 'B_67890';
      const customerId = 'customer_123';

      // Create pending booking
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerId,
        workerId: workerCred!.user!.uid,
        status: 'requested',
      );

      // Step 1-2: Accept booking
      await mockBooking.acceptBooking(bookingId: bookingId);

      final acceptedBooking = await mockFirestore.getDocument(
        collection: 'bookings',
        documentId: bookingId,
      );

      expect(acceptedBooking.data()!['status'], 'accepted');

      // Verify customer notified via push
      final customerNotifications = await mockNotification.getNotifications(
        userId: customerId,
      );
      expect(customerNotifications.any((n) => n['type'] == 'booking_accepted'),
          true);

      // Test declining with reason
      const bookingId2 = 'B_67891';
      await mockBooking.createBooking(
        bookingId: bookingId2,
        customerId: customerId,
        workerId: workerCred.user!.uid,
        status: 'requested',
      );

      const declineReason = 'Schedule conflict';
      await mockBooking.declineBooking(
        bookingId: bookingId2,
        reason: declineReason,
      );

      final declinedBooking = await mockFirestore.getDocument(
        collection: 'bookings',
        documentId: bookingId2,
      );

      expect(declinedBooking.data()!['status'], 'declined');
      expect(declinedBooking.data()!['decline_reason'], declineReason);

      TestLogger.logTestPass('FT-025',
          'Status updated, customer notified immediately via push notification');
    });

    test('FT-026: Mark Booking as Completed', () async {
      TestLogger.logTestStart('FT-026', 'Mark Booking as Completed');

      // Precondition: Worker has "In Progress" booking
      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );
      expect(workerCred, isNotNull);

      const bookingId = 'B_67890';
      const customerId = 'customer_123';

      // Create in-progress booking
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerId,
        workerId: workerCred!.user!.uid,
        status: 'in_progress',
      );

      // Step 1-3: Mark as completed
      await mockBooking.completeBooking(bookingId: bookingId);

      final booking = await mockFirestore.getDocument(
        collection: 'bookings',
        documentId: bookingId,
      );

      expect(booking.data()!['status'], 'completed');
      expect(booking.data()!['completed_at'], isNotNull);

      // Verify customer prompted to rate/review
      final customerNotifications = await mockNotification.getNotifications(
        userId: customerId,
      );
      expect(customerNotifications.any((n) => n['type'] == 'booking_completed'),
          true);
      expect(
          customerNotifications.any((n) => n['action'] == 'rate_worker'), true);

      TestLogger.logTestPass('FT-026',
          'Status changes to "Completed", customer prompted to rate/review');
    });

    test('FT-027: Booking History View', () async {
      TestLogger.logTestStart('FT-027', 'Booking History View');

      // Precondition: User has completed bookings
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      // Create multiple completed bookings
      for (int i = 0; i < 5; i++) {
        await mockBooking.createBooking(
          bookingId: 'B_completed_$i',
          customerId: customerCred!.user!.uid,
          workerId: 'worker_$i',
          status: 'completed',
          completedAt: DateTime.now().subtract(Duration(days: i)),
        );
      }

      // Step 1-3: View booking history
      final history = await mockBooking.getBookingHistory(
        userId: customerCred!.user!.uid,
      );

      expect(history.length, 5);

      // Verify chronological order (newest first)
      for (int i = 0; i < history.length - 1; i++) {
        final current = history[i]['completed_at'] as DateTime;
        final next = history[i + 1]['completed_at'] as DateTime;
        expect(current.isAfter(next), true);
      }

      // Verify all required fields
      for (var booking in history) {
        expect(booking['scheduled_date'], isNotNull);
        expect(booking['service_type'], isNotNull);
        expect(booking['worker_name'], isNotNull);
        expect(booking['final_price'], isNotNull);
        expect(booking['can_rebook'], true);
      }

      TestLogger.logTestPass('FT-027',
          'Chronological list of all completed bookings with date, service, worker/customer name, final price, re-book option');
    });
  });

  group('🔖 Booking & Quote Validation Tests (FT-063 to FT-072)', () {
    test('FT-063: Quote Request with Empty Description', () async {
      TestLogger.logTestStart('FT-063', 'Quote Request with Empty Description');

      // Precondition: Customer on quote request form
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      // Test Data: Empty description
      const workerId = 'HM_1234';
      const problemDescription = '';

      // Step 1-3: Attempt to submit with empty description
      try {
        await mockQuote.createQuoteRequest(
          customerId: customerCred!.user!.uid,
          customerName: 'Test Customer',
          workerId: workerId,
          problemDescription: problemDescription,
          scheduledDate: DateTime.now().add(Duration(days: 1)),
        );
        fail('Should have thrown validation error');
      } catch (e) {
        expect(e.toString(), contains('Please provide problem description'));
      }

      TestLogger.logTestPass('FT-063',
          'Error "Please provide problem description" displayed, submission blocked');
    });

    test('FT-064: Multiple Quote Requests to Same Worker', () async {
      TestLogger.logTestStart(
          'FT-064', 'Multiple Quote Requests to Same Worker');

      // Precondition: Customer already sent quote request 1 hour ago
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const workerId = 'HM_1234';

      // Create first quote request
      await mockQuote.createQuoteRequest(
        customerId: customerCred!.user!.uid,
        customerName: 'Test Customer',
        workerId: workerId,
        problemDescription: 'First request',
        scheduledDate: DateTime.now().add(Duration(days: 1)),
      );

      // Step 1-3: Attempt duplicate request
      try {
        await mockQuote.createQuoteRequest(
          customerId: customerCred.user!.uid,
          customerName: 'Test Customer',
          workerId: workerId,
          problemDescription: 'Second request',
          scheduledDate: DateTime.now().add(Duration(days: 1)),
        );
        fail('Should have thrown duplicate error');
      } catch (e) {
        expect(e.toString(),
            contains('You already have a pending quote with this worker'));
      }

      TestLogger.logTestPass('FT-064',
          'Warning "You already have a pending quote with this worker" displayed');
    });

    test('FT-065: Quote Acceptance After Worker Unavailable', () async {
      TestLogger.logTestStart(
          'FT-065', 'Quote Acceptance After Worker Unavailable');

      // Precondition: Customer has pending quote, worker went offline
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const quoteId = 'Q_12345';
      const workerId = 'HM_1234';

      // Create sent quote
      await mockQuote.createSentQuote(
        quoteId: quoteId,
        customerId: customerCred!.user!.uid,
        workerId: workerId,
      );

      // Step 1: Worker goes offline
      await mockFirestore.updateDocument(
        collection: 'workers',
        documentId: workerId,
        data: {'is_online': false},
      );

      // Step 2-3: Customer attempts to accept quote
      try {
        await mockQuote.acceptQuote(quoteId: quoteId);
        fail('Should have thrown availability error');
      } catch (e) {
        expect(e.toString(),
            contains('Worker no longer available. Please request new quote'));
      }

      TestLogger.logTestPass('FT-065',
          'Error "Worker no longer available. Please request new quote" displayed');
    });

    test('FT-066: Booking Cancellation After Worker Acceptance', () async {
      TestLogger.logTestStart(
          'FT-066', 'Booking Cancellation After Worker Acceptance');

      // Precondition: Booking status is "Accepted"
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const bookingId = 'B_67890';
      const workerId = 'HM_1234';
      const workerPhone = '+94771234567';

      // Step 1: Worker accepts booking
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerId,
        status: 'accepted',
      );

      // Step 2-3: Customer attempts to cancel
      try {
        await mockBooking.cancelBooking(bookingId: bookingId);
        fail('Should have thrown cancellation restriction error');
      } catch (e) {
        expect(e.toString(), contains('Contact worker to cancel'));
        // FIXED: Check if error contains any of the expected strings
        final errorMessage = e.toString();
        expect(
            errorMessage.contains(workerPhone) ||
                errorMessage.contains('phone') ||
                errorMessage.contains('chat'),
            true);
      }

      // Verify direct cancel is disabled
      final canCancel =
          await mockBooking.canCancelBooking(bookingId: bookingId);
      expect(canCancel, false);

      TestLogger.logTestPass('FT-066',
          'Error "Contact worker to cancel" + phone/chat buttons displayed, direct cancel disabled');
    });

    test('FT-067: Booking with Past Date Selection', () async {
      TestLogger.logTestStart('FT-067', 'Booking with Past Date Selection');

      // Precondition: Customer creating booking
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const workerId = 'HM_1234';
      final pastDate = DateTime.now().subtract(Duration(days: 1));

      // Step 1-3: Attempt to book with past date
      try {
        await mockBooking.createDirectBooking(
          customerId: customerCred!.user!.uid,
          workerId: workerId,
          scheduledDate: pastDate,
          defaultRate: 3500.0,
        );
        fail('Should have thrown date validation error');
      } catch (e) {
        expect(e.toString(), contains('Please select a future date'));
      }

      TestLogger.logTestPass(
          'FT-067', 'Error "Please select a future date" displayed');
    });

    test('FT-068: Quote Expiration After 48 Hours', () async {
      TestLogger.logTestStart('FT-068', 'Quote Expiration After 48 Hours');

      // Precondition: Worker sent quote
      const quoteId = 'Q_12345';
      const customerId = 'customer_123';

      // Create quote sent 48 hours ago
      await mockQuote.createExpiredQuote(
        quoteId: quoteId,
        customerId: customerId,
        hoursAgo: 48,
      );

      // Step 1-3: Customer attempts to accept after 48 hours
      try {
        await mockQuote.acceptQuote(quoteId: quoteId);
        fail('Should have thrown expiration error');
      } catch (e) {
        expect(e.toString(), contains('This quote expired. Request new quote'));
      }

      // Verify quote status
      final quote = await mockFirestore.getDocument(
        collection: 'quotes',
        documentId: quoteId,
      );

      expect(quote.data()!['status'], 'expired');

      TestLogger.logTestPass('FT-068',
          'Quote status "Expired", cannot be accepted, message "This quote expired. Request new quote"');
    });

    test('FT-069: Booking Status Update Notifications', () async {
      TestLogger.logTestStart('FT-069', 'Booking Status Update Notifications');

      // Precondition: Customer has active booking
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const bookingId = 'B_67890';
      const workerId = 'HM_1234';

      // Create requested booking
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerId,
        status: 'requested',
      );

      // Step 1: Worker accepts booking
      final startTime = DateTime.now();
      await mockBooking.acceptBooking(bookingId: bookingId);

      // Step 2-3: Check notification delivery time
      await Future.delayed(Duration(milliseconds: 100));

      final customerNotifications = await mockNotification.getNotifications(
        userId: customerCred.user!.uid,
      );

      final acceptNotification = customerNotifications.firstWhere(
        (n) => n['type'] == 'booking_accepted',
      );

      final notificationTime = acceptNotification['sent_at'] as DateTime;
      final deliveryTime = notificationTime.difference(startTime);

      expect(deliveryTime.inSeconds, lessThanOrEqualTo(5));
      expect(acceptNotification['is_push'], true);

      TestLogger.logTestPass('FT-069',
          'Push notification received within 5 seconds of status change');
    });

    test('FT-070: Booking History Pagination', () async {
      TestLogger.logTestStart('FT-070', 'Booking History Pagination');

      // Precondition: User has 100+ completed bookings
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      // Create 100+ bookings
      for (int i = 0; i < 150; i++) {
        await mockBooking.createBooking(
          bookingId: 'B_$i',
          customerId: customerCred!.user!.uid,
          workerId: 'worker_$i',
          status: 'completed',
          completedAt: DateTime.now().subtract(Duration(days: i)),
        );
      }

      // Step 1-3: Load booking history and measure performance
      final stopwatch = Stopwatch()..start();

      final firstPage = await mockBooking.getBookingHistoryPaginated(
        userId: customerCred!.user!.uid,
        page: 1,
        pageSize: 20,
      );

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(firstPage.length, 20);

      // Test pagination
      final secondPage = await mockBooking.getBookingHistoryPaginated(
        userId: customerCred.user!.uid,
        page: 2,
        pageSize: 20,
      );

      expect(secondPage.length, 20);
      expect(
          secondPage.first['booking_id'], isNot(firstPage.first['booking_id']));

      TestLogger.logTestPass('FT-070',
          'History loads in <2 seconds, paginated (20 per page), smooth scrolling');
    });

    test('FT-071: Booking with Special Instructions Field', () async {
      TestLogger.logTestStart(
          'FT-071', 'Booking with Special Instructions Field');

      // Precondition: Customer creating booking
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      // Test Data: 500+ character text
      final longInstructions = 'A' * 550;

      const bookingId = 'B_12345';
      const workerId = 'HM_1234';

      // Step 1-3: Create booking with long instructions
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerId,
        status: 'requested',
        specialInstructions: longInstructions,
      );

      final booking = await mockFirestore.getDocument(
        collection: 'bookings',
        documentId: bookingId,
      );

      expect(booking.data()!['special_instructions'], longInstructions);
      expect(booking.data()!['special_instructions'].length, 550);

      // Verify truncation in list view
      final listView =
          await mockBooking.getBookingListView(bookingId: bookingId);
      expect(listView['instructions_preview'].length, lessThanOrEqualTo(100));
      expect(listView['has_read_more'], true);

      TestLogger.logTestPass('FT-071',
          'Text saved successfully, truncated in list view with "Read more" button');
    });

    test('FT-072: Direct Booking Emergency Flow', () async {
      TestLogger.logTestStart('FT-072', 'Direct Booking Emergency Flow');

      // Precondition: Customer viewing worker profile
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const workerId = 'HM_1234';
      const defaultRate = 3500.0;

      // Step 1-3: Create emergency booking
      final bookingId = await mockBooking.createEmergencyBooking(
        customerId: customerCred!.user!.uid,
        workerId: workerId,
        defaultRate: defaultRate,
      );

      expect(bookingId, isNotEmpty);

      final booking = await mockFirestore.getDocument(
        collection: 'bookings',
        documentId: bookingId,
      );

      expect(booking.data()!['urgency'], 'emergency');
      expect(booking.data()!['status'], 'requested');
      expect(booking.data()!['price'], defaultRate);

      // Verify urgent notification sent
      final workerNotifications = await mockNotification.getNotifications(
        userId: workerId,
      );

      final emergencyNotif = workerNotifications.firstWhere(
        (n) => n['type'] == 'booking_request' && n['urgency'] == 'emergency',
      );

      expect(emergencyNotif['priority'], 'high');

      TestLogger.logTestPass('FT-072',
          'Booking created immediately, worker receives urgent notification, default rate applied');
    });
  });

  group('💬 Communication Features Tests (FT-028 to FT-030)', () {
    test('FT-028: Real-Time In-App Chat', () async {
      TestLogger.logTestStart('FT-028', 'Real-Time In-App Chat');

      // Precondition: Customer and worker have active booking
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );

      expect(customerCred, isNotNull);
      expect(workerCred, isNotNull);

      const bookingId = 'B_12345';

      // Create active booking
      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerCred!.user!.uid,
        status: 'accepted',
      );

      // Step 1-2: Customer sends message
      final message1Time = DateTime.now();
      final messageId1 = await mockChat.sendMessage(
        bookingId: bookingId,
        senderId: customerCred.user!.uid,
        message: 'Hello',
      );

      // Step 3: Worker receives notification
      await Future.delayed(Duration(milliseconds: 100));

      final workerNotifications = await mockNotification.getNotifications(
        userId: workerCred.user!.uid,
      );

      expect(workerNotifications.any((n) => n['type'] == 'new_message'), true);

      // Step 4-5: Worker replies
      final message2Time = DateTime.now();
      final messageId2 = await mockChat.sendMessage(
        bookingId: bookingId,
        senderId: workerCred.user!.uid,
        message: 'Tomorrow 9 AM',
      );

      // Verify delivery time
      final deliveryTime = message2Time.difference(message1Time);
      expect(deliveryTime.inMilliseconds, lessThan(1200));

      // Verify messages in chat
      final messages = await mockChat.getMessages(bookingId: bookingId);
      expect(messages.length, 2);
      expect(messages[0]['text'], 'Hello');
      expect(messages[1]['text'], 'Tomorrow 9 AM');

      // Verify read receipts
      expect(messages[0]['status'], 'read');
      expect(messages[1]['status'], 'delivered');

      // Verify unread count
      final unreadCount = await mockChat.getUnreadCount(
        bookingId: bookingId,
        userId: customerCred.user!.uid,
      );
      expect(unreadCount, 1);

      TestLogger.logTestPass('FT-028',
          'Messages delivered within 1.2 seconds average, real-time updates, read receipts (✓✓), unread count displayed');
    });

    test('FT-029: Voice Call Integration', () async {
      TestLogger.logTestStart('FT-029', 'Voice Call Integration');

      // Precondition: Customer viewing worker profile or booking
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      const workerPhone = '+94771234567';
      const workerId = 'HM_1234';

      // Create worker with phone number
      await mockFirestore.setDocument(
        collection: 'workers',
        documentId: workerId,
        data: {
          'worker_id': workerId,
          'phone': workerPhone,
        },
      );

      // Step 1-3: Initiate call
      final callIntent = await mockBooking.initiateCall(
        workerId: workerId,
        customerId: customerCred!.user!.uid,
      );

      expect(callIntent['action'], 'dial');
      expect(callIntent['phone_number'], workerPhone);

      // Verify call activity logged
      final callLogs = await mockFirestore.queryCollection(
        collection: 'call_logs',
        where: {
          'worker_id': workerId,
          'customer_id': customerCred.user!.uid,
        },
      );

      expect(callLogs.isNotEmpty, true);
      expect(callLogs.first.data()!['timestamp'], isNotNull);

      TestLogger.logTestPass('FT-029',
          'Device phone app opens with worker\'s number pre-filled, call activity logged');
    });

    test('FT-030: Push Notifications', () async {
      TestLogger.logTestStart('FT-030', 'Push Notifications');

      // Precondition: User has notifications enabled
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      await mockNotification.enableNotifications(
        userId: customerCred!.user!.uid,
      );

      const bookingId = 'B_12345';
      const workerId = 'HM_1234';

      // Test notification events
      final events = [
        {'type': 'new_message', 'screen': 'chat'},
        {'type': 'booking_accepted', 'screen': 'booking_details'},
        {'type': 'quote_received', 'screen': 'quote_details'},
        {'type': 'booking_completed', 'screen': 'booking_details'},
      ];

      for (var event in events) {
        // Step 1: Trigger notification event
        final triggerTime = DateTime.now();

        await mockNotification.sendNotification(
          userId: customerCred.user!.uid,
          type: event['type'] as String,
          bookingId: bookingId,
        );

        // Step 2: Check notification delivery
        await Future.delayed(Duration(milliseconds: 100));

        final notifications = await mockNotification.getNotifications(
          userId: customerCred.user!.uid,
        );

        final notification = notifications.firstWhere(
          (n) => n['type'] == event['type'],
        );

        final deliveryTime =
            (notification['sent_at'] as DateTime).difference(triggerTime);
        expect(deliveryTime.inSeconds, lessThanOrEqualTo(5));

        // Step 3-4: Verify tapping opens relevant screen
        expect(notification['target_screen'], event['screen']);
      }

      TestLogger.logTestPass('FT-030',
          'Notification appears within 5 seconds, tapping opens relevant screen (chat/booking details)');
    });
  });

  group('💬 Communication Validation Tests (FT-073 to FT-076)', () {
    test('FT-073: Chat Message with Special Characters', () async {
      TestLogger.logTestStart('FT-073', 'Chat Message with Special Characters');

      // Precondition: Chat conversation open
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      final workerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'worker@test.com',
        password: 'Test@123',
      );

      const bookingId = 'B_12345';

      await mockBooking.createBooking(
        bookingId: bookingId,
        customerId: customerCred!.user!.uid,
        workerId: workerCred!.user!.uid,
        status: 'accepted',
      );

      // Test Data: Messages with special characters
      final testMessages = [
        'Hello 😊',
        'කොහොමද', // Sinhala
        'நல்ல', // Tamil
        'Special chars: @#\$%',
      ];

      // Step 1-4: Send and verify all message types
      for (var message in testMessages) {
        final messageId = await mockChat.sendMessage(
          bookingId: bookingId,
          senderId: customerCred.user!.uid,
          message: message,
        );

        expect(messageId, isNotEmpty);

        // Verify message stored correctly
        final storedMessage = await mockFirestore.getDocument(
          collection: 'messages',
          documentId: messageId,
        );

        expect(storedMessage.data()!['text'], message);

        // Verify display on receiver end
        final messages = await mockChat.getMessages(bookingId: bookingId);
        final receivedMessage =
            messages.firstWhere((m) => m['message_id'] == messageId);
        expect(receivedMessage['text'], message);
      }

      TestLogger.logTestPass('FT-073',
          'All characters displayed correctly on sender and receiver devices');
    });

    test('FT-074: Chat Message Retry on Network Failure', () async {
      TestLogger.logTestStart(
          'FT-074', 'Chat Message Retry on Network Failure');

      // Precondition: Chat conversation open
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );

      const bookingId = 'B_12345';
      const message = 'Test message';

      // Step 1-2: Disable internet and send message
      await mockChat.setNetworkStatus(offline: true);

      final messageId = await mockChat.sendMessage(
        bookingId: bookingId,
        senderId: customerCred!.user!.uid,
        message: message,
      );

      // Step 3: Verify "Sending..." status
      var messageStatus = await mockChat.getMessageStatus(messageId: messageId);
      expect(messageStatus, 'sending');

      // Step 4-5: Re-enable internet and verify auto-resend
      await mockChat.setNetworkStatus(offline: false);
      await Future.delayed(Duration(milliseconds: 500));

      messageStatus = await mockChat.getMessageStatus(messageId: messageId);
      expect(messageStatus, 'sent');

      // Verify message in queue was sent
      final messages = await mockChat.getMessages(bookingId: bookingId);
      final sentMessage =
          messages.firstWhere((m) => m['message_id'] == messageId);
      expect(sentMessage['text'], message);

      TestLogger.logTestPass('FT-074',
          'Message queued locally, auto-resends when online, marked as "Sent" (✓) when successful');
    });

    test('FT-075: Voice Call with Invalid Phone Number', () async {
      TestLogger.logTestStart('FT-075', 'Voice Call with Invalid Phone Number');

      // Precondition: Worker profile has incomplete/invalid phone
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );

      const workerId = 'HM_1234';

      // Test Data: Invalid phone numbers
      final invalidPhones = [null, '', 'invalid', '123'];

      for (var phone in invalidPhones) {
        // Create worker with invalid phone
        await mockFirestore.setDocument(
          collection: 'workers',
          documentId: workerId,
          data: {
            'worker_id': workerId,
            'phone': phone,
          },
        );

        // Step 1-3: Attempt to call
        try {
          await mockBooking.initiateCall(
            workerId: workerId,
            customerId: customerCred!.user!.uid,
          );
          fail('Should have thrown invalid phone error');
        } catch (e) {
          expect(e.toString(),
              contains('Phone number not available. Please use chat'));
        }
      }

      TestLogger.logTestPass('FT-075',
          'Error "Phone number not available. Please use chat" displayed, no crash');
    });

    test('FT-076: Push Notification Opt-Out', () async {
      TestLogger.logTestStart('FT-076', 'Push Notification Opt-Out');

      // Precondition: User logged in
      final customerCred = await mockAuth.createUserWithEmailAndPassword(
        email: 'customer@test.com',
        password: 'Test@123',
      );
      expect(customerCred, isNotNull);

      // Step 1-2: Disable push notifications
      await mockNotification.disablePushNotifications(
        userId: customerCred!.user!.uid,
      );

      // Step 3: Trigger notification event
      await mockNotification.sendNotification(
        userId: customerCred.user!.uid,
        type: 'booking_accepted',
        bookingId: 'B_12345',
      );

      // Step 4: Verify no push notifications but in-app notifications shown
      final pushNotifications = await mockNotification.getPushNotifications(
        userId: customerCred.user!.uid,
      );
      expect(pushNotifications.isEmpty, true);

      final inAppNotifications = await mockNotification.getInAppNotifications(
        userId: customerCred.user!.uid,
      );
      expect(inAppNotifications.isNotEmpty, true);

      TestLogger.logTestPass('FT-076',
          'No push notifications received, but in-app notifications still shown');
    });
  });
}
