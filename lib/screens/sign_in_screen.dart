// lib/screens/sign_in_screen.dart
// FIXED VERSION - Navigate to PRIMARY account (first created account)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_account_screen.dart';
import 'account_type_screen.dart';
import 'worker_registration_flow.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';
import 'customer_dashboard.dart';
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

      print('🔍 User accountType: $accountType');

      // Check both customer and worker accounts
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

      print('✅ Has Customer: $hasCustomer, Has Worker: $hasWorker');

      // NEW LOGIC: Navigate based on PRIMARY account (accountType)
      if (accountType == 'customer' && hasCustomer) {
        // Customer is primary account
        print('✅ Navigating to Customer Dashboard (Primary)');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
        return;
      } else if (accountType == 'worker' && hasWorker) {
        // Worker is primary account
        print('✅ Navigating to Worker Dashboard (Primary)');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WorkerDashboardScreen()),
        );
        return;
      } else if (accountType == 'both') {
        // User has both accounts - check which was created first
        if (hasCustomer && hasWorker) {
          // Compare creation timestamps
          Map<String, dynamic> customerData =
              customerDoc.data() as Map<String, dynamic>;
          Map<String, dynamic> workerData =
              workerDoc.data() as Map<String, dynamic>;

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

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email address first.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      _showSuccessSnackBar(
          'Password reset email sent. Please check your inbox.');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      _showErrorSnackBar(errorMessage);
    }
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
                        // Logo/Title
                        Icon(
                          Icons.handyman,
                          size: 64,
                          color: Color(0xFF2196F3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: 16,
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

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text('Forgot Password?'),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Sign In Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
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
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Google Sign In Button
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.asset(
                            'assets/google_logo.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.g_mobiledata, size: 24);
                            },
                          ),
                          label: Text('Sign in with Google'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Create Account Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateAccountScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
