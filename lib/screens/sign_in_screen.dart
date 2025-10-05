// lib/screens/sign_in_screen.dart
// FIXED VERSION - Corrected accountType check for workers
// Changed 'worker' to 'service_provider' to match what WorkerService saves

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_account_screen.dart';
import 'account_type_screen.dart';
import 'worker_registration_flow.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';
import 'customer_dashboard.dart';
import 'forgot_password_screen.dart';
import '../services/google_auth_service.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      _showSuccessSnackBar('Welcome back!');

      // Navigate based on PRIMARY account (first created)
      await _navigateBasedOnRole(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential =
          await _googleAuthService.signInWithGoogle();

      if (userCredential == null) {
        setState(() => _isLoading = false);
        return;
      }

      _showSuccessSnackBar(
          'Welcome ${userCredential.user?.displayName ?? ""}!');

      await _navigateBasedOnRole(userCredential.user!);
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// FIXED: Navigate based on PRIMARY account (first created account)
  /// Priority: Admin > Primary Account (Customer/Worker) > Secondary Account > Account Selection
  /// CRITICAL FIX: Changed 'worker' to 'service_provider' to match WorkerService.saveWorker()
  Future<void> _navigateBasedOnRole(User user) async {
    try {
      // Get user document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // User document doesn't exist - redirect to account type selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccountTypeScreen()),
        );
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? role = userData['role'];

      // Priority 1: Check if user is admin
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
        );
        return;
      }

      // Priority 2: Check PRIMARY account (accountType field)
      String? accountType = userData['accountType'];
      if (accountType != null) {
        if (accountType == 'customer') {
          print(
              '✅ Primary account is Customer - navigating to Customer Dashboard');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CustomerDashboard()),
          );
        } else if (accountType == 'service_provider') {
          // ✅ FIXED: Changed from 'worker' to 'service_provider'
          print('✅ Primary account is Worker - navigating to Worker Dashboard');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WorkerDashboardScreen()),
          );
        } else {
          // Unknown account type - redirect to selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AccountTypeScreen()),
          );
        }
        return;
      }

      // Check if user has both customer and worker accounts
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();
      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      bool hasCustomer = customerDoc.exists;
      bool hasWorker = workerDoc.exists;

      // Priority 3: If user has BOTH accounts, check created_at timestamps
      if (hasCustomer && hasWorker) {
        print('⚠️ User has BOTH customer and worker accounts');

        Map<String, dynamic>? customerData =
            customerDoc.data() as Map<String, dynamic>?;
        Map<String, dynamic>? workerData =
            workerDoc.data() as Map<String, dynamic>?;

        if (customerData != null && workerData != null) {
          Timestamp? customerCreated = customerData['created_at'];
          Timestamp? workerCreated = workerData['created_at'];

          if (customerCreated != null && workerCreated != null) {
            // Navigate to the account that was created first
            if (customerCreated.compareTo(workerCreated) < 0) {
              print(
                  '✅ Customer was created first - navigating to Customer Dashboard');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CustomerDashboard()),
              );
            } else {
              print(
                  '✅ Worker was created first - navigating to Worker Dashboard');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => WorkerDashboardScreen()),
              );
            }
            return;
          }
        }

        // Fallback: if timestamps not available, navigate to customer
        if (hasCustomer) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CustomerDashboard()),
          );
        } else if (hasWorker) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WorkerDashboardScreen()),
          );
        }
        return;
      }

      // Fallback: Check which account exists (for old users without accountType)
      if (hasCustomer) {
        print('✅ Customer account found - navigating to customer dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
        return;
      }

      if (hasWorker) {
        print('✅ Worker account found - navigating to worker dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WorkerDashboardScreen()),
        );
        return;
      }

      // Priority 3: No account exists - redirect to account type selection
      print(
          '⚠️ No customer or worker account found - redirecting to account type selection');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccountTypeScreen()),
      );
    } catch (e) {
      print('❌ Error in navigation: $e');
      _showErrorSnackBar('Navigation error: ${e.toString()}');

      // Fallback to account type selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccountTypeScreen()),
      );
    }
  }

  void _resetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo/Title
                        Icon(
                          Icons.construction,
                          size: 64,
                          color: Color(0xFF2196F3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8),

                        // Remember Me & Forgot Password Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                Text('Remember me'),
                              ],
                            ),
                            TextButton(
                              onPressed: _resetPassword,
                              child: Text('Forgot Password?'),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Sign In Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Google Sign In Button
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.network(
                            'https://www.google.com/favicon.ico',
                            height: 24,
                            width: 24,
                          ),
                          label: Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          CreateAccountScreen()),
                                );
                              },
                              child: Text('Sign Up'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
