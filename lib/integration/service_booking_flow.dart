// lib/integration/service_booking_flow.dart
// This file shows how to integrate the complete booking flow

import 'package:flutter/material.dart';
import '../screens/service_request_flow.dart';
import '../screens/worker_search_quotes_screen.dart';
import '../screens/booking_confirmation_screen.dart';
import '../screens/customer_bookings_screen.dart';

class ServiceBookingIntegration {
  // Step 1: Customer submits service request (existing functionality)
  static void startServiceRequest(
    BuildContext context, {
    required String serviceType,
    required String subService,
    required String serviceName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceRequestFlow(
          serviceType: serviceType,
          subService: subService,
          serviceName: serviceName,
        ),
      ),
    );
  }

  // Step 2: After service request is submitted, show workers and quotes
  static void showWorkersAndQuotes(
    BuildContext context, {
    required String serviceRequestId,
    required String serviceType,
    required String problemDescription,
    double? latitude,
    double? longitude,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerSearchQuotesScreen(
          serviceRequestId: serviceRequestId,
          serviceType: serviceType,
          problemDescription: problemDescription,
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
  }

  // Step 3: Navigate to booking confirmation
  static void confirmBooking(
    BuildContext context, {
    required QuoteModel quote,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(quote: quote),
      ),
    );
  }

  // Step 4: View customer bookings
  static void viewCustomerBookings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerBookingsScreen(),
      ),
    );
  }
}

// Enhanced Service Request Flow with integrated booking flow
class EnhancedServiceRequestFlow extends StatefulWidget {
  final String serviceType;
  final String subService;
  final String serviceName;

  const EnhancedServiceRequestFlow({
    Key? key,
    required this.serviceType,
    required this.subService,
    required this.serviceName,
  }) : super(key: key);

  @override
  _EnhancedServiceRequestFlowState createState() =>
      _EnhancedServiceRequestFlowState();
}

class _EnhancedServiceRequestFlowState
    extends State<EnhancedServiceRequestFlow> {
  // Override the submit request method to navigate to workers/quotes
  Future<void> _submitRequestAndShowWorkers() async {
    try {
      // Submit service request (using existing logic)
      String serviceRequestId = await _submitServiceRequest();

      // Get user location
      double? latitude, longitude;
      // Add location logic here if needed

      // Navigate to workers and quotes screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkerSearchQuotesScreen(
            serviceRequestId: serviceRequestId,
            serviceType: widget.serviceType,
            problemDescription: _problemDescription,
            latitude: latitude,
            longitude: longitude,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to submit request: ${e.toString()}');
    }
  }

  Future<String> _submitServiceRequest() async {
    // Implement service request submission
    // Return the service request ID
    return 'SR001'; // Placeholder
  }

  String _problemDescription = '';

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build the service request form
    return Scaffold(
      appBar: AppBar(
        title: Text('Request ${widget.serviceName}'),
        backgroundColor: Color(0xFFFF9800),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service request form content
            _buildServiceForm(),

            SizedBox(height: 32),

            // Submit button that navigates to workers/quotes
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequestAndShowWorkers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF9800),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Submit Request & Find Workers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Describe your ${widget.serviceName} needs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the problem or service needed...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) {
            setState(() {
              _problemDescription = value;
            });
          },
        ),
        // Add more form fields as needed
      ],
    );
  }
}
