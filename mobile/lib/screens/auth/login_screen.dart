import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _showError = false;
  bool _emailSubmitted = false;
  String _errorMessage = '';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || !_termsAccepted) return;

    setState(() => _isLoading = true);

    try {
      final response = await Dio().post(
        'https://support.arcturustech.com/api/user/authenticate',
        data: {
          'email': _emailController.text,
          'password': _passwordController.text,
          'spec': 'genie'
        },
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', response.data['accessToken']);
        await prefs.setString('email', response.data['email']);
        await prefs.setBool('isLoggedIn', true);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/chat');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data['message'] ?? 'Login failed';
        _showError = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showError = false);
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (_showError)
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.redAccent,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () => setState(() => _showError = false),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Image.asset('assets/images/genie_logo.png',
                              width: 100),
                          const SizedBox(height: 5),
                          const Text('Genie',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                letterSpacing: 1.2,
                                fontFamily: 'GenieFont',
                              )),
                          const Text('Powered by Arcturustech',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.mail_outline_rounded,
                              color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Invalid email format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_emailSubmitted) ...[
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20.0)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20.0)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.length < 5) {
                              return 'Password must be at least 5 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _termsAccepted,
                                onChanged: (value) => setState(
                                    () => _termsAccepted = value ?? false),
                                shape: const CircleBorder(),
                                side: const BorderSide(color: Colors.grey),
                                fillColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                  (states) =>
                                      states.contains(MaterialState.selected)
                                          ? Colors.blue
                                          : Colors.transparent,
                                ),
                                checkColor: Colors.white,
                                overlayColor: MaterialStateProperty.all(
                                    Colors.grey.withOpacity(0.1)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                  children: [
                                    const TextSpan(
                                        text:
                                            "I confirm that I have read, consent and agree to Arcturus's "),
                                    TextSpan(
                                      text: "Terms of Use",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          const url =
                                              'https://helpdesk.arcturustech.com/hc/en-us';
                                          if (await canLaunchUrl(
                                              Uri.parse(url))) {
                                            await launchUrl(
                                              Uri.parse(url),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          const url =
                                              'https://helpdesk.arcturustech.com/hc/en-us';
                                          if (await canLaunchUrl(
                                              Uri.parse(url))) {
                                            await launchUrl(
                                              Uri.parse(url),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _termsAccepted && !_isLoading ? _login : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Log in',
                                    style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => launchUrl(Uri.parse(
                                      'https://support.arcturustech.com/forgot-password')),
                                  child: const Text('Forgot Password?',
                                      style: TextStyle(color: Colors.blue)),
                                ),
                                TextButton(
                                  onPressed: () => launchUrl(Uri.parse(
                                      'https://support.arcturustech.com/register')),
                                  child: const Text('Sign Up',
                                      style: TextStyle(color: Colors.blue)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _emailSubmitted = true);
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  FocusScope.of(context)
                                      .requestFocus(_passwordFocusNode);
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            child: const Text('Next',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
