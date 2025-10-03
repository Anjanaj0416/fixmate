// lib/screens/sign_in_screen.dart
// FIXED VERSION - Always navigate customers to customer dashboard first
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

      // Navigate based on user role
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

  /// FIXED: Navigate based on user role with proper priority
  /// Priority: Admin > Customer > Worker > Account Selection
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

      // Priority 2: Check if customer account exists
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        // Customer account exists - ALWAYS navigate to customer dashboard
        print('✅ Customer account found - navigating to customer dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
        return;
      }

      // Priority 3: Check if worker account exists (only if no customer account)
      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      if (workerDoc.exists) {
        // Only worker account exists - navigate to worker dashboard
        print(
            '✅ Worker account found (no customer) - navigating to worker dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WorkerDashboardScreen()),
        );
        return;
      }

      // Priority 4: No account exists - redirect to account type selection
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
    } catch (e) {
      _showErrorSnackBar('Password reset failed: ${e.toString()}');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 40),

                      // Logo/Title
                      Text(
                        'FixMate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Welcome back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 48),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFF2196F3)),
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
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
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
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFF2196F3)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Remember Me & Forgot Password
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
                                activeColor: Color(0xFF2196F3),
                              ),
                              Text(
                                'Remember me',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: Color(0xFF2196F3)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Google Sign In Button
                      SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: Image.asset(
                            'assets/google_logo.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.g_mobiledata,
                                  color: Colors.red, size: 24);
                            },
                          ),
                          label: Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
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
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
