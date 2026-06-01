import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_home_front_end/exports.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getAuthErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  void _bypassForDemo() {
    // Allows developers or reviewers to bypass auth and experience the dashboard immediately
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const Homepage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF090A0F),
              Color(0xFF101323),
              Color(0xFF1A1D36),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420.0),
                  child: GlassContainer(
                    borderRadius: 24.0,
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                    bgOpacity: 0.06,
                    borderOpacity: 0.12,
                    glowColor: const Color(0xFF8E99F3),
                    glowBlurRadius: 20.0,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App Branding Header
                          const Icon(
                            Icons.blur_on,
                            size: 64.0,
                            color: Color(0xFF8E99F3),
                          ),
                          const SizedBox(height: 12.0),
                          Center(
                            child: Text(
                              "AURA COMMAND",
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [
                                      Color(0xFF8E99F3),
                                      Color(0xFFE57373),
                                    ],
                                  ).createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                  ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          const Center(
                            child: Text(
                              "ENTERPRISE SMART HOME CONTROLLER",
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8C939D),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 35.0),

                          // Dynamic Error Box
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE57373).withOpacity(0.1),
                                border: Border.all(
                                  color: const Color(0xFFE57373).withOpacity(0.3),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFE57373),
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20.0),
                          ],

                          // Email Input Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 14.5),
                            decoration: InputDecoration(
                              labelText: "EMAIL ADDRESS",
                              labelStyle: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E99F3),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(
                                  color: const Color(0xFFE57373).withOpacity(0.5),
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE57373),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),

                          // Password Input Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white, fontSize: 14.5),
                            decoration: InputDecoration(
                              labelText: "PASSWORD",
                              labelStyle: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.white38,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E99F3),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide(
                                  color: const Color(0xFFE57373).withOpacity(0.5),
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE57373),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28.0),

                          // Action Button
                          _isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E99F3)),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5C6BC0).withOpacity(0.35),
                                        blurRadius: 15.0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF5C6BC0),
                                        Color(0xFF8E99F3),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                    ),
                                    child: Text(
                                      _isSignUp ? "REGISTER NEW ACCOUNT" : "AUTHENTICATE TERMINAL",
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 20.0),

                          // Toggle mode button
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8E99F3),
                            ),
                            child: Text(
                              _isSignUp
                                  ? "Already have an account? Sign In"
                                  : "Need an enterprise account? Register",
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white10)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text("OR", style: TextStyle(color: Colors.white30, fontSize: 11.0, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(child: Divider(color: Colors.white10)),
                              ],
                            ),
                          ),

                          // Demo Bypass Button
                          TextButton(
                            onPressed: _bypassForDemo,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8C939D),
                            ),
                            child: const Text(
                              "Bypass Authentication (Demo Mode)",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
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
      ),
    );
  }
}
