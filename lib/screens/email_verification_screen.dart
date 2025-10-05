// lib/screens/email_verification_screen.dart
// NEW FILE - Email Verification Screen for Two-Factor Authentication

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userData;

  EmailVerificationScreen({
    required this.email,
    required this.userData,
  });

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isEmailSent = false;
  Timer? _timer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Send verification email to user
  Future<void> _sendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          _isEmailSent = true;
        });
        _showSuccessSnackBar('Verification email sent to ${widget.email}');
        _startResendTimer();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send verification email: ${e.toString()}');
    }
  }

  /// Start timer to check if email is verified
  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _checkEmailVerified();
    });
  }

  /// Check if email is verified
  Future<void> _checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      user = _auth.currentUser;

      if (user!.emailVerified) {
        _timer?.cancel();
        _showSuccessSnackBar('Email verified successfully!');

        // Wait a moment before navigating
        await Future.delayed(Duration(seconds: 1));

        // Navigate to account type selection
        Navigator.pushReplacementNamed(context, '/account_type');
      }
    }
  }

  /// Start countdown timer for resend button
  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  /// Resend verification email
  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      await _sendVerificationEmail();
    } catch (e) {
      _showErrorSnackBar('Failed to resend email: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Manual verification check
  Future<void> _checkVerificationManually() async {
    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;

        if (user!.emailVerified) {
          _showSuccessSnackBar('Email verified successfully!');
          await Future.delayed(Duration(seconds: 1));
          Navigator.pushReplacementNamed(context, '/account_type');
        } else {
          _showErrorSnackBar(
              'Email not verified yet. Please check your inbox and click the verification link.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error checking verification: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () async {
            // Sign out user if they go back without verifying
            await _auth.signOut();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),

              // Email icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 50,
                  color: Color(0xFF2196F3),
                ),
              ),

              SizedBox(height: 32),

              // Title
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 16),

              // Description
              Text(
                'We\'ve sent a verification link to',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Email address
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Instructions
              Text(
                'Please check your inbox and click on the verification link to activate your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40),

              // Auto-verification indicator
              if (_isEmailSent)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Verification email sent! Checking automatically...',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 24),

              // Manual check button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkVerificationManually,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'I\'ve Verified My Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 24),

              // Resend email section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the email?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: _canResend && !_isLoading
                        ? _resendVerificationEmail
                        : null,
                    child: Text(
                      _canResend ? 'Resend' : 'Resend in ${_resendCountdown}s',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            _canResend ? Color(0xFF2196F3) : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40),

              // Help text
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildTipItem('Check your spam/junk folder'),
                    _buildTipItem('Make sure ${widget.email} is correct'),
                    _buildTipItem(
                        'The link expires after 1 hour - request a new one if needed'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
