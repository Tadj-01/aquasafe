import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/branding/app_branding.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_logo.dart';
import '../administrator_dashboard/admin_main_screen.dart';
import 'admin_signup_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@aquasafe.dz');
  final _passwordController = TextEditingController(text: 'AquaSafe2026!');
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: ApiConstants.googleServerClientId.isNotEmpty
        ? ApiConstants.googleServerClientId
        : null,
    scopes: ['email', 'profile'],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminMainScreen(),
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (mounted) {
          setState(() => _isGoogleLoading = false);
          _showGoogleSetupDialog(
            title: 'Google OAuth Setup Required',
            message:
                'On Android, Google Sign-In requires registering your app with Google Cloud Console:\n\n'
                '• Package Name: dz.aquasafe.frontend\n'
                '• SHA-1: 67:0E:23:9A:3B:1D:14:4A:C8:CD:8F:F9:2E:EE:32:33:66:C7:04:DA\n'
                '• Web Client ID (serverClientId) in api_constants.dart\n\n'
                'In the meantime, you can log in immediately using the credentials filled above (admin@aquasafe.dz / AquaSafe2026!).',
          );
        }
        return;
      }

      final success = await AuthService.loginWithGoogle(idToken);
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminMainScreen(),
          ),
        );
      } else if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage =
              'Google sign-in verification failed with authority server.';
        });
      }
    } on ApiException catch (apiErr) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        if (apiErr.statusCode == 403) {
          _showPendingApprovalDialog(apiErr.message);
        } else {
          setState(() => _errorMessage = apiErr.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
        final errStr = e.toString();
        if (errStr.contains('10') || errStr.contains('sign_in_failed')) {
          _showGoogleSetupDialog(
            title: 'Google Play Services Configuration',
            message:
                'Google Sign-In requires OAuth configuration in Google Cloud:\n\n'
                '1. Go to Google Cloud Console (APIs & Services > Credentials)\n'
                '2. Add an Android OAuth Client ID with:\n'
                '   Package name: dz.aquasafe.frontend\n'
                '   SHA-1 fingerprint: 67:0E:23:9A:3B:1D:14:4A:C8:CD:8F:F9:2E:EE:32:33:66:C7:04:DA\n'
                '3. Set the Web Client ID in ApiConstants.googleServerClientId.\n\n'
                'In the meantime, log in directly using the pre-filled supervisor credentials!',
          );
        } else {
          setState(() {
            _errorMessage = 'Google Authentication: $errStr';
          });
        }
      }
    }
  }

  void _showPendingApprovalDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.hourglass_top_rounded,
            color: Colors.orange, size: 40),
        title: const Text('Registration Submitted'),
        content: Text(
          message.isNotEmpty
              ? message
              : 'Your Google account has been registered as a candidate administrator! Waiting for supervisor approval before login.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGoogleSetupDialog(
      {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.info_outline_rounded,
            color: AppBranding.primaryBlue, size: 40),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child:
              Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Authority Portal'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppLogo(
                      size: 64,
                      showText: false,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Administrator Access',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppBranding.deepNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Authorized water authority personnel only.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppBranding.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address.';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Error display
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppBranding.statusUnderRepair.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppBranding.statusUnderRepair.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppBranding.statusUnderRepair,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppBranding.statusUnderRepair,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Standard Login Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Log In'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider with "OR"
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppBranding.secondaryText.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-In Button
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppBranding.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : _handleGoogleSignIn,
                        child: _isGoogleLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google colorful G icon simulation
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppBranding.deepNavy,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Signup Option for Candidate Admins
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "New personnel?",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppBranding.secondaryText,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminSignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Request Admin Access',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppBranding.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Information Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppBranding.lightWaterBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppBranding.primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'All new accounts (Email or Google) require approval from the Administrator Supervisor before login.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppBranding.deepNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
