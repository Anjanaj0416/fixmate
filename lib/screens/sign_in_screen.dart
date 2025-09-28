import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_account_screen.dart';
import 'account_type_screen.dart';
import 'worker_registration_flow.dart';
// Import your main app screen here when available
// import 'main_app_screen.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

      // Check if user has completed profile setup
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('accountType') &&
            userData['accountType'] != null) {
          String accountType = userData['accountType'];

          // Navigate based on account type
          if (accountType == 'service_provider') {
            _showSuccessSnackBar('Redirecting to worker dashboard...');
            await Future.delayed(
                Duration(seconds: 1)); // Brief delay to show message

            Navigator.pushReplacementNamed(context, '/worker_dashboard');
          } else if (accountType == 'customer') {
            _showSuccessSnackBar('Redirecting to customer dashboard...');
            await Future.delayed(Duration(seconds: 1));

            // Navigate to customer dashboard when available
            Navigator.pushReplacementNamed(context, '/customer_dashboard');
          } else if (accountType == 'service_provider_pending') {
            // User started worker registration but didn't complete it
            _showSuccessSnackBar('Completing your worker registration...');
            await Future.delayed(Duration(seconds: 1));

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WorkerRegistrationFlow()),
            );
          } else {
            // Unknown account type, go to account type selection
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AccountTypeScreen()),
            );
          }
        } else {
          // User needs to complete account type selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AccountTypeScreen()),
          );
        }
      } else {
        // User document doesn't exist, go to account type selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccountTypeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection';
          break;
        default:
          errorMessage = e.message ?? 'Sign in failed';
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email first');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSuccessSnackBar('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for this email';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send reset email';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An error occurred while sending reset email');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 48),

              // Header
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sign in to your FixMate account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 48),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF2196F3)),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF2196F3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                        activeColor: Color(0xFF2196F3),
                      ),
                      Text(
                        'Remember me',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
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
              ),
              SizedBox(height: 40),

              // Sign Up Link
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateAccountScreen(),
                            ),
                          );
                        },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48),

              // Terms and Privacy
              Center(
                child: Text(
                  'By signing in, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
