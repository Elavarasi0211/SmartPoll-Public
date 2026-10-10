import 'package:flutter/material.dart';

import 'admin_face_verification_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  final TextEditingController usernameController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  bool obscurePassword = true;
  bool isLoggingIn = false;

  // Demo admin credentials
  static const String adminUsername = 'admin';
  static const String adminPassword = 'admin123';

  void loginAdmin() {
    final username =
    usernameController.text.trim();

    final password =
    passwordController.text.trim();

    if (username.isEmpty ||
        password.isEmpty) {
      _showMessage(
        'Please enter username and password.',
      );
      return;
    }

    if (username == adminUsername &&
        password == adminPassword) {
      setState(() {
        isLoggingIn = true;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const AdminFaceVerificationScreen(),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            isLoggingIn = false;
          });
        }
      });
    } else {
      _showMessage(
        'Invalid admin username or password.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 430,
            ),
            child: Card(
              elevation: 4,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFF102A43,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .admin_panel_settings_rounded,
                          color:
                          Color(0xFFF4B942),
                          size: 42,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'SmartPoll',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Admin Portal',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Secure administration and '
                          'voting management',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Username
                    TextField(
                      controller:
                      usernameController,
                      textInputAction:
                      TextInputAction.next,
                      decoration:
                      InputDecoration(
                        labelText: 'Username',
                        prefixIcon:
                        const Icon(
                          Icons
                              .person_outline,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Password
                    TextField(
                      controller:
                      passwordController,
                      obscureText:
                      obscurePassword,
                      onSubmitted: (_) =>
                          loginAdmin(),
                      decoration:
                      InputDecoration(
                        labelText: 'Password',
                        prefixIcon:
                        const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon:
                        IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons
                                .visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                              !obscurePassword;
                            });
                          },
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      height: 52,
                      child:
                      ElevatedButton(
                        onPressed: isLoggingIn
                            ? null
                            : loginAdmin,
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF102A43,
                          ),
                          foregroundColor:
                          Colors.white,
                          disabledBackgroundColor:
                          Colors.grey,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        child: isLoggingIn
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Text(
                          'Login',
                          style:
                          TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          size: 16,
                          color:
                          Color(0xFF102A43),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Protected Admin Access',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
    );
  }
}